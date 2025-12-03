import uvicorn
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import HTMLResponse
from strawberry.fastapi import GraphQLRouter

from app.graphql.schema import schema
from app.db.mysql import Base, engine

# Create all database tables
Base.metadata.create_all(bind=engine)

app = FastAPI(title="YGMS Unified API")

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Mount GraphQL
graphql_app = GraphQLRouter(schema)
app.include_router(graphql_app, prefix="/graphql")

@app.get("/")
def read_root():
    return {"message": "YGMS Backend Running"}

@app.get("/frontend", response_class=HTMLResponse)
def serve_frontend():
    with open("../frontend.html", "r", encoding="utf-8") as f:
        return f.read()

if __name__ == "__main__":
    uvicorn.run("app.main:app", host="0.0.0.0", port=8000, reload=True)
