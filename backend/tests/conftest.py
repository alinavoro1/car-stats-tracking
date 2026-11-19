import os

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
def client():
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
    testing_session = sessionmaker(
        bind=engine, autoflush=False, expire_on_commit=False
    )

    def override_get_db():
        db = testing_session()
        try:
            yield db
        finally:
            db.close()

    app.dependency_overrides[get_db] = override_get_db
    with TestClient(app) as test_client:
        yield test_client

    app.dependency_overrides.clear()
    Base.metadata.drop_all(engine)
    engine.dispose()
