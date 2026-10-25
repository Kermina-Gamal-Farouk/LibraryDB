-- =============================================
-- Library Management Database (SQL Server)
-- 5 tables, 1 view, 1 stored procedure, 1 trigger
-- =============================================
IF DB_ID('LibraryDB') IS NOT NULL
BEGIN
    ALTER DATABASE LibraryDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE LibraryDB;
END
GO
CREATE DATABASE LibraryDB;
GO
USE LibraryDB;
GO

-- ---------- Tables ----------
CREATE TABLE Authors (
    AuthorID   INT IDENTITY(1,1) PRIMARY KEY,
    FullName   NVARCHAR(100) NOT NULL,
    Country    NVARCHAR(50)
);

CREATE TABLE Categories (
    CategoryID   INT IDENTITY(1,1) PRIMARY KEY,
    CategoryName NVARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE Books (
    BookID          INT IDENTITY(1,1) PRIMARY KEY,
    Title           NVARCHAR(150) NOT NULL,
    AuthorID        INT NOT NULL REFERENCES Authors(AuthorID),
    CategoryID      INT NOT NULL REFERENCES Categories(CategoryID),
    PublishYear     INT CHECK (PublishYear BETWEEN 1800 AND 2100),
    CopiesAvailable INT NOT NULL DEFAULT 1 CHECK (CopiesAvailable >= 0)
);

CREATE TABLE Members (
    MemberID  INT IDENTITY(1,1) PRIMARY KEY,
    FullName  NVARCHAR(100) NOT NULL,
    Email     NVARCHAR(100) UNIQUE,
    JoinDate  DATE NOT NULL DEFAULT GETDATE()
);

CREATE TABLE Loans (
    LoanID     INT IDENTITY(1,1) PRIMARY KEY,
    BookID     INT NOT NULL REFERENCES Books(BookID),
    MemberID   INT NOT NULL REFERENCES Members(MemberID),
    LoanDate   DATE NOT NULL DEFAULT GETDATE(),
    DueDate    DATE NOT NULL,
    ReturnDate DATE NULL
);
GO

-- ---------- Sample data ----------
INSERT INTO Authors (FullName, Country) VALUES
(N'Naguib Mahfouz', N'Egypt'),
(N'George Orwell', N'UK'),
(N'Robert C. Martin', N'USA'),
(N'Taha Hussein', N'Egypt');

INSERT INTO Categories (CategoryName) VALUES
(N'Novel'), (N'Programming'), (N'History');

INSERT INTO Books (Title, AuthorID, CategoryID, PublishYear, CopiesAvailable) VALUES
(N'Cairo Trilogy', 1, 1, 1957, 3),
(N'Children of Gebelawi', 1, 1, 1959, 2),
(N'1984', 2, 1, 1949, 4),
(N'Clean Code', 3, 2, 2008, 2),
(N'The Days', 4, 1, 1929, 1);

INSERT INTO Members (FullName, Email) VALUES
(N'Ahmed Ali', 'ahmed@example.com'),
(N'Sara Hassan', 'sara@example.com'),
(N'Omar Khaled', 'omar@example.com');

INSERT INTO Loans (BookID, MemberID, LoanDate, DueDate, ReturnDate) VALUES
(1, 1, '2026-09-01', '2026-09-15', '2026-09-10'),
(3, 2, '2026-10-01', '2026-10-15', NULL),
(4, 1, '2026-10-05', '2026-10-19', NULL),
(5, 3, '2026-10-10', '2026-10-24', NULL);
GO

-- ---------- View: current (not returned) loans ----------
CREATE VIEW vw_ActiveLoans AS
SELECT l.LoanID, m.FullName AS Member, b.Title, l.LoanDate, l.DueDate,
       CASE WHEN l.DueDate < CAST(GETDATE() AS DATE) THEN 'Overdue' ELSE 'On time' END AS Status
FROM Loans l
JOIN Members m ON m.MemberID = l.MemberID
JOIN Books   b ON b.BookID   = l.BookID
WHERE l.ReturnDate IS NULL;
GO

-- ---------- Stored procedure: borrow a book ----------
CREATE PROCEDURE sp_BorrowBook
    @BookID INT, @MemberID INT, @Days INT = 14
AS
BEGIN
    IF (SELECT CopiesAvailable FROM Books WHERE BookID = @BookID) <= 0
    BEGIN
        RAISERROR('No copies available.', 16, 1);
        RETURN;
    END
    INSERT INTO Loans (BookID, MemberID, DueDate)
    VALUES (@BookID, @MemberID, DATEADD(DAY, @Days, CAST(GETDATE() AS DATE)));
END
GO

-- ---------- Trigger: update stock automatically ----------
CREATE TRIGGER trg_Loan_Insert ON Loans AFTER INSERT AS
BEGIN
    UPDATE b SET CopiesAvailable = CopiesAvailable - 1
    FROM Books b JOIN inserted i ON i.BookID = b.BookID;
END
GO

CREATE TRIGGER trg_Loan_Return ON Loans AFTER UPDATE AS
BEGIN
    UPDATE b SET CopiesAvailable = CopiesAvailable + 1
    FROM Books b
    JOIN inserted i ON i.BookID = b.BookID
    JOIN deleted  d ON d.LoanID = i.LoanID
    WHERE d.ReturnDate IS NULL AND i.ReturnDate IS NOT NULL;
END
GO

-- ---------- Practice queries ----------
-- 1) Books with author and category
SELECT b.Title, a.FullName AS Author, c.CategoryName, b.PublishYear
FROM Books b
JOIN Authors a    ON a.AuthorID = b.AuthorID
JOIN Categories c ON c.CategoryID = b.CategoryID;

-- 2) Number of books per author
SELECT a.FullName, COUNT(*) AS BooksCount
FROM Authors a JOIN Books b ON b.AuthorID = a.AuthorID
GROUP BY a.FullName ORDER BY BooksCount DESC;

-- 3) Members who borrowed more than 1 book
SELECT m.FullName, COUNT(*) AS TotalLoans
FROM Members m JOIN Loans l ON l.MemberID = m.MemberID
GROUP BY m.FullName HAVING COUNT(*) > 1;

-- 4) Overdue loans (uses the view)
SELECT * FROM vw_ActiveLoans WHERE Status = 'Overdue';

-- 5) Test the procedure
EXEC sp_BorrowBook @BookID = 2, @MemberID = 3;
SELECT Title, CopiesAvailable FROM Books WHERE BookID = 2;
