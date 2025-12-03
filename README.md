git # CS-125-Project
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

This project is fully containerized, so you only need Docker to run everything.

### 1. Prerequisites
- **Docker** and **Docker Compose** must be installed and running.

### 2. Environment Variables
Before starting, you need to create a `.env` file to store database credentials. You can do this by copying the example file:
```bash
cp .env_example .env
```
Feel free to review and change the default passwords in the `.env` file.

### 3. Build and Run
With Docker running, execute the following command from the project root directory:
```bash
docker-compose up --build
```
> **Note:** If you have old containers running from a previous attempt, you may want to stop and remove them first with `docker-compose down`.

This command will:
1.  Build the Docker image for the backend service.
2.  Start containers for the backend, MySQL, MongoDB, and Redis.
3.  Automatically initialize the MySQL database with the schema and data from the `sql_files` directory.

The backend API will be available at `http://localhost:8000`.

### 4. Test the API

#### Option A: Interactive Dashboard
Navigate to the following URL in your web browser to use the simple frontend dashboard:
- **URL:** `http://localhost:8000/frontend`

#### Option B: GraphQL Interface
Access the interactive GraphQL IDE (GraphiQL) to run queries and mutations directly:
- **URL:** `http://localhost:8000/graphql`

**Sample Query (Get event status and attendees):**
```graphql
query {
  event(eventId: 1) {
    id
    name
    status
    date
  }
  eventAttendees(eventId: 1)
  eventAttendeeCount(eventId: 1)
}
```

**Sample Mutation (Check a user in):**
```graphql
mutation {
  check_in_user(eventId: 1, youthId: 1)
}
```

