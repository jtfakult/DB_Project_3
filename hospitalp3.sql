/* -*- mode:sql; sql-product: oracle; indent-tabs-mode: nil  -*- */
/*
Group 21
Jacob Fakult
Jacob Komissar

2017-02-14
*/

/*
Sections are marked in boxes something like this:
/* ***** ***** ***** ***** ***** ***** ***** *\
 *          Section 0: Introduction          *
\* ***** ***** ***** ***** ***** ***** ***** *

- Section 0: Introduction
- Section 0.1: Drop Everything
- Section 1: Creating Table
- Section 2: Sample Data
- Section 3: Queries

Differences between the tables created and the official solution to phase 1 are
listed in the next comment.

The queries should conform to the questions asked, with a single exception:
Queries asking for SSN will show both patientID and SSN, because SSN is not
the patients' primary key in this database.
*/


/*
New assumptions:
 - A room number is an integer.
 - Office numbers are always integers.
 - Most phone numbers will be from the United States.
 - All names, addresses, etc. are ASCII only.
 - A name is no longer than 60 characters.


Restrictions implemented in the database:
 - Telephone number format:
   - Phone numbers must be either a 10-digit string or a plus sign followed by
     9-15 digits.
   - Rationale:
     If a single format is not used for phone numbers, phone numbers become
     difficult to compare. Assuming most patients will use US phone numbers,
     10-digit numbers are needed. To also accommodate international patients,
     an international format based on E.164 is also allowed, with a range limit
     from the minimal used phone number to the maximum allowed.
 - Partial SSN validation:
   - SSNs must be 3 digits, a hyphen, 2 digits, a hyphen, and 4 digits, in that
     order.
   - Rationale: it's really easy to implement this


Differences from official solution:
  Tables:
   - Future visits are their own table, "Appointments", rather than a column of
     the Admissions table. If you want them together, use the view named
     AdmissionsAppointments.
  Names:
   - StayIn is called RoomStays, because I like it a little more.
   - Equipment is named EquipmentUnit
   - Various columns have slightly different names, but should remain clear.
  Data:
   - Patients have an additional column for their unique ID, which is not their
     SSN, as an SSN is not sufficient as a unique identifier for all potential
     patients.
   - The Examination table has additional information (time), allowing a doctor
     to examine the same patiend multiple times during the same visit.
   - The Examination table also does not include the patient/admission in its
     primary key. This allows multiple doctors to examine a patient at once.


Remaining limitations:
  - Rooms may contain only one patient at a time.
  - Employees may not share offices.



**** Development Notes ****

Naming conventions (used so far):
 - table and view names are PascalCase
 - columns are camelCase
 - constraint names look like TableName_then_snake_case
 - trigger names should be descriptive snake_case
 - functions use Capital_Underscore_Case

Style convention for table creation:
  General patterns:
    - types are lowercase
    - statements are in ALL CAPS (e.g. CREATE TABLE)
    - primary keys come before other columns
    - lowercase patterns (see below) follow uppercase patterns
  Capitalized:
    - PRIMARY KEY
    - LIKE, REGEXP_LIKE
    - NOT NULL
  Lowercase:
    - constraint
    - foreign key ... references
    - check
    - in

Style convention for queries:
  - Always capitalize any words recognized by SQL.


Implementation conventions (keep similar types consistent):
 - money is represented as a decimal(9, 2)
 - names have a maximum length of 50 characters, which is generally enough
 - titles of various sorts have length up to 30

*/


-- Allow blank lines in statements.
set sqlblanklines on

/* ***** Section 0.1: DROP Everything ***** */
DROP VIEW CriticalCases;
DROP VIEW DoctorsLoad;

DROP VIEW AdmissionsAppointments;
-- DROP TABLE EmployeeHeirarchy;

DROP TABLE EquipmentUnits;
DROP TABLE EquipmentTypes;
DROP TABLE Appointments;
DROP TABLE Examinations;
DROP TABLE RoomStays;
DROP TABLE Admissions;
DROP TABLE RoomAccess;
DROP TABLE RoomServices;
DROP TABLE Rooms;
DROP TABLE Doctors;
DROP TABLE Employees;
DROP TABLE Patients;




/* ***** ***** ***** ***** ***** ***** ***** *\
 *        Section 1:  Creating Tables        *
\* ***** ***** ***** ***** ***** ***** ***** */


/* The stub before each table uses a simple notation:
   TableName(type *column, type +column, type column, ...)
   * indicates a primary key
   + indicates a unique element
   Used types are:
   - 'int'
   - 'num'
   - 'date'
   - a number, representing the length of a string column
 */


/* ***** PEOPLE ***** */

-- Patients (int *patientID, 11 +SSN, 50 givenName, 50 surname, 100 address, 15 phoneNumber)
CREATE TABLE Patients (
    patientID   integer PRIMARY KEY
  , SSN         char(11) UNIQUE check (REGEXP_LIKE(SSN, '^[0-9]{3}-[0-9]{2}-[0-9]{4}$'))
  , givenName   varchar2(50) /* patients may be brought in without an identifying information; null allowed */
  , surname     varchar2(50)
  , address     varchar2(100) /* maybe extend length */
  , phoneNumber varchar2(15) check (REGEXP_LIKE(phoneNumber, '^(\+[0-9]{9,15}|[0-9]{10})$'))
);

-- Employees (int *employeeID, 50 givenName, 50 surname, 60 title, int officeNumber, num salary, 17 position, int managerID)
CREATE TABLE Employees (
    employeeID   integer PRIMARY KEY
  , givenName    varchar2(50)
  , surname      varchar2(50) NOT NULL /* To work at the hospital, you need some name. */
  , title        varchar2(60)
  , officeNumber integer
  , salary       decimal(9, 2) /* allows pay in 1-cent intervals, up to 9,999,999.99 */
  , position     varchar2(17)
  , managerID    integer references Employees(employeeID)
);

-- Doctors (int *doctorID, 50 givenName, 50 surname, 1 gender, 30 specialty)
CREATE TABLE Doctors (
    doctorID     integer PRIMARY KEY
  , givenName    varchar2(50)
  , surname      varchar2(50) NOT NULL /* To work at the hospital, you need some name. */
  , gender       char(1) NOT NULL check (gender in ('M', 'F', 'O', 'U')) /* Male/Female/Other/Unspecified */
  , specialty    varchar2(30) /* maybe make longer */
/* Replacement for surname NOT NULL (requires at least one name) */
/*  , constraint Doctors_has_name check (givenName is not NULL or surname is not NULL) */
);



/* ***** ROOM DATA ***** */

-- Rooms (int *roomNumber, int isOccupied)
CREATE TABLE Rooms (
    roomNumber integer PRIMARY KEY
  , isOccupied integer check (isOccupied in (1, 0)) /* could be replaced with 'occupancy', the number of people in the room */
);

-- RoomSerives (int *roomNumber, 30 *service)
CREATE TABLE RoomServices (
    constraint RoomServices_pk PRIMARY KEY (roomNumber, service)
  , roomNumber integer references Rooms(roomNumber) on delete CASCADE /* if a room disappears, so do its services */
  , service    varchar(30)
);

-- RoomAccess (int *roomNumber, int *employeeID)
CREATE TABLE RoomAccess (
    constraint RoomAccess_pk PRIMARY KEY (roomNumber, employeeID)
  , roomNumber integer references Rooms(roomNumber) on delete CASCADE
  , employeeID integer references Employees(employeeID) on delete CASCADE
  /* If a room or employee disappears, so do relevant access permissions. */
);



/* ***** ADMISSION DATA ***** */

-- Admissions (int *admissionID, int patientID, date admissionDate, date releaseDate, num totalPayment, num insuranceCoverage)
CREATE TABLE Admissions (
    admissionID       integer PRIMARY KEY
  , patientID         integer references Patients(patientID)
  , admissionDate     date NOT NULL
  , releaseDate       date /* if null, ongoing hospitalization */
  , totalPayment      decimal(9, 2)
  , insuranceCoverage decimal(5, 4)
);

-- RoomStays (int *roomNumber, int *admissionID, time *startTime, time endTime)
CREATE TABLE RoomStays (
    constraint RoomStays_pk PRIMARY KEY (roomNumber, admissionID, startTime) /* unsure */
  , roomNumber  integer references Rooms(roomNumber)
  , admissionID integer references Admissions(admissionID)
  , startTime   date
  , endTime     date /* if null, ongoing stay */
);

-- Examinations (int *doctorID, time *examinationTime, int admissionID, 1000 results)
CREATE TABLE Examinations (
    constraint Examinations_pk PRIMARY KEY (doctorID, examinationTime)
  , doctorID        integer references Doctors(doctorID)
  , examinationTime date
  , admissionID     integer NOT NULL references Admissions(admissionID)
  , results         varchar2(1000) /* very large (at least 500; imagine all the things a doctor can say) */
);

-- Appointments (date *appointmentTime, int *patientID, int admissionFollowed)
CREATE TABLE Appointments (
    constraint Appointments_pk PRIMARY KEY (appointmentTime, patientID)
  , appointmentTime   date
  , patientID         integer references Patients(patientID)
  , admissionFollowed integer references Admissions(admissionID) /* may be null */
);



/* ***** EQUIPMENT ***** */

-- EquipmentTypes (100 *equipID, 100 model, 200 description, 1000 instructions)
CREATE TABLE EquipmentTypes (
  /* I asked the professor about ID/model. He said ID should be more specific
     information, and model more general. */
    equipID       varchar2(100) PRIMARY KEY /* e.g. 'GE 1.5T Optima 450W' */
  , model         varchar2(100) NOT NULL /* e.g. 'EEG'. Were this a proper database, I would say always use full names. */
  , description   varchar2(200)
  , instructions  varchar2(1000) /* maybe should be a clob instead of a varchar */
/*  , numberOfUnits integer */
);

-- EquipmentUnits (30 *serialNumber, 100 *typeID, int room, int yearPurchased, date inspectionDate)
CREATE TABLE EquipmentUnits (
    constraint EquipmentUnits_pk PRIMARY KEY (serialNumber, typeID)
  , serialNumber   varchar2(30)
  , typeID         varchar2(100) references EquipmentTypes(equipID)
  , room           integer       references Rooms(roomNumber) on delete SET NULL
  /* if room is null, unit is not in a room; if room is deleted, remove from room */
  , yearPurchased  smallint NOT NULL /* use to_date(yearPurchased, 'YYYY') for a date; a date can't just be a year */
  , inspectionDate date /* if null, never inspected */
);


CREATE VIEW AdmissionsAppointments AS
  SELECT Admissions.*, Appointments.appointmentTime as followupTime
  FROM Admissions LEFT JOIN Appointments
       ON Admissions.admissionID = Appointments.admissionFollowed;




/* ***** ***** ***** ***** ***** ***** ***** *\
 *          Section 2:  Sample Data          *
\* ***** ***** ***** ***** ***** ***** ***** */


-- Use ISO 8601 dates.
ALTER SESSION set nls_date_format = 'YYYY-MM-DD';

/* The entry method used is not scalable. For large datasets, insert one at a time.
   To enter rows, use the "entry" substitution variable as follows:

INSERT into {table name} (
  select {column value}, {column value}, ...
  &entry {column value}, {column value}, ...
  from dual);

   When this evaluates, each row entered becomes a table (selected from dual), all
   of which are combined (via "union all") and added to the table.

   (I ran this by the professor to make sure it was okay.)
*/
set verify off
define entry = " from dual union all select "


-- Doctors (*int doctorID, 50 givenName, 50 surname, 1 gender, 30 specialty)
INSERT into Doctors (
  select 0, '',          'EMH',     'O', 'Surgery'
  &entry 1, '',          'Phlox',   'M', 'Radiology'
  &entry 2, 'Beverly',   'Crusher', 'F', 'Surgery'
  &entry 3, 'Deanna',    'Troi',    'F', 'Psychology'
  &entry 4, 'Leonard',   'McCoy',   'M', 'Exobiology'
  &entry 5, 'Christine', 'Chapel',  'F', 'Exobiology'
  &entry 6, 'Katherine', 'Pulaski', 'F', 'Cardiology'
  &entry 7, 'Leonard',   'McCoy',   'M', 'Surgery' /* A clone? */
  &entry 8, 'Benjamin',  'Spock',   'M', 'Pediatrics'
  &entry 9, 'Julian',    'Bashir',  'M', null /* Couldn't think of a good specialty, so null it is. */
  from dual);


-- Employees (int *employeeID, 50 givenName, 50 surname, 60 title, int officeNumber, num salary, 17 position, int managerID)
/* 16 total, 10 normal, 4 division managers, 2 general managers */
INSERT into Employees (
  select      1, 'Miles',   'O''Brien', 'Chief of Operations',         106,  30000.7, 'General Manager', null
    &entry    6, 'Geordi',  'La Forge', 'Chief Engineer',              111,   3000.3, 'Division Manager',  1
      &entry  0, 'B''Elanna', 'Torres', 'Assistant Chief Engineer',    203,    897.6, 'Regular Employee',  6
      &entry  7, 'Jacob',     'Fakult', 'Database Administrator',      206, -50000,   'Regular Employee',  6 /* that's tuition, etc */
      &entry  9, 'Jacob',   'Komissar', 'Database Administrator',      207, -50000,   'Regular Employee',  6
      &entry 15, 'Reginald', 'Barclay', 'Systems Diagnostic Engineer', 204,   2000,   'Regular Employee',  6
    &entry   10, 'Janice', 'Rand', 'Assistant Chief of Operations',    107,  14000,   'Division Manager',  1
      &entry 14, '',     'Neelix', 'Head of Culinary Services',        243,    403,   'Regular Employee', 10
      &entry 13, '',        'Rom', 'Grand Nagus',                    400, 9999999.99, 'Regular Employee', 10 /* Wait, what? */
  &entry      4, 'Emp4 name1',  'Emp4 name2',  'Emp4 title',  108, 654321, 'General Manager', null
    &entry    2, 'Emp2 name1',  'Emp2 name2',  'Emp2 title',  110,      0, 'Division Manager', 4
      &entry  8, 'Emp8 name1',  'Emp8 name2',  'Emp8 title',  112,     71, 'Regular Employee', 2
      &entry 12, 'Emp12 name1', 'Emp12 name2', 'Emp12 title', 205,   2300, 'Regular Employee', 2
    &entry    5, 'Emp5 name1',  'Emp5 name2',  'Emp5 title',  109, 123456, 'Division Manager', 4
      &entry  3, 'Emp3 name1',  'Emp3 name2',  'Emp3 title',  113,      0, 'Regular Employee', 5
      &entry 11, 'Emp11 name1', 'Emp11 name2', 'Emp11, Ferroprojection Technician', 208, 105000, 'Regular Employee', 5
  from dual);


-- Patients (int *patientID, 11 +SSN, vchr50 givenName, 50 surname, 100 address, 15 phoneNumber)
/* 10 total, 5 must have at least 2 admissions */
INSERT into Patients (
  select  0, null,          'John',      'Doe',        '',                            '' /* An amnesiac! */
  &entry  1, '111-22-3333', 'John',      'Smith',      '5 Main Street, Town',         '' /* SSN required by project */
  &entry  2, '123-45-6789', 'Firstname', 'McLastname', '## Avenue Street, Town City', '1234567890'
  &entry  3, '987-65-4321', 'William',   'Williams',   '33 Jackson St, Willamsburg',  '9876543210'
  &entry  4, null,          'Mr.',       'Spock',      null,                          null /* Yes, I made his first name "Mr.". And he's a foreigner, of course. */
  &entry  5, '555-55-5555', 'Pentor',    'Quinte',     '55 Quincy Street, Fiville',   '5555555555' /* out of creativity too soon */
  &entry  6, '110-73-8164', 'Reginald',  'Barclay',    'Space',                       '+112358132134'
  &entry  7, '777-77-7777', 'Lucky',     'Lucky',      '7 Clover Circle',             '7777777777' /* Oh. */
  &entry  8, null,          'Gulnaz',    'Cherkezishvili', 'Somewhere in Georgia',    '+995004886223' /* Where did 7 go? */
  &entry  9, '003-26-1931', 'Leonard',   'Nimoy',      'Los Angeles',                 '1425055200' /* birth and death */
  &entry 10, '000-00-0000', 'Patient',   'McPatient',  'Patient Address',             '0000000000'
  from dual);


-- Rooms (int *roomNumber, int isOccupied)
/* at least 10, 3 must have 2 or more services */
INSERT into Rooms (
  select 120, 1
  &entry 121, 0
  &entry 132, 0
  &entry 133, 0
  &entry 214, 1
  &entry 215, 0
  &entry 226, 0
  &entry 227, 1
  &entry 238, 1
  &entry 239, 0
  from dual);


-- RoomServices (int *roomNumber, 30 *service)
/* 3 rooms must have 2+ */
INSERT into RoomServices (
  select 132, 'Intensive Care Unit' /* one service each */
  &entry 133, 'Intensive Care Unit'
  &entry 214, 'Service 3'
  &entry 215, 'Service 3'

  &entry 120, 'Service 1' /* rooms with multiple services */
  &entry 120, 'Service 5'

  &entry 121, 'Service 1'
  &entry 121, 'Service 5'

  &entry 226, 'Service 4'
  &entry 226, 'Service 6'

  &entry 227, 'Service 4'
  &entry 227, 'Service 6'

  &entry 238, 'Service 4'
  &entry 238, 'Service 5'

  &entry 239, 'Service 4'
  &entry 239, 'Service 5'
  &entry 239, 'Service 6'
  from dual);


-- RoomAccess (int *roomNumber, int *employeeID)
INSERT into RoomAccess (employeeID, roomNumber) (
  select 0, 120 /* separated by employee */
  &entry 0, 121
  &entry 0, 226
  &entry 0, 227
  &entry 0, 238
  &entry 0, 239

  &entry 1, 120 /* 1 may access all rooms */
  &entry 1, 121
  &entry 1, 132
  &entry 1, 133
  &entry 1, 214
  &entry 1, 215
  &entry 1, 226
  &entry 1, 227
  &entry 1, 238
  &entry 1, 239

  &entry 2, 121
  &entry 2, 133
  &entry 2, 215
  &entry 2, 227
  &entry 2, 239

  &entry 3, 214
  &entry 3, 215
  &entry 3, 226
  &entry 3, 227
  &entry 3, 238
  &entry 3, 239

  &entry 4, 121
  &entry 4, 133
  &entry 4, 214
  &entry 4, 227
  &entry 4, 238

  &entry 5, 120
  &entry 5, 121

  &entry 6, 132
  &entry 6, 133
  &entry 6, 226
  &entry 6, 227
  &entry 6, 238
  &entry 6, 239

  &entry 7, 132
  &entry 7, 133

  &entry 8, 120
  &entry 8, 132
  &entry 8, 214
  &entry 8, 226
  &entry 8, 238

  &entry 9, 132
  &entry 9, 133

  &entry 10, 226
  &entry 10, 227
  &entry 10, 238
  &entry 10, 239

  &entry 12, 214
  &entry 12, 215

  &entry 13, 120
  &entry 13, 132
  &entry 13, 214
  &entry 13, 226

  &entry 14, 120
  &entry 14, 121
  &entry 14, 132
  &entry 14, 133

  &entry 15, 120
  &entry 15, 121
  &entry 15, 238
  &entry 15, 239
  from dual);



-- Admissions (int *admissionID, int patientID, date admissionDate, date releaseDate, num totalPayment, num insuranceCoverage)
/* self-imposed: at least 15; 4 patients with 1 each, 4 with 2 each, 1 with 3, 1 with 0 */
INSERT into Admissions (
  select  1, 1, '0111-11-11', '1111-11-11', 111111.11, 1      /* 1000 years */
  &entry  0, 0, '1995-04-12', null, null, null                /* ongoing */
  &entry 11, 1, '2001-01-01', '2011-01-01',  10000,    0.7359 /* 10 years */
  &entry  2, 2, '2002-02-02', '2002-02-06',   8000,    0.1875 /* 4 days */
  &entry  4, 4, '2004-04-04', '2004-04-04',   3000,    0.35   /* 1 day */
  &entry  6, 6, '2006-06-06', '2006-06-12', 300000.3,  0.3    /* 6 days */
  &entry  7, 7, '2007-07-07', '2007-07-17', 777777.7,  0.7    /* 10 days */
  &entry  8, 8, '2008-08-08', '2009-01-03', 876543.21, 0.9    /* 4 months 26 days */
  &entry  9, 9, '2009-09-09', '2009-10-10',    100,    0.37   /* 1 month 1 day */
  &entry 12, 2, '2012-12-12', '2013-01-13', 500000,    0.2    /* 1 month 1 day */
  &entry 18, 8, '2018-06-18', null,          12000,    0.3333 /* ongoing */
  &entry 17, 7, '2017-07-07', '2017-07-27',  77777,    0      /* 20 days */
  &entry 14, 4, '4444-04-04', null,          null,     null   /* ongoing */
  &entry  5, 5, '5555-05-05', '5555-05-05',  55555.5,  0.5    /* 1 day; no rooms */
  &entry 77, 7, '7777-07-07', null,            777,    0.7777 /* ongoing */

  /* extra entries */
  &entry 100, 10, '1000-01-01', '1000-12-31', 100000,  0.5
  &entry 101, 10, '1001-01-01', '1001-12-31', 100000,  0.5
  &entry 102, 10, '1002-01-01', '1002-12-31', 100000,  0.5
  &entry 103, 10, '1003-01-01', '1003-12-31', 100000,  0.5
  &entry 104, 10, '1004-01-01', '1004-12-31', 100000,  0.5
  &entry 105, 10, '1005-01-01', '1005-12-31', 100000,  0.5
  &entry 106, 10, '1006-01-01', '1006-12-31', 100000,  0.5
  &entry 107, 10, '1007-01-01', '1007-12-31', 100000,  0.5
  &entry 108, 10, '1008-01-01', '1008-12-31', 100000,  0.5
  &entry 109, 10, '1009-01-01', '1009-12-31', 100000,  0.5
  &entry 110, 10, '1010-01-01', '1010-12-31', 100000,  0.5

  from dual);



-- Add hour and minute to time format for entring more precise times.
ALTER SESSION set NLS_DATE_FORMAT = 'YYYY-MM-DD HH24:MI';


-- RoomStays (int *roomNumber, int *admissionID, time *startTime, time endTime)
/* Note: admission 5 should never use a room. */
INSERT into RoomStays (
  /* rooms currently in use */
  select 120,  0, '2015-08-03 0:0', null
  &entry 227, 77, '7777-07-07 7:7', null
  &entry 214, 14, '4444-04-04 4:4', null
  &entry 238, 18, '2019-03-14 18:36', null

  &entry 121, 4, '2004-04-04 10:30', '2004-04-04 14:50'

  &entry 132, 11, '2001-01-01 10:01', '2001-01-01 11:00'
  &entry 227, 11, '2001-01-01 11:11', '2002-01-01 11:10'
  &entry 239, 11, '2002-01-01 11:11', '2007-01-01 01:00'
  &entry 227, 11, '2007-01-01 01:10', '2011-01-01 11:11'

  &entry 132,  2, '2002-02-02 02:02', '2002-02-02 20:20'
  &entry 214,  2, '2002-02-02 20:22', '2002-02-04 02:02'
  &entry 133, 12, '2012-12-12 02:02', '2012-12-12 20:20'

  &entry 133,  8, '2008-08-08 08:00', '2008-08-08 08:08'
  &entry 133,  8, '2008-10-08 08:00', '2008-10-08 08:08'
  &entry 133,  8, '2008-12-08 08:00', '2008-12-08 08:08'

  &entry 133,  1, '0111-11-11 11:00', '0111-11-11 11:11'
  &entry 133,  1, '0112-11-11 11:00', '0112-11-11 11:11'
  &entry 133,  1, '0113-11-11 11:00', '0113-11-11 11:11'
  &entry 133,  1, '0114-11-11 11:00', '0114-11-11 11:11'
  &entry 133,  1, '0115-11-11 11:00', '0115-11-11 11:11'
  from dual);

-- Examinations (int *doctorID, time *examinationTime, int admissionID, 1000 results)
/* SSN 111-22-3333 must be examined by the same doctor twice in one visit. */
INSERT into Examinations (
  select 3, '1995-04-13 15:00', 0, 'This patient is an clearly amnestic.'
  &entry 9, '2009-09-09 21:35', 9, 'Nothing interesting to see here; move along.'
  &entry 7, '2007-07-13 13:13', 7, 'This man is remarkably unlucky.'
  &entry 0, '2008-11-05 14:00', 8, 'How do you pronounce this woman''s name?'

  &entry 2, '2001-01-01 10:01', 11, 'Patient resuscitated after heart attack.'
  &entry 6, '2002-01-01 11:00', 11, 'Patient stable, but likely to relapse.'
  &entry 0, '2003-01-01 11:11', 11, 'Patient stable after emergency operation.'
  &entry 3, '2004-01-01 01:10', 11, 'Patient appears mentally stable.'
  &entry 6, '2005-01-01 11:00', 11, 'Patient''s heart acting normal.'
  &entry 2, '2006-01-01 10:01', 11, 'First operation completed without complications.'
  &entry 2, '2007-01-01 10:01', 11, 'Second operation completed without complications.'
  &entry 6, '2008-01-01 11:00', 11, 'Patient recovering well from operations.'
  &entry 3, '2009-01-01 01:10', 11, 'Patient remains mentally stable despite extended stay.'
  &entry 6, '2010-01-01 11:00', 11, 'Patient should be ready for release within 2 years.'

  -- doctor 6 has 11 total examinations, but during only 2 admissions
  &entry 6, '1000-01-01 06:00', 100, 'Doctor 6 admission 100 examination 1.'
  &entry 6, '1000-01-02 06:00', 100, 'Doctor 6 admission 100 examination 2.'
  &entry 6, '1000-01-03 06:00', 100, 'Doctor 6 admission 100 examination 3.'
  &entry 6, '1000-01-04 06:00', 100, 'Doctor 6 admission 100 examination 4.'
  &entry 6, '1000-01-05 06:00', 100, 'Doctor 6 admission 100 examination 5.'
  &entry 6, '1000-01-06 06:00', 100, 'Doctor 6 admission 100 examination 6.'
  &entry 6, '1000-01-07 06:00', 100, 'Doctor 6 admission 100 examination 7.'


  -- doctor 4 should have over 11 admission cases (0 above here)
  &entry 4, '1111-04-01 06:00', 1, 'Doctor 4 admission 1 examination 1.'
  &entry 4, '1000-04-01 04:00', 100, 'Doctor 4 admission 100 examination 1.'
  &entry 4, '1001-04-01 04:01', 101, 'Doctor 4 admission 101 examination 1.'
  &entry 4, '1002-04-02 04:00', 102, 'Doctor 4 admission 102 examination 1.'
  &entry 4, '1003-04-03 04:00', 103, 'Doctor 4 admission 103 examination 1.'
  &entry 4, '1004-04-04 04:00', 104, 'Doctor 4 admission 104 examination 1.'
  &entry 4, '1005-04-05 04:00', 105, 'Doctor 4 admission 105 examination 1.'
  &entry 4, '1006-04-06 04:00', 106, 'Doctor 4 admission 106 examination 1.'
  &entry 4, '1007-04-07 04:00', 107, 'Doctor 4 admission 107 examination 1.'
  &entry 4, '1008-04-08 04:00', 108, 'Doctor 4 admission 108 examination 1.'
  &entry 4, '1009-04-09 04:00', 109, 'Doctor 4 admission 109 examination 1.'
  &entry 4, '1010-04-10 04:00', 110, 'Doctor 4 admission 110 examination 1.'


  -- doctor 2 should have 11 admission cases (1 above here)
  &entry 2, '1000-02-01 02:00', 100, 'Doctor 2 admission 100 examination 1.'
  &entry 2, '1001-02-01 02:01', 101, 'Doctor 2 admission 101 examination 1.'
  &entry 2, '1002-02-02 02:00', 102, 'Doctor 2 admission 102 examination 1.'
  &entry 2, '1003-02-03 02:00', 103, 'Doctor 2 admission 103 examination 1.'
  &entry 2, '1004-02-04 02:00', 104, 'Doctor 2 admission 104 examination 1.'
  &entry 2, '1005-02-05 02:00', 105, 'Doctor 2 admission 105 examination 1.'
  &entry 2, '1006-02-06 02:00', 106, 'Doctor 2 admission 106 examination 1.'
  &entry 2, '1007-02-07 02:00', 107, 'Doctor 2 admission 107 examination 1.'
  &entry 2, '1008-02-08 02:00', 108, 'Doctor 2 admission 108 examination 1.'
  &entry 2, '1009-02-09 02:00', 109, 'Doctor 2 admission 109 examination 1.'
  &entry 2, '1010-02-10 02:00', 110, 'Doctor 2 admission 110 examination 1.'

  from dual);



/*
 1, 1, '0111-11-11', '1111-11-11', 111111.11, 1
 0, 0, '1995-04-12', null, null, null
11, 1, '2001-01-01', '2011-01-01',  10000,    0.7359 -- carefully worked examinations and room stays
 2, 2, '2002-02-02', '2002-02-06',   8000,    0.1875
 4, 4, '2004-04-04', '2004-04-04',   3000,    0.35
 6, 6, '2006-06-06', '2006-06-12', 300000.3,  0.3
 7, 7, '2007-07-07', '2007-07-17', 777777.7,  0.7
 8, 8, '2008-08-08', '2009-01-03', 876543.21, 0.9
 9, 9, '2009-09-09', '2009-10-10',    100,    0.37
12, 2, '2012-12-12', '2013-01-13', 500000,    0.2
18, 8, '2018-06-18', null,          12000,    0.3333
17, 7, '2017-07-07', '2017-07-27',  77777,    0
14, 4, '4444-04-04', null,          null,     null
 5, 5, '5555-05-05', '5555-05-05',  55555.5,  0.5
77, 7, '7777-07-07', null,            777,    0.7777
*/

-- Appointments (time *appointmentTime, int *patientID, int admissionFollowed)
/* SSN 111-22-3333 must have an upcoming appointment
   Notes:
   Patient 3 should have 1 appointment.
   Patient 1 should have exactly 1 appointment, which much follow an admission.
*/
INSERT into Appointments (
  select '2111-11-11 11:11', 1, 11
  &entry '2017-02-02 02:02', 2,  2
  &entry '2018-02-02 02:02', 2, 12
  &entry '3333-03-03 03:30', 3, null /* has had no admissions */
  &entry '2017-06-06 06:00', 6, null
  &entry '2019-08-08 12:00', 8, null
  &entry '2020-08-08 16:00', 8, 18
  &entry '2017-09-09 09:00', 9, null
  from dual);

-- Remove hour and minute again.
ALTER SESSION set NLS_DATE_FORMAT = 'YYYY-MM-DD';



-- EquipmentTypes (100 *equipID, 100 model, 200 description, 1000 instructions)
INSERT into EquipmentTypes (
  select 'TR-580 Medical Tricorder VII', 'Medical Tricorder', 'General-purpose portable scanner/emitter.',
         'Open tricorder and point at subject. Results will appear on the display. If results are not useful,'
         || ' press buttons until useful results appear. Do not use near temporal distorations.'
  &entry 'TR-590 Medical Tricorder X', 'Medical Tricorder', 'General-purpose portable scanner/emitter.',
         'Open tricorder and point at subject. Press buttons until you get interesting results.'
         || 'Refer to full technical manual for details.'
  &entry 'Companyname Machine Mark Number', 'Turboencabulator', 'The turboencabulator is capable of both'
         || ' supplying inverse reactive current for use in unilateral phase detractors and automatically'
         || ' synchronizing cardinal grammeters.', 'To use the turboencabulator, please reference the'
         || ' "Manual for the Use of the CDSMM Mark N Turboencabulator". Please note that if you are not'
         || ' trained in the use of turboencabulators, it is generally prudent to delegate the issue to your'
         || ' resident ferroprojection technician.'
  &entry 'MRI', 'Some sort of Magnetic Resonance Imager', 'It''s big and loud.', 'See the operation manual.'
  from dual);

-- EquipmentUnits (30 *serialNumber, 100 *typeID, int room, int yearPurchased, date inspectionDate)
/* 3 per type, 1 type should have units from 2010 and 2011 */
/* Note: Date literals used to allow use of year 0. */
INSERT into EquipmentUnits (
  select 'VX03-BBN', 'Companyname Machine Mark Number', 238,  1967, date'1988-10-31'
  &entry 'VX33-QZX', 'Companyname Machine Mark Number', 226,  1697, date'4444-06-14'
  &entry 'XKCD.COM', 'Companyname Machine Mark Number', null, 3023, null
  &entry 'QQQQ-QQQ', 'Companyname Machine Mark Number', 121,  -850, date'0000-01-01'

  &entry 'G32-001D-MD4', 'TR-580 Medical Tricorder VII', 121, 2368, date'2373-05-14'
  &entry 'G32-993C-MD3', 'TR-580 Medical Tricorder VII', 239, 2368, date'2373-05-12'
  &entry 'G32-002D-MD4', 'TR-580 Medical Tricorder VII', 132, 2368, date'2373-04-30'

  &entry 'A01-02X', 'TR-590 Medical Tricorder X',  133, 2010, date'2373-10-11' /* serial number required by project */
  &entry 'A03-02X', 'TR-590 Medical Tricorder X', null, 2011, date'2373-10-12'
  &entry 'A10-02Y', 'TR-590 Medical Tricorder X',  238, 2374, date'2374-10-12'
  from dual);

-- Remove data entry substitution variable.
undefine entry
set verify on






/* ***** ***** ***** ***** ***** ***** ***** *\
 *            Section 3:  Queries            *
\* ***** ***** ***** ***** ***** ***** ***** */



/* NEEDS TO BE DONE */

/* Q1: List the room number of currently occupied rooms */
prompt QUESTION 1 QUERY (should be 120, 214, 227, 238)
SELECT roomNumber AS occupiedRooms
FROM Rooms
WHERE isOccupied=1;


/* Q2: Display the employees ID, names, and salary of all employees working under an employee with id=10 */
prompt QUESTION 2 QUERY (should be 14 and 13)
SELECT employeeID, givenName, surname, salary
FROM Employees
WHERE managerID=10;


/* Q3: For all patients, report SSN, and sum of insurance payments over all visits */
prompt QUESTION 3 QUERY (should be 101500 for patient 2)
SELECT patientID, SSN, NVL(SUM(insurancePayments), 0) AS totalInsurancePayments
FROM (SELECT P.patientID, SSN, (insuranceCoverage * totalPayment) AS insurancePayments
      FROM Patients P, Admissions A
      WHERE P.patientID = A.patientID)
GROUP BY patientID, SSN;


/* Q4: Report SSN, first last name, and number of visits from each patient */
prompt QUESTION 4 QUERY (should be 0:1 1:2 2:2 3:0 4:2 5:1 6:1 7:3 8:2 9:1)
/* It is essential that the count be an attribute of A, and not P.
   That's how this is able to include a count of 0 for patients without visits.
 */
SELECT P.patientID, SSN, givenName, surname, count(A.patientID) AS "NUMBER OF VISITS"
FROM Patients P LEFT JOIN Admissions A
     ON P.PatientID=A.patientID
GROUP BY P.patientID, SSN, givenName, surname;


/* Q5: Report the room number that has equipment unit A01-02X*/
prompt QUESTION 5 QUERY (should be 133)
SELECT R.roomNumber
FROM Rooms R, EquipmentUnits E
WHERE (R.roomNumber = E.room) AND (E.serialNumber = 'A01-02X');


/* Q6: Report the one (or multiple) employees with access to the most rooms */
prompt QUESTION 6 QUERY (should be 1)
SELECT employeeID, count(*) AS totalRooms
FROM RoomAccess
GROUP BY employeeID
HAVING count(*)=(SELECT MAX(count)
                 FROM (SELECT count(*) as count
                       FROM RoomAccess
                       GROUP BY employeeID));



/* Q7: Report the count of every employee rank in the hospital */
prompt QUESTION 7 QUERY (should be 10/4/2)
SELECT position || 's' AS Type, count(*) AS Count
FROM Employees
GROUP BY position;
/*
ORDER BY CASE WHEN Employees.position = 'General Manager' THEN 1
              WHEN Employees.position = 'Division Manager' THEN 2
              WHEN Employees.position = 'Regular Employee' THEN 3 END DESC;
*/
/* The commented-out "ORDER BY" clause sorts the table by rank. */


/* Q8: Report SSN, first, last, and time for any patient who has scheduled a future visit */
prompt QUESTION 8 QUERY (should be patients 1, 2, 2, 3, 6, 8, 8, 9)
prompt (Assumption: Patients with multiple scheduled visits should list all such appointments.)
SELECT patientID, SSN, givenName, surname, appointmentTime
FROM Patients NATURAL JOIN Appointments;


/* Q9: Report type ID, model, and #units for any equipment type with more than 3 units */
prompt QUESTION 9 QUERY (output should be the Turboencabulator)
SELECT equipID, model, count(*) AS totalUnits
FROM EquipmentTypes T, EquipmentUnits U
WHERE (T.equipID=U.typeID)
GROUP BY T.equipID, T.model
HAVING count(*)>3;


/* Q10: Report the date of the scheduled visits for patient with SSN=111-22-333 */
prompt QUESTION 10 QUERY (output should be 2111-11-11)
SELECT appointmentTime
FROM Patients NATURAL JOIN Appointments
WHERE SSN = '111-22-3333';


/* Q11: Report doctors id who have examined patient with SSN=111-22-333 more than 2 times */
prompt QUESTION 11 QUERY (output should be 6 and 2)
SELECT doctorID
FROM Admissions NATURAL JOIN Examinations NATURAL JOIN Patients
WHERE (SSN = '111-22-3333')
GROUP BY doctorID
HAVING count(*) > 2;


/* Q12: Report type ID for equipment type with units purchased in both 2010 and 2011. */
prompt QUESTION 12 QUERY (output should be TR-590...)
(SELECT typeID
 FROM EquipmentUnits
 WHERE yearPurchased=2010)
INTERSECT
(SELECT typeID
 FROM EquipmentUnits
 WHERE yearPurchased=2011);

prompt PLEASE NOTE: Certain query results may include additional columns.
prompt (Particularly, patientID is listed along with SSN any time SSN is required.)
prompt See source file for details.




/* ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** *\
 * ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** *
 * ***** ***** *****         PHASE 3         ***** ***** ***** *
 * ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** *
\* ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** */


/* Table for comparing employee ranks by a numeric value. */
-- CREATE TABLE EmployeeHeirarchy (position varchar2(17), priority integer);
-- INSERT INTO EmployeeHeirarchy VALUES ('General Manager',  2);
-- INSERT INTO EmployeeHeirarchy VALUES ('Division Manager', 1);
-- INSERT INTO EmployeeHeirarchy VALUES ('Regular Employee', 0);


set serveroutput on
/* View Q1: CriticalCases
 * Patients who have been to ICU 2+ times. (id, ssn, name, name, numberOfICUvisits
 * Should return patient 2 with 2 visits, 8 with 3, 1 with 5
 */
CREATE VIEW CriticalCases AS
  SELECT patientID, SSN, givenName, surname, count(*) AS numberOfAdmissionsToICU
  FROM Patients NATURAL JOIN Admissions NATURAL JOIN RoomStays NATURAL JOIN RoomServices
  WHERE RoomServices.service = 'Intensive Care Unit'
  GROUP BY patientID, SSN, givenName, surname
  HAVING count(*) >= 2

-- -- More explicit version
-- CREATE VIEW CriticalCases AS
--   SELECT patientID, SSN, givenName, surname, count(*) AS numberOfAdmissionsToICU
--   FROM Patients, Admissions, RoomStays, RoomServices
--   WHERE Patients.patientID = Admissions.patientID
--     AND Admissions.admissionID = RoomStays.admissionID
--     AND RoomStays.roomNumber = RoomServices.roomNumber
--     AND RoomServices.service = 'Intensive Care Unit'
--   GROUP BY patientID, SSN, givenName, surname
--   HAVING count(*) >= 2;

-- CREATE VIEW CriticalCases AS
--   SELECT patientID, SSN, givenName, surname, count(*) AS numberOfAdmissionsToICU
--   FROM         Patients
--   JOIN Admissions   ON Patients.patientID = Admissions.patientID
--   JOIN RoomStays    ON Admissions.admissionID = RoomStays.admissionID
--   JOIN RoomServices ON RoomStays.roomNumber = RoomServices.roomNumber
--   WHERE RoomServices.service = 'Intensive Care Unit'
--   GROUP BY patientID, SSN, givenName, surname
--   HAVING count(*) >= 2;

/* View Q2: DoctorsLoad
 * Show ID, gender, load of doctors who have examined over 10 admissions.
 * Overloads should be doctors 2 and 4 only.
 */
CREATE VIEW DoctorsLoad AS
  SELECT Doctors.doctorID, gender, (CASE WHEN COUNT(DISTINCT admissionID)>10
                            THEN 'Overloaded' ELSE 'Underloaded' END) as load
  FROM Doctors LEFT JOIN Examinations
    ON Doctors.doctorID = Examinations.doctorID
  GROUP BY Doctors.doctorID, gender
/*  ORDER BY Doctors.doctorID */;

/* View Q3: Use views to report patients with over 4 ICU visits.
 * Should be patient 1 only.
 */
prompt VIEW QUESTION 3 (should be patient 1 only)
SELECT * FROM CriticalCases WHERE numberOfAdmissionsToICU > 4;

/* View Q4: Report ID and names of female overloaded doctors. */
prompt VIEW QUESTION 4 (should be doctor 2 only)
SELECT doctorID, givenName, surname
FROM Doctors NATURAL JOIN DoctorsLoad
WHERE load = 'Overloaded' AND gender = 'F';


/* View Q5: Report doctorID, patientID, SSN, and comment
   from underloaded doctors examining critical cases. */
prompt VIEW QUESTION 5 (DoctorID-PatientID*Times: 0-8*1, 6-1*4, 0-1*1, 3-1*2)
SELECT doctorID, patientID, SSN, results
FROM  (SELECT doctorID, admissionID, results
       FROM Doctors NATURAL JOIN Examinations NATURAL JOIN DoctorsLoad
       WHERE load = 'Underloaded')
  NATURAL JOIN
      (SELECT patientID, SSN, admissionID
       FROM CriticalCases NATURAL JOIN Admissions);



/* Trigger 1: Rooms may not offer over 3 services. */
CREATE OR REPLACE TRIGGER max_3_services_per_room
AFTER INSERT OR UPDATE ON RoomServices
DECLARE
  num integer;
BEGIN
  /* select number of rooms with over 3 services */
  SELECT count(*)
  INTO num
  FROM (SELECT roomNumber   FROM RoomServices
        GROUP BY roomNumber HAVING count(*) > 3);

  IF (num <> 0)
  THEN RAISE_APPLICATION_ERROR(-20001, 'Too many services for one room (max 3).');
  END IF;
END;
/

/* Trigger 2: Insurance is always 70% */
CREATE OR REPLACE TRIGGER insurance_always_70_percent
BEFORE INSERT OR UPDATE ON Admissions
FOR EACH ROW
BEGIN
  :new.insuranceCoverage := 0.7;
END;
/

/* Triggers 3 and 4: Employees myst have supervisors of the correct rank at all times. */
CREATE OR REPLACE TRIGGER enforce_employee_heirarchy
AFTER INSERT OR UPDATE OR DELETE ON Employees
DECLARE invalidEmployees integer;
BEGIN
  /* get the number of employees placed improperly in the heirarchy */
  SELECT count(*)
  INTO invalidEmployees
  FROM
  (  /* employees with wrong-ranked manager */
    (SELECT E1.employeeID
     FROM Employees E1
     JOIN Employees E2          ON E1.managerID = E2.employeeID
     -- JOIN EmployeeHeirarchy EH1 ON E1.position = EH1.position
     -- JOIN EmployeeHeirarchy EH2 ON E2.position = EH2.position
     -- WHERE EH1.priority+1 = EH2.priority
     WHERE NOT ((E1.position = 'Regular Employee' AND E2.position = 'Division Manager')
             OR (E1.position = 'Division Manager' AND E2.position = 'General Manager')))
    UNION ALL
     /* non-General Managers without a manager */
    (SELECT employeeID FROM Employees
     WHERE position <> 'General Manager' AND managerID IS NULL)
  );

  IF (invalidEmployees <> 0)
  THEN RAISE_APPLICATION_ERROR(-20002, 'Invalid employee heirarchy.');
  END IF;
END;
/
-- -- Heirarchy integrity tests:
-- -- gen: 1,4 - ddiv: 6,10 - reg: 0,3
-- UPDATE Employees SET managerID=NULL WHERE employeeID=1 /* pass */;
-- UPDATE Employees SET managerID=4 WHERE employeeID=1 /* fail */;
-- UPDATE Employees SET managerID=6 WHERE employeeID=1 /* fail */;
-- UPDATE Employees SET managerID=0 WHERE employeeID=1 /* fail */;

-- UPDATE Employees SET managerID=NULL WHERE employeeID=6 /* fail */;
-- UPDATE Employees SET managerID=4 WHERE employeeID=6 /* pass */;
-- UPDATE Employees SET managerID=10 WHERE employeeID=6 /* fail */;
-- UPDATE Employees SET managerID=0 WHERE employeeID=6 /* fail */;

-- UPDATE Employees SET managerID=NULL WHERE employeeID=0 /* fail */;
-- UPDATE Employees SET managerID=1 WHERE employeeID=0 /* fail */;
-- UPDATE Employees SET managerID=10 WHERE employeeID=0 /* pass */;
-- UPDATE Employees SET managerID=3 WHERE employeeID=0 /* fail */;


-- Employees (employeeID, givenName, surname, title, officeNumber, salary, managerID)


/* Trigger 5: Add appointment 3 months after entering the ICU.
 * Assumtion: 3 months is exactly 90 days.
 * If the patient already has an appointment that day, one will be added at
 *   least 1 hour after the existing appointment, a whole number of hours after
 *   the intended time. (e.g. attempting to add an appointment at 2:03 when one
 *   exists at 1:30 and one exists at 3:00, the new appointment will be added at
 *   4:03).
 */
CREATE OR REPLACE TRIGGER add_appointment_after_ICU
AFTER INSERT ON RoomStays
FOR EACH ROW
DECLARE
  patient   integer;
  isICUroom integer;
  offset    interval day to second := interval '90' day;
  timetaken integer;
BEGIN
  SELECT count(*) INTO isICUroom
  FROM RoomServices WHERE roomNumber = :new.roomNumber and service = 'Intensive Care Unit';

  SELECT patientID INTO patient
  FROM Admissions WHERE admissionID = :new.admissionID;

  IF (isICUroom <> 0)
  THEN
    LOOP
      /* reject current offset if it puts the new appointment under an hour after one that already exists */
      SELECT count(*) INTO timetaken FROM Appointments
      WHERE patientid = patient AND abs(:new.startTime + offset - appointmentTime) < (1/24);
      EXIT WHEN (timetaken = 0);
      offset := offset + interval '1' hour;
  END LOOP;

  INSERT INTO Appointments VALUES (:new.startTime + offset, patient, :new.admissionID);
  END IF;
END;
/
-- -- These three statements are the example shown above.
-- -- Make sure the correct date format is active.
-- insert into appointments values ('2001-05-30 1:30', 10, null);
-- insert into appointments values ('2001-05-30 3:00', 10, null);
-- insert into roomstays values (132, 101, '2001-03-01 2:03', null);



/* Trigger 6: MRIs must be purchased on dates after 2005 (no NULL).
 * NOT NULL already enforced.
 * This trigger will not work if it is added after any pre-2005 MRIs.
 */
CREATE OR REPLACE TRIGGER MRI_only_after_2005
AFTER INSERT OR UPDATE ON EquipmentUnits
DECLARE oldest smallint;
BEGIN
  SELECT MIN(yearPurchased)
  INTO oldest
  FROM EquipmentUnits
  WHERE typeID = 'MRI';
  IF (oldest <= 2005)
  THEN RAISE_APPLICATION_ERROR(-20003, 'MRI may not be purchased before 2005.');
  END IF;
END;
/


/* Trigger 7: Show all doctors that have previously examined each newly-admitted patient. */
CREATE OR REPLACE TRIGGER show_docs_for_new_admissions
BEFORE INSERT ON Admissions
FOR EACH ROW
BEGIN
  FOR curs IN (
    SELECT DISTINCT Doctors.doctorID, Doctors.givenName, Doctors.surname
    FROM Patients NATURAL JOIN Admissions NATURAL JOIN Examinations
    JOIN Doctors ON Examinations.doctorID = Doctors.doctorID
    WHERE patientID = :new.patientID
  ) LOOP
    DBMS_OUTPUT.PUT_LINE(curs.givenName || ' ' || curs.surname);
  END LOOP;
END;
/

/* IMPORTANT
 *
 * MUST HAVE SEPARATE FILE DESCRIBING TRIGGERS
 */



-- set serveroutput off
