# Design Document

## Overview

The Blockchain Learning Management System (LMS) is implemented as a Solidity smart contract deployed on the Somnia testnet. The system manages user registration, course creation, exam administration, and score tracking entirely on-chain. The design emphasizes gas efficiency, security, and user experience while maintaining educational data integrity.

## Architecture

### Smart Contract Structure

```
LearningManagementSystem.sol
├── User Management
├── Course Management  
├── Exam Management
├── Enrollment System
├── Scoring System
└── Access Control
```

### Key Design Patterns

- **Role-Based Access Control**: Separate permissions for Tutors and Students
- **State Machine Pattern**: Exam states (Created, Active, Expired)
- **Factory Pattern**: Dynamic creation of courses and exams
- **Event-Driven Architecture**: Comprehensive event logging for off-chain indexing

## Components and Interfaces

### Core Data Structures

```solidity
struct User {
    string name;
    UserRole role;
    bool isRegistered;
    uint256 registrationTime;
}

struct Course {
    uint256 courseId;
    string title;
    address tutor;
    uint256 creationTime;
    bool isActive;
}

struct Exam {
    uint256 examId;
    uint256 courseId;
    string title;
    uint256 startTime;
    uint256 duration;
    Question[] questions;
    bool isActive;
}

struct Question {
    string questionText;
    string[] options;
    uint8 correctAnswer;
}

struct ExamAttempt {
    uint256 examId;
    address student;
    uint8[] answers;
    uint256 score;
    uint256 submissionTime;
    bool isCompleted;
}

struct Enrollment {
    uint256 courseId;
    address student;
    uint256 enrollmentTime;
}
```

### Main Contract Functions

#### User Management
- `registerUser(string name, UserRole role)`: Register new users
- `getUserProfile(address user)`: Get user information
- `isUserRegistered(address user)`: Check registration status

#### Course Management
- `createCourse(string title)`: Tutors create courses
- `getCourse(uint256 courseId)`: Retrieve course details
- `getTutorCourses(address tutor)`: Get courses by tutor
- `getAllCourses()`: List all available courses

#### Exam Management
- `createExam(ExamParams params)`: Tutors create exams
- `getExam(uint256 examId)`: Retrieve exam details
- `getCourseExams(uint256 courseId)`: Get exams for a course
- `isExamActive(uint256 examId)`: Check if exam is currently active

#### Enrollment System
- `enrollInCourse(uint256 courseId)`: Students enroll in courses
- `getStudentEnrollments(address student)`: Get student's courses
- `isStudentEnrolled(address student, uint256 courseId)`: Check enrollment

#### Exam Taking System
- `startExam(uint256 examId)`: Begin exam attempt
- `submitExamAnswers(uint256 examId, uint8[] answers)`: Submit exam
- `getExamAttempt(uint256 examId, address student)`: Get attempt details
- `calculateScore(uint256 examId, uint8[] answers)`: Calculate percentage score

### Access Control

```solidity
modifier onlyRegistered() {
    require(users[msg.sender].isRegistered, "User not registered");
    _;
}

modifier onlyTutor() {
    require(users[msg.sender].role == UserRole.Tutor, "Only tutors allowed");
    _;
}

modifier onlyStudent() {
    require(users[msg.sender].role == UserRole.Student, "Only students allowed");
    _;
}

modifier onlyEnrolled(uint256 courseId) {
    require(isStudentEnrolled(msg.sender, courseId), "Not enrolled in course");
    _;
}
```

## Data Models

### Storage Mappings

```solidity
mapping(address => User) public users;
mapping(uint256 => Course) public courses;
mapping(uint256 => Exam) public exams;
mapping(bytes32 => Enrollment) public enrollments; // keccak256(student, courseId)
mapping(bytes32 => ExamAttempt) public examAttempts; // keccak256(student, examId)
mapping(address => uint256[]) public tutorCourses;
mapping(address => uint256[]) public studentEnrollments;
mapping(uint256 => uint256[]) public courseExams;
```

### State Variables

```solidity
uint256 public nextCourseId = 1;
uint256 public nextExamId = 1;
uint256 public totalUsers;
uint256 public totalCourses;
uint256 public totalExams;
```

## Error Handling

### Custom Errors

```solidity
error UserAlreadyRegistered();
error UserNotRegistered();
error InvalidRole();
error CourseNotFound();
error ExamNotFound();
error ExamNotActive();
error ExamExpired();
error AlreadyEnrolled();
error NotEnrolled();
error UnauthorizedAccess();
error InvalidExamAnswers();
error ExamAlreadySubmitted();
```

### Validation Patterns

- Input validation for all public functions
- State validation before state changes
- Access control checks using modifiers
- Time-based validations for exam scheduling
- Answer format validation for exam submissions

## Testing Strategy

### Unit Tests

- User registration and authentication flows
- Course creation and management
- Exam creation with question validation
- Enrollment process and access control
- Exam taking and scoring logic
- Time-based exam activation and expiration

### Integration Tests

- End-to-end user journeys (Tutor and Student flows)
- Cross-contract interactions
- Event emission verification
- Gas optimization testing
- Edge case handling (expired exams, duplicate enrollments)

### Test Scenarios

1. **Tutor Flow**: Register → Create Course → Create Exam → View Results
2. **Student Flow**: Register → Enroll → Take Exam → View Score
3. **Timing Tests**: Exam activation, duration enforcement, expiration
4. **Access Control**: Unauthorized access attempts, role restrictions
5. **Data Integrity**: Score calculations, answer validation, state consistency

### Deployment Configuration

#### Hardhat Network Configuration

```javascript
networks: {
  somniaTestnet: {
    type: "http",
    url: "https://dream-rpc.somnia.network/",
    chainId: 50312,
    accounts: process.env.SOMNIA_TESTNET_PRIVATE_KEY ? [process.env.SOMNIA_TESTNET_PRIVATE_KEY] : [],
    gas: 8000000,
    gasPrice: 20000000000
  }
}
```

#### Contract Deployment Strategy

- Deploy main LMS contract with initialization parameters
- Verify contract on Somnia testnet explorer
- Set up event indexing for off-chain queries
- Configure frontend integration endpoints
- Implement upgrade patterns for future enhancements

### Security Considerations

- Reentrancy protection using OpenZeppelin's ReentrancyGuard
- Integer overflow protection (Solidity 0.8+)
- Access control validation on all state-changing functions
- Input sanitization and validation
- Time manipulation resistance for exam scheduling
- Gas limit considerations for large question sets