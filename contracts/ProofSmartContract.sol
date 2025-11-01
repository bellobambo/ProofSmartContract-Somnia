// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract ProofSmartContract {
    // Enums
    enum Role {
        TUTOR,
        STUDENT
    }

    struct User {
        string name;
        Role role;
        bool isRegistered;
    }

    struct Course {
        uint256 courseId;
        string title;
        address tutor;
        bool isActive;
    }

    struct Exam {
        uint256 examId;
        uint256 courseId;
        string title;
        uint256 questionCount;
        bool isActive;
        address creator;
    }

    struct ExamSession {
        uint256 examId;
        address student;
        bool[] answers; // true/false answers
        uint256 score;
        bool isCompleted;
    }

    // State Variables
    mapping(address => User) public users;
    mapping(address => bool) public registeredUsers;

    mapping(uint256 => Course) public courses;
    mapping(uint256 => mapping(address => bool)) public courseEnrollments;

    mapping(uint256 => Exam) public exams;
    mapping(uint256 => uint256[]) public courseExams;

    // Simple true/false questions
    mapping(uint256 => mapping(uint256 => string)) public examQuestions; // examId => questionIndex => questionText
    mapping(uint256 => mapping(uint256 => bool)) public examCorrectAnswers; // examId => questionIndex => correct answer (true/false)

    mapping(uint256 => mapping(address => ExamSession)) public examSessions;

    uint256 public courseCounter;
    uint256 public examCounter;

    // Events
    event UserRegistered(address indexed user, string name, Role role);
    event CourseCreated(uint256 indexed courseId, string title, address indexed tutor);
    event EnrollmentCreated(address indexed student, uint256 indexed courseId);
    event ExamCreated(uint256 indexed examId, uint256 indexed courseId, string title);
    event ExamCompleted(uint256 indexed examId, address indexed student, uint256 score);

    // Modifiers
    modifier onlyTutor() {
        require(registeredUsers[msg.sender] && users[msg.sender].role == Role.TUTOR, "Not a tutor");
        _;
    }

    modifier onlyStudent() {
        require(registeredUsers[msg.sender] && users[msg.sender].role == Role.STUDENT, "Not a student");
        _;
    }

    modifier courseExists(uint256 courseId) {
        require(courseId < courseCounter && courses[courseId].isActive, "Course not found");
        _;
    }

    modifier examExists(uint256 examId) {
        require(examId < examCounter && exams[examId].isActive, "Exam not found");
        _;
    }

    // User Management Functions
    function registerUser(string memory name, Role role) public {
        require(!registeredUsers[msg.sender], "Already registered");
        require(bytes(name).length > 0, "Name cannot be empty");

        users[msg.sender] = User({
            name: name,
            role: role,
            isRegistered: true
        });

        registeredUsers[msg.sender] = true;
        emit UserRegistered(msg.sender, name, role);
    }

    function getUser(address userAddress) public view returns (User memory) {
        require(registeredUsers[userAddress], "User not registered");
        return users[userAddress];
    }

    function isUserRegistered(address userAddress) public view returns (bool) {
        return registeredUsers[userAddress];
    }

    // Course Management Functions
    function createCourse(string memory title) public onlyTutor {
        require(bytes(title).length > 0, "Title cannot be empty");

        uint256 courseId = courseCounter;
        courses[courseId] = Course({
            courseId: courseId,
            title: title,
            tutor: msg.sender,
            isActive: true
        });

        courseCounter++;
        emit CourseCreated(courseId, title, msg.sender);
    }

    function getAllCourses() public view returns (Course[] memory) {
        Course[] memory allCourses = new Course[](courseCounter);
        uint256 activeCount = 0;
        
        for (uint256 i = 0; i < courseCounter; i++) {
            if (courses[i].isActive) {
                allCourses[activeCount] = courses[i];
                activeCount++;
            }
        }
        
        // Resize array to only include active courses
        Course[] memory activeCourses = new Course[](activeCount);
        for (uint256 i = 0; i < activeCount; i++) {
            activeCourses[i] = allCourses[i];
        }
        
        return activeCourses;
    }

    function enrollInCourse(uint256 courseId) public onlyStudent courseExists(courseId) {
        require(!courseEnrollments[courseId][msg.sender], "Already enrolled");
        courseEnrollments[courseId][msg.sender] = true;
        emit EnrollmentCreated(msg.sender, courseId);
    }

    function isEnrolledInCourse(uint256 courseId, address student) public view returns (bool) {
        return courseEnrollments[courseId][student];
    }

    // Exam Management Functions - Simplified True/False System
    function createExam(
        uint256 courseId,
        string memory title,
        string[] memory questionTexts,
        bool[] memory correctAnswers
    ) public onlyTutor courseExists(courseId) {
        require(courses[courseId].tutor == msg.sender, "Not course owner");
        require(bytes(title).length > 0, "Title cannot be empty");
        require(questionTexts.length > 0, "At least one question required");
        require(questionTexts.length == correctAnswers.length, "Array length mismatch");

        uint256 examId = examCounter;

        exams[examId] = Exam({
            examId: examId,
            courseId: courseId,
            title: title,
            questionCount: questionTexts.length,
            isActive: true,
            creator: msg.sender
        });

        // Store questions and correct answers
        for (uint256 i = 0; i < questionTexts.length; i++) {
            require(bytes(questionTexts[i]).length > 0, "Question text cannot be empty");
            examQuestions[examId][i] = questionTexts[i];
            examCorrectAnswers[examId][i] = correctAnswers[i];
        }

        courseExams[courseId].push(examId);
        examCounter++;

        emit ExamCreated(examId, courseId, title);
    }

    function getExamsForCourse(uint256 courseId) public view courseExists(courseId) returns (uint256[] memory) {
        return courseExams[courseId];
    }

    // Get all questions for an exam (without correct answers for students)
    function getExamQuestions(uint256 examId) public view examExists(examId) returns (string[] memory) {
        Exam storage exam = exams[examId];
        string[] memory questionTexts = new string[](exam.questionCount);

        for (uint256 i = 0; i < exam.questionCount; i++) {
            questionTexts[i] = examQuestions[examId][i];
        }

        return questionTexts;
    }

    // Assessment System Functions - Simplified
    function takeExam(uint256 examId, bool[] memory answers) public onlyStudent examExists(examId) {
        Exam storage exam = exams[examId];
        
        require(courseEnrollments[exam.courseId][msg.sender], "Not enrolled in course");
        require(!examSessions[examId][msg.sender].isCompleted, "Exam already completed");
        require(answers.length == exam.questionCount, "Answer count mismatch");

        // Calculate score
        uint256 correctAnswers = 0;
        for (uint256 i = 0; i < exam.questionCount; i++) {
            if (answers[i] == examCorrectAnswers[examId][i]) {
                correctAnswers++;
            }
        }

        uint256 scorePercentage = (correctAnswers * 100) / exam.questionCount;

        // Store exam session
        examSessions[examId][msg.sender] = ExamSession({
            examId: examId,
            student: msg.sender,
            answers: answers,
            score: scorePercentage,
            isCompleted: true
        });

        emit ExamCompleted(examId, msg.sender, scorePercentage);
    }

    function getExamResults(uint256 examId, address student) public view examExists(examId) returns (
        uint256 score,
        bool[] memory answers,
        bool isCompleted
    ) {
        require(
            msg.sender == student || 
            (registeredUsers[msg.sender] && users[msg.sender].role == Role.TUTOR),
            "Unauthorized access"
        );

        ExamSession storage session = examSessions[examId][student];
        return (session.score, session.answers, session.isCompleted);
    }

    // Helper Functions
    function getCourse(uint256 courseId) public view courseExists(courseId) returns (Course memory) {
        return courses[courseId];
    }

    function getExam(uint256 examId) public view examExists(examId) returns (Exam memory) {
        return exams[examId];
    }

    function getAllExams() public view returns (Exam[] memory) {
        Exam[] memory allExams = new Exam[](examCounter);
        uint256 activeCount = 0;

        for (uint256 i = 0; i < examCounter; i++) {
            if (exams[i].isActive) {
                allExams[activeCount] = exams[i];
                activeCount++;
            }
        }

        // Resize array to only include active exams
        Exam[] memory activeExams = new Exam[](activeCount);
        for (uint256 i = 0; i < activeCount; i++) {
            activeExams[i] = allExams[i];
        }

        return activeExams;
    }

    function getAvailableExamsForStudent(address student) public view returns (Exam[] memory) {
        Exam[] memory allExams = new Exam[](examCounter);
        uint256 availableCount = 0;

        for (uint256 i = 0; i < examCounter; i++) {
            if (exams[i].isActive && courseEnrollments[exams[i].courseId][student]) {
                allExams[availableCount] = exams[i];
                availableCount++;
            }
        }

        // Resize array to only include available exams
        Exam[] memory availableExams = new Exam[](availableCount);
        for (uint256 i = 0; i < availableCount; i++) {
            availableExams[i] = allExams[i];
        }

        return availableExams;
    }
}
