from pydantic_settings import BaseSettings
from pydantic import Field


class Settings(BaseSettings):
    # JWT / auth
    SECRET_KEY: str = Field(..., env="SECRET_KEY")
    REFRESH_SECRET_KEY: str = Field(..., env="REFRESH_SECRET_KEY")
    ALGORITHM: str = Field(env="ALGORITHM")
    ACCESS_TOKEN_EXPIRE_MINUTES: int = Field(..., env="ACCESS_TOKEN_EXPIRE_MINUTES")
    REFRESH_TOKEN_EXPIRE_DAYS: int = Field(..., env="REFRESH_TOKEN_EXPIRE_DAYS")
    COOLDOWN_VERIFICATION_EMAIL_SECONDS: int = 60
    # Google
    GOOGLE_SERVER_CLIENT_ID_WEB: str = Field(..., env="GOOGLE_SERVER_CLIENT_ID_WEB")

    # Database
    DATABASE_URL: str = Field(..., env="DATABASE_URL")
    ALEMBIC_DATABASE_URL: str = Field(..., env="ALEMBIC_DATABASE_URL")
    TEST_DATABASE_URL: str = Field(..., env="TEST_DATABASE_URL")

    # Api Url
    API_BASE_URL_MOBILE: str = Field(..., env="API_BASE_URL_MOBILE")

    # Email settings (example)
    MAIL_USERNAME: str = Field(..., env="MAIL_USERNAME")
    MAIL_PASSWORD: str = Field(..., env="MAIL_PASSWORD")

    # Misc
    ENVIRONMENT: str = "development"

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"
        extra = "ignore"


settings = Settings()
