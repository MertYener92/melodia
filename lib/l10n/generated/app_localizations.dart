import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
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
    Locale('tr'),
  ];

  /// Bottom nav label for the AI Music tab
  ///
  /// In en, this message translates to:
  /// **'AI Music'**
  String get navAiMusic;

  /// Bottom nav label for the AI Video tab
  ///
  /// In en, this message translates to:
  /// **'AI Video'**
  String get navAiVideo;

  /// Bottom nav label for the Library tab
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get navLibrary;

  /// Bottom nav label for the Profile tab
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// Small pill badge on the home hero screen
  ///
  /// In en, this message translates to:
  /// **'AI SONG GENERATOR'**
  String get createBadge;

  /// Big headline on the home hero screen
  ///
  /// In en, this message translates to:
  /// **'Generate Your Song'**
  String get createTitle;

  /// Subtitle under the headline on the home hero screen
  ///
  /// In en, this message translates to:
  /// **'Turn your ideas into original songs with AI in seconds.'**
  String get createSubtitle;

  /// Primary CTA button on the home hero screen
  ///
  /// In en, this message translates to:
  /// **'Generate Song'**
  String get createButton;

  /// Heading on the profile screen
  ///
  /// In en, this message translates to:
  /// **'Your profile'**
  String get profileTitle;

  /// Stat card label for song count
  ///
  /// In en, this message translates to:
  /// **'Songs'**
  String get profileSongs;

  /// Stat card label for favorites count
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get profileFavorites;

  /// Menu item leading to settings
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get profileSettings;

  /// Menu item leading to the paywall
  ///
  /// In en, this message translates to:
  /// **'Upgrade Plan'**
  String get profileUpgradePlan;

  /// Menu item for help and support
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get profileHelpSupport;

  /// Menu item for app info
  ///
  /// In en, this message translates to:
  /// **'About Melodia Studio'**
  String get profileAboutApp;

  /// Settings menu row label for language selection
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// Title of the language picker sheet
  ///
  /// In en, this message translates to:
  /// **'Choose Language'**
  String get settingsLanguagePickerTitle;

  /// Option to follow the device's language automatically
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get settingsLanguageSystemDefault;

  /// Heading on the library hero header
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get libraryHeroTitle;

  /// Subtitle under the library heading
  ///
  /// In en, this message translates to:
  /// **'All your creations, in one place.'**
  String get libraryHeroSubtitle;

  /// Decorative italic quote on the library hero, multi-line
  ///
  /// In en, this message translates to:
  /// **'Good ideas\nare always\nsaved somewhere.'**
  String get libraryQuote;

  /// Small caps tagline under the quote
  ///
  /// In en, this message translates to:
  /// **'CREATE  ·  DISCOVER  ·  SAVE'**
  String get libraryTagline;

  /// Hub card title for songs
  ///
  /// In en, this message translates to:
  /// **'My Songs'**
  String get librarySongsTitle;

  /// Hub card subtitle for songs
  ///
  /// In en, this message translates to:
  /// **'All the songs you\'ve made.'**
  String get librarySongsSubtitle;

  /// Song count label on the songs hub card
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No songs} one{1 song} other{{count} songs}}'**
  String librarySongsCount(int count);

  /// Hub card title for videos
  ///
  /// In en, this message translates to:
  /// **'My Videos'**
  String get libraryVideosTitle;

  /// Hub card subtitle for videos
  ///
  /// In en, this message translates to:
  /// **'All the videos you\'ve made.'**
  String get libraryVideosSubtitle;

  /// Video count label on the videos hub card
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No videos} one{1 video} other{{count} videos}}'**
  String libraryVideosCount(int count);

  /// Hub card title for favorites
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get libraryFavoritesTitle;

  /// Hub card subtitle for favorites
  ///
  /// In en, this message translates to:
  /// **'Content you\'ve liked.'**
  String get libraryFavoritesSubtitle;

  /// Favorites count label on the favorites hub card
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No items} one{1 item} other{{count} items}}'**
  String libraryFavoritesCount(int count);

  /// Hub card title for downloads
  ///
  /// In en, this message translates to:
  /// **'Downloads'**
  String get libraryDownloadsTitle;

  /// Hub card subtitle for downloads
  ///
  /// In en, this message translates to:
  /// **'What you\'ve saved to your device.'**
  String get libraryDownloadsSubtitle;

  /// No description provided for @actionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// No description provided for @actionLogout.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get actionLogout;

  /// No description provided for @dangerZoneTitle.
  ///
  /// In en, this message translates to:
  /// **'DANGER ZONE'**
  String get dangerZoneTitle;

  /// No description provided for @deleteAccountConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Permanently delete your account'**
  String get deleteAccountConfirmTitle;

  /// No description provided for @deleteAccountConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone. All your songs, video clips, and account information will be PERMANENTLY deleted. Are you sure you want to continue?'**
  String get deleteAccountConfirmBody;

  /// No description provided for @deleteAccountShort.
  ///
  /// In en, this message translates to:
  /// **'Delete My Account'**
  String get deleteAccountShort;

  /// No description provided for @deleteAccountBody.
  ///
  /// In en, this message translates to:
  /// **'All your songs, video clips, and account information will be permanently deleted. This action cannot be undone.'**
  String get deleteAccountBody;

  /// No description provided for @deleteAccountPermanentButton.
  ///
  /// In en, this message translates to:
  /// **'Permanently Delete My Account'**
  String get deleteAccountPermanentButton;

  /// No description provided for @genericUnexpectedError.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred.'**
  String get genericUnexpectedError;

  /// No description provided for @searchSongsHint.
  ///
  /// In en, this message translates to:
  /// **'Search songs...'**
  String get searchSongsHint;

  /// No description provided for @noSongsFound.
  ///
  /// In en, this message translates to:
  /// **'No songs found'**
  String get noSongsFound;

  /// No description provided for @removeFromFavorites.
  ///
  /// In en, this message translates to:
  /// **'Remove from favorites'**
  String get removeFromFavorites;

  /// No description provided for @addToFavorites.
  ///
  /// In en, this message translates to:
  /// **'Add to favorites'**
  String get addToFavorites;

  /// No description provided for @actionRename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get actionRename;

  /// No description provided for @actionShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get actionShare;

  /// No description provided for @shareComingSoonMessage.
  ///
  /// In en, this message translates to:
  /// **'Sharing will be available soon.'**
  String get shareComingSoonMessage;

  /// No description provided for @actionDownload.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get actionDownload;

  /// No description provided for @downloadComingSoonMessage.
  ///
  /// In en, this message translates to:
  /// **'Downloading will be available soon.'**
  String get downloadComingSoonMessage;

  /// No description provided for @actionDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get actionDelete;

  /// No description provided for @renameSongTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename song'**
  String get renameSongTitle;

  /// No description provided for @actionSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get actionSave;

  /// No description provided for @favoritesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No favorites yet'**
  String get favoritesEmptyTitle;

  /// No description provided for @favoritesEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Tap the ♥ icon while playing a song or clip.'**
  String get favoritesEmptyBody;

  /// No description provided for @sectionSongs.
  ///
  /// In en, this message translates to:
  /// **'Songs'**
  String get sectionSongs;

  /// No description provided for @sectionVideos.
  ///
  /// In en, this message translates to:
  /// **'Videos'**
  String get sectionVideos;

  /// No description provided for @untitledClip.
  ///
  /// In en, this message translates to:
  /// **'Untitled clip'**
  String get untitledClip;

  /// No description provided for @comingSoonTitle.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoonTitle;

  /// No description provided for @downloadsComingSoonBody.
  ///
  /// In en, this message translates to:
  /// **'We\'re working on letting you see the songs and videos you\'ve downloaded to your device here.'**
  String get downloadsComingSoonBody;

  /// No description provided for @aiMusicSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Describe the song in your mind, we\'ll take care of the rest.'**
  String get aiMusicSubtitle;

  /// No description provided for @modeAdvancedTitle.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get modeAdvancedTitle;

  /// No description provided for @modeAdvancedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Describe the music like you would to a person — its world, feeling, story. AI turns it into a professional production.'**
  String get modeAdvancedSubtitle;

  /// No description provided for @modeStandardTitle.
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get modeStandardTitle;

  /// No description provided for @modeStandardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick the style, mood, vocal and length yourself — a quick, clear form that puts you fully in control while still creating your song in just a few simple steps.'**
  String get modeStandardSubtitle;

  /// No description provided for @modeQuickTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick'**
  String get modeQuickTitle;

  /// No description provided for @modeQuickSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Describe your idea in one sentence and let AI handle the rest — genre, tempo, vocal style and lyrical theme are all chosen automatically for you.'**
  String get modeQuickSubtitle;

  /// No description provided for @createFormAppBarTitle.
  ///
  /// In en, this message translates to:
  /// **'Create your song'**
  String get createFormAppBarTitle;

  /// No description provided for @createFormHeadline.
  ///
  /// In en, this message translates to:
  /// **'Create your next song'**
  String get createFormHeadline;

  /// No description provided for @createFormSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Turn your ideas into music with AI'**
  String get createFormSubtitle;

  /// No description provided for @describeSongFirst.
  ///
  /// In en, this message translates to:
  /// **'Please describe your song first.'**
  String get describeSongFirst;

  /// No description provided for @songReadyMessage.
  ///
  /// In en, this message translates to:
  /// **'Your song is ready! 🎶'**
  String get songReadyMessage;

  /// No description provided for @describeSongLabel.
  ///
  /// In en, this message translates to:
  /// **'Describe your song'**
  String get describeSongLabel;

  /// No description provided for @describeSongHint.
  ///
  /// In en, this message translates to:
  /// **'A romantic pop song about summer nights...'**
  String get describeSongHint;

  /// No description provided for @labelGenre.
  ///
  /// In en, this message translates to:
  /// **'GENRE'**
  String get labelGenre;

  /// No description provided for @labelMood.
  ///
  /// In en, this message translates to:
  /// **'MOOD'**
  String get labelMood;

  /// No description provided for @labelVocal.
  ///
  /// In en, this message translates to:
  /// **'VOCAL'**
  String get labelVocal;

  /// No description provided for @labelSongLength.
  ///
  /// In en, this message translates to:
  /// **'SONG LENGTH'**
  String get labelSongLength;

  /// No description provided for @quickCreateHeadline.
  ///
  /// In en, this message translates to:
  /// **'Describe your song in one sentence'**
  String get quickCreateHeadline;

  /// No description provided for @quickCreateSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Let AI handle the rest — genre, tempo, vocal, lyrical theme, all automatic.'**
  String get quickCreateSubtitle;

  /// No description provided for @quickCreateHint.
  ///
  /// In en, this message translates to:
  /// **'E.g: A cool but slightly dark song to listen to while driving through the city at night'**
  String get quickCreateHint;

  /// No description provided for @preparingLabel.
  ///
  /// In en, this message translates to:
  /// **'Preparing...'**
  String get preparingLabel;

  /// No description provided for @actionCreate.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get actionCreate;

  /// Generic error message with a technical detail appended
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred: {error}'**
  String unexpectedErrorWithDetail(String error);

  /// No description provided for @proUpsellTitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock Your Creativity'**
  String get proUpsellTitle;

  /// No description provided for @proUpsellSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create more. Create better.'**
  String get proUpsellSubtitle;

  /// No description provided for @planWeeklyTitle.
  ///
  /// In en, this message translates to:
  /// **'7-Day Access'**
  String get planWeeklyTitle;

  /// No description provided for @planWeeklySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Unlimited access, billed weekly'**
  String get planWeeklySubtitle;

  /// No description provided for @planYearlyTitle.
  ///
  /// In en, this message translates to:
  /// **'Yearly Access'**
  String get planYearlyTitle;

  /// No description provided for @planYearlyBadge.
  ///
  /// In en, this message translates to:
  /// **'Best Value'**
  String get planYearlyBadge;

  /// No description provided for @featureSongsVideos.
  ///
  /// In en, this message translates to:
  /// **'Create AI Songs & Music Videos'**
  String get featureSongsVideos;

  /// No description provided for @featureVoiceCovers.
  ///
  /// In en, this message translates to:
  /// **'Make AI Covers with Your Own Voice'**
  String get featureVoiceCovers;

  /// No description provided for @featurePriorityGeneration.
  ///
  /// In en, this message translates to:
  /// **'Priority Generation'**
  String get featurePriorityGeneration;

  /// No description provided for @featureCommercialLicense.
  ///
  /// In en, this message translates to:
  /// **'Commercial License Included'**
  String get featureCommercialLicense;

  /// No description provided for @ctaContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get ctaContinue;

  /// No description provided for @cancelAnytimeNote.
  ///
  /// In en, this message translates to:
  /// **'Cancel anytime.'**
  String get cancelAnytimeNote;

  /// No description provided for @restorePurchasesAction.
  ///
  /// In en, this message translates to:
  /// **'Restore purchases'**
  String get restorePurchasesAction;

  /// No description provided for @purchaseSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Your subscription is active! Welcome to Pro.'**
  String get purchaseSuccessMessage;

  /// Placeholder string for saveBadge
  ///
  /// In en, this message translates to:
  /// **'Save {percent}%'**
  String saveBadge(int percent);

  /// Placeholder string for productsLoadErrorWithDetail
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load products: {error}'**
  String productsLoadErrorWithDetail(String error);

  /// Placeholder string for purchaseStartErrorWithDetail
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t start the purchase: {error}'**
  String purchaseStartErrorWithDetail(String error);
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
      <String>['en', 'es', 'tr'].contains(locale.languageCode);

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
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
