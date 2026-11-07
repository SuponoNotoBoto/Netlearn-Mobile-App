import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_id.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('id')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'NetLearn'**
  String get appName;

  /// No description provided for @appDescription.
  ///
  /// In en, this message translates to:
  /// **'AR Computer Network Learning Application'**
  String get appDescription;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @materials.
  ///
  /// In en, this message translates to:
  /// **'Materials'**
  String get materials;

  /// No description provided for @arScanner.
  ///
  /// In en, this message translates to:
  /// **'AR Scanner'**
  String get arScanner;

  /// No description provided for @quizzes.
  ///
  /// In en, this message translates to:
  /// **'Quizzes'**
  String get quizzes;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @previous.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previous;

  /// No description provided for @continueText.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueText;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get retry;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get loading;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// No description provided for @hello.
  ///
  /// In en, this message translates to:
  /// **'Hello'**
  String get hello;

  /// No description provided for @student.
  ///
  /// In en, this message translates to:
  /// **'Student'**
  String get student;

  /// No description provided for @lecturer.
  ///
  /// In en, this message translates to:
  /// **'Lecturer'**
  String get lecturer;

  /// No description provided for @studentDashboard.
  ///
  /// In en, this message translates to:
  /// **'Student Dashboard'**
  String get studentDashboard;

  /// No description provided for @lecturerDashboard.
  ///
  /// In en, this message translates to:
  /// **'Lecturer Dashboard'**
  String get lecturerDashboard;

  /// No description provided for @learningMaterials.
  ///
  /// In en, this message translates to:
  /// **'Learning Materials'**
  String get learningMaterials;

  /// No description provided for @learningModule.
  ///
  /// In en, this message translates to:
  /// **'Learning Module'**
  String get learningModule;

  /// No description provided for @module.
  ///
  /// In en, this message translates to:
  /// **'Module'**
  String get module;

  /// No description provided for @modules.
  ///
  /// In en, this message translates to:
  /// **'Modules'**
  String get modules;

  /// No description provided for @moduleList.
  ///
  /// In en, this message translates to:
  /// **'Module List'**
  String get moduleList;

  /// No description provided for @computerNetworks.
  ///
  /// In en, this message translates to:
  /// **'Computer Networks'**
  String get computerNetworks;

  /// No description provided for @learningProgress.
  ///
  /// In en, this message translates to:
  /// **'Learning Progress'**
  String get learningProgress;

  /// No description provided for @weeklyProgress.
  ///
  /// In en, this message translates to:
  /// **'Weekly Progress'**
  String get weeklyProgress;

  /// No description provided for @upcomingTasks.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Tasks'**
  String get upcomingTasks;

  /// No description provided for @noUpcomingTasks.
  ///
  /// In en, this message translates to:
  /// **'No upcoming tasks'**
  String get noUpcomingTasks;

  /// No description provided for @noUpcomingTasksDescription.
  ///
  /// In en, this message translates to:
  /// **'Tasks with deadlines will appear here.'**
  String get noUpcomingTasksDescription;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No description provided for @deadline.
  ///
  /// In en, this message translates to:
  /// **'Deadline'**
  String get deadline;

  /// No description provided for @duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// No description provided for @minutes.
  ///
  /// In en, this message translates to:
  /// **'minutes'**
  String get minutes;

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get available;

  /// No description provided for @locked.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get locked;

  /// No description provided for @unlocked.
  ///
  /// In en, this message translates to:
  /// **'Unlocked'**
  String get unlocked;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @inProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get inProgress;

  /// No description provided for @notStarted.
  ///
  /// In en, this message translates to:
  /// **'Not Started'**
  String get notStarted;

  /// No description provided for @readingMaterial.
  ///
  /// In en, this message translates to:
  /// **'Reading Material'**
  String get readingMaterial;

  /// No description provided for @reading.
  ///
  /// In en, this message translates to:
  /// **'Reading'**
  String get reading;

  /// No description provided for @video.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get video;

  /// No description provided for @learningVideo.
  ///
  /// In en, this message translates to:
  /// **'Learning Video'**
  String get learningVideo;

  /// No description provided for @videoLearning.
  ///
  /// In en, this message translates to:
  /// **'Learning Video'**
  String get videoLearning;

  /// No description provided for @markAsCompleted.
  ///
  /// In en, this message translates to:
  /// **'Mark as Completed'**
  String get markAsCompleted;

  /// Label of the reading completion action in the material reader. The PRD calls the student-facing action "Mark as Read"; the RPC behind it is still mark_reading_completed, so only the wording changed.
  ///
  /// In en, this message translates to:
  /// **'Mark as Read'**
  String get markAsRead;

  /// No description provided for @readLabel.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get readLabel;

  /// No description provided for @overallProgress.
  ///
  /// In en, this message translates to:
  /// **'Overall progress'**
  String get overallProgress;

  /// Number of materials inside a module, e.g. "4 materials".
  ///
  /// In en, this message translates to:
  /// **'{count} materials'**
  String materialsCount(int count);

  /// Small eyebrow above a module card, e.g. "Module 1". Callers that want the padded "01" form pass the already-padded string, so the pattern here is a plain number.
  ///
  /// In en, this message translates to:
  /// **'Module {number}'**
  String moduleEyebrow(Object number);

  /// Small label painted inside the IP-address material thumbnail illustration. Kept as an actual localizable value instead of a constant because the Figma design switches it by language (CONTOH IP in Indonesian).
  ///
  /// In en, this message translates to:
  /// **'EXAMPLE IP'**
  String get materialArtExampleIp;

  /// No description provided for @readingProgressLabel.
  ///
  /// In en, this message translates to:
  /// **'Reading progress'**
  String get readingProgressLabel;

  /// No description provided for @downloadPdf.
  ///
  /// In en, this message translates to:
  /// **'Download PDF'**
  String get downloadPdf;

  /// No description provided for @nextVideo.
  ///
  /// In en, this message translates to:
  /// **'Next: Video'**
  String get nextVideo;

  /// No description provided for @nextQuiz.
  ///
  /// In en, this message translates to:
  /// **'Next: Quiz'**
  String get nextQuiz;

  /// No description provided for @evaluation.
  ///
  /// In en, this message translates to:
  /// **'Evaluation'**
  String get evaluation;

  /// No description provided for @quizList.
  ///
  /// In en, this message translates to:
  /// **'Quiz List'**
  String get quizList;

  /// No description provided for @startQuiz.
  ///
  /// In en, this message translates to:
  /// **'Start Quiz'**
  String get startQuiz;

  /// No description provided for @resumeQuiz.
  ///
  /// In en, this message translates to:
  /// **'Resume Quiz'**
  String get resumeQuiz;

  /// No description provided for @submitAnswer.
  ///
  /// In en, this message translates to:
  /// **'Submit Answer'**
  String get submitAnswer;

  /// No description provided for @submitQuiz.
  ///
  /// In en, this message translates to:
  /// **'Submit Quiz'**
  String get submitQuiz;

  /// No description provided for @question.
  ///
  /// In en, this message translates to:
  /// **'Question'**
  String get question;

  /// No description provided for @questions.
  ///
  /// In en, this message translates to:
  /// **'Questions'**
  String get questions;

  /// No description provided for @fromTotal.
  ///
  /// In en, this message translates to:
  /// **'of'**
  String get fromTotal;

  /// No description provided for @timeRemaining.
  ///
  /// In en, this message translates to:
  /// **'Time Remaining'**
  String get timeRemaining;

  /// No description provided for @quizCompleted.
  ///
  /// In en, this message translates to:
  /// **'Quiz Completed'**
  String get quizCompleted;

  /// No description provided for @score.
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get score;

  /// No description provided for @correct.
  ///
  /// In en, this message translates to:
  /// **'Correct'**
  String get correct;

  /// No description provided for @wrong.
  ///
  /// In en, this message translates to:
  /// **'Wrong'**
  String get wrong;

  /// No description provided for @passed.
  ///
  /// In en, this message translates to:
  /// **'Passed'**
  String get passed;

  /// No description provided for @failed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get failed;

  /// No description provided for @returnDashboard.
  ///
  /// In en, this message translates to:
  /// **'Return to Dashboard'**
  String get returnDashboard;

  /// No description provided for @backToQuizList.
  ///
  /// In en, this message translates to:
  /// **'Back to Quiz List'**
  String get backToQuizList;

  /// No description provided for @academicInformation.
  ///
  /// In en, this message translates to:
  /// **'Academic Information'**
  String get academicInformation;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @identityNumber.
  ///
  /// In en, this message translates to:
  /// **'Identity Number'**
  String get identityNumber;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @program.
  ///
  /// In en, this message translates to:
  /// **'Program'**
  String get program;

  /// No description provided for @accountStatus.
  ///
  /// In en, this message translates to:
  /// **'Account Status'**
  String get accountStatus;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @inactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inactive;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @indonesian.
  ///
  /// In en, this message translates to:
  /// **'Indonesian'**
  String get indonesian;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageIndonesian.
  ///
  /// In en, this message translates to:
  /// **'Indonesian'**
  String get languageIndonesian;

  /// No description provided for @logoutConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out?'**
  String get logoutConfirmation;

  /// No description provided for @yesLogout.
  ///
  /// In en, this message translates to:
  /// **'Yes, Log Out'**
  String get yesLogout;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong.'**
  String get somethingWentWrong;

  /// No description provided for @pageNotFound.
  ///
  /// In en, this message translates to:
  /// **'Page not found.'**
  String get pageNotFound;

  /// No description provided for @failedToLoad.
  ///
  /// In en, this message translates to:
  /// **'Failed to load data.'**
  String get failedToLoad;

  /// No description provided for @sessionNotFound.
  ///
  /// In en, this message translates to:
  /// **'Session not found.'**
  String get sessionNotFound;

  /// No description provided for @profileNotFound.
  ///
  /// In en, this message translates to:
  /// **'Profile not found.'**
  String get profileNotFound;

  /// No description provided for @arComingSoon.
  ///
  /// In en, this message translates to:
  /// **'AR Scanner is coming soon.'**
  String get arComingSoon;

  /// No description provided for @arScannerTitle.
  ///
  /// In en, this message translates to:
  /// **'AR Scanner'**
  String get arScannerTitle;

  /// No description provided for @arStatusInitializing.
  ///
  /// In en, this message translates to:
  /// **'Preparing the AR camera…'**
  String get arStatusInitializing;

  /// No description provided for @arStatusSearching.
  ///
  /// In en, this message translates to:
  /// **'Point the camera at one of the NetLearn markers.'**
  String get arStatusSearching;

  /// No description provided for @arMarkerDetected.
  ///
  /// In en, this message translates to:
  /// **'Marker recognized'**
  String get arMarkerDetected;

  /// No description provided for @arScanPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Camera permission is required to scan markers. Enable camera access and try again.'**
  String get arScanPermissionDenied;

  /// No description provided for @arInitFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not start the AR camera. Your device may not support ARCore.'**
  String get arInitFailed;

  /// No description provided for @arRescanTooltip.
  ///
  /// In en, this message translates to:
  /// **'Rescan'**
  String get arRescanTooltip;

  /// No description provided for @arHelpTooltip.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get arHelpTooltip;

  /// No description provided for @arHelpTitle.
  ///
  /// In en, this message translates to:
  /// **'How to scan a marker'**
  String get arHelpTitle;

  /// No description provided for @arHelpBody.
  ///
  /// In en, this message translates to:
  /// **'1. Print the NetLearn marker cards.\n2. Place a card on a flat surface.\n3. Point the camera at the whole card.\n4. Hold steady until the object information appears.'**
  String get arHelpBody;

  /// Badge shown on the object information card, e.g. "Module 2".
  ///
  /// In en, this message translates to:
  /// **'Module {number}'**
  String arModuleBadge(int number);

  /// No description provided for @arObjKomputerName.
  ///
  /// In en, this message translates to:
  /// **'Desktop Computer'**
  String get arObjKomputerName;

  /// No description provided for @arObjKomputerDesc.
  ///
  /// In en, this message translates to:
  /// **'An end device that sends and receives data over the network.'**
  String get arObjKomputerDesc;

  /// No description provided for @arObjSwitchName.
  ///
  /// In en, this message translates to:
  /// **'Switch'**
  String get arObjSwitchName;

  /// No description provided for @arObjSwitchDesc.
  ///
  /// In en, this message translates to:
  /// **'Connects devices in a local network and forwards frames to the destination port using MAC addresses.'**
  String get arObjSwitchDesc;

  /// No description provided for @arObjHubName.
  ///
  /// In en, this message translates to:
  /// **'Hub'**
  String get arObjHubName;

  /// No description provided for @arObjHubDesc.
  ///
  /// In en, this message translates to:
  /// **'Connects devices and repeats incoming data to every connected port, unlike a switch that forwards only to the target device.'**
  String get arObjHubDesc;

  /// No description provided for @arObjRouterName.
  ///
  /// In en, this message translates to:
  /// **'Router'**
  String get arObjRouterName;

  /// No description provided for @arObjRouterDesc.
  ///
  /// In en, this message translates to:
  /// **'Connects different networks and forwards packets between them using IP addresses and a routing table.'**
  String get arObjRouterDesc;

  /// No description provided for @arObjTopologiName.
  ///
  /// In en, this message translates to:
  /// **'Star Topology'**
  String get arObjTopologiName;

  /// No description provided for @arObjTopologiDesc.
  ///
  /// In en, this message translates to:
  /// **'A topology where every device connects to a central switch. The central device is critical: if it fails, the whole network is affected.'**
  String get arObjTopologiDesc;

  /// No description provided for @arObjIpAddressName.
  ///
  /// In en, this message translates to:
  /// **'IP Address Simulation'**
  String get arObjIpAddressName;

  /// No description provided for @arObjIpAddressDesc.
  ///
  /// In en, this message translates to:
  /// **'Configure the IPv4 address and subnet mask of two computers connected through one switch.'**
  String get arObjIpAddressDesc;

  /// No description provided for @arDetailHeaderLabel.
  ///
  /// In en, this message translates to:
  /// **'Detailed Information'**
  String get arDetailHeaderLabel;

  /// No description provided for @arDetailSectionDefinition.
  ///
  /// In en, this message translates to:
  /// **'Definition'**
  String get arDetailSectionDefinition;

  /// No description provided for @arDetailSectionFunction.
  ///
  /// In en, this message translates to:
  /// **'Function'**
  String get arDetailSectionFunction;

  /// No description provided for @arDetailExtraKomputer.
  ///
  /// In en, this message translates to:
  /// **'Example Activities'**
  String get arDetailExtraKomputer;

  /// No description provided for @arDetailExtraSwitch.
  ///
  /// In en, this message translates to:
  /// **'How It Works'**
  String get arDetailExtraSwitch;

  /// No description provided for @arDetailExtraHub.
  ///
  /// In en, this message translates to:
  /// **'Difference from a Switch'**
  String get arDetailExtraHub;

  /// No description provided for @arDetailExtraRouter.
  ///
  /// In en, this message translates to:
  /// **'How It Works'**
  String get arDetailExtraRouter;

  /// No description provided for @arDetailExtraTopologi.
  ///
  /// In en, this message translates to:
  /// **'Advantages and Limitations'**
  String get arDetailExtraTopologi;

  /// No description provided for @arDetailOpenButton.
  ///
  /// In en, this message translates to:
  /// **'View Full Information'**
  String get arDetailOpenButton;

  /// No description provided for @arNarrationMute.
  ///
  /// In en, this message translates to:
  /// **'Turn off narration'**
  String get arNarrationMute;

  /// No description provided for @arNarrationReplay.
  ///
  /// In en, this message translates to:
  /// **'Listen again'**
  String get arNarrationReplay;

  /// No description provided for @arNarrationUnmute.
  ///
  /// In en, this message translates to:
  /// **'Turn on narration'**
  String get arNarrationUnmute;

  /// No description provided for @arObjKomputerDetailDef.
  ///
  /// In en, this message translates to:
  /// **'A computer is an end device that users use to send and receive data over a network.'**
  String get arObjKomputerDetailDef;

  /// No description provided for @arObjKomputerDetailFunction.
  ///
  /// In en, this message translates to:
  /// **'In a network, the computer is a source or destination of data: it creates requests, sends data to other devices, and receives data from them.'**
  String get arObjKomputerDetailFunction;

  /// No description provided for @arObjKomputerDetailExtra.
  ///
  /// In en, this message translates to:
  /// **'Examples of computer activity in a network: opening web pages, sending email, uploading files, and streaming video. All of these are essentially processes of sending and receiving data.'**
  String get arObjKomputerDetailExtra;

  /// No description provided for @arObjSwitchDetailDef.
  ///
  /// In en, this message translates to:
  /// **'A network device that connects many devices within a single local area network (LAN).'**
  String get arObjSwitchDetailDef;

  /// No description provided for @arObjSwitchDetailFunction.
  ///
  /// In en, this message translates to:
  /// **'The switch connects devices in a local network and forwards data only to the destination device, so network traffic stays more efficient than with a hub.'**
  String get arObjSwitchDetailFunction;

  /// No description provided for @arObjSwitchDetailExtra.
  ///
  /// In en, this message translates to:
  /// **'How it works: the switch reads the destination MAC address on each frame and forwards it to the port connected to the destination device using its MAC table.'**
  String get arObjSwitchDetailExtra;

  /// No description provided for @arObjHubDetailDef.
  ///
  /// In en, this message translates to:
  /// **'A simple network device that connects several devices within one network.'**
  String get arObjHubDetailDef;

  /// No description provided for @arObjHubDetailFunction.
  ///
  /// In en, this message translates to:
  /// **'The hub connects devices and forwards incoming data to every connected port, without knowing which device is the destination.'**
  String get arObjHubDetailFunction;

  /// No description provided for @arObjHubDetailExtra.
  ///
  /// In en, this message translates to:
  /// **'Difference from a switch: the hub broadcasts data to all devices, while the switch forwards data only to the destination device based on the MAC address. Hubs are therefore less efficient and more prone to collisions.'**
  String get arObjHubDetailExtra;

  /// No description provided for @arObjRouterDetailDef.
  ///
  /// In en, this message translates to:
  /// **'A network device that connects two or more different networks.'**
  String get arObjRouterDetailDef;

  /// No description provided for @arObjRouterDetailFunction.
  ///
  /// In en, this message translates to:
  /// **'The router forwards data packets between networks, choosing the best path toward the destination network.'**
  String get arObjRouterDetailFunction;

  /// No description provided for @arObjRouterDetailExtra.
  ///
  /// In en, this message translates to:
  /// **'How it works: the router reads the destination IP address on the packet and decides the forwarding path using its routing table. Routers let devices from different networks communicate, for example between a home LAN and the internet.'**
  String get arObjRouterDetailExtra;

  /// No description provided for @arObjTopologiDetailDef.
  ///
  /// In en, this message translates to:
  /// **'A network layout in which every device connects directly to a single central device, usually a switch or hub.'**
  String get arObjTopologiDetailDef;

  /// No description provided for @arObjTopologiDetailFunction.
  ///
  /// In en, this message translates to:
  /// **'The central device acts as the shared connection point: all data between devices passes through it before being forwarded to its destination.'**
  String get arObjTopologiDetailFunction;

  /// No description provided for @arObjTopologiDetailExtra.
  ///
  /// In en, this message translates to:
  /// **'Advantages: easy to add devices and easy to detect a faulty cable. Limitation: if the central device fails, the whole network stops working (single point of failure).'**
  String get arObjTopologiDetailExtra;

  /// No description provided for @arIpComputerA.
  ///
  /// In en, this message translates to:
  /// **'Computer A'**
  String get arIpComputerA;

  /// No description provided for @arIpComputerB.
  ///
  /// In en, this message translates to:
  /// **'Computer B'**
  String get arIpComputerB;

  /// No description provided for @arIpSwitch.
  ///
  /// In en, this message translates to:
  /// **'Switch'**
  String get arIpSwitch;

  /// No description provided for @arIpAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'IP Address'**
  String get arIpAddressLabel;

  /// No description provided for @arIpSubnetLabel.
  ///
  /// In en, this message translates to:
  /// **'Subnet Mask'**
  String get arIpSubnetLabel;

  /// No description provided for @arIpTestButton.
  ///
  /// In en, this message translates to:
  /// **'Test Connection'**
  String get arIpTestButton;

  /// No description provided for @arIpResetButton.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get arIpResetButton;

  /// No description provided for @arIpInitialHint.
  ///
  /// In en, this message translates to:
  /// **'Enter each computer\'s IPv4 address and subnet mask, then test the connection.'**
  String get arIpInitialHint;

  /// No description provided for @arIpSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Connection Succeeded'**
  String get arIpSuccessTitle;

  /// Shown after a successful Modul 4 connectivity test.
  ///
  /// In en, this message translates to:
  /// **'Both computers are in the same subnet ({network}).'**
  String arIpSuccessReason(String network);

  /// No description provided for @arIpFailureTitle.
  ///
  /// In en, this message translates to:
  /// **'Connection Failed'**
  String get arIpFailureTitle;

  /// No description provided for @arIpErrInvalidIpA.
  ///
  /// In en, this message translates to:
  /// **'Computer A\'s IP address is not a valid IPv4 address.'**
  String get arIpErrInvalidIpA;

  /// No description provided for @arIpErrInvalidMaskA.
  ///
  /// In en, this message translates to:
  /// **'Computer A\'s subnet mask is not valid.'**
  String get arIpErrInvalidMaskA;

  /// No description provided for @arIpErrUnusableHostA.
  ///
  /// In en, this message translates to:
  /// **'Computer A\'s address cannot be used as a host address.'**
  String get arIpErrUnusableHostA;

  /// No description provided for @arIpErrInvalidIpB.
  ///
  /// In en, this message translates to:
  /// **'Computer B\'s IP address is not a valid IPv4 address.'**
  String get arIpErrInvalidIpB;

  /// No description provided for @arIpErrInvalidMaskB.
  ///
  /// In en, this message translates to:
  /// **'Computer B\'s subnet mask is not valid.'**
  String get arIpErrInvalidMaskB;

  /// No description provided for @arIpErrUnusableHostB.
  ///
  /// In en, this message translates to:
  /// **'Computer B\'s address cannot be used as a host address.'**
  String get arIpErrUnusableHostB;

  /// No description provided for @arIpErrDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Both computers use the same IP address.'**
  String get arIpErrDuplicate;

  /// No description provided for @arIpErrDifferentSubnet.
  ///
  /// In en, this message translates to:
  /// **'The computers are in different subnets, so they cannot communicate through the switch without routing.'**
  String get arIpErrDifferentSubnet;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to NetLearn!'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in using your personal email, institutional email, or student ID.'**
  String get loginSubtitle;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBack;

  /// No description provided for @emailOrStudentId.
  ///
  /// In en, this message translates to:
  /// **'Email or Student ID'**
  String get emailOrStudentId;

  /// No description provided for @enterEmailOrStudentId.
  ///
  /// In en, this message translates to:
  /// **'Enter your NIM or Email'**
  String get enterEmailOrStudentId;

  /// No description provided for @emailOrLecturerId.
  ///
  /// In en, this message translates to:
  /// **'Email or Lecturer ID'**
  String get emailOrLecturerId;

  /// No description provided for @enterEmailOrLecturerId.
  ///
  /// In en, this message translates to:
  /// **'Enter your NIP or Email'**
  String get enterEmailOrLecturerId;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @loginAsStudent.
  ///
  /// In en, this message translates to:
  /// **'Login as Student'**
  String get loginAsStudent;

  /// No description provided for @loginAsLecturer.
  ///
  /// In en, this message translates to:
  /// **'Login as Lecturer'**
  String get loginAsLecturer;

  /// No description provided for @loginAsAdmin.
  ///
  /// In en, this message translates to:
  /// **'Login as Admin'**
  String get loginAsAdmin;

  /// No description provided for @studentId.
  ///
  /// In en, this message translates to:
  /// **'Student ID'**
  String get studentId;

  /// No description provided for @lecturerId.
  ///
  /// In en, this message translates to:
  /// **'Lecturer ID'**
  String get lecturerId;

  /// No description provided for @enterStudentId.
  ///
  /// In en, this message translates to:
  /// **'Enter your student ID'**
  String get enterStudentId;

  /// No description provided for @enterLecturerId.
  ///
  /// In en, this message translates to:
  /// **'Enter your lecturer ID'**
  String get enterLecturerId;

  /// No description provided for @enterEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get enterEmail;

  /// No description provided for @enterPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get enterPassword;

  /// No description provided for @invalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Invalid credentials.'**
  String get invalidCredentials;

  /// No description provided for @accountInactive.
  ///
  /// In en, this message translates to:
  /// **'Your account is inactive.'**
  String get accountInactive;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password'**
  String get forgotPasswordTitle;

  /// No description provided for @forgotPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the registered email address to receive a password reset code.'**
  String get forgotPasswordSubtitle;

  /// No description provided for @sendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send Reset Link'**
  String get sendResetLink;

  /// No description provided for @resetPasswordHeading.
  ///
  /// In en, this message translates to:
  /// **'Reset\nPassword'**
  String get resetPasswordHeading;

  /// No description provided for @backToLogin.
  ///
  /// In en, this message translates to:
  /// **'Back to Login'**
  String get backToLogin;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get requiredField;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get invalidEmail;

  /// No description provided for @emailSent.
  ///
  /// In en, this message translates to:
  /// **'Email Sent'**
  String get emailSent;

  /// No description provided for @passwordResetEmailSent.
  ///
  /// In en, this message translates to:
  /// **'If the email is registered, a password reset link has been sent. Check your inbox.'**
  String get passwordResetEmailSent;

  /// No description provided for @registerTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get registerTitle;

  /// No description provided for @registerHeading.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get registerHeading;

  /// No description provided for @registerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create an account to start learning with NetLearn.'**
  String get registerSubtitle;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @enterFullName.
  ///
  /// In en, this message translates to:
  /// **'Enter your full name'**
  String get enterFullName;

  /// No description provided for @studentIdOrEmployeeId.
  ///
  /// In en, this message translates to:
  /// **'Student ID / Employee ID'**
  String get studentIdOrEmployeeId;

  /// No description provided for @enterStudentOrEmployeeId.
  ///
  /// In en, this message translates to:
  /// **'Enter your Student ID'**
  String get enterStudentOrEmployeeId;

  /// No description provided for @userEmail.
  ///
  /// In en, this message translates to:
  /// **'User Email'**
  String get userEmail;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @confirmPasswordPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Confirm your password'**
  String get confirmPasswordPlaceholder;

  /// No description provided for @passwordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Password confirmation does not match.'**
  String get passwordMismatch;

  /// No description provided for @passwordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get passwordMinLength;

  /// No description provided for @authIdentifierRequired.
  ///
  /// In en, this message translates to:
  /// **'NIM or Email is required.'**
  String get authIdentifierRequired;

  /// No description provided for @authPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required.'**
  String get authPasswordRequired;

  /// No description provided for @fullNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Full name is required.'**
  String get fullNameRequired;

  /// No description provided for @studentIdRequired.
  ///
  /// In en, this message translates to:
  /// **'Student ID is required.'**
  String get studentIdRequired;

  /// No description provided for @emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required.'**
  String get emailRequired;

  /// No description provided for @confirmPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password confirmation is required.'**
  String get confirmPasswordRequired;

  /// No description provided for @bannerConnectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Connection problem. Check your internet and try again.'**
  String get bannerConnectionFailed;

  /// No description provided for @bannerServerProblem.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong on the server. Please try again.'**
  String get bannerServerProblem;

  /// No description provided for @bannerUnknownError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get bannerUnknownError;

  /// No description provided for @resetRequestSent.
  ///
  /// In en, this message translates to:
  /// **'Password reset instructions were requested. Check your email.'**
  String get resetRequestSent;

  /// No description provided for @registerSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Registration Successful'**
  String get registerSuccessTitle;

  /// No description provided for @registerSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'We\'ve sent a confirmation link to your email. Check your inbox and spam folder, confirm it, then sign in with your new account.'**
  String get registerSuccessMessage;

  /// No description provided for @registerSuccessLoginPrompt.
  ///
  /// In en, this message translates to:
  /// **'Registration successful. Please sign in with your email and password.'**
  String get registerSuccessLoginPrompt;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Login'**
  String get alreadyHaveAccount;

  /// No description provided for @noAccountYet.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Register'**
  String get noAccountYet;

  /// No description provided for @chooseYourLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose Your Language'**
  String get chooseYourLanguage;

  /// No description provided for @onboardingDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose the language you want to use while learning with NetLearn.'**
  String get onboardingDescription;

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// No description provided for @prototypeMode.
  ///
  /// In en, this message translates to:
  /// **'Prototype mode · Language selection appears after every successful login.'**
  String get prototypeMode;

  /// No description provided for @computerNetworkingLMS.
  ///
  /// In en, this message translates to:
  /// **'Computer Networking LMS'**
  String get computerNetworkingLMS;

  /// No description provided for @unreadNotifications.
  ///
  /// In en, this message translates to:
  /// **'{count} unread notifications'**
  String unreadNotifications(int count);

  /// No description provided for @studentList.
  ///
  /// In en, this message translates to:
  /// **'Student List'**
  String get studentList;

  /// No description provided for @studentScoreSummary.
  ///
  /// In en, this message translates to:
  /// **'Student Score Recap'**
  String get studentScoreSummary;

  /// No description provided for @tasksAwaitingReview.
  ///
  /// In en, this message translates to:
  /// **'{count} tasks awaiting review'**
  String tasksAwaitingReview(int count);

  /// No description provided for @reviewStudentSubmissions.
  ///
  /// In en, this message translates to:
  /// **'Review student submissions'**
  String get reviewStudentSubmissions;

  /// No description provided for @tasksApproachingDeadline.
  ///
  /// In en, this message translates to:
  /// **'{count} tasks approaching their deadline'**
  String tasksApproachingDeadline(int count);

  /// No description provided for @trackActiveTasks.
  ///
  /// In en, this message translates to:
  /// **'Track active tasks'**
  String get trackActiveTasks;

  /// No description provided for @moduleNotPublished.
  ///
  /// In en, this message translates to:
  /// **'Module {number} is not published'**
  String moduleNotPublished(int number);

  /// No description provided for @completeTheMaterial.
  ///
  /// In en, this message translates to:
  /// **'Complete the {title} material'**
  String completeTheMaterial(String title);

  /// No description provided for @viewMaterial.
  ///
  /// In en, this message translates to:
  /// **'View Material'**
  String get viewMaterial;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @registerButton.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get registerButton;

  /// No description provided for @registerLecturerNotice.
  ///
  /// In en, this message translates to:
  /// **'Lecturer accounts are created by the admin. Select Student to register.'**
  String get registerLecturerNotice;

  /// No description provided for @accountManagedBy.
  ///
  /// In en, this message translates to:
  /// **'Account managed by '**
  String get accountManagedBy;

  /// No description provided for @campusAdministrator.
  ///
  /// In en, this message translates to:
  /// **'campus administrator'**
  String get campusAdministrator;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @tomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get tomorrow;

  /// No description provided for @minutesShort.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get minutesShort;

  /// No description provided for @lockedModuleMessage.
  ///
  /// In en, this message translates to:
  /// **'This module is still locked.'**
  String get lockedModuleMessage;

  /// No description provided for @lockedNeedsPretest.
  ///
  /// In en, this message translates to:
  /// **'Complete the Pretest'**
  String get lockedNeedsPretest;

  /// No description provided for @dashboardLoadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load dashboard data.'**
  String get dashboardLoadError;

  /// No description provided for @moduleProgressLoadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load module progress.'**
  String get moduleProgressLoadError;

  /// No description provided for @noModules.
  ///
  /// In en, this message translates to:
  /// **'No modules yet'**
  String get noModules;

  /// No description provided for @noModulesDescription.
  ///
  /// In en, this message translates to:
  /// **'Published modules will appear here.'**
  String get noModulesDescription;

  /// Module number
  ///
  /// In en, this message translates to:
  /// **'{number}'**
  String moduleNumber(Object number);

  /// Question number
  ///
  /// In en, this message translates to:
  /// **'Question {number}'**
  String questionNumber(Object number);

  /// Question progress
  ///
  /// In en, this message translates to:
  /// **'{current} of {total}'**
  String questionsProgress(Object current, Object total);

  /// Duration in minutes
  ///
  /// In en, this message translates to:
  /// **'{minutes} minutes'**
  String durationMinutes(Object minutes);

  /// Progress percentage
  ///
  /// In en, this message translates to:
  /// **'{percentage}%'**
  String progressPercentage(Object percentage);

  /// No description provided for @materialNotFound.
  ///
  /// In en, this message translates to:
  /// **'Material not found.'**
  String get materialNotFound;

  /// No description provided for @learningMaterial.
  ///
  /// In en, this message translates to:
  /// **'Learning Material'**
  String get learningMaterial;

  /// No description provided for @coreMaterial.
  ///
  /// In en, this message translates to:
  /// **'Core'**
  String get coreMaterial;

  /// No description provided for @summary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get summary;

  /// No description provided for @readMaterial.
  ///
  /// In en, this message translates to:
  /// **'Read Material'**
  String get readMaterial;

  /// No description provided for @readMaterialDescription.
  ///
  /// In en, this message translates to:
  /// **'Study the material before continuing to the next stage.'**
  String get readMaterialDescription;

  /// No description provided for @materialContentUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Reading material is not available.'**
  String get materialContentUnavailable;

  /// No description provided for @readingCompletedMessage.
  ///
  /// In en, this message translates to:
  /// **'Reading material completed successfully.'**
  String get readingCompletedMessage;

  /// Message shown when saving learning progress fails.
  ///
  /// In en, this message translates to:
  /// **'Failed to save progress: {error}'**
  String progressSaveFailed(String error);

  /// No description provided for @learningVideoDescription.
  ///
  /// In en, this message translates to:
  /// **'Watch the learning video to strengthen your understanding.'**
  String get learningVideoDescription;

  /// No description provided for @videoUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Video for this material is not available.'**
  String get videoUnavailable;

  /// No description provided for @watched.
  ///
  /// In en, this message translates to:
  /// **'Watched'**
  String get watched;

  /// No description provided for @videoPlayerComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Video player will be available in the next stage.'**
  String get videoPlayerComingSoon;

  /// No description provided for @evaluationDescription.
  ///
  /// In en, this message translates to:
  /// **'Complete the quiz after finishing the learning components.'**
  String get evaluationDescription;

  /// No description provided for @materialLocked.
  ///
  /// In en, this message translates to:
  /// **'Material locked'**
  String get materialLocked;

  /// No description provided for @completePreviousModule.
  ///
  /// In en, this message translates to:
  /// **'Complete the previous module first to unlock this material.'**
  String get completePreviousModule;

  /// No description provided for @readMaterialTitle.
  ///
  /// In en, this message translates to:
  /// **'Read Material'**
  String get readMaterialTitle;

  /// No description provided for @materialIdMissing.
  ///
  /// In en, this message translates to:
  /// **'Material ID not found.'**
  String get materialIdMissing;

  /// No description provided for @videoMaterialIdMissing.
  ///
  /// In en, this message translates to:
  /// **'Video material ID not found.'**
  String get videoMaterialIdMissing;

  /// No description provided for @assessmentTypeMissing.
  ///
  /// In en, this message translates to:
  /// **'Assessment type not found.'**
  String get assessmentTypeMissing;

  /// No description provided for @assessmentTypeInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid assessment type.'**
  String get assessmentTypeInvalid;

  /// No description provided for @assessmentResultIdMissing.
  ///
  /// In en, this message translates to:
  /// **'Assessment result ID not found.'**
  String get assessmentResultIdMissing;

  /// No description provided for @readingProgress.
  ///
  /// In en, this message translates to:
  /// **'Reading progress'**
  String get readingProgress;

  /// No description provided for @videoOptional.
  ///
  /// In en, this message translates to:
  /// **'Supporting Video (Optional)'**
  String get videoOptional;

  /// No description provided for @viewPdf.
  ///
  /// In en, this message translates to:
  /// **'View PDF'**
  String get viewPdf;

  /// Section title for PDF view/download actions in the material reader.
  ///
  /// In en, this message translates to:
  /// **'Material Resources'**
  String get materialResources;

  /// Button to mark all materials in the current module as read.
  ///
  /// In en, this message translates to:
  /// **'Mark All as Read'**
  String get markAllAsRead;

  /// Description for the Mark All as Read button.
  ///
  /// In en, this message translates to:
  /// **'Mark all reading materials in this module as completed.'**
  String get markAllAsReadDescription;

  /// Shown when a material has no associated PDF file.
  ///
  /// In en, this message translates to:
  /// **'No PDF available for this material.'**
  String get noPdfAvailable;

  /// Shown when the in-app PDF viewer fails to open the file; the download button remains the fallback.
  ///
  /// In en, this message translates to:
  /// **'This PDF could not be displayed. Try downloading it.'**
  String get pdfOpenFailed;

  /// Description under the Material Resources title when the material has a PDF.
  ///
  /// In en, this message translates to:
  /// **'This material includes a PDF you can view or download.'**
  String get materialResourcesDescription;

  /// Success message when PDF download completes.
  ///
  /// In en, this message translates to:
  /// **'PDF downloaded successfully.'**
  String get pdfDownloadSuccess;

  /// Error message when PDF download fails.
  ///
  /// In en, this message translates to:
  /// **'Failed to download PDF. Please try again.'**
  String get pdfDownloadFailed;

  /// Section title for video resources in the material reader.
  ///
  /// In en, this message translates to:
  /// **'Video Learning'**
  String get videoLearningSection;

  /// Heading above the assessment list cards.
  ///
  /// In en, this message translates to:
  /// **'Your assessments'**
  String get assessmentListIntroTitle;

  /// Sub-heading above the assessment list cards.
  ///
  /// In en, this message translates to:
  /// **'Measure your understanding, from start to finish.'**
  String get assessmentListIntroSubtitle;

  /// Explains the order of the two core assessments above the list.
  ///
  /// In en, this message translates to:
  /// **'Complete the Pretest before starting the materials. The Post Test becomes available after all modules are completed.'**
  String get assessmentListIntroBody;

  /// No description provided for @assessmentInitialTag.
  ///
  /// In en, this message translates to:
  /// **'Initial assessment'**
  String get assessmentInitialTag;

  /// No description provided for @assessmentFinalTag.
  ///
  /// In en, this message translates to:
  /// **'Final assessment'**
  String get assessmentFinalTag;

  /// No description provided for @startPretest.
  ///
  /// In en, this message translates to:
  /// **'Take the Pretest'**
  String get startPretest;

  /// Button that opens the post test. Distinct from startPostTest, which is "Start Post-test" and is used on the dashboard.
  ///
  /// In en, this message translates to:
  /// **'Start Post Test'**
  String get startPostTestLabel;

  /// Button to open pretest instructions instead of starting directly.
  ///
  /// In en, this message translates to:
  /// **'View Pretest Instructions'**
  String get viewPretestInstructions;

  /// Button to open posttest instructions instead of starting directly.
  ///
  /// In en, this message translates to:
  /// **'View Posttest Instructions'**
  String get viewPosttestInstructions;

  /// Meta line showing question count and duration for an assessment card.
  ///
  /// In en, this message translates to:
  /// **'{count} Questions · {minutes} Minutes'**
  String assignmentMeta(String count, String minutes);

  /// Description for pretest card.
  ///
  /// In en, this message translates to:
  /// **'Check your initial understanding before studying.'**
  String get assessmentInitialDesc;

  /// Description for posttest card.
  ///
  /// In en, this message translates to:
  /// **'Evaluate your understanding after completing all modules.'**
  String get assessmentFinalDesc;

  /// Top bar title for the lecturer assessments page.
  ///
  /// In en, this message translates to:
  /// **'Assessment'**
  String get assignments;

  /// Bottom navigation tab label for assignments (student only).
  ///
  /// In en, this message translates to:
  /// **'Assessment'**
  String get assignmentsTab;

  /// Link at bottom of assessment list to navigate to history page.
  ///
  /// In en, this message translates to:
  /// **'View Assessment History'**
  String get viewAssessmentHistory;

  /// Top bar title on the Pretest instructions page.
  ///
  /// In en, this message translates to:
  /// **'Assessment - Pretest'**
  String get pretestInstructionsTopBar;

  /// All-caps label inside the illustration on the Pretest instructions page.
  ///
  /// In en, this message translates to:
  /// **'KNOW YOUR STARTING POINT'**
  String get pretestInstructionsArtLabel;

  /// Main heading on the Pretest instructions page.
  ///
  /// In en, this message translates to:
  /// **'Know your starting point'**
  String get pretestInstructionsTitle;

  /// Introductory paragraph on the Pretest instructions page.
  ///
  /// In en, this message translates to:
  /// **'Before you start learning, let\'s measure your understanding of computer networking.'**
  String get pretestInstructionsBody;

  /// No description provided for @pretestInstructionsQuestionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Number of questions'**
  String get pretestInstructionsQuestionsLabel;

  /// Pretest question count on the instruction card.
  ///
  /// In en, this message translates to:
  /// **'{count} questions'**
  String pretestInstructionsQuestionsValue(String count);

  /// No description provided for @pretestInstructionsDurationLabel.
  ///
  /// In en, this message translates to:
  /// **'Time limit'**
  String get pretestInstructionsDurationLabel;

  /// No description provided for @pretestInstructionsTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Question type'**
  String get pretestInstructionsTypeLabel;

  /// No description provided for @pretestInstructionsTypeValue.
  ///
  /// In en, this message translates to:
  /// **'Multiple choice'**
  String get pretestInstructionsTypeValue;

  /// No description provided for @pretestInstructionsWarningPrefix.
  ///
  /// In en, this message translates to:
  /// **'The pretest can only be taken '**
  String get pretestInstructionsWarningPrefix;

  /// No description provided for @pretestInstructionsWarningEmphasis.
  ///
  /// In en, this message translates to:
  /// **'once'**
  String get pretestInstructionsWarningEmphasis;

  /// No description provided for @pretestInstructionsWarningSuffix.
  ///
  /// In en, this message translates to:
  /// **'. Make sure your internet connection is stable and you are ready before starting.'**
  String get pretestInstructionsWarningSuffix;

  /// No description provided for @pretestInstructionsLockTitle.
  ///
  /// In en, this message translates to:
  /// **'The key to start learning'**
  String get pretestInstructionsLockTitle;

  /// No description provided for @pretestInstructionsLockBody.
  ///
  /// In en, this message translates to:
  /// **'Complete the pretest to unlock Module 1. The score does not affect your final grade.'**
  String get pretestInstructionsLockBody;

  /// Primary button on the Pretest instructions page that opens the question screen.
  ///
  /// In en, this message translates to:
  /// **'Start Pretest Now'**
  String get startPretestNow;

  /// Top bar title on the Posttest instructions page.
  ///
  /// In en, this message translates to:
  /// **'Assessment - Post Test'**
  String get posttestInstructionsTopBar;

  /// All-caps label inside the illustration on the Posttest instructions page.
  ///
  /// In en, this message translates to:
  /// **'SHOW WHAT YOU HAVE LEARNED'**
  String get posttestInstructionsArtLabel;

  /// Main heading on the Posttest instructions page.
  ///
  /// In en, this message translates to:
  /// **'Posttest Instructions'**
  String get posttestInstructionsTitle;

  /// Introductory paragraph on the Posttest instructions page.
  ///
  /// In en, this message translates to:
  /// **'You have completed all modules. Let\'s measure how far your understanding of computer networking has grown.'**
  String get posttestInstructionsBody;

  /// No description provided for @posttestInstructionsWarningPrefix.
  ///
  /// In en, this message translates to:
  /// **'The post test can only be taken '**
  String get posttestInstructionsWarningPrefix;

  /// No description provided for @posttestInstructionsLockTitle.
  ///
  /// In en, this message translates to:
  /// **'The final checkpoint'**
  String get posttestInstructionsLockTitle;

  /// No description provided for @posttestInstructionsLockBody.
  ///
  /// In en, this message translates to:
  /// **'The Post Test becomes available after all 4 modules have been completed. The score does not affect your final grade.'**
  String get posttestInstructionsLockBody;

  /// Primary button on the Posttest instructions page that opens the question screen.
  ///
  /// In en, this message translates to:
  /// **'Start Post Test Now'**
  String get startPosttestNow;

  /// Primary button on the student dashboard to resume the next unfinished learning step.
  ///
  /// In en, this message translates to:
  /// **'Continue Learning'**
  String get continueLearning;

  /// Shown in place of the Continue Learning button when the whole learning flow is finished.
  ///
  /// In en, this message translates to:
  /// **'All materials completed'**
  String get allMaterialsCompleted;

  /// No description provided for @assessmentCompletedTitle.
  ///
  /// In en, this message translates to:
  /// **'Already Completed'**
  String get assessmentCompletedTitle;

  /// No description provided for @assessmentCompletedBody.
  ///
  /// In en, this message translates to:
  /// **'You have already completed this assessment.'**
  String get assessmentCompletedBody;

  /// Shown in the completed-assessment dialog when a score exists.
  ///
  /// In en, this message translates to:
  /// **'You have already completed this assessment with a score of {score}.'**
  String assessmentCompletedWithScore(String score);

  /// Explains why the start action is gone: the assessment is one-shot.
  ///
  /// In en, this message translates to:
  /// **'{assessment} can only be taken once and cannot be repeated.'**
  String assessmentCompletedOnlyOnce(String assessment);

  /// No description provided for @assessmentCompletedStatusPassed.
  ///
  /// In en, this message translates to:
  /// **'Result: Passed'**
  String get assessmentCompletedStatusPassed;

  /// No description provided for @assessmentCompletedStatusFailed.
  ///
  /// In en, this message translates to:
  /// **'Result: Not passed'**
  String get assessmentCompletedStatusFailed;

  /// Correct/wrong answer counts in the completed-assessment dialog.
  ///
  /// In en, this message translates to:
  /// **'{correct} correct · {wrong} wrong'**
  String assessmentCompletedBreakdown(int correct, int wrong);

  /// No description provided for @viewAssessmentResult.
  ///
  /// In en, this message translates to:
  /// **'View Result'**
  String get viewAssessmentResult;

  /// No description provided for @assessmentLockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Assessment Locked'**
  String get assessmentLockedTitle;

  /// No description provided for @assessmentLockedPosttest.
  ///
  /// In en, this message translates to:
  /// **'The Post Test becomes available after all 4 modules have been completed.'**
  String get assessmentLockedPosttest;

  /// No description provided for @assessmentLockedGeneric.
  ///
  /// In en, this message translates to:
  /// **'This assessment is not available yet.'**
  String get assessmentLockedGeneric;

  /// No description provided for @assessmentLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load assessments'**
  String get assessmentLoadFailed;

  /// No description provided for @assessmentLoadFailedBody.
  ///
  /// In en, this message translates to:
  /// **'Check your internet connection and try again.'**
  String get assessmentLoadFailedBody;

  /// No description provided for @assessmentResult.
  ///
  /// In en, this message translates to:
  /// **'Assessment Result'**
  String get assessmentResult;

  /// No description provided for @assessmentTotalQuestions.
  ///
  /// In en, this message translates to:
  /// **'Total Questions'**
  String get assessmentTotalQuestions;

  /// No description provided for @pretestCompletedMessage.
  ///
  /// In en, this message translates to:
  /// **'The pretest is complete. You can continue to the learning materials.'**
  String get pretestCompletedMessage;

  /// No description provided for @posttestCompletedMessage.
  ///
  /// In en, this message translates to:
  /// **'The post test is complete. The entire learning sequence has been completed.'**
  String get posttestCompletedMessage;

  /// No description provided for @backToAssessment.
  ///
  /// In en, this message translates to:
  /// **'Back to Assessment'**
  String get backToAssessment;

  /// No description provided for @backToDashboard.
  ///
  /// In en, this message translates to:
  /// **'Back to Dashboard'**
  String get backToDashboard;

  /// No description provided for @videoNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'This material has no video yet.'**
  String get videoNotAvailable;

  /// No description provided for @materialNotPublished.
  ///
  /// In en, this message translates to:
  /// **'This material has not been published.'**
  String get materialNotPublished;

  /// No description provided for @materialLockedMessage.
  ///
  /// In en, this message translates to:
  /// **'This material is still locked.'**
  String get materialLockedMessage;

  /// No description provided for @markVideoDone.
  ///
  /// In en, this message translates to:
  /// **'Mark as Done'**
  String get markVideoDone;

  /// No description provided for @videoDone.
  ///
  /// In en, this message translates to:
  /// **'Video Done'**
  String get videoDone;

  /// No description provided for @videoMarkedDone.
  ///
  /// In en, this message translates to:
  /// **'Video marked as done.'**
  String get videoMarkedDone;

  /// No description provided for @videoCannotOpen.
  ///
  /// In en, this message translates to:
  /// **'This video cannot be opened'**
  String get videoCannotOpen;

  /// No description provided for @startReading.
  ///
  /// In en, this message translates to:
  /// **'Start Reading'**
  String get startReading;

  /// No description provided for @continueReading.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueReading;

  /// No description provided for @noReadingContent.
  ///
  /// In en, this message translates to:
  /// **'The reading content for this material is not available yet. Please contact your lecturer or admin.'**
  String get noReadingContent;

  /// No description provided for @readingMarked.
  ///
  /// In en, this message translates to:
  /// **'Material marked as read.'**
  String get readingMarked;

  /// Progress header above the current assessment question.
  ///
  /// In en, this message translates to:
  /// **'Question {current} of {total}'**
  String assessmentQuestionProgress(int current, int total);

  /// How many questions the student has answered so far.
  ///
  /// In en, this message translates to:
  /// **'{count} answered'**
  String assessmentAnsweredCount(int count);

  /// No description provided for @assessmentQuestionNavigation.
  ///
  /// In en, this message translates to:
  /// **'Question Navigation'**
  String get assessmentQuestionNavigation;

  /// No description provided for @assessmentCurrentQuestion.
  ///
  /// In en, this message translates to:
  /// **'Current question'**
  String get assessmentCurrentQuestion;

  /// No description provided for @assessmentAnsweredQuestion.
  ///
  /// In en, this message translates to:
  /// **'Answered'**
  String get assessmentAnsweredQuestion;

  /// No description provided for @assessmentUnansweredQuestion.
  ///
  /// In en, this message translates to:
  /// **'Not answered'**
  String get assessmentUnansweredQuestion;

  /// No description provided for @assessmentYourAnswer.
  ///
  /// In en, this message translates to:
  /// **'Your answer'**
  String get assessmentYourAnswer;

  /// No description provided for @assessmentPreviousQuestion.
  ///
  /// In en, this message translates to:
  /// **'Previous question'**
  String get assessmentPreviousQuestion;

  /// No description provided for @assessmentNextQuestion.
  ///
  /// In en, this message translates to:
  /// **'Next question'**
  String get assessmentNextQuestion;

  /// No description provided for @assessmentSubmitTitle.
  ///
  /// In en, this message translates to:
  /// **'Submit Assessment?'**
  String get assessmentSubmitTitle;

  /// Submit confirmation when some questions are still unanswered.
  ///
  /// In en, this message translates to:
  /// **'There are still {count} unanswered questions. Are you sure you want to submit the assessment?'**
  String assessmentSubmitWithUnanswered(int count);

  /// No description provided for @assessmentSubmitAllAnswered.
  ///
  /// In en, this message translates to:
  /// **'All questions have been answered. Are you sure you want to submit the assessment?'**
  String get assessmentSubmitAllAnswered;

  /// No description provided for @assessmentLeaveTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave Assessment?'**
  String get assessmentLeaveTitle;

  /// No description provided for @assessmentLeaveBody.
  ///
  /// In en, this message translates to:
  /// **'Your saved answers will remain saved, but the assessment will not be completed until you submit it.'**
  String get assessmentLeaveBody;

  /// No description provided for @stay.
  ///
  /// In en, this message translates to:
  /// **'Stay'**
  String get stay;

  /// No description provided for @leave.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get leave;

  /// No description provided for @assessmentSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get assessmentSubmit;

  /// No description provided for @assessmentTimeWarning.
  ///
  /// In en, this message translates to:
  /// **'Less than 1 minute remains.'**
  String get assessmentTimeWarning;

  /// No description provided for @assessmentNextAction.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get assessmentNextAction;

  /// No description provided for @assessmentSubmitAction.
  ///
  /// In en, this message translates to:
  /// **'Submit Assessment'**
  String get assessmentSubmitAction;

  /// No description provided for @assessmentErrorNotFound.
  ///
  /// In en, this message translates to:
  /// **'Assessment was not found.'**
  String get assessmentErrorNotFound;

  /// No description provided for @assessmentErrorNotPublished.
  ///
  /// In en, this message translates to:
  /// **'Assessment has not been published.'**
  String get assessmentErrorNotPublished;

  /// No description provided for @assessmentErrorNoQuestions.
  ///
  /// In en, this message translates to:
  /// **'This assessment has no questions.'**
  String get assessmentErrorNoQuestions;

  /// No description provided for @assessmentErrorAttemptNotFound.
  ///
  /// In en, this message translates to:
  /// **'Assessment attempt was not found.'**
  String get assessmentErrorAttemptNotFound;

  /// No description provided for @assessmentErrorLocked.
  ///
  /// In en, this message translates to:
  /// **'Assessment is still locked.'**
  String get assessmentErrorLocked;

  /// No description provided for @assessmentErrorLockedOrCompleted.
  ///
  /// In en, this message translates to:
  /// **'This test has already been completed or is not open yet.'**
  String get assessmentErrorLockedOrCompleted;

  /// No description provided for @assessmentErrorPretestRequired.
  ///
  /// In en, this message translates to:
  /// **'You must complete the Pretest first.'**
  String get assessmentErrorPretestRequired;

  /// No description provided for @assessmentErrorModulesIncomplete.
  ///
  /// In en, this message translates to:
  /// **'All modules must be completed first.'**
  String get assessmentErrorModulesIncomplete;

  /// No description provided for @assessmentErrorAlreadyCompleted.
  ///
  /// In en, this message translates to:
  /// **'This assessment has already been completed.'**
  String get assessmentErrorAlreadyCompleted;

  /// No description provided for @assessmentErrorDeadlinePassed.
  ///
  /// In en, this message translates to:
  /// **'The deadline for this assessment has passed.'**
  String get assessmentErrorDeadlinePassed;

  /// No description provided for @assessmentErrorAttemptsExhausted.
  ///
  /// In en, this message translates to:
  /// **'You have used up all attempts for this assessment.'**
  String get assessmentErrorAttemptsExhausted;

  /// No description provided for @assessmentErrorNotEnrolled.
  ///
  /// In en, this message translates to:
  /// **'You are not enrolled in the class that owns this assessment.'**
  String get assessmentErrorNotEnrolled;

  /// No description provided for @assessmentErrorNoSession.
  ///
  /// In en, this message translates to:
  /// **'Your login session was not found.'**
  String get assessmentErrorNoSession;

  /// No description provided for @assessmentErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get assessmentErrorGeneric;

  /// No description provided for @backToMaterial.
  ///
  /// In en, this message translates to:
  /// **'Back to Material'**
  String get backToMaterial;

  /// No description provided for @nextToVideo.
  ///
  /// In en, this message translates to:
  /// **'Continue to Video'**
  String get nextToVideo;

  /// No description provided for @posttestUnlockedTitle.
  ///
  /// In en, this message translates to:
  /// **'All modules complete!'**
  String get posttestUnlockedTitle;

  /// No description provided for @posttestUnlockedMessage.
  ///
  /// In en, this message translates to:
  /// **'You have finished every module. Take the Post-test to complete the course.'**
  String get posttestUnlockedMessage;

  /// No description provided for @notNow.
  ///
  /// In en, this message translates to:
  /// **'Not Now'**
  String get notNow;

  /// No description provided for @startPosttest.
  ///
  /// In en, this message translates to:
  /// **'Start Post-test'**
  String get startPosttest;

  /// No description provided for @pretestLockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Pretest Not Completed'**
  String get pretestLockedTitle;

  /// No description provided for @pretestLockedMessage.
  ///
  /// In en, this message translates to:
  /// **'This module unlocks once you complete the Pretest. Take the Pretest first to open this material.'**
  String get pretestLockedMessage;

  /// No description provided for @readyToStart.
  ///
  /// In en, this message translates to:
  /// **'Ready to start'**
  String get readyToStart;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @assessment.
  ///
  /// In en, this message translates to:
  /// **'Assessment'**
  String get assessment;

  /// No description provided for @on.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get on;

  /// No description provided for @off.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get off;

  /// No description provided for @lecturerDashboardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Information Technology Education'**
  String get lecturerDashboardSubtitle;

  /// No description provided for @contentManagement.
  ///
  /// In en, this message translates to:
  /// **'Content Management'**
  String get contentManagement;

  /// No description provided for @manageMaterials.
  ///
  /// In en, this message translates to:
  /// **'Manage Materials'**
  String get manageMaterials;

  /// No description provided for @manageMaterialsDescription.
  ///
  /// In en, this message translates to:
  /// **'Add and edit learning materials'**
  String get manageMaterialsDescription;

  /// No description provided for @manageAssessments.
  ///
  /// In en, this message translates to:
  /// **'Manage Assessments'**
  String get manageAssessments;

  /// No description provided for @manageAssessmentsDescription.
  ///
  /// In en, this message translates to:
  /// **'Questions and answer keys'**
  String get manageAssessmentsDescription;

  /// No description provided for @addMaterial.
  ///
  /// In en, this message translates to:
  /// **'Add Material'**
  String get addMaterial;

  /// No description provided for @addMaterialDescription.
  ///
  /// In en, this message translates to:
  /// **'Create a new learning material'**
  String get addMaterialDescription;

  /// No description provided for @totalStudents.
  ///
  /// In en, this message translates to:
  /// **'Total Students'**
  String get totalStudents;

  /// No description provided for @totalClasses.
  ///
  /// In en, this message translates to:
  /// **'Total Classes'**
  String get totalClasses;

  /// No description provided for @averageScore.
  ///
  /// In en, this message translates to:
  /// **'Average Score'**
  String get averageScore;

  /// No description provided for @noClassData.
  ///
  /// In en, this message translates to:
  /// **'No class data yet'**
  String get noClassData;

  /// No description provided for @publishedOfTotal.
  ///
  /// In en, this message translates to:
  /// **'{count} of {total} published'**
  String publishedOfTotal(int count, int total);

  /// No description provided for @scorePercent.
  ///
  /// In en, this message translates to:
  /// **'{value}%'**
  String scorePercent(String value);

  /// No description provided for @searchMaterials.
  ///
  /// In en, this message translates to:
  /// **'Search materials'**
  String get searchMaterials;

  /// No description provided for @allModules.
  ///
  /// In en, this message translates to:
  /// **'All Modules'**
  String get allModules;

  /// No description provided for @noVideo.
  ///
  /// In en, this message translates to:
  /// **'No video'**
  String get noVideo;

  /// No description provided for @createdAt.
  ///
  /// In en, this message translates to:
  /// **'Created {date}'**
  String createdAt(String date);

  /// No description provided for @coreMaterialProtected.
  ///
  /// In en, this message translates to:
  /// **'Core materials cannot be deleted'**
  String get coreMaterialProtected;

  /// No description provided for @coreModuleLocked.
  ///
  /// In en, this message translates to:
  /// **'Only core materials can be placed in a module'**
  String get coreModuleLocked;

  /// No description provided for @noMaterials.
  ///
  /// In en, this message translates to:
  /// **'No materials yet'**
  String get noMaterials;

  /// No description provided for @noMaterialsDescription.
  ///
  /// In en, this message translates to:
  /// **'Tap Add Material to create your first learning material.'**
  String get noMaterialsDescription;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @publish.
  ///
  /// In en, this message translates to:
  /// **'Publish'**
  String get publish;

  /// No description provided for @unpublish.
  ///
  /// In en, this message translates to:
  /// **'Unpublish'**
  String get unpublish;

  /// No description provided for @published.
  ///
  /// In en, this message translates to:
  /// **'Published'**
  String get published;

  /// No description provided for @draft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get draft;

  /// No description provided for @deleteMaterial.
  ///
  /// In en, this message translates to:
  /// **'Delete Material'**
  String get deleteMaterial;

  /// No description provided for @deleteMaterialConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This material will be permanently removed. Student progress for it is deleted as well.'**
  String get deleteMaterialConfirmBody;

  /// No description provided for @materialDeleted.
  ///
  /// In en, this message translates to:
  /// **'Material deleted.'**
  String get materialDeleted;

  /// No description provided for @materialPublished.
  ///
  /// In en, this message translates to:
  /// **'Material published.'**
  String get materialPublished;

  /// No description provided for @materialUnpublished.
  ///
  /// In en, this message translates to:
  /// **'Material unpublished.'**
  String get materialUnpublished;

  /// No description provided for @materialCreated.
  ///
  /// In en, this message translates to:
  /// **'Material created.'**
  String get materialCreated;

  /// No description provided for @materialUpdated.
  ///
  /// In en, this message translates to:
  /// **'Material updated.'**
  String get materialUpdated;

  /// No description provided for @materialSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save the material.'**
  String get materialSaveFailed;

  /// No description provided for @coreProtectedError.
  ///
  /// In en, this message translates to:
  /// **'This is a core material and cannot be changed.'**
  String get coreProtectedError;

  /// No description provided for @invalidVideoUrlError.
  ///
  /// In en, this message translates to:
  /// **'That video URL is not a valid YouTube link.'**
  String get invalidVideoUrlError;

  /// No description provided for @notPermittedError.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have permission to do that.'**
  String get notPermittedError;

  /// No description provided for @addMaterialTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Material'**
  String get addMaterialTitle;

  /// No description provided for @editMaterial.
  ///
  /// In en, this message translates to:
  /// **'Edit Material'**
  String get editMaterial;

  /// No description provided for @materialTitleSection.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get materialTitleSection;

  /// No description provided for @titleIndonesian.
  ///
  /// In en, this message translates to:
  /// **'Title (Indonesian)'**
  String get titleIndonesian;

  /// No description provided for @titleIndonesianHint.
  ///
  /// In en, this message translates to:
  /// **'The title students see'**
  String get titleIndonesianHint;

  /// No description provided for @titleEnglish.
  ///
  /// In en, this message translates to:
  /// **'Title (English)'**
  String get titleEnglish;

  /// No description provided for @titleEnglishHint.
  ///
  /// In en, this message translates to:
  /// **'Optional, shown when the app is in English'**
  String get titleEnglishHint;

  /// No description provided for @materialPlacementSection.
  ///
  /// In en, this message translates to:
  /// **'Placement'**
  String get materialPlacementSection;

  /// No description provided for @orderIndex.
  ///
  /// In en, this message translates to:
  /// **'Order Index'**
  String get orderIndex;

  /// No description provided for @orderIndexInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid order number (1 or higher)'**
  String get orderIndexInvalid;

  /// No description provided for @summaryHint.
  ///
  /// In en, this message translates to:
  /// **'A short summary shown on the material card'**
  String get summaryHint;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @descriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Describe the task objectives'**
  String get descriptionHint;

  /// No description provided for @content.
  ///
  /// In en, this message translates to:
  /// **'Content'**
  String get content;

  /// No description provided for @materialContentSection.
  ///
  /// In en, this message translates to:
  /// **'Content'**
  String get materialContentSection;

  /// No description provided for @materialContentHint.
  ///
  /// In en, this message translates to:
  /// **'Plain text. Use three backticks for monospaced blocks, \'- \' for bullets and \'1. \' for headings.'**
  String get materialContentHint;

  /// No description provided for @contentHint.
  ///
  /// In en, this message translates to:
  /// **'Reading content'**
  String get contentHint;

  /// No description provided for @videoUrl.
  ///
  /// In en, this message translates to:
  /// **'Video URL'**
  String get videoUrl;

  /// No description provided for @durationMinutesLabel.
  ///
  /// In en, this message translates to:
  /// **'Duration (minutes)'**
  String get durationMinutesLabel;

  /// No description provided for @studyTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Estimated study time (minutes)'**
  String get studyTimeLabel;

  /// No description provided for @studyTimeHint.
  ///
  /// In en, this message translates to:
  /// **'Reading time plus video. This is not the YouTube video length.'**
  String get studyTimeHint;

  /// No description provided for @durationInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid duration'**
  String get durationInvalid;

  /// No description provided for @publishOn.
  ///
  /// In en, this message translates to:
  /// **'Publish immediately'**
  String get publishOn;

  /// No description provided for @publishOff.
  ///
  /// In en, this message translates to:
  /// **'Save as draft'**
  String get publishOff;

  /// No description provided for @assessmentIntro.
  ///
  /// In en, this message translates to:
  /// **'Both assessments are shared by all students. Every question needs an answer key before it can be published.'**
  String get assessmentIntro;

  /// No description provided for @noAssessments.
  ///
  /// In en, this message translates to:
  /// **'No assessments'**
  String get noAssessments;

  /// No description provided for @noAssessmentsDescription.
  ///
  /// In en, this message translates to:
  /// **'There are no assessments in this course yet.'**
  String get noAssessmentsDescription;

  /// No description provided for @pretest.
  ///
  /// In en, this message translates to:
  /// **'Pre-test'**
  String get pretest;

  /// No description provided for @posttest.
  ///
  /// In en, this message translates to:
  /// **'Post-test'**
  String get posttest;

  /// No description provided for @questionsShort.
  ///
  /// In en, this message translates to:
  /// **'questions'**
  String get questionsShort;

  /// No description provided for @answerKeysShort.
  ///
  /// In en, this message translates to:
  /// **'answer keys'**
  String get answerKeysShort;

  /// No description provided for @answerKeyMissing.
  ///
  /// In en, this message translates to:
  /// **'{count} questions missing answer key'**
  String answerKeyMissing(int count);

  /// No description provided for @manageQuestions.
  ///
  /// In en, this message translates to:
  /// **'Manage Questions'**
  String get manageQuestions;

  /// No description provided for @assessmentPublished.
  ///
  /// In en, this message translates to:
  /// **'Assessment published.'**
  String get assessmentPublished;

  /// No description provided for @assessmentUnpublished.
  ///
  /// In en, this message translates to:
  /// **'Assessment unpublished.'**
  String get assessmentUnpublished;

  /// No description provided for @assessmentQuizIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Cannot publish: every question needs an answer key.'**
  String get assessmentQuizIncomplete;

  /// No description provided for @assessmentSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save assessment.'**
  String get assessmentSaveFailed;

  /// No description provided for @addQuestion.
  ///
  /// In en, this message translates to:
  /// **'Add Question'**
  String get addQuestion;

  /// No description provided for @editQuestion.
  ///
  /// In en, this message translates to:
  /// **'Edit Question'**
  String get editQuestion;

  /// No description provided for @noQuestions.
  ///
  /// In en, this message translates to:
  /// **'No questions yet'**
  String get noQuestions;

  /// No description provided for @noQuestionsDescription.
  ///
  /// In en, this message translates to:
  /// **'Tap Add Question to build this assessment.'**
  String get noQuestionsDescription;

  /// No description provided for @questionText.
  ///
  /// In en, this message translates to:
  /// **'Question'**
  String get questionText;

  /// No description provided for @questionTextHint.
  ///
  /// In en, this message translates to:
  /// **'Enter the question text'**
  String get questionTextHint;

  /// No description provided for @answerOptions.
  ///
  /// In en, this message translates to:
  /// **'Answer Options'**
  String get answerOptions;

  /// No description provided for @optionHint.
  ///
  /// In en, this message translates to:
  /// **'Enter option text'**
  String get optionHint;

  /// No description provided for @correctAnswer.
  ///
  /// In en, this message translates to:
  /// **'Correct Answer'**
  String get correctAnswer;

  /// No description provided for @answerKeyHint.
  ///
  /// In en, this message translates to:
  /// **'Select the correct answer'**
  String get answerKeyHint;

  /// No description provided for @pickAnswerKey.
  ///
  /// In en, this message translates to:
  /// **'Please select the correct answer first.'**
  String get pickAnswerKey;

  /// No description provided for @noAnswerKey.
  ///
  /// In en, this message translates to:
  /// **'No answer key set'**
  String get noAnswerKey;

  /// No description provided for @questionImage.
  ///
  /// In en, this message translates to:
  /// **'Question Image URL'**
  String get questionImage;

  /// No description provided for @questionAdded.
  ///
  /// In en, this message translates to:
  /// **'Question added.'**
  String get questionAdded;

  /// No description provided for @questionUpdated.
  ///
  /// In en, this message translates to:
  /// **'Question updated.'**
  String get questionUpdated;

  /// No description provided for @questionDeleted.
  ///
  /// In en, this message translates to:
  /// **'Question deleted.'**
  String get questionDeleted;

  /// No description provided for @questionSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save the question.'**
  String get questionSaveFailed;

  /// No description provided for @deleteQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete Question'**
  String get deleteQuestion;

  /// No description provided for @deleteQuestionConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'The answer key and any student answers to this question are deleted too, and cannot be restored.'**
  String get deleteQuestionConfirmBody;

  /// No description provided for @nip.
  ///
  /// In en, this message translates to:
  /// **'NIP'**
  String get nip;

  /// No description provided for @role.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get role;

  /// No description provided for @roleLecturer.
  ///
  /// In en, this message translates to:
  /// **'Lecturer'**
  String get roleLecturer;

  /// No description provided for @accountInformation.
  ///
  /// In en, this message translates to:
  /// **'Account information'**
  String get accountInformation;

  /// No description provided for @profileReadOnlyNote.
  ///
  /// In en, this message translates to:
  /// **'Your name, NIP and email are managed by the admin. Contact them to change them.'**
  String get profileReadOnlyNote;

  /// No description provided for @myProfile.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get myProfile;

  /// No description provided for @joinedSince.
  ///
  /// In en, this message translates to:
  /// **'Joined since'**
  String get joinedSince;

  /// No description provided for @users.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get users;

  /// No description provided for @tasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get tasks;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @manage.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get manage;

  /// No description provided for @overview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overview;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @lockStatus.
  ///
  /// In en, this message translates to:
  /// **'Lock Status'**
  String get lockStatus;

  /// No description provided for @materialAccessLabel.
  ///
  /// In en, this message translates to:
  /// **'Material access'**
  String get materialAccessLabel;

  /// No description provided for @materialAccessOptionProgress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get materialAccessOptionProgress;

  /// No description provided for @materialAccessOptionOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get materialAccessOptionOpen;

  /// No description provided for @materialAccessOptionLocked.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get materialAccessOptionLocked;

  /// No description provided for @materialAccessHelp.
  ///
  /// In en, this message translates to:
  /// **'Follow progress: counts toward finishing the module, like every ordinary material. Open / Locked: your override — optional for students, never blocks the next module.'**
  String get materialAccessHelp;

  /// No description provided for @materialAccessForcedOpenBadge.
  ///
  /// In en, this message translates to:
  /// **'Forced open'**
  String get materialAccessForcedOpenBadge;

  /// No description provided for @materialAccessForcedLockedBadge.
  ///
  /// In en, this message translates to:
  /// **'Forced locked'**
  String get materialAccessForcedLockedBadge;

  /// No description provided for @materialAccessLockedItemMessage.
  ///
  /// In en, this message translates to:
  /// **'This material is locked by the lecturer.'**
  String get materialAccessLockedItemMessage;

  /// No description provided for @statusPublished.
  ///
  /// In en, this message translates to:
  /// **'Published'**
  String get statusPublished;

  /// No description provided for @statusDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get statusDraft;

  /// No description provided for @studyProgram.
  ///
  /// In en, this message translates to:
  /// **'Study Programme'**
  String get studyProgram;

  /// No description provided for @notFilledYet.
  ///
  /// In en, this message translates to:
  /// **'(not filled in yet)'**
  String get notFilledYet;

  /// No description provided for @academicTag.
  ///
  /// In en, this message translates to:
  /// **'Information Technology Education'**
  String get academicTag;

  /// Academic tag shown on student profile hero, e.g. study program name.
  ///
  /// In en, this message translates to:
  /// **'Information Technology Education'**
  String get studentAcademicTag;

  /// No description provided for @settingsAndActivity.
  ///
  /// In en, this message translates to:
  /// **'Settings & Activity'**
  String get settingsAndActivity;

  /// No description provided for @profileInfo.
  ///
  /// In en, this message translates to:
  /// **'Profile Information'**
  String get profileInfo;

  /// No description provided for @academicInfo.
  ///
  /// In en, this message translates to:
  /// **'Academic Information'**
  String get academicInfo;

  /// Subtitle for the student academic information menu item.
  ///
  /// In en, this message translates to:
  /// **'NIM, Semester, and Study Program details'**
  String get academicInfoStudentSubtitle;

  /// Menu item title for student assessment history.
  ///
  /// In en, this message translates to:
  /// **'Assessment History'**
  String get assessmentHistory;

  /// First tab of the two-tab assessment page: the core pretest and post test list.
  ///
  /// In en, this message translates to:
  /// **'Pretest & Post Test'**
  String get assessmentCoreTab;

  /// Subtitle for assessment history menu item.
  ///
  /// In en, this message translates to:
  /// **'Pretest & Post Test transcripts'**
  String get assessmentHistorySubtitle;

  /// Metric label for student progress percentage.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get studentProgressLabel;

  /// Metric label for student completed modules.
  ///
  /// In en, this message translates to:
  /// **'Modules'**
  String get studentModulesLabel;

  /// Metric label for student average score.
  ///
  /// In en, this message translates to:
  /// **'Average Score'**
  String get studentAverageScoreLabel;

  /// No description provided for @securityAndPassword.
  ///
  /// In en, this message translates to:
  /// **'Security & Password'**
  String get securityAndPassword;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'NetLearn v1.0.0 · Learn. Connect. Grow.'**
  String get appVersion;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light Theme'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark Theme'**
  String get themeDark;

  /// No description provided for @changePasswordNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Password change not available yet. Use the link below to reset.'**
  String get changePasswordNotAvailable;

  /// No description provided for @usePasswordReset.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password'**
  String get usePasswordReset;

  /// Shown when the password reset email could not be sent from the profile security dialog.
  ///
  /// In en, this message translates to:
  /// **'Failed to send the password reset link. Make sure your email is valid.'**
  String get passwordResetEmailFailed;

  /// Empty state for the student assessment history page.
  ///
  /// In en, this message translates to:
  /// **'No assessment history yet. Complete your first assessment to see its result here.'**
  String get assessmentHistoryEmpty;

  /// Label for the student ID shown on the assessment history identity card.
  ///
  /// In en, this message translates to:
  /// **'Student ID'**
  String get historyStudentId;

  /// Card title for the Pretest status row on the assessment history page, spelled as in the Figma reference.
  ///
  /// In en, this message translates to:
  /// **'Pretest'**
  String get historyPretestTitle;

  /// Card title for the Posttest status row on the assessment history page, spelled as in the Figma reference.
  ///
  /// In en, this message translates to:
  /// **'Posttest'**
  String get historyPosttestTitle;

  /// Label for the completed-assessments metric on the assessment history summary.
  ///
  /// In en, this message translates to:
  /// **'Assessments completed'**
  String get historyCompletedLabel;

  /// Label for the average-score metric on the assessment history summary.
  ///
  /// In en, this message translates to:
  /// **'Average available score'**
  String get historyAverageLabel;

  /// Row label for the score on an assessment history card.
  ///
  /// In en, this message translates to:
  /// **'Score:'**
  String get historyScoreLabel;

  /// Caption under the assessment history summary while either the Pretest or the Post Test has no submitted attempt.
  ///
  /// In en, this message translates to:
  /// **'{done}/2 · Assessments not complete'**
  String historyCoreIncomplete(String done);

  /// No description provided for @studentSpaceHeading.
  ///
  /// In en, this message translates to:
  /// **'Your learning space'**
  String get studentSpaceHeading;

  /// No description provided for @studentDashboardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Ready to learn something new today?'**
  String get studentDashboardSubtitle;

  /// No description provided for @shortcutPretest.
  ///
  /// In en, this message translates to:
  /// **'Pretest'**
  String get shortcutPretest;

  /// No description provided for @shortcutPretestHint.
  ///
  /// In en, this message translates to:
  /// **'Test your knowledge'**
  String get shortcutPretestHint;

  /// No description provided for @shortcutModules.
  ///
  /// In en, this message translates to:
  /// **'Modules'**
  String get shortcutModules;

  /// No description provided for @shortcutModulesHint.
  ///
  /// In en, this message translates to:
  /// **'4 learning modules'**
  String get shortcutModulesHint;

  /// No description provided for @shortcutScanner.
  ///
  /// In en, this message translates to:
  /// **'AR Scanner'**
  String get shortcutScanner;

  /// No description provided for @shortcutScannerHint.
  ///
  /// In en, this message translates to:
  /// **'Explore in 3D'**
  String get shortcutScannerHint;

  /// No description provided for @shortcutPosttest.
  ///
  /// In en, this message translates to:
  /// **'Post Test'**
  String get shortcutPosttest;

  /// No description provided for @shortcutPosttestHint.
  ///
  /// In en, this message translates to:
  /// **'Final assessment'**
  String get shortcutPosttestHint;

  /// No description provided for @shortcutAssignments.
  ///
  /// In en, this message translates to:
  /// **'Assessment'**
  String get shortcutAssignments;

  /// No description provided for @shortcutAssignmentsHint.
  ///
  /// In en, this message translates to:
  /// **'Tasks & assessments'**
  String get shortcutAssignmentsHint;

  /// No description provided for @shortcutAssessmentHistory.
  ///
  /// In en, this message translates to:
  /// **'Assessment History'**
  String get shortcutAssessmentHistory;

  /// No description provided for @shortcutAssessmentHistoryHint.
  ///
  /// In en, this message translates to:
  /// **'Scores and progress history'**
  String get shortcutAssessmentHistoryHint;

  /// No description provided for @shortcutProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get shortcutProfile;

  /// No description provided for @shortcutProfileHint.
  ///
  /// In en, this message translates to:
  /// **'Account & settings'**
  String get shortcutProfileHint;

  /// No description provided for @shortcutVirtualLab.
  ///
  /// In en, this message translates to:
  /// **'Virtual Lab'**
  String get shortcutVirtualLab;

  /// No description provided for @shortcutVirtualLabHint.
  ///
  /// In en, this message translates to:
  /// **'Network simulation'**
  String get shortcutVirtualLabHint;

  /// Virtual lab shortcut
  ///
  /// In en, this message translates to:
  /// **'Virtual Lab'**
  String get virtualLab;

  /// No description provided for @virtualLabAddPc.
  ///
  /// In en, this message translates to:
  /// **'Add PC'**
  String get virtualLabAddPc;

  /// No description provided for @virtualLabAddSwitch.
  ///
  /// In en, this message translates to:
  /// **'Add switch'**
  String get virtualLabAddSwitch;

  /// No description provided for @virtualLabConnect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get virtualLabConnect;

  /// No description provided for @virtualLabConnectFinish.
  ///
  /// In en, this message translates to:
  /// **'Create cable'**
  String get virtualLabConnectFinish;

  /// No description provided for @virtualLabEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Use the toolbar above to add devices and link them'**
  String get virtualLabEmptyHint;

  /// No description provided for @virtualLabDeleteSelected.
  ///
  /// In en, this message translates to:
  /// **'Delete selected'**
  String get virtualLabDeleteSelected;

  /// No description provided for @virtualLabReset.
  ///
  /// In en, this message translates to:
  /// **'Reset canvas'**
  String get virtualLabReset;

  /// No description provided for @virtualLabConnectNeedSelection.
  ///
  /// In en, this message translates to:
  /// **'Select a device first'**
  String get virtualLabConnectNeedSelection;

  /// No description provided for @virtualLabConnectPendingHint.
  ///
  /// In en, this message translates to:
  /// **'Tap a second device to create the cable'**
  String get virtualLabConnectPendingHint;

  /// No description provided for @virtualLabSelectedCable.
  ///
  /// In en, this message translates to:
  /// **'Cable selected'**
  String get virtualLabSelectedCable;

  /// No description provided for @virtualLabTestConnectivity.
  ///
  /// In en, this message translates to:
  /// **'Test connectivity'**
  String get virtualLabTestConnectivity;

  /// No description provided for @virtualLabTestSuccess.
  ///
  /// In en, this message translates to:
  /// **'Connection succeeded'**
  String get virtualLabTestSuccess;

  /// No description provided for @virtualLabTestFailed.
  ///
  /// In en, this message translates to:
  /// **'Connection failed'**
  String get virtualLabTestFailed;

  /// No description provided for @virtualLabTestNeedDevices.
  ///
  /// In en, this message translates to:
  /// **'Add network settings to at least two devices first'**
  String get virtualLabTestNeedDevices;

  /// No description provided for @virtualLabConfigDeviceTitle.
  ///
  /// In en, this message translates to:
  /// **'Device configuration'**
  String get virtualLabConfigDeviceTitle;

  /// No description provided for @virtualLabIpLabel.
  ///
  /// In en, this message translates to:
  /// **'IP Address'**
  String get virtualLabIpLabel;

  /// No description provided for @virtualLabMaskLabel.
  ///
  /// In en, this message translates to:
  /// **'Subnet Mask'**
  String get virtualLabMaskLabel;

  /// No description provided for @virtualLabNoIp.
  ///
  /// In en, this message translates to:
  /// **'Not configured'**
  String get virtualLabNoIp;

  /// No description provided for @virtualLabScenario1.
  ///
  /// In en, this message translates to:
  /// **'Scenario 1'**
  String get virtualLabScenario1;

  /// No description provided for @virtualLabReasonInvalidIp.
  ///
  /// In en, this message translates to:
  /// **'Invalid IP address format.'**
  String get virtualLabReasonInvalidIp;

  /// No description provided for @virtualLabReasonInvalidMask.
  ///
  /// In en, this message translates to:
  /// **'Invalid subnet mask format.'**
  String get virtualLabReasonInvalidMask;

  /// No description provided for @virtualLabReasonHostAddress.
  ///
  /// In en, this message translates to:
  /// **'An address is a network or broadcast address, not a host.'**
  String get virtualLabReasonHostAddress;

  /// No description provided for @virtualLabReasonDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate IP address detected.'**
  String get virtualLabReasonDuplicate;

  /// No description provided for @virtualLabReasonNoPath.
  ///
  /// In en, this message translates to:
  /// **'No network path between the configured devices.'**
  String get virtualLabReasonNoPath;

  /// No description provided for @virtualLabReasonDifferentSubnet.
  ///
  /// In en, this message translates to:
  /// **'Devices are in different subnets.'**
  String get virtualLabReasonDifferentSubnet;

  /// No description provided for @virtualLabSelectedDevice.
  ///
  /// In en, this message translates to:
  /// **'Device selected'**
  String get virtualLabSelectedDevice;

  /// No description provided for @virtualLabSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Build a topology, set IPv4, then test connectivity with ping.'**
  String get virtualLabSubtitle;

  /// No description provided for @virtualLabScenarioLabel.
  ///
  /// In en, this message translates to:
  /// **'SCENARIO 1 · SINGLE-SUBNET LAN'**
  String get virtualLabScenarioLabel;

  /// No description provided for @virtualLabScenarioDescription.
  ///
  /// In en, this message translates to:
  /// **'Connect PC2 to Switch1, give it an IP in 192.168.1.0/24, then ping from PC1 to PC2.'**
  String get virtualLabScenarioDescription;

  /// No description provided for @virtualLabToolSelect.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get virtualLabToolSelect;

  /// No description provided for @virtualLabToolCable.
  ///
  /// In en, this message translates to:
  /// **'Cable'**
  String get virtualLabToolCable;

  /// No description provided for @virtualLabToolPc.
  ///
  /// In en, this message translates to:
  /// **'PC'**
  String get virtualLabToolPc;

  /// No description provided for @virtualLabToolSwitch.
  ///
  /// In en, this message translates to:
  /// **'Switch'**
  String get virtualLabToolSwitch;

  /// No description provided for @virtualLabToolDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get virtualLabToolDelete;

  /// No description provided for @virtualLabToolReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get virtualLabToolReset;

  /// No description provided for @virtualLabLegendConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get virtualLabLegendConnected;

  /// No description provided for @virtualLabLegendNeedsConfig.
  ///
  /// In en, this message translates to:
  /// **'Needs config'**
  String get virtualLabLegendNeedsConfig;

  /// No description provided for @virtualLabLegendNotCabled.
  ///
  /// In en, this message translates to:
  /// **'Not cabled'**
  String get virtualLabLegendNotCabled;

  /// No description provided for @virtualLabCanvasHint.
  ///
  /// In en, this message translates to:
  /// **'Tap to select · drag to move · tap a cable to select it'**
  String get virtualLabCanvasHint;

  /// No description provided for @virtualLabPanelConfiguration.
  ///
  /// In en, this message translates to:
  /// **'Configuration'**
  String get virtualLabPanelConfiguration;

  /// No description provided for @virtualLabPanelPingTest.
  ///
  /// In en, this message translates to:
  /// **'Ping Test'**
  String get virtualLabPanelPingTest;

  /// No description provided for @virtualLabNoDeviceSelected.
  ///
  /// In en, this message translates to:
  /// **'Tap a device on the canvas to configure it.'**
  String get virtualLabNoDeviceSelected;

  /// No description provided for @virtualLabDeviceNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Device name'**
  String get virtualLabDeviceNameLabel;

  /// No description provided for @virtualLabDevicePcPorts.
  ///
  /// In en, this message translates to:
  /// **'PC · 1 port NIC'**
  String get virtualLabDevicePcPorts;

  /// No description provided for @virtualLabDeviceSwitchPorts.
  ///
  /// In en, this message translates to:
  /// **'Switch · multi-port'**
  String get virtualLabDeviceSwitchPorts;

  /// No description provided for @virtualLabStatusInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid'**
  String get virtualLabStatusInvalid;

  /// No description provided for @virtualLabCableConnected.
  ///
  /// In en, this message translates to:
  /// **'Cable: connected'**
  String get virtualLabCableConnected;

  /// No description provided for @virtualLabCableNotConnected.
  ///
  /// In en, this message translates to:
  /// **'Cable: not connected'**
  String get virtualLabCableNotConnected;

  /// No description provided for @virtualLabApply.
  ///
  /// In en, this message translates to:
  /// **'Apply configuration'**
  String get virtualLabApply;

  /// No description provided for @virtualLabPingSource.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get virtualLabPingSource;

  /// No description provided for @virtualLabPingTarget.
  ///
  /// In en, this message translates to:
  /// **'Target'**
  String get virtualLabPingTarget;

  /// No description provided for @virtualLabPingRun.
  ///
  /// In en, this message translates to:
  /// **'Run ping'**
  String get virtualLabPingRun;

  /// No description provided for @virtualLabPingSuccess.
  ///
  /// In en, this message translates to:
  /// **'Ping succeeded — both devices can reach each other.'**
  String get virtualLabPingSuccess;

  /// No description provided for @virtualLabPingFailed.
  ///
  /// In en, this message translates to:
  /// **'Ping failed'**
  String get virtualLabPingFailed;

  /// No description provided for @virtualLabPingNoDevices.
  ///
  /// In en, this message translates to:
  /// **'Add at least two devices first.'**
  String get virtualLabPingNoDevices;

  /// No description provided for @virtualLabPingSameDevice.
  ///
  /// In en, this message translates to:
  /// **'Choose two different devices to ping.'**
  String get virtualLabPingSameDevice;

  /// No description provided for @virtualLabCableIssueSameDevice.
  ///
  /// In en, this message translates to:
  /// **'Pick a different device for the other end of the cable.'**
  String get virtualLabCableIssueSameDevice;

  /// No description provided for @virtualLabCableIssuePcPortFull.
  ///
  /// In en, this message translates to:
  /// **'This PC already uses its only port. Delete its existing cable first.'**
  String get virtualLabCableIssuePcPortFull;

  /// No description provided for @virtualLabCableIssueDuplicate.
  ///
  /// In en, this message translates to:
  /// **'These two devices are already connected.'**
  String get virtualLabCableIssueDuplicate;

  /// No description provided for @virtualLabReasonNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'A device has no IP configuration yet.'**
  String get virtualLabReasonNotConfigured;

  /// No description provided for @virtualLabFooterNote.
  ///
  /// In en, this message translates to:
  /// **'Local on-device simulation · Scores and progress unaffected.'**
  String get virtualLabFooterNote;

  /// No description provided for @virtualLabBackToDashboard.
  ///
  /// In en, this message translates to:
  /// **'Back to Dashboard'**
  String get virtualLabBackToDashboard;

  /// No description provided for @learningJourney.
  ///
  /// In en, this message translates to:
  /// **'Your learning journey'**
  String get learningJourney;

  /// No description provided for @modulesCompletedOf.
  ///
  /// In en, this message translates to:
  /// **'{completed} of {total} modules completed'**
  String modulesCompletedOf(Object completed, Object total);

  /// Per-module completion line on the student dashboard module card, e.g. "2 of 3 materials completed".
  ///
  /// In en, this message translates to:
  /// **'{completed} of {total} materials completed'**
  String moduleMaterialsCompleted(int completed, int total);

  /// No description provided for @keepGoing.
  ///
  /// In en, this message translates to:
  /// **'Keep going!'**
  String get keepGoing;

  /// No description provided for @oneStepToday.
  ///
  /// In en, this message translates to:
  /// **'One small step today,'**
  String get oneStepToday;

  /// No description provided for @oneConnectionTomorrow.
  ///
  /// In en, this message translates to:
  /// **'one big connection for your future.'**
  String get oneConnectionTomorrow;

  /// No description provided for @aboutNetLearn.
  ///
  /// In en, this message translates to:
  /// **'About NetLearn'**
  String get aboutNetLearn;

  /// Hero heading on the About page naming the product and its subject.
  ///
  /// In en, this message translates to:
  /// **'NetLearn — Computer Networking Learning Platform'**
  String get aboutNetLearnHeadline;

  /// First paragraph of the About page description, addressing students.
  ///
  /// In en, this message translates to:
  /// **'NetLearn is a computer networking learning platform designed to help students learn networking concepts through structured learning materials, digital reading, learning videos, and assessments.'**
  String get aboutNetLearnBody;

  /// Second paragraph of the About page description, addressing lecturers.
  ///
  /// In en, this message translates to:
  /// **'The platform also supports lecturers in managing learning materials and organizing learning resources in one place.'**
  String get aboutNetLearnBodyLecturers;

  /// Release-status badge on the About page hero card.
  ///
  /// In en, this message translates to:
  /// **'Release'**
  String get aboutReleaseBadge;

  /// Badge next to the version line while the app is not released.
  ///
  /// In en, this message translates to:
  /// **'Under Development'**
  String get aboutUnderDevelopmentBadge;

  /// Short note under the version block on the About page.
  ///
  /// In en, this message translates to:
  /// **'The application has been officially released and is ready to use.'**
  String get aboutPreReleaseNote;

  /// No description provided for @aboutVersion.
  ///
  /// In en, this message translates to:
  /// **'Version 1.0.0'**
  String get aboutVersion;

  /// Section heading above the six feature rows on the About page.
  ///
  /// In en, this message translates to:
  /// **'Key Features'**
  String get keyFeaturesTitle;

  /// No description provided for @aboutFeatureMaterialsTitle.
  ///
  /// In en, this message translates to:
  /// **'Learning Materials'**
  String get aboutFeatureMaterialsTitle;

  /// No description provided for @aboutFeatureMaterialsDescription.
  ///
  /// In en, this message translates to:
  /// **'Access structured computer networking lessons.'**
  String get aboutFeatureMaterialsDescription;

  /// No description provided for @aboutFeatureReadingTitle.
  ///
  /// In en, this message translates to:
  /// **'Digital Reading'**
  String get aboutFeatureReadingTitle;

  /// No description provided for @aboutFeatureReadingDescription.
  ///
  /// In en, this message translates to:
  /// **'Study networking topics through the material reader.'**
  String get aboutFeatureReadingDescription;

  /// No description provided for @aboutFeatureVideosTitle.
  ///
  /// In en, this message translates to:
  /// **'Learning Videos'**
  String get aboutFeatureVideosTitle;

  /// No description provided for @aboutFeatureVideosDescription.
  ///
  /// In en, this message translates to:
  /// **'Access available supporting learning videos.'**
  String get aboutFeatureVideosDescription;

  /// No description provided for @aboutFeatureAssessmentTitle.
  ///
  /// In en, this message translates to:
  /// **'Assessment'**
  String get aboutFeatureAssessmentTitle;

  /// No description provided for @aboutFeatureAssessmentDescription.
  ///
  /// In en, this message translates to:
  /// **'Complete Pretest and Posttest activities to evaluate understanding.'**
  String get aboutFeatureAssessmentDescription;

  /// No description provided for @aboutFeatureProgressTitle.
  ///
  /// In en, this message translates to:
  /// **'Learning Progress'**
  String get aboutFeatureProgressTitle;

  /// No description provided for @aboutFeatureProgressDescription.
  ///
  /// In en, this message translates to:
  /// **'Review your progress through the available learning activities.'**
  String get aboutFeatureProgressDescription;

  /// No description provided for @aboutFeatureLecturerTitle.
  ///
  /// In en, this message translates to:
  /// **'Lecturer Material Management'**
  String get aboutFeatureLecturerTitle;

  /// No description provided for @aboutFeatureLecturerDescription.
  ///
  /// In en, this message translates to:
  /// **'Help lecturers create, edit, and manage learning materials.'**
  String get aboutFeatureLecturerDescription;

  /// Section heading above the three download resource cards.
  ///
  /// In en, this message translates to:
  /// **'Download Resources'**
  String get downloadResourcesTitle;

  /// No description provided for @downloadMarkerTitle.
  ///
  /// In en, this message translates to:
  /// **'Download Marker'**
  String get downloadMarkerTitle;

  /// No description provided for @downloadMarkerDescription.
  ///
  /// In en, this message translates to:
  /// **'Download markers provided for supported Augmented Reality learning activities in NetLearn.'**
  String get downloadMarkerDescription;

  /// No description provided for @downloadMaterialsTitle.
  ///
  /// In en, this message translates to:
  /// **'Download Materials'**
  String get downloadMaterialsTitle;

  /// No description provided for @downloadMaterialsDescription.
  ///
  /// In en, this message translates to:
  /// **'Download the NetLearn computer networking course material book in PDF format.'**
  String get downloadMaterialsDescription;

  /// No description provided for @downloadManualsTitle.
  ///
  /// In en, this message translates to:
  /// **'Download Manual Books'**
  String get downloadManualsTitle;

  /// No description provided for @downloadManualsDescription.
  ///
  /// In en, this message translates to:
  /// **'Access the NetLearn user guides explaining how to use the application\'s main features according to the available user roles.'**
  String get downloadManualsDescription;

  /// Badge on download cards whose resource file does not exist yet.
  ///
  /// In en, this message translates to:
  /// **'Coming Soon'**
  String get downloadComingSoon;

  /// Status line on download cards without a real file or destination.
  ///
  /// In en, this message translates to:
  /// **'Not Available Yet'**
  String get notAvailableYet;

  /// Label of the (inactive) download button on each resource card.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get downloadGeneric;

  /// Badge on download cards whose PDF file is bundled in the app.
  ///
  /// In en, this message translates to:
  /// **'PDF'**
  String get downloadPdfBadge;

  /// Snackbar after a bundled About PDF is downloaded.
  ///
  /// In en, this message translates to:
  /// **'PDF downloaded.'**
  String get downloadSucceeded;

  /// Snackbar when a bundled About PDF fails to download; raw errors never surface because they can leak the asset path.
  ///
  /// In en, this message translates to:
  /// **'Could not download the PDF. Please try again.'**
  String get downloadFailed;

  /// No description provided for @viewAllNotifications.
  ///
  /// In en, this message translates to:
  /// **'View All Notifications'**
  String get viewAllNotifications;

  /// Overall completion line on the student dashboard summary card.
  ///
  /// In en, this message translates to:
  /// **'{completed}/{total} · Components completed'**
  String componentsCompletedOf(int completed, int total);

  /// No description provided for @componentPretestSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Check your understanding before learning.'**
  String get componentPretestSubtitle;

  /// No description provided for @componentTapToOpen.
  ///
  /// In en, this message translates to:
  /// **'Tap to open'**
  String get componentTapToOpen;

  /// No description provided for @componentCompletePretestFirst.
  ///
  /// In en, this message translates to:
  /// **'Complete Pretest first.'**
  String get componentCompletePretestFirst;

  /// No description provided for @componentPosttestSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Evaluate your understanding after all modules.'**
  String get componentPosttestSubtitle;

  /// No description provided for @componentCompleteAllModules.
  ///
  /// In en, this message translates to:
  /// **'Complete all modules first.'**
  String get componentCompleteAllModules;

  /// Greeting shown on the lecturer dashboard hero. The {name} placeholder is replaced with the lecturer's actual name.
  ///
  /// In en, this message translates to:
  /// **'Hello, {name} 👋'**
  String lecturerGreeting(String name);

  /// No description provided for @lecturerSpaceHeading.
  ///
  /// In en, this message translates to:
  /// **'Teaching workspace'**
  String get lecturerSpaceHeading;

  /// No description provided for @shortcutManageMaterials.
  ///
  /// In en, this message translates to:
  /// **'Manage Materials'**
  String get shortcutManageMaterials;

  /// No description provided for @shortcutManageMaterialsHint.
  ///
  /// In en, this message translates to:
  /// **'12 materials'**
  String get shortcutManageMaterialsHint;

  /// No description provided for @assignment.
  ///
  /// In en, this message translates to:
  /// **'Assignments'**
  String get assignment;

  /// No description provided for @shortcutAssignmentHint.
  ///
  /// In en, this message translates to:
  /// **'Pretest & Post Test'**
  String get shortcutAssignmentHint;

  /// No description provided for @shortcutManageQuestions.
  ///
  /// In en, this message translates to:
  /// **'Manage Questions'**
  String get shortcutManageQuestions;

  /// No description provided for @shortcutManageQuestionsHint.
  ///
  /// In en, this message translates to:
  /// **'Question bank'**
  String get shortcutManageQuestionsHint;

  /// No description provided for @shortcutManageTasks.
  ///
  /// In en, this message translates to:
  /// **'Manage Tasks'**
  String get shortcutManageTasks;

  /// No description provided for @shortcutManageTasksHint.
  ///
  /// In en, this message translates to:
  /// **'Tasks & submissions'**
  String get shortcutManageTasksHint;

  /// No description provided for @shortcutLecturerProfile.
  ///
  /// In en, this message translates to:
  /// **'Lecturer Profile'**
  String get shortcutLecturerProfile;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'This feature is coming soon.'**
  String get comingSoon;

  /// No description provided for @recentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent Activity'**
  String get recentActivity;

  /// No description provided for @recentNotifications.
  ///
  /// In en, this message translates to:
  /// **'Recent Notifications'**
  String get recentNotifications;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get noNotifications;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @announcements.
  ///
  /// In en, this message translates to:
  /// **'Announcements'**
  String get announcements;

  /// No description provided for @reminders.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get reminders;

  /// No description provided for @noAnnouncements.
  ///
  /// In en, this message translates to:
  /// **'No announcements yet'**
  String get noAnnouncements;

  /// No description provided for @noAnnouncementsMessage.
  ///
  /// In en, this message translates to:
  /// **'Announcements published by your lecturer will appear here.'**
  String get noAnnouncementsMessage;

  /// No description provided for @noReminders.
  ///
  /// In en, this message translates to:
  /// **'No upcoming deadlines'**
  String get noReminders;

  /// No description provided for @noRemindersMessage.
  ///
  /// In en, this message translates to:
  /// **'Reminders appear when an assessment is pending or a deadline is approaching.'**
  String get noRemindersMessage;

  /// No description provided for @assessmentsCompleted.
  ///
  /// In en, this message translates to:
  /// **'Assessments completed'**
  String get assessmentsCompleted;

  /// No description provided for @assessmentsIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Assessments not complete'**
  String get assessmentsIncomplete;

  /// No description provided for @averageAvailableScore.
  ///
  /// In en, this message translates to:
  /// **'Average available score'**
  String get averageAvailableScore;

  /// No description provided for @backToStudentList.
  ///
  /// In en, this message translates to:
  /// **'Back to Student List'**
  String get backToStudentList;

  /// No description provided for @lecturerNoRemindersMessage.
  ///
  /// In en, this message translates to:
  /// **'All students have completed the Pretest and Posttest.'**
  String get lecturerNoRemindersMessage;

  /// No description provided for @noAssessmentHistory.
  ///
  /// In en, this message translates to:
  /// **'No assessment history yet. Complete your first assessment to see its result here.'**
  String get noAssessmentHistory;

  /// No description provided for @noStudentsFound.
  ///
  /// In en, this message translates to:
  /// **'No students found.'**
  String get noStudentsFound;

  /// No description provided for @reminderNotCompleted.
  ///
  /// In en, this message translates to:
  /// **'Not completed'**
  String get reminderNotCompleted;

  /// No description provided for @scoreTabEmpty.
  ///
  /// In en, this message translates to:
  /// **'No student data yet.'**
  String get scoreTabEmpty;

  /// No description provided for @searchStudentsHint.
  ///
  /// In en, this message translates to:
  /// **'Search name or student ID'**
  String get searchStudentsHint;

  /// No description provided for @studentListIntro.
  ///
  /// In en, this message translates to:
  /// **'Select a student to view their Pretest and Posttest scores.'**
  String get studentListIntro;

  /// No description provided for @studentScoreHistoryIntro.
  ///
  /// In en, this message translates to:
  /// **'Pretest and Posttest score history.'**
  String get studentScoreHistoryIntro;

  /// No description provided for @viewScoreSummary.
  ///
  /// In en, this message translates to:
  /// **'View Score Recap'**
  String get viewScoreSummary;

  /// No description provided for @notificationUnread.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get notificationUnread;

  /// No description provided for @notificationRead.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get notificationRead;

  /// No description provided for @notificationJustNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get notificationJustNow;

  /// No description provided for @notificationMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} minutes ago'**
  String notificationMinutesAgo(Object count);

  /// No description provided for @notificationHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} hours ago'**
  String notificationHoursAgo(Object count);

  /// No description provided for @notificationDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} days ago'**
  String notificationDaysAgo(Object count);

  /// No description provided for @notificationReadSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save the read status.'**
  String get notificationReadSaveFailed;

  /// No description provided for @manageAnnouncements.
  ///
  /// In en, this message translates to:
  /// **'Manage Announcements'**
  String get manageAnnouncements;

  /// No description provided for @createAnnouncement.
  ///
  /// In en, this message translates to:
  /// **'Create Announcement'**
  String get createAnnouncement;

  /// No description provided for @editAnnouncement.
  ///
  /// In en, this message translates to:
  /// **'Edit Announcement'**
  String get editAnnouncement;

  /// No description provided for @announcementTitle.
  ///
  /// In en, this message translates to:
  /// **'Announcement Title'**
  String get announcementTitle;

  /// No description provided for @announcementTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Enter a title for the announcement'**
  String get announcementTitleHint;

  /// No description provided for @announcementContent.
  ///
  /// In en, this message translates to:
  /// **'Announcement Content'**
  String get announcementContent;

  /// No description provided for @announcementContentHint.
  ///
  /// In en, this message translates to:
  /// **'Write the announcement details here'**
  String get announcementContentHint;

  /// No description provided for @recipientScope.
  ///
  /// In en, this message translates to:
  /// **'Recipient Scope'**
  String get recipientScope;

  /// No description provided for @allStudents.
  ///
  /// In en, this message translates to:
  /// **'All Students'**
  String get allStudents;

  /// No description provided for @saveAsDraft.
  ///
  /// In en, this message translates to:
  /// **'Save as Draft'**
  String get saveAsDraft;

  /// No description provided for @publishAnnouncement.
  ///
  /// In en, this message translates to:
  /// **'Publish Announcement'**
  String get publishAnnouncement;

  /// No description provided for @saveDraft.
  ///
  /// In en, this message translates to:
  /// **'Save Draft'**
  String get saveDraft;

  /// No description provided for @announcementDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get announcementDraft;

  /// No description provided for @announcementPublished.
  ///
  /// In en, this message translates to:
  /// **'Published'**
  String get announcementPublished;

  /// No description provided for @deleteAnnouncement.
  ///
  /// In en, this message translates to:
  /// **'Delete Announcement'**
  String get deleteAnnouncement;

  /// No description provided for @deleteAnnouncementConfirm.
  ///
  /// In en, this message translates to:
  /// **'This announcement will be permanently removed. Are you sure?'**
  String get deleteAnnouncementConfirm;

  /// No description provided for @announcementDeleted.
  ///
  /// In en, this message translates to:
  /// **'Announcement deleted.'**
  String get announcementDeleted;

  /// No description provided for @announcementCreated.
  ///
  /// In en, this message translates to:
  /// **'Announcement created.'**
  String get announcementCreated;

  /// No description provided for @announcementUpdated.
  ///
  /// In en, this message translates to:
  /// **'Announcement updated.'**
  String get announcementUpdated;

  /// No description provided for @announcementPublishedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Announcement published.'**
  String get announcementPublishedSuccess;

  /// No description provided for @announcementUnpublished.
  ///
  /// In en, this message translates to:
  /// **'Announcement unpublished.'**
  String get announcementUnpublished;

  /// No description provided for @announcementSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save the announcement.'**
  String get announcementSaveFailed;

  /// No description provided for @titleRequired.
  ///
  /// In en, this message translates to:
  /// **'Title is required'**
  String get titleRequired;

  /// No description provided for @contentRequired.
  ///
  /// In en, this message translates to:
  /// **'Content is required'**
  String get contentRequired;

  /// No description provided for @reminderDueSoon.
  ///
  /// In en, this message translates to:
  /// **'Due soon'**
  String get reminderDueSoon;

  /// No description provided for @reminderDueTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Due tomorrow'**
  String get reminderDueTomorrow;

  /// No description provided for @reminderOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get reminderOverdue;

  /// No description provided for @daysLeft.
  ///
  /// In en, this message translates to:
  /// **'{count} days left'**
  String daysLeft(Object count);

  /// No description provided for @hoursLeft.
  ///
  /// In en, this message translates to:
  /// **'{count} hours left'**
  String hoursLeft(Object count);

  /// No description provided for @minutesLeft.
  ///
  /// In en, this message translates to:
  /// **'{count} minutes left'**
  String minutesLeft(Object count);

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewDetails;

  /// No description provided for @markAsReadAction.
  ///
  /// In en, this message translates to:
  /// **'Mark as Read'**
  String get markAsReadAction;

  /// No description provided for @by.
  ///
  /// In en, this message translates to:
  /// **'by'**
  String get by;

  /// No description provided for @assessments.
  ///
  /// In en, this message translates to:
  /// **'Assessments'**
  String get assessments;

  /// No description provided for @addTask.
  ///
  /// In en, this message translates to:
  /// **'Add Assessment'**
  String get addTask;

  /// No description provided for @editTask.
  ///
  /// In en, this message translates to:
  /// **'Edit Task'**
  String get editTask;

  /// No description provided for @editTaskAndQuestions.
  ///
  /// In en, this message translates to:
  /// **'Edit Task & Questions'**
  String get editTaskAndQuestions;

  /// No description provided for @viewDetail.
  ///
  /// In en, this message translates to:
  /// **'View Detail'**
  String get viewDetail;

  /// No description provided for @taskDetails.
  ///
  /// In en, this message translates to:
  /// **'Task Details'**
  String get taskDetails;

  /// No description provided for @taskCreated.
  ///
  /// In en, this message translates to:
  /// **'Task created.'**
  String get taskCreated;

  /// No description provided for @taskUpdated.
  ///
  /// In en, this message translates to:
  /// **'Task updated.'**
  String get taskUpdated;

  /// No description provided for @taskPublished.
  ///
  /// In en, this message translates to:
  /// **'Task published.'**
  String get taskPublished;

  /// No description provided for @taskUnpublished.
  ///
  /// In en, this message translates to:
  /// **'Task unpublished.'**
  String get taskUnpublished;

  /// No description provided for @taskSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save the task.'**
  String get taskSaveFailed;

  /// No description provided for @taskNotFound.
  ///
  /// In en, this message translates to:
  /// **'Task not found.'**
  String get taskNotFound;

  /// No description provided for @taskIdMissing.
  ///
  /// In en, this message translates to:
  /// **'Task ID not found.'**
  String get taskIdMissing;

  /// No description provided for @noTasks.
  ///
  /// In en, this message translates to:
  /// **'No tasks yet'**
  String get noTasks;

  /// No description provided for @noTasksDescription.
  ///
  /// In en, this message translates to:
  /// **'Create your first task to get started.'**
  String get noTasksDescription;

  /// No description provided for @basicInformation.
  ///
  /// In en, this message translates to:
  /// **'Basic Information'**
  String get basicInformation;

  /// No description provided for @timingDeadline.
  ///
  /// In en, this message translates to:
  /// **'Timing & Deadline'**
  String get timingDeadline;

  /// No description provided for @taskTitle.
  ///
  /// In en, this message translates to:
  /// **'Task Title'**
  String get taskTitle;

  /// No description provided for @taskTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Enter task title'**
  String get taskTitleHint;

  /// No description provided for @instructions.
  ///
  /// In en, this message translates to:
  /// **'Instructions'**
  String get instructions;

  /// No description provided for @instructionsHint.
  ///
  /// In en, this message translates to:
  /// **'Instructions for students'**
  String get instructionsHint;

  /// No description provided for @moduleHint.
  ///
  /// In en, this message translates to:
  /// **'Select a module'**
  String get moduleHint;

  /// No description provided for @standaloneTask.
  ///
  /// In en, this message translates to:
  /// **'Standalone Task'**
  String get standaloneTask;

  /// No description provided for @timeLimitMinutes.
  ///
  /// In en, this message translates to:
  /// **'Time Limit (minutes)'**
  String get timeLimitMinutes;

  /// No description provided for @timeLimitHelper.
  ///
  /// In en, this message translates to:
  /// **'0 means no time limit. Max 180 minutes.'**
  String get timeLimitHelper;

  /// No description provided for @timeLimitInvalid.
  ///
  /// In en, this message translates to:
  /// **'Time limit must be between 0 and 180 minutes'**
  String get timeLimitInvalid;

  /// No description provided for @timeLimitShort.
  ///
  /// In en, this message translates to:
  /// **'limit'**
  String get timeLimitShort;

  /// No description provided for @deadlineHint.
  ///
  /// In en, this message translates to:
  /// **'Select deadline (optional)'**
  String get deadlineHint;

  /// No description provided for @deadlineInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid deadline format'**
  String get deadlineInvalid;

  /// No description provided for @createTask.
  ///
  /// In en, this message translates to:
  /// **'Create Task'**
  String get createTask;

  /// No description provided for @noDescription.
  ///
  /// In en, this message translates to:
  /// **'No description provided'**
  String get noDescription;

  /// No description provided for @noInstructions.
  ///
  /// In en, this message translates to:
  /// **'No instructions provided'**
  String get noInstructions;

  /// No description provided for @submitted.
  ///
  /// In en, this message translates to:
  /// **'Submitted'**
  String get submitted;

  /// No description provided for @submissionRate.
  ///
  /// In en, this message translates to:
  /// **'Submission rate:'**
  String get submissionRate;

  /// No description provided for @taskResults.
  ///
  /// In en, this message translates to:
  /// **'Task Results'**
  String get taskResults;

  /// No description provided for @questionImageHint.
  ///
  /// In en, this message translates to:
  /// **'Optional image URL'**
  String get questionImageHint;

  /// No description provided for @assessmentPublishedTitle.
  ///
  /// In en, this message translates to:
  /// **'Assessment Published'**
  String get assessmentPublishedTitle;

  /// No description provided for @assessmentUnpublishedTitle.
  ///
  /// In en, this message translates to:
  /// **'Assessment Unpublished'**
  String get assessmentUnpublishedTitle;

  /// No description provided for @january.
  ///
  /// In en, this message translates to:
  /// **'January'**
  String get january;

  /// No description provided for @february.
  ///
  /// In en, this message translates to:
  /// **'February'**
  String get february;

  /// No description provided for @march.
  ///
  /// In en, this message translates to:
  /// **'March'**
  String get march;

  /// No description provided for @april.
  ///
  /// In en, this message translates to:
  /// **'April'**
  String get april;

  /// No description provided for @may.
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get may;

  /// No description provided for @june.
  ///
  /// In en, this message translates to:
  /// **'June'**
  String get june;

  /// No description provided for @july.
  ///
  /// In en, this message translates to:
  /// **'July'**
  String get july;

  /// No description provided for @august.
  ///
  /// In en, this message translates to:
  /// **'August'**
  String get august;

  /// No description provided for @september.
  ///
  /// In en, this message translates to:
  /// **'September'**
  String get september;

  /// No description provided for @october.
  ///
  /// In en, this message translates to:
  /// **'October'**
  String get october;

  /// No description provided for @november.
  ///
  /// In en, this message translates to:
  /// **'November'**
  String get november;

  /// No description provided for @december.
  ///
  /// In en, this message translates to:
  /// **'December'**
  String get december;

  /// No description provided for @multipleChoice.
  ///
  /// In en, this message translates to:
  /// **'Multiple Choice'**
  String get multipleChoice;

  /// No description provided for @backToAssessments.
  ///
  /// In en, this message translates to:
  /// **'Back to Assessments'**
  String get backToAssessments;

  /// No description provided for @failedToLoadQuestions.
  ///
  /// In en, this message translates to:
  /// **'Failed to load questions'**
  String get failedToLoadQuestions;

  /// No description provided for @submissionRateUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Student count unavailable'**
  String get submissionRateUnavailable;

  /// No description provided for @moveUp.
  ///
  /// In en, this message translates to:
  /// **'Move up'**
  String get moveUp;

  /// No description provided for @moveDown.
  ///
  /// In en, this message translates to:
  /// **'Move down'**
  String get moveDown;

  /// No description provided for @department.
  ///
  /// In en, this message translates to:
  /// **'Department'**
  String get department;

  /// No description provided for @informaticsEngineering.
  ///
  /// In en, this message translates to:
  /// **'Informatics Engineering'**
  String get informaticsEngineering;

  /// No description provided for @informationTechnologyEducation.
  ///
  /// In en, this message translates to:
  /// **'Information Technology Education'**
  String get informationTechnologyEducation;

  /// No description provided for @lecturerRoleProgram.
  ///
  /// In en, this message translates to:
  /// **'Lecturer S1 Information Technology Education'**
  String get lecturerRoleProgram;

  /// No description provided for @materialPdf.
  ///
  /// In en, this message translates to:
  /// **'Material PDF (optional)'**
  String get materialPdf;

  /// No description provided for @uploadPdf.
  ///
  /// In en, this message translates to:
  /// **'Upload PDF'**
  String get uploadPdf;

  /// No description provided for @replacePdf.
  ///
  /// In en, this message translates to:
  /// **'Replace PDF'**
  String get replacePdf;

  /// No description provided for @removePdf.
  ///
  /// In en, this message translates to:
  /// **'Remove PDF'**
  String get removePdf;

  /// No description provided for @pdfUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading PDF...'**
  String get pdfUploading;

  /// No description provided for @pdfUploaded.
  ///
  /// In en, this message translates to:
  /// **'PDF uploaded.'**
  String get pdfUploaded;

  /// No description provided for @pdfRemoved.
  ///
  /// In en, this message translates to:
  /// **'PDF removed.'**
  String get pdfRemoved;

  /// No description provided for @pdfUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not upload the PDF.'**
  String get pdfUploadFailed;

  /// No description provided for @pdfTooLarge.
  ///
  /// In en, this message translates to:
  /// **'PDF is too large (max 20 MB).'**
  String get pdfTooLarge;

  /// No description provided for @pdfInvalidType.
  ///
  /// In en, this message translates to:
  /// **'Please choose a PDF file.'**
  String get pdfInvalidType;

  /// No description provided for @noPdf.
  ///
  /// In en, this message translates to:
  /// **'No PDF uploaded'**
  String get noPdf;

  /// No description provided for @openPdfFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open the PDF.'**
  String get openPdfFailed;

  /// No description provided for @accountEmail.
  ///
  /// In en, this message translates to:
  /// **'Account Email'**
  String get accountEmail;

  /// No description provided for @answerKeysConfigured.
  ///
  /// In en, this message translates to:
  /// **'{answered}/{total} Answer Keys Configured'**
  String answerKeysConfigured(int answered, int total);

  /// No description provided for @answerOptionsAndKey.
  ///
  /// In en, this message translates to:
  /// **'Options & Answer Key'**
  String get answerOptionsAndKey;

  /// No description provided for @assessmentQuestions.
  ///
  /// In en, this message translates to:
  /// **'Assessment Questions'**
  String get assessmentQuestions;

  /// No description provided for @backToSecurity.
  ///
  /// In en, this message translates to:
  /// **'Back to Security'**
  String get backToSecurity;

  /// No description provided for @changeEmail.
  ///
  /// In en, this message translates to:
  /// **'Change Email'**
  String get changeEmail;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @changePasswordHint.
  ///
  /// In en, this message translates to:
  /// **'You can change your password here'**
  String get changePasswordHint;

  /// No description provided for @confirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get confirmNewPassword;

  /// No description provided for @confirmNewPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Re-enter your new password'**
  String get confirmNewPasswordHint;

  /// No description provided for @drafts.
  ///
  /// In en, this message translates to:
  /// **'Drafts'**
  String get drafts;

  /// No description provided for @forgotPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your email to receive a reset code'**
  String get forgotPasswordHint;

  /// No description provided for @imageUrlHint.
  ///
  /// In en, this message translates to:
  /// **'https://... (optional)'**
  String get imageUrlHint;

  /// No description provided for @invalidOtp.
  ///
  /// In en, this message translates to:
  /// **'Invalid code. Please try again.'**
  String get invalidOtp;

  /// No description provided for @manageAnnouncementsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage your announcements'**
  String get manageAnnouncementsSubtitle;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// No description provided for @newPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your new password'**
  String get newPasswordHint;

  /// Label for the current password field on the change password form.
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get currentPassword;

  /// Helper text above the change password fields.
  ///
  /// In en, this message translates to:
  /// **'Use a strong password that you do not use on other accounts.'**
  String get strongPasswordHint;

  /// Submit button on the change password form.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @noAnnouncementsLecturerMessage.
  ///
  /// In en, this message translates to:
  /// **'No announcements yet'**
  String get noAnnouncementsLecturerMessage;

  /// No description provided for @noStudents.
  ///
  /// In en, this message translates to:
  /// **'No students yet'**
  String get noStudents;

  /// No description provided for @noStudentsDescription.
  ///
  /// In en, this message translates to:
  /// **'Students with the student role will appear here.'**
  String get noStudentsDescription;

  /// No description provided for @nim.
  ///
  /// In en, this message translates to:
  /// **'NIM'**
  String get nim;

  /// No description provided for @posttestScore.
  ///
  /// In en, this message translates to:
  /// **'Posttest Score'**
  String get posttestScore;

  /// No description provided for @pretestScore.
  ///
  /// In en, this message translates to:
  /// **'Pretest Score'**
  String get pretestScore;

  /// No description provided for @scoreNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Not available'**
  String get scoreNotAvailable;

  /// No description provided for @scoreScaleHint.
  ///
  /// In en, this message translates to:
  /// **'Scores are on a 0–100 scale. — means the assessment has not been completed.'**
  String get scoreScaleHint;

  /// No description provided for @scoreTableSemantics.
  ///
  /// In en, this message translates to:
  /// **'Student score table'**
  String get scoreTableSemantics;

  /// No description provided for @studentName.
  ///
  /// In en, this message translates to:
  /// **'Student Name'**
  String get studentName;

  /// No description provided for @otpCode.
  ///
  /// In en, this message translates to:
  /// **'Verification Code'**
  String get otpCode;

  /// No description provided for @otpCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Enter the code sent to your email'**
  String get otpCodeHint;

  /// No description provided for @otpSentTitle.
  ///
  /// In en, this message translates to:
  /// **'Check Your Email'**
  String get otpSentTitle;

  /// No description provided for @otpSentBody.
  ///
  /// In en, this message translates to:
  /// **'We sent a verification code to {submittedEmail}'**
  String otpSentBody(String submittedEmail);

  /// No description provided for @passwordChangeNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Password change is not available in demo mode'**
  String get passwordChangeNotAvailable;

  /// No description provided for @passwordDemoNote.
  ///
  /// In en, this message translates to:
  /// **'This is a demo account. Password changes are disabled.'**
  String get passwordDemoNote;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get passwordTooShort;

  /// No description provided for @passwordUpdated.
  ///
  /// In en, this message translates to:
  /// **'Password Updated'**
  String get passwordUpdated;

  /// No description provided for @passwordUpdatedBody.
  ///
  /// In en, this message translates to:
  /// **'Your password has been updated successfully.'**
  String get passwordUpdatedBody;

  /// No description provided for @passwordUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update password. Please try again.'**
  String get passwordUpdateFailed;

  /// No description provided for @pdfUploadHint.
  ///
  /// In en, this message translates to:
  /// **'Upload a PDF file'**
  String get pdfUploadHint;

  /// No description provided for @preferencesAndAccount.
  ///
  /// In en, this message translates to:
  /// **'Preferences & Account'**
  String get preferencesAndAccount;

  /// No description provided for @questionNotFound.
  ///
  /// In en, this message translates to:
  /// **'This question is no longer part of this assessment.'**
  String get questionNotFound;

  /// No description provided for @resendCode.
  ///
  /// In en, this message translates to:
  /// **'Resend Code'**
  String get resendCode;

  /// No description provided for @resendCodeSent.
  ///
  /// In en, this message translates to:
  /// **'A new code has been sent to your email.'**
  String get resendCodeSent;

  /// No description provided for @savePassword.
  ///
  /// In en, this message translates to:
  /// **'Save Password'**
  String get savePassword;

  /// No description provided for @saveQuestion.
  ///
  /// In en, this message translates to:
  /// **'Save Question'**
  String get saveQuestion;

  /// No description provided for @scoreOverview.
  ///
  /// In en, this message translates to:
  /// **'Score Recap'**
  String get scoreOverview;

  /// No description provided for @searchStudents.
  ///
  /// In en, this message translates to:
  /// **'Search Students'**
  String get searchStudents;

  /// No description provided for @securityFooterNote.
  ///
  /// In en, this message translates to:
  /// **'Your security settings are managed by the administrator.'**
  String get securityFooterNote;

  /// No description provided for @sendOtpCode.
  ///
  /// In en, this message translates to:
  /// **'Send Code'**
  String get sendOtpCode;

  /// No description provided for @setNewPasswordHeading.
  ///
  /// In en, this message translates to:
  /// **'Set New Password'**
  String get setNewPasswordHeading;

  /// No description provided for @setNewPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a strong password for your account'**
  String get setNewPasswordSubtitle;

  /// No description provided for @studentData.
  ///
  /// In en, this message translates to:
  /// **'Student Data'**
  String get studentData;

  /// No description provided for @studentDataOverview.
  ///
  /// In en, this message translates to:
  /// **'Student Data Overview'**
  String get studentDataOverview;

  /// No description provided for @totalAnnouncements.
  ///
  /// In en, this message translates to:
  /// **'Total Announcements'**
  String get totalAnnouncements;

  /// No description provided for @verifyCode.
  ///
  /// In en, this message translates to:
  /// **'Verify Code'**
  String get verifyCode;

  /// No description provided for @optionLabel.
  ///
  /// In en, this message translates to:
  /// **'Option {letter}'**
  String optionLabel(String letter);

  /// Watch and learn subtitle
  ///
  /// In en, this message translates to:
  /// **'Watch & learn'**
  String get watchAndLearn;

  /// Network practice subtitle
  ///
  /// In en, this message translates to:
  /// **'Network practice'**
  String get networkPractice;

  /// Account and settings subtitle
  ///
  /// In en, this message translates to:
  /// **'Account & settings'**
  String get accountSettings;

  /// No video available message
  ///
  /// In en, this message translates to:
  /// **'No video available yet.'**
  String get noVideoAvailable;

  /// Video list header subtitle
  ///
  /// In en, this message translates to:
  /// **'{count} modules · Choose a video to start learning'**
  String videoListSubtitle(int count);

  /// Video card subtitle
  ///
  /// In en, this message translates to:
  /// **'View learning video'**
  String get videoListWatchVideo;

  /// No video available description
  ///
  /// In en, this message translates to:
  /// **'No learning videos have been published yet.'**
  String get noVideoAvailableMessage;

  /// Download student data as CSV
  ///
  /// In en, this message translates to:
  /// **'Download CSV'**
  String get downloadCsv;

  /// CSV export success message
  ///
  /// In en, this message translates to:
  /// **'CSV downloaded successfully.'**
  String get csvExported;

  /// CSV export error message
  ///
  /// In en, this message translates to:
  /// **'Failed to export CSV. Please try again.'**
  String get csvFailed;

  /// Video card badge when the module has a usable video link
  ///
  /// In en, this message translates to:
  /// **'Video link available'**
  String get videoLinkAvailable;

  /// Video card badge when the module has no usable video link
  ///
  /// In en, this message translates to:
  /// **'Video not available yet'**
  String get videoLinkUnavailable;

  /// Splash screen tagline
  ///
  /// In en, this message translates to:
  /// **'LEARN. CONNECT. GROW.'**
  String get splashTagline;

  /// Accessibility label for the splash loading indicator
  ///
  /// In en, this message translates to:
  /// **'Opening the application'**
  String get splashOpening;

  /// Small heading above the onboarding step indicator
  ///
  /// In en, this message translates to:
  /// **'Your networking journey'**
  String get onboardingJourneyLabel;

  /// Total page count after the active onboarding page number, e.g. "01 / 03".
  ///
  /// In en, this message translates to:
  /// **' / 03'**
  String get onboardingPageNumberSuffix;

  /// Onboarding screen 1 headline
  ///
  /// In en, this message translates to:
  /// **'Learn Networking, Connect Everything.'**
  String get onboardingIntroTitle;

  /// Onboarding screen 1 description
  ///
  /// In en, this message translates to:
  /// **'Build your understanding of computer networks through guided materials, learning videos, and assessments.'**
  String get onboardingIntroBody;

  /// Onboarding screen 2 headline
  ///
  /// In en, this message translates to:
  /// **'Understand the Fundamentals.'**
  String get onboardingModulesTitle;

  /// Onboarding screen 2 description
  ///
  /// In en, this message translates to:
  /// **'Explore the core concepts of computer networking, one step at a time.'**
  String get onboardingModulesBody;

  /// Onboarding screen 3 headline
  ///
  /// In en, this message translates to:
  /// **'Turn Knowledge into Practice.'**
  String get onboardingPracticeTitle;

  /// Onboarding screen 3 description
  ///
  /// In en, this message translates to:
  /// **'Study materials, watch learning videos, complete assessments, and review your results.'**
  String get onboardingPracticeBody;

  /// Shown when recording onboarding completion on the account fails, e.g. without a network
  ///
  /// In en, this message translates to:
  /// **'Could not save your onboarding status. It may appear again on your next sign-in.'**
  String get onboardingPersistFailed;

  /// Onboarding module card: Dasar-Dasar Jaringan
  ///
  /// In en, this message translates to:
  /// **'Computer Networking Fundamentals'**
  String get onboardingModuleFundamentals;

  /// Onboarding module card: Perangkat Jaringan
  ///
  /// In en, this message translates to:
  /// **'Network Devices'**
  String get onboardingModuleDevices;

  /// Onboarding module card: Topologi Jaringan
  ///
  /// In en, this message translates to:
  /// **'Network Topologies'**
  String get onboardingModuleTopologies;

  /// Onboarding module card: IP Address
  ///
  /// In en, this message translates to:
  /// **'IP Address'**
  String get onboardingModuleIpAddress;

  /// Onboarding learning journey step 1 title
  ///
  /// In en, this message translates to:
  /// **'Study Materials'**
  String get journeyStudyTitle;

  /// Onboarding learning journey step 1 subtitle
  ///
  /// In en, this message translates to:
  /// **'Build your foundation'**
  String get journeyStudySubtitle;

  /// Onboarding learning journey step 2 title
  ///
  /// In en, this message translates to:
  /// **'Watch Videos'**
  String get journeyVideosTitle;

  /// Onboarding learning journey step 2 subtitle
  ///
  /// In en, this message translates to:
  /// **'See concepts in action'**
  String get journeyVideosSubtitle;

  /// Onboarding learning journey step 3 title
  ///
  /// In en, this message translates to:
  /// **'Take Assessments'**
  String get journeyAssessmentsTitle;

  /// Onboarding learning journey step 3 subtitle
  ///
  /// In en, this message translates to:
  /// **'Check your understanding'**
  String get journeyAssessmentsSubtitle;

  /// Onboarding learning journey step 4 title
  ///
  /// In en, this message translates to:
  /// **'Review Results'**
  String get journeyReviewTitle;

  /// Onboarding learning journey step 4 subtitle
  ///
  /// In en, this message translates to:
  /// **'Reflect on your learning'**
  String get journeyReviewSubtitle;

  /// Onboarding skip action
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardingSkip;

  /// Final onboarding action
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get onboardingGetStarted;

  /// Accessibility label for the onboarding progress dots
  ///
  /// In en, this message translates to:
  /// **'Onboarding progress'**
  String get onboardingProgressLabel;

  /// Accessibility description of the onboarding student scene
  ///
  /// In en, this message translates to:
  /// **'A student exploring a computer network from a laptop, connected to a router and a desktop computer'**
  String get onboardingSceneStudentLabel;

  /// Accessibility description of the onboarding networking scene
  ///
  /// In en, this message translates to:
  /// **'Computers connected through a router with Ethernet ports'**
  String get onboardingSceneNetworkLabel;

  /// No description provided for @manageClassesTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage Class'**
  String get manageClassesTitle;

  /// No description provided for @manageClassesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create, configure, and manage your classes and modules.'**
  String get manageClassesSubtitle;

  /// No description provided for @createClassTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Class'**
  String get createClassTitle;

  /// No description provided for @switchClassAction.
  ///
  /// In en, this message translates to:
  /// **'Switch Class'**
  String get switchClassAction;

  /// No description provided for @archivedClassesTitle.
  ///
  /// In en, this message translates to:
  /// **'Archived Classes'**
  String get archivedClassesTitle;

  /// No description provided for @noClassesLecturerTitle.
  ///
  /// In en, this message translates to:
  /// **'No active classes yet'**
  String get noClassesLecturerTitle;

  /// No description provided for @noClassesLecturerMessage.
  ///
  /// In en, this message translates to:
  /// **'Create your first class from the NetLearn template or start a custom class from scratch.'**
  String get noClassesLecturerMessage;

  /// No description provided for @classStatusDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get classStatusDraft;

  /// No description provided for @classStatusPublished.
  ///
  /// In en, this message translates to:
  /// **'Published'**
  String get classStatusPublished;

  /// No description provided for @classStatusArchived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get classStatusArchived;

  /// No description provided for @classOriginTemplate.
  ///
  /// In en, this message translates to:
  /// **'NetLearn Template'**
  String get classOriginTemplate;

  /// No description provided for @classOriginCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom Class'**
  String get classOriginCustom;

  /// No description provided for @classMembersCount.
  ///
  /// In en, this message translates to:
  /// **'{count} students'**
  String classMembersCount(int count);

  /// No description provided for @classModulesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} modules'**
  String classModulesCount(int count);

  /// No description provided for @classInviteCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Invite Code'**
  String get classInviteCodeLabel;

  /// No description provided for @classInviteCodeCopied.
  ///
  /// In en, this message translates to:
  /// **'Invite code copied to clipboard.'**
  String get classInviteCodeCopied;

  /// No description provided for @classManageButton.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get classManageButton;

  /// No description provided for @classNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Class Name'**
  String get classNameLabel;

  /// No description provided for @classNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Computer Networks — Class A'**
  String get classNameHint;

  /// No description provided for @classNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Class name is required'**
  String get classNameRequired;

  /// No description provided for @classDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Class Description'**
  String get classDescriptionLabel;

  /// No description provided for @classDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Short summary of class goals or schedule'**
  String get classDescriptionHint;

  /// No description provided for @classSemesterLabel.
  ///
  /// In en, this message translates to:
  /// **'Semester / Academic Period'**
  String get classSemesterLabel;

  /// No description provided for @classSemesterHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Odd 2026/2027'**
  String get classSemesterHint;

  /// No description provided for @classCreationModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Class Structure Source'**
  String get classCreationModeTitle;

  /// No description provided for @classUseTemplateTitle.
  ///
  /// In en, this message translates to:
  /// **'Use NetLearn Template'**
  String get classUseTemplateTitle;

  /// No description provided for @classUseTemplateSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Copies the 4 core modules, 5 materials, Pretest, and Posttest into your class.'**
  String get classUseTemplateSubtitle;

  /// No description provided for @classCreateCustomTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Custom Class'**
  String get classCreateCustomTitle;

  /// No description provided for @classCreateCustomSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Start with an empty class and build your own modules, materials, and assessments.'**
  String get classCreateCustomSubtitle;

  /// No description provided for @classPretestEnabledLabel.
  ///
  /// In en, this message translates to:
  /// **'Enable Pretest Gate'**
  String get classPretestEnabledLabel;

  /// No description provided for @classPretestEnabledHelper.
  ///
  /// In en, this message translates to:
  /// **'Students must submit the Pretest before unlocking Module 1.'**
  String get classPretestEnabledHelper;

  /// No description provided for @classPosttestEnabledLabel.
  ///
  /// In en, this message translates to:
  /// **'Enable Posttest Evaluation'**
  String get classPosttestEnabledLabel;

  /// No description provided for @classPosttestEnabledHelper.
  ///
  /// In en, this message translates to:
  /// **'Unlocks the final Posttest after all published modules are completed.'**
  String get classPosttestEnabledHelper;

  /// No description provided for @classLeaderboardEnabledLabel.
  ///
  /// In en, this message translates to:
  /// **'Enable Class Leaderboard'**
  String get classLeaderboardEnabledLabel;

  /// No description provided for @classLeaderboardEnabledHelper.
  ///
  /// In en, this message translates to:
  /// **'Shows ranked assessment and overall class standings to enrolled students.'**
  String get classLeaderboardEnabledHelper;

  /// No description provided for @classCreatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Class created successfully.'**
  String get classCreatedSuccess;

  /// No description provided for @classUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Class settings updated.'**
  String get classUpdatedSuccess;

  /// No description provided for @classPublishAction.
  ///
  /// In en, this message translates to:
  /// **'Publish Class'**
  String get classPublishAction;

  /// No description provided for @classArchiveAction.
  ///
  /// In en, this message translates to:
  /// **'Archive Class'**
  String get classArchiveAction;

  /// No description provided for @classRestoreAction.
  ///
  /// In en, this message translates to:
  /// **'Restore to Draft'**
  String get classRestoreAction;

  /// No description provided for @classTabModules.
  ///
  /// In en, this message translates to:
  /// **'Modules'**
  String get classTabModules;

  /// No description provided for @classTabSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings & Gates'**
  String get classTabSettings;

  /// No description provided for @classTabInviteRoster.
  ///
  /// In en, this message translates to:
  /// **'Invite & Roster'**
  String get classTabInviteRoster;

  /// No description provided for @classTabLeaderboard.
  ///
  /// In en, this message translates to:
  /// **'Leaderboard'**
  String get classTabLeaderboard;

  /// No description provided for @classAddModuleAction.
  ///
  /// In en, this message translates to:
  /// **'Add Module'**
  String get classAddModuleAction;

  /// No description provided for @classEditModuleAction.
  ///
  /// In en, this message translates to:
  /// **'Edit Module'**
  String get classEditModuleAction;

  /// No description provided for @classModuleTitleIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Module Title (Indonesian)'**
  String get classModuleTitleIdLabel;

  /// No description provided for @classModuleTitleEnLabel.
  ///
  /// In en, this message translates to:
  /// **'Module Title (English)'**
  String get classModuleTitleEnLabel;

  /// No description provided for @classModuleDescIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Description (Indonesian)'**
  String get classModuleDescIdLabel;

  /// No description provided for @classModuleDescEnLabel.
  ///
  /// In en, this message translates to:
  /// **'Description (English)'**
  String get classModuleDescEnLabel;

  /// No description provided for @classNoModulesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No modules in this class yet. Add your first module to begin.'**
  String get classNoModulesEmpty;

  /// No description provided for @classAddMaterialToModule.
  ///
  /// In en, this message translates to:
  /// **'Add Material'**
  String get classAddMaterialToModule;

  /// No description provided for @classRotateInviteAction.
  ///
  /// In en, this message translates to:
  /// **'Rotate Code'**
  String get classRotateInviteAction;

  /// No description provided for @classInviteActiveLabel.
  ///
  /// In en, this message translates to:
  /// **'Allow Joining via Invite Code'**
  String get classInviteActiveLabel;

  /// No description provided for @classRosterEmpty.
  ///
  /// In en, this message translates to:
  /// **'No students have joined this class yet.'**
  String get classRosterEmpty;

  /// No description provided for @classRemoveMemberTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove Student from Class?'**
  String get classRemoveMemberTitle;

  /// No description provided for @classRemoveMemberConfirm.
  ///
  /// In en, this message translates to:
  /// **'Their historical progress and attempt records will be preserved.'**
  String get classRemoveMemberConfirm;

  /// No description provided for @classRemoveMemberAction.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get classRemoveMemberAction;

  /// No description provided for @classPolicyChangeTitle.
  ///
  /// In en, this message translates to:
  /// **'Update Class Gate Policy?'**
  String get classPolicyChangeTitle;

  /// No description provided for @classPolicyChangeConfirm.
  ///
  /// In en, this message translates to:
  /// **'Changing Pretest, Posttest, or Leaderboard settings increments the class policy version. Students who already unlocked modules keep their unlocked status.'**
  String get classPolicyChangeConfirm;

  /// No description provided for @studentMyClassesTitle.
  ///
  /// In en, this message translates to:
  /// **'My Classes'**
  String get studentMyClassesTitle;

  /// No description provided for @studentActiveClassLabel.
  ///
  /// In en, this message translates to:
  /// **'Active Class'**
  String get studentActiveClassLabel;

  /// No description provided for @studentJoinClassAction.
  ///
  /// In en, this message translates to:
  /// **'Join Class'**
  String get studentJoinClassAction;

  /// No description provided for @studentJoinClassHint.
  ///
  /// In en, this message translates to:
  /// **'Enter 8-character invite code'**
  String get studentJoinClassHint;

  /// No description provided for @studentJoinClassSuccess.
  ///
  /// In en, this message translates to:
  /// **'Successfully joined the class!'**
  String get studentJoinClassSuccess;

  /// No description provided for @studentNoClassTitle.
  ///
  /// In en, this message translates to:
  /// **'Join a Class to Start Learning'**
  String get studentNoClassTitle;

  /// No description provided for @studentNoClassMessage.
  ///
  /// In en, this message translates to:
  /// **'Ask your lecturer for an 8-character class invite code to unlock your modules, materials, and assessments.'**
  String get studentNoClassMessage;

  /// No description provided for @studentLeaveClassAction.
  ///
  /// In en, this message translates to:
  /// **'Leave Class'**
  String get studentLeaveClassAction;

  /// No description provided for @studentLeaveClassConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to leave this class? Your historical progress will stay saved if you rejoin later.'**
  String get studentLeaveClassConfirm;

  /// No description provided for @classEmptyMaterialsMessage.
  ///
  /// In en, this message translates to:
  /// **'Your lecturer is still preparing the learning modules for this class.'**
  String get classEmptyMaterialsMessage;

  /// No description provided for @leaderboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Class Leaderboard'**
  String get leaderboardTitle;

  /// No description provided for @leaderboardOverallTab.
  ///
  /// In en, this message translates to:
  /// **'Overall Class'**
  String get leaderboardOverallTab;

  /// No description provided for @leaderboardAssessmentTab.
  ///
  /// In en, this message translates to:
  /// **'Per Assessment'**
  String get leaderboardAssessmentTab;

  /// No description provided for @leaderboardCohortFinal.
  ///
  /// In en, this message translates to:
  /// **'Final (Completed All)'**
  String get leaderboardCohortFinal;

  /// No description provided for @leaderboardCohortProvisional.
  ///
  /// In en, this message translates to:
  /// **'In Progress (Provisional)'**
  String get leaderboardCohortProvisional;

  /// No description provided for @leaderboardEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No ranked assessments yet'**
  String get leaderboardEmptyTitle;

  /// No description provided for @leaderboardEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Rankings will appear once students submit graded assessments in this class.'**
  String get leaderboardEmptyMessage;

  /// No description provided for @leaderboardFormulaNote.
  ///
  /// In en, this message translates to:
  /// **'Normalized 0–100 score · Highest valid attempt · Pretest excluded by default · Ties broken by earliest submission.'**
  String get leaderboardFormulaNote;

  /// No description provided for @leaderboardYouBadge.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get leaderboardYouBadge;

  /// No description provided for @couldNotLoadData.
  ///
  /// In en, this message translates to:
  /// **'Could not load data.'**
  String get couldNotLoadData;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// Accessibility description of the onboarding learning journey scene
  ///
  /// In en, this message translates to:
  /// **'A laptop, assessment sheets, and result charts connected in one learning journey'**
  String get onboardingSceneJourneyLabel;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'id'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'id': return AppLocalizationsId();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
