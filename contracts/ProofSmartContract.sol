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
        string tutorName;
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
        uint256[] answers; // multiple choice answers (0-3)
        uint256 score; // raw score (number of correct answers)
        bool isCompleted;
    }

    // State Variables
    mapping(address => User) public users;
    mapping(address => bool) public registeredUsers;

    mapping(uint256 => Course) public courses;
    mapping(uint256 => mapping(address => bool)) public courseEnrollments;

    mapping(uint256 => Exam) public exams;
    mapping(uint256 => uint256[]) public courseExams;

    // Multiple choice questions (4 options each)
    mapping(uint256 => mapping(uint256 => string)) public examQuestions; // examId => questionIndex => questionText
    mapping(uint256 => mapping(uint256 => string[4])) public examOptions; // examId => questionIndex => [option0, option1, option2, option3]
    mapping(uint256 => mapping(uint256 => uint256)) public examCorrectAnswers; // examId => questionIndex => correct answer index (0-3)

    mapping(uint256 => mapping(address => ExamSession)) public examSessions;

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
    event ExamCompleted(
        uint256 indexed examId,
        address indexed student,
        uint256 score
    );

    // Modifiers
    modifier onlyTutor() {
        require(
            registeredUsers[msg.sender] && users[msg.sender].role == Role.TUTOR,
            "Not a tutor"
        );
        _;
    }

    modifier onlyStudent() {
        require(
            registeredUsers[msg.sender] &&
                users[msg.sender].role == Role.STUDENT,
            "Not a student"
        );
        _;
    }

    modifier courseExists(uint256 courseId) {
        require(
            courseId < courseCounter && courses[courseId].isActive,
            "Course not found"
        );
        _;
    }

    modifier examExists(uint256 examId) {
        require(
            examId < examCounter && exams[examId].isActive,
            "Exam not found"
        );
        _;
    }

    // User Management Functions
    function registerUser(string memory name, Role role) public {
        require(!registeredUsers[msg.sender], "Already registered");
        require(bytes(name).length > 0, "Name cannot be empty");

        users[msg.sender] = User({name: name, role: role, isRegistered: true});

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
            tutorName: users[msg.sender].name,
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

    // Get course with lecturer name
    function getCourseWithLecturer(
        uint256 courseId
    )
        public
        view
        courseExists(courseId)
        returns (
            uint256 id,
            string memory title,
            address tutor,
            string memory tutorName,
            bool isActive
        )
    {
        Course storage course = courses[courseId];
        return (
            course.courseId,
            course.title,
            course.tutor,
            course.tutorName,
            course.isActive
        );
    }

    function enrollInCourse(
        uint256 courseId
    ) public onlyStudent courseExists(courseId) {
        require(!courseEnrollments[courseId][msg.sender], "Already enrolled");
        courseEnrollments[courseId][msg.sender] = true;
        emit EnrollmentCreated(msg.sender, courseId);
    }

    function isEnrolledInCourse(
        uint256 courseId,
        address student
    ) public view returns (bool) {
        return courseEnrollments[courseId][student];
    }

    // Exam Management Functions - Multiple Choice System (4 options)
    function createExam(
        uint256 courseId,
        string memory title,
        string[] memory questionTexts,
        string[4][] memory questionOptions, // Array of 4-option arrays
        uint256[] memory correctAnswers // Correct answer indices (0-3)
    ) public onlyTutor courseExists(courseId) {
        require(courses[courseId].tutor == msg.sender, "Not course owner");
        require(bytes(title).length > 0, "Title cannot be empty");
        require(questionTexts.length > 0, "At least one question required");
        require(
            questionTexts.length == questionOptions.length,
            "Question-options length mismatch"
        );
        require(
            questionTexts.length == correctAnswers.length,
            "Question-answers length mismatch"
        );

        uint256 examId = examCounter;

        exams[examId] = Exam({
            examId: examId,
            courseId: courseId,
            title: title,
            questionCount: questionTexts.length,
            isActive: true,
            creator: msg.sender
        });

        // Store questions, options, and correct answers
        for (uint256 i = 0; i < questionTexts.length; i++) {
            require(
                bytes(questionTexts[i]).length > 0,
                "Question text cannot be empty"
            );
            require(correctAnswers[i] < 4, "Correct answer index must be 0-3");

            // Validate all options are non-empty
            for (uint256 j = 0; j < 4; j++) {
                require(
                    bytes(questionOptions[i][j]).length > 0,
                    "Option text cannot be empty"
                );
            }

            examQuestions[examId][i] = questionTexts[i];
            examOptions[examId][i] = questionOptions[i];
            examCorrectAnswers[examId][i] = correctAnswers[i];
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

    // Get all questions and options for an exam (without correct answers for students)
    function getExamQuestions(
        uint256 examId
    )
        public
        view
        examExists(examId)
        returns (
            string[] memory questionTexts,
            string[4][] memory questionOptions
        )
    {
        Exam storage exam = exams[examId];
        questionTexts = new string[](exam.questionCount);
        questionOptions = new string[4][](exam.questionCount);

        for (uint256 i = 0; i < exam.questionCount; i++) {
            questionTexts[i] = examQuestions[examId][i];
            questionOptions[i] = examOptions[examId][i];
        }

        return (questionTexts, questionOptions);
    }

    // Assessment System Functions - Returns raw score
    function takeExam(
        uint256 examId,
        uint256[] memory answers
    ) public onlyStudent examExists(examId) returns (uint256 rawScore) {
        Exam storage exam = exams[examId];

        require(
            courseEnrollments[exam.courseId][msg.sender],
            "Not enrolled in course"
        );

        // Check if exam already completed and return previous score
        if (examSessions[examId][msg.sender].isCompleted) {
            return examSessions[examId][msg.sender].score;
        }

        require(answers.length == exam.questionCount, "Answer count mismatch");

        // Validate answer indices are within range (0-3)
        for (uint256 i = 0; i < answers.length; i++) {
            require(answers[i] < 4, "Answer index must be 0-3");
        }

        // Calculate raw score by comparing student answers with correct answers
        uint256 correctAnswers = 0;
        for (uint256 i = 0; i < exam.questionCount; i++) {
            if (answers[i] == examCorrectAnswers[examId][i]) {
                correctAnswers++;
            }
        }

        rawScore = correctAnswers;

        // Store exam session
        examSessions[examId][msg.sender] = ExamSession({
            examId: examId,
            student: msg.sender,
            answers: answers,
            score: rawScore,
            isCompleted: true
        });

        emit ExamCompleted(examId, msg.sender, rawScore);
        return rawScore;
    }

    function getExamResults(
        uint256 examId,
        address student
    )
        public
        view
        examExists(examId)
        returns (uint256 rawScore, uint256[] memory answers, bool isCompleted)
    {
        require(
            msg.sender == student ||
                (registeredUsers[msg.sender] &&
                    users[msg.sender].role == Role.TUTOR),
            "Unauthorized access"
        );

        ExamSession storage session = examSessions[examId][student];
        return (session.score, session.answers, session.isCompleted);
    }

    // Check if student has already completed an exam
    function hasCompletedExam(
        uint256 examId,
        address student
    ) public view examExists(examId) returns (bool) {
        return examSessions[examId][student].isCompleted;
    }

    // Get student's exam score - returns raw score (number of correct answers)
    function getStudentExamScore(
        uint256 examId,
        address student
    )
        public
        view
        examExists(examId)
        returns (uint256 rawScore, bool isCompleted)
    {
        require(
            msg.sender == student ||
                (registeredUsers[msg.sender] &&
                    users[msg.sender].role == Role.TUTOR),
            "Unauthorized access"
        );

        ExamSession storage session = examSessions[examId][student];
        return (session.score, session.isCompleted);
    }

    // Get correct answers for an exam (only for tutors)
    function getExamCorrectAnswers(
        uint256 examId
    ) public view examExists(examId) returns (uint256[] memory) {
        require(
            registeredUsers[msg.sender] && users[msg.sender].role == Role.TUTOR,
            "Only tutors can access correct answers"
        );

        Exam storage exam = exams[examId];
        uint256[] memory correctAnswers = new uint256[](exam.questionCount);

        for (uint256 i = 0; i < exam.questionCount; i++) {
            correctAnswers[i] = examCorrectAnswers[examId][i];
        }

        return correctAnswers;
    }

    // Get correct answers for an exam (for students who have completed the exam)
    function getCorrectAnswersForStudent(
        uint256 examId
    ) public view examExists(examId) onlyStudent returns (uint256[] memory) {
        Exam storage exam = exams[examId];

        // Check if student is enrolled in the course
        require(
            courseEnrollments[exam.courseId][msg.sender],
            "Not enrolled in course"
        );

        // Check if student has completed the exam
        require(
            examSessions[examId][msg.sender].isCompleted,
            "Must complete exam before viewing correct answers"
        );

        uint256[] memory correctAnswers = new uint256[](exam.questionCount);

        for (uint256 i = 0; i < exam.questionCount; i++) {
            correctAnswers[i] = examCorrectAnswers[examId][i];
        }

        return correctAnswers;
    }

    // Get detailed exam review for student (questions, options, correct answers, student answers)
    function getExamReviewForStudent(
        uint256 examId
    )
        public
        view
        examExists(examId)
        onlyStudent
        returns (
            string[] memory questionTexts,
            string[4][] memory questionOptions,
            uint256[] memory correctAnswers,
            uint256[] memory studentAnswers,
            bool[] memory isCorrect,
            uint256 totalScore,
            uint256 maxScore
        )
    {
        Exam storage exam = exams[examId];
        ExamSession storage session = examSessions[examId][msg.sender];

        // Check if student is enrolled in the course
        require(
            courseEnrollments[exam.courseId][msg.sender],
            "Not enrolled in course"
        );

        // Check if student has completed the exam
        require(
            session.isCompleted,
            "Must complete exam before viewing review"
        );

        // Initialize arrays
        questionTexts = new string[](exam.questionCount);
        questionOptions = new string[4][](exam.questionCount);
        correctAnswers = new uint256[](exam.questionCount);
        studentAnswers = new uint256[](exam.questionCount);
        isCorrect = new bool[](exam.questionCount);
        totalScore = session.score;
        maxScore = exam.questionCount;

        // Populate all data
        for (uint256 i = 0; i < exam.questionCount; i++) {
            questionTexts[i] = examQuestions[examId][i];
            questionOptions[i] = examOptions[examId][i];
            correctAnswers[i] = examCorrectAnswers[examId][i];
            studentAnswers[i] = session.answers[i];
            isCorrect[i] = (session.answers[i] ==
                examCorrectAnswers[examId][i]);
        }

        return (
            questionTexts,
            questionOptions,
            correctAnswers,
            studentAnswers,
            isCorrect,
            totalScore,
            maxScore
        );
    }

    // Get both correct answers and student submitted answers for comparison
    function getExamAnswersComparison(
        uint256 examId,
        address student
    )
        public
        view
        examExists(examId)
        returns (
            uint256[] memory correctAnswers,
            uint256[] memory studentAnswers,
            bool[] memory isCorrect,
            bool isCompleted
        )
    {
        // Allow access to tutors or the student themselves
        require(
            msg.sender == student ||
                (registeredUsers[msg.sender] &&
                    users[msg.sender].role == Role.TUTOR),
            "Unauthorized access"
        );

        Exam storage exam = exams[examId];
        ExamSession storage session = examSessions[examId][student];

        // Initialize arrays
        correctAnswers = new uint256[](exam.questionCount);
        studentAnswers = new uint256[](exam.questionCount);
        isCorrect = new bool[](exam.questionCount);
        isCompleted = session.isCompleted;

        // Populate correct answers
        for (uint256 i = 0; i < exam.questionCount; i++) {
            correctAnswers[i] = examCorrectAnswers[examId][i];
        }

        // If exam is completed, populate student answers and comparison
        if (isCompleted) {
            for (uint256 i = 0; i < exam.questionCount; i++) {
                studentAnswers[i] = session.answers[i];
                isCorrect[i] = (session.answers[i] ==
                    examCorrectAnswers[examId][i]);
            }
        }

        return (correctAnswers, studentAnswers, isCorrect, isCompleted);
    }

    // Helper Functions
    function getCourse(
        uint256 courseId
    ) public view courseExists(courseId) returns (Course memory) {
        return courses[courseId];
    }

    function getExam(
        uint256 examId
    ) public view examExists(examId) returns (Exam memory) {
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

    function getAvailableExamsForStudent(
        address student
    ) public view returns (Exam[] memory) {
        Exam[] memory allExams = new Exam[](examCounter);
        uint256 availableCount = 0;

        for (uint256 i = 0; i < examCounter; i++) {
            if (
                exams[i].isActive &&
                courseEnrollments[exams[i].courseId][student]
            ) {
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

    // Get exams with completion status for a student
    function getExamsWithStatusForStudent(
        address student
    )
        public
        view
        returns (
            Exam[] memory availableExams,
            bool[] memory completionStatus,
            uint256[] memory scores
        )
    {
        Exam[] memory allExams = new Exam[](examCounter);
        bool[] memory allCompletionStatus = new bool[](examCounter);
        uint256[] memory allScores = new uint256[](examCounter);
        uint256 availableCount = 0;

        for (uint256 i = 0; i < examCounter; i++) {
            if (
                exams[i].isActive &&
                courseEnrollments[exams[i].courseId][student]
            ) {
                allExams[availableCount] = exams[i];
                allCompletionStatus[availableCount] = examSessions[i][student]
                    .isCompleted;
                allScores[availableCount] = examSessions[i][student].score;
                availableCount++;
            }
        }

        // Resize arrays to only include available exams
        availableExams = new Exam[](availableCount);
        completionStatus = new bool[](availableCount);
        scores = new uint256[](availableCount);

        for (uint256 i = 0; i < availableCount; i++) {
            availableExams[i] = allExams[i];
            completionStatus[i] = allCompletionStatus[i];
            scores[i] = allScores[i];
        }

        return (availableExams, completionStatus, scores);
    }
}
