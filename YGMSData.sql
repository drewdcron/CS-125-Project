
-- YGMSData.sql
-- Inserts sample data into the ygms_db schema.

-- Make sure we are operating in the correct database
USE ygms_db;

-- =========================================================
-- 1. CORE PEOPLE (Person Table)
-- =========================================================

-- Note: AUTO_INCREMENT will assign IDs starting from 1.

-- IDs 1-2: Staff (Youth Pastor & Leader)
INSERT INTO Person (Name, Email, PhoneNumber) VALUES
('Pastor Mike Davis', 'mike.davis@church.org', '555-1001'), -- ID 1 (Youth Pastor)
('Sarah Chen', 'sarah.chen@church.org', '555-1002');      -- ID 2 (Leader)

-- IDs 3-4: Volunteers
INSERT INTO Person (Name, Email, PhoneNumber) VALUES
('Maria Gomez', 'maria.g@volunteer.net', '555-1003'),    -- ID 3 (Volunteer)
('Chris Evans', 'chris.e@volunteer.net', '555-1004');    -- ID 4 (Volunteer)

-- IDs 5-7: Parents/Guardians
INSERT INTO Person (Name, Email, PhoneNumber) VALUES
('Tom Smith', 'tom.smith@home.net', '555-2001'),       -- ID 5 (Parent)
('Alice Jones', 'alice.jones@home.net', '555-2002'),   -- ID 6 (Parent)
('Bob Brown', 'bob.brown@home.net', '555-2003');       -- ID 7 (Parent)

-- IDs 8-12: Youth (Students)
INSERT INTO Person (Name, Email, PhoneNumber) VALUES
('Ethan Smith', 'ethan.s@youth.org', '555-3001'),      -- ID 8 (Youth - Child of Parent ID 5)
('Maya Jones', 'maya.j@youth.org', '555-3002'),        -- ID 9 (Youth - Child of Parent ID 6)
('Sam Brown', 'sam.b@youth.org', '555-3003'),          -- ID 10 (Youth - Child of Parent ID 7)
('Chloe Green', 'chloe.g@youth.org', '555-3004'),      -- ID 11 (Youth - No Parent link for testing)
('Liam Wilson', 'liam.w@youth.org', '555-3005');       -- ID 12 (Youth - Child of Parent ID 5)

-- =========================================================
-- 2. ROLE TABLES (Linking to Person IDs)
-- =========================================================

-- Youth Pastor (PersonID 1)
INSERT INTO YouthPastor (PersonID, HireDate) VALUES
(1, '2019-08-01');

-- Leaders (PersonID 2)
INSERT INTO Leader (PersonID) VALUES
(2); -- Leader ID 1: Sarah Chen

-- Volunteers (PersonID 3 & 4)
INSERT INTO Volunteer (PersonID, Specialty) VALUES
(3, 'Music/Worship'), -- Volunteer ID 1: Maria Gomez
(4, 'Tech/Media');    -- Volunteer ID 2: Chris Evans

-- Parents/Guardians (PersonID 5, 6, 7)
INSERT INTO ParentGuardian (PersonID, RelationshipToYouth) VALUES
(5, 'Father'), -- ParentGuardian ID 1: Tom Smith
(6, 'Mother'), -- ParentGuardian ID 2: Alice Jones
(7, 'Father'); -- ParentGuardian ID 3: Bob Brown

-- Youth (Linking to ParentGuardian IDs)
-- YouthID is the PK of the Youth table. ParentGuardianID is the PK of the ParentGuardian table.
INSERT INTO Youth (PersonID, ParentGuardianID, GradeLevel, BirthDate) VALUES
(8, 1, 9, '2009-05-15'),  -- Youth ID 1: Ethan (ParentGuardian ID 1 = Tom Smith)
(9, 2, 10, '2008-01-20'), -- Youth ID 2: Maya (ParentGuardian ID 2 = Alice Jones)
(10, 3, 11, '2007-11-03'), -- Youth ID 3: Sam (ParentGuardian ID 3 = Bob Brown)
(11, NULL, 12, '2006-07-28'), -- Youth ID 4: Chloe (No linked ParentGuardian)
(12, 1, 9, '2009-12-01');   -- Youth ID 5: Liam (ParentGuardian ID 1 = Tom Smith)

-- =========================================================
-- 3. MEDICAL INFO (Linking to Youth IDs)
-- =========================================================

INSERT INTO MedicalInfo (YouthID, Info) VALUES
(1, 'Allergies: Peanuts, Tree Nuts. Carries Epi-Pen.'), -- Youth ID 1: Ethan
(2, 'Asthma, requires inhaler for heavy activity.'),     -- Youth ID 2: Maya
(3, 'No known issues.');                                -- Youth ID 3: Sam

-- =========================================================
-- 4. EVENTS (Event Super-type)
-- =========================================================

INSERT INTO Event (Date, Time, Location, MaxCapacity) VALUES
('2025-12-10', '18:30:00', 'Main Auditorium', 150),  -- ID 1: One-Time Event
('2025-12-04', '19:00:00', 'Youth Room 101', 12),   -- ID 2: Small Group 1
('2025-12-04', '19:00:00', 'Youth Room 102', 12),   -- ID 3: Small Group 2
('2025-12-03', '17:00:00', 'Pastor Mike Office', 5); -- ID 4: Leader Meeting

-- =========================================================
-- 5. EVENT SUB-TYPES (Linking to Event IDs)
-- =========================================================

-- OneTimeEvent (EventID 1)
INSERT INTO OneTimeEvent (EventID, Name, Description, Cost, IsRegistrationRequired) VALUES
(1, 'Ugly Sweater Christmas Party', 'Annual holiday party with games and a white elephant exchange.', 5.00, TRUE); -- OneTimeEvent ID 1

-- SmallGroup (EventIDs 2 & 3)
INSERT INTO SmallGroup (EventID, LeaderID, Theme, DayOfWeek) VALUES
(2, 1, 'The Parables of Jesus', 'Wed'), -- SmallGroup ID 1 (LeaderID 1: Sarah Chen)
(3, 1, 'Foundations of Faith', 'Wed');  -- SmallGroup ID 2 (LeaderID 1: Sarah Chen, demonstrating one leader can lead multiple groups)

-- Meeting (EventID 4)
INSERT INTO Meeting (EventID, MainTopic) VALUES
(4, 'January Calendar and Volunteer Assignments'); -- Meeting ID 1

-- =========================================================
-- 6. JUNCTION TABLES (Linking Relationships)
-- =========================================================

-- SmallGroupMembers (Linking Youth to Small Groups)
INSERT INTO SmallGroupMembers (SmallGroupID, YouthID, DateJoined) VALUES
(1, 1, '2025-09-01'), -- Youth ID 1 (Ethan) in SG 1
(1, 4, '2025-09-01'), -- Youth ID 4 (Chloe) in SG 1
(2, 2, '2025-10-15'), -- Youth ID 2 (Maya) in SG 2
(2, 3, '2025-10-15'), -- Youth ID 3 (Sam) in SG 2
(2, 5, '2025-11-20'); -- Youth ID 5 (Liam) in SG 2

-- OneTimeEventYouth (Registration/RSVP for Christmas Party, OneTimeEvent ID 1)
INSERT INTO OneTimeEventYouth (OneTimeEventID, YouthID, RegistrationStatus) VALUES
(1, 1, 'Registered'),
(1, 2, 'Registered'),
(1, 3, 'Registered'),
(1, 4, 'Waitlist'), -- Testing the waitlist status
(1, 5, 'Registered');

-- PermissionWaiver (General waivers signed by Parent 1 and 2)
INSERT INTO PermissionWaiver (YouthID, PersonID, DocumentType, DateSigned, DateExpires, Status) VALUES
(1, 5, 'Annual Medical Release', '2025-10-15', '2026-10-15', 'Signed'),  -- Waiver ID 1: Ethan (signed by Person ID 5: Tom Smith)
(2, 6, 'Annual Medical Release', '2025-10-20', '2026-10-20', 'Signed');  -- Waiver ID 2: Maya (signed by Person ID 6: Alice Jones)

-- PermissionWaiverEvent (Linking the general waiver to the upcoming event, Event ID 1)
INSERT INTO PermissionWaiverEvent (EventID, PermissionWaiverID, IsRequired) VALUES
(1, 1, TRUE),
(1, 2, TRUE);