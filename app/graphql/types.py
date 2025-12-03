from typing import List, Optional
import strawberry
from strawberry.scalars import JSON
import json
from app.db.mongo import mongo_db

@strawberry.type
class PersonType:
    id: int
    name: str
    email: Optional[str]

@strawberry.type
class CustomField:
    key: str
    value: str

@strawberry.type
class EventType:
    id: int
    name: Optional[str]
    description: Optional[str]
    location: Optional[str]
    status: str
    date: str

    @strawberry.field
    def custom_data(self) -> List[CustomField]:
        doc = mongo_db["eventCustomData"].find_one({"event_id": self.id})
        if doc and "data" in doc:
            return [CustomField(key=k, value=str(v)) for k, v in doc["data"].items()]
        return []

@strawberry.type
class EventTypeSchema:
    id: int
    name: str
    
    @strawberry.field
    def fields(self) -> JSON:
        doc = mongo_db["event_types"].find_one({"type_id": self.id})
        if doc and "fields" in doc:
            return doc["fields"]
        return {}