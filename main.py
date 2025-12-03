# main.py
# Youth Group Management System Backend
# Includes: FastAPI, SQLAlchemy (MySQL), Pydantic, Redis, MongoDB, and Strawberry (GraphQL)
# @author Brevin Tating btating@westmont.edu


import os
from typing import List, Optional, Any
from fastapi import FastAPI, Depends, HTTPException
from pydantic_settings import BaseSettings, SettingsConfigDict
from pydantic import BaseModel, ConfigDict
from sqlalchemy import create_engine, Column, Integer, String
from sqlalchemy.orm import sessionmaker, Session, declarative_base
from pymongo import MongoClient
import redis
import strawberry
from strawberry.fastapi import GraphQLRouter
import uvicorn

# ==========================================
#  CONFIGURATION
# ==========================================
class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    # MySQL
    MYSQL_USER: str = "root"
    MYSQL_PASSWORD: str = "password" # Fallback if .env missing
    MYSQL_HOST: str = "127.0.0.1"
    MYSQL_PORT: int = 3306
    MYSQL_DATABASE: str = "ygms_db"

    # Mongo
    MONGO_HOST: str = "localhost"

    # Redis (Cloud or Local)
    REDIS_HOST: str = "localhost"
    REDIS_PORT: int = 6379
    REDIS_USER: str = "default"
    REDIS_PASSWORD: str = ""

    @property
    def DATABASE_URL(self):
        return (
            f"mysql+pymysql://{self.MYSQL_USER}:{self.MYSQL_PASSWORD}@"
            f"{self.MYSQL_HOST}:{self.MYSQL_PORT}/{self.MYSQL_DATABASE}"
        )

settings = Settings()

# ==========================================
#  DATABASE SETUP
# ==========================================
# MySQL Setup
Base = declarative_base()
engine = create_engine(settings.DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

class PersonORM(Base):
    __tablename__ = "Person"
    ID = Column(Integer, primary_key=True, index=True)
    Name = Column(String(255), nullable=False)
    Email = Column(String(100), unique=True)
    PhoneNumber = Column(String(20), unique=True)

class Person(BaseModel):
    ID: int
    Name: str
    Email: Optional[str] = None
    PhoneNumber: Optional[str] = None
    model_config = ConfigDict(from_attributes=True)

# MongoDB Setup
mongo_client = MongoClient(f"mongodb://{settings.MONGO_HOST}:27017")
mongo_db = mongo_client["ygms_mongo_db"]
notes_collection = mongo_db["meeting_notes"]

# Redis Setup
try:
    redis_client = redis.Redis(
        host=settings.REDIS_HOST, port=settings.REDIS_PORT,
        username=settings.REDIS_USER, password=settings.REDIS_PASSWORD,
        decode_responses=True, socket_timeout=2
    )
except:
    redis_client = None

# ==========================================
# GRAPHQL SCHEMA
# ==========================================
@strawberry.type
class PersonType:
    id: int
    name: str
    email: Optional[str]
    phone_number: Optional[str]

    @strawberry.field
    def status(self) -> str:
        if not redis_client:
            return "Redis Error"
        # Check Redis for this specific person's ID
        val = redis_client.get(f"attendance:{self.id}")
        return val if val else "Not Checked In"

@strawberry.type
class CheckInType:
    user_id: int
    status: str

@strawberry.type
class NoteType:
    id: str
    content: str

@strawberry.type
class Query:
    @strawberry.field
    def people(self) -> List[PersonType]:
        db = SessionLocal()
        try:
            users = db.query(PersonORM).all()
            return [
                PersonType(id=u.ID, name=u.Name, email=u.Email, phone_number=u.PhoneNumber)
                for u in users
            ]
        finally:
            db.close()

    @strawberry.field
    def checkin_status(self, user_id: int) -> CheckInType:
        if not redis_client:
            return CheckInType(user_id=user_id, status="Redis Error")
        status = redis_client.get(f"attendance:{user_id}")
        return CheckInType(user_id=user_id, status=status if status else "Not Checked In")

    @strawberry.field
    def notes(self) -> List[NoteType]:
        # Fetch all documents from MongoDB
        raw_notes = notes_collection.find()
        return [NoteType(id=str(n["_id"]), content=n["content"]) for n in raw_notes]


@strawberry.type
class Mutation:
    # Write to Redis
    @strawberry.mutation
    def check_in_user(self, user_id: int) -> str:
        if redis_client:
            redis_client.set(f"attendance:{user_id}", "Checked In", ex=7200)
            return f"User {user_id} Checked In"
        return "Redis Error"

    @strawberry.mutation
    def add_note(self, content: str) -> str:
        result = notes_collection.insert_one({"content": content})
        return f"Note saved with ID: {result.inserted_id}"


schema = strawberry.Schema(query=Query, mutation=Mutation)
graphql_app = GraphQLRouter(schema)

# ==========================================
# API APPLICATION
# ==========================================
app = FastAPI(title="YGMS Unified API")

from fastapi.middleware.cors import CORSMiddleware

app.add_middleware(
    CORSMiddleware,
    # This allows your IDE (and anything else) to talk to the backend
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Routes
app.include_router(graphql_app, prefix="/graphql")

@app.get("/")
def read_root():
    return {"message": "YGMS Backend Running", "graphql_url": "http://127.0.0.1:8005/graphql"}

# Run Command
if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8005)