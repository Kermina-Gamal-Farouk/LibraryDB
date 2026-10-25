# Library Management Database

A relational database for a library system, built with SQL Server.

## Tables
- Authors
- Categories
- Books
- Members
- Loans

## Features
- View vw_ActiveLoans shows current loans and marks overdue ones.
- Stored procedure sp_BorrowBook handles borrowing a book.
- Triggers update available copies when a book is borrowed or returned.

## How to run
1. Open 1_LibraryDB.sql in SQL Server Management Studio.
2. Click Execute.

## Sample queries
The file ends with 5 practice queries using joins, grouping, and the view.
