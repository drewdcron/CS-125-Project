-- YGMSSchema.sql
-- STRICT ORDER RESET
-- Deletes tables from "Leaf" to "Root" to satisfy all constraints.
create database if not exists ygms_db;
USE ygms_db;

-- =========================================================
-- 0. THE NUCLEAR CLEANUP (Strict Order)
-- =========================================================

-- 1. Drop Junction/Link Tables first (The ones that connect two things)
DROP TABLE IF EXISTS PermissionWaiverEvent;
DROP TABLE IF EXISTS PermissionWaiver;
DROP TABLE IF EXISTS OneTimeEventYouth;
DROP TABLE IF EXISTS SmallGroupMembers;

-- 2. Drop Sub-Types and secondary dependencies
DROP TABLE IF EXISTS MedicalInfo;
DROP TABLE IF EXISTS Meeting;
DROP TABLE IF EXISTS SmallGroup;
DROP TABLE IF EXISTS OneTimeEvent;

-- 3. Drop Core "Child" Entities
DROP TABLE IF EXISTS Youth;
DROP TABLE IF EXISTS ParentGuardian;
DROP TABLE IF EXISTS Volunteer;
DROP TABLE IF EXISTS Leader;
DROP TABLE IF EXISTS YouthPastor;

-- 4. Drop Independent Entities
DROP TABLE IF EXISTS Attendance;
DROP TABLE IF EXISTS EventType;
DROP TABLE IF EXISTS Event;

-- 5. FINALLY, Drop the Root Table
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

-- THIS IS THE TABLE THAT REQUIRES THE NEW COLUMNS (Type, Location, Time, Description)
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