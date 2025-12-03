import json
from datetime import datetime
import strawberry
from app.db.mysql import SessionLocal
from app.models.sql_models import EventTypeORM, EventORM, AttendanceLogORM, PersonORM
from app.db.mongo import mongo_db
from app.db.redis_db import redis_client

# CRITICAL FIX 1: Import the Strawberry Type, not just the ORM model
from app.graphql.types import EventType


@strawberry.type
class Mutation:
    @strawberry.mutation
    def create_event_type(self, name: str, schema_json: str) -> str:
        db = SessionLocal()
        try:
            new_type = EventTypeORM(Name=name)
            db.add(new_type)
            db.commit()
            db.refresh(new_type)

            mongo_doc = {
                "type_id": new_type.ID,
                "type_name": name,
                "fields": json.loads(schema_json)
            }
            mongo_db["event_types"].insert_one(mongo_doc)
            return f"Created Event Type '{name}' (ID: {new_type.ID})"
        except Exception as e:
            return f"Error: {str(e)}"
        finally:
            db.close()

    @strawberry.mutation
    def delete_event_type(self, name: str) -> str:
        db = SessionLocal()
        try:
            event_type_to_delete = db.query(EventTypeORM).filter(EventTypeORM.Name == name).first()
            if not event_type_to_delete:
                db.close()
                return f"Event Type '{name}' not found."

            type_id = event_type_to_delete.ID
            mongo_db["event_types"].delete_one({"type_id": type_id})
            db.delete(event_type_to_delete)
            db.commit()

            return f"Successfully deleted Event Type '{name}' (ID: {type_id})."
        except Exception as e:
            db.rollback()
            return f"Error: {str(e)}"
        finally:
            db.close()

    @strawberry.mutation
    def update_event_type_schema(self, type_id: int, schema_json: str) -> str:
        try:
            updates = {"$set": {"fields": json.loads(schema_json)}}
            result = mongo_db["event_types"].update_one({"type_id": type_id}, updates)
            if result.modified_count > 0:
                return f"Updated schema for event type {type_id}"
            return f"Event type {type_id} not found or schema unchanged."
        except Exception as e:
            return f"Error: {str(e)}"

    @strawberry.mutation
    def add_custom_event_data(self, event_id: int, type_id: int, data_json: str) -> str:
        try:
            doc = {
                "event_id": event_id,
                "type_id": type_id,
                "data": json.loads(data_json)
            }
            mongo_db["eventCustomData"].insert_one(doc)
            return f"Added custom data for event {event_id}"
        except Exception as e:
            return f"Error: {str(e)}"

    @strawberry.mutation
    def open_event(self, event_id: int) -> str:
        db = SessionLocal()
        event = db.query(EventORM).filter(EventORM.ID == event_id).first()
        if event:
            event.Status = "OPEN"
            db.commit()
            db.close()
            return f"Event {event_id} is now OPEN."
        return "Event not found."

    @strawberry.mutation
    def check_in_user(self, event_id: int, youth_id: int) -> str:
        if not redis_client: return "Redis Error"

        # VALIDATION: Check user exists in SQL before adding to Redis
        db = SessionLocal()
        person = db.query(PersonORM).filter(PersonORM.ID == youth_id).first()
        db.close()

        if not person:
            return f"Error: Youth ID {youth_id} does not exist."

        key = f"event:{event_id}:checkedIn"
        redis_client.sadd(key, youth_id)
        return f"Youth {youth_id} checked into Event {event_id}."

    @strawberry.mutation
    def check_out_user(self, event_id: int, youth_id: int) -> str:
        if not redis_client: return "Redis Error"
        key = f"event:{event_id}:checkedIn"
        redis_client.srem(key, youth_id)
        return f"Youth {youth_id} checked out from Event {event_id}."

    @strawberry.mutation
    def close_event(self, event_id: int) -> str:
        db = SessionLocal()
        event = db.query(EventORM).filter(EventORM.ID == event_id).first()

        if not event or event.Status != "OPEN":
            db.close()
            return "Cannot close: Event not found or not open."

        key = f"event:{event_id}:checkedIn"
        attendees = redis_client.smembers(key)

        count = 0
        try:
            for youth_id in attendees:
                # Prevent duplicate logs
                exists = db.query(AttendanceLogORM).filter_by(EventID=event_id, YouthID=int(youth_id)).first()
                if not exists:
                    log = AttendanceLogORM(
                        EventID=event_id,
                        YouthID=int(youth_id),
                        CheckInTime=str(datetime.now())
                    )
                    db.add(log)
                    count += 1

            event.Status = "CLOSED"
            db.commit()  # SAFETY: Commit to SQL *before* deleting from Redis

            # Now safe to delete
            redis_client.delete(key)
            return f"Event closed. Moved {count} attendees from Redis to MySQL."

        except Exception as e:
            db.rollback()
            return f"Error closing event: {str(e)}"
        finally:
            db.close()

    # CRITICAL FIX 2: Return EventType (Strawberry), NOT EventORM (SQLAlchemy)
    @strawberry.mutation
    def create_event(self, name: str, description: str, date: str, location: str) -> EventType:
        db = SessionLocal()
        try:
            new_event = EventORM(
                Name=name,
                Description=description,
                Date=date,
                Location=location,
                Status="UPCOMING"
            )
            db.add(new_event)
            db.commit()
            db.refresh(new_event)

            # CRITICAL FIX 3: Manually map the ORM object to the Strawberry Type
            return EventType(
                id=new_event.ID,
                name=new_event.Name,
                description=new_event.Description,
                location=new_event.Location,
                status=new_event.Status,
                date=new_event.Date
            )
        except Exception as e:
            db.rollback()
            raise e
        finally:
            db.close()

    @strawberry.mutation
    def check_in_by_name(self, event_id: int, name: str) -> str:
        db = SessionLocal()
        try:
            person = db.query(PersonORM).filter(PersonORM.Name == name).first()
            if not person:
                return "User not found"

            if not redis_client:
                return "Redis Error"

            key = f"event:{event_id}:checkedIn"
            redis_client.sadd(key, person.ID)
            return f"Youth {person.ID} checked into Event {event_id}."
        finally:
            db.close()