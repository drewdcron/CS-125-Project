# main.py
# YGMS Phase 6: Interactive Event System
# Features: MongoDB User-Defined Types & Redis Set-Based Check-ins

import json
from typing import List, Optional
from fastapi import FastAPI
from fastapi.responses import HTMLResponse
from fastapi.middleware.cors import CORSMiddleware
from pydantic_settings import BaseSettings, SettingsConfigDict
from sqlalchemy import create_engine, Column, Integer, String
from sqlalchemy.orm import sessionmaker, declarative_base
from pymongo import MongoClient
import redis
import strawberry
from strawberry.fastapi import GraphQLRouter
import uvicorn


# --- 1. CONFIGURATION ---
class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")
    MYSQL_USER: str = "root"
    MYSQL_PASSWORD: str = "password"
    MYSQL_HOST: str = "127.0.0.1"
    MYSQL_PORT: int = 3306  # Check if this needs to be 3307 for Docker
    MYSQL_DATABASE: str = "ygms_db"
    MONGO_HOST: str = "localhost"

    # Defaults to localhost, but .env can override for Cloud Redis
    REDIS_HOST: str = "localhost"
    REDIS_PORT: int = 6379
    REDIS_USER: str = "default"
    REDIS_PASSWORD: str = ""

    @property
    def DATABASE_URL(self):
        return f"mysql+pymysql://{self.MYSQL_USER}:{self.MYSQL_PASSWORD}@{self.MYSQL_HOST}:{self.MYSQL_PORT}/{self.MYSQL_DATABASE}"


settings = Settings()

# --- DATABASE CONNECTIONS ---

# MySQL
Base = declarative_base()
engine = create_engine(settings.DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


class PersonORM(Base):
    __tablename__ = "Person"
    ID = Column(Integer, primary_key=True)
    Name = Column(String(255))
    Email = Column(String(100))


# EventType Table (Links MySQL ID to Mongo Schema)
class EventTypeORM(Base):
    __tablename__ = "EventType"
    ID = Column(Integer, primary_key=True, autoincrement=True)
    Name = Column(String(100), unique=True)


Base.metadata.create_all(bind=engine)

# MongoDB
mongo_client = MongoClient(f"mongodb://{settings.MONGO_HOST}:27017")
mongo_db = mongo_client["ygms_mongo_db"]
event_types_collection = mongo_db["event_types"]

# Redis
try:
    redis_client = redis.Redis(
        host=settings.REDIS_HOST, port=settings.REDIS_PORT,
        username=settings.REDIS_USER, password=settings.REDIS_PASSWORD,
        decode_responses=True, socket_timeout=2
    )

    redis_client.ping()
    print("SUCCESS: Connected to Redis!")

except:
    redis_client = None


# --- GRAPHQL SCHEMA ---

@strawberry.type
class PersonType:
    id: int
    name: str
    email: Optional[str]


@strawberry.type
class Query:
    @strawberry.field
    def people(self) -> List[PersonType]:
        db = SessionLocal()
        try:
            users = db.query(PersonORM).all()
            return [PersonType(id=u.ID, name=u.Name, email=u.Email) for u in users]
        finally:
            db.close()

    # Get list of IDs currently in a specific event (Redis)
    @strawberry.field
    def event_attendees(self, event_id: int) -> List[int]:
        if not redis_client: return []
        # SMEMBERS returns a set of strings, we convert to ints
        members = redis_client.smembers(f"event:{event_id}:checkedIn")
        return [int(m) for m in members]


@strawberry.type
class Mutation:

    # Create Event Type (MySQL + Mongo)
    @strawberry.mutation
    def create_event_type(self, name: str, schema_json: str) -> str:
        db = SessionLocal()
        try:
            # MySQL: Save Name/ID
            new_type = EventTypeORM(Name=name)
            db.add(new_type)
            db.commit()
            db.refresh(new_type)

            # MongoDB: Save Schema Definition
            mongo_doc = {
                "type_id": new_type.ID,
                "type_name": name,
                "fields": json.loads(schema_json)
            }
            event_types_collection.insert_one(mongo_doc)
            return f"Created Event '{name}' (ID: {new_type.ID})"
        except Exception as e:
            return f"Error: {str(e)}"
        finally:
            db.close()

    # Check In to Event (Redis Set)
    @strawberry.mutation
    def check_in_to_event(self, event_id: int, student_id: int) -> str:
        if not redis_client: return "Redis Error"

        # SADD adds to a Set (handles duplicates automatically)
        key = f"event:{event_id}:checkedIn"
        redis_client.sadd(key, student_id)
        return "Checked In"


schema = strawberry.Schema(query=Query, mutation=Mutation)
graphql_app = GraphQLRouter(schema)

# --- APP SETUP ---
app = FastAPI()
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])
app.include_router(graphql_app, prefix="/graphql")


@app.get("/")
def read_root():
    return {"message": "YGMS Backend Running", "graphql_url": "http://127.0.0.1:8005/graphql"}

@app.get("/frontend", response_class=HTMLResponse)
def serve_frontend():
    with open("frontend.html", "r", encoding="utf-8") as f:
        return f.read()


if __name__ == "__main__":
    uvicorn.run(app, host="127.0.0.1", port=8005)