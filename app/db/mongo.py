from pymongo import MongoClient
from app.core.config import settings

mongo_client = MongoClient(f"mongodb://{settings.MONGO_HOST}:27017")
mongo_db = mongo_client["ygms_mongo_db"]
notes_collection = mongo_db["meeting_notes"]