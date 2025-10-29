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
        uint256 registrationTimestamp;
    }

    struct Course {
        uint256 courseId;
        string title;
        address tutor;
        uint256 creationTimestamp;
        bool isActive;
    }

    // Store questions and options separately to avoid nested arrays
    struct Exam {
        uint256 examId;
        uint256 courseId;
        string title;
        uint256 scheduledDateTime;
        uint256 durationMinutes;
        uint256 questionCount;
        bool isActive;
        address creator;
    }

    struct ExamSession {
        uint256 examId;
        address student;
        uint256 startTime;
        uint256[] selectedAnswers;
        uint256 score;
        bool isCompleted;
        bool isSubmitted;
    }

    // State Variables
    mapping(address => User) public users;
    mapping(address => bool) public registeredUsers;

    mapping(uint256 => Course) public courses;
    mapping(address => uint256[]) public tutorCourses;
    mapping(address => uint256[]) public studentEnrollments;
    mapping(uint256 => mapping(address => bool)) public courseEnrollments;

    mapping(uint256 => Exam) public exams;
    mapping(uint256 => uint256[]) public courseExams;

    // Store questions and options separately
    mapping(uint256 => mapping(uint256 => string)) public examQuestions; // examId => questionIndex => questionText
    mapping(uint256 => mapping(uint256 => string[])) public examQuestionOptions; // examId => questionIndex => options[]
    mapping(uint256 => mapping(uint256 => uint256)) public examCorrectAnswers; // examId => questionIndex => correctAnswerIndex

    mapping(uint256 => mapping(address => ExamSession)) public examSessions;
    mapping(address => mapping(uint256 => uint256)) public studentScores;

    uint256 public courseCounter;
    uint256 public examCounter;

    // Events
    event UserRegistered(address indexed user, string name, Role role);
    event CourseCreated(
        uint256 indexed courseId,
        string title,
        address indexed tutor
    );
    event EnrollmentCreated(address indexed student, uint256 indexed courseId);
    event ExamCreated(
        uint256 indexed examId,
        uint256 indexed courseId,
        string title
    );
    event ExamStarted(uint256 indexed examId, address indexed student);
    event ExamCompleted(
        uint256 indexed examId,
        address indexed student,
        uint256 score
    );

    // Custom Errors
    error UserAlreadyRegistered();
    error UserNotRegistered();
    error UnauthorizedAccess();
    error CourseNotFound();
    error ExamNotFound();
    error ExamNotActive();
    error ExamAlreadyCompleted();
    error NotEnrolledInCourse();
    error InvalidExamTime();
    error ExamDurationExpired();
    error InvalidAnswerIndex();
    error InvalidInput(string message);

    // Modifiers
    modifier onlyRegistered() {
        if (!registeredUsers[msg.sender]) revert UserNotRegistered();
        _;
    }

    modifier onlyTutor() {
        if (
            !registeredUsers[msg.sender] || users[msg.sender].role != Role.TUTOR
        ) revert UnauthorizedAccess();
        _;
    }

    modifier onlyStudent() {
        if (
            !registeredUsers[msg.sender] ||
            users[msg.sender].role != Role.STUDENT
        ) revert UnauthorizedAccess();
        _;
    }

    modifier courseExists(uint256 courseId) {
        if (courseId >= courseCounter || !courses[courseId].isActive)
            revert CourseNotFound();
        _;
    }

    modifier examExists(uint256 examId) {
        if (examId >= examCounter) revert ExamNotFound();
        _;
    }

    // User Management Functions
    function registerUser(string memory name, Role role) public {
        if (registeredUsers[msg.sender]) revert UserAlreadyRegistered();
        if (bytes(name).length == 0) revert InvalidInput("Name cannot be empty");

        users[msg.sender] = User({
            name: name,
            role: role,
            isRegistered: true,
            registrationTimestamp: block.timestamp
        });

        registeredUsers[msg.sender] = true;
        emit UserRegistered(msg.sender, name, role);
    }

    function getUser(address userAddress) public view returns (User memory) {
        if (!registeredUsers[userAddress]) revert UserNotRegistered();
        return users[userAddress];
    }

    function isUserRegistered(address userAddress) public view returns (bool) {
        return registeredUsers[userAddress];
    }

    // Course Management Functions
    function createCourse(string memory title) public onlyTutor {
        if (bytes(title).length == 0) revert InvalidInput("Title cannot be empty");

        uint256 courseId = courseCounter;

        courses[courseId] = Course({
            courseId: courseId,
            title: title,
            tutor: msg.sender,
            creationTimestamp: block.timestamp,
            isActive: true
        });

        tutorCourses[msg.sender].push(courseId);
        courseCounter++;

        emit CourseCreated(courseId, title, msg.sender);
    }

    function getAllCourses() public view returns (Course[] memory) {
        uint256 activeCount = 0;
        for (uint256 i = 0; i < courseCounter; i++) {
            if (courses[i].isActive) {
                activeCount++;
            }
        }

        Course[] memory activeCourses = new Course[](activeCount);
        uint256 currentIndex = 0;
        for (uint256 i = 0; i < courseCounter; i++) {
            if (courses[i].isActive) {
                activeCourses[currentIndex] = courses[i];
                currentIndex++;
            }
        }
        return activeCourses;
    }

    function enrollInCourse(
        uint256 courseId
    ) public onlyStudent courseExists(courseId) {
        if (courseEnrollments[courseId][msg.sender])
            revert UserAlreadyRegistered();

        courseEnrollments[courseId][msg.sender] = true;
        studentEnrollments[msg.sender].push(courseId);

        emit EnrollmentCreated(msg.sender, courseId);
    }

    function getStudentEnrollments(
        address student
    ) public view returns (uint256[] memory) {
        return studentEnrollments[student];
    }

    // Exam Management Functions - Fixed version
    function createExam(
        uint256 courseId,
        string memory title,
        uint256 scheduledDateTime,
        uint256 durationMinutes,
        string[] memory questionTexts,
        string[][] memory optionsArray,
        uint256[] memory correctAnswerIndices
    ) public onlyTutor courseExists(courseId) {
        if (scheduledDateTime < block.timestamp) revert InvalidExamTime();
        if (durationMinutes == 0) revert InvalidExamTime();
        if (courses[courseId].tutor != msg.sender) revert UnauthorizedAccess();
        if (bytes(title).length == 0) revert InvalidInput("Title cannot be empty");
        if (questionTexts.length == 0) revert InvalidInput("At least one question required");

        // Validate arrays have same length
        if (questionTexts.length != optionsArray.length || 
            optionsArray.length != correctAnswerIndices.length) {
            revert InvalidInput("Array length mismatch");
        }

        uint256 examId = examCounter;

        // Create exam without nested arrays
        exams[examId] = Exam({
            examId: examId,
            courseId: courseId,
            title: title,
            scheduledDateTime: scheduledDateTime,
            durationMinutes: durationMinutes,
            questionCount: questionTexts.length,
            isActive: true,
            creator: msg.sender
        });

        // Store questions and options separately
        for (uint256 i = 0; i < questionTexts.length; i++) {
            if (bytes(questionTexts[i]).length == 0) {
                revert InvalidInput("Question text cannot be empty");
            }
            if (optionsArray[i].length < 2) {
                revert InvalidInput("At least 2 options required");
            }
            if (correctAnswerIndices[i] >= optionsArray[i].length) {
                revert InvalidInput("Correct answer index out of bounds");
            }

            examQuestions[examId][i] = questionTexts[i];
            examQuestionOptions[examId][i] = optionsArray[i];
            examCorrectAnswers[examId][i] = correctAnswerIndices[i];
        }

        courseExams[courseId].push(examId);
        examCounter++;

        emit ExamCreated(examId, courseId, title);
    }

    function getExamsForCourse(
        uint256 courseId
    ) public view courseExists(courseId) returns (uint256[] memory) {
        return courseExams[courseId];
    }

    function isExamActive(
        uint256 examId
    ) public view examExists(examId) returns (bool) {
        Exam storage exam = exams[examId];
        return
            exam.isActive &&
            exam.scheduledDateTime <= block.timestamp &&
            block.timestamp <=
            (exam.scheduledDateTime + exam.durationMinutes * 1 minutes);
    }

    // Get single question with options
    function getExamQuestion(
        uint256 examId, 
        uint256 questionIndex
    ) public view examExists(examId) returns (
        string memory questionText,
        string[] memory options,
        uint256 correctAnswerIndex
    ) {
        if (!isExamActive(examId)) revert ExamNotActive();
        if (questionIndex >= exams[examId].questionCount) revert InvalidAnswerIndex();
        
        questionText = examQuestions[examId][questionIndex];
        options = examQuestionOptions[examId][questionIndex];
        correctAnswerIndex = examCorrectAnswers[examId][questionIndex];
    }

    // Get all questions for an exam
    function getExamQuestions(
        uint256 examId
    ) public view examExists(examId) returns (
        string[] memory questionTexts,
        string[][] memory optionsArray,
        uint256[] memory correctAnswerIndices
    ) {
        if (!isExamActive(examId)) revert ExamNotActive();
        
        Exam storage exam = exams[examId];
        questionTexts = new string[](exam.questionCount);
        optionsArray = new string[][](exam.questionCount);
        correctAnswerIndices = new uint256[](exam.questionCount);
        
        for (uint256 i = 0; i < exam.questionCount; i++) {
            questionTexts[i] = examQuestions[examId][i];
            optionsArray[i] = examQuestionOptions[examId][i];
            correctAnswerIndices[i] = examCorrectAnswers[examId][i];
        }
    }

    // Assessment System Functions
    function startExam(uint256 examId) public onlyStudent examExists(examId) {
        Exam storage exam = exams[examId];

        if (!isExamActive(examId)) revert ExamNotActive();
        if (!courseEnrollments[exam.courseId][msg.sender])
            revert NotEnrolledInCourse();
        if (examSessions[examId][msg.sender].isCompleted)
            revert ExamAlreadyCompleted();

        examSessions[examId][msg.sender] = ExamSession({
            examId: examId,
            student: msg.sender,
            startTime: block.timestamp,
            selectedAnswers: new uint256[](exam.questionCount),
            score: 0,
            isCompleted: false,
            isSubmitted: false
        });

        emit ExamStarted(examId, msg.sender);
    }

    function submitAnswer(
        uint256 examId,
        uint256 questionIndex,
        uint256 answerIndex
    ) public onlyStudent examExists(examId) {
        ExamSession storage session = examSessions[examId][msg.sender];
        Exam storage exam = exams[examId];

        if (session.isSubmitted) revert ExamAlreadyCompleted();
        if (
            block.timestamp >
            session.startTime + exam.durationMinutes * 1 minutes
        ) revert ExamDurationExpired();
        if (questionIndex >= exam.questionCount) revert InvalidAnswerIndex();
        
        string[] storage options = examQuestionOptions[examId][questionIndex];
        if (answerIndex >= options.length) revert InvalidAnswerIndex();

        session.selectedAnswers[questionIndex] = answerIndex;
    }

    function submitExam(uint256 examId) public onlyStudent examExists(examId) {
        ExamSession storage session = examSessions[examId][msg.sender];
        Exam storage exam = exams[examId];

        if (session.isSubmitted) revert ExamAlreadyCompleted();
        if (
            block.timestamp >
            session.startTime + exam.durationMinutes * 1 minutes
        ) revert ExamDurationExpired();

        // Prevent division by zero
        if (exam.questionCount == 0) {
            session.score = 0;
        } else {
            // Calculate score as percentage
            uint256 correctAnswers = 0;
            for (uint256 i = 0; i < exam.questionCount; i++) {
                if (session.selectedAnswers[i] == examCorrectAnswers[examId][i]) {
                    correctAnswers++;
                }
            }

            uint256 scorePercentage = (correctAnswers * 100) / exam.questionCount;
            session.score = scorePercentage;
        }

        session.isCompleted = true;
        session.isSubmitted = true;
        studentScores[msg.sender][examId] = session.score;

        emit ExamCompleted(examId, msg.sender, session.score);
    }

    function getExamResults(
        uint256 examId,
        address student
    )
        public
        view
        examExists(examId)
        returns (
            uint256 score,
            uint256[] memory selectedAnswers,
            bool isCompleted
        )
    {
        ExamSession storage session = examSessions[examId][student];

        // Only allow tutors or the student themselves to view results
        if (
            msg.sender != student &&
            (!registeredUsers[msg.sender] ||
                users[msg.sender].role != Role.TUTOR)
        ) {
            revert UnauthorizedAccess();
        }

        return (session.score, session.selectedAnswers, session.isCompleted);
    }

    // Helper function to get course details
    function getCourse(uint256 courseId) public view courseExists(courseId) returns (Course memory) {
        return courses[courseId];
    }

    // Helper function to get exam details
    function getExam(uint256 examId) public view examExists(examId) returns (Exam memory) {
        return exams[examId];
    }

    // Helper to get exam question count
    function getExamQuestionCount(uint256 examId) public view examExists(examId) returns (uint256) {
        return exams[examId].questionCount;
    }
}