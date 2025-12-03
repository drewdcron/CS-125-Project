from app.db.mysql import Base
from sqlalchemy import Column, Integer, String

class PersonORM(Base):
    __tablename__ = "Person"
    ID = Column(Integer, primary_key=True)
    Name = Column(String(255))
    Email = Column(String(100))


# EventType Table (Links MySQL ID to Mongo Schema)
class EventTypeORM(Base):
    __tablename__ = "EventType"
    ID = Column(Integer, primary_key=True, autoincrement=True)
    Name = Column(String(100), unique=True)

class EventORM(Base):
    __tablename__ = "Event"
    ID = Column(Integer, primary_key=True, index=True)
    # Ensure this matches your SQL schema columns
    Name = Column(String(255))
    Date = Column(String(50))
    Status = Column(String(50), default="PLANNED") # <--- The new column

class AttendanceLogORM(Base):
    __tablename__ = "AttendanceLog"
    ID = Column(Integer, primary_key=True, index=True)
    EventID = Column(Integer)
    YouthID = Column(Integer)
    CheckInTime = Column(String(50))