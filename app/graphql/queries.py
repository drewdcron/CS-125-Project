from typing import List, Optional
import strawberry
from app.db.mysql import SessionLocal
from app.models.sql_models import PersonORM, EventORM
from app.graphql.types import PersonType, EventType, EventTypeSchema
from app.db.redis_db import redis_client
from app.db.mongo import mongo_db

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

    @strawberry.field
    def events(self) -> List[EventType]:
        db = SessionLocal()
        try:
            events_orm = db.query(EventORM).all()
            return [EventType(id=e.ID, name=e.Name, status=e.Status, date=e.Date) for e in events_orm]
        finally:
            db.close()

    @strawberry.field
    def event_attendees(self, event_id: int) -> List[int]:
        if not redis_client: return []
        key = f"event:{event_id}:checkedIn"
        members = redis_client.smembers(key)
        return [int(m) for m in members]

    @strawberry.field
    def is_user_checked_in(self, event_id: int, youth_id: int) -> bool:
        if not redis_client: return False
        key = f"event:{event_id}:checkedIn"
        return redis_client.sismember(key, youth_id)

    @strawberry.field
    def event_attendee_count(self, event_id: int) -> int:
        if not redis_client: return 0
        key = f"event:{event_id}:checkedIn"
        return redis_client.scard(key)
    
    @strawberry.field
    def event(self, event_id: int) -> Optional[EventType]:
        db = SessionLocal()
        try:
            event_orm = db.query(EventORM).filter(EventORM.ID == event_id).first()
            if event_orm:
                return EventType(id=event_orm.ID, name=event_orm.Name, status=event_orm.Status, date=event_orm.Date)
            return None
        finally:
            db.close()

    @strawberry.field
    def event_type_schema(self, type_id: int) -> Optional[EventTypeSchema]:
        doc = mongo_db["event_types"].find_one({"type_id": type_id})
        if doc:
            return EventTypeSchema(id=doc["type_id"], name=doc["type_name"])
        return None
