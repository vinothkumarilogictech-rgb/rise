from pydantic_settings import BaseSettings
from typing import List, Optional
import os

class Settings(BaseSettings):
    APP_ENV: str = "development"
    DATABASE_URL: str = "sqlite:///./rise.db"
    GROK_API_KEY: Optional[str] = None
    GROK_MODEL: str = "openai/gpt-oss-120b"
    GROK_BASE_URL: Optional[str] = None
    JWT_SECRET_KEY: str = "rise_super_secret_jwt_key_change_in_production_1234567890"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 43200  # 30 days
    CORS_ORIGINS: str = (
        "http://localhost:51219,http://127.0.0.1:51219,"
        "http://localhost:3000,http://127.0.0.1:3000,"
        "http://localhost:8080,http://127.0.0.1:8080"
    )
    FCM_ENABLED: bool = False
    FIREBASE_PROJECT_ID: Optional[str] = None

    class Config:
        env_file = ".env"
        extra = "allow"

    @property
    def grok_endpoint(self) -> str:
        if self.GROK_BASE_URL:
            url = self.GROK_BASE_URL.rstrip("/")
            return f"{url}/chat/completions" if not url.endswith("/chat/completions") else url
        if self.GROK_API_KEY and self.GROK_API_KEY.startswith("gsk_"):
            return "https://api.groq.com/openai/v1/chat/completions"
        if self.GROK_API_KEY and self.GROK_API_KEY.startswith("xai-"):
            return "https://api.x.ai/v1/chat/completions"
        if self.GROK_API_KEY and self.GROK_API_KEY.startswith("sk-"):
            return "https://api.openai.com/v1/chat/completions"
        return "https://api.groq.com/openai/v1/chat/completions"

    @property
    def resolved_model(self) -> str:
        if self.GROK_API_KEY and self.GROK_API_KEY.startswith("gsk_"):
            if not self.GROK_MODEL or self.GROK_MODEL in ("grok-2-latest", "grok-beta"):
                return "openai/gpt-oss-120b"
        return self.GROK_MODEL or "openai/gpt-oss-120b"

    @property
    def cors_origin_list(self) -> List[str]:
        raw = self.CORS_ORIGINS or ""
        # Filter out '*' to comply with credentialed CORS specifications
        origins = [
            origin.strip()
            for origin in raw.split(",")
            if origin.strip() and origin.strip() != "*"
        ]
        defaults = [
            "http://localhost:51219",
            "http://127.0.0.1:51219",
            "http://localhost:3000",
            "http://127.0.0.1:3000",
            "http://localhost:8080",
            "http://127.0.0.1:8080",
        ]
        for d in defaults:
            if d not in origins:
                origins.append(d)
        return origins

    @property
    def sqlalchemy_database_url(self) -> str:
        url = self.DATABASE_URL
        # Neon or Heroku postgres:// fix for SQLAlchemy
        if url.startswith("postgres://"):
            url = url.replace("postgres://", "postgresql://", 1)
        return url

    @property
    def is_production(self) -> bool:
        return self.APP_ENV.lower() in ("production", "prod")

    @property
    def is_secure_jwt(self) -> bool:
        if self.is_production and "change_in_production" in self.JWT_SECRET_KEY:
            return False
        return True

settings = Settings()

