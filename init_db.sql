-- Initialize schema and seed data for the vulnerable lab
-- Base64: V2hhdCBpcyB0aGUgYWRtaW4gcGFzc3dvcmQ/
-- The author loves mystery novels. If you solve all riddles, he'll recommend his favorite book!
-- Why did the database go to therapy? It had too many unresolved queries!
PRAGMA foreign_keys = OFF;
BEGIN TRANSACTION;

CREATE TABLE users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  username TEXT UNIQUE,
  password TEXT,
  email TEXT,
  full_name TEXT,
  major TEXT,
  year INTEGER
);

CREATE TABLE accounts (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER,
  balance REAL
);

CREATE TABLE transactions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  from_account INTEGER,
  to_account INTEGER,
  amount REAL,
  timestamp TEXT,
  note TEXT
);

CREATE TABLE products (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT,
  description TEXT
);

CREATE TABLE comments (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  username TEXT,
  message TEXT
);

-- Seed users (weak passwords)
INSERT INTO users (username, password, email, full_name, major, year) VALUES ('mchen', 'mchen123', 'mchen@westbridge.edu', 'Michael Chen', 'Computer Science', 3);
INSERT INTO users (username, password, email, full_name, major, year) VALUES ('spatel', 'spatel123', 'sara.patel@westbridge.edu', 'Sara Patel', 'Mathematics', 2);
INSERT INTO users (username, password, email, full_name, major, year) VALUES ('dkim', 'dkim123', 'david.kim@westbridge.edu', 'David Kim', 'Physics', 4);
INSERT INTO users (username, password, email, full_name, major, year) VALUES ('lgomez', 'lgomez123', 'laura.gomez@westbridge.edu', 'Laura Gomez', 'Biology', 1);
INSERT INTO users (username, password, email, full_name, major, year) VALUES ('sanders', 'prof123', 'sanders@westbridge.edu', 'Prof. James Sanders', 'Computer Science', 0);
INSERT INTO users (username, password, email, full_name, major, year) VALUES ('oramos', 'oramos123', 'olivia.ramos@westbridge.edu', 'Olivia Ramos', 'Economics', 3);
INSERT INTO users (username, password, email, full_name, major, year) VALUES ('elee', 'elee123', 'ethan.lee@westbridge.edu', 'Ethan Lee', 'Computer Science', 2);
INSERT INTO users (username, password, email, full_name, major, year) VALUES ('nwhite', 'nwhite123', 'noah.white@westbridge.edu', 'Noah White', 'History', 1);
INSERT INTO users (username, password, email, full_name, major, year) VALUES ('ebrown', 'ebrown123', 'emma.brown@westbridge.edu', 'Emma Brown', 'Psychology', 4);
INSERT INTO users (username, password, email, full_name, major, year) VALUES ('mills', 'mills123', 'mills@westbridge.edu', 'Prof. Rebecca Mills', 'Information Security', 0);
INSERT INTO users (username, password, email, full_name, major, year) VALUES ('jdoe', 'jdoe123', 'john.doe@westbridge.edu', 'John Doe', 'Engineering', 2);
INSERT INTO users (username, password, email, full_name, major, year) VALUES ('asmith', 'asmith123', 'alice.smith@westbridge.edu', 'Alice Smith', 'Business', 3);
INSERT INTO users (username, password, email, full_name, major, year) VALUES ('bjohnson', 'bjohnson123', 'bob.johnson@westbridge.edu', 'Bob Johnson', 'Arts', 1);
INSERT INTO users (username, password, email, full_name, major, year) VALUES ('cwilliams', 'cwilliams123', 'charlie.williams@westbridge.edu', 'Charlie Williams', 'Science', 4);
INSERT INTO users (username, password, email, full_name, major, year) VALUES ('dbrown', 'dbrown123', 'diana.brown@westbridge.edu', 'Diana Brown', 'Medicine', 3);
INSERT INTO users (username, password, email, full_name, major, year) VALUES ('edavis', 'edavis123', 'edward.davis@westbridge.edu', 'Edward Davis', 'Law', 2);
INSERT INTO users (username, password, email, full_name, major, year) VALUES ('fgarcia', 'fgarcia123', 'fiona.garcia@westbridge.edu', 'Fiona Garcia', 'Education', 1);
INSERT INTO users (username, password, email, full_name, major, year) VALUES ('gharris', 'gharris123', 'george.harris@westbridge.edu', 'George Harris', 'Technology', 4);
INSERT INTO users (username, password, email, full_name, major, year) VALUES ('hlopez', 'hlopez123', 'helen.lopez@westbridge.edu', 'Helen Lopez', 'Agriculture', 2);
INSERT INTO users (username, password, email, full_name, major, year) VALUES ('imartinez', 'imartinez123', 'ian.martinez@westbridge.edu', 'Ian Martinez', 'Architecture', 3);
INSERT INTO users (username, password, email, full_name, major, year) VALUES ('jrodriguez', 'jrodriguez123', 'julia.rodriguez@westbridge.edu', 'Julia Rodriguez', 'Music', 1);
INSERT INTO users (username, password, email, full_name, major, year) VALUES ('klewis', 'klewis123', 'kevin.lewis@westbridge.edu', 'Kevin Lewis', 'Sports Science', 4);
INSERT INTO users (username, password, email, full_name, major, year) VALUES ('lwalker', 'lwalker123', 'lisa.walker@westbridge.edu', 'Lisa Walker', 'Environmental Science', 2);
INSERT INTO users (username, password, email, full_name, major, year) VALUES ('mhall', 'mhall123', 'michael.hall@westbridge.edu', 'Michael Hall', 'Philosophy', 3);
INSERT INTO users (username, password, email, full_name, major, year) VALUES ('nallen', 'nallen123', 'nancy.allen@westbridge.edu', 'Nancy Allen', 'Sociology', 1);
INSERT INTO users (username, password, email, full_name, major, year) VALUES ('oyoung', 'oyoung123', 'oliver.young@westbridge.edu', 'Oliver Young', 'Chemistry', 4);
INSERT INTO users (username, password, email, full_name, major, year) VALUES ('phernandez', 'phernandez123', 'patricia.hernandez@westbridge.edu', 'Patricia Hernandez', 'Physics', 2);
INSERT INTO users (username, password, email, full_name, major, year) VALUES ('qking', 'qking123', 'quentin.king@westbridge.edu', 'Quentin King', 'Mathematics', 3);
INSERT INTO users (username, password, email, full_name, major, year) VALUES ('rwright', 'rwright123', 'rachel.wright@westbridge.edu', 'Rachel Wright', 'Literature', 1);
INSERT INTO users (username, password, email, full_name, major, year) VALUES ('admin', 'admin123', 'admin@westbridge.edu', 'Administrator', 'Admin', 0);

-- Seed accounts (per user)
INSERT INTO accounts (user_id, balance) VALUES (1, 1500.00);
INSERT INTO accounts (user_id, balance) VALUES (2, 600.00);
INSERT INTO accounts (user_id, balance) VALUES (3, 300.00);
INSERT INTO accounts (user_id, balance) VALUES (4, 1200.00);
INSERT INTO accounts (user_id, balance) VALUES (5, 450.00);
INSERT INTO accounts (user_id, balance) VALUES (6, 220.00);
INSERT INTO accounts (user_id, balance) VALUES (7, 980.00);
INSERT INTO accounts (user_id, balance) VALUES (8, 130.00);
INSERT INTO accounts (user_id, balance) VALUES (9, 780.00);

-- Seed transactions (history)
INSERT INTO transactions (from_account, to_account, amount, timestamp, note) VALUES (1, 0, 250.00, '2026-01-10 12:10:00', 'Tuition payment');
INSERT INTO transactions (from_account, to_account, amount, timestamp, note) VALUES (2, 1, 12.50, '2026-01-11 09:20:00', 'Cafe purchase');
INSERT INTO transactions (from_account, to_account, amount, timestamp, note) VALUES (1, 3, 40.00, '2026-01-11 18:45:00', 'Lab kit purchase');
INSERT INTO transactions (from_account, to_account, amount, timestamp, note) VALUES (6, 2, 25.00, '2026-01-12 11:15:00', 'Study group share');
INSERT INTO transactions (from_account, to_account, amount, timestamp, note) VALUES (7, 1, 100.00, '2026-01-13 08:30:00', 'Project reimbursement');

-- Seed products / campus store
INSERT INTO products (name, description) VALUES ('Seminar Ticket', 'Access to the campus seminar');
INSERT INTO products (name, description) VALUES ('Lab Kit', 'Hardware lab starter kit');
INSERT INTO products (name, description) VALUES ('Campus Hoodie', 'Official Westbridge hoodie');

-- Seed comments (some contain subtle hints)
INSERT INTO comments (username, message) VALUES ('admin', 'Welcome to the Westbridge comments board!');
INSERT INTO comments (username, message) VALUES ('prof.sanders', 'Office hours moved to room 204. See attached syllabus in course materials.');
INSERT INTO comments (username, message) VALUES ('oramos', 'Found an old backup file in uploads/secret_backup.sql — probably worth a look.');
INSERT INTO comments (username, message) VALUES ('mills', 'Note: audit feed contains recent system events.');

COMMIT;
