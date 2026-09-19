// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get navAiMusic => 'AI Music';

  @override
  String get navAiVideo => 'AI Video';

  @override
  String get navLibrary => 'Library';

  @override
  String get navProfile => 'Profile';

  @override
  String get createBadge => 'AI SONG GENERATOR';

  @override
  String get createTitle => 'Generate Your Song';

  @override
  String get createSubtitle =>
      'Turn your ideas into original songs with AI in seconds.';

  @override
  String get createButton => 'Generate Song';

  @override
  String get profileTitle => 'Your profile';

  @override
  String get profileSongs => 'Songs';

  @override
  String get profileFavorites => 'Favorites';

  @override
  String get profileSettings => 'Settings';

  @override
  String get profileUpgradePlan => 'Upgrade Plan';

  @override
  String get profileHelpSupport => 'Help & Support';

  @override
  String get profileAboutApp => 'About Melodia Studio';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguagePickerTitle => 'Choose Language';

  @override
  String get settingsLanguageSystemDefault => 'System Default';

  @override
  String get libraryHeroTitle => 'Library';

  @override
  String get libraryHeroSubtitle => 'All your creations, in one place.';

  @override
  String get libraryQuote => 'Good ideas\nare always\nsaved somewhere.';

  @override
  String get libraryTagline => 'CREATE  ·  DISCOVER  ·  SAVE';

  @override
  String get librarySongsTitle => 'My Songs';

  @override
  String get librarySongsSubtitle => 'All the songs you\'ve made.';

  @override
  String librarySongsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count songs',
      one: '1 song',
      zero: 'No songs',
    );
    return '$_temp0';
  }

  @override
  String get libraryVideosTitle => 'My Videos';

  @override
  String get libraryVideosSubtitle => 'All the videos you\'ve made.';

  @override
  String libraryVideosCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count videos',
      one: '1 video',
      zero: 'No videos',
    );
    return '$_temp0';
  }

  @override
  String get libraryFavoritesTitle => 'Favorites';

  @override
  String get libraryFavoritesSubtitle => 'Content you\'ve liked.';

  @override
  String libraryFavoritesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
      zero: 'No items',
    );
    return '$_temp0';
  }

  @override
  String get libraryDownloadsTitle => 'Downloads';

  @override
  String get libraryDownloadsSubtitle => 'What you\'ve saved to your device.';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionLogout => 'Log Out';

  @override
  String get dangerZoneTitle => 'DANGER ZONE';

  @override
  String get deleteAccountConfirmTitle => 'Permanently delete your account';

  @override
  String get deleteAccountConfirmBody =>
      'This action cannot be undone. All your songs, video clips, and account information will be PERMANENTLY deleted. Are you sure you want to continue?';

  @override
  String get deleteAccountShort => 'Delete My Account';

  @override
  String get deleteAccountBody =>
      'All your songs, video clips, and account information will be permanently deleted. This action cannot be undone.';

  @override
  String get deleteAccountPermanentButton => 'Permanently Delete My Account';

  @override
  String get genericUnexpectedError => 'An unexpected error occurred.';

  @override
  String get searchSongsHint => 'Search songs...';

  @override
  String get noSongsFound => 'No songs found';

  @override
  String get removeFromFavorites => 'Remove from favorites';

  @override
  String get addToFavorites => 'Add to favorites';

  @override
  String get actionRename => 'Rename';

  @override
  String get actionShare => 'Share';

  @override
  String get shareComingSoonMessage => 'Sharing will be available soon.';

  @override
  String get actionDownload => 'Download';

  @override
  String get downloadComingSoonMessage => 'Downloading will be available soon.';

  @override
  String get actionDelete => 'Delete';

  @override
  String get renameSongTitle => 'Rename song';

  @override
  String get actionSave => 'Save';

  @override
  String get favoritesEmptyTitle => 'No favorites yet';

  @override
  String get favoritesEmptyBody =>
      'Tap the ♥ icon while playing a song or clip.';

  @override
  String get sectionSongs => 'Songs';

  @override
  String get sectionVideos => 'Videos';

  @override
  String get untitledClip => 'Untitled clip';

  @override
  String get comingSoonTitle => 'Coming soon';

  @override
  String get downloadsComingSoonBody =>
      'We\'re working on letting you see the songs and videos you\'ve downloaded to your device here.';

  @override
  String get aiMusicSubtitle =>
      'Describe the song in your mind, we\'ll take care of the rest.';

  @override
  String get modeAdvancedTitle => 'Advanced';

  @override
  String get modeAdvancedSubtitle =>
      'Describe the music like you would to a person — its world, feeling, story. AI turns it into a professional production.';

  @override
  String get modeStandardTitle => 'Standard';

  @override
  String get modeStandardSubtitle =>
      'Pick the style, mood, vocal and length yourself — a quick, clear form that puts you fully in control while still creating your song in just a few simple steps.';

  @override
  String get modeQuickTitle => 'Quick';

  @override
  String get modeQuickSubtitle =>
      'Describe your idea in one sentence and let AI handle the rest — genre, tempo, vocal style and lyrical theme are all chosen automatically for you.';

  @override
  String get createFormAppBarTitle => 'Create your song';

  @override
  String get createFormHeadline => 'Create your next song';

  @override
  String get createFormSubtitle => 'Turn your ideas into music with AI';

  @override
  String get describeSongFirst => 'Please describe your song first.';

  @override
  String get songReadyMessage => 'Your song is ready! 🎶';

  @override
  String get describeSongLabel => 'Describe your song';

  @override
  String get describeSongHint => 'A romantic pop song about summer nights...';

  @override
  String get labelGenre => 'GENRE';

  @override
  String get labelMood => 'MOOD';

  @override
  String get labelVocal => 'VOCAL';

  @override
  String get labelSongLength => 'SONG LENGTH';

  @override
  String get quickCreateHeadline => 'Describe your song in one sentence';

  @override
  String get quickCreateSubtitle =>
      'Let AI handle the rest — genre, tempo, vocal, lyrical theme, all automatic.';

  @override
  String get quickCreateHint =>
      'E.g: A cool but slightly dark song to listen to while driving through the city at night';

  @override
  String get preparingLabel => 'Preparing...';

  @override
  String get actionCreate => 'Create';

  @override
  String unexpectedErrorWithDetail(String error) {
    return 'An unexpected error occurred: $error';
  }

  @override
  String get proUpsellTitle => 'Unlock Your Creativity';

  @override
  String get proUpsellSubtitle => 'Create more. Create better.';

  @override
  String get planWeeklyTitle => '7-Day Access';

  @override
  String get planWeeklySubtitle => 'Unlimited access, billed weekly';

  @override
  String get planYearlyTitle => 'Yearly Access';

  @override
  String get planYearlyBadge => 'Best Value';

  @override
  String get featureSongsVideos => 'Create AI Songs & Music Videos';

  @override
  String get featureVoiceCovers => 'Make AI Covers with Your Own Voice';

  @override
  String get featurePriorityGeneration => 'Priority Generation';

  @override
  String get featureCommercialLicense => 'Commercial License Included';

  @override
  String get ctaContinue => 'Continue';

  @override
  String get cancelAnytimeNote => 'Cancel anytime.';

  @override
  String get restorePurchasesAction => 'Restore purchases';

  @override
  String get purchaseSuccessMessage =>
      'Your subscription is active! Welcome to Pro.';

  @override
  String saveBadge(int percent) {
    return 'Save $percent%';
  }

  @override
  String productsLoadErrorWithDetail(String error) {
    return 'Couldn\'t load products: $error';
  }

  @override
  String purchaseStartErrorWithDetail(String error) {
    return 'Couldn\'t start the purchase: $error';
  }

  @override
  String get loginHeadline => 'Bring your music\nto life.';

  @override
  String get loginSignInWithApple => 'Continue with Apple';

  @override
  String get loginOr => 'or';

  @override
  String get loginEmailLabel => 'Email';

  @override
  String get loginPasswordLabel => 'Password (min. 8 characters)';

  @override
  String get loginVerificationCodeLabel => 'Verification code';

  @override
  String get loginTitleSignIn => 'Sign in to continue';

  @override
  String get loginTitleSignUp => 'Create a new account';

  @override
  String get loginTitleConfirm => 'Verify your email';

  @override
  String get loginButtonSignIn => 'Sign In';

  @override
  String get loginButtonSignUp => 'Sign Up';

  @override
  String get loginButtonConfirm => 'Verify';

  @override
  String get loginNoAccount => 'Don\'t have an account? Sign up';

  @override
  String get loginHaveAccount => 'Already have an account? Sign in';

  @override
  String loginAppleSignInFailedWithDetail(String error) {
    return 'Apple sign-in failed: $error';
  }

  @override
  String loginConfirmCodeSentTo(String email) {
    return 'Enter the 6-digit code sent to $email.';
  }

  @override
  String get settingsSectionSettings => 'Settings';

  @override
  String get settingsSectionSupport => 'Support';

  @override
  String get settingsSectionAbout => 'About';

  @override
  String get settingsSectionAccount => 'Account';

  @override
  String get settingsDisplayLanguage => 'Display Language';

  @override
  String get settingsHomepagePreference => 'Homepage Preference';

  @override
  String get settingsEmailSupport => 'Email Support';

  @override
  String get settingsHelpCenter => 'Help Center';

  @override
  String get settingsRequestFeature => 'Request a Feature';

  @override
  String get settingsUploadVoice => 'Upload Voice';

  @override
  String get settingsShareWithFriends => 'Share with Friends';

  @override
  String get settingsRateIt => 'Rate It';

  @override
  String get settingsTermsPrivacy => 'Terms and Privacy';

  @override
  String get settingsCopyrightRemoval => 'Copyright Removal Request';

  @override
  String get settingsAboutUs => 'About Us';

  @override
  String get settingsComingSoon => 'Coming soon';

  @override
  String get settingsShareMessage =>
      'Check out Melodia — create your own songs with AI!';

  @override
  String get profileEditProfile => 'Edit Profile';

  @override
  String get profileCompleteTitle => 'Complete Your Profile';

  @override
  String get profileNoSongsYet => 'No songs published yet';

  @override
  String get profileBrowseSongs => 'Browse your songs';

  @override
  String get profileStepTitle0 => 'What should we call you?';

  @override
  String get profileStepSubtitle0 => 'Set your display name';

  @override
  String get profileStepTitle1 => 'Choose a profile photo';

  @override
  String get profileStepSubtitle1 => 'Give your profile a face';

  @override
  String get profileStepTitle2 => 'Which music genres do you like?';

  @override
  String get profileStepSubtitle2 => 'Pick your 1-5 favorite genres';

  @override
  String get profileStepTitle3 => 'What do you want to create on Melodia?';

  @override
  String get profileStepSubtitle3 =>
      'Let\'s shape your personal recommendations';

  @override
  String get settingsAccountInfo => 'Account Information';

  @override
  String get settingsSubscription => 'Subscription & Payment';

  @override
  String get settingsCredits => 'Credits';

  @override
  String profileStepOf(int step) {
    return 'Step $step of 4';
  }

  @override
  String get settingsSectionMembership => 'Membership';

  @override
  String get settingsSectionUsage => 'Usage';

  @override
  String get accountUserId => 'User ID';

  @override
  String get accountName => 'Name';

  @override
  String get accountEmail => 'Email';

  @override
  String get accountMemberSince => 'Member Since';

  @override
  String get accountCurrentPlan => 'Current Plan';

  @override
  String get accountTotalSongs => 'Total Songs Created';

  @override
  String get accountIdCopied => 'User ID copied';

  @override
  String get accountUnknown => 'Unknown';

  @override
  String get planFree => 'Free Plan';

  @override
  String get planProWeekly => 'Pro • Weekly';

  @override
  String get planProMonthly => 'Pro • Monthly';

  @override
  String get planProYearly => 'Pro • Yearly';

  @override
  String get playerMinimize => 'Minimize';

  @override
  String get playerMoreActions => 'More';

  @override
  String get playerAiGenerated => 'AI Generated';

  @override
  String get playerRemix => 'Remix';

  @override
  String get playerShare => 'Share';

  @override
  String get playerPlaylist => 'Playlist';

  @override
  String get playerComment => 'Comment';

  @override
  String get playerComingSoon => 'Coming soon';

  @override
  String get playerAddFavorite => 'Add to favorites';

  @override
  String get playerRemoveFavorite => 'Remove from favorites';

  @override
  String get playerDownload => 'Download';

  @override
  String get playerLyrics => 'Lyrics';

  @override
  String get playerCreateVideo => 'Create music video';

  @override
  String get playerShuffle => 'Shuffle';

  @override
  String get playerRepeat => 'Repeat';

  @override
  String get playerPrevious => 'Previous';

  @override
  String get playerNext => 'Next';

  @override
  String get playerPlay => 'Play';

  @override
  String get playerPause => 'Pause';

  @override
  String get playerNoSong => 'No song playing';

  @override
  String get remixHint => 'Describe the new style…';

  @override
  String get remixCreate => 'Create remix';

  @override
  String get remixInstrumental => 'Instrumental';

  @override
  String get remixStarted => 'Remix is being prepared';

  @override
  String get remixReady => 'Your remix is ready';

  @override
  String get remixFailed => 'Remix could not be created';

  @override
  String get remixView => 'View';

  @override
  String get remixListen => 'Listen';

  @override
  String get remixBuyCredits => 'Get credits';

  @override
  String get remixCreditsNeeded => 'Not enough credits for a remix.';

  @override
  String get remixStyleAcoustic => 'Acoustic';

  @override
  String get remixStyleRock => 'Rock';

  @override
  String get remixStyleLofi => 'Lo-fi';

  @override
  String get remixStyleEdm => 'EDM';

  @override
  String get remixStyleJazz => 'Jazz';

  @override
  String get remixStyleOrchestral => 'Orchestral';

  @override
  String get remixStyleRnb => 'R&B';

  @override
  String get remixStyleTrap => 'Trap';

  @override
  String get remixStyle80s => '80s Synthwave';

  @override
  String get remixStyleLatin => 'Latin';

  @override
  String get remixStartedDetail => 'We\'ll let you know when it\'s ready.';

  @override
  String get remixFailedDetail => 'No credits were spent — you can try again.';
}
