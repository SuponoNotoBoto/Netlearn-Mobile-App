// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'NetLearn';

  @override
  String get appDescription => 'AR Computer Network Learning Application';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get materials => 'Materials';

  @override
  String get arScanner => 'AR Scanner';

  @override
  String get quizzes => 'Quizzes';

  @override
  String get profile => 'Profile';

  @override
  String get login => 'Login';

  @override
  String get logout => 'Logout';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get back => 'Back';

  @override
  String get next => 'Next';

  @override
  String get previous => 'Previous';

  @override
  String get continueText => 'Continue';

  @override
  String get close => 'Close';

  @override
  String get retry => 'Try Again';

  @override
  String get refresh => 'Refresh';

  @override
  String get loading => 'Loading';

  @override
  String get welcome => 'Welcome';

  @override
  String get hello => 'Hello';

  @override
  String get student => 'Student';

  @override
  String get lecturer => 'Lecturer';

  @override
  String get studentDashboard => 'Student Dashboard';

  @override
  String get lecturerDashboard => 'Lecturer Dashboard';

  @override
  String get learningMaterials => 'Learning Materials';

  @override
  String get learningModule => 'Learning Module';

  @override
  String get module => 'Module';

  @override
  String get modules => 'Modules';

  @override
  String get moduleList => 'Module List';

  @override
  String get computerNetworks => 'Computer Networks';

  @override
  String get learningProgress => 'Learning Progress';

  @override
  String get weeklyProgress => 'Weekly Progress';

  @override
  String get upcomingTasks => 'Upcoming Tasks';

  @override
  String get noUpcomingTasks => 'No upcoming tasks';

  @override
  String get noUpcomingTasksDescription => 'Tasks with deadlines will appear here.';

  @override
  String get viewAll => 'View All';

  @override
  String get deadline => 'Deadline';

  @override
  String get duration => 'Duration';

  @override
  String get minutes => 'minutes';

  @override
  String get available => 'Available';

  @override
  String get locked => 'Locked';

  @override
  String get unlocked => 'Unlocked';

  @override
  String get completed => 'Completed';

  @override
  String get inProgress => 'In Progress';

  @override
  String get notStarted => 'Not Started';

  @override
  String get readingMaterial => 'Reading Material';

  @override
  String get reading => 'Reading';

  @override
  String get video => 'Video';

  @override
  String get learningVideo => 'Learning Video';

  @override
  String get videoLearning => 'Learning Video';

  @override
  String get markAsCompleted => 'Mark as Completed';

  @override
  String get markAsRead => 'Mark as Read';

  @override
  String get readLabel => 'Read';

  @override
  String get overallProgress => 'Overall progress';

  @override
  String materialsCount(int count) {
    return '$count materials';
  }

  @override
  String moduleEyebrow(Object number) {
    return 'Module $number';
  }

  @override
  String get materialArtExampleIp => 'EXAMPLE IP';

  @override
  String get readingProgressLabel => 'Reading progress';

  @override
  String get downloadPdf => 'Download PDF';

  @override
  String get nextVideo => 'Next: Video';

  @override
  String get nextQuiz => 'Next: Quiz';

  @override
  String get evaluation => 'Evaluation';

  @override
  String get quizList => 'Quiz List';

  @override
  String get startQuiz => 'Start Quiz';

  @override
  String get resumeQuiz => 'Resume Quiz';

  @override
  String get submitAnswer => 'Submit Answer';

  @override
  String get submitQuiz => 'Submit Quiz';

  @override
  String get question => 'Question';

  @override
  String get questions => 'Questions';

  @override
  String get fromTotal => 'of';

  @override
  String get timeRemaining => 'Time Remaining';

  @override
  String get quizCompleted => 'Quiz Completed';

  @override
  String get score => 'Score';

  @override
  String get correct => 'Correct';

  @override
  String get wrong => 'Wrong';

  @override
  String get passed => 'Passed';

  @override
  String get failed => 'Failed';

  @override
  String get returnDashboard => 'Return to Dashboard';

  @override
  String get backToQuizList => 'Back to Quiz List';

  @override
  String get academicInformation => 'Academic Information';

  @override
  String get name => 'Name';

  @override
  String get identityNumber => 'Identity Number';

  @override
  String get email => 'Email';

  @override
  String get program => 'Program';

  @override
  String get accountStatus => 'Account Status';

  @override
  String get active => 'Active';

  @override
  String get inactive => 'Inactive';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get indonesian => 'Indonesian';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageIndonesian => 'Indonesian';

  @override
  String get logoutConfirmation => 'Are you sure you want to log out?';

  @override
  String get yesLogout => 'Yes, Log Out';

  @override
  String get error => 'Error';

  @override
  String get somethingWentWrong => 'Something went wrong.';

  @override
  String get pageNotFound => 'Page not found.';

  @override
  String get failedToLoad => 'Failed to load data.';

  @override
  String get sessionNotFound => 'Session not found.';

  @override
  String get profileNotFound => 'Profile not found.';

  @override
  String get arComingSoon => 'AR Scanner is coming soon.';

  @override
  String get arScannerTitle => 'AR Scanner';

  @override
  String get arStatusInitializing => 'Preparing the AR camera…';

  @override
  String get arStatusSearching => 'Point the camera at one of the NetLearn markers.';

  @override
  String get arMarkerDetected => 'Marker recognized';

  @override
  String get arScanPermissionDenied => 'Camera permission is required to scan markers. Enable camera access and try again.';

  @override
  String get arInitFailed => 'Could not start the AR camera. Your device may not support ARCore.';

  @override
  String get arRescanTooltip => 'Rescan';

  @override
  String get arHelpTooltip => 'Help';

  @override
  String get arHelpTitle => 'How to scan a marker';

  @override
  String get arHelpBody => '1. Print the NetLearn marker cards.\n2. Place a card on a flat surface.\n3. Point the camera at the whole card.\n4. Hold steady until the object information appears.';

  @override
  String arModuleBadge(int number) {
    return 'Module $number';
  }

  @override
  String get arObjKomputerName => 'Desktop Computer';

  @override
  String get arObjKomputerDesc => 'An end device that sends and receives data over the network.';

  @override
  String get arObjSwitchName => 'Switch';

  @override
  String get arObjSwitchDesc => 'Connects devices in a local network and forwards frames to the destination port using MAC addresses.';

  @override
  String get arObjHubName => 'Hub';

  @override
  String get arObjHubDesc => 'Connects devices and repeats incoming data to every connected port, unlike a switch that forwards only to the target device.';

  @override
  String get arObjRouterName => 'Router';

  @override
  String get arObjRouterDesc => 'Connects different networks and forwards packets between them using IP addresses and a routing table.';

  @override
  String get arObjTopologiName => 'Star Topology';

  @override
  String get arObjTopologiDesc => 'A topology where every device connects to a central switch. The central device is critical: if it fails, the whole network is affected.';

  @override
  String get arObjIpAddressName => 'IP Address Simulation';

  @override
  String get arObjIpAddressDesc => 'Configure the IPv4 address and subnet mask of two computers connected through one switch.';

  @override
  String get arDetailHeaderLabel => 'Detailed Information';

  @override
  String get arDetailSectionDefinition => 'Definition';

  @override
  String get arDetailSectionFunction => 'Function';

  @override
  String get arDetailExtraKomputer => 'Example Activities';

  @override
  String get arDetailExtraSwitch => 'How It Works';

  @override
  String get arDetailExtraHub => 'Difference from a Switch';

  @override
  String get arDetailExtraRouter => 'How It Works';

  @override
  String get arDetailExtraTopologi => 'Advantages and Limitations';

  @override
  String get arDetailOpenButton => 'View Full Information';

  @override
  String get arNarrationMute => 'Turn off narration';

  @override
  String get arNarrationReplay => 'Listen again';

  @override
  String get arNarrationUnmute => 'Turn on narration';

  @override
  String get arObjKomputerDetailDef => 'A computer is an end device that users use to send and receive data over a network.';

  @override
  String get arObjKomputerDetailFunction => 'In a network, the computer is a source or destination of data: it creates requests, sends data to other devices, and receives data from them.';

  @override
  String get arObjKomputerDetailExtra => 'Examples of computer activity in a network: opening web pages, sending email, uploading files, and streaming video. All of these are essentially processes of sending and receiving data.';

  @override
  String get arObjSwitchDetailDef => 'A network device that connects many devices within a single local area network (LAN).';

  @override
  String get arObjSwitchDetailFunction => 'The switch connects devices in a local network and forwards data only to the destination device, so network traffic stays more efficient than with a hub.';

  @override
  String get arObjSwitchDetailExtra => 'How it works: the switch reads the destination MAC address on each frame and forwards it to the port connected to the destination device using its MAC table.';

  @override
  String get arObjHubDetailDef => 'A simple network device that connects several devices within one network.';

  @override
  String get arObjHubDetailFunction => 'The hub connects devices and forwards incoming data to every connected port, without knowing which device is the destination.';

  @override
  String get arObjHubDetailExtra => 'Difference from a switch: the hub broadcasts data to all devices, while the switch forwards data only to the destination device based on the MAC address. Hubs are therefore less efficient and more prone to collisions.';

  @override
  String get arObjRouterDetailDef => 'A network device that connects two or more different networks.';

  @override
  String get arObjRouterDetailFunction => 'The router forwards data packets between networks, choosing the best path toward the destination network.';

  @override
  String get arObjRouterDetailExtra => 'How it works: the router reads the destination IP address on the packet and decides the forwarding path using its routing table. Routers let devices from different networks communicate, for example between a home LAN and the internet.';

  @override
  String get arObjTopologiDetailDef => 'A network layout in which every device connects directly to a single central device, usually a switch or hub.';

  @override
  String get arObjTopologiDetailFunction => 'The central device acts as the shared connection point: all data between devices passes through it before being forwarded to its destination.';

  @override
  String get arObjTopologiDetailExtra => 'Advantages: easy to add devices and easy to detect a faulty cable. Limitation: if the central device fails, the whole network stops working (single point of failure).';

  @override
  String get arIpComputerA => 'Computer A';

  @override
  String get arIpComputerB => 'Computer B';

  @override
  String get arIpSwitch => 'Switch';

  @override
  String get arIpAddressLabel => 'IP Address';

  @override
  String get arIpSubnetLabel => 'Subnet Mask';

  @override
  String get arIpTestButton => 'Test Connection';

  @override
  String get arIpResetButton => 'Reset';

  @override
  String get arIpInitialHint => 'Enter each computer\'s IPv4 address and subnet mask, then test the connection.';

  @override
  String get arIpSuccessTitle => 'Connection Succeeded';

  @override
  String arIpSuccessReason(String network) {
    return 'Both computers are in the same subnet ($network).';
  }

  @override
  String get arIpFailureTitle => 'Connection Failed';

  @override
  String get arIpErrInvalidIpA => 'Computer A\'s IP address is not a valid IPv4 address.';

  @override
  String get arIpErrInvalidMaskA => 'Computer A\'s subnet mask is not valid.';

  @override
  String get arIpErrUnusableHostA => 'Computer A\'s address cannot be used as a host address.';

  @override
  String get arIpErrInvalidIpB => 'Computer B\'s IP address is not a valid IPv4 address.';

  @override
  String get arIpErrInvalidMaskB => 'Computer B\'s subnet mask is not valid.';

  @override
  String get arIpErrUnusableHostB => 'Computer B\'s address cannot be used as a host address.';

  @override
  String get arIpErrDuplicate => 'Both computers use the same IP address.';

  @override
  String get arIpErrDifferentSubnet => 'The computers are in different subnets, so they cannot communicate through the switch without routing.';

  @override
  String get loginTitle => 'Welcome to NetLearn!';

  @override
  String get loginSubtitle => 'Sign in using your personal email, institutional email, or student ID.';

  @override
  String get welcomeBack => 'Welcome back';

  @override
  String get emailOrStudentId => 'Email or Student ID';

  @override
  String get enterEmailOrStudentId => 'Enter your NIM or Email';

  @override
  String get emailOrLecturerId => 'Email or Lecturer ID';

  @override
  String get enterEmailOrLecturerId => 'Enter your NIP or Email';

  @override
  String get password => 'Password';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get signIn => 'Sign In';

  @override
  String get loginAsStudent => 'Login as Student';

  @override
  String get loginAsLecturer => 'Login as Lecturer';

  @override
  String get loginAsAdmin => 'Login as Admin';

  @override
  String get studentId => 'Student ID';

  @override
  String get lecturerId => 'Lecturer ID';

  @override
  String get enterStudentId => 'Enter your student ID';

  @override
  String get enterLecturerId => 'Enter your lecturer ID';

  @override
  String get enterEmail => 'Enter your email';

  @override
  String get enterPassword => 'Enter your password';

  @override
  String get invalidCredentials => 'Invalid credentials.';

  @override
  String get accountInactive => 'Your account is inactive.';

  @override
  String get forgotPasswordTitle => 'Forgot Password';

  @override
  String get forgotPasswordSubtitle => 'Enter the registered email address to receive a password reset code.';

  @override
  String get sendResetLink => 'Send Reset Link';

  @override
  String get resetPasswordHeading => 'Reset\nPassword';

  @override
  String get backToLogin => 'Back to Login';

  @override
  String get requiredField => 'This field is required';

  @override
  String get invalidEmail => 'Enter a valid email address.';

  @override
  String get emailSent => 'Email Sent';

  @override
  String get passwordResetEmailSent => 'If the email is registered, a password reset link has been sent. Check your inbox.';

  @override
  String get registerTitle => 'Create Account';

  @override
  String get registerHeading => 'Register';

  @override
  String get registerSubtitle => 'Create an account to start learning with NetLearn.';

  @override
  String get register => 'Register';

  @override
  String get fullName => 'Full Name';

  @override
  String get enterFullName => 'Enter your full name';

  @override
  String get studentIdOrEmployeeId => 'Student ID / Employee ID';

  @override
  String get enterStudentOrEmployeeId => 'Enter your Student ID';

  @override
  String get userEmail => 'User Email';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get confirmPasswordPlaceholder => 'Confirm your password';

  @override
  String get passwordMismatch => 'Password confirmation does not match.';

  @override
  String get passwordMinLength => 'Password must be at least 8 characters';

  @override
  String get authIdentifierRequired => 'NIM or Email is required.';

  @override
  String get authPasswordRequired => 'Password is required.';

  @override
  String get fullNameRequired => 'Full name is required.';

  @override
  String get studentIdRequired => 'Student ID is required.';

  @override
  String get emailRequired => 'Email is required.';

  @override
  String get confirmPasswordRequired => 'Password confirmation is required.';

  @override
  String get bannerConnectionFailed => 'Connection problem. Check your internet and try again.';

  @override
  String get bannerServerProblem => 'Something went wrong on the server. Please try again.';

  @override
  String get bannerUnknownError => 'Something went wrong. Please try again.';

  @override
  String get resetRequestSent => 'Password reset instructions were requested. Check your email.';

  @override
  String get registerSuccessTitle => 'Registration Successful';

  @override
  String get registerSuccessMessage => 'We\'ve sent a confirmation link to your email. Check your inbox and spam folder, confirm it, then sign in with your new account.';

  @override
  String get registerSuccessLoginPrompt => 'Registration successful. Please sign in with your email and password.';

  @override
  String get alreadyHaveAccount => 'Already have an account? Login';

  @override
  String get noAccountYet => 'Don\'t have an account? Register';

  @override
  String get chooseYourLanguage => 'Choose Your Language';

  @override
  String get onboardingDescription => 'Choose the language you want to use while learning with NetLearn.';

  @override
  String get continueButton => 'Continue';

  @override
  String get prototypeMode => 'Prototype mode · Language selection appears after every successful login.';

  @override
  String get computerNetworkingLMS => 'Computer Networking LMS';

  @override
  String unreadNotifications(int count) {
    return '$count unread notifications';
  }

  @override
  String get studentList => 'Student List';

  @override
  String get studentScoreSummary => 'Student Score Recap';

  @override
  String tasksAwaitingReview(int count) {
    return '$count tasks awaiting review';
  }

  @override
  String get reviewStudentSubmissions => 'Review student submissions';

  @override
  String tasksApproachingDeadline(int count) {
    return '$count tasks approaching their deadline';
  }

  @override
  String get trackActiveTasks => 'Track active tasks';

  @override
  String moduleNotPublished(int number) {
    return 'Module $number is not published';
  }

  @override
  String completeTheMaterial(String title) {
    return 'Complete the $title material';
  }

  @override
  String get viewMaterial => 'View Material';

  @override
  String get notifications => 'Notifications';

  @override
  String get registerButton => 'Register';

  @override
  String get registerLecturerNotice => 'Lecturer accounts are created by the admin. Select Student to register.';

  @override
  String get accountManagedBy => 'Account managed by ';

  @override
  String get campusAdministrator => 'campus administrator';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get tomorrow => 'Tomorrow';

  @override
  String get minutesShort => 'min';

  @override
  String get lockedModuleMessage => 'This module is still locked.';

  @override
  String get lockedNeedsPretest => 'Complete the Pretest';

  @override
  String get dashboardLoadError => 'Failed to load dashboard data.';

  @override
  String get moduleProgressLoadError => 'Failed to load module progress.';

  @override
  String get noModules => 'No modules yet';

  @override
  String get noModulesDescription => 'Published modules will appear here.';

  @override
  String moduleNumber(Object number) {
    return '$number';
  }

  @override
  String questionNumber(Object number) {
    return 'Question $number';
  }

  @override
  String questionsProgress(Object current, Object total) {
    return '$current of $total';
  }

  @override
  String durationMinutes(Object minutes) {
    return '$minutes minutes';
  }

  @override
  String progressPercentage(Object percentage) {
    return '$percentage%';
  }

  @override
  String get materialNotFound => 'Material not found.';

  @override
  String get learningMaterial => 'Learning Material';

  @override
  String get coreMaterial => 'Core';

  @override
  String get summary => 'Summary';

  @override
  String get readMaterial => 'Read Material';

  @override
  String get readMaterialDescription => 'Study the material before continuing to the next stage.';

  @override
  String get materialContentUnavailable => 'Reading material is not available.';

  @override
  String get readingCompletedMessage => 'Reading material completed successfully.';

  @override
  String progressSaveFailed(String error) {
    return 'Failed to save progress: $error';
  }

  @override
  String get learningVideoDescription => 'Watch the learning video to strengthen your understanding.';

  @override
  String get videoUnavailable => 'Video for this material is not available.';

  @override
  String get watched => 'Watched';

  @override
  String get videoPlayerComingSoon => 'Video player will be available in the next stage.';

  @override
  String get evaluationDescription => 'Complete the quiz after finishing the learning components.';

  @override
  String get materialLocked => 'Material locked';

  @override
  String get completePreviousModule => 'Complete the previous module first to unlock this material.';

  @override
  String get readMaterialTitle => 'Read Material';

  @override
  String get materialIdMissing => 'Material ID not found.';

  @override
  String get videoMaterialIdMissing => 'Video material ID not found.';

  @override
  String get assessmentTypeMissing => 'Assessment type not found.';

  @override
  String get assessmentTypeInvalid => 'Invalid assessment type.';

  @override
  String get assessmentResultIdMissing => 'Assessment result ID not found.';

  @override
  String get readingProgress => 'Reading progress';

  @override
  String get videoOptional => 'Supporting Video (Optional)';

  @override
  String get viewPdf => 'View PDF';

  @override
  String get materialResources => 'Material Resources';

  @override
  String get markAllAsRead => 'Mark All as Read';

  @override
  String get markAllAsReadDescription => 'Mark all reading materials in this module as completed.';

  @override
  String get noPdfAvailable => 'No PDF available for this material.';

  @override
  String get pdfOpenFailed => 'This PDF could not be displayed. Try downloading it.';

  @override
  String get materialResourcesDescription => 'This material includes a PDF you can view or download.';

  @override
  String get pdfDownloadSuccess => 'PDF downloaded successfully.';

  @override
  String get pdfDownloadFailed => 'Failed to download PDF. Please try again.';

  @override
  String get videoLearningSection => 'Video Learning';

  @override
  String get assessmentListIntroTitle => 'Your assessments';

  @override
  String get assessmentListIntroSubtitle => 'Measure your understanding, from start to finish.';

  @override
  String get assessmentListIntroBody => 'Complete the Pretest before starting the materials. The Post Test becomes available after all modules are completed.';

  @override
  String get assessmentInitialTag => 'Initial assessment';

  @override
  String get assessmentFinalTag => 'Final assessment';

  @override
  String get startPretest => 'Take the Pretest';

  @override
  String get startPostTestLabel => 'Start Post Test';

  @override
  String get viewPretestInstructions => 'View Pretest Instructions';

  @override
  String get viewPosttestInstructions => 'View Posttest Instructions';

  @override
  String assignmentMeta(String count, String minutes) {
    return '$count Questions · $minutes Minutes';
  }

  @override
  String get assessmentInitialDesc => 'Check your initial understanding before studying.';

  @override
  String get assessmentFinalDesc => 'Evaluate your understanding after completing all modules.';

  @override
  String get assignments => 'Assessment';

  @override
  String get assignmentsTab => 'Assessment';

  @override
  String get viewAssessmentHistory => 'View Assessment History';

  @override
  String get pretestInstructionsTopBar => 'Assessment - Pretest';

  @override
  String get pretestInstructionsArtLabel => 'KNOW YOUR STARTING POINT';

  @override
  String get pretestInstructionsTitle => 'Know your starting point';

  @override
  String get pretestInstructionsBody => 'Before you start learning, let\'s measure your understanding of computer networking.';

  @override
  String get pretestInstructionsQuestionsLabel => 'Number of questions';

  @override
  String pretestInstructionsQuestionsValue(String count) {
    return '$count questions';
  }

  @override
  String get pretestInstructionsDurationLabel => 'Time limit';

  @override
  String get pretestInstructionsTypeLabel => 'Question type';

  @override
  String get pretestInstructionsTypeValue => 'Multiple choice';

  @override
  String get pretestInstructionsWarningPrefix => 'The pretest can only be taken ';

  @override
  String get pretestInstructionsWarningEmphasis => 'once';

  @override
  String get pretestInstructionsWarningSuffix => '. Make sure your internet connection is stable and you are ready before starting.';

  @override
  String get pretestInstructionsLockTitle => 'The key to start learning';

  @override
  String get pretestInstructionsLockBody => 'Complete the pretest to unlock Module 1. The score does not affect your final grade.';

  @override
  String get startPretestNow => 'Start Pretest Now';

  @override
  String get posttestInstructionsTopBar => 'Assessment - Post Test';

  @override
  String get posttestInstructionsArtLabel => 'SHOW WHAT YOU HAVE LEARNED';

  @override
  String get posttestInstructionsTitle => 'Posttest Instructions';

  @override
  String get posttestInstructionsBody => 'You have completed all modules. Let\'s measure how far your understanding of computer networking has grown.';

  @override
  String get posttestInstructionsWarningPrefix => 'The post test can only be taken ';

  @override
  String get posttestInstructionsLockTitle => 'The final checkpoint';

  @override
  String get posttestInstructionsLockBody => 'The Post Test becomes available after all 4 modules have been completed. The score does not affect your final grade.';

  @override
  String get startPosttestNow => 'Start Post Test Now';

  @override
  String get continueLearning => 'Continue Learning';

  @override
  String get allMaterialsCompleted => 'All materials completed';

  @override
  String get assessmentCompletedTitle => 'Already Completed';

  @override
  String get assessmentCompletedBody => 'You have already completed this assessment.';

  @override
  String assessmentCompletedWithScore(String score) {
    return 'You have already completed this assessment with a score of $score.';
  }

  @override
  String assessmentCompletedOnlyOnce(String assessment) {
    return '$assessment can only be taken once and cannot be repeated.';
  }

  @override
  String get assessmentCompletedStatusPassed => 'Result: Passed';

  @override
  String get assessmentCompletedStatusFailed => 'Result: Not passed';

  @override
  String assessmentCompletedBreakdown(int correct, int wrong) {
    return '$correct correct · $wrong wrong';
  }

  @override
  String get viewAssessmentResult => 'View Result';

  @override
  String get assessmentLockedTitle => 'Assessment Locked';

  @override
  String get assessmentLockedPosttest => 'The Post Test becomes available after all 4 modules have been completed.';

  @override
  String get assessmentLockedGeneric => 'This assessment is not available yet.';

  @override
  String get assessmentLoadFailed => 'Failed to load assessments';

  @override
  String get assessmentLoadFailedBody => 'Check your internet connection and try again.';

  @override
  String get assessmentResult => 'Assessment Result';

  @override
  String get assessmentTotalQuestions => 'Total Questions';

  @override
  String get pretestCompletedMessage => 'The pretest is complete. You can continue to the learning materials.';

  @override
  String get posttestCompletedMessage => 'The post test is complete. The entire learning sequence has been completed.';

  @override
  String get backToAssessment => 'Back to Assessment';

  @override
  String get backToDashboard => 'Back to Dashboard';

  @override
  String get videoNotAvailable => 'This material has no video yet.';

  @override
  String get materialNotPublished => 'This material has not been published.';

  @override
  String get materialLockedMessage => 'This material is still locked.';

  @override
  String get markVideoDone => 'Mark as Done';

  @override
  String get videoDone => 'Video Done';

  @override
  String get videoMarkedDone => 'Video marked as done.';

  @override
  String get videoCannotOpen => 'This video cannot be opened';

  @override
  String get startReading => 'Start Reading';

  @override
  String get continueReading => 'Continue';

  @override
  String get noReadingContent => 'The reading content for this material is not available yet. Please contact your lecturer or admin.';

  @override
  String get readingMarked => 'Material marked as read.';

  @override
  String assessmentQuestionProgress(int current, int total) {
    return 'Question $current of $total';
  }

  @override
  String assessmentAnsweredCount(int count) {
    return '$count answered';
  }

  @override
  String get assessmentQuestionNavigation => 'Question Navigation';

  @override
  String get assessmentCurrentQuestion => 'Current question';

  @override
  String get assessmentAnsweredQuestion => 'Answered';

  @override
  String get assessmentUnansweredQuestion => 'Not answered';

  @override
  String get assessmentYourAnswer => 'Your answer';

  @override
  String get assessmentPreviousQuestion => 'Previous question';

  @override
  String get assessmentNextQuestion => 'Next question';

  @override
  String get assessmentSubmitTitle => 'Submit Assessment?';

  @override
  String assessmentSubmitWithUnanswered(int count) {
    return 'There are still $count unanswered questions. Are you sure you want to submit the assessment?';
  }

  @override
  String get assessmentSubmitAllAnswered => 'All questions have been answered. Are you sure you want to submit the assessment?';

  @override
  String get assessmentLeaveTitle => 'Leave Assessment?';

  @override
  String get assessmentLeaveBody => 'Your saved answers will remain saved, but the assessment will not be completed until you submit it.';

  @override
  String get stay => 'Stay';

  @override
  String get leave => 'Leave';

  @override
  String get assessmentSubmit => 'Submit';

  @override
  String get assessmentTimeWarning => 'Less than 1 minute remains.';

  @override
  String get assessmentNextAction => 'Next';

  @override
  String get assessmentSubmitAction => 'Submit Assessment';

  @override
  String get assessmentErrorNotFound => 'Assessment was not found.';

  @override
  String get assessmentErrorNotPublished => 'Assessment has not been published.';

  @override
  String get assessmentErrorNoQuestions => 'This assessment has no questions.';

  @override
  String get assessmentErrorAttemptNotFound => 'Assessment attempt was not found.';

  @override
  String get assessmentErrorLocked => 'Assessment is still locked.';

  @override
  String get assessmentErrorLockedOrCompleted => 'This test has already been completed or is not open yet.';

  @override
  String get assessmentErrorPretestRequired => 'You must complete the Pretest first.';

  @override
  String get assessmentErrorModulesIncomplete => 'All modules must be completed first.';

  @override
  String get assessmentErrorAlreadyCompleted => 'This assessment has already been completed.';

  @override
  String get assessmentErrorDeadlinePassed => 'The deadline for this assessment has passed.';

  @override
  String get assessmentErrorAttemptsExhausted => 'You have used up all attempts for this assessment.';

  @override
  String get assessmentErrorNotEnrolled => 'You are not enrolled in the class that owns this assessment.';

  @override
  String get assessmentErrorNoSession => 'Your login session was not found.';

  @override
  String get assessmentErrorGeneric => 'Something went wrong. Please try again.';

  @override
  String get backToMaterial => 'Back to Material';

  @override
  String get nextToVideo => 'Continue to Video';

  @override
  String get posttestUnlockedTitle => 'All modules complete!';

  @override
  String get posttestUnlockedMessage => 'You have finished every module. Take the Post-test to complete the course.';

  @override
  String get notNow => 'Not Now';

  @override
  String get startPosttest => 'Start Post-test';

  @override
  String get pretestLockedTitle => 'Pretest Not Completed';

  @override
  String get pretestLockedMessage => 'This module unlocks once you complete the Pretest. Take the Pretest first to open this material.';

  @override
  String get readyToStart => 'Ready to start';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get assessment => 'Assessment';

  @override
  String get on => 'On';

  @override
  String get off => 'Off';

  @override
  String get lecturerDashboardSubtitle => 'Information Technology Education';

  @override
  String get contentManagement => 'Content Management';

  @override
  String get manageMaterials => 'Manage Materials';

  @override
  String get manageMaterialsDescription => 'Add and edit learning materials';

  @override
  String get manageAssessments => 'Manage Assessments';

  @override
  String get manageAssessmentsDescription => 'Questions and answer keys';

  @override
  String get addMaterial => 'Add Material';

  @override
  String get addMaterialDescription => 'Create a new learning material';

  @override
  String get totalStudents => 'Total Students';

  @override
  String get totalClasses => 'Total Classes';

  @override
  String get averageScore => 'Average Score';

  @override
  String get noClassData => 'No class data yet';

  @override
  String publishedOfTotal(int count, int total) {
    return '$count of $total published';
  }

  @override
  String scorePercent(String value) {
    return '$value%';
  }

  @override
  String get searchMaterials => 'Search materials';

  @override
  String get allModules => 'All Modules';

  @override
  String get noVideo => 'No video';

  @override
  String createdAt(String date) {
    return 'Created $date';
  }

  @override
  String get coreMaterialProtected => 'Core materials cannot be deleted';

  @override
  String get coreModuleLocked => 'Only core materials can be placed in a module';

  @override
  String get noMaterials => 'No materials yet';

  @override
  String get noMaterialsDescription => 'Tap Add Material to create your first learning material.';

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Delete';

  @override
  String get publish => 'Publish';

  @override
  String get unpublish => 'Unpublish';

  @override
  String get published => 'Published';

  @override
  String get draft => 'Draft';

  @override
  String get deleteMaterial => 'Delete Material';

  @override
  String get deleteMaterialConfirmBody => 'This material will be permanently removed. Student progress for it is deleted as well.';

  @override
  String get materialDeleted => 'Material deleted.';

  @override
  String get materialPublished => 'Material published.';

  @override
  String get materialUnpublished => 'Material unpublished.';

  @override
  String get materialCreated => 'Material created.';

  @override
  String get materialUpdated => 'Material updated.';

  @override
  String get materialSaveFailed => 'Could not save the material.';

  @override
  String get coreProtectedError => 'This is a core material and cannot be changed.';

  @override
  String get invalidVideoUrlError => 'That video URL is not a valid YouTube link.';

  @override
  String get notPermittedError => 'You don\'t have permission to do that.';

  @override
  String get addMaterialTitle => 'Add Material';

  @override
  String get editMaterial => 'Edit Material';

  @override
  String get materialTitleSection => 'Title';

  @override
  String get titleIndonesian => 'Title (Indonesian)';

  @override
  String get titleIndonesianHint => 'The title students see';

  @override
  String get titleEnglish => 'Title (English)';

  @override
  String get titleEnglishHint => 'Optional, shown when the app is in English';

  @override
  String get materialPlacementSection => 'Placement';

  @override
  String get orderIndex => 'Order Index';

  @override
  String get orderIndexInvalid => 'Enter a valid order number (1 or higher)';

  @override
  String get summaryHint => 'A short summary shown on the material card';

  @override
  String get description => 'Description';

  @override
  String get descriptionHint => 'Describe the task objectives';

  @override
  String get content => 'Content';

  @override
  String get materialContentSection => 'Content';

  @override
  String get materialContentHint => 'Plain text. Use three backticks for monospaced blocks, \'- \' for bullets and \'1. \' for headings.';

  @override
  String get contentHint => 'Reading content';

  @override
  String get videoUrl => 'Video URL';

  @override
  String get durationMinutesLabel => 'Duration (minutes)';

  @override
  String get studyTimeLabel => 'Estimated study time (minutes)';

  @override
  String get studyTimeHint => 'Reading time plus video. This is not the YouTube video length.';

  @override
  String get durationInvalid => 'Enter a valid duration';

  @override
  String get publishOn => 'Publish immediately';

  @override
  String get publishOff => 'Save as draft';

  @override
  String get assessmentIntro => 'Both assessments are shared by all students. Every question needs an answer key before it can be published.';

  @override
  String get noAssessments => 'No assessments';

  @override
  String get noAssessmentsDescription => 'There are no assessments in this course yet.';

  @override
  String get pretest => 'Pre-test';

  @override
  String get posttest => 'Post-test';

  @override
  String get questionsShort => 'questions';

  @override
  String get answerKeysShort => 'answer keys';

  @override
  String answerKeyMissing(int count) {
    return '$count questions missing answer key';
  }

  @override
  String get manageQuestions => 'Manage Questions';

  @override
  String get assessmentPublished => 'Assessment published.';

  @override
  String get assessmentUnpublished => 'Assessment unpublished.';

  @override
  String get assessmentQuizIncomplete => 'Cannot publish: every question needs an answer key.';

  @override
  String get assessmentSaveFailed => 'Failed to save assessment.';

  @override
  String get addQuestion => 'Add Question';

  @override
  String get editQuestion => 'Edit Question';

  @override
  String get noQuestions => 'No questions yet';

  @override
  String get noQuestionsDescription => 'Tap Add Question to build this assessment.';

  @override
  String get questionText => 'Question';

  @override
  String get questionTextHint => 'Enter the question text';

  @override
  String get answerOptions => 'Answer Options';

  @override
  String get optionHint => 'Enter option text';

  @override
  String get correctAnswer => 'Correct Answer';

  @override
  String get answerKeyHint => 'Select the correct answer';

  @override
  String get pickAnswerKey => 'Please select the correct answer first.';

  @override
  String get noAnswerKey => 'No answer key set';

  @override
  String get questionImage => 'Question Image URL';

  @override
  String get questionAdded => 'Question added.';

  @override
  String get questionUpdated => 'Question updated.';

  @override
  String get questionDeleted => 'Question deleted.';

  @override
  String get questionSaveFailed => 'Could not save the question.';

  @override
  String get deleteQuestion => 'Delete Question';

  @override
  String get deleteQuestionConfirmBody => 'The answer key and any student answers to this question are deleted too, and cannot be restored.';

  @override
  String get nip => 'NIP';

  @override
  String get role => 'Role';

  @override
  String get roleLecturer => 'Lecturer';

  @override
  String get accountInformation => 'Account information';

  @override
  String get profileReadOnlyNote => 'Your name, NIP and email are managed by the admin. Contact them to change them.';

  @override
  String get myProfile => 'My Profile';

  @override
  String get joinedSince => 'Joined since';

  @override
  String get users => 'Users';

  @override
  String get tasks => 'Tasks';

  @override
  String get status => 'Status';

  @override
  String get manage => 'Manage';

  @override
  String get overview => 'Overview';

  @override
  String get all => 'All';

  @override
  String get lockStatus => 'Lock Status';

  @override
  String get materialAccessLabel => 'Material access';

  @override
  String get materialAccessOptionProgress => 'Progress';

  @override
  String get materialAccessOptionOpen => 'Open';

  @override
  String get materialAccessOptionLocked => 'Locked';

  @override
  String get materialAccessHelp => 'Follow progress: counts toward finishing the module, like every ordinary material. Open / Locked: your override — optional for students, never blocks the next module.';

  @override
  String get materialAccessForcedOpenBadge => 'Forced open';

  @override
  String get materialAccessForcedLockedBadge => 'Forced locked';

  @override
  String get materialAccessLockedItemMessage => 'This material is locked by the lecturer.';

  @override
  String get statusPublished => 'Published';

  @override
  String get statusDraft => 'Draft';

  @override
  String get studyProgram => 'Study Programme';

  @override
  String get notFilledYet => '(not filled in yet)';

  @override
  String get academicTag => 'Information Technology Education';

  @override
  String get studentAcademicTag => 'Information Technology Education';

  @override
  String get settingsAndActivity => 'Settings & Activity';

  @override
  String get profileInfo => 'Profile Information';

  @override
  String get academicInfo => 'Academic Information';

  @override
  String get academicInfoStudentSubtitle => 'NIM, Semester, and Study Program details';

  @override
  String get assessmentHistory => 'Assessment History';

  @override
  String get assessmentCoreTab => 'Pretest & Post Test';

  @override
  String get assessmentHistorySubtitle => 'Pretest & Post Test transcripts';

  @override
  String get studentProgressLabel => 'Progress';

  @override
  String get studentModulesLabel => 'Modules';

  @override
  String get studentAverageScoreLabel => 'Average Score';

  @override
  String get securityAndPassword => 'Security & Password';

  @override
  String get appVersion => 'NetLearn v1.0.0 · Learn. Connect. Grow.';

  @override
  String get themeLight => 'Light Theme';

  @override
  String get themeDark => 'Dark Theme';

  @override
  String get changePasswordNotAvailable => 'Password change not available yet. Use the link below to reset.';

  @override
  String get usePasswordReset => 'Forgot Password';

  @override
  String get passwordResetEmailFailed => 'Failed to send the password reset link. Make sure your email is valid.';

  @override
  String get assessmentHistoryEmpty => 'No assessment history yet. Complete your first assessment to see its result here.';

  @override
  String get historyStudentId => 'Student ID';

  @override
  String get historyPretestTitle => 'Pretest';

  @override
  String get historyPosttestTitle => 'Posttest';

  @override
  String get historyCompletedLabel => 'Assessments completed';

  @override
  String get historyAverageLabel => 'Average available score';

  @override
  String get historyScoreLabel => 'Score:';

  @override
  String historyCoreIncomplete(String done) {
    return '$done/2 · Assessments not complete';
  }

  @override
  String get studentSpaceHeading => 'Your learning space';

  @override
  String get studentDashboardSubtitle => 'Ready to learn something new today?';

  @override
  String get shortcutPretest => 'Pretest';

  @override
  String get shortcutPretestHint => 'Test your knowledge';

  @override
  String get shortcutModules => 'Modules';

  @override
  String get shortcutModulesHint => '4 learning modules';

  @override
  String get shortcutScanner => 'AR Scanner';

  @override
  String get shortcutScannerHint => 'Explore in 3D';

  @override
  String get shortcutPosttest => 'Post Test';

  @override
  String get shortcutPosttestHint => 'Final assessment';

  @override
  String get shortcutAssignments => 'Assessment';

  @override
  String get shortcutAssignmentsHint => 'Tasks & assessments';

  @override
  String get shortcutAssessmentHistory => 'Assessment History';

  @override
  String get shortcutAssessmentHistoryHint => 'Scores and progress history';

  @override
  String get shortcutProfile => 'Profile';

  @override
  String get shortcutProfileHint => 'Account & settings';

  @override
  String get shortcutVirtualLab => 'Virtual Lab';

  @override
  String get shortcutVirtualLabHint => 'Network simulation';

  @override
  String get virtualLab => 'Virtual Lab';

  @override
  String get virtualLabAddPc => 'Add PC';

  @override
  String get virtualLabAddSwitch => 'Add switch';

  @override
  String get virtualLabConnect => 'Connect';

  @override
  String get virtualLabConnectFinish => 'Create cable';

  @override
  String get virtualLabEmptyHint => 'Use the toolbar above to add devices and link them';

  @override
  String get virtualLabDeleteSelected => 'Delete selected';

  @override
  String get virtualLabReset => 'Reset canvas';

  @override
  String get virtualLabConnectNeedSelection => 'Select a device first';

  @override
  String get virtualLabConnectPendingHint => 'Tap a second device to create the cable';

  @override
  String get virtualLabSelectedCable => 'Cable selected';

  @override
  String get virtualLabTestConnectivity => 'Test connectivity';

  @override
  String get virtualLabTestSuccess => 'Connection succeeded';

  @override
  String get virtualLabTestFailed => 'Connection failed';

  @override
  String get virtualLabTestNeedDevices => 'Add network settings to at least two devices first';

  @override
  String get virtualLabConfigDeviceTitle => 'Device configuration';

  @override
  String get virtualLabIpLabel => 'IP Address';

  @override
  String get virtualLabMaskLabel => 'Subnet Mask';

  @override
  String get virtualLabNoIp => 'Not configured';

  @override
  String get virtualLabScenario1 => 'Scenario 1';

  @override
  String get virtualLabReasonInvalidIp => 'Invalid IP address format.';

  @override
  String get virtualLabReasonInvalidMask => 'Invalid subnet mask format.';

  @override
  String get virtualLabReasonHostAddress => 'An address is a network or broadcast address, not a host.';

  @override
  String get virtualLabReasonDuplicate => 'Duplicate IP address detected.';

  @override
  String get virtualLabReasonNoPath => 'No network path between the configured devices.';

  @override
  String get virtualLabReasonDifferentSubnet => 'Devices are in different subnets.';

  @override
  String get virtualLabSelectedDevice => 'Device selected';

  @override
  String get virtualLabSubtitle => 'Build a topology, set IPv4, then test connectivity with ping.';

  @override
  String get virtualLabScenarioLabel => 'SCENARIO 1 · SINGLE-SUBNET LAN';

  @override
  String get virtualLabScenarioDescription => 'Connect PC2 to Switch1, give it an IP in 192.168.1.0/24, then ping from PC1 to PC2.';

  @override
  String get virtualLabToolSelect => 'Select';

  @override
  String get virtualLabToolCable => 'Cable';

  @override
  String get virtualLabToolPc => 'PC';

  @override
  String get virtualLabToolSwitch => 'Switch';

  @override
  String get virtualLabToolDelete => 'Delete';

  @override
  String get virtualLabToolReset => 'Reset';

  @override
  String get virtualLabLegendConnected => 'Connected';

  @override
  String get virtualLabLegendNeedsConfig => 'Needs config';

  @override
  String get virtualLabLegendNotCabled => 'Not cabled';

  @override
  String get virtualLabCanvasHint => 'Tap to select · drag to move · tap a cable to select it';

  @override
  String get virtualLabPanelConfiguration => 'Configuration';

  @override
  String get virtualLabPanelPingTest => 'Ping Test';

  @override
  String get virtualLabNoDeviceSelected => 'Tap a device on the canvas to configure it.';

  @override
  String get virtualLabDeviceNameLabel => 'Device name';

  @override
  String get virtualLabDevicePcPorts => 'PC · 1 port NIC';

  @override
  String get virtualLabDeviceSwitchPorts => 'Switch · multi-port';

  @override
  String get virtualLabStatusInvalid => 'Invalid';

  @override
  String get virtualLabCableConnected => 'Cable: connected';

  @override
  String get virtualLabCableNotConnected => 'Cable: not connected';

  @override
  String get virtualLabApply => 'Apply configuration';

  @override
  String get virtualLabPingSource => 'Source';

  @override
  String get virtualLabPingTarget => 'Target';

  @override
  String get virtualLabPingRun => 'Run ping';

  @override
  String get virtualLabPingSuccess => 'Ping succeeded — both devices can reach each other.';

  @override
  String get virtualLabPingFailed => 'Ping failed';

  @override
  String get virtualLabPingNoDevices => 'Add at least two devices first.';

  @override
  String get virtualLabPingSameDevice => 'Choose two different devices to ping.';

  @override
  String get virtualLabCableIssueSameDevice => 'Pick a different device for the other end of the cable.';

  @override
  String get virtualLabCableIssuePcPortFull => 'This PC already uses its only port. Delete its existing cable first.';

  @override
  String get virtualLabCableIssueDuplicate => 'These two devices are already connected.';

  @override
  String get virtualLabReasonNotConfigured => 'A device has no IP configuration yet.';

  @override
  String get virtualLabFooterNote => 'Local on-device simulation · Scores and progress unaffected.';

  @override
  String get virtualLabBackToDashboard => 'Back to Dashboard';

  @override
  String get learningJourney => 'Your learning journey';

  @override
  String modulesCompletedOf(Object completed, Object total) {
    return '$completed of $total modules completed';
  }

  @override
  String moduleMaterialsCompleted(int completed, int total) {
    return '$completed of $total materials completed';
  }

  @override
  String get keepGoing => 'Keep going!';

  @override
  String get oneStepToday => 'One small step today,';

  @override
  String get oneConnectionTomorrow => 'one big connection for your future.';

  @override
  String get aboutNetLearn => 'About NetLearn';

  @override
  String get aboutNetLearnHeadline => 'NetLearn — Computer Networking Learning Platform';

  @override
  String get aboutNetLearnBody => 'NetLearn is a computer networking learning platform designed to help students learn networking concepts through structured learning materials, digital reading, learning videos, and assessments.';

  @override
  String get aboutNetLearnBodyLecturers => 'The platform also supports lecturers in managing learning materials and organizing learning resources in one place.';

  @override
  String get aboutReleaseBadge => 'Release';

  @override
  String get aboutUnderDevelopmentBadge => 'Under Development';

  @override
  String get aboutPreReleaseNote => 'The application has been officially released and is ready to use.';

  @override
  String get aboutVersion => 'Version 1.0.0';

  @override
  String get keyFeaturesTitle => 'Key Features';

  @override
  String get aboutFeatureMaterialsTitle => 'Learning Materials';

  @override
  String get aboutFeatureMaterialsDescription => 'Access structured computer networking lessons.';

  @override
  String get aboutFeatureReadingTitle => 'Digital Reading';

  @override
  String get aboutFeatureReadingDescription => 'Study networking topics through the material reader.';

  @override
  String get aboutFeatureVideosTitle => 'Learning Videos';

  @override
  String get aboutFeatureVideosDescription => 'Access available supporting learning videos.';

  @override
  String get aboutFeatureAssessmentTitle => 'Assessment';

  @override
  String get aboutFeatureAssessmentDescription => 'Complete Pretest and Posttest activities to evaluate understanding.';

  @override
  String get aboutFeatureProgressTitle => 'Learning Progress';

  @override
  String get aboutFeatureProgressDescription => 'Review your progress through the available learning activities.';

  @override
  String get aboutFeatureLecturerTitle => 'Lecturer Material Management';

  @override
  String get aboutFeatureLecturerDescription => 'Help lecturers create, edit, and manage learning materials.';

  @override
  String get downloadResourcesTitle => 'Download Resources';

  @override
  String get downloadMarkerTitle => 'Download Marker';

  @override
  String get downloadMarkerDescription => 'Download markers provided for supported Augmented Reality learning activities in NetLearn.';

  @override
  String get downloadMaterialsTitle => 'Download Materials';

  @override
  String get downloadMaterialsDescription => 'Download the NetLearn computer networking course material book in PDF format.';

  @override
  String get downloadManualsTitle => 'Download Manual Books';

  @override
  String get downloadManualsDescription => 'Access the NetLearn user guides explaining how to use the application\'s main features according to the available user roles.';

  @override
  String get downloadComingSoon => 'Coming Soon';

  @override
  String get notAvailableYet => 'Not Available Yet';

  @override
  String get downloadGeneric => 'Download';

  @override
  String get downloadPdfBadge => 'PDF';

  @override
  String get downloadSucceeded => 'PDF downloaded.';

  @override
  String get downloadFailed => 'Could not download the PDF. Please try again.';

  @override
  String get viewAllNotifications => 'View All Notifications';

  @override
  String componentsCompletedOf(int completed, int total) {
    return '$completed/$total · Components completed';
  }

  @override
  String get componentPretestSubtitle => 'Check your understanding before learning.';

  @override
  String get componentTapToOpen => 'Tap to open';

  @override
  String get componentCompletePretestFirst => 'Complete Pretest first.';

  @override
  String get componentPosttestSubtitle => 'Evaluate your understanding after all modules.';

  @override
  String get componentCompleteAllModules => 'Complete all modules first.';

  @override
  String lecturerGreeting(String name) {
    return 'Hello, $name 👋';
  }

  @override
  String get lecturerSpaceHeading => 'Teaching workspace';

  @override
  String get shortcutManageMaterials => 'Manage Materials';

  @override
  String get shortcutManageMaterialsHint => '12 materials';

  @override
  String get assignment => 'Assignments';

  @override
  String get shortcutAssignmentHint => 'Pretest & Post Test';

  @override
  String get shortcutManageQuestions => 'Manage Questions';

  @override
  String get shortcutManageQuestionsHint => 'Question bank';

  @override
  String get shortcutManageTasks => 'Manage Tasks';

  @override
  String get shortcutManageTasksHint => 'Tasks & submissions';

  @override
  String get shortcutLecturerProfile => 'Lecturer Profile';

  @override
  String get comingSoon => 'This feature is coming soon.';

  @override
  String get recentActivity => 'Recent Activity';

  @override
  String get recentNotifications => 'Recent Notifications';

  @override
  String get noNotifications => 'No notifications yet';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get announcements => 'Announcements';

  @override
  String get reminders => 'Reminders';

  @override
  String get noAnnouncements => 'No announcements yet';

  @override
  String get noAnnouncementsMessage => 'Announcements published by your lecturer will appear here.';

  @override
  String get noReminders => 'No upcoming deadlines';

  @override
  String get noRemindersMessage => 'Reminders appear when an assessment is pending or a deadline is approaching.';

  @override
  String get assessmentsCompleted => 'Assessments completed';

  @override
  String get assessmentsIncomplete => 'Assessments not complete';

  @override
  String get averageAvailableScore => 'Average available score';

  @override
  String get backToStudentList => 'Back to Student List';

  @override
  String get lecturerNoRemindersMessage => 'All students have completed the Pretest and Posttest.';

  @override
  String get noAssessmentHistory => 'No assessment history yet. Complete your first assessment to see its result here.';

  @override
  String get noStudentsFound => 'No students found.';

  @override
  String get reminderNotCompleted => 'Not completed';

  @override
  String get scoreTabEmpty => 'No student data yet.';

  @override
  String get searchStudentsHint => 'Search name or student ID';

  @override
  String get studentListIntro => 'Select a student to view their Pretest and Posttest scores.';

  @override
  String get studentScoreHistoryIntro => 'Pretest and Posttest score history.';

  @override
  String get viewScoreSummary => 'View Score Recap';

  @override
  String get notificationUnread => 'Unread';

  @override
  String get notificationRead => 'Read';

  @override
  String get notificationJustNow => 'Just now';

  @override
  String notificationMinutesAgo(Object count) {
    return '$count minutes ago';
  }

  @override
  String notificationHoursAgo(Object count) {
    return '$count hours ago';
  }

  @override
  String notificationDaysAgo(Object count) {
    return '$count days ago';
  }

  @override
  String get notificationReadSaveFailed => 'Could not save the read status.';

  @override
  String get manageAnnouncements => 'Manage Announcements';

  @override
  String get createAnnouncement => 'Create Announcement';

  @override
  String get editAnnouncement => 'Edit Announcement';

  @override
  String get announcementTitle => 'Announcement Title';

  @override
  String get announcementTitleHint => 'Enter a title for the announcement';

  @override
  String get announcementContent => 'Announcement Content';

  @override
  String get announcementContentHint => 'Write the announcement details here';

  @override
  String get recipientScope => 'Recipient Scope';

  @override
  String get allStudents => 'All Students';

  @override
  String get saveAsDraft => 'Save as Draft';

  @override
  String get publishAnnouncement => 'Publish Announcement';

  @override
  String get saveDraft => 'Save Draft';

  @override
  String get announcementDraft => 'Draft';

  @override
  String get announcementPublished => 'Published';

  @override
  String get deleteAnnouncement => 'Delete Announcement';

  @override
  String get deleteAnnouncementConfirm => 'This announcement will be permanently removed. Are you sure?';

  @override
  String get announcementDeleted => 'Announcement deleted.';

  @override
  String get announcementCreated => 'Announcement created.';

  @override
  String get announcementUpdated => 'Announcement updated.';

  @override
  String get announcementPublishedSuccess => 'Announcement published.';

  @override
  String get announcementUnpublished => 'Announcement unpublished.';

  @override
  String get announcementSaveFailed => 'Could not save the announcement.';

  @override
  String get titleRequired => 'Title is required';

  @override
  String get contentRequired => 'Content is required';

  @override
  String get reminderDueSoon => 'Due soon';

  @override
  String get reminderDueTomorrow => 'Due tomorrow';

  @override
  String get reminderOverdue => 'Overdue';

  @override
  String daysLeft(Object count) {
    return '$count days left';
  }

  @override
  String hoursLeft(Object count) {
    return '$count hours left';
  }

  @override
  String minutesLeft(Object count) {
    return '$count minutes left';
  }

  @override
  String get viewDetails => 'View Details';

  @override
  String get markAsReadAction => 'Mark as Read';

  @override
  String get by => 'by';

  @override
  String get assessments => 'Assessments';

  @override
  String get addTask => 'Add Assessment';

  @override
  String get editTask => 'Edit Task';

  @override
  String get editTaskAndQuestions => 'Edit Task & Questions';

  @override
  String get viewDetail => 'View Detail';

  @override
  String get taskDetails => 'Task Details';

  @override
  String get taskCreated => 'Task created.';

  @override
  String get taskUpdated => 'Task updated.';

  @override
  String get taskPublished => 'Task published.';

  @override
  String get taskUnpublished => 'Task unpublished.';

  @override
  String get taskSaveFailed => 'Could not save the task.';

  @override
  String get taskNotFound => 'Task not found.';

  @override
  String get taskIdMissing => 'Task ID not found.';

  @override
  String get noTasks => 'No tasks yet';

  @override
  String get noTasksDescription => 'Create your first task to get started.';

  @override
  String get basicInformation => 'Basic Information';

  @override
  String get timingDeadline => 'Timing & Deadline';

  @override
  String get taskTitle => 'Task Title';

  @override
  String get taskTitleHint => 'Enter task title';

  @override
  String get instructions => 'Instructions';

  @override
  String get instructionsHint => 'Instructions for students';

  @override
  String get moduleHint => 'Select a module';

  @override
  String get standaloneTask => 'Standalone Task';

  @override
  String get timeLimitMinutes => 'Time Limit (minutes)';

  @override
  String get timeLimitHelper => '0 means no time limit. Max 180 minutes.';

  @override
  String get timeLimitInvalid => 'Time limit must be between 0 and 180 minutes';

  @override
  String get timeLimitShort => 'limit';

  @override
  String get deadlineHint => 'Select deadline (optional)';

  @override
  String get deadlineInvalid => 'Invalid deadline format';

  @override
  String get createTask => 'Create Task';

  @override
  String get noDescription => 'No description provided';

  @override
  String get noInstructions => 'No instructions provided';

  @override
  String get submitted => 'Submitted';

  @override
  String get submissionRate => 'Submission rate:';

  @override
  String get taskResults => 'Task Results';

  @override
  String get questionImageHint => 'Optional image URL';

  @override
  String get assessmentPublishedTitle => 'Assessment Published';

  @override
  String get assessmentUnpublishedTitle => 'Assessment Unpublished';

  @override
  String get january => 'January';

  @override
  String get february => 'February';

  @override
  String get march => 'March';

  @override
  String get april => 'April';

  @override
  String get may => 'May';

  @override
  String get june => 'June';

  @override
  String get july => 'July';

  @override
  String get august => 'August';

  @override
  String get september => 'September';

  @override
  String get october => 'October';

  @override
  String get november => 'November';

  @override
  String get december => 'December';

  @override
  String get multipleChoice => 'Multiple Choice';

  @override
  String get backToAssessments => 'Back to Assessments';

  @override
  String get failedToLoadQuestions => 'Failed to load questions';

  @override
  String get submissionRateUnavailable => 'Student count unavailable';

  @override
  String get moveUp => 'Move up';

  @override
  String get moveDown => 'Move down';

  @override
  String get department => 'Department';

  @override
  String get informaticsEngineering => 'Informatics Engineering';

  @override
  String get informationTechnologyEducation => 'Information Technology Education';

  @override
  String get lecturerRoleProgram => 'Lecturer S1 Information Technology Education';

  @override
  String get materialPdf => 'Material PDF (optional)';

  @override
  String get uploadPdf => 'Upload PDF';

  @override
  String get replacePdf => 'Replace PDF';

  @override
  String get removePdf => 'Remove PDF';

  @override
  String get pdfUploading => 'Uploading PDF...';

  @override
  String get pdfUploaded => 'PDF uploaded.';

  @override
  String get pdfRemoved => 'PDF removed.';

  @override
  String get pdfUploadFailed => 'Could not upload the PDF.';

  @override
  String get pdfTooLarge => 'PDF is too large (max 20 MB).';

  @override
  String get pdfInvalidType => 'Please choose a PDF file.';

  @override
  String get noPdf => 'No PDF uploaded';

  @override
  String get openPdfFailed => 'Could not open the PDF.';

  @override
  String get accountEmail => 'Account Email';

  @override
  String answerKeysConfigured(int answered, int total) {
    return '$answered/$total Answer Keys Configured';
  }

  @override
  String get answerOptionsAndKey => 'Options & Answer Key';

  @override
  String get assessmentQuestions => 'Assessment Questions';

  @override
  String get backToSecurity => 'Back to Security';

  @override
  String get changeEmail => 'Change Email';

  @override
  String get changePassword => 'Change Password';

  @override
  String get changePasswordHint => 'You can change your password here';

  @override
  String get confirmNewPassword => 'Confirm New Password';

  @override
  String get confirmNewPasswordHint => 'Re-enter your new password';

  @override
  String get drafts => 'Drafts';

  @override
  String get forgotPasswordHint => 'Enter your email to receive a reset code';

  @override
  String get imageUrlHint => 'https://... (optional)';

  @override
  String get invalidOtp => 'Invalid code. Please try again.';

  @override
  String get manageAnnouncementsSubtitle => 'Manage your announcements';

  @override
  String get newPassword => 'New Password';

  @override
  String get newPasswordHint => 'Enter your new password';

  @override
  String get currentPassword => 'Current Password';

  @override
  String get strongPasswordHint => 'Use a strong password that you do not use on other accounts.';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get noAnnouncementsLecturerMessage => 'No announcements yet';

  @override
  String get noStudents => 'No students yet';

  @override
  String get noStudentsDescription => 'Students with the student role will appear here.';

  @override
  String get nim => 'NIM';

  @override
  String get posttestScore => 'Posttest Score';

  @override
  String get pretestScore => 'Pretest Score';

  @override
  String get scoreNotAvailable => 'Not available';

  @override
  String get scoreScaleHint => 'Scores are on a 0–100 scale. — means the assessment has not been completed.';

  @override
  String get scoreTableSemantics => 'Student score table';

  @override
  String get studentName => 'Student Name';

  @override
  String get otpCode => 'Verification Code';

  @override
  String get otpCodeHint => 'Enter the code sent to your email';

  @override
  String get otpSentTitle => 'Check Your Email';

  @override
  String otpSentBody(String submittedEmail) {
    return 'We sent a verification code to $submittedEmail';
  }

  @override
  String get passwordChangeNotAvailable => 'Password change is not available in demo mode';

  @override
  String get passwordDemoNote => 'This is a demo account. Password changes are disabled.';

  @override
  String get passwordTooShort => 'Password must be at least 8 characters';

  @override
  String get passwordUpdated => 'Password Updated';

  @override
  String get passwordUpdatedBody => 'Your password has been updated successfully.';

  @override
  String get passwordUpdateFailed => 'Failed to update password. Please try again.';

  @override
  String get pdfUploadHint => 'Upload a PDF file';

  @override
  String get preferencesAndAccount => 'Preferences & Account';

  @override
  String get questionNotFound => 'This question is no longer part of this assessment.';

  @override
  String get resendCode => 'Resend Code';

  @override
  String get resendCodeSent => 'A new code has been sent to your email.';

  @override
  String get savePassword => 'Save Password';

  @override
  String get saveQuestion => 'Save Question';

  @override
  String get scoreOverview => 'Score Recap';

  @override
  String get searchStudents => 'Search Students';

  @override
  String get securityFooterNote => 'Your security settings are managed by the administrator.';

  @override
  String get sendOtpCode => 'Send Code';

  @override
  String get setNewPasswordHeading => 'Set New Password';

  @override
  String get setNewPasswordSubtitle => 'Choose a strong password for your account';

  @override
  String get studentData => 'Student Data';

  @override
  String get studentDataOverview => 'Student Data Overview';

  @override
  String get totalAnnouncements => 'Total Announcements';

  @override
  String get verifyCode => 'Verify Code';

  @override
  String optionLabel(String letter) {
    return 'Option $letter';
  }

  @override
  String get watchAndLearn => 'Watch & learn';

  @override
  String get networkPractice => 'Network practice';

  @override
  String get accountSettings => 'Account & settings';

  @override
  String get noVideoAvailable => 'No video available yet.';

  @override
  String videoListSubtitle(int count) {
    return '$count modules · Choose a video to start learning';
  }

  @override
  String get videoListWatchVideo => 'View learning video';

  @override
  String get noVideoAvailableMessage => 'No learning videos have been published yet.';

  @override
  String get downloadCsv => 'Download CSV';

  @override
  String get csvExported => 'CSV downloaded successfully.';

  @override
  String get csvFailed => 'Failed to export CSV. Please try again.';

  @override
  String get videoLinkAvailable => 'Video link available';

  @override
  String get videoLinkUnavailable => 'Video not available yet';

  @override
  String get splashTagline => 'LEARN. CONNECT. GROW.';

  @override
  String get splashOpening => 'Opening the application';

  @override
  String get onboardingJourneyLabel => 'Your networking journey';

  @override
  String get onboardingPageNumberSuffix => ' / 03';

  @override
  String get onboardingIntroTitle => 'Learn Networking, Connect Everything.';

  @override
  String get onboardingIntroBody => 'Build your understanding of computer networks through guided materials, learning videos, and assessments.';

  @override
  String get onboardingModulesTitle => 'Understand the Fundamentals.';

  @override
  String get onboardingModulesBody => 'Explore the core concepts of computer networking, one step at a time.';

  @override
  String get onboardingPracticeTitle => 'Turn Knowledge into Practice.';

  @override
  String get onboardingPracticeBody => 'Study materials, watch learning videos, complete assessments, and review your results.';

  @override
  String get onboardingPersistFailed => 'Could not save your onboarding status. It may appear again on your next sign-in.';

  @override
  String get onboardingModuleFundamentals => 'Computer Networking Fundamentals';

  @override
  String get onboardingModuleDevices => 'Network Devices';

  @override
  String get onboardingModuleTopologies => 'Network Topologies';

  @override
  String get onboardingModuleIpAddress => 'IP Address';

  @override
  String get journeyStudyTitle => 'Study Materials';

  @override
  String get journeyStudySubtitle => 'Build your foundation';

  @override
  String get journeyVideosTitle => 'Watch Videos';

  @override
  String get journeyVideosSubtitle => 'See concepts in action';

  @override
  String get journeyAssessmentsTitle => 'Take Assessments';

  @override
  String get journeyAssessmentsSubtitle => 'Check your understanding';

  @override
  String get journeyReviewTitle => 'Review Results';

  @override
  String get journeyReviewSubtitle => 'Reflect on your learning';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingGetStarted => 'Get Started';

  @override
  String get onboardingProgressLabel => 'Onboarding progress';

  @override
  String get onboardingSceneStudentLabel => 'A student exploring a computer network from a laptop, connected to a router and a desktop computer';

  @override
  String get onboardingSceneNetworkLabel => 'Computers connected through a router with Ethernet ports';

  @override
  String get manageClassesTitle => 'Manage Class';

  @override
  String get manageClassesSubtitle => 'Create, configure, and manage your classes and modules.';

  @override
  String get createClassTitle => 'Create Class';

  @override
  String get switchClassAction => 'Switch Class';

  @override
  String get archivedClassesTitle => 'Archived Classes';

  @override
  String get noClassesLecturerTitle => 'No active classes yet';

  @override
  String get noClassesLecturerMessage => 'Create your first class from the NetLearn template or start a custom class from scratch.';

  @override
  String get classStatusDraft => 'Draft';

  @override
  String get classStatusPublished => 'Published';

  @override
  String get classStatusArchived => 'Archived';

  @override
  String get classOriginTemplate => 'NetLearn Template';

  @override
  String get classOriginCustom => 'Custom Class';

  @override
  String classMembersCount(int count) {
    return '$count students';
  }

  @override
  String classModulesCount(int count) {
    return '$count modules';
  }

  @override
  String get classInviteCodeLabel => 'Invite Code';

  @override
  String get classInviteCodeCopied => 'Invite code copied to clipboard.';

  @override
  String get classManageButton => 'Manage';

  @override
  String get classNameLabel => 'Class Name';

  @override
  String get classNameHint => 'e.g. Computer Networks — Class A';

  @override
  String get classNameRequired => 'Class name is required';

  @override
  String get classDescriptionLabel => 'Class Description';

  @override
  String get classDescriptionHint => 'Short summary of class goals or schedule';

  @override
  String get classSemesterLabel => 'Semester / Academic Period';

  @override
  String get classSemesterHint => 'e.g. Odd 2026/2027';

  @override
  String get classCreationModeTitle => 'Class Structure Source';

  @override
  String get classUseTemplateTitle => 'Use NetLearn Template';

  @override
  String get classUseTemplateSubtitle => 'Copies the 4 core modules, 5 materials, Pretest, and Posttest into your class.';

  @override
  String get classCreateCustomTitle => 'Create Custom Class';

  @override
  String get classCreateCustomSubtitle => 'Start with an empty class and build your own modules, materials, and assessments.';

  @override
  String get classPretestEnabledLabel => 'Enable Pretest Gate';

  @override
  String get classPretestEnabledHelper => 'Students must submit the Pretest before unlocking Module 1.';

  @override
  String get classPosttestEnabledLabel => 'Enable Posttest Evaluation';

  @override
  String get classPosttestEnabledHelper => 'Unlocks the final Posttest after all published modules are completed.';

  @override
  String get classLeaderboardEnabledLabel => 'Enable Class Leaderboard';

  @override
  String get classLeaderboardEnabledHelper => 'Shows ranked assessment and overall class standings to enrolled students.';

  @override
  String get classCreatedSuccess => 'Class created successfully.';

  @override
  String get classUpdatedSuccess => 'Class settings updated.';

  @override
  String get classPublishAction => 'Publish Class';

  @override
  String get classArchiveAction => 'Archive Class';

  @override
  String get classRestoreAction => 'Restore to Draft';

  @override
  String get classTabModules => 'Modules';

  @override
  String get classTabSettings => 'Settings & Gates';

  @override
  String get classTabInviteRoster => 'Invite & Roster';

  @override
  String get classTabLeaderboard => 'Leaderboard';

  @override
  String get classAddModuleAction => 'Add Module';

  @override
  String get classEditModuleAction => 'Edit Module';

  @override
  String get classModuleTitleIdLabel => 'Module Title (Indonesian)';

  @override
  String get classModuleTitleEnLabel => 'Module Title (English)';

  @override
  String get classModuleDescIdLabel => 'Description (Indonesian)';

  @override
  String get classModuleDescEnLabel => 'Description (English)';

  @override
  String get classNoModulesEmpty => 'No modules in this class yet. Add your first module to begin.';

  @override
  String get classAddMaterialToModule => 'Add Material';

  @override
  String get classRotateInviteAction => 'Rotate Code';

  @override
  String get classInviteActiveLabel => 'Allow Joining via Invite Code';

  @override
  String get classRosterEmpty => 'No students have joined this class yet.';

  @override
  String get classRemoveMemberTitle => 'Remove Student from Class?';

  @override
  String get classRemoveMemberConfirm => 'Their historical progress and attempt records will be preserved.';

  @override
  String get classRemoveMemberAction => 'Remove';

  @override
  String get classPolicyChangeTitle => 'Update Class Gate Policy?';

  @override
  String get classPolicyChangeConfirm => 'Changing Pretest, Posttest, or Leaderboard settings increments the class policy version. Students who already unlocked modules keep their unlocked status.';

  @override
  String get studentMyClassesTitle => 'My Classes';

  @override
  String get studentActiveClassLabel => 'Active Class';

  @override
  String get studentJoinClassAction => 'Join Class';

  @override
  String get studentJoinClassHint => 'Enter 8-character invite code';

  @override
  String get studentJoinClassSuccess => 'Successfully joined the class!';

  @override
  String get studentNoClassTitle => 'Join a Class to Start Learning';

  @override
  String get studentNoClassMessage => 'Ask your lecturer for an 8-character class invite code to unlock your modules, materials, and assessments.';

  @override
  String get studentLeaveClassAction => 'Leave Class';

  @override
  String get studentLeaveClassConfirm => 'Are you sure you want to leave this class? Your historical progress will stay saved if you rejoin later.';

  @override
  String get classEmptyMaterialsMessage => 'Your lecturer is still preparing the learning modules for this class.';

  @override
  String get leaderboardTitle => 'Class Leaderboard';

  @override
  String get leaderboardOverallTab => 'Overall Class';

  @override
  String get leaderboardAssessmentTab => 'Per Assessment';

  @override
  String get leaderboardCohortFinal => 'Final (Completed All)';

  @override
  String get leaderboardCohortProvisional => 'In Progress (Provisional)';

  @override
  String get leaderboardEmptyTitle => 'No ranked assessments yet';

  @override
  String get leaderboardEmptyMessage => 'Rankings will appear once students submit graded assessments in this class.';

  @override
  String get leaderboardFormulaNote => 'Normalized 0–100 score · Highest valid attempt · Pretest excluded by default · Ties broken by earliest submission.';

  @override
  String get leaderboardYouBadge => 'You';

  @override
  String get couldNotLoadData => 'Could not load data.';

  @override
  String get confirm => 'Confirm';

  @override
  String get onboardingSceneJourneyLabel => 'A laptop, assessment sheets, and result charts connected in one learning journey';
}
