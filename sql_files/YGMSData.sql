-- YGMSData.sql
-- STRICT ORDER RESET
-- Explicit IDs included to prevent Foreign Key Errors

USE ygms_db;

-- =========================================================
-- 1. POPULATE SEED DATA
-- =========================================================

-- We use EXPLICIT IDs in the INSERT statement to ensure Foreign Keys always match.
INSERT INTO Person (ID, Name, Email, Role) VALUES
(1, 'Pastor Mike', 'mike@ygms.com', 'Youth Pastor'),
(2, 'Sarah Chen', 'sarah@ygms.com', 'Leader'),
(3, 'John Miller', 'john@ygms.com', 'Leader'),
(4, 'Parent One', 'p1@test.com', 'Parent'),
(5, 'Parent Two', 'p2@test.com', 'Parent'),
(6, 'Volunteer Dave', 'dave@test.com', 'Volunteer'),
(7, 'Ethan Smith', 'ethan@test.com', 'Student'),
(8, 'Olivia Jones', 'olivia@test.com', 'Student'),
(9, 'Liam Brown', 'liam@test.com', 'Student'),
(10, 'Emma Davis', 'emma@test.com', 'Student'),
(11, 'Noah Wilson', 'noah@test.com', 'Student'),
(12, 'Ava Johnson', 'ava@test.com', 'Student'),
(13, 'Pastor Emily', 'emily@ygms.com', 'Youth Pastor'),
(14, 'Leader Alex', 'alex@ygms.com', 'Leader'),
(15, 'Leader Jordan', 'jordan@ygms.com', 'Leader'),
(16, 'Leader Taylor', 'taylor@ygms.com', 'Leader'),
(17, 'Volunteer Lisa', 'lisa@test.com', 'Volunteer'),
(18, 'Volunteer Tom', 'tom@test.com', 'Volunteer'),
(19, 'Volunteer Karen', 'karen@test.com', 'Volunteer'),
(20, 'Volunteer Bob', 'bob@test.com', 'Volunteer'),
(21, 'Mrs. Robinson', 'robinson@test.com', 'Parent'),
(22, 'Mr. Garcia', 'garcia@test.com', 'Parent'),
(23, 'Ms. Lee', 'lee@test.com', 'Parent'),
(24, 'Mr. Patel', 'patel@test.com', 'Parent'),
(25, 'Mrs. Kim', 'kim@test.com', 'Parent'),
(26, 'Mr. Johnson', 'johnson@test.com', 'Parent'),
(27, 'Lucas Robinson', 'lucas@test.com', 'Student'),
(28, 'Mia Robinson', 'mia@test.com', 'Student'),
(29, 'Isabella Garcia', 'bella@test.com', 'Student'),
(30, 'Mateo Garcia', 'mateo@test.com', 'Student'),
(31, 'Sophia Lee', 'sophia@test.com', 'Student'),
(32, 'Jackson Patel', 'jack@test.com', 'Student'),
(33, 'Aiden Patel', 'aiden@test.com', 'Student'),
(34, 'Chloe Kim', 'chloe@test.com', 'Student'),
(35, 'Elijah Johnson', 'elijah@test.com', 'Student'),
(36, 'Grace Johnson', 'grace@test.com', 'Student'),
(37, 'Benji Button', 'benji@test.com', 'Student'),
(38, 'Zoey Deschanel', 'zoey@test.com', 'Student'),
(39, 'Hannah Montana', 'hannah@test.com', 'Student'),
(40, 'Peter Parker', 'peter@test.com', 'Student'),
(41, 'Miles Morales', 'miles@test.com', 'Student'),
(42, 'Gwen Stacy', 'gwen@test.com', 'Student'),
(43, 'Harry Potter', 'harry@test.com', 'Student'),
(44, 'Ron Weasley', 'ron@test.com', 'Student');

-- SUB-TABLE INSERTS (Now guaranteed to work)
INSERT INTO YouthPastor VALUES (1, '2020-01-01'), (13, '2022-06-15');
INSERT INTO Leader VALUES (2), (3), (14), (15), (16);
INSERT INTO Volunteer VALUES (6, 'Audio/Visual'), (17, 'Kitchen/Snacks'), (18, 'Security'), (19, 'Check-In Desk'), (20, 'Worship Band');
INSERT INTO ParentGuardian VALUES (4, 'Father'), (5, 'Mother'), (21, 'Mother'), (22, 'Father'), (23, 'Mother'), (24, 'Father'), (25, 'Mother'), (26, 'Father');

-- Youth Inserts
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
INSERT IGNORE INTO EventType (Name) SELECT Name FROM OneTimeEvent;
INSERT IGNORE INTO EventType (Name) SELECT CONCAT(Theme, ' (Small Group)') FROM SmallGroup;
INSERT IGNORE INTO EventType (Name) SELECT MainTopic FROM Meeting;