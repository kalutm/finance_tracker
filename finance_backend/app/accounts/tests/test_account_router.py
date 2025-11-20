import pytest
from fastapi.testclient import TestClient
from types import SimpleNamespace
from uuid import UUID

from app.main import app
from app.accounts.exceptions import (
    AccountNameAlreadyTaken,
    AccountNotFound,
    CouldnotDeleteAccount,
)
from app.models.account import Account
from app.tests.conftest import override_get_current_user
from app.accounts import service as account_service_module


# Set up TestClient AFTER overrides
@pytest.fixture(scope="module")
def client():
    return TestClient(app)


# This fixture injects a fake service instance via DI override
@pytest.fixture
def fake_service():
    svc = SimpleNamespace(
        get_user_accounts=lambda: ([ ], 0),
        create_account=lambda data: None,
        get_account=lambda acc_id: None,
        update_account=lambda acc_id, data: None,
        deactivate_account=lambda acc_id: None,
        restore_account=lambda acc_id: None,
        delete_account=lambda acc_id: None,
    )

    # Apply DI override
    app.dependency_overrides[account_service_module.get_account_service] = lambda: svc
    yield svc

    # Clean up override
    app.dependency_overrides.pop(account_service_module.get_account_service, None)


uid = UUID(int=0x12345678123456781234567812345678)


# -------------------------
#       TEST CASES
# -------------------------

def test_get_user_accounts_success(client, fake_service, override_get_current_user):
    fake_accounts = [
        Account(id=1, name="Acc1", type="SAVINGS", currency="USD", user_id=uid, active=True)
    ]
    fake_service.get_user_accounts = lambda: (fake_accounts, 1)

    resp = client.get("/v1/accounts/")
    data = resp.json()

    assert resp.status_code == 200
    assert data["total"] == 1
    assert data["accounts"][0]["name"] == "Acc1"


def test_create_account_success(client, fake_service, override_get_current_user):
    fake_account = Account(id=1, name="NewAcc", type="CHECKING", currency="USD", user_id=uid)
    fake_service.create_account = lambda data: fake_account

    resp = client.post("/v1/accounts", json={"name": "NewAcc", "type": "WALLET", "currency": "USD"})
    data = resp.json()

    assert resp.status_code == 201
    assert data["name"] == "NewAcc"


def test_create_account_name_taken(client, fake_service, override_get_current_user):
    def raise_err(data):
        raise AccountNameAlreadyTaken("please use a different Account name")

    fake_service.create_account = raise_err

    resp = client.post("/v1/accounts", json={"name": "NewAcc", "type": "WALLET", "currency": "USD"})
    assert resp.status_code == 400
    assert "please use a different Account name" in resp.json()["detail"]


def test_get_account_success(client, fake_service, override_get_current_user):
    fake_account = Account(id=1, name="Acc1", type="WALLET", currency="USD", user_id=uid)
    fake_service.get_account = lambda acc_id: fake_account

    resp = client.get("/v1/accounts/1")
    data = resp.json()

    assert resp.status_code == 200
    assert data["id"] == 1


def test_get_account_not_found(client, fake_service, override_get_current_user):
    def raise_err(acc_id):
        raise AccountNotFound("could not find account")

    fake_service.get_account = raise_err

    resp = client.get("/v1/accounts/1")
    assert resp.status_code == 404
    assert "Not Found" in resp.json()["detail"]


def test_update_account_success(client, fake_service, override_get_current_user):
    fake_account = Account(id=1, name="Updated", type="SAVINGS", currency="USD", user_id=uid)
    fake_service.update_account = lambda acc_id, data: fake_account

    resp = client.patch("/v1/accounts/1", json={"name": "Updated"})
    data = resp.json()

    assert resp.status_code == 200
    assert data["name"] == "Updated"


def test_update_account_not_found(client, fake_service, override_get_current_user):
    fake_service.update_account = lambda acc_id, data: (_ for _ in ()).throw(AccountNotFound("account not found"))

    resp = client.patch("/v1/accounts/1", json={"name": "Updated"})
    assert resp.status_code == 404


def test_update_account_name_taken(client, fake_service, override_get_current_user):
    fake_service.update_account = lambda acc_id, data: (_ for _ in ()).throw(AccountNameAlreadyTaken("duplicate name"))

    resp = client.patch("/v1/accounts/1", json={"name": "Duplicate"})
    assert resp.status_code == 400
    assert "duplicate name" in resp.json()["detail"]


def test_deactivate_account_success(client, fake_service, override_get_current_user):
    fake_account = Account(id=1, name="Acc1", type="SAVINGS", currency="USD", user_id=uid, active=False)
    fake_service.deactivate_account = lambda acc_id: fake_account

    resp = client.patch("/accounts/1/deactivate")
    data = resp.json()
    assert resp.status_code == 200
    assert data["active"] is False


def test_deactivate_account_not_found(client, fake_service, override_get_current_user):
    fake_service.deactivate_account = lambda acc_id: (_ for _ in ()).throw(AccountNotFound("not found"))

    resp = client.patch("/accounts/1/deactivate")
    assert resp.status_code == 404


def test_restore_account_success(client, fake_service, override_get_current_user):
    fake_account = Account(id=1, name="Acc1", type="SAVINGS", currency="USD", user_id=uid, active=True)
    fake_service.restore_account = lambda acc_id: fake_account

    resp = client.patch("/accounts/1/restore")
    data = resp.json()
    assert resp.status_code == 200
    assert data["active"] is True


def test_restore_account_not_found(client, fake_service, override_get_current_user):
    fake_service.restore_account = lambda acc_id: (_ for _ in ()).throw(AccountNotFound("not found"))

    resp = client.patch("/accounts/1/restore")
    assert resp.status_code == 404


def test_delete_account_success(client, fake_service, override_get_current_user):
    fake_service.delete_account = lambda acc_id: None

    resp = client.delete("/accounts/1")
    assert resp.status_code == 204


def test_delete_account_not_found(client, fake_service, override_get_current_user):
    fake_service.delete_account = lambda acc_id: (_ for _ in ()).throw(AccountNotFound("not found"))

    resp = client.delete("/accounts/1")
    assert resp.status_code == 404


def test_delete_account_cannot_delete(client, fake_service, override_get_current_user):
    fake_service.delete_account = lambda acc_id: (_ for _ in ()).throw(CouldnotDeleteAccount("cannot delete"))

    resp = client.delete("/accounts/1")
    assert resp.status_code == 400
