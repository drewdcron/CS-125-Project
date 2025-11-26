# main.py
# Main file to run fastapi server
# @author Brevin Tating btating@westmont.edu
# @author Andrew Krahn akrahn@westmont.edu

from fastapi import FastAPI
from typing import List, Dict
from pymongo import MongoClient
import uvicorn

# Initialize Client (using env var from docker-compose)
mongo_client = MongoClient("mongodb://mongo:27017")
mongo_db = mongo_client["ygms_mongo_db"]
notes_collection = mongo_db["meeting_notes"]

app = FastAPI(
    title="Youth Group Management System API",
    version="1.0.0"
)

@app.get("/")
def read_root():
    return {"message": "Welcome to the Youth Group Management System Backend API!"}


@app.get("/people", response_model=List[Dict])
def get_all_people():
    # TODO: Implement connection to MySQL and fetch data
    # For now, return mock data
    mock_data = [
        {"id": 1, "name": "Alice Johnson", "role": "Student"},
        {"id": 2, "name": "Pastor Bob", "role": "Leader"}
    ]
    return mock_data

@app.post("/api/v1/notes")
def create_meeting_note(note: dict):
    # MongoDB stores JSON-like dictionaries directly
    result = notes_collection.insert_one(note)
    return {"id": str(result.inserted_id), "message": "Note saved to MongoDB!"}

if __name__ == "__main__":
    # You will typically run this via Uvicorn command in production/docker,
    # but this is useful for local development:
    uvicorn.run(app, host="127.0.0.1", port=8000)

