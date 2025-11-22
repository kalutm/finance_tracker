import pytest
from sqlmodel import Session
from uuid import UUID
from app.auth.repo import UserRepository
from app.models.user import User
from app.models.enums import Provider
from app.tests.conftest import db_session, create_test_database

# Instantiate once since UserRepository is stateless
repo = UserRepository()

# Tests
def test_get_user_by_email_success(db_session: Session):
    user = User(email="test@example.com", provider=Provider.LOCAL)
    db_session.add(user)
    db_session.commit()

    found_user = repo.get_user_by_email(db_session, "test@example.com")

    assert found_user is not None
    assert found_user.email == "test@example.com"


def test_get_user_by_email_returns_none(db_session: Session):
    result = repo.get_user_by_email(db_session, "missing@example.com")
    assert result is None


@pytest.mark.parametrize("provider,should_return", [
    (Provider.LOCAL, True),
    (Provider.LOCAL_GOOGLE, True),
    (Provider.GOOGLE, False),
])
def test_get_local_user_by_email_filters_correctly(db_session: Session, provider, should_return):
    user = User(email="a@b.com", provider=provider)
    db_session.add(user)
    db_session.commit()

    result = repo.get_local_user_by_email(db_session, "a@b.com")

    if should_return:
        assert result is not None
        assert result.email == user.email
        assert result.provider == provider
    else:
        assert result is None


@pytest.mark.parametrize("provider,should_return", [
    (Provider.LOCAL, False),
    (Provider.LOCAL_GOOGLE, True),
    (Provider.GOOGLE, True),
])
def test_get_google_user_by_provider_id(db_session: Session, provider, should_return):
    user = User(email="g@test.com", provider=provider, provider_id="google123")
    db_session.add(user)
    db_session.commit()

    result = repo.get_google_user_by_provider_id(db_session, "google123")

    if should_return:
        assert result is not None
        assert result.provider_id == "google123"
        assert result.provider == provider
    else:
        assert result is None


@pytest.mark.parametrize("provider,should_return", [
    (Provider.LOCAL, False),
    (Provider.LOCAL_GOOGLE, False),
    (Provider.GOOGLE, True),
])
def test_get_google_only_user_by_email(db_session: Session, provider, should_return):
    user = User(email="x@x.com", provider=provider)
    db_session.add(user)
    db_session.commit()

    result = repo.get_google_only_user_by_email(db_session, "x@x.com")

    if should_return:
        assert result is not None
        assert result.provider == Provider.GOOGLE
    else:
        assert result is None


def test_get_user_by_id(db_session: Session):
    user = User(email="id@x.com", provider=Provider.LOCAL)
    db_session.add(user)
    db_session.commit()

    found = repo.get_user_by_id(db_session, str(user.id))
    assert found is not None
    assert found.id == user.id
    assert found.email == user.email


def test_get_user_by_id_returns_none(db_session: Session):
    # do NOT add user → repo should naturally return None
    result = repo.get_user_by_id(db_session, UUID("9999"))
    assert result is None


def test_save_user_persists_to_db(db_session: Session):
    user = User(email="save@x.com", provider=Provider.LOCAL)
    repo.save_user(db_session, user)

    fetched = db_session.get(User, user.id)
    assert fetched is not None
    assert fetched.email == "save@x.com"


def test_delete_user_removes_from_db(db_session: Session):
    user = User(email="del@x.com", provider=Provider.LOCAL)
    db_session.add(user)
    db_session.commit()

    repo.delete_user(db_session, user)

    assert db_session.get(User, user.id) is None
