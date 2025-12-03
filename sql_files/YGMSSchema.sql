-- Author: Brevin Tating btating@westmont.edu

-- Create Youth Group Management DB
CREATE DATABASE IF NOT EXISTS ygms_db;

-- Select DB
USE ygms_db;


-- People and Roles

-- Person Table
-- Hold basic information for ALL people (Youth, Leader, Parent/Guardian)
CREATE TABLE Person(
    ID INT PRIMARY KEY AUTO_INCREMENT,
    Name VARCHAR(255) NOT NULL,
    Email VARCHAR(100) UNIQUE NULL,
    PhoneNumber VARCHAR(20) UNIQUE NULL
);

-- ParentGuardian (Role Entity)
CREATE TABLE ParentGuardian (
    ID INT PRIMARY KEY AUTO_INCREMENT,
    PersonID INT NOT NULL UNIQUE,
    RelationshipToYouth VARCHAR(50), -- e.g., 'Mother', 'Father', 'Aunt'
    FOREIGN KEY (PersonID) REFERENCES Person(ID)
);

-- Youth (Role Entity)
CREATE TABLE Youth (
    ID INT PRIMARY KEY AUTO_INCREMENT,
    PersonID INT NOT NULL UNIQUE,
    ParentGuardianID INT, -- Links to the ParentGuardian table ID
    GradeLevel INT, -- Useful for grouping and event targeting
    BirthDate DATE, -- Important for age-based restrictions/groups
    FOREIGN KEY (PersonID) REFERENCES Person(ID),
    FOREIGN KEY (ParentGuardianID) REFERENCES ParentGuardian(ID)
);

-- Leader (Role Entity)
CREATE TABLE Leader (
    ID INT PRIMARY KEY AUTO_INCREMENT,
    PersonID INT NOT NULL UNIQUE,
    FOREIGN KEY (PersonID) REFERENCES Person(ID)
);

-- YouthPastor (Role Entity)
CREATE TABLE YouthPastor (
    ID INT PRIMARY KEY AUTO_INCREMENT,
    PersonID INT NOT NULL UNIQUE,
    HireDate DATE,
    FOREIGN KEY (PersonID) REFERENCES Person(ID)
);

-- Volunteer (Role Entity)
CREATE TABLE Volunteer (
    ID INT PRIMARY KEY AUTO_INCREMENT,
    PersonID INT NOT NULL UNIQUE,
    Specialty VARCHAR(100),
    FOREIGN KEY (PersonID) REFERENCES Person(ID)
);



-- MedicalInfo (Related to Youth)
CREATE TABLE MedicalInfo (
    ID INT PRIMARY KEY AUTO_INCREMENT,
    YouthID INT NOT NULL UNIQUE,
    Info TEXT,
    FOREIGN KEY (YouthID) REFERENCES Youth(ID)
);

-- Events and Groups

-- Event (Super-type Entity)
CREATE TABLE Event (
    ID INT PRIMARY KEY AUTO_INCREMENT,
    Date DATE NOT NULL,
    Time TIME,
    Location VARCHAR(255),
    IsCancelled BOOLEAN DEFAULT FALSE,
    MaxCapacity INT -- Important for managing RSVPs and logistics
);

-- OneTimeEvent (Event Sub-type)
CREATE TABLE OneTimeEvent (
    ID INT PRIMARY KEY AUTO_INCREMENT,
    EventID INT NOT NULL UNIQUE,
    Name VARCHAR(255) NOT NULL,
    Description TEXT,
    Cost DECIMAL(6, 2) DEFAULT 0.00, -- Financial tracking
    IsRegistrationRequired BOOLEAN DEFAULT TRUE, -- Links to RSVP functionality
    FOREIGN KEY (EventID) REFERENCES Event(ID)
);

--  SmallGroup (Event Sub-type, though usually an ongoing activity)
CREATE TABLE SmallGroup (
    ID INT PRIMARY KEY AUTO_INCREMENT,
    EventID INT NOT NULL UNIQUE,
    LeaderID INT,
    Theme VARCHAR(100), -- e.g., 'Book of John', 'The Parables of Jesus'
    DayOfWeek ENUM('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'), -- Helps with scheduling
    FOREIGN KEY (EventID) REFERENCES Event(ID),
    FOREIGN KEY (LeaderID) REFERENCES Leader(ID)
);

-- Meeting (Event Sub-type)
CREATE TABLE Meeting (
    ID INT PRIMARY KEY AUTO_INCREMENT,
    EventID INT NOT NULL UNIQUE,
    MainTopic VARCHAR(255),
    DateCreated DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (EventID) REFERENCES Event(ID)
);


-- Junction Tables

-- 12. SmallGroupMembers (Many-to-Many: SmallGroup <--> Youth)
CREATE TABLE SmallGroupMembers (
    SmallGroupID INT NOT NULL,
    YouthID INT NOT NULL,
    DateJoined DATE, -- When the youth joined the group
    IsActive BOOLEAN DEFAULT TRUE,
    PRIMARY KEY (SmallGroupID, YouthID),
    FOREIGN KEY (SmallGroupID) REFERENCES SmallGroup(ID),
    FOREIGN KEY (YouthID) REFERENCES Youth(ID)
);

-- OneTimeEventYouth (Represents Registration/RSVP Status)
-- This table will eventually hold the attendance data from Redis (Attendance history).
CREATE TABLE OneTimeEventYouth (
    OneTimeEventID INT NOT NULL,
    YouthID INT NOT NULL,
    RegistrationStatus ENUM('Registered', 'Waitlist', 'Cancelled') DEFAULT 'Registered',
    RegistrationDate DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (OneTimeEventID, YouthID),
    FOREIGN KEY (OneTimeEventID) REFERENCES OneTimeEvent(ID),
    FOREIGN KEY (YouthID) REFERENCES Youth(ID)
);

-- PermissionWaiver (Many-to-One: Waivers link to a Youth)
CREATE TABLE PermissionWaiver (
    ID INT PRIMARY KEY AUTO_INCREMENT,
    YouthID INT NOT NULL,
    PersonID INT NOT NULL, -- Who signed the waiver (Parent/Guardian or Youth if 18+)
    DocumentType VARCHAR(100) NOT NULL, -- e.g., 'General Release', 'Medical Authorization'
    DateSigned DATE NOT NULL,
    DateExpires DATE, -- Crucial for annual forms
    Status ENUM('Signed', 'Pending', 'Expired') NOT NULL,
    FOREIGN KEY (YouthID) REFERENCES Youth(ID),
    FOREIGN KEY (PersonID) REFERENCES Person(ID)
);

-- PermissionWaiverEvent (Many-to-Many: PermissionWaiver <--> Event)
CREATE TABLE PermissionWaiverEvent (
    EventID INT NOT NULL,
    PermissionWaiverID INT NOT NULL,
    IsRequired BOOLEAN DEFAULT TRUE,
    PRIMARY KEY (EventID, PermissionWaiverID),
    FOREIGN KEY (EventID) REFERENCES Event(ID),
    FOREIGN KEY (PermissionWaiverID) REFERENCES PermissionWaiver(ID)
);


