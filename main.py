# main.py
# Assignment: Redis & MongoDB Initial Integration
# Features: User-Defined Event Types & Real-Time Check-In with Persistence

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
    MYSQL_USER: str
    MYSQL_PASSWORD: str
    MYSQL_HOST: str
    MYSQL_PORT: int
    MYSQL_DATABASE: str
    MONGO_HOST: str
    REDIS_HOST: str
    REDIS_PORT: int
    REDIS_USER: str
    REDIS_PASSWORD: str

    @property
    def DATABASE_URL(self):
        return f"mysql+pymysql://{self.MYSQL_USER}:{self.MYSQL_PASSWORD}@{self.MYSQL_HOST}:{self.MYSQL_PORT}/{self.MYSQL_DATABASE}"


settings = Settings()

# --- 2. DATABASE CONNECTIONS ---

# A. MySQL (Relational Core)
Base = declarative_base()
engine = create_engine(settings.DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


# Standard Person Table
class PersonORM(Base):
    __tablename__ = "Person"
    ID = Column(Integer, primary_key=True)
    Name = Column(String(255))
    Email = Column(String(100))


# FEATURE 1 TABLE: EventType (Stores the stable ID)
class EventTypeORM(Base):
    __tablename__ = "EventType"
    ID = Column(Integer, primary_key=True, autoincrement=True)
    Name = Column(String(100), unique=True)


# FEATURE 2 TABLE: Attendance (Permanent Record)
class AttendanceORM(Base):
    __tablename__ = "Attendance"
    ID = Column(Integer, primary_key=True, autoincrement=True)
    EventID = Column(Integer)
    StudentID = Column(Integer)
    Status = Column(String(50))  # e.g., "Present"


# Create all tables
Base.metadata.create_all(bind=engine)

# B. MongoDB (Schema Storage)
mongo_client = MongoClient(f"mongodb://{settings.MONGO_HOST}:27017")
mongo_db = mongo_client["ygms_mongo_db"]
# Collection for Feature 1
event_types_collection = mongo_db["event_types"]

# C. Redis (Real-time Set)
try:
    redis_client = redis.Redis(
        host=settings.REDIS_HOST, port=settings.REDIS_PORT,
        username=settings.REDIS_USER, password=settings.REDIS_PASSWORD,
        decode_responses=True, socket_timeout=2
    )
except:
    redis_client = None


# --- 3. GRAPHQL SCHEMA ---

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

    # Query to see who is currently in Redis (Live View)
    @strawberry.field
    def event_live_roster(self, event_id: int) -> List[int]:
        if not redis_client: return []
        # Redis Command: SMEMBERS
        members = redis_client.smembers(f"event:{event_id}:checkedIn")
        return [int(m) for m in members]


@strawberry.type
class Mutation:

    # --- FEATURE 1: MONGODB (User-Defined Event Types) ---
    @strawberry.mutation
    def create_event_type(self, name: str, schema_json: str) -> str:
        """
        Creates a new Event Type.
        1. Saves Name/ID in MySQL (Relational).
        2. Saves Schema Definition in MongoDB (Flexible).
        """
        db = SessionLocal()
        try:
            # 1. MySQL: Create the record to get a generated ID
            new_type = EventTypeORM(Name=name)
            db.add(new_type)
            db.commit()
            db.refresh(new_type)

            # 2. MongoDB: Store the custom schema keyed by the MySQL ID
            mongo_doc = {
                "type_id": new_type.ID,
                "type_name": name,
                "fields": json.loads(schema_json)  # Parse JSON string to object
            }
            event_types_collection.insert_one(mongo_doc)

            return f"Created Event Type '{name}' with ID {new_type.ID}."
        except Exception as e:
            return f"Error: {str(e)}"
        finally:
            db.close()

    # --- FEATURE 2: REDIS (Real-Time Check-In) ---
    @strawberry.mutation
    def check_in_student(self, event_id: int, student_id: int) -> str:
        """ Adds student to Redis Set (SADD) """
        if not redis_client: return "Redis Error"

        key = f"event:{event_id}:checkedIn"
        redis_client.sadd(key, student_id)
        return f"Student {student_id} checked into Event {event_id}"

    @strawberry.mutation
    def check_out_student(self, event_id: int, student_id: int) -> str:
        """ Removes student from Redis Set (SREM) """
        if not redis_client: return "Redis Error"

        key = f"event:{event_id}:checkedIn"
        redis_client.srem(key, student_id)
        return f"Student {student_id} checked out of Event {event_id}"

    # --- THE FLUSH: REDIS -> MYSQL ---
    @strawberry.mutation
    def end_event(self, event_id: int) -> str:
        """
        Ends the event:
        1. Reads live roster from Redis.
        2. Saves permanent records to MySQL Attendance table.
        3. Deletes Redis key.
        """
        if not redis_client: return "Redis Error"

        key = f"event:{event_id}:checkedIn"
        # 1. Read from Redis
        student_ids = redis_client.smembers(key)

        if not student_ids:
            return "No students checked in. Event ended."

        db = SessionLocal()
        count = 0
        try:
            # 2. Write to MySQL
            for s_id in student_ids:
                record = AttendanceORM(EventID=event_id, StudentID=int(s_id), Status="Present")
                db.add(record)
                count += 1

            db.commit()

            # 3. Clean up Redis
            redis_client.delete(key)
            return f"Event {event_id} synced. Saved {count} records to MySQL."

        except Exception as e:
            db.rollback()
            return f"Error saving to MySQL: {str(e)}"
        finally:
            db.close()


schema = strawberry.Schema(query=Query, mutation=Mutation)
graphql_app = GraphQLRouter(schema)

# --- 4. APP SETUP ---
app = FastAPI()
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])
app.include_router(graphql_app, prefix="/graphql")

@app.get("/")
def read_root():
    return {"message": "Welcome to the YGMS!",
            "graphql_url": "http://127.0.0.1:8005/graphql",
            "frontend_url": "http://127.0.0.1:8005/frontend"}
@app.get("/frontend", response_class=HTMLResponse)
def serve_frontend():
    with open("frontend.html", "r", encoding="utf-8") as f: return f.read()


if __name__ == "__main__":
    uvicorn.run(app, host="127.0.0.1", port=8005)