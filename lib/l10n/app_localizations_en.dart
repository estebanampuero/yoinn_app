// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Yoinn';

  @override
  String get navActivities => 'Activities';

  @override
  String get navMap => 'Map';

  @override
  String get navAlerts => 'Alerts';

  @override
  String get navProfile => 'Profile';

  @override
  String get exploreCityTitle => 'Explore your City';

  @override
  String get exploreCityText =>
      'Create and discover unique activities and events happening around you in real-time.';

  @override
  String get joinActivityTitle => 'Join the Activity';

  @override
  String get joinActivityText =>
      'Request to join sports, food, parties, and more with a single tap.';

  @override
  String get connectChatTitle => 'Connect and Chat';

  @override
  String get connectChatText =>
      'Meet new people, chat with the group, and live real experiences.';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get continueWithApple => 'Continue with Apple';

  @override
  String get demoAccessLabel => 'Demo / Admin Access';

  @override
  String get emailDemoLabel => 'Demo Email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get enterButton => 'Log In';

  @override
  String get termsAndConditionsText =>
      'By continuing, you agree to our Terms of Service\nand Privacy Policy.';

  @override
  String get logout => 'Log Out';

  @override
  String get searchPlaceholder => 'Search...';

  @override
  String get catAll => 'All';

  @override
  String get catSport => 'Sport';

  @override
  String get catFood => 'Food';

  @override
  String get catArt => 'Art';

  @override
  String get catParty => 'Party';

  @override
  String get catOutdoor => 'Travel';

  @override
  String get catGames => 'Games';

  @override
  String get catOther => 'Other';

  @override
  String get hostedBy => 'Hosted by:';

  @override
  String get spotsLeft => 'spots left';

  @override
  String get goingCount => 'going';

  @override
  String get joinButton => 'Join';

  @override
  String get viewDetails => 'View Details';

  @override
  String get activityGroup => 'Group Activity';

  @override
  String get radiusLabel => 'Search radius';

  @override
  String get kmUnit => 'km';

  @override
  String get chatPlaceholder => 'Write a message...';

  @override
  String get sendButton => 'Send';

  @override
  String get noMessages => 'No messages yet. Say hello!';

  @override
  String get createActivityTitle => 'Create Plan';

  @override
  String get fieldTitle => 'Activity Title';

  @override
  String get fieldDesc => 'Description';

  @override
  String get fieldDate => 'Date';

  @override
  String get fieldTime => 'Time';

  @override
  String get fieldLocation => 'Location';

  @override
  String get fieldSpots => 'Available spots';

  @override
  String get createButton => 'Publish';

  @override
  String get errorGeneric => 'An error occurred';

  @override
  String get errorAppleLogin => 'Error signing in with Apple';

  @override
  String get successMessage => 'Success!';

  @override
  String get loading => 'Loading...';

  @override
  String get dialogUseTicketTitle => 'Use 1 Ticket?';

  @override
  String get dialogUseTicketBody =>
      'You are about to use 1 of your weekly tickets to apply for this activity.';

  @override
  String dialogTicketsRemaining(Object count) {
    return 'You will have: $count tickets left';
  }

  @override
  String get btnUseTicket => 'USE TICKET';

  @override
  String get btnCancel => 'Cancel';

  @override
  String get msgRequestSent => 'Request sent! Ticket used.';

  @override
  String get msgGoPro => 'Go PRO to join more activities.';

  @override
  String get dialogDeleteTitle => 'Delete Activity';

  @override
  String get dialogDeleteBody => 'Are you sure? This action cannot be undone.';

  @override
  String get btnDelete => 'Delete';

  @override
  String get msgActivityDeleted => 'Activity deleted';

  @override
  String get shareMessageIntro =>
      'Hey! 🌟 I found this activity on Yoinn and thought you\'d like it:';

  @override
  String get shareMessageCta =>
      '👇 Tap here to see details or download the app:';

  @override
  String get optShare => 'Share Activity';

  @override
  String get optEdit => 'Edit Activity';

  @override
  String get optDelete => 'Delete';

  @override
  String get optReport => 'Report';

  @override
  String get optBlock => 'Block User';

  @override
  String get dialogReportTitle => 'Report Activity';

  @override
  String get dialogReportBody => 'Why do you want to report this?';

  @override
  String get reasonSpam => 'It\'s Spam';

  @override
  String get reasonOffensive => 'Offensive Content';

  @override
  String get msgReportThanks =>
      'Thanks. We will review this content within 24h.';

  @override
  String get msgReportError => 'Error sending report.';

  @override
  String get dialogBlockTitle => 'Block User';

  @override
  String get dialogBlockBody =>
      'You won\'t see more content from this user. Continue?';

  @override
  String get btnBlock => 'BLOCK';

  @override
  String get msgUserBlocked => 'User blocked.';

  @override
  String get lblAboutActivity => 'About the activity';

  @override
  String get lblConfirmedAttendees => 'Confirmed Attendees';

  @override
  String get btnGoToChat => 'Go to Group Chat';

  @override
  String get btnManageRequests => 'Manage Requests';

  @override
  String get btnYouAreIn => 'You\'re in! Go to Chat';

  @override
  String get btnRequestPending => 'Request sent...';

  @override
  String get btnSoldOut => 'SOLD OUT';

  @override
  String get btnRequestJoin => 'Request to Join';

  @override
  String get screenCreateTitle => 'Create New Activity';

  @override
  String get lblPhotoHeader => 'Activity Photo';

  @override
  String get lblTapToUpload => 'Tap to upload an image';

  @override
  String get lblCategory => 'Category';

  @override
  String get lblMaxAttendees => 'Max Guests';

  @override
  String get btnReady => 'Done';

  @override
  String get btnPublish => 'Publish Activity';

  @override
  String get hintTitle => 'Ex: Hiking Afternoon';

  @override
  String get hintDesc => 'Tell us what it\'s about...';

  @override
  String get hintLocation => 'Tap to search on map...';

  @override
  String get msgSelectLocation => 'Please tap on \"Location\" to select on map';

  @override
  String get msgActivityCreated => 'Activity created successfully!';

  @override
  String get errImageUpload => 'Could not upload image';

  @override
  String get personSingular => 'person';

  @override
  String get personPlural => 'people';

  @override
  String get tabUsers => 'Users';

  @override
  String get tabActivities => 'Activities';

  @override
  String get tabReports => 'Reports';

  @override
  String get msgNoUsers => 'No users found.';

  @override
  String get msgNoActivities => 'No activities found.';

  @override
  String get msgNoReports => 'No pending reports!';

  @override
  String get dialogDeleteUserTitle => 'Delete User';

  @override
  String dialogDeleteUserBody(Object name) {
    return 'Delete $name permanently?';
  }

  @override
  String get dialogSanctionTitle => 'Confirm Sanction';

  @override
  String get dialogSanctionBody =>
      'This will delete the reported activity and close the report. Proceed?';

  @override
  String get btnDeleteAll => 'DELETE ALL';

  @override
  String get btnDismiss => 'Dismiss (False)';

  @override
  String get lblReportedActivity => 'REPORTED ACTIVITY';

  @override
  String get lblReason => 'Reason:';

  @override
  String get lblTapDetails => 'Tap to review details';

  @override
  String get msgContentDeleted => 'Content deleted by moderation';

  @override
  String get msgReportDismissed => 'Report dismissed';

  @override
  String get msgActivityLoading => 'Loading activity...';

  @override
  String get msgActivityNotFound =>
      'Activity does not exist (possibly already deleted).';

  @override
  String get lblTypingSingle => 'Someone is typing...';

  @override
  String get lblTypingMultiple => 'Several people are typing...';

  @override
  String get msgEmptyChatTitle => 'Say hi to the group!';

  @override
  String get msgEmptyChatBody => 'Be the first to break the ice.';

  @override
  String get screenEditActivityTitle => 'Edit Activity';

  @override
  String get btnSaveChanges => 'Save Changes';

  @override
  String get msgActivityUpdated => 'Activity updated successfully!';

  @override
  String get msgActivityRenewed =>
      'Activity renewed and spots reset successfully.';

  @override
  String get msgSelectLocationVerify =>
      'Please tap on \"Location\" to verify on map';

  @override
  String get screenEditProfileTitle => 'Edit Profile';

  @override
  String get btnSave => 'SAVE';

  @override
  String get lblName => 'Name';

  @override
  String get lblBio => 'Bio';

  @override
  String get lblInstagram => 'Instagram Username (Optional)';

  @override
  String get lblInterests => 'Interests / Hobbies';

  @override
  String get errNameRequired => 'Name is required';

  @override
  String get msgProfileUpdated => 'Profile updated successfully';

  @override
  String get msgNoActivitiesTitle => 'No activities found';

  @override
  String get msgNoActivitiesBody => 'Try changing filters or create a new one';

  @override
  String get hobbySports => 'Sports';

  @override
  String get hobbyFood => 'Food';

  @override
  String get hobbyParty => 'Party';

  @override
  String get hobbyMusic => 'Music';

  @override
  String get hobbyArt => 'Art';

  @override
  String get hobbyOutdoors => 'Outdoors';

  @override
  String get hobbyTech => 'Tech';

  @override
  String get hobbyCinema => 'Cinema';

  @override
  String get hobbyGames => 'Games';

  @override
  String get hobbyTravel => 'Travel';

  @override
  String get hobbyWellness => 'Wellness';

  @override
  String get hobbyEducation => 'Education';

  @override
  String get hobbyPets => 'Pets';

  @override
  String get hobbyBusiness => 'Business';

  @override
  String get hobbyLanguages => 'Languages';

  @override
  String get hobbyVolunteering => 'Volunteering';

  @override
  String get hobbyPhotography => 'Photography';

  @override
  String get hobbyLiterature => 'Literature';

  @override
  String get hobbyFamily => 'Family';

  @override
  String get hobbyOther => 'Other';

  @override
  String get lblSelectedLocation => 'Selected location';

  @override
  String get hintSearchAddress => 'Search address...';

  @override
  String get btnUseCurrentLocation => 'Use my current location';

  @override
  String get btnViewAddress => '🔍 View address';

  @override
  String get btnConfirmLocation => 'Confirm Location';

  @override
  String get errGpsLocation => 'Could not get GPS location';

  @override
  String screenManageRequestsTitle(Object activityTitle) {
    return 'Requests for $activityTitle';
  }

  @override
  String get msgNoPendingRequests => 'No pending requests';

  @override
  String get lblWantsToJoin => 'Wants to join';

  @override
  String msgUserAccepted(Object user) {
    return '$user accepted';
  }

  @override
  String get screenManageParticipantsTitle => 'Manage Participants';

  @override
  String get msgNoRequestsYet => 'No requests yet';

  @override
  String get lblPendingRequests => 'Pending Requests';

  @override
  String get lblAcceptedParticipants => 'Accepted Participants';

  @override
  String get lblConfirmed => 'Confirmed';

  @override
  String get tooltipRemoveParticipant => 'Remove participant';

  @override
  String get dialogRemoveParticipantTitle => 'Remove participant?';

  @override
  String dialogRemoveParticipantBody(Object user) {
    return 'Are you sure you want to remove $user from the activity?';
  }

  @override
  String get errUserNotAuth => 'User not authenticated';

  @override
  String get errImageSelect => 'Error selecting image';

  @override
  String get paywallTitle => 'Unlock the World';

  @override
  String get paywallSubtitle => 'With Yoinn Premium';

  @override
  String get paywallBtnStart => 'Start Now';

  @override
  String get paywallBtnRestore => 'Restore Purchases';

  @override
  String get paywallLegalTerms => 'Terms of Use';

  @override
  String get paywallLegalPrivacy => 'Privacy Policy';

  @override
  String get paywallPlanMonthly => 'MONTHLY';

  @override
  String get paywallPlanAnnual => 'ANNUAL';

  @override
  String get paywallLabelFree => 'FREE';

  @override
  String get paywallLabelPro => 'PRO';

  @override
  String get paywallErrNoPlan => 'Error: Plan temporarily unavailable.';

  @override
  String get paywallErrNoPurchases => 'No active purchases found.';

  @override
  String get featRadius => 'Search Radius';

  @override
  String get featGlobal => 'Create anywhere';

  @override
  String get featGuests => 'Guests per Event';

  @override
  String get featJoins => 'Join Events';

  @override
  String get featBadge => 'Verified Badge';

  @override
  String get valGlobalFree => '❌';

  @override
  String get valGlobalPro => 'Worldwide 🌍';

  @override
  String valGuestsFree(Object count) {
    return '$count max';
  }

  @override
  String valGuestsPro(Object count) {
    return '$count (Groups)';
  }

  @override
  String valJoinsFree(Object count) {
    return '$count / wk';
  }

  @override
  String get valJoinsPro => 'Unlimited ∞';

  @override
  String get valBadgeFree => '❌';

  @override
  String get valBadgePro => '✅';

  @override
  String get lblSavePercent => 'SAVE 20%';

  @override
  String lblOnlyPricePerMonth(Object price) {
    return 'Just $price / mo';
  }

  @override
  String get screenProfileTitle => 'Profile';

  @override
  String get lblSearchPrefs => 'Search Preferences';

  @override
  String lblUnlockPro(Object km) {
    return 'Unlock up to $km km';
  }

  @override
  String get lblGallery => 'Gallery';

  @override
  String get lblActivities => 'Activities';

  @override
  String get btnDeleteAccount => 'Delete account';

  @override
  String get msgWelcomePro => 'Welcome to Yoinn PRO! 🌟';

  @override
  String get bannerUpgradeTitle => 'Upgrade to Yoinn PRO';

  @override
  String get bannerUpgradeSubtitle => 'Unlock travel mode and more reach';

  @override
  String get dialogDeleteAccountTitle => 'Delete Account';

  @override
  String get dialogDeleteAccountBody =>
      'This action is irreversible. Your data and activities will be deleted.';

  @override
  String get lblTypeDelete => 'Type DELETE to confirm:';

  @override
  String get hintDelete => 'DELETE';

  @override
  String get btnDeleteConfirm => 'DELETE';

  @override
  String get msgProSearchFeature => 'Go PRO to search up to 150 km 🌍';

  @override
  String get errUserNotFound => 'User not found';

  @override
  String errLimitReached(Object limit, Object proHint) {
    return 'Activity limit reached ($limit). $proHint';
  }

  @override
  String get hintGoPro => 'Go PRO for more.';

  @override
  String errNoTickets(Object limit) {
    return 'No Tickets. You used your $limit weekly attempts. Go PRO to keep betting.';
  }

  @override
  String get errActivityFull => 'Activity is full.';

  @override
  String get errActivityNotFound => 'Activity not found';

  @override
  String get errCreatingActivity => 'Error creating activity';

  @override
  String get errEditingActivity => 'Error editing activity';

  @override
  String get errDeletingActivity => 'Error deleting activity';

  @override
  String get errApplying => 'Error applying';

  @override
  String get errAccepting => 'Error accepting user';

  @override
  String get errRejecting => 'Error rejecting';

  @override
  String get errRemoving => 'Error removing participant';

  @override
  String get errSendingMessage => 'Error sending message';

  @override
  String get errUploadingGallery => 'Error uploading gallery image';

  @override
  String get errUpdatingProfile => 'Error updating profile';

  @override
  String get lblOrganizer => 'Organizer';

  @override
  String get msgActivityFull => 'Activity Full!';

  @override
  String msgSpotsLeft(Object count) {
    return '$count spots available';
  }

  @override
  String get lblEventLocation => 'Event Location';

  @override
  String lblTotalCapacity(Object count) {
    return 'Total capacity: $count people';
  }

  @override
  String get msgNoParticipants => 'No one has joined yet. Be the first!';

  @override
  String get msgOnlyOneSpot => 'Only 1 spot left!';

  @override
  String msgSpotsLeftShort(Object count) {
    return 'Only $count spots left!';
  }

  @override
  String get lblGoing => 'going';

  @override
  String get lblSpots => 'spots';

  @override
  String get lblCreatedActivities => 'Created Activities';

  @override
  String get msgNoCreatedActivities =>
      'You haven\'t created any activities yet.';

  @override
  String get msgNoPhotos => 'No photos yet';

  @override
  String get tooltipAddPhoto => 'Add photo';

  @override
  String get msgPhotoAdded => 'Photo added!';

  @override
  String get paywallLimitTitle => 'Weekly Limit Reached';

  @override
  String get paywallLimitBody =>
      'You\'ve reached your 3 free joins for the week. Go PRO to join everything you want.';

  @override
  String get paywallBenefitJoins => 'Unlimited Event Joins';

  @override
  String get paywallBenefitCreate => 'Create events anywhere';

  @override
  String get paywallBenefitRadius => 'Search radius up to 150km';

  @override
  String get lblPerMonth => '/ month';

  @override
  String get lblCancelAnytime => 'Cancel anytime';

  @override
  String get btnUnlockNow => 'UNLOCK NOW';

  @override
  String get badgePro => 'PRO';

  @override
  String get badgeLocalGuide => '🌟 Local Guide';

  @override
  String get btnEditProfile => 'Edit Profile';

  @override
  String get lblInterestsTitle => 'Interests';

  @override
  String get msgLoginToViewAlerts => 'Log in to view your alerts';

  @override
  String get screenNotificationsTitle => 'Notifications';

  @override
  String get msgErrorLoadingNotifications => 'Error loading notifications';

  @override
  String get msgNoNewNotifications => 'You have no new notifications';

  @override
  String get lblNotificationDefaultTitle => 'New Notification';

  @override
  String get msgActivityNoLongerExists => 'This activity no longer exists';

  @override
  String get msgErrorLoadingActivity => 'Error loading activity';
}
