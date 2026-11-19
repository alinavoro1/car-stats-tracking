from app.config import Settings


def settings_with(database_url: str) -> Settings:
    return Settings(
        _env_file=None,
        database_url=database_url,
        secret_key="x" * 48,
    )


def test_postgres_scheme_is_normalized():
    settings = settings_with("postgres://user:pass@host:5432/db")
    assert settings.database_url == "postgresql+psycopg://user:pass@host:5432/db"


def test_plain_postgresql_scheme_is_normalized():
    settings = settings_with("postgresql://user:pass@host:5432/db")
    assert settings.database_url == "postgresql+psycopg://user:pass@host:5432/db"


def test_driver_url_is_unchanged():
    url = "postgresql+psycopg://user:pass@host:5432/db"
    assert settings_with(url).database_url == url
