# main.py
import json
from datetime import datetime
from typing import List, Optional
from fastapi import FastAPI
from fastapi.responses import HTMLResponse
from fastapi.middleware.cors import CORSMiddleware
from pydantic_settings import BaseSettings, SettingsConfigDict
from sqlalchemy import create_engine, String, Integer, text
from sqlalchemy.orm import sessionmaker, DeclarativeBase, Mapped, mapped_column
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
    REDIS_PASSWORD: str

    @property
    def DATABASE_URL(self):
        return f"mysql+pymysql://{self.MYSQL_USER}:{self.MYSQL_PASSWORD}@{self.MYSQL_HOST}:{self.MYSQL_PORT}/{self.MYSQL_DATABASE}"


settings = Settings()


# --- 2. DATABASE SETUP ---
class Base(DeclarativeBase):
    pass


engine = create_engine(settings.DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


class PersonORM(Base):
    __tablename__ = "Person"
    ID: Mapped[int] = mapped_column(Integer, primary_key=True)
    Name: Mapped[str] = mapped_column(String(255))
    Email: Mapped[str] = mapped_column(String(100))
    PhoneNumber: Mapped[Optional[str]] = mapped_column(String(20), default=None)
    Role: Mapped[str] = mapped_column(String(50))


class EventTypeORM(Base):
    __tablename__ = "EventType"
    ID: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    Name: Mapped[str] = mapped_column(String(100), unique=True)
    Status: Mapped[str] = mapped_column(String(50), default="Active")
    Type: Mapped[Optional[str]] = mapped_column(String(50), default=None)
    Location: Mapped[Optional[str]] = mapped_column(String(255), default=None)
    Time: Mapped[Optional[str]] = mapped_column(String(100), default=None)
    Description: Mapped[Optional[str]] = mapped_column(String(255), default=None)


class AttendanceORM(Base):
    __tablename__ = "Attendance"
    ID: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    EventID: Mapped[int] = mapped_column(Integer)
    StudentID: Mapped[int] = mapped_column(Integer)
    Status: Mapped[str] = mapped_column(String(50))


Base.metadata.create_all(bind=engine)

# --- NOSQL CONNECTIONS ---
try:
    mongo_client = MongoClient(f"mongodb://{settings.MONGO_HOST}:27017")
    mongo_client.admin.command('ping')
    mongo_db = mongo_client["ygms_mongo_db"]
    event_types_collection = mongo_db["event_types"]
    event_custom_data_collection = mongo_db["event_custom_data"]
    student_profiles_collection = mongo_db["student_profiles"]
    print("STARTUP CHECK: MongoDB connected.")
except Exception as e:
    print(f"STARTUP CHECK: MongoDB connection failed: {e}")
    mongo_client, event_types_collection, event_custom_data_collection, student_profiles_collection = None, None, None, None

try:
    redis_client = redis.Redis(
        host=settings.REDIS_HOST, port=settings.REDIS_PORT,
        password=settings.REDIS_PASSWORD, decode_responses=True, socket_timeout=2
    )
    redis_client.ping()
    print("STARTUP CHECK: Redis connected.")
except Exception as e:
    print(f"STARTUP CHECK: Redis connection failed: {e}")
    redis_client = None


# --- 3. GRAPHQL TYPES ---
@strawberry.type
class PersonType:
    id: int
    name: str
    email: Optional[str]
    role: str
    phone_number: Optional[str]


@strawberry.type
class EventTypeObj:
    id: int
    name: str
    status: str
    type: Optional[str]
    location: Optional[str]
    time: Optional[str]
    description: Optional[str]


@strawberry.type
class CustomDataType:
    student_id: int
    event_id: int
    data_json: str


# --- 4. QUERY RESOLVERS ---
@strawberry.type
class Query:
    @strawberry.field
    def people(self) -> List[PersonType]:
        db = SessionLocal()
        try:
            users = db.query(PersonORM).all()
            return [PersonType(id=u.ID, name=u.Name, email=u.Email, role=u.Role, phone_number=u.PhoneNumber) for u in
                    users]
        finally:
            db.close()

    @strawberry.field
    def youth(self) -> List[PersonType]:
        db = SessionLocal()
        try:
            users = db.query(PersonORM).filter(PersonORM.Role.in_(['Youth', 'Student'])).all()
            return [PersonType(id=u.ID, name=u.Name, email=u.Email, role=u.Role, phone_number=u.PhoneNumber) for u in
                    users]
        finally:
            db.close()

    @strawberry.field
    def get_all_events(self) -> List[EventTypeObj]:
        db = SessionLocal()
        try:
            events = db.query(EventTypeORM).all()
            return [EventTypeObj(
                id=e.ID, name=e.Name, status=e.Status or "Active", type=e.Type,
                location=e.Location, time=e.Time, description=e.Description
            ) for e in events]
        finally:
            db.close()

    @strawberry.field
    def get_rsvp_list(self, event_id: int) -> List[int]:
        if redis_client is None: return []
        members = redis_client.smembers(f"event:{event_id}:rsvp")
        return [int(m) for m in members]

    @strawberry.field
    def event_live_roster(self, event_id: int) -> List[int]:
        if redis_client is None: return []
        members = redis_client.smembers(f"event:{event_id}:checkedIn")
        return [int(m) for m in members]

    @strawberry.field
    def get_active_count(self, event_id: int) -> int:
        if redis_client is None: return 0
        return redis_client.scard(f"event:{event_id}:checkedIn")

    @strawberry.field
    def is_student_checked_in(self, event_id: int, student_id: int) -> bool:
        if redis_client is None: return False
        return redis_client.sismember(f"event:{event_id}:checkedIn", student_id)

    @strawberry.field
    def get_custom_data_for_event(self, event_id: int) -> List[CustomDataType]:
        if event_custom_data_collection is None: return []
        cursor = event_custom_data_collection.find({"eventId": event_id})
        results = []
        for doc in cursor:
            if "studentId" in doc and "eventId" in doc:
                results.append(CustomDataType(
                    student_id=doc["studentId"], event_id=doc["eventId"], data_json=json.dumps(doc.get("data", {}))
                ))
        return results

    @strawberry.field
    def get_student_profile(self, student_id: int) -> str:
        if student_profiles_collection is None: return "{}"
        doc = student_profiles_collection.find_one({"studentId": student_id})
        if doc: return json.dumps(doc.get("data", {}))
        return "{}"


# --- 5. MUTATIONS ---
@strawberry.type
class Mutation:
    @strawberry.mutation
    def create_event_type(self, name: str, event_type: str, location: str, time: str, description: str) -> str:
        db = SessionLocal()
        if redis_client is None: return "Error: Redis not connected."
        try:
            new_type = EventTypeORM(Name=name, Status='Active', Type=event_type, Location=location, Time=time,
                                    Description=description)
            db.add(new_type)
            db.commit()
            db.refresh(new_type)
            event_id = new_type.ID
            redis_client.set(f"event:{event_id}:status", "Active")
            return f"{event_id}:{name}"
        except Exception as e:
            db.rollback()
            return f"Error: {str(e)}"
        finally:
            db.close()

    @strawberry.mutation
    def update_event_details(self, event_id: int, name: str, location: str, time: str, generic_description: str) -> str:
        db = SessionLocal()
        try:
            event = db.query(EventTypeORM).filter_by(ID=event_id).first()
            if not event: return "Error: Event not found."
            event.Name = name
            event.Location = location
            event.Time = time
            try:
                current_json = json.loads(event.Description) if event.Description else {}
            except:
                current_json = {"generic": "", "specialized": {}}
            if not isinstance(current_json, dict): current_json = {"generic": "", "specialized": {}}
            current_json["generic"] = generic_description
            event.Description = json.dumps(current_json)
            db.commit()
            return "Event Updated Successfully"
        except Exception as e:
            db.rollback()
            return f"Error: {str(e)}"
        finally:
            db.close()

    @strawberry.mutation
    def rsvp_student(self, event_id: int, student_id: int) -> str:
        if redis_client is None: return "Redis Error"
        redis_client.sadd(f"event:{event_id}:rsvp", student_id)
        return "RSVP Confirmed"

    @strawberry.mutation
    def submit_custom_data(self, event_id: int, student_id: int, data_json: str) -> str:
        if event_custom_data_collection is None: return "Error: Mongo Not Connected"
        try:
            data_dict = json.loads(data_json)
            doc = {"eventId": event_id, "studentId": student_id, "data": data_dict}
            event_custom_data_collection.update_one(
                {"eventId": event_id, "studentId": student_id}, {"$set": doc}, upsert=True
            )
            return "Data Saved"
        except Exception as e:
            return f"Error: {e}"

    @strawberry.mutation
    def check_in_student(self, event_id: int, student_id: int) -> str:
        if redis_client is None: return "Redis Error"

        db = SessionLocal()
        try:
            person = db.query(PersonORM).filter_by(ID=student_id).first()
            if not person:
                return "Error: User not found."

            user_role = person.Role
            EXEMPT_ROLES = ["Youth Pastor", "Leader", "Admin", "Security", "Pastor"]

            if user_role not in EXEMPT_ROLES:
                is_rsvped = redis_client.sismember(f"event:{event_id}:rsvp", student_id)
                if not is_rsvped:
                    return f"Error: {user_role}s must RSVP before checking in."
        finally:
            db.close()

        redis_client.sadd(f"event:{event_id}:checkedIn", student_id)
        timestamp = datetime.now().isoformat()
        redis_client.hset(f"event:{event_id}:checkInTimes", str(student_id), timestamp)
        return "Checked In"

    @strawberry.mutation
    def check_out_student(self, event_id: int, student_id: int) -> str:
        if redis_client is None: return "Redis Error"
        redis_client.srem(f"event:{event_id}:checkedIn", student_id)
        timestamp = datetime.now().isoformat()
        redis_client.hset(f"event:{event_id}:checkOutTimes", str(student_id), timestamp)
        return "Checked Out"

    @strawberry.mutation
    def update_student_profile(self, student_id: int, data_json: str) -> str:
        if student_profiles_collection is None: return "Error: Mongo Not Connected"
        try:
            data_dict = json.loads(data_json)
            student_profiles_collection.update_one(
                {"studentId": student_id}, {"$set": {"data": data_dict}}, upsert=True
            )
            return "Profile Updated"
        except Exception as e:
            return f"Error: {e}"

    @strawberry.mutation
    def un_rsvp_student(self, event_id: int, student_id: int) -> str:
        if redis_client is None: return "Redis Error"
        redis_client.srem(f"event:{event_id}:rsvp", student_id)
        redis_client.srem(f"event:{event_id}:checkedIn", student_id)
        if event_custom_data_collection is not None:
            event_custom_data_collection.delete_one({"eventId": event_id, "studentId": student_id})
        return "RSVP Cleared"

    @strawberry.mutation
    def create_person(self, name: str, email: str, role: str, phone: Optional[str] = "") -> str:
        db = SessionLocal()
        try:
            new_person = PersonORM(Name=name, Email=email, Role=role, PhoneNumber=phone)
            db.add(new_person)
            db.commit()
            db.refresh(new_person)
            return f"User Created with ID: {new_person.ID}"
        except Exception as e:
            db.rollback()
            return f"Error: {e}"
        finally:
            db.close()

    @strawberry.mutation
    def delete_person(self, person_id: int) -> str:
        db = SessionLocal()
        try:
            # This query starts the transaction automatically
            person = db.query(PersonORM).filter_by(ID=person_id).first()
            if not person:
                return "Error: User not found."

            name = person.Name

            # --- SAFE DELETE ORDER ---
            sql_statements = [
                # 1. Dependents (Tables referencing Person/Youth)
                "DELETE FROM SmallGroupMembers WHERE YouthID = :id",
                "DELETE FROM OneTimeEventYouth WHERE YouthID = :id",
                "DELETE FROM Attendance WHERE StudentID = :id",
                "DELETE FROM MedicalInfo WHERE YouthID = :id",
                "DELETE FROM PermissionWaiver WHERE YouthID = :id OR PersonID = :id",

                # 2. Roles
                "DELETE FROM YouthPastor WHERE PersonID = :id",
                "DELETE FROM Leader WHERE PersonID = :id",
                "DELETE FROM Volunteer WHERE PersonID = :id",

                # 3. Youth Specific
                "DELETE FROM Youth WHERE PersonID = :id",

                # 4. Parent Specific (Unlink children first)
                "UPDATE Youth SET ParentGuardianID = NULL WHERE ParentGuardianID = :id",
                "DELETE FROM ParentGuardian WHERE PersonID = :id"
            ]

            # Execute statements within the existing transaction
            for statement in sql_statements:
                db.execute(text(statement), {"id": person_id})

            # Delete the main Person record
            db.delete(person)

            # Commit the single transaction containing all updates
            db.commit()

            # Clean up MongoDB Profile
            if student_profiles_collection is not None:
                student_profiles_collection.delete_one({"studentId": person_id})

            return f"Successfully deleted user: {name}"
        except Exception as e:
            db.rollback()
            return f"Error deleting user: {str(e)}"
        finally:
            db.close()

    @strawberry.mutation
    def end_event(self, event_id: int) -> str:
        if redis_client is None: return "Redis Error"
        db = SessionLocal()
        try:
            key_roster = f"event:{event_id}:checkedIn"
            ids = redis_client.smembers(key_roster)
            count = 0
            with db.begin():
                for s_id in ids:
                    exists = db.query(AttendanceORM).filter_by(EventID=event_id, StudentID=int(s_id)).first()
                    if not exists:
                        db.add(AttendanceORM(EventID=event_id, StudentID=int(s_id), Status="Present"))
                        count += 1
                event = db.query(EventTypeORM).filter_by(ID=event_id).first()
                if event: event.Status = "Ended"
            db.commit()

            redis_client.delete(key_roster)
            redis_client.delete(f"event:{event_id}:checkInTimes")
            redis_client.delete(f"event:{event_id}:checkOutTimes")
            redis_client.delete(f"event:{event_id}:rsvp")
            redis_client.delete(f"event:{event_id}:status")
            return f"Event Ended. {count} records saved."
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
    host = "127.0.0.1:8005"
    return {"GraphQL": f"http://{host}/graphql", "Leader": f"http://{host}/frontend/leader",
            "Guest": f"http://{host}/frontend/guest"}


@app.get("/frontend/leader", response_class=HTMLResponse)
def serve_leader():
    with open("html_files/leader.html", "r", encoding="utf-8") as f: return f.read()


@app.get("/frontend/guest", response_class=HTMLResponse)
def serve_guest():
    with open("html_files/guest.html", "r", encoding="utf-8") as f: return f.read()


if __name__ == "__main__":
    try:
        engine.connect().close()
        print("STARTUP CHECK: MySQL connection successful.")
    except:
        pass
    uvicorn.run(app, host="127.0.0.1", port=8005)