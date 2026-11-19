import os

# Testele nu depind de backend/.env.
os.environ.setdefault(
    "SECRET_KEY", "test-secret-key-long-enough-for-hs256-123456"
)

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine, event
from sqlalchemy.orm import sessionmaker

from app.db import Base, get_db
from app.main import app

# Implicit se folosește SQLite doar pentru teste. Pentru paritate cu producția:
#   TEST_DATABASE_URL=postgresql+psycopg://... pytest
TEST_DATABASE_URL = os.environ.get(
    "TEST_DATABASE_URL", "sqlite:///./test_car_tracker.db"
)
IS_SQLITE = TEST_DATABASE_URL.startswith("sqlite")


@pytest.fixture
def session_factory():
    engine = create_engine(
        TEST_DATABASE_URL,
        connect_args={"check_same_thread": False} if IS_SQLITE else {},
    )
    if IS_SQLITE:
        @event.listens_for(engine, "connect")
        def _enable_foreign_keys(dbapi_connection, _):
            cursor = dbapi_connection.cursor()
            cursor.execute("PRAGMA foreign_keys=ON")
            cursor.close()

    Base.metadata.drop_all(engine)
    Base.metadata.create_all(engine)
    factory = sessionmaker(bind=engine, autoflush=False, expire_on_commit=False)
    yield factory

    Base.metadata.drop_all(engine)
    engine.dispose()


TEST_EMAIL = "test-user@example.com"
TEST_PASSWORD = "parola12345"


@pytest.fixture
def auth_headers(client):
    client.post(
        "/api/v1/auth/register",
        json={"email": TEST_EMAIL, "password": TEST_PASSWORD},
    )
    response = client.post(
        "/api/v1/auth/login",
        json={"email": TEST_EMAIL, "password": TEST_PASSWORD},
    )
    assert response.status_code == 200, response.text
    token = response.json()["access_token"]
    return {"Authorization": f"Bearer {token}"}


@pytest.fixture
def client(session_factory):
    def override_get_db():
        db = session_factory()
        try:
            yield db
        finally:
            db.close()

    app.dependency_overrides[get_db] = override_get_db
    with TestClient(app) as test_client:
        yield test_client

    app.dependency_overrides.clear()
