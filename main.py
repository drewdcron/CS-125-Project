# main.py
import json
from datetime import datetime
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

    # Mongo
    MONGO_HOST: str

    # Redis (Update to 127.0.0.1 if running local, or use Cloud URL)
    REDIS_HOST: str
    REDIS_PORT: int
    REDIS_PASSWORD: str

    @property
    def DATABASE_URL(self):
        return f"mysql+pymysql://{self.MYSQL_USER}:{self.MYSQL_PASSWORD}@{self.MYSQL_HOST}:{self.MYSQL_PORT}/{self.MYSQL_DATABASE}"


settings = Settings()

# --- 2. DATABASE SETUP ---
Base = declarative_base()
engine = create_engine(settings.DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


class PersonORM(Base):
    __tablename__ = "Person"
    ID = Column(Integer, primary_key=True)
    Name = Column(String(255))
    Email = Column(String(100))
    PhoneNumber = Column(String(20))
    Role = Column(String(50))


class EventTypeORM(Base):
    __tablename__ = "EventType"
    ID = Column(Integer, primary_key=True, autoincrement=True)
    Name = Column(String(100), unique=True)


class AttendanceORM(Base):
    __tablename__ = "Attendance"
    ID = Column(Integer, primary_key=True, autoincrement=True)
    EventID = Column(Integer)
    StudentID = Column(Integer)
    Status = Column(String(50))


# Create tables if missing
Base.metadata.create_all(bind=engine)

# --- NOSQL CONNECTIONS ---
# MongoDB
mongo_client = MongoClient(f"mongodb://{settings.MONGO_HOST}:27017")
mongo_db = mongo_client["ygms_mongo_db"]
event_types_collection = mongo_db["event_types"]  # Stores schemas
event_custom_data_collection = mongo_db["event_custom_data"]  # Stores answers

# Redis
try:
    redis_client = redis.Redis(
        host=settings.REDIS_HOST, port=settings.REDIS_PORT,
        password=settings.REDIS_PASSWORD, decode_responses=True, socket_timeout=2
    )
except:
    redis_client = None


# --- 3. GRAPHQL TYPES ---

@strawberry.type
class PersonType:
    id: int
    name: str
    email: Optional[str]
    role: str


@strawberry.type
class EventTypeObj:
    id: int
    name: str


@strawberry.type
class MongoSchemaType:
    type_id: int
    schema_json: str


@strawberry.type
class CustomDataType:
    student_id: int
    event_id: int
    data_json: str


# --- 4. QUERY RESOLVERS (READ) ---
@strawberry.type
class Query:

    # --- MySQL Queries ---
    @strawberry.field
    def people(self) -> List[PersonType]:
        db = SessionLocal()
        try:
            users = db.query(PersonORM).all()
            return [PersonType(id=u.ID, name=u.Name, email=u.Email, role=u.Role) for u in users]
        finally:
            db.close()

    @strawberry.field
    def get_all_events(self) -> List[EventTypeObj]:
        db = SessionLocal()
        try:
            events = db.query(EventTypeORM).all()
            return [EventTypeObj(id=e.ID, name=e.Name) for e in events]
        finally:
            db.close()

    @strawberry.field
    def get_rsvp_list(self, event_id: int) -> List[int]:
        # New list just for RSVPs
        if not redis_client: return []
        members = redis_client.smembers(f"event:{event_id}:rsvp")
        return [int(m) for m in members]

    # --- Redis Queries (Live Roster) ---

    @strawberry.field
    def event_live_roster(self, event_id: int) -> List[int]:
        # Requirement: SMEMBERS (List all students)
        if not redis_client: return []
        members = redis_client.smembers(f"event:{event_id}:checkedIn")
        return [int(m) for m in members]

    @strawberry.field
    def get_active_count(self, event_id: int) -> int:
        # Requirement: SCARD (Get count)
        if not redis_client: return 0
        return redis_client.scard(f"event:{event_id}:checkedIn")

    @strawberry.field
    def is_student_checked_in(self, event_id: int, student_id: int) -> bool:
        # Requirement: SISMEMBER (Check specific student)
        if not redis_client: return False
        return redis_client.sismember(f"event:{event_id}:checkedIn", student_id)

    # --- MongoDB Queries (Schemas & Custom Data) ---

    @strawberry.field
    def get_event_schema(self, type_id: int) -> Optional[str]:
        # Requirement: db.eventTypes.findOne
        doc = event_types_collection.find_one({"typeId": type_id})
        if doc:
            return json.dumps(doc.get("schema", {}))
        return None

    @strawberry.field
    def get_custom_data_for_event(self, event_id: int) -> List[CustomDataType]:
        # Requirement: db.eventCustomData.find
        cursor = event_custom_data_collection.find({"eventId": event_id})
        results = []
        for doc in cursor:
            results.append(CustomDataType(
                student_id=doc["studentId"],
                event_id=doc["eventId"],
                data_json=json.dumps(doc.get("data", {}))
            ))
        return results


# --- 5. MUTATIONS (WRITE) ---
@strawberry.type
class Mutation:

    # --- Setup Logic (MySQL + Mongo) ---
    @strawberry.mutation
    def create_event_type(self, name: str, schema_json: str) -> str:
        db = SessionLocal()
        try:
            # 1. MySQL: Save basic info to get ID
            new_type = EventTypeORM(Name=name)
            db.add(new_type)
            db.commit()
            db.refresh(new_type)

            # 2. MongoDB: Save the flexible schema
            # Requirement: db.eventTypes.insertOne
            schema_dict = json.loads(schema_json)
            mongo_doc = {
                "typeId": new_type.ID,
                "name": name,
                "schema": schema_dict
            }
            event_types_collection.insert_one(mongo_doc)

            return f"{new_type.ID}:{name}"
        except Exception as e:
            return f"Error: {str(e)}"
        finally:
            db.close()

    @strawberry.mutation
    def rsvp_student(self, event_id: int, student_id: int) -> str:
        # Adds to the RSVP list (Intention), NOT the Check-In list (Presence)
        if not redis_client: return "Redis Error"
        redis_client.sadd(f"event:{event_id}:rsvp", student_id)
        return "RSVP Confirmed"

    @strawberry.mutation
    def update_event_schema(self, type_id: int, schema_json: str) -> str:
        # Requirement: db.eventTypes.updateOne
        try:
            new_schema = json.loads(schema_json)
            result = event_types_collection.update_one(
                {"typeId": type_id},
                {"$set": {"schema": new_schema}}
            )
            return f"Updated: {result.modified_count} docs"
        except Exception as e:
            return f"Error: {e}"

    @strawberry.mutation
    def submit_custom_data(self, event_id: int, student_id: int, data_json: str) -> str:
        # Requirement: db.eventCustomData.insertOne
        try:
            data_dict = json.loads(data_json)
            doc = {
                "eventId": event_id,
                "studentId": student_id,
                "data": data_dict
            }
            event_custom_data_collection.insert_one(doc)
            return "Data Saved"
        except Exception as e:
            return f"Error: {e}"

    # --- Live Check-In Logic (Redis) ---

    @strawberry.mutation
    def check_in_student(self, event_id: int, student_id: int) -> str:
        if not redis_client: return "Redis Error"

        # 1. Add to Roster (Set)
        # Requirement: SADD
        redis_client.sadd(f"event:{event_id}:checkedIn", student_id)

        # 2. Log Timestamp (Hash)
        # Requirement: HSET
        timestamp = datetime.now().isoformat()
        redis_client.hset(f"event:{event_id}:checkInTimes", str(student_id), timestamp)

        return "Checked In"

    @strawberry.mutation
    def check_out_student(self, event_id: int, student_id: int) -> str:
        if not redis_client: return "Redis Error"

        # 1. Remove from Roster (Set)
        # Requirement: SREM
        redis_client.srem(f"event:{event_id}:checkedIn", student_id)

        # 2. Log Timestamp (Hash)
        # Requirement: HSET
        timestamp = datetime.now().isoformat()
        redis_client.hset(f"event:{event_id}:checkOutTimes", str(student_id), timestamp)

        return "Checked Out"

    # --- End Event Logic (Redis -> MySQL) ---

    @strawberry.mutation
    def end_event(self, event_id: int) -> str:
        if not redis_client: return "Redis Error"

        db = SessionLocal()
        try:
            # --- 1. SAVE ATTENDANCE (Redis -> MySQL) ---
            # Retrieve the list of student IDs from the active Redis roster
            key_roster = f"event:{event_id}:checkedIn"
            ids = redis_client.smembers(key_roster)

            count = 0
            for s_id in ids:
                # Check if this record already exists in MySQL to prevent duplicates
                exists = db.query(AttendanceORM).filter_by(EventID=event_id, StudentID=int(s_id)).first()
                if not exists:
                    # Create the permanent record. Even if the Event is deleted later,
                    # this row stays in the 'Attendance' table.
                    db.add(AttendanceORM(EventID=event_id, StudentID=int(s_id), Status="Present"))
                    count += 1

            # Commit the attendance records first
            db.commit()

            # --- 2. DELETE EVENT FROM MENU (MySQL) ---
            # This removes the event from the 'EventType' table, so it
            # stops showing up in the frontend dropdown.
            event = db.query(EventTypeORM).filter_by(ID=event_id).first()
            event_name = "Unknown Event"

            if event:
                event_name = event.Name
                db.delete(event)
                db.commit()


            # --- 3. PRESERVE MONGO (Do Nothing) ---
            # We intentionally DO NOT delete from 'event_custom_data_collection'.
            # This ensures snack preferences and allergies are kept forever.

            return f"Event '{event_name}' ended. {count} attendance records saved. Event removed from active menu."

        except Exception as e:
            db.rollback()
            return f"Error: {e}"
        finally:
            db.close()





schema = strawberry.Schema(query=Query, mutation=Mutation)
graphql_app = GraphQLRouter(schema)

app = FastAPI()
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])
app.include_router(graphql_app, prefix="/graphql")

@app.get("/")
def read_root():
    return {"message":"Welcome to the YGMS!",
            "graphql_url":"http://127.0.0.1:8005/graphql",
            "frontend_url":"http://127.0.0.1:8005/frontend"}

@app.get("/frontend", response_class=HTMLResponse)
def serve_frontend():
    with open("frontend.html", "r", encoding="utf-8") as f: return f.read()


if __name__ == "__main__":
    print(f"STARTUP CHECK: Connecting to MySQL on Port {settings.MYSQL_PORT}")

    uvicorn.run(app, host="127.0.0.1", port=8005)
