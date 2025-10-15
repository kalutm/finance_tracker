# tests/conftest.py
import os
import pytest
from fastapi.testclient import TestClient
from sqlmodel import SQLModel, create_engine, Session
from sqlalchemy import event
from sqlalchemy.engine import Engine
from sqlalchemy.orm import sessionmaker

# import your FastAPI app and the get_db dependency
from app.main import app
from app import models  # ensure model modules imported so SQLModel.metadata includes them

from app.core.settings import settings

# Config: test DB URL by env var (set this in your CI or local shell)
TEST_DATABASE_URL = settings.TEST_DATABASE_URL

# Create a fresh engine for tests (echo=False)
test_engine = create_engine(TEST_DATABASE_URL, echo=False)

# Use sessionmaker for creating sessions bound to a connection (for nested transactions)
TestingSessionLocal = sessionmaker(
    autocommit=False, autoflush=False, bind=test_engine
)


@pytest.fixture(scope="session", autouse=True)
def create_test_database():
    """
    Create all tables at the start of the test session, drop at the end.
    Use scope='session' so we create/drop once per pytest run.
    """
    # import all models so they are registered on metadata
    SQLModel.metadata.create_all(test_engine)
    yield
    SQLModel.metadata.drop_all(test_engine)


@pytest.fixture(scope="function")
def db_session():
    """
    Create a new connection + nested transaction for a test, yield a Session
    Rollback to savepoint at the end so DB is clean for next test.
    """
    connection = test_engine.connect()
    transaction = connection.begin()

    # bind a session to the connection
    session = Session(bind=connection)

    try:
        yield session
    finally:
        session.close()
        transaction.rollback()
        connection.close()


@pytest.fixture(scope="function")
def client(db_session, monkeypatch):
    """
    TestClient that uses the db_session for the app's get_db dependency.
    """
    # dependency override function
    def _get_test_session():
        try:
            yield db_session
        finally:
            pass

    # monkeypatch the dependency in your app
    monkeypatch.setattr("app.db.session.get_session", _get_test_session)  # adjust import path to your dep
    # If your get_db lives elsewhere, change the path above.

    with TestClient(app) as c:
        yield c
