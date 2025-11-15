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

##  Suggested Repository Structure
- TBD

