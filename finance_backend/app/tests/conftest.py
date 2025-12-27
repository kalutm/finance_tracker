import pytest
from fastapi.testclient import TestClient
from sqlmodel import SQLModel, create_engine, Session
from sqlalchemy.orm import sessionmaker
from uuid import UUID, uuid4

from finance_backend.app.main import app
from app import models
from app.models.user import User
from app.core.settings import settings
from app.db.session import get_session
from app.auth.dependencies import get_current_user


# Database setup

TEST_DATABASE_URL = settings.TEST_DATABASE_URL
test_engine = create_engine(TEST_DATABASE_URL, echo=False)

TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=test_engine)


@pytest.fixture(scope="session", autouse=True)
def create_test_database():
    """Create/drop all tables once for the entire pytest session."""
    SQLModel.metadata.create_all(test_engine)
    yield
    SQLModel.metadata.drop_all(test_engine)


@pytest.fixture(scope="function")
def db_session(create_test_database):
    """Start a transaction per test and roll it back after."""
    connection = test_engine.connect()
    transaction = connection.begin()
    session = Session(bind=connection)
    try:
        yield session
    finally:
        session.close()
        transaction.rollback()
        connection.close()


# Dependency overrides

@pytest.fixture(scope="function")
def override_get_session(db_session):
    """Override get_session dependency to use the test DB session."""
    def _get_test_session():
        yield db_session

    app.dependency_overrides[get_session] = _get_test_session
    yield
    app.dependency_overrides.pop(get_session, None)


@pytest.fixture(scope="function")
def override_get_current_user():
    """Override get_current_user dependency to simulate a logged-in user."""
    fake_user = User(
        id=UUID(int=0x12345678123456781234567812345678),
        provider=models.enums.Provider.LOCAL,
        email="fake@user.com",
        is_verified=True,
        is_active=True,
    )

    def _fake_user():
        return fake_user

    app.dependency_overrides[get_current_user] = _fake_user
    yield
    app.dependency_overrides.pop(get_current_user, None)


# Test client
@pytest.fixture(scope="function")
def client(override_get_session):
    """Test client with dependencies overridden (auth + db)."""
    with TestClient(app) as c:
        yield c


# ------------- Helpers -------------

def create_test_user(session: Session, email="test@example.com", password_hash="hashed"):
    user = models.user.User(
        email=email,
        hashed_password=password_hash,
        provider=models.enums.Provider.LOCAL,
    )
    session.add(user)
    session.commit()
    session.refresh(user)
    return user