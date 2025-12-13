# CS-125-Project
### Our final project for CS-125 Database Design Fall 2025

---

## Authors
- ### Andrew Krahn
- ### Brevin Tating
---
# Youth Group Ministry

A full-stack event, attendance, and leadership management system designed for youth ministries.  
Built to support youth leaders, volunteers, parents/guardians, and students ages 10–21.

---

##  Who Uses This Platform?

### **Primary Users**
- Youth pastors  
- Youth leaders  
- Administrators  

### **Secondary Users**
- Volunteers  
- Parents & guardians  
- Students (ages 10–21)

---

##  What Users Want to Do

### **Students / Youths**
- Attend youth group meetings, events, workshops, and retreats  
- Register for upcoming events  
- View schedules and attendance history  
- Sign up to volunteer (tech team, café, outreach)  
- Apply for roles (student leader, worship team member, etc.)

### **Leaders / Volunteers**
- Check students in/out of events in real-time  
- Create and manage events, workshops, and small groups  
- Add and edit meeting notes (stored in MongoDB)  
- View live attendance dashboards (powered by Redis)  
- Review event history and participation  

### **Parents / Guardians**
- Register their students for events  
- View attendance logs and upcoming schedules  

---

##  Permissions & Capabilities

### **Students Should Be Able To**
- Create an account (or be added by a leader)  
- View and register for events  
- Join small groups  
- Participate in check-in/out via QR code or leader confirmation  

### **Leaders Should Be Able To**
- Manage people, events, and small groups  
- Record attendance and notes  
- Access live dashboards (via Redis)  
- Search and filter people and events  

### **Parents Should Be Able To**
- Register their students for events  
- Update emergency contact info  
- View schedules and attendance  

---

##  What Users Should *Not* Be Able To Do

### **Students Should NOT**
- Edit event details  
- Change attendance records  
- Access leader-only notes  
- See MongoDB notes unless marked “public”  

### **Parents Should NOT**
- Edit student profiles (except emergency contact info)  
- Access other students’ data  

### **Volunteers (Non-Leaders) Should NOT**
- Access admin-only dashboards  
- Manage user accounts  

---

##  Team
**DuckKnights**

---

## Architecture

* **MySQL:** Stores student roster (Relational Data).
* **MongoDB:** Stores meeting notes (Document Data).
* **Redis:** Stores live check-in status (Key-Value Data).
* **GraphQL (Strawberry):** Unified API layer.

## How to Run

### 1. Prerequisites
- Docker Desktop (running)
- Python 3.10+
- A .env file that includes all MySQL and Redis information needed
```bash
# MYSQL Information
MYSQL_USER = user
MYSQL_PASSWORD = password
MYSQL_HOST = host
MYSQL_PORT = port
MYSQL_DATABASE = database

# Redis Information
REDIS_HOST= host
REDIS_PORT= port
REDIS_PASSWORD = password
REDIS_USER = user

# Mongo Information
MONGO_HOST = host (set to localhost)
```


### 2. Start Databases (Docker)
Ensure Docker Desktop is running, then start the database containers:
```bash
docker-compose up -d 
```
##### Note: Wait approximately 30 seconds after starting for MySQL to initialize and populate the seed data.

### 3. Setup & Run Backend:
Install the required dependencies from the requirements file:
```bash
pip install -r requirements.txt
```

Start the server:
```bash
python3 main.py
```
### 4. Test API:

#### Leader Portal
URL: http://127.0.0.1:8005/frontend/leader
- Login as a Leader or Pastor.
- Manage events, view the live roster, and access the "Danger Zone" for administrative tasks.

#### Guest Portal
URL: http://127.0.0.1:8005/frontend/guest
- Login as a Student,Parent, or volunteer.
- Search for events, RSVP, and edit medical profiles.

#### GraphQL Playground
URL: http://127.0.0.1:8005/graphql
- Interactive interface to test API queries and mutations.

Sample Query (Reads from MySQL & Redis):

```bash
query {
  people {
    id
    name
    role
  }
  eventLiveRoster(eventId: 1)
}
```

Sample Mutation (Writes to Redis):
```bash
mutation {
  checkInStudent(eventId: 1, studentId: 19)
}
```

Sample Mutation (Writes to MongoDB):
```bash
mutation {
  updateStudentProfile(studentId: 19, dataJson: "{\"allergies\": \"Peanuts\", \"contactName\": \"Mom\"}")
}
```

