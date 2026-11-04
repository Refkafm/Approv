// ignore_for_file: lines_longer_than_80_chars
import 'strings.dart';

/// Teks English. Tambah teks baru di [S], lalu di sini dan di file bahasa lainnya.
class SEn extends S {
  const SEn();

  @override
  String get languageCode => 'en';

  @override
  String get back => 'Back';

  @override
  String get continueLabel => 'Continue';

  @override
  String get saving => 'Saving...';

  @override
  String get checking => 'Checking...';

  @override
  String get preparing => 'Preparing...';

  @override
  String get sending => 'Sending...';

  @override
  String get signOut => 'Sign out';

  @override
  String get done => 'Done';

  @override
  String get tasks => 'Tasks';

  @override
  String get rewards => 'Rewards';

  @override
  String get welcomeTitle => 'Who is using this phone?';

  @override
  String get welcomeSubtitle => 'Parents set tasks and rewards. Kids collect points.';

  @override
  String get welcomeParent => 'I\'m a parent';

  @override
  String get welcomeChild => 'I\'m a kid';

  @override
  String get demoModeNote => 'Demo mode: not connected to a server, data is only kept while the app is open.';

  @override
  String get devComponents => 'View design components';

  @override
  String get joinCodeLength => 'The code has 6 letters or numbers.';

  @override
  String joinHello(String name) => 'Hi, $name!';

  @override
  String get pinSubtitle => 'Create a 4-digit PIN to keep your profile safe when the phone is shared.';

  @override
  String get pinLabel => 'PIN';

  @override
  String get savePin => 'Save PIN';

  @override
  String get skipForNow => 'Skip for now';

  @override
  String get joinTitle => 'Join a family';

  @override
  String get joinSubtitleAdult => 'Enter the invite code from the family owner.';

  @override
  String get joinSubtitleChild => 'Ask a parent to open the Family tab on their phone, then enter the code here.';

  @override
  String get inviteCodeLabel => 'Invite code';

  @override
  String get nicknameLabel => 'Your nickname';

  @override
  String get nicknameHintAdult => 'e.g. Dad';

  @override
  String get joinButton => 'Join';

  @override
  String get onbNamesRequired => 'Please fill in the family name and your nickname first.';

  @override
  String get onbCreateTitle => 'Create a family';

  @override
  String get onbCreateSubtitle => 'Start with a family name. You can change everything later.';

  @override
  String get familyNameLabel => 'Family name';

  @override
  String get familyNameHint => 'e.g. The Rina Family';

  @override
  String get nicknameHintOwner => 'e.g. Mom Rina';

  @override
  String get onbHaveInvite => 'Have an invite code from your partner?';

  @override
  String get onbAddChildTitle => 'Add a child';

  @override
  String get onbAddChildSubtitle =>
      'Kids don\'t need an email or phone number. Later they just enter a code on their phone.';

  @override
  String get birthDateEmpty => 'Birth date not set';

  @override
  String get addChild => 'Add child';

  @override
  String get addAnotherChild => 'Add another child';

  @override
  String get onbTemplateTitle => 'Choose a points template';

  @override
  String get onbTemplateSubtitle =>
      'Fills in sample tasks and rewards for their age. You can change the numbers anytime.';

  @override
  String templateSummary(String daily, String screen) => '±$daily points/day · 30 min screen time = $screen points';

  @override
  String get suggested => 'Suggested';

  @override
  String get useTemplate => 'Use this template';

  @override
  String get skipTemplate => 'Skip, I\'ll fill it in later';

  @override
  String get onbReviewTitle => 'Check tasks & rewards';

  @override
  String get onbReviewSubtitle =>
      'These are samples from the template. Edit or delete them later in the Tasks and Rewards tabs.';

  @override
  String get rewardGoalSaved => 'Goal (saved up)';

  @override
  String get rewardInstant => 'Instant';

  @override
  String get onbConnectTitle => 'Connect your kid\'s phone';

  @override
  String get onbConnectSubtitle => 'On your kid\'s phone: open the app, choose "I\'m a kid", then enter the code.';

  @override
  String get onbConnectNote => 'You can create a new code anytime in the Family tab.';

  @override
  String get loginSubtitle => 'Sign in to your parent account. Kids don\'t need an account.';

  @override
  String get emailLabel => 'Email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get signIn => 'Sign in';

  @override
  String get or => 'or';

  @override
  String get continueGoogle => 'Continue with Google';

  @override
  String get continueApple => 'Continue with Apple';

  @override
  String get usePhone => 'Use phone number';

  @override
  String get noAccount => 'Don\'t have an account?';

  @override
  String get createAccount => 'Create a new account';

  @override
  String get otpTitle => 'Enter the OTP code';

  @override
  String otpSubtitle(String phone) => 'A 6-digit code was sent by SMS to $phone.';

  @override
  String get phoneTitle => 'Your phone number';

  @override
  String get phoneSubtitle => 'We\'ll send an OTP code by SMS.';

  @override
  String get phoneLabel => 'Phone number';

  @override
  String get sendCode => 'Send code';

  @override
  String get otpLabel => 'OTP code';

  @override
  String get resendCode => 'Resend code';

  @override
  String demoOtp(String otp) => 'Demo mode: the OTP code is always $otp.';

  @override
  String get registerTitle => 'Create account';

  @override
  String get registerSubtitle => 'Create a parent account to store your family data.';

  @override
  String get passwordHint => 'At least 6 characters';

  @override
  String get repeatPassword => 'Repeat password';

  @override
  String get registering => 'Creating account...';

  @override
  String get register => 'Sign up';

  @override
  String get confirmEmailSent =>
      'Account created. Open the confirmation link in your email, then come back and sign in.';

  @override
  String get registerGoogle => 'Sign up with Google';

  @override
  String get haveAccount => 'Already have an account?';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get resetTitle => 'Reset password';

  @override
  String get resetSubtitle => 'Enter your account email. We\'ll send a code to set a new password.';

  @override
  String get resetCodeTitle => 'Check your email';

  @override
  String resetCodeSubtitle(String email) =>
      'If $email is registered, we sent an email with a link. Open it on this phone and tap the link. Check your spam folder too.';

  @override
  String get haveResetCode => 'Got a code in the email? Enter it here';

  @override
  String get resendEmail => 'Resend email';

  @override
  String get demoOpenResetLink => 'Open the email link (demo)';

  @override
  String get newPasswordTitle => 'Create a new password';

  @override
  String get newPasswordSubtitle => 'You signed in with the email link. Create a new password for this account.';

  @override
  String get resetCodeLabel => 'Code from email';

  @override
  String get newPassword => 'New password';

  @override
  String get saveNewPassword => 'Save & sign in';

  @override
  String demoResetCode(String code) => 'Demo mode: the code is always $code.';

  @override
  String get navHome => 'Home';

  @override
  String get navApprovals => 'Approvals';

  @override
  String get navFamily => 'Family';

  @override
  String get navHistory => 'History';

  @override
  String helloName(String name) => 'Hi, $name';

  @override
  String get familySettingsLabel => 'Family & settings';

  @override
  String get familyCardDesc => 'Members, invite codes, and settings';

  @override
  String get openFamily => 'Open family';

  @override
  String get pendingApprovalsTitle => 'Waiting for approval';

  @override
  String get nothingWaiting => 'Nothing is waiting.';

  @override
  String taskReportsCount(int n) => n == 1 ? '1 task report' : '$n task reports';

  @override
  String redemptionsCount(int n) => n == 1 ? '1 reward request' : '$n reward requests';

  @override
  String get openApprovalQueue => 'Open approval queue';

  @override
  String get noChildrenYet => 'No kids yet. Add them in the Family tab.';

  @override
  String pointsAmount(String points) => '$points points';

  @override
  String streakDays(int n) => n == 1 ? '1-day streak' : '$n-day streak';

  @override
  String goalPercent(int percent) => 'goal $percent%';

  @override
  String get notConnected => 'not connected';

  @override
  String get settings => 'Settings';

  @override
  String get todayTasks => 'Today\'s tasks';

  @override
  String get noTasksToday => 'No tasks today.';

  @override
  String get allTasksDone => 'All tasks done. Awesome!';

  @override
  String tasksLeft(int n) => n == 1 ? '1 task left, you got this!' : '$n tasks left, you got this!';

  @override
  String get signOutDeviceTitle => 'Sign out of this phone?';

  @override
  String get signOutChildNote => 'Your points stay safe. To sign in again, ask a parent for a new code.';

  @override
  String get cancel => 'Cancel';

  @override
  String get goal => 'Goal';

  @override
  String get newTask => 'New task';

  @override
  String get activeFilter => 'Active';

  @override
  String get archivedFilter => 'Archived';

  @override
  String get allChildren => 'All kids';

  @override
  String get allFrequencies => 'All frequencies';

  @override
  String get loadTasksFailed => 'Could not load tasks.';

  @override
  String get noArchivedTasks => 'No archived tasks.';

  @override
  String get noTasksYet => 'No tasks yet. Tap + to create one.';

  @override
  String get noMatchingTasks => 'No matching tasks.';

  @override
  String get noTasksForYou => 'No tasks for you yet. Ask a parent!';

  @override
  String get allTodayDone => 'All of today\'s tasks are done. Awesome!';

  @override
  String queuedReports(int n) => n == 1
      ? '1 report is waiting for signal. It will be sent automatically when the phone is back online.'
      : '$n reports are waiting for signal. They will be sent automatically when the phone is back online.';

  @override
  String get otherDays => 'Other days';

  @override
  String get tryToSend => 'Try sending';

  @override
  String get close => 'Close';

  @override
  String get waitingSignal => 'Waiting for signal';

  @override
  String get taskNotFound => 'Task not found';

  @override
  String get editTask => 'Edit task';

  @override
  String get taskNameLabel => 'Task name';

  @override
  String get taskNameHint => 'e.g. Water the plants';

  @override
  String get iconLabel => 'Icon';

  @override
  String get pointsLabel => 'Points';

  @override
  String get pointsChangeHint => 'Changing the points doesn\'t change points already given.';

  @override
  String get descriptionOptional => 'Description (optional)';

  @override
  String get taskDescHint => 'e.g. All the pots on the porch';

  @override
  String get howOften => 'How often?';

  @override
  String get daysLabel => 'Days';

  @override
  String get maxPerDay => 'Max reports per day';

  @override
  String get maxPerDayHint => 'Stops the easiest task from being repeated over and over.';

  @override
  String get verificationLabel => 'How to verify';

  @override
  String get verifyAutoHint => 'Points are added right away. You can undo it within 24 hours.';

  @override
  String get verifyApproveHint => 'Points are added after you approve the report.';

  @override
  String get verifyPhotoHint => 'Your kid must photograph the result with the in-app camera.';

  @override
  String get minPhotos => 'Minimum photos';

  @override
  String get beforeAfterLabel => 'Before & after photos';

  @override
  String get beforeAfterDesc => 'E.g. a messy room, then tidy.';

  @override
  String get allowGalleryLabel => 'Allow from gallery';

  @override
  String get allowGalleryDesc =>
      'E.g. a photo of test scores from the teacher. Usually camera only, so old photos can\'t be reused.';

  @override
  String get forWhom => 'Who is it for?';

  @override
  String get saveTask => 'Save task';

  @override
  String get reactivate => 'Reactivate';

  @override
  String get archiveAction => 'Archive';

  @override
  String get archiveTaskHint => 'Archived tasks disappear from the kid\'s list, but their history stays.';

  @override
  String taskIconName(String key) => switch (key) {
    'bed' => 'bed',
    'dish' => 'dishes',
    'book' => 'book',
    'pencil' => 'pencil',
    'broom' => 'broom',
    'trophy' => 'trophy',
    'tooth' => 'teeth',
    'dog' => 'pet',
    'plant' => 'plant',
    'basket' => 'basket',
    'shirt' => 'clothes',
    'trash' => 'trash',
    'bath' => 'bath',
    'math' => 'calculator',
    'music' => 'music',
    'run' => 'sport',
    _ => key,
  };

  @override
  String iconSemantic(String name) => '$name icon';

  @override
  String pointsEarned(String points) => '+$points points added!';

  @override
  String get newPhotoSent => 'New photo sent! Wait for a parent to check it.';

  @override
  String get reportSent => 'Report sent! Wait for a parent to check it.';

  @override
  String get ok => 'OK';

  @override
  String get preparingPhoto => 'Preparing photo...';

  @override
  String get cameraUnavailable => 'The camera couldn\'t be opened. Check the camera permission in your phone settings.';

  @override
  String get uploadingPhoto => 'Uploading photo...';

  @override
  String get offlineQueued => 'No signal. The report is saved and will be sent automatically later.';

  @override
  String takenAt(String time) => 'Taken $time';

  @override
  String retakeRequested(String reason) =>
      'A parent asked for a new photo: $reason. Your report still counts and your streak stays.';

  @override
  String get photoUnclear => 'the photo was unclear';

  @override
  String get reportAutoHint => 'Points are added as soon as you report.';

  @override
  String get reportApproveHint => 'A parent checks it first, then the points are added.';

  @override
  String get reportBeforeAfterHint => 'Take a photo before and after, then send it to a parent.';

  @override
  String get reportPhotoHint => 'Take a photo of your work, then send it to a parent.';

  @override
  String get noteOptional => 'Note (optional)';

  @override
  String get reportNoteHintPhoto => 'e.g. I wiped the table too';

  @override
  String get reportNoteHint => 'e.g. The plates are on the rack';

  @override
  String get sendRetake => 'Send new photo';

  @override
  String get sendReport => 'Send report';

  @override
  String photoTapToView(String name) => 'Photo $name, tap to view';

  @override
  String get retakePhoto => 'Retake';

  @override
  String photoOf(String kind) => 'Photo: $kind';

  @override
  String get takePhoto => 'Take photo';

  @override
  String get addPhoto => 'Add photo';

  @override
  String get fromGallery => 'From gallery';

  @override
  String get taskReports => 'Task reports';

  @override
  String taskReportsWithCount(int n) => 'Task reports ($n)';

  @override
  String get rewardRedemptions => 'Reward requests';

  @override
  String get loadReportsFailed => 'Could not load reports.';

  @override
  String get noPendingReports => 'No reports waiting. Nice!';

  @override
  String get waitingOver3Days => 'waiting > 3 days';

  @override
  String get noPendingRedemptions => 'No reward requests waiting.';

  @override
  String get redemptionRequested => 'requested';

  @override
  String get redemptionApprovedNotGiven => 'approved, not given yet';

  @override
  String get reportNotFound => 'Report not found';

  @override
  String reportedAt(String time) => 'Reported $time';

  @override
  String noteFrom(String name) => 'Note from $name';

  @override
  String get backToQueue => 'Back to queue';

  @override
  String get bonusOptional => 'Bonus (optional)';

  @override
  String get noBonus => 'No bonus';

  @override
  String get approve => 'Approve';

  @override
  String approveWithBonus(int bonus) => 'Approve + $bonus bonus';

  @override
  String get askRetake => 'Ask for new photo';

  @override
  String get reject => 'Reject';

  @override
  String get reasonPhotoBlurry => 'The photo is blurry';

  @override
  String get reasonResultNotVisible => 'The result isn\'t visible';

  @override
  String get reasonNotFinished => 'Not finished yet';

  @override
  String get reasonNotTidy => 'Not tidy enough';

  @override
  String get reasonNotAsAsked => 'Not what was asked';

  @override
  String get rejectReportTitle => 'Reject report';

  @override
  String get retakeExplain => 'The report still counts; your kid just retakes the photo. The streak stays.';

  @override
  String get rejectExplain => 'Your kid will see this reason and can report again.';

  @override
  String get reasonLabel => 'Reason';

  @override
  String get retakeNoteHint => 'e.g. The floor isn\'t visible';

  @override
  String get rejectReasonHint => 'e.g. The floor is still dirty';

  @override
  String get sendRejection => 'Send rejection';

  @override
  String get photosLoadFailed => 'Photos couldn\'t be loaded.';

  @override
  String get noPhotos => 'No photos.';

  @override
  String get fromGallerySuffix => ' · from gallery';

  @override
  String proofPhotoSemantic(int index, int total) => 'Proof photo $index of $total, tap to enlarge';

  @override
  String rejectReasonRequired(String name) => 'Write a reason for rejecting; $name will see it.';

  @override
  String redemptionSummary(String name, String points, String time) => '$name · $points points · $time';

  @override
  String screenTimeManual(String name, int minutes) =>
      'Unlock access for $name manually (Screen Time / Family Link) for $minutes minutes. The timer is already running on their phone.';

  @override
  String screenTimeAfterApprove(int minutes, String name) =>
      'Once approved, a $minutes-minute timer runs on $name\'s phone.';

  @override
  String get pointsHeld => 'The points are on hold. If rejected, they are refunded in full.';

  @override
  String get rejectReasonRequiredLabel => 'Reason (required to reject)';

  @override
  String get redemptionRejectHint => 'e.g. Tomorrow, it\'s late';

  @override
  String get markGivenHint => 'Approved. Mark it once the reward has been given.';

  @override
  String get markGiven => 'Given';

  @override
  String get rejectReasonRequiredGeneric => 'Write a reason so your kid knows what to fix.';

  @override
  String get rewardShop => 'Reward shop';

  @override
  String get loadRewardsFailed => 'Could not load rewards.';

  @override
  String get inProgressRedemptions => 'In progress';

  @override
  String get setAsideForGoal => 'Set aside points for your goal';

  @override
  String get instantRewards => 'Instant rewards';

  @override
  String get goalRewards => 'Goal rewards';

  @override
  String minutesAmount(int n) => n == 1 ? '1 minute' : '$n minutes';

  @override
  String get enough => 'Enough!';

  @override
  String shortBy(String points) => '$points short';

  @override
  String get requestSent => 'Request sent! Wait for a parent to approve it.';

  @override
  String get screenTimeApproved => 'Approved! Your session timer is running.';

  @override
  String get rewardYours => 'Yay! The reward is yours.';

  @override
  String priceLabel(String points) => 'Price: $points points';

  @override
  String balanceAfter(String points) => 'Your points after redeeming: $points';

  @override
  String pointsShortMore(String points) => 'You need $points more points.';

  @override
  String get parentWillApprove => 'A parent will approve it first.';

  @override
  String get oneMoment => 'One moment...';

  @override
  String get redeemNow => 'Redeem now';

  @override
  String shortPoints(String points) => '$points points short';

  @override
  String get makeGoal => 'Make it my goal';

  @override
  String waitingParentHeld(String points) => 'Waiting for a parent · $points points on hold';

  @override
  String get approvedWaitGiven => 'Approved, waiting to be given';

  @override
  String get cancelAction => 'Cancel';

  @override
  String timerSemantic(String title, int minutes) => '$title, $minutes minutes left';

  @override
  String get fiveMinutesLeft => '5 minutes left, get ready.';

  @override
  String untilTime(String time) => 'Until $time';

  @override
  String get setAsideTitle => 'Set aside for goal';

  @override
  String get setAsideNote => 'Points set aside can\'t be spent on instant rewards.';

  @override
  String allAmount(String points) => 'All ($points)';

  @override
  String get setAside => 'Set aside';

  @override
  String get priceRiseTitle => 'Price goes up in 7 days';

  @override
  String priceRiseBody(String points) =>
      'A kid is saving for this reward as a goal. To be fair, the new price of $points points applies in 7 days and they will be notified.';

  @override
  String get rewardNotFound => 'Reward not found';

  @override
  String get newReward => 'New reward';

  @override
  String get editReward => 'Edit reward';

  @override
  String get rewardNameLabel => 'Reward name';

  @override
  String get rewardNameHint => 'e.g. 30 minutes of gaming';

  @override
  String get priceInPoints => 'Price (points)';

  @override
  String pendingPriceHint(String points, String date) => 'The increase to $points points applies on $date.';

  @override
  String get typeLabel => 'Type';

  @override
  String get instantTypeLabel => 'Instant (screen time & small things)';

  @override
  String get instantTypeHint => 'Kids redeem anytime they have enough points, within the daily limit.';

  @override
  String get goalTypeHint => 'Kids save up and watch their progress until they have enough.';

  @override
  String get screenTimeDuration => 'Screen time length (minutes, optional)';

  @override
  String get screenTimeDurationHint => 'If set, a session timer runs on the kid\'s phone after approval.';

  @override
  String get maxPerDayShort => 'Max per day';

  @override
  String get noLimit => 'No limit';

  @override
  String get stockOptional => 'Stock (optional)';

  @override
  String get stockHint => 'Leave empty for unlimited';

  @override
  String get needsParentApproval => 'Needs parent approval';

  @override
  String get saveReward => 'Save reward';

  @override
  String get noArchivedRewards => 'No archived rewards.';

  @override
  String get noRewardsYet => 'No rewards yet. Tap + to create one.';

  @override
  String risesTo(String points, String date) => 'goes up to $points from $date';

  @override
  String get openRewardShop => 'Open reward shop';

  @override
  String get myGoal => 'My goal';

  @override
  String get noGoalYet => 'No goal yet. Pick a big reward you want to save for.';

  @override
  String get goalEnough => 'You have enough points! Redeem now.';

  @override
  String get collectPointsFirst => 'Collect some points first.';

  @override
  String daysLeftApprox(int n) => n == 1 ? '±1 day to go' : '±$n days to go';

  @override
  String get parentOrCaregiver => 'parent / caregiver';

  @override
  String inviteChildHint(String name) => 'On $name\'s phone: open the app, choose "I\'m a kid", then enter this code.';

  @override
  String get inviteAdultHint => 'On their phone: sign in with their own account, then choose "Have an invite code?".';

  @override
  String get save => 'Save';

  @override
  String get loadMembersFailed => 'Could not load family members.';

  @override
  String get children => 'Kids';

  @override
  String get noChildren => 'No kids yet.';

  @override
  String get connectedToChildPhone => 'Connected to the kid\'s phone';

  @override
  String get notConnectedToChildPhone => 'Not connected to the kid\'s phone yet';

  @override
  String get codeButton => 'Code';

  @override
  String get parentsAndCaregivers => 'Parents & caregivers';

  @override
  String get roleOwner => 'Owner';

  @override
  String get roleAdmin => 'Admin';

  @override
  String get inviteAdult => 'Invite a parent / caregiver';

  @override
  String get familySettings => 'Family settings';

  @override
  String get quietStartHelp => 'Bedtime starts';

  @override
  String get quietEndHelp => 'Bedtime ends';

  @override
  String get timezoneLabel => 'Time zone';

  @override
  String get timezoneHint => 'Decides when daily tasks and daily limits reset.';

  @override
  String get languageLabel => 'Language';

  @override
  String get languageHint => 'Applies to every phone in this family.';

  @override
  String get quietHoursLabel => 'Kids\' bedtime';

  @override
  String startsAt(String time) => 'Starts $time';

  @override
  String endsAt(String time) => 'Ends $time';

  @override
  String get quietHoursHint => 'Notifications for kids during these hours are held and sent after bedtime ends.';

  @override
  String get streakBonusLabel => '7-day streak bonus';

  @override
  String get none => 'None';

  @override
  String get allowNegativeLabel => 'Penalties may exceed the balance';

  @override
  String get allowNegativeHint => 'A kid\'s balance can go negative (point debt).';

  @override
  String get birthDateHelp => 'Birth date';

  @override
  String get childNameRequired => 'Please fill in the kid\'s nickname first.';

  @override
  String get childNameLabel => 'Kid\'s nickname';

  @override
  String get childNameHint => 'e.g. Raka';

  @override
  String get avatarColor => 'Avatar color';

  @override
  String get birthDateOptional => 'Birth date (optional)';

  @override
  String get birthDateUse => 'Used to suggest a points template for their age.';

  @override
  String get pickDate => 'Pick a date';

  @override
  String get penaltyBrokenPromise => 'Broke a promise';

  @override
  String get penaltyOverTime => 'Played over the time limit';

  @override
  String get penaltyForgotTask => 'Forgot an important task';

  @override
  String get bonusHelped => 'Helped without being asked';

  @override
  String get bonusGoodGrades => 'Good grades';

  @override
  String get bonusGoodAttitude => 'Great attitude today';

  @override
  String get amountRequired => 'Enter the number of points first.';

  @override
  String adjustReasonRequired(String name) => 'Write a reason. $name will see it.';

  @override
  String penaltyExceedsBalance(String name, String points) => 'The penalty exceeds $name\'s balance ($points points).';

  @override
  String penaltyFor(String name) => 'Penalty for $name';

  @override
  String bonusFor(String name) => 'Bonus for $name';

  @override
  String get pointsAmountLabel => 'Points';

  @override
  String get penaltyReasonHint => 'e.g. Played games past the limit';

  @override
  String get bonusReasonHint => 'e.g. Helped wash the car without being asked';

  @override
  String balanceBecomes(String name, String points) => '$name\'s balance becomes $points points.';

  @override
  String get givePenalty => 'Give penalty';

  @override
  String get giveBonus => 'Give bonus';

  @override
  String get reverseReasonRequired => 'Write a reason so your kid knows why it was undone.';

  @override
  String reverseTitle(String task) => 'Undo "$task"?';

  @override
  String get reverseExplain =>
      'The points for this task are taken back. If they were already spent, the balance can go negative (point debt) and is paid off automatically from the next points.';

  @override
  String get reverseReasonHint => 'e.g. The bed wasn\'t made';

  @override
  String get reverseTask => 'Undo task';

  @override
  String get childNotFound => 'Kid not found';

  @override
  String get loadDataFailed => 'Could not load data.';

  @override
  String get thisWeek => 'This week';

  @override
  String get tasksApproved => 'Tasks approved';

  @override
  String get pointsIn => 'Points in';

  @override
  String get pointsOut => 'Points out';

  @override
  String get bonus => 'Bonus';

  @override
  String get penalty => 'Penalty';

  @override
  String get pointsHistory => 'Points history';

  @override
  String get taskFallback => 'task';

  @override
  String get loadHistoryFailed => 'Could not load history.';

  @override
  String get statusWaitingParent => 'waiting for a parent';

  @override
  String get statusApproved => 'approved';

  @override
  String get statusGiven => 'given';

  @override
  String statusRejected(String reason) => 'rejected: $reason';

  @override
  String get statusCancelled => 'cancelled';

  @override
  String get pointTransactions => 'Point transactions';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get noTransactions => 'No point transactions yet.';

  @override
  String get goalSavings => 'goal savings';

  @override
  String get tapToUndo => 'tap to undo';

  @override
  String get freqOnce => 'Once';

  @override
  String get freqDaily => 'Daily';

  @override
  String get freqDaysOfWeek => 'Certain days';

  @override
  String get freqWeekly => 'Weekly';

  @override
  String get freqRepeat => 'Repeating';

  @override
  String get verifyAuto => 'Automatic';

  @override
  String get verifyApprove => 'Approval';

  @override
  String get verifyPhoto => 'Approval + photo';

  @override
  String isoDayShort(int day) => const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][day - 1];

  @override
  String isoDayLong(int day) =>
      const ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'][day - 1];

  @override
  String monthShort(int month) =>
      const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][month - 1];

  @override
  String todayAt(String time) => 'Today $time';

  @override
  String yesterdayAt(String time) => 'Yesterday $time';

  @override
  String get taskNameRequired => 'Enter a task name first.';

  @override
  String get taskNameTooLong => 'Task names can be up to 60 characters.';

  @override
  String get taskPointsRange => 'Points must be between 1 and 100,000.';

  @override
  String get pickAtLeastOneDay => 'Pick at least one day.';

  @override
  String get dailyLimitRange => 'Daily limit must be 1 to 20.';

  @override
  String get photoCountRange => 'Photos must be 1 to 3.';

  @override
  String get descriptionTooLong => 'Descriptions can be up to 500 characters.';

  @override
  String maxPerDayShortLabel(int n) => 'max $n×/day';

  @override
  String get rewardInstantShort => 'Instant';

  @override
  String get rewardNameRequired => 'Enter a reward name first.';

  @override
  String get rewardNameTooLong => 'Reward names can be up to 60 characters.';

  @override
  String get rewardCostRange => 'The price must be between 1 and 10,000,000 points.';

  @override
  String get durationRange => 'Length must be 1–1440 minutes.';

  @override
  String get rewardDailyLimitMin => 'The daily limit must be at least 1.';

  @override
  String get stockNotNegative => 'Stock can\'t be negative.';

  @override
  String stockAmount(int n) => '$n in stock';

  @override
  String get needsApprovalShort => 'needs approval';

  @override
  String get immediate => 'immediate';

  @override
  String get ledgerTask => 'Task';

  @override
  String ledgerBonus(String reason) => 'Bonus: $reason';

  @override
  String get greatWork => 'great work';

  @override
  String ledgerPenalty(String reason) => 'Penalty: $reason';

  @override
  String get ledgerStreak => 'Streak bonus';

  @override
  String ledgerRedeem(String reason) => 'Redeemed: $reason';

  @override
  String get rewardFallback => 'reward';

  @override
  String ledgerRefund(String? reason) => reason == null ? 'Points refunded' : 'Points refunded: $reason';

  @override
  String ledgerReversal(String reason) => 'Undone: $reason';

  @override
  String get ledgerGoalSave => 'Saved for goal';

  @override
  String get ledgerGoalUnsave => 'Taken from goal savings';

  @override
  String get notScheduledToday => 'Not scheduled today';

  @override
  String get notDoneYet => 'Not done yet';

  @override
  String get waitingApproval => 'Waiting for approval';

  @override
  String get needsNewPhoto => 'Needs a new photo';

  @override
  String get rejectedTryAgain => 'Rejected, try again';

  @override
  String rejectedReasonTryAgain(String reason) => 'Rejected: $reason. Try again';

  @override
  String get undoneByParent => 'Undone by a parent';

  @override
  String approvedCanRepeat(int used, int limit) => 'Approved · can do again ($used/$limit)';

  @override
  String get approvedLabel => 'Approved';

  @override
  String get photoBefore => 'Before';

  @override
  String get photoAfter => 'After';

  @override
  String get needBeforeAfter => 'Needs before & after photos';

  @override
  String get needBefore => 'Needs a before photo';

  @override
  String get needAfter => 'Needs an after photo';

  @override
  String needMorePhotos(int n) => n == 1 ? 'Needs 1 more photo' : 'Needs $n more photos';

  @override
  String ageBandLabel(String range) => '$range years';

  @override
  String get familyNameRequired => 'Enter a family name.';

  @override
  String get familyNameTooLong => 'Family names can be up to 60 characters.';

  @override
  String get streakBonusRange => 'Streak bonus must be 0–100%.';

  @override
  String get reportExpired => 'Reports saved more than 24 hours ago can\'t be sent anymore.';

  @override
  String reportNotSent(String reason) => 'One report was not sent: $reason';

  @override
  String get streakSuccess => 'done';

  @override
  String get streakPending => 'waiting for approval';

  @override
  String get streakEmpty => 'none';

  @override
  String get streakToday => 'today, no report yet';

  @override
  String get daysInARow => ' days in a row';

  @override
  String get streakPendingNote => 'Waiting for approval, your streak is safe for now.';

  @override
  String get debtPaidAutomatically => 'It will be paid off automatically from your next points.';

  @override
  String inGoalSavings(String points) => '+ $points in goal savings';

  @override
  String beingRedeemed(String points) => '$points being redeemed';

  @override
  String debtSemantic(String points) => 'Point debt $points';

  @override
  String balanceSemantic(String points) => 'Balance $points points';

  @override
  String get pointDebt => 'Point debt';

  @override
  String get photoLoadFailed => 'The photo couldn\'t be loaded.';

  @override
  String proofPhotoOf(int index, int total) => 'Proof photo $index of $total';

  @override
  String get closePhoto => 'Close photo';

  @override
  String codeFor(String name) => 'Code for $name';

  @override
  String codeSemantic(String spaced) => 'Code $spaced';

  @override
  String get codeValidity => 'Valid for 24 hours and can only be used once.';

  @override
  String decrease(String label) => 'Decrease $label';

  @override
  String increase(String label) => 'Increase $label';

  @override
  String goalProgressSemantic(String title, String saved, String target, int percent) =>
      'Goal $title, $saved of $target points, $percent percent';

  @override
  String stepOf(int step, int total) => 'Step $step of $total';

  @override
  String get emailHint => 'name@email.com';

  @override
  String avatarSemantic(String color) => '$color avatar';

  @override
  String avatarColorName(String key) => switch (key) {
    'lime' => 'green',
    'lilac' => 'purple',
    'sky' => 'blue',
    'peach' => 'orange',
    'butter' => 'yellow',
    _ => key,
  };
}
