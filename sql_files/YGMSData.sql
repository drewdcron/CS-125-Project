-- YGMSData.sql
-- Description: Expanded data file with 40 people and comprehensive relationships.
-- Use this file to re-seed your ygms_db.

create database if not exists ygms_db;
USE ygms_db;

-- =========================================================
-- 0. THE NUCLEAR CLEANUP (Strict Order)
-- =========================================================
-- Drop junction tables first, then dependent tables, then base tables.
DROP TABLE IF EXISTS PermissionWaiverEvent;
DROP TABLE IF EXISTS PermissionWaiver;
DROP TABLE IF EXISTS OneTimeEventYouth;
DROP TABLE IF EXISTS SmallGroupMembers;
DROP TABLE IF EXISTS MedicalInfo;
DROP TABLE IF EXISTS Meeting;
DROP TABLE IF EXISTS SmallGroup;
DROP TABLE IF EXISTS OneTimeEvent;
DROP TABLE IF EXISTS Youth;
DROP TABLE IF EXISTS ParentGuardian;
DROP TABLE IF EXISTS Volunteer;
DROP TABLE IF EXISTS Leader;
DROP TABLE IF EXISTS YouthPastor;
DROP TABLE IF EXISTS Attendance;
DROP TABLE IF EXISTS EventType;
DROP TABLE IF EXISTS Event;
DROP TABLE IF EXISTS Person;

-- =========================================================
-- 1. RE-CREATE TABLES (Necessary for safe data insertion)
-- =========================================================

CREATE TABLE Person (
    ID INT AUTO_INCREMENT PRIMARY KEY,
    Name VARCHAR(255) NOT NULL,
    Email VARCHAR(100),
    PhoneNumber VARCHAR(20),
    Role VARCHAR(50) DEFAULT 'Student'
);

CREATE TABLE EventType (
    ID INT AUTO_INCREMENT PRIMARY KEY,
    Name VARCHAR(100) UNIQUE,
    Status VARCHAR(50) DEFAULT 'Active',
    Type VARCHAR(50),
    Location VARCHAR(255),
    Time DATETIME,
    Description VARCHAR(255)
);

CREATE TABLE Attendance (
    ID INT AUTO_INCREMENT PRIMARY KEY,
    EventID INT,
    StudentID INT,
    Status VARCHAR(50)
);

CREATE TABLE YouthPastor ( PersonID INT PRIMARY KEY, HireDate DATE, FOREIGN KEY (PersonID) REFERENCES Person(ID) );
CREATE TABLE Leader ( PersonID INT PRIMARY KEY, FOREIGN KEY (PersonID) REFERENCES Person(ID) );
CREATE TABLE Volunteer ( PersonID INT PRIMARY KEY, Specialty VARCHAR(100), FOREIGN KEY (PersonID) REFERENCES Person(ID) );
CREATE TABLE ParentGuardian ( PersonID INT PRIMARY KEY, RelationshipToYouth VARCHAR(50), FOREIGN KEY (PersonID) REFERENCES Person(ID) );
CREATE TABLE Youth ( PersonID INT PRIMARY KEY, ParentGuardianID INT, GradeLevel INT, BirthDate DATE, FOREIGN KEY (PersonID) REFERENCES Person(ID), FOREIGN KEY (ParentGuardianID) REFERENCES ParentGuardian(PersonID) );
CREATE TABLE MedicalInfo ( YouthID INT PRIMARY KEY, Info TEXT, FOREIGN KEY (YouthID) REFERENCES Youth(PersonID) );
CREATE TABLE Event ( ID INT AUTO_INCREMENT PRIMARY KEY, Date DATE, Time TIME, Location VARCHAR(255), MaxCapacity INT );
CREATE TABLE OneTimeEvent ( EventID INT PRIMARY KEY, Name VARCHAR(255), Description TEXT, Cost DECIMAL(10,2), IsRegistrationRequired BOOLEAN, FOREIGN KEY (EventID) REFERENCES Event(ID) );
CREATE TABLE SmallGroup ( EventID INT PRIMARY KEY, LeaderID INT, Theme VARCHAR(255), DayOfWeek VARCHAR(10), FOREIGN KEY (EventID) REFERENCES Event(ID), FOREIGN KEY (LeaderID) REFERENCES Leader(PersonID) );
CREATE TABLE Meeting ( EventID INT PRIMARY KEY, MainTopic VARCHAR(255), FOREIGN KEY (EventID) REFERENCES Event(ID) );
CREATE TABLE SmallGroupMembers ( SmallGroupID INT, YouthID INT, DateJoined DATE, PRIMARY KEY (SmallGroupID, YouthID), FOREIGN KEY (SmallGroupID) REFERENCES SmallGroup(EventID), FOREIGN KEY (YouthID) REFERENCES Youth(PersonID) );
CREATE TABLE OneTimeEventYouth ( OneTimeEventID INT, YouthID INT, RegistrationStatus VARCHAR(50), PRIMARY KEY (OneTimeEventID, YouthID), FOREIGN KEY (OneTimeEventID) REFERENCES OneTimeEvent(EventID), FOREIGN KEY (YouthID) REFERENCES Youth(PersonID) );
CREATE TABLE PermissionWaiver ( ID INT AUTO_INCREMENT PRIMARY KEY, YouthID INT, PersonID INT, DocumentType VARCHAR(100), DateSigned DATE, DateExpires DATE, Status VARCHAR(50), FOREIGN KEY (YouthID) REFERENCES Youth(PersonID), FOREIGN KEY (PersonID) REFERENCES Person(ID) );
CREATE TABLE PermissionWaiverEvent ( EventID INT, PermissionWaiverID INT, IsRequired BOOLEAN, PRIMARY KEY (EventID, PermissionWaiverID), FOREIGN KEY (EventID) REFERENCES Event(ID), FOREIGN KEY (PermissionWaiverID) REFERENCES PermissionWaiver(ID) );

-- Reset ID sequence for safe insertion
ALTER TABLE Person AUTO_INCREMENT = 1;


-- =========================================================
-- 2. PERSON AND RELATED TABLES (40 Total Records)
-- =========================================================

-- IDs 1-3: Pastors/Admin
INSERT INTO Person (ID, Name, Email, PhoneNumber, Role) VALUES
(1, 'Pastor John Doe', 'john.doe@ygms.com', '555-0101', 'Youth Pastor'),
(2, 'Pastor Sarah Chen', 'sarah.chen@ygms.com', '555-0102', 'Youth Pastor'),
(3, 'Admin Terry', 'terry.a@ygms.com', '555-8001', 'Admin');

-- IDs 4-8: Leaders
INSERT INTO Person (ID, Name, Email, PhoneNumber, Role) VALUES
(4, 'Jane Smith (Leader)', 'jane.smith@ygms.com', '555-0104', 'Leader'),
(5, 'Robert Brown (Leader)', 'robert.brown@ygms.com', '555-0105', 'Leader'),
(6, 'Tom Wilson (Leader)', 'tom.w@leader.org', '555-3001', 'Leader'),
(7, 'Kelly Roy (Leader)', 'kelly.r@leader.org', '555-3002', 'Leader'),
(8, 'Mia Vasquez (Leader)', 'mia.v@leader.org', '555-3004', 'Leader');

-- IDs 9-13: Volunteers
INSERT INTO Person (ID, Name, Email, PhoneNumber, Role) VALUES
(9, 'Frank Miller (Volunteer)', 'frank.miller@example.com', '555-0109', 'Volunteer'),
(10, 'Jen Parker (Volunteer)', 'jen.p@volunteer.org', '555-4001', 'Volunteer'),
(11, 'Sam Adams (Volunteer)', 'sam.a@volunteer.org', '555-4002', 'Volunteer'),
(12, 'Victor Liu (Volunteer)', 'victor.l@volunteer.org', '555-4003', 'Volunteer'),
(13, 'Security Head', 'sec.head@ygms.org', '555-6001', 'Security');

-- IDs 14-18: Parents/Guardians
INSERT INTO Person (ID, Name, Email, PhoneNumber, Role) VALUES
(14, 'Eve Wilson (Parent)', 'eve.wilson@example.com', '555-0114', 'ParentGuardian'), -- Parent of 19, 20
(15, 'Rachel A. (Parent)', 'rachel.a@parent.org', '555-5001', 'ParentGuardian'),   -- Parent of 21, 22
(16, 'David B. (Parent)', 'david.b@parent.org', '555-5002', 'ParentGuardian'),     -- Parent of 23
(17, 'Maria P. (Parent)', 'maria.p@parent.org', '555-5003', 'ParentGuardian'),     -- Parent of 24
(18, 'Mr. Kim (Guardian)', 'mr.kim@guardian.org', '555-5004', 'ParentGuardian');   -- Parent of 25

-- IDs 19-40: Youth/Students (22 Records)
INSERT INTO Person (ID, Name, Email, PhoneNumber, Role) VALUES
-- Grade 12 (4)
(19, 'Alice Johnson', 'alice.johnson@example.com', '555-0119', 'Youth'),
(20, 'Bob Williams', 'bob.williams@example.com', '555-0120', 'Youth'),
(21, 'Emily White', 'emily.white@youth.org', '555-0121', 'Youth'),
(22, 'Jacob Hall', 'jacob.hall@youth.org', '555-0122', 'Youth'),
-- Grade 11 (6)
(23, 'Charlie Davis', 'charlie.davis@example.com', '555-0123', 'Youth'),
(24, 'Fiona Grant', 'fiona.grant@youth.org', '555-0124', 'Youth'),
(25, 'Kevin Lopez', 'kevin.l@youth.org', '555-0125', 'Youth'),
(26, 'Laura Miller', 'laura.m@youth.org', '555-0126', 'Youth'),
(27, 'Mark Nelson', 'mark.n@youth.org', '555-0127', 'Youth'),
(28, 'Nora Oliver', 'nora.o@youth.org', '555-0128', 'Youth'),
-- Grade 10 (6)
(29, 'Alex Johnson', 'alex.j@youth.org', '555-0129', 'Youth'),
(30, 'Brenda Lee', 'brenda.l@youth.org', '555-0130', 'Youth'),
(31, 'Caleb Smith', 'caleb.s@youth.org', '555-0131', 'Youth'),
(32, 'Diana Green', 'diana.g@youth.org', '555-0132', 'Youth'),
(33, 'Ethan Wong', 'ethan.w@youth.org', '555-0133', 'Youth'),
(34, 'Grace King', 'grace.k@youth.org', '555-0134', 'Youth'),
-- Grade 9 (6)
(35, 'Liam Parris', 'liam.p@youth.org', '555-0135', 'Youth'),
(36, 'Chloe Scott', 'chloe.s@youth.org', '555-0136', 'Youth'),
(37, 'Ryan Turner', 'ryan.t@youth.org', '555-0137', 'Youth'),
(38, 'Sophia Vega', 'sophia.v@youth.org', '555-0138', 'Youth'),
(39, 'Tyler Wood', 'tyler.w@youth.org', '555-0139', 'Youth'),
(40, 'Zoe Young', 'zoe.y@youth.org', '555-0140', 'Youth');


-- === ROLE-SPECIFIC TABLE POPULATION ===
INSERT INTO YouthPastor (PersonID, HireDate) VALUES (1, '2022-01-15'), (2, '2024-06-01');
INSERT INTO Leader (PersonID) VALUES (4), (5), (6), (7), (8);
INSERT INTO Volunteer (PersonID, Specialty) VALUES
(9, 'Audio/Visual'),
(10, 'Hospitality'),
(11, 'Transportation'),
(12, 'First Aid'),
(13, 'Security');

INSERT INTO ParentGuardian (PersonID, RelationshipToYouth) VALUES
(14, 'Mother'),
(15, 'Father'),
(16, 'Mother'),
(17, 'Guardian'),
(18, 'Father');

-- === YOUTH TABLE POPULATION (Linking Youth to Parents) ===
INSERT INTO Youth (PersonID, ParentGuardianID, GradeLevel, BirthDate) VALUES
(19, 14, 12, '2008-05-20'), -- Alice
(20, 14, 12, '2008-11-11'), -- Bob (Siblings)
(21, 15, 12, '2007-08-01'), -- Emily
(22, 16, 12, '2008-03-15'), -- Jacob
(23, 15, 11, '2009-01-05'), -- Charlie
(24, 17, 11, '2009-07-28'), -- Fiona
(25, 18, 11, '2009-10-10'), -- Kevin
(26, 14, 11, '2009-04-04'), -- Laura (Another Sibling)
(27, 15, 10, '2010-06-12'), -- Mark
(28, 16, 10, '2010-02-02'), -- Nora
(29, 17, 10, '2010-09-09'), -- Alex
(30, 18, 10, '2010-12-01'), -- Brenda
(31, 14, 9, '2011-03-20'),  -- Caleb
(32, 15, 9, '2011-04-15'),  -- Diana
(33, 16, 9, '2011-05-25'),  -- Ethan
(34, 17, 9, '2011-06-30'),  -- Grace
(35, 18, 9, '2011-07-07'),  -- Liam
(36, 14, 9, '2011-08-18'),  -- Chloe
(37, 15, 9, '2011-09-01'),  -- Ryan
(38, 16, 9, '2011-10-10'),  -- Sophia
(39, 17, 9, '2011-11-20'),  -- Tyler
(40, 18, 9, '2011-12-31');  -- Zoe

-- === MEDICAL INFO ===
INSERT INTO MedicalInfo (YouthID, Info) VALUES
(19, 'Allergic to peanuts. Requires EpiPen.'),
(20, 'Asthma, carries inhaler.'),
(23, 'Vegetarian diet.'),
(25, 'No known issues.'),
(36, 'Requires prescription medication daily.');


-- =========================================================
-- 3. EVENTS (The original tables, kept for schema completeness)
-- =========================================================

INSERT INTO Event (ID, Date, Time, Location, MaxCapacity) VALUES
(1, '2025-12-25', '18:00:00', 'Main Hall', 100), -- Christmas Party (OneTimeEvent)
(2, '2025-11-10', '19:00:00', 'Room 204', 15),  -- Small Group (Leader Jane Smith ID 4)
(3, '2025-11-12', '19:00:00', 'Room 205', 15),  -- Meeting
(4, '2025-11-15', '17:30:00', 'Gym', 50);       -- Basketball Night (OneTimeEvent)

INSERT INTO OneTimeEvent (EventID, Name, Description, Cost, IsRegistrationRequired) VALUES
(1, 'Youth Group Christmas Party', 'Annual celebration with food and games.', 10.00, TRUE),
(4, 'Basketball Night', 'Casual open gym.', 0.00, FALSE);

INSERT INTO SmallGroup (EventID, LeaderID, Theme, DayOfWeek) VALUES
(2, 4, 'Book of Mark', 'Monday'); -- Leader ID 4: Jane Smith

INSERT INTO Meeting (EventID, MainTopic) VALUES
(3, 'Q1 2026 Budget Review');


-- =========================================================
-- 4. EVENTTYPE (The application's core event registry)
-- =========================================================

INSERT INTO EventType (ID, Name, Status, Type, Location, Time, Description) VALUES
(
    1,
    'Youth Group Christmas Party',
    'Active',
    'One-Time Event',
    'Main Hall',
    '2025-12-25 18:00:00',
    '{"generic": "Annual celebration with food and games.", "specialized": {"Cost": "10.00", "RegistrationRequired": true}}'
),
(
    2,
    'Small Group - Book of Mark (Jane)',
    'Active',
    'Small Group',
    'Room 204',
    '2025-12-16 19:00:00', -- Next Monday
    '{"generic": "Weekly small group study.", "specialized": {"LeaderID": 4, "Theme": "Book of Mark", "DayOfWeek": "Monday"}}'
),
(
    3,
    'Leader Planning Meeting',
    'Active',
    'Meeting',
    'Room 205',
    '2025-12-18 19:00:00', -- Next Wednesday
    '{"generic": "Quarterly budget review and scheduling.", "specialized": {"MainTopic": "Q1 2026 Budget"}}'
),
(
    4,
    'Basketball Night',
    'Active',
    'One-Time Event',
    'Gym',
    '2025-12-19 17:30:00', -- Next Friday
    '{"generic": "Open gym for all students. Wear appropriate shoes.", "specialized": {"Cost": "0.00", "RegistrationRequired": false}}'
);

-- =========================================================
-- 5. JUNCTION DATA (Expanded)
-- =========================================================

-- Attendance for Christmas Party (Event ID 1)
INSERT INTO Attendance (EventID, StudentID, Status) VALUES
(1, 19, 'Present'), -- Alice
(1, 20, 'Present'), -- Bob
(1, 23, 'Absent'),  -- Charlie
(1, 29, 'Present'), -- Alex
(1, 30, 'Present'); -- Brenda

-- Small Group Members (Small Group ID 2, Leader ID 4)
INSERT INTO SmallGroupMembers (SmallGroupID, YouthID, DateJoined) VALUES
(2, 19, '2025-11-01'), -- Alice (G12)
(2, 20, '2025-11-01'), -- Bob (G12)
(2, 23, '2025-11-01'), -- Charlie (G11)
(2, 29, '2025-11-01'), -- Alex (G10)
(2, 35, '2025-11-15'), -- Liam (G9)
(2, 36, '2025-11-15'); -- Chloe (G9)

-- One Time Event Registration (Christmas Party ID 1)
INSERT INTO OneTimeEventYouth (OneTimeEventID, YouthID, RegistrationStatus) VALUES
(1, 19, 'Registered'),
(1, 20, 'Registered'),
(1, 21, 'Pending'),
(1, 22, 'Registered'),
(1, 29, 'Registered'),
(1, 30, 'Registered');

-- Permissions/Waivers (Example for Youth 19: Alice Johnson)
INSERT INTO PermissionWaiver (YouthID, PersonID, DocumentType, DateSigned, DateExpires, Status) VALUES
(19, 14, 'General Release', '2025-01-01', '2026-01-01', 'Valid'),
(19, 14, 'Medical Consent', '2025-01-01', '2026-01-01', 'Valid');

INSERT INTO PermissionWaiverEvent (EventID, PermissionWaiverID, IsRequired) VALUES
(1, 1, TRUE); -- Christmas Party requires General Release Waiver (Waiver ID 1)