-- YGMSData.sql
-- Robust Data Seeder
-- 1. Clears all existing data
-- 2. Resets ID counters to 1
-- 3. Inserts fresh data with Roles

USE ygms_db;

-- People (IDs 1-12)
INSERT INTO Person (Name, Email, PhoneNumber, Role) VALUES
('Pastor Mike Davis', 'mike.davis@church.org', '555-1001', 'Leader'), -- ID 1
('Sarah Chen', 'sarah.chen@church.org', '555-1002', 'Leader'),      -- ID 2
('Maria Gomez', 'maria.g@volunteer.net', '555-1003', 'Volunteer'),    -- ID 3
('Chris Evans', 'chris.e@volunteer.net', '555-1004', 'Volunteer'),    -- ID 4
('Tom Smith', 'tom.smith@home.net', '555-2001', 'Parent'),       -- ID 5
('Alice Jones', 'alice.jones@home.net', '555-2002', 'Parent'),   -- ID 6
('Bob Brown', 'bob.brown@home.net', '555-2003', 'Parent'),       -- ID 7
('Ethan Smith', 'ethan.s@youth.org', '555-3001', 'Student'),      -- ID 8
('Maya Jones', 'maya.j@youth.org', '555-3002', 'Student'),        -- ID 9
('Sam Brown', 'sam.b@youth.org', '555-3003', 'Student'),          -- ID 10
('Chloe Green', 'chloe.g@youth.org', '555-3004', 'Student'),      -- ID 11
('Liam Wilson', 'liam.w@youth.org', '555-3005', 'Student');       -- ID 12

-- Roles
INSERT INTO YouthPastor VALUES (1, '2019-08-01');
INSERT INTO Leader VALUES (2);
INSERT INTO Volunteer VALUES (3, 'Music'), (4, 'Tech');
INSERT INTO ParentGuardian VALUES (5, 'Father'), (6, 'Mother'), (7, 'Father');

-- Youth (Corrected Parent IDs: 5, 6, 7)
INSERT INTO Youth (PersonID, ParentGuardianID, GradeLevel, BirthDate) VALUES
(8, 5, 9, '2009-05-15'),  -- Ethan linked to Tom (5)
(9, 6, 10, '2008-01-20'), -- Maya linked to Alice (6)
(10, 7, 11, '2007-11-03'), -- Sam linked to Bob (7)
(11, NULL, 12, '2006-07-28'), -- Chloe (No parent)
(12, 5, 9, '2009-12-01');  -- Liam linked to Tom (5)

-- Medical
INSERT INTO MedicalInfo VALUES (8, 'Allergies'), (9, 'Asthma'), (10, 'None');

-- Events
INSERT INTO Event VALUES
(1, '2025-12-10', '18:30:00', 'Auditorium', 150),
(2, '2025-12-04', '19:00:00', 'Room 101', 12),
(3, '2025-12-04', '19:00:00', 'Room 102', 12),
(4, '2025-12-03', '17:00:00', 'Office', 5);

INSERT INTO OneTimeEvent VALUES (1, 'Ugly Sweater', 'Fun', 5.00, TRUE);
INSERT INTO SmallGroup VALUES (2, 2, 'Parables', 'Wed'), (3, 2, 'Faith', 'Wed');
INSERT INTO Meeting VALUES (4, 'Planning');

-- Links (Using IDs 8-12 for Youth)
INSERT INTO SmallGroupMembers VALUES (2, 8, '2025-09-01'), (2, 11, '2025-09-01'), (3, 9, '2025-10-15'), (3, 10, '2025-10-15'), (3, 12, '2025-11-20');
INSERT INTO OneTimeEventYouth VALUES (1, 8, 'Registered'), (1, 9, 'Registered'), (1, 10, 'Registered'), (1, 11, 'Waitlist'), (1, 12, 'Registered');

-- Waivers (Youth ID, Parent ID)
INSERT INTO PermissionWaiver (YouthID, PersonID, DocumentType, DateSigned, DateExpires, Status) VALUES
(8, 5, 'Waiver', '2025-10-15', '2026-10-15', 'Signed'),
(9, 6, 'Waiver', '2025-10-20', '2026-10-20', 'Signed');

INSERT INTO PermissionWaiverEvent VALUES (1, 1, TRUE), (1, 2, TRUE);

SELECT * FROM Person;