import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

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
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Yoinn'**
  String get appTitle;

  /// No description provided for @navActivities.
  ///
  /// In en, this message translates to:
  /// **'Activities'**
  String get navActivities;

  /// No description provided for @navMap.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get navMap;

  /// No description provided for @navAlerts.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get navAlerts;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @exploreCityTitle.
  ///
  /// In en, this message translates to:
  /// **'Explore your City'**
  String get exploreCityTitle;

  /// No description provided for @exploreCityText.
  ///
  /// In en, this message translates to:
  /// **'Create and discover unique activities and events happening around you in real-time.'**
  String get exploreCityText;

  /// No description provided for @joinActivityTitle.
  ///
  /// In en, this message translates to:
  /// **'Join the Activity'**
  String get joinActivityTitle;

  /// No description provided for @joinActivityText.
  ///
  /// In en, this message translates to:
  /// **'Request to join sports, food, parties, and more with a single tap.'**
  String get joinActivityText;

  /// No description provided for @connectChatTitle.
  ///
  /// In en, this message translates to:
  /// **'Connect and Chat'**
  String get connectChatTitle;

  /// No description provided for @connectChatText.
  ///
  /// In en, this message translates to:
  /// **'Meet new people, chat with the group, and live real experiences.'**
  String get connectChatText;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @continueWithApple.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get continueWithApple;

  /// No description provided for @demoAccessLabel.
  ///
  /// In en, this message translates to:
  /// **'Demo / Admin Access'**
  String get demoAccessLabel;

  /// No description provided for @emailDemoLabel.
  ///
  /// In en, this message translates to:
  /// **'Demo Email'**
  String get emailDemoLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @enterButton.
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get enterButton;

  /// No description provided for @termsAndConditionsText.
  ///
  /// In en, this message translates to:
  /// **'By continuing, you agree to our Terms of Service\nand Privacy Policy.'**
  String get termsAndConditionsText;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logout;

  /// No description provided for @searchPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search...'**
  String get searchPlaceholder;

  /// No description provided for @catAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get catAll;

  /// No description provided for @catSport.
  ///
  /// In en, this message translates to:
  /// **'Sport'**
  String get catSport;

  /// No description provided for @catFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get catFood;

  /// No description provided for @catArt.
  ///
  /// In en, this message translates to:
  /// **'Art'**
  String get catArt;

  /// No description provided for @catParty.
  ///
  /// In en, this message translates to:
  /// **'Party'**
  String get catParty;

  /// No description provided for @catOutdoor.
  ///
  /// In en, this message translates to:
  /// **'Outdoor'**
  String get catOutdoor;

  /// No description provided for @catGames.
  ///
  /// In en, this message translates to:
  /// **'Games'**
  String get catGames;

  /// No description provided for @catOther.
  ///
  /// In en, this message translates to:
  /// **'Others'**
  String get catOther;

  /// No description provided for @hostedBy.
  ///
  /// In en, this message translates to:
  /// **'Hosted by:'**
  String get hostedBy;

  /// No description provided for @spotsLeft.
  ///
  /// In en, this message translates to:
  /// **'spots left'**
  String get spotsLeft;

  /// No description provided for @goingCount.
  ///
  /// In en, this message translates to:
  /// **'going'**
  String get goingCount;

  /// No description provided for @joinButton.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get joinButton;

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewDetails;

  /// No description provided for @activityGroup.
  ///
  /// In en, this message translates to:
  /// **'Group Activity'**
  String get activityGroup;

  /// No description provided for @radiusLabel.
  ///
  /// In en, this message translates to:
  /// **'Search radius'**
  String get radiusLabel;

  /// No description provided for @kmUnit.
  ///
  /// In en, this message translates to:
  /// **'km'**
  String get kmUnit;

  /// No description provided for @chatPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Write a message...'**
  String get chatPlaceholder;

  /// No description provided for @sendButton.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get sendButton;

  /// No description provided for @noMessages.
  ///
  /// In en, this message translates to:
  /// **'No messages yet. Say hello!'**
  String get noMessages;

  /// No description provided for @createActivityTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Plan'**
  String get createActivityTitle;

  /// No description provided for @fieldTitle.
  ///
  /// In en, this message translates to:
  /// **'Activity Title'**
  String get fieldTitle;

  /// No description provided for @fieldDesc.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get fieldDesc;

  /// No description provided for @fieldDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get fieldDate;

  /// No description provided for @fieldTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get fieldTime;

  /// No description provided for @fieldLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get fieldLocation;

  /// No description provided for @fieldSpots.
  ///
  /// In en, this message translates to:
  /// **'Available spots'**
  String get fieldSpots;

  /// No description provided for @createButton.
  ///
  /// In en, this message translates to:
  /// **'Publish'**
  String get createButton;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'An error occurred'**
  String get errorGeneric;

  /// No description provided for @errorAppleLogin.
  ///
  /// In en, this message translates to:
  /// **'Error signing in with Apple'**
  String get errorAppleLogin;

  /// No description provided for @successMessage.
  ///
  /// In en, this message translates to:
  /// **'Success!'**
  String get successMessage;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @dialogUseTicketTitle.
  ///
  /// In en, this message translates to:
  /// **'Use 1 Ticket?'**
  String get dialogUseTicketTitle;

  /// No description provided for @dialogUseTicketBody.
  ///
  /// In en, this message translates to:
  /// **'You are about to use 1 of your weekly tickets to apply for this activity.'**
  String get dialogUseTicketBody;

  /// No description provided for @dialogTicketsRemaining.
  ///
  /// In en, this message translates to:
  /// **'You will have: {count} tickets left'**
  String dialogTicketsRemaining(Object count);

  /// No description provided for @btnUseTicket.
  ///
  /// In en, this message translates to:
  /// **'USE TICKET'**
  String get btnUseTicket;

  /// No description provided for @btnCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get btnCancel;

  /// No description provided for @msgRequestSent.
  ///
  /// In en, this message translates to:
  /// **'Request sent! Ticket used.'**
  String get msgRequestSent;

  /// No description provided for @msgGoPro.
  ///
  /// In en, this message translates to:
  /// **'Go PRO to join more activities.'**
  String get msgGoPro;

  /// No description provided for @dialogDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Activity'**
  String get dialogDeleteTitle;

  /// No description provided for @dialogDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure? This action cannot be undone.'**
  String get dialogDeleteBody;

  /// No description provided for @btnDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get btnDelete;

  /// No description provided for @msgActivityDeleted.
  ///
  /// In en, this message translates to:
  /// **'Activity deleted'**
  String get msgActivityDeleted;

  /// No description provided for @shareMessageIntro.
  ///
  /// In en, this message translates to:
  /// **'Hey! 🌟 I found this activity on Yoinn and thought you\'d like it:'**
  String get shareMessageIntro;

  /// No description provided for @shareMessageCta.
  ///
  /// In en, this message translates to:
  /// **'👇 Tap here to see details or download the app:'**
  String get shareMessageCta;

  /// No description provided for @optShare.
  ///
  /// In en, this message translates to:
  /// **'Share Activity'**
  String get optShare;

  /// No description provided for @optEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit Activity'**
  String get optEdit;

  /// No description provided for @optDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get optDelete;

  /// No description provided for @optReport.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get optReport;

  /// No description provided for @optBlock.
  ///
  /// In en, this message translates to:
  /// **'Block User'**
  String get optBlock;

  /// No description provided for @dialogReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Report Activity'**
  String get dialogReportTitle;

  /// No description provided for @dialogReportBody.
  ///
  /// In en, this message translates to:
  /// **'Why do you want to report this?'**
  String get dialogReportBody;

  /// No description provided for @reasonSpam.
  ///
  /// In en, this message translates to:
  /// **'It\'s Spam'**
  String get reasonSpam;

  /// No description provided for @reasonOffensive.
  ///
  /// In en, this message translates to:
  /// **'Offensive Content'**
  String get reasonOffensive;

  /// No description provided for @msgReportThanks.
  ///
  /// In en, this message translates to:
  /// **'Thanks. We will review this content within 24h.'**
  String get msgReportThanks;

  /// No description provided for @msgReportError.
  ///
  /// In en, this message translates to:
  /// **'Error sending report.'**
  String get msgReportError;

  /// No description provided for @dialogBlockTitle.
  ///
  /// In en, this message translates to:
  /// **'Block User'**
  String get dialogBlockTitle;

  /// No description provided for @dialogBlockBody.
  ///
  /// In en, this message translates to:
  /// **'You won\'t see more content from this user. Continue?'**
  String get dialogBlockBody;

  /// No description provided for @btnBlock.
  ///
  /// In en, this message translates to:
  /// **'BLOCK'**
  String get btnBlock;

  /// No description provided for @msgUserBlocked.
  ///
  /// In en, this message translates to:
  /// **'User blocked.'**
  String get msgUserBlocked;

  /// No description provided for @lblAboutActivity.
  ///
  /// In en, this message translates to:
  /// **'About the activity'**
  String get lblAboutActivity;

  /// No description provided for @lblConfirmedAttendees.
  ///
  /// In en, this message translates to:
  /// **'Confirmed Attendees'**
  String get lblConfirmedAttendees;

  /// No description provided for @btnGoToChat.
  ///
  /// In en, this message translates to:
  /// **'Go to Group Chat'**
  String get btnGoToChat;

  /// No description provided for @btnManageRequests.
  ///
  /// In en, this message translates to:
  /// **'Manage Requests'**
  String get btnManageRequests;

  /// No description provided for @btnYouAreIn.
  ///
  /// In en, this message translates to:
  /// **'You\'re in! Go to Chat'**
  String get btnYouAreIn;

  /// No description provided for @btnRequestPending.
  ///
  /// In en, this message translates to:
  /// **'Request sent...'**
  String get btnRequestPending;

  /// No description provided for @btnSoldOut.
  ///
  /// In en, this message translates to:
  /// **'SOLD OUT'**
  String get btnSoldOut;

  /// No description provided for @btnRequestJoin.
  ///
  /// In en, this message translates to:
  /// **'Request to Join'**
  String get btnRequestJoin;

  /// No description provided for @screenCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create New Activity'**
  String get screenCreateTitle;

  /// No description provided for @lblPhotoHeader.
  ///
  /// In en, this message translates to:
  /// **'Activity Photo'**
  String get lblPhotoHeader;

  /// No description provided for @lblTapToUpload.
  ///
  /// In en, this message translates to:
  /// **'Tap to upload an image'**
  String get lblTapToUpload;

  /// No description provided for @lblCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get lblCategory;

  /// No description provided for @lblMaxAttendees.
  ///
  /// In en, this message translates to:
  /// **'Max Guests'**
  String get lblMaxAttendees;

  /// No description provided for @btnReady.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get btnReady;

  /// No description provided for @btnPublish.
  ///
  /// In en, this message translates to:
  /// **'Publish Activity'**
  String get btnPublish;

  /// No description provided for @hintTitle.
  ///
  /// In en, this message translates to:
  /// **'Ex: Hiking Afternoon'**
  String get hintTitle;

  /// No description provided for @hintDesc.
  ///
  /// In en, this message translates to:
  /// **'Tell us what it\'s about...'**
  String get hintDesc;

  /// No description provided for @hintLocation.
  ///
  /// In en, this message translates to:
  /// **'Tap to search on map...'**
  String get hintLocation;

  /// No description provided for @msgSelectLocation.
  ///
  /// In en, this message translates to:
  /// **'Please tap on \"Location\" to select on map'**
  String get msgSelectLocation;

  /// No description provided for @msgActivityCreated.
  ///
  /// In en, this message translates to:
  /// **'Activity created successfully!'**
  String get msgActivityCreated;

  /// No description provided for @errImageUpload.
  ///
  /// In en, this message translates to:
  /// **'Could not upload image'**
  String get errImageUpload;

  /// No description provided for @personSingular.
  ///
  /// In en, this message translates to:
  /// **'person'**
  String get personSingular;

  /// No description provided for @personPlural.
  ///
  /// In en, this message translates to:
  /// **'people'**
  String get personPlural;

  /// No description provided for @tabUsers.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get tabUsers;

  /// No description provided for @tabActivities.
  ///
  /// In en, this message translates to:
  /// **'Activities'**
  String get tabActivities;

  /// No description provided for @tabReports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get tabReports;

  /// No description provided for @msgNoUsers.
  ///
  /// In en, this message translates to:
  /// **'No users found.'**
  String get msgNoUsers;

  /// No description provided for @msgNoActivities.
  ///
  /// In en, this message translates to:
  /// **'No activities found.'**
  String get msgNoActivities;

  /// No description provided for @msgNoReports.
  ///
  /// In en, this message translates to:
  /// **'No pending reports!'**
  String get msgNoReports;

  /// No description provided for @dialogDeleteUserTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete User'**
  String get dialogDeleteUserTitle;

  /// No description provided for @dialogDeleteUserBody.
  ///
  /// In en, this message translates to:
  /// **'Delete {name} permanently?'**
  String dialogDeleteUserBody(Object name);

  /// No description provided for @dialogSanctionTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Sanction'**
  String get dialogSanctionTitle;

  /// No description provided for @dialogSanctionBody.
  ///
  /// In en, this message translates to:
  /// **'This will delete the reported activity and close the report. Proceed?'**
  String get dialogSanctionBody;

  /// No description provided for @btnDeleteAll.
  ///
  /// In en, this message translates to:
  /// **'DELETE ALL'**
  String get btnDeleteAll;

  /// No description provided for @btnDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss (False)'**
  String get btnDismiss;

  /// No description provided for @lblReportedActivity.
  ///
  /// In en, this message translates to:
  /// **'REPORTED ACTIVITY'**
  String get lblReportedActivity;

  /// No description provided for @lblReason.
  ///
  /// In en, this message translates to:
  /// **'Reason:'**
  String get lblReason;

  /// No description provided for @lblTapDetails.
  ///
  /// In en, this message translates to:
  /// **'Tap to review details'**
  String get lblTapDetails;

  /// No description provided for @msgContentDeleted.
  ///
  /// In en, this message translates to:
  /// **'Content deleted by moderation'**
  String get msgContentDeleted;

  /// No description provided for @msgReportDismissed.
  ///
  /// In en, this message translates to:
  /// **'Report dismissed'**
  String get msgReportDismissed;

  /// No description provided for @msgActivityLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading activity...'**
  String get msgActivityLoading;

  /// No description provided for @msgActivityNotFound.
  ///
  /// In en, this message translates to:
  /// **'Activity does not exist (possibly already deleted).'**
  String get msgActivityNotFound;

  /// No description provided for @lblTypingSingle.
  ///
  /// In en, this message translates to:
  /// **'Someone is typing...'**
  String get lblTypingSingle;

  /// No description provided for @lblTypingMultiple.
  ///
  /// In en, this message translates to:
  /// **'Several people are typing...'**
  String get lblTypingMultiple;

  /// No description provided for @msgEmptyChatTitle.
  ///
  /// In en, this message translates to:
  /// **'Say hi to the group!'**
  String get msgEmptyChatTitle;

  /// No description provided for @msgEmptyChatBody.
  ///
  /// In en, this message translates to:
  /// **'Be the first to break the ice.'**
  String get msgEmptyChatBody;

  /// No description provided for @screenEditActivityTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Activity'**
  String get screenEditActivityTitle;

  /// No description provided for @btnSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get btnSaveChanges;

  /// No description provided for @msgActivityUpdated.
  ///
  /// In en, this message translates to:
  /// **'Activity updated successfully!'**
  String get msgActivityUpdated;

  /// No description provided for @msgActivityRenewed.
  ///
  /// In en, this message translates to:
  /// **'Activity renewed and spots reset successfully.'**
  String get msgActivityRenewed;

  /// No description provided for @msgSelectLocationVerify.
  ///
  /// In en, this message translates to:
  /// **'Please tap on \"Location\" to verify on map'**
  String get msgSelectLocationVerify;

  /// No description provided for @screenEditProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get screenEditProfileTitle;

  /// No description provided for @btnSave.
  ///
  /// In en, this message translates to:
  /// **'SAVE'**
  String get btnSave;

  /// No description provided for @lblName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get lblName;

  /// No description provided for @lblBio.
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get lblBio;

  /// No description provided for @lblInstagram.
  ///
  /// In en, this message translates to:
  /// **'Instagram Username (Optional)'**
  String get lblInstagram;

  /// No description provided for @lblInterests.
  ///
  /// In en, this message translates to:
  /// **'Interests / Hobbies'**
  String get lblInterests;

  /// No description provided for @errNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get errNameRequired;

  /// No description provided for @msgProfileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get msgProfileUpdated;

  /// No description provided for @msgNoActivitiesTitle.
  ///
  /// In en, this message translates to:
  /// **'No activities found'**
  String get msgNoActivitiesTitle;

  /// No description provided for @msgNoActivitiesBody.
  ///
  /// In en, this message translates to:
  /// **'Try changing filters or create a new one'**
  String get msgNoActivitiesBody;

  /// No description provided for @hobbySports.
  ///
  /// In en, this message translates to:
  /// **'Sports'**
  String get hobbySports;

  /// No description provided for @hobbyFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get hobbyFood;

  /// No description provided for @hobbyParty.
  ///
  /// In en, this message translates to:
  /// **'Party'**
  String get hobbyParty;

  /// No description provided for @hobbyMusic.
  ///
  /// In en, this message translates to:
  /// **'Music'**
  String get hobbyMusic;

  /// No description provided for @hobbyArt.
  ///
  /// In en, this message translates to:
  /// **'Art'**
  String get hobbyArt;

  /// No description provided for @hobbyOutdoors.
  ///
  /// In en, this message translates to:
  /// **'Outdoors'**
  String get hobbyOutdoors;

  /// No description provided for @hobbyTech.
  ///
  /// In en, this message translates to:
  /// **'Tech'**
  String get hobbyTech;

  /// No description provided for @hobbyCinema.
  ///
  /// In en, this message translates to:
  /// **'Cinema'**
  String get hobbyCinema;

  /// No description provided for @hobbyGames.
  ///
  /// In en, this message translates to:
  /// **'Games'**
  String get hobbyGames;

  /// No description provided for @hobbyTravel.
  ///
  /// In en, this message translates to:
  /// **'Travel'**
  String get hobbyTravel;

  /// No description provided for @hobbyWellness.
  ///
  /// In en, this message translates to:
  /// **'Wellness'**
  String get hobbyWellness;

  /// No description provided for @hobbyEducation.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get hobbyEducation;

  /// No description provided for @hobbyPets.
  ///
  /// In en, this message translates to:
  /// **'Pets'**
  String get hobbyPets;

  /// No description provided for @hobbyBusiness.
  ///
  /// In en, this message translates to:
  /// **'Business'**
  String get hobbyBusiness;

  /// No description provided for @hobbyLanguages.
  ///
  /// In en, this message translates to:
  /// **'Languages'**
  String get hobbyLanguages;

  /// No description provided for @hobbyVolunteering.
  ///
  /// In en, this message translates to:
  /// **'Volunteering'**
  String get hobbyVolunteering;

  /// No description provided for @hobbyPhotography.
  ///
  /// In en, this message translates to:
  /// **'Photography'**
  String get hobbyPhotography;

  /// No description provided for @hobbyLiterature.
  ///
  /// In en, this message translates to:
  /// **'Literature'**
  String get hobbyLiterature;

  /// No description provided for @hobbyFamily.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get hobbyFamily;

  /// No description provided for @hobbyOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get hobbyOther;

  /// No description provided for @lblSelectedLocation.
  ///
  /// In en, this message translates to:
  /// **'Selected location'**
  String get lblSelectedLocation;

  /// No description provided for @hintSearchAddress.
  ///
  /// In en, this message translates to:
  /// **'Search address...'**
  String get hintSearchAddress;

  /// No description provided for @btnUseCurrentLocation.
  ///
  /// In en, this message translates to:
  /// **'Use my current location'**
  String get btnUseCurrentLocation;

  /// No description provided for @btnViewAddress.
  ///
  /// In en, this message translates to:
  /// **'🔍 View address'**
  String get btnViewAddress;

  /// No description provided for @btnConfirmLocation.
  ///
  /// In en, this message translates to:
  /// **'Confirm Location'**
  String get btnConfirmLocation;

  /// No description provided for @errGpsLocation.
  ///
  /// In en, this message translates to:
  /// **'Could not get GPS location'**
  String get errGpsLocation;

  /// No description provided for @screenManageRequestsTitle.
  ///
  /// In en, this message translates to:
  /// **'Requests for {activityTitle}'**
  String screenManageRequestsTitle(Object activityTitle);

  /// No description provided for @msgNoPendingRequests.
  ///
  /// In en, this message translates to:
  /// **'No pending requests'**
  String get msgNoPendingRequests;

  /// No description provided for @lblWantsToJoin.
  ///
  /// In en, this message translates to:
  /// **'Wants to join'**
  String get lblWantsToJoin;

  /// No description provided for @msgUserAccepted.
  ///
  /// In en, this message translates to:
  /// **'{user} accepted'**
  String msgUserAccepted(Object user);

  /// No description provided for @screenManageParticipantsTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage Participants'**
  String get screenManageParticipantsTitle;

  /// No description provided for @msgNoRequestsYet.
  ///
  /// In en, this message translates to:
  /// **'No requests yet'**
  String get msgNoRequestsYet;

  /// No description provided for @lblPendingRequests.
  ///
  /// In en, this message translates to:
  /// **'Pending Requests'**
  String get lblPendingRequests;

  /// No description provided for @lblAcceptedParticipants.
  ///
  /// In en, this message translates to:
  /// **'Accepted Participants'**
  String get lblAcceptedParticipants;

  /// No description provided for @lblConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get lblConfirmed;

  /// No description provided for @tooltipRemoveParticipant.
  ///
  /// In en, this message translates to:
  /// **'Remove participant'**
  String get tooltipRemoveParticipant;

  /// No description provided for @dialogRemoveParticipantTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove participant?'**
  String get dialogRemoveParticipantTitle;

  /// No description provided for @dialogRemoveParticipantBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove {user} from the activity?'**
  String dialogRemoveParticipantBody(Object user);

  /// No description provided for @errUserNotAuth.
  ///
  /// In en, this message translates to:
  /// **'User not authenticated'**
  String get errUserNotAuth;

  /// No description provided for @errImageSelect.
  ///
  /// In en, this message translates to:
  /// **'Error selecting image'**
  String get errImageSelect;

  /// No description provided for @paywallTitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock the World'**
  String get paywallTitle;

  /// No description provided for @paywallSubtitle.
  ///
  /// In en, this message translates to:
  /// **'With Yoinn Premium'**
  String get paywallSubtitle;

  /// No description provided for @paywallBtnStart.
  ///
  /// In en, this message translates to:
  /// **'Start Now'**
  String get paywallBtnStart;

  /// No description provided for @paywallBtnRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore Purchases'**
  String get paywallBtnRestore;

  /// No description provided for @paywallLegalTerms.
  ///
  /// In en, this message translates to:
  /// **'Terms of Use'**
  String get paywallLegalTerms;

  /// No description provided for @paywallLegalPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get paywallLegalPrivacy;

  /// No description provided for @paywallPlanMonthly.
  ///
  /// In en, this message translates to:
  /// **'MONTHLY'**
  String get paywallPlanMonthly;

  /// No description provided for @paywallPlanAnnual.
  ///
  /// In en, this message translates to:
  /// **'ANNUAL'**
  String get paywallPlanAnnual;

  /// No description provided for @paywallLabelFree.
  ///
  /// In en, this message translates to:
  /// **'FREE'**
  String get paywallLabelFree;

  /// No description provided for @paywallLabelPro.
  ///
  /// In en, this message translates to:
  /// **'PRO'**
  String get paywallLabelPro;

  /// No description provided for @paywallErrNoPlan.
  ///
  /// In en, this message translates to:
  /// **'Error: Plan temporarily unavailable.'**
  String get paywallErrNoPlan;

  /// No description provided for @paywallErrNoPurchases.
  ///
  /// In en, this message translates to:
  /// **'No active purchases found.'**
  String get paywallErrNoPurchases;

  /// No description provided for @featRadius.
  ///
  /// In en, this message translates to:
  /// **'Search Radius'**
  String get featRadius;

  /// No description provided for @featGlobal.
  ///
  /// In en, this message translates to:
  /// **'Create anywhere'**
  String get featGlobal;

  /// No description provided for @featGuests.
  ///
  /// In en, this message translates to:
  /// **'Guests per Event'**
  String get featGuests;

  /// No description provided for @featJoins.
  ///
  /// In en, this message translates to:
  /// **'Join Events'**
  String get featJoins;

  /// No description provided for @featBadge.
  ///
  /// In en, this message translates to:
  /// **'Verified Badge'**
  String get featBadge;

  /// No description provided for @valGlobalFree.
  ///
  /// In en, this message translates to:
  /// **'❌'**
  String get valGlobalFree;

  /// No description provided for @valGlobalPro.
  ///
  /// In en, this message translates to:
  /// **'Worldwide 🌍'**
  String get valGlobalPro;

  /// No description provided for @valGuestsFree.
  ///
  /// In en, this message translates to:
  /// **'{count} max'**
  String valGuestsFree(Object count);

  /// No description provided for @valGuestsPro.
  ///
  /// In en, this message translates to:
  /// **'{count} (Groups)'**
  String valGuestsPro(Object count);

  /// No description provided for @valJoinsFree.
  ///
  /// In en, this message translates to:
  /// **'{count} / wk'**
  String valJoinsFree(Object count);

  /// No description provided for @valJoinsPro.
  ///
  /// In en, this message translates to:
  /// **'Unlimited ∞'**
  String get valJoinsPro;

  /// No description provided for @valBadgeFree.
  ///
  /// In en, this message translates to:
  /// **'❌'**
  String get valBadgeFree;

  /// No description provided for @valBadgePro.
  ///
  /// In en, this message translates to:
  /// **'✅'**
  String get valBadgePro;

  /// No description provided for @lblSavePercent.
  ///
  /// In en, this message translates to:
  /// **'SAVE 20%'**
  String get lblSavePercent;

  /// No description provided for @lblOnlyPricePerMonth.
  ///
  /// In en, this message translates to:
  /// **'Just {price} / mo'**
  String lblOnlyPricePerMonth(Object price);

  /// No description provided for @screenProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get screenProfileTitle;

  /// No description provided for @lblSearchPrefs.
  ///
  /// In en, this message translates to:
  /// **'Search Preferences'**
  String get lblSearchPrefs;

  /// No description provided for @lblUnlockPro.
  ///
  /// In en, this message translates to:
  /// **'Unlock up to {km} km'**
  String lblUnlockPro(Object km);

  /// No description provided for @lblGallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get lblGallery;

  /// No description provided for @lblActivities.
  ///
  /// In en, this message translates to:
  /// **'Activities'**
  String get lblActivities;

  /// No description provided for @btnDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get btnDeleteAccount;

  /// No description provided for @msgWelcomePro.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Yoinn PRO! 🌟'**
  String get msgWelcomePro;

  /// No description provided for @bannerUpgradeTitle.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Yoinn PRO'**
  String get bannerUpgradeTitle;

  /// No description provided for @bannerUpgradeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock travel mode and more reach'**
  String get bannerUpgradeSubtitle;

  /// No description provided for @dialogDeleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get dialogDeleteAccountTitle;

  /// No description provided for @dialogDeleteAccountBody.
  ///
  /// In en, this message translates to:
  /// **'This action is irreversible. Your data and activities will be deleted.'**
  String get dialogDeleteAccountBody;

  /// No description provided for @lblTypeDelete.
  ///
  /// In en, this message translates to:
  /// **'Type DELETE to confirm:'**
  String get lblTypeDelete;

  /// No description provided for @hintDelete.
  ///
  /// In en, this message translates to:
  /// **'DELETE'**
  String get hintDelete;

  /// No description provided for @btnDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'DELETE'**
  String get btnDeleteConfirm;

  /// No description provided for @msgProSearchFeature.
  ///
  /// In en, this message translates to:
  /// **'Go PRO to search up to 150 km 🌍'**
  String get msgProSearchFeature;

  /// No description provided for @errUserNotFound.
  ///
  /// In en, this message translates to:
  /// **'User not found'**
  String get errUserNotFound;

  /// No description provided for @errLimitReached.
  ///
  /// In en, this message translates to:
  /// **'Activity limit reached ({limit}). {proHint}'**
  String errLimitReached(Object limit, Object proHint);

  /// No description provided for @hintGoPro.
  ///
  /// In en, this message translates to:
  /// **'Go PRO for more.'**
  String get hintGoPro;

  /// No description provided for @errNoTickets.
  ///
  /// In en, this message translates to:
  /// **'No Tickets. You used your {limit} weekly attempts. Go PRO to keep betting.'**
  String errNoTickets(Object limit);

  /// No description provided for @errActivityFull.
  ///
  /// In en, this message translates to:
  /// **'Activity is full.'**
  String get errActivityFull;

  /// No description provided for @errActivityNotFound.
  ///
  /// In en, this message translates to:
  /// **'Activity not found'**
  String get errActivityNotFound;

  /// No description provided for @errCreatingActivity.
  ///
  /// In en, this message translates to:
  /// **'Error creating activity'**
  String get errCreatingActivity;

  /// No description provided for @errEditingActivity.
  ///
  /// In en, this message translates to:
  /// **'Error editing activity'**
  String get errEditingActivity;

  /// No description provided for @errDeletingActivity.
  ///
  /// In en, this message translates to:
  /// **'Error deleting activity'**
  String get errDeletingActivity;

  /// No description provided for @errApplying.
  ///
  /// In en, this message translates to:
  /// **'Error applying'**
  String get errApplying;

  /// No description provided for @errAccepting.
  ///
  /// In en, this message translates to:
  /// **'Error accepting user'**
  String get errAccepting;

  /// No description provided for @errRejecting.
  ///
  /// In en, this message translates to:
  /// **'Error rejecting'**
  String get errRejecting;

  /// No description provided for @errRemoving.
  ///
  /// In en, this message translates to:
  /// **'Error removing participant'**
  String get errRemoving;

  /// No description provided for @errSendingMessage.
  ///
  /// In en, this message translates to:
  /// **'Error sending message'**
  String get errSendingMessage;

  /// No description provided for @errUploadingGallery.
  ///
  /// In en, this message translates to:
  /// **'Error uploading gallery image'**
  String get errUploadingGallery;

  /// No description provided for @errUpdatingProfile.
  ///
  /// In en, this message translates to:
  /// **'Error updating profile'**
  String get errUpdatingProfile;

  /// No description provided for @lblOrganizer.
  ///
  /// In en, this message translates to:
  /// **'Organizer'**
  String get lblOrganizer;

  /// No description provided for @msgActivityFull.
  ///
  /// In en, this message translates to:
  /// **'Activity Full!'**
  String get msgActivityFull;

  /// No description provided for @msgSpotsLeft.
  ///
  /// In en, this message translates to:
  /// **'{count} spots available'**
  String msgSpotsLeft(Object count);

  /// No description provided for @lblEventLocation.
  ///
  /// In en, this message translates to:
  /// **'Event Location'**
  String get lblEventLocation;

  /// No description provided for @lblTotalCapacity.
  ///
  /// In en, this message translates to:
  /// **'Total capacity: {count} people'**
  String lblTotalCapacity(Object count);

  /// No description provided for @msgNoParticipants.
  ///
  /// In en, this message translates to:
  /// **'No one has joined yet. Be the first!'**
  String get msgNoParticipants;

  /// No description provided for @msgOnlyOneSpot.
  ///
  /// In en, this message translates to:
  /// **'Only 1 spot left!'**
  String get msgOnlyOneSpot;

  /// No description provided for @msgSpotsLeftShort.
  ///
  /// In en, this message translates to:
  /// **'Only {count} spots left!'**
  String msgSpotsLeftShort(Object count);

  /// No description provided for @lblGoing.
  ///
  /// In en, this message translates to:
  /// **'going'**
  String get lblGoing;

  /// No description provided for @lblSpots.
  ///
  /// In en, this message translates to:
  /// **'spots'**
  String get lblSpots;

  /// No description provided for @lblCreatedActivities.
  ///
  /// In en, this message translates to:
  /// **'Created Activities'**
  String get lblCreatedActivities;

  /// No description provided for @msgNoCreatedActivities.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t created any activities yet.'**
  String get msgNoCreatedActivities;

  /// No description provided for @msgNoPhotos.
  ///
  /// In en, this message translates to:
  /// **'No photos yet'**
  String get msgNoPhotos;

  /// No description provided for @tooltipAddPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add photo'**
  String get tooltipAddPhoto;

  /// No description provided for @msgPhotoAdded.
  ///
  /// In en, this message translates to:
  /// **'Photo added!'**
  String get msgPhotoAdded;

  /// No description provided for @paywallLimitTitle.
  ///
  /// In en, this message translates to:
  /// **'Weekly Limit Reached'**
  String get paywallLimitTitle;

  /// No description provided for @paywallLimitBody.
  ///
  /// In en, this message translates to:
  /// **'You\'ve reached your 3 free joins for the week. Go PRO to join everything you want.'**
  String get paywallLimitBody;

  /// No description provided for @paywallBenefitJoins.
  ///
  /// In en, this message translates to:
  /// **'Unlimited Event Joins'**
  String get paywallBenefitJoins;

  /// No description provided for @paywallBenefitCreate.
  ///
  /// In en, this message translates to:
  /// **'Create events anywhere'**
  String get paywallBenefitCreate;

  /// No description provided for @paywallBenefitRadius.
  ///
  /// In en, this message translates to:
  /// **'Search radius up to 150km'**
  String get paywallBenefitRadius;

  /// No description provided for @lblPerMonth.
  ///
  /// In en, this message translates to:
  /// **'/ month'**
  String get lblPerMonth;

  /// No description provided for @lblCancelAnytime.
  ///
  /// In en, this message translates to:
  /// **'Cancel anytime'**
  String get lblCancelAnytime;

  /// No description provided for @btnUnlockNow.
  ///
  /// In en, this message translates to:
  /// **'UNLOCK NOW'**
  String get btnUnlockNow;

  /// No description provided for @badgePro.
  ///
  /// In en, this message translates to:
  /// **'PRO'**
  String get badgePro;

  /// No description provided for @badgeLocalGuide.
  ///
  /// In en, this message translates to:
  /// **'🌟 Local Guide'**
  String get badgeLocalGuide;

  /// No description provided for @btnEditProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get btnEditProfile;

  /// No description provided for @lblInterestsTitle.
  ///
  /// In en, this message translates to:
  /// **'Interests'**
  String get lblInterestsTitle;

  /// No description provided for @msgLoginToViewAlerts.
  ///
  /// In en, this message translates to:
  /// **'Log in to view your alerts'**
  String get msgLoginToViewAlerts;

  /// No description provided for @screenNotificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get screenNotificationsTitle;

  /// No description provided for @msgErrorLoadingNotifications.
  ///
  /// In en, this message translates to:
  /// **'Error loading notifications'**
  String get msgErrorLoadingNotifications;

  /// No description provided for @msgNoNewNotifications.
  ///
  /// In en, this message translates to:
  /// **'You have no new notifications'**
  String get msgNoNewNotifications;

  /// No description provided for @lblNotificationDefaultTitle.
  ///
  /// In en, this message translates to:
  /// **'New Notification'**
  String get lblNotificationDefaultTitle;

  /// No description provided for @msgActivityNoLongerExists.
  ///
  /// In en, this message translates to:
  /// **'This activity no longer exists'**
  String get msgActivityNoLongerExists;

  /// No description provided for @msgErrorLoadingActivity.
  ///
  /// In en, this message translates to:
  /// **'Error loading activity'**
  String get msgErrorLoadingActivity;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
