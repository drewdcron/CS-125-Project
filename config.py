# config.py
from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):

    model_config = SettingsConfigDict(env_file=".env")
    # These must match the names in your .env file
    MYSQL_USER: str
    MYSQL_PASSWORD: str
    MYSQL_HOST: str = "127.0.0.1" # Default for local testing
    MYSQL_PORT: int = 3306
    MYSQL_DATABASE: str = "ygms_db"

    @property
    def DATABASE_URL(self):
        # Format: mysql+pymysql://user:password@host:port/database
        return (
            f"mysql+pymysql://{self.MYSQL_USER}:{self.MYSQL_PASSWORD}@"
            f"{self.MYSQL_HOST}:{self.MYSQL_PORT}/{self.MYSQL_DATABASE}"
        )


settings = Settings()