-- YGMSData.sql
-- STRICT ORDER RESET

USE ygms_db;

-- =========================================================
-- 0. THE NUCLEAR CLEANUP
-- =========================================================
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
-- 1. RE-CREATE TABLES
-- =========================================================

CREATE TABLE Person (
    ID INT AUTO_INCREMENT PRIMARY KEY,
    Name VARCHAR(255) NOT NULL,
    Email VARCHAR(100),
    PhoneNumber VARCHAR(20),
    Role VARCHAR(50) DEFAULT 'Student'
);

-- Note the Status column for Soft Deletes
CREATE TABLE EventType (
    ID INT AUTO_INCREMENT PRIMARY KEY,
    Name VARCHAR(100) UNIQUE,
    Status VARCHAR(50) DEFAULT 'Active'
);

CREATE TABLE Attendance ( ID INT AUTO_INCREMENT PRIMARY KEY, EventID INT, StudentID INT, Status VARCHAR(50) );
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

-- =========================================================
-- 2. POPULATE SEED DATA (MASSIVE UPDATE)
-- =========================================================

-- --- 1. ADMINS (Pastors & Leaders) ---
INSERT INTO Person (Name, Email, Role) VALUES
('Pastor Mike', 'mike@ygms.com', 'Youth Pastor'),      -- 1
('Sarah Chen', 'sarah@ygms.com', 'Leader'),            -- 2
('John Miller', 'john@ygms.com', 'Leader'),            -- 3
('Pastor Emily', 'emily@ygms.com', 'Youth Pastor'),    -- 13 (New)
('Leader Alex', 'alex@ygms.com', 'Leader'),            -- 14 (New)
('Leader Jordan', 'jordan@ygms.com', 'Leader'),        -- 15 (New)
('Leader Taylor', 'taylor@ygms.com', 'Leader');        -- 16 (New)

INSERT INTO YouthPastor VALUES (1, '2020-01-01'), (13, '2022-06-15');
INSERT INTO Leader VALUES (2), (3), (14), (15), (16);

-- --- 2. VOLUNTEERS (Tech, Kitchen, Security) ---
INSERT INTO Person (Name, Email, Role) VALUES
('Volunteer Dave', 'dave@test.com', 'Volunteer'),      -- 6 (Existing)
('Volunteer Lisa', 'lisa@test.com', 'Volunteer'),      -- 17
('Volunteer Tom', 'tom@test.com', 'Volunteer'),        -- 18
('Volunteer Karen', 'karen@test.com', 'Volunteer'),    -- 19
('Volunteer Bob', 'bob@test.com', 'Volunteer');        -- 20

INSERT INTO Volunteer VALUES
(6, 'Audio/Visual'), (17, 'Kitchen/Snacks'), (18, 'Security'), (19, 'Check-In Desk'), (20, 'Worship Band');

-- --- 3. PARENTS ---
INSERT INTO Person (Name, Email, Role) VALUES
('Parent One', 'p1@test.com', 'Parent'),               -- 4
('Parent Two', 'p2@test.com', 'Parent'),               -- 5
('Mrs. Robinson', 'robinson@test.com', 'Parent'),      -- 21
('Mr. Garcia', 'garcia@test.com', 'Parent'),           -- 22
('Ms. Lee', 'lee@test.com', 'Parent'),                 -- 23
('Mr. Patel', 'patel@test.com', 'Parent'),             -- 24
('Mrs. Kim', 'kim@test.com', 'Parent'),                -- 25
('Mr. Johnson', 'johnson@test.com', 'Parent');         -- 26

INSERT INTO ParentGuardian VALUES
(4, 'Father'), (5, 'Mother'), (21, 'Mother'), (22, 'Father'),
(23, 'Mother'), (24, 'Father'), (25, 'Mother'), (26, 'Father');

-- --- 4. STUDENTS (Linked to Parents) ---
INSERT INTO Person (Name, Email, Role) VALUES
('Ethan Smith', 'ethan@test.com', 'Student'),          -- 7 (Parent 4)
('Olivia Jones', 'olivia@test.com', 'Student'),        -- 8 (Parent 4)
('Liam Brown', 'liam@test.com', 'Student'),            -- 9 (Parent 5)
('Emma Davis', 'emma@test.com', 'Student'),            -- 10 (Parent 5)
('Noah Wilson', 'noah@test.com', 'Student'),           -- 11 (Parent 4)
('Ava Johnson', 'ava@test.com', 'Student'),            -- 12 (Parent 5)
-- New Students
('Lucas Robinson', 'lucas@test.com', 'Student'),       -- 27 (Parent 21)
('Mia Robinson', 'mia@test.com', 'Student'),           -- 28 (Parent 21)
('Isabella Garcia', 'bella@test.com', 'Student'),      -- 29 (Parent 22)
('Mateo Garcia', 'mateo@test.com', 'Student'),         -- 30 (Parent 22)
('Sophia Lee', 'sophia@test.com', 'Student'),          -- 31 (Parent 23)
('Jackson Patel', 'jack@test.com', 'Student'),         -- 32 (Parent 24)
('Aiden Patel', 'aiden@test.com', 'Student'),          -- 33 (Parent 24)
('Chloe Kim', 'chloe@test.com', 'Student'),            -- 34 (Parent 25)
('Elijah Johnson', 'elijah@test.com', 'Student'),      -- 35 (Parent 26)
('Grace Johnson', 'grace@test.com', 'Student'),        -- 36 (Parent 26)
('Benji Button', 'benji@test.com', 'Student'),         -- 37 (Parent 21)
('Zoey Deschanel', 'zoey@test.com', 'Student'),        -- 38 (Parent 22)
('Hannah Montana', 'hannah@test.com', 'Student'),      -- 39 (Parent 23)
('Peter Parker', 'peter@test.com', 'Student'),         -- 40 (Parent 24)
('Miles Morales', 'miles@test.com', 'Student'),        -- 41 (Parent 25)
('Gwen Stacy', 'gwen@test.com', 'Student'),            -- 42 (Parent 26)
('Harry Potter', 'harry@test.com', 'Student'),         -- 43 (Parent 4)
('Ron Weasley', 'ron@test.com', 'Student');            -- 44 (Parent 5)

-- Youth Inserts (PersonID, ParentID, Grade, DOB)
INSERT INTO Youth VALUES
(7, 4, 10, '2008-05-15'), (8, 4, 11, '2007-08-20'), (9, 5, 9, '2009-02-10'),
(10, 5, 12, '2006-11-30'), (11, 4, 10, '2008-01-01'), (12, 5, 9, '2009-06-15'),
(27, 21, 8, '2010-03-12'), (28, 21, 10, '2008-07-22'),
(29, 22, 11, '2007-12-05'), (30, 22, 9, '2009-09-09'),
(31, 23, 12, '2006-05-14'), (32, 24, 7, '2011-02-28'),
(33, 24, 9, '2009-11-11'), (34, 25, 10, '2008-10-31'),
(35, 26, 8, '2010-01-20'), (36, 26, 11, '2007-04-04'),
(37, 21, 6, '2012-06-06'), (38, 22, 12, '2006-08-08'),
(39, 23, 8, '2010-09-09'), (40, 24, 11, '2007-10-10'),
(41, 25, 9, '2009-12-12'), (42, 26, 10, '2008-01-23'),
(43, 4, 7, '2011-07-31'), (44, 5, 7, '2011-03-01');

-- =========================================================
-- 3. EVENTS
-- =========================================================
INSERT INTO Event (Date, Time, Location, MaxCapacity) VALUES
('2025-12-25', '18:00:00', 'Main Hall', 100), -- 1
('2025-11-10', '19:00:00', 'Room 204', 15),  -- 2
('2025-11-12', '19:00:00', 'Room 205', 15),  -- 3
('2025-01-15', '18:30:00', 'Sanctuary', 200), -- 4
('2025-02-14', '20:00:00', 'Youth Room', 50); -- 5

INSERT INTO OneTimeEvent VALUES (1, 'Ugly Sweater Party', 'Wear your worst sweater!', 0.00, FALSE);
INSERT INTO SmallGroup VALUES (2, 2, 'The Parables of Jesus', 'Wednesday');
INSERT INTO SmallGroup VALUES (3, 3, 'Foundations of Faith', 'Friday');
INSERT INTO Meeting VALUES (4, 'January Calendar Planning');
INSERT INTO OneTimeEvent VALUES (5, 'Late Night Pizza Party', 'Pizza and Games', 5.00, TRUE);

-- =========================================================
-- 4. SYNC TO DROPDOWN
-- =========================================================
