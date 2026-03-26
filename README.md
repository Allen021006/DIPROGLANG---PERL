Perlfect Library — Online Public Access Catalog System
A Perl-based Online Public Access Catalog (OPAC) System designed to manage library records, borrowing transactions, and overdue monitoring. This system demonstrates object-oriented programming, event-driven design, and database integration using Perl.

Project Files
The repository contains the following main components:
  • opac_final.pl — Core system logic implemented in Perl
  • library_opac.sql — Database structure and initial schema
  • api.php — Backend API for web interface
  • index.html — Frontend interface

System Requirements
Ensure the following are installed before running the project:
  • ODBC Data Sources
  • XAMPP (MySQL Database)
  • Strawberry Perl

Installation Guide
1. Install XAMPP (MySQL)
  • Start Apache and MySQL in XAMPP Control Panel
  •Open your browser and go to:
    http://localhost/phpmyadmin

Create Database:
  1. Click New
  2. Enter database name: library_opac
  3. Click Create
  4. Import the file library_opac.sql

2. Install Strawberry Perl
Go to:
[Strawberry Perl](https://strawberryperl.com/)
Steps:
  1. Download the 64-bit installer (.msi)
  2. Run installer → click Next through all steps
  3. Verify installation:
perl -v


3. Install MySQL ODBC Connector
Go to:
[MySQL ODBC Connector](https://dev.mysql.com/downloads/connector/odbc/)
Steps:
  1. Download Windows (x86, 64-bit), MSI Installer
  2. Install normally
Verify Installation:
  1. Press Win + R
  2. Run:
  C:\Windows\System32\odbcad32.exe
  
  3. Go to Drivers tab
  4. Confirm:
MySQL ODBC 9.6 Unicode Driver


4. Install Perl ODBC Module
Open PowerShell (Administrator) and run:
cpan DBD::ODBC

  • Press Enter for default options
  • Wait until installation completes

5. Set Up Project Folder (Perl System)
Open PowerShell:
mkdir C:\dev\projects\perl_opac_project
cd C:\dev\projects\perl_opac_project

Place:
opac_final.pl
library_opac.sql


6. Set Up Web Interface (HTML + PHP)
Navigate to your XAMPP directory:
C:\xampp\htdocs\opac\

Place:
index.html
api.php


Running the System
Option 1: Run Web Interface
Open browser:
http://localhost/opac/


Option 2: Run Perl Program (CLI)
In terminal:
perl opac_final.pl

Important Notes
• Ensure XAMPP (MySQL) is running before executing the program
• Database library_opac must already be created and imported
• ODBC driver must be properly configured
• The system supports both:
  •CLI-based execution (Perl)
  •Web-based interface (HTML + PHP)

Features
• Add, Edit, Delete, and Search Book Records
• Borrow and Return Book System
• Overdue Detection with Automatic Fee Calculation
• Dewey Decimal Classification (DDC) Browser
• Transaction Records and Statistics Dashboard
• Object-Oriented and Event-Driven Architecture

Project Highlights
This system demonstrates:
• Object-Oriented Programming (OOP) using Perl
• Event-driven design via menu dispatching
• Parameter passing and modular subprograms
• Encapsulation using blessed hash references
• Database integration via ODBC
• Memory management and garbage collection

Developers
• Aquino, Tyrone Andrei
• Panganiban, Allen David
• Priniel, Shannon Kyle
• Sangalang, Benedict
• Yalung, Hans Jeremy

License
This project is for academic purposes only under the course
Design and Implementation of Programming Languages (6DIPROGLANG)


