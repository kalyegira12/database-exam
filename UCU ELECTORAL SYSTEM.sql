-- Active: 1726470671500@@127.0.0.1@3306
CREATE DATABASE VOTTINGSYSTEM;
USE VOTTINGSYSTEM;

-- Faculty Table
CREATE TABLE Faculty (
    FacultyID VARCHAR(20) PRIMARY KEY,
    FacultyName VARCHAR(100) NOT NULL
);

-- Positions Table
CREATE TABLE Positions (
    PositionID VARCHAR(50) PRIMARY KEY,
    PositionName VARCHAR(100) NOT NULL
);

-- Student Table
CREATE TABLE Student (
    StudentID VARCHAR(70) PRIMARY KEY,
    Names VARCHAR(100) NOT NULL,
    FacultyID VARCHAR(20) NOT NULL,
    Email VARCHAR(100) NOT NULL,
    PhoneNumber VARCHAR(15),
    YearOfStudy INT NOT NULL,
    Nationality VARCHAR(100) NOT NULL,
    ResidentInfo VARCHAR(100) NOT NULL,
    CGPA DECIMAL(3, 2) CHECK (CGPA >= 0.00 AND CGPA <= 5.00),
    FOREIGN KEY (FacultyID) REFERENCES Faculty(FacultyID),
    CONSTRAINT chk_YearOfStudy CHECK (YearOfStudy BETWEEN 1 AND 6)
);

-- Electoral Commission Table
CREATE TABLE ElectoralCommission (
    CommissionID VARCHAR(30) PRIMARY KEY,
    MemberName VARCHAR(100) NOT NULL,
    Roles VARCHAR(40),
    ContactInfo VARCHAR(20),
    StartDate DATE NOT NULL,
    EndDate DATE
);

-- Candidate Table
CREATE TABLE Candidate (
    CandidateID VARCHAR(30) PRIMARY KEY,
    StudentID VARCHAR(70) NOT NULL,
    PositionID VARCHAR(50) NOT NULL,
    FacultyID VARCHAR(20) NOT NULL,
    ApprovalDate DATE,
    FOREIGN KEY (StudentID) REFERENCES Student(StudentID),
    FOREIGN KEY (PositionID) REFERENCES Positions(PositionID),
    FOREIGN KEY (FacultyID) REFERENCES Faculty(FacultyID)
);


-- Application Table
CREATE TABLE Application (
    ApplicationID VARCHAR(30) PRIMARY KEY,
    StudentID VARCHAR(70) NOT NULL,
    CGPA DECIMAL(3, 2) NOT NULL,
    PaymentStatus ENUM('Paid', 'Unpaid') NOT NULL,
    QualificationStatus ENUM('Qualified', 'Not Qualified') NOT NULL,
    FOREIGN KEY (StudentID) REFERENCES Student(StudentID),
    CONSTRAINT chk_Qualification CHECK (QualificationStatus = 'Qualified' AND CGPA >= 4.00)
);

-- Vetting Table
CREATE TABLE Vetting (
    VettingID VARCHAR(30) PRIMARY KEY,
    CandidateID VARCHAR(30) NOT NULL,
    VettingStatus ENUM('Approved', 'Rejected') NOT NULL,
    Remarks VARCHAR(255),
    FOREIGN KEY (CandidateID) REFERENCES Candidate(CandidateID)
);

-- Verification Code Table
CREATE TABLE VerificationCode (
    CodeID VARCHAR(30) PRIMARY KEY,
    StudentID VARCHAR(70) NOT NULL,
    Code VARCHAR(10) NOT NULL,
    IsUsed BOOLEAN DEFAULT FALSE,
    GeneratedAt DATETIME NOT NULL,
    FOREIGN KEY (StudentID) REFERENCES Student(StudentID)
);

-- Votes Table
CREATE TABLE Votes (
    VoteID VARCHAR(20) PRIMARY KEY,
    VoterID VARCHAR(70) NOT NULL,
    CandidateID VARCHAR(30) NOT NULL,
    Timestamp DATETIME NOT NULL,
    FOREIGN KEY (VoterID) REFERENCES Student(StudentID),
    FOREIGN KEY (CandidateID) REFERENCES Candidate(CandidateID)
);

-- Results Table
CREATE TABLE Results (
    ResultID VARCHAR(10) PRIMARY KEY,
    CandidateID VARCHAR(30) NOT NULL,
    TotalVotes INT NOT NULL,
    FOREIGN KEY (CandidateID) REFERENCES Candidate(CandidateID)
);

-- Nominations Table
CREATE TABLE Nominations (
    NominationID VARCHAR(30) PRIMARY KEY,
    NominatedStudentID VARCHAR(70) NOT NULL,
    NominatorStudentID VARCHAR(70) NOT NULL,
    FacultyID VARCHAR(20) NOT NULL,
    NominationDate DATE NOT NULL,
    FOREIGN KEY (NominatedStudentID) REFERENCES Student(StudentID),
    FOREIGN KEY (NominatorStudentID) REFERENCES Student(StudentID),
    FOREIGN KEY (FacultyID) REFERENCES Faculty(FacultyID)
);

-- Prevent Duplicate Votes
DELIMITER $$
CREATE TRIGGER check_duplicate_votes
BEFORE INSERT ON Votes
FOR EACH ROW
BEGIN
    DECLARE vote_count INT;
    SELECT COUNT(*) INTO vote_count
    FROM Votes
    WHERE VoterID = NEW.VoterID AND CandidateID = NEW.CandidateID;
    IF vote_count > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Duplicate votes are not allowed.';
    END IF;
END $$
DELIMITER ;

-- Prevent Cross-Faculty Voting
DELIMITER $$
CREATE TRIGGER check_faculty_voting
BEFORE INSERT ON Votes
FOR EACH ROW
BEGIN
    DECLARE voter_faculty VARCHAR(20);
    DECLARE candidate_faculty VARCHAR(20);
    SELECT FacultyID INTO voter_faculty FROM Student WHERE StudentID = NEW.VoterID;
    SELECT FacultyID INTO candidate_faculty FROM Candidate WHERE CandidateID = NEW.CandidateID;
    IF voter_faculty != candidate_faculty THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Voters can only vote for candidates within their faculty.';
    END IF;
END $$
DELIMITER ;

-- Prevent Ugandan Students from Voting for International MP
DELIMITER $$
CREATE TRIGGER check_international_mp_voting
BEFORE INSERT ON Votes
FOR EACH ROW
BEGIN
    DECLARE voter_nationality VARCHAR(100);
    DECLARE position_name VARCHAR(100);
    SELECT Nationality INTO voter_nationality FROM Student WHERE StudentID = NEW.VoterID;
    SELECT PositionName INTO position_name FROM Candidate c
    JOIN Positions p ON c.PositionID = p.PositionID
    WHERE c.CandidateID = NEW.CandidateID;
    IF position_name = 'MP - International Students' AND voter_nationality = 'Ugandan' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ugandan students cannot vote for the MP - International Students position.';
    END IF;
END $$
DELIMITER ;

DELIMITER $$
CREATE TRIGGER enforce_cgpa_qualification
BEFORE INSERT ON Candidate
FOR EACH ROW
BEGIN
    DECLARE student_cgpa DECIMAL(3, 2);
    SELECT CGPA INTO student_cgpa FROM Student WHERE StudentID = NEW.StudentID;
    IF student_cgpa < 4.00 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Candidate does not meet the minimum CGPA requirement of 4.00.';
    END IF;
END $$
DELIMITER ;


-- Sample Data
INSERT INTO Faculty VALUES ('F001', 'Engineering, Design and Technology');
INSERT INTO Faculty VALUES ('F002', 'Law');
INSERT INTO Faculty VALUES ('F003', 'Education');

INSERT INTO Positions VALUES ('P01', 'Guild President');
INSERT INTO Positions VALUES ('P02', 'MP - Faculty Law');
INSERT INTO Positions VALUES ('P03', 'MP - Faculty Education');
INSERT INTO Positions VALUES ('P04', 'MP - International Students');

INSERT INTO Student VALUES ('M23B13/002', 'Kalyegira Emmanuel', 'F001', 'kalyegira@gmail.com', '07786233037', 3, 'Ugandan', 'Kampala', 4.50);
INSERT INTO Student VALUES ('S23B13/007', 'Kirabo Andrew', 'F002', 'andrea@gmail.com', '0778860079', 1, 'Ugandan', 'Wakiso', 3.80);
INSERT INTO Student VALUES ('I23B13/003', 'John Smith', 'F003', 'johnsmith@gmail.com', '0789456123', 2, 'American', 'Kampala', 4.20);

-- Example Verification Code
INSERT INTO VerificationCode VALUES ('VC001', 'M23B13/002', 'ABC123', FALSE, NOW());
