# Requirements Document

## Introduction

A blockchain-based Learning Management System (LMS) that enables tutors to create courses and exams, and students to enroll in courses, take exams, and receive scores. The system uses wallet-based authentication and stores all data on-chain for transparency and immutability.

## Glossary

- **LMS_Contract**: The main smart contract managing the learning management system
- **User**: Any wallet address that interacts with the system (Tutor or Student)
- **Tutor**: A registered user with permission to create courses and exams
- **Student**: A registered user who can enroll in courses and take exams
- **Course**: An educational program created by a tutor with a unique title
- **Exam**: A timed assessment associated with a course containing questions and answers
- **Enrollment**: The relationship between a student and a course they have joined
- **Exam_Session**: An active exam attempt by a student with timing constraints
- **Question**: An exam component with multiple choice options and one correct answer
- **Score**: The percentage result of a completed exam attempt

## Requirements

### Requirement 1

**User Story:** As a wallet holder, I want to register on the platform with my name and role, so that I can access LMS features appropriate to my role.

#### Acceptance Criteria

1. WHEN a wallet connects for the first time, THE LMS_Contract SHALL allow registration with name and role selection
2. THE LMS_Contract SHALL store the user's wallet address, name, and role (Tutor or Student) on-chain
3. WHEN a previously registered wallet connects, THE LMS_Contract SHALL automatically authenticate the user
4. THE LMS_Contract SHALL prevent duplicate registrations for the same wallet address
5. THE LMS_Contract SHALL validate that role is either "Tutor" or "Student"

### Requirement 2

**User Story:** As a tutor, I want to create courses with titles, so that students can discover and enroll in my educational content.

#### Acceptance Criteria

1. WHEN a registered tutor creates a course, THE LMS_Contract SHALL store the course with a unique identifier
2. THE LMS_Contract SHALL associate each course with the tutor's wallet address
3. THE LMS_Contract SHALL require a non-empty course title for course creation
4. THE LMS_Contract SHALL prevent duplicate course titles by the same tutor
5. THE LMS_Contract SHALL make created courses visible to all users for enrollment

### Requirement 3

**User Story:** As a tutor, I want to create exams for my courses with questions and timing, so that I can assess student knowledge.

#### Acceptance Criteria

1. WHEN a tutor creates an exam, THE LMS_Contract SHALL require course selection, exam title, date, time, duration, and questions
2. THE LMS_Contract SHALL validate that the selected course belongs to the creating tutor
3. THE LMS_Contract SHALL store exam questions with multiple choice options and correct answer indicators
4. WHEN exam date and time arrive, THE LMS_Contract SHALL activate the exam for the specified duration
5. THE LMS_Contract SHALL validate that each question has exactly one correct answer marked with "(A)", "(a)", or "(Answer)"

### Requirement 4

**User Story:** As a student, I want to enroll in available courses, so that I can access course content and exams.

#### Acceptance Criteria

1. WHEN a registered student selects a course, THE LMS_Contract SHALL create an enrollment record
2. THE LMS_Contract SHALL prevent duplicate enrollments for the same student-course combination
3. THE LMS_Contract SHALL make enrolled courses visible in the student's dashboard
4. THE LMS_Contract SHALL allow students to view available exams for enrolled courses
5. THE LMS_Contract SHALL restrict exam access to enrolled students only

### Requirement 5

**User Story:** As an enrolled student, I want to take available exams and submit answers, so that I can demonstrate my knowledge and receive scores.

#### Acceptance Criteria

1. WHEN an exam is active and student is enrolled, THE LMS_Contract SHALL allow exam entry
2. WHILE an exam session is active, THE LMS_Contract SHALL track remaining time and prevent late submissions
3. WHEN a student submits exam answers, THE LMS_Contract SHALL calculate and store the percentage score
4. THE LMS_Contract SHALL immediately display the calculated score after submission
5. IF exam duration expires or student has already submitted, THEN THE LMS_Contract SHALL display questions with correct answers in read-only mode

### Requirement 6

**User Story:** As a system user, I want all interactions recorded on-chain, so that there is transparency and immutability of educational records.

#### Acceptance Criteria

1. THE LMS_Contract SHALL emit events for all major actions (registration, course creation, enrollment, exam submission)
2. THE LMS_Contract SHALL store all user data, courses, exams, and scores permanently on-chain
3. THE LMS_Contract SHALL provide read functions to query user profiles, courses, exams, and scores
4. THE LMS_Contract SHALL maintain audit trails for all educational activities
5. THE LMS_Contract SHALL ensure data integrity through blockchain immutability