import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_it.dart';

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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
    Locale('it'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Trainer Atlas 5e'**
  String get appTitle;

  /// No description provided for @infoAction.
  ///
  /// In en, this message translates to:
  /// **'INFO'**
  String get infoAction;

  /// No description provided for @reviewTourTooltip.
  ///
  /// In en, this message translates to:
  /// **'INFO · Review the tour'**
  String get reviewTourTooltip;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Language and application preferences.'**
  String get settingsSubtitle;

  /// No description provided for @languageSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'LANGUAGE'**
  String get languageSectionTitle;

  /// No description provided for @languageSectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose how Trainer Atlas 5e selects the interface language.'**
  String get languageSectionSubtitle;

  /// No description provided for @languageSystemTitle.
  ///
  /// In en, this message translates to:
  /// **'Device language'**
  String get languageSystemTitle;

  /// No description provided for @languageSystemSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Uses Italian or English when available and falls back to English for every other device language.'**
  String get languageSystemSubtitle;

  /// No description provided for @languageItalianTitle.
  ///
  /// In en, this message translates to:
  /// **'Italiano'**
  String get languageItalianTitle;

  /// No description provided for @languageItalianSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Always use the Italian interface.'**
  String get languageItalianSubtitle;

  /// No description provided for @languageEnglishTitle.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglishTitle;

  /// No description provided for @languageEnglishSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Always use the English interface.'**
  String get languageEnglishSubtitle;

  /// No description provided for @homeTourDashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Your dashboard'**
  String get homeTourDashboardTitle;

  /// No description provided for @homeTourDashboardDescription.
  ///
  /// In en, this message translates to:
  /// **'See the active profile, level, money, available Poké Slots and the maximum challenge rating you can control.'**
  String get homeTourDashboardDescription;

  /// No description provided for @homeTourTrainerTitle.
  ///
  /// In en, this message translates to:
  /// **'Trainer and team'**
  String get homeTourTrainerTitle;

  /// No description provided for @homeTourTrainerDescription.
  ///
  /// In en, this message translates to:
  /// **'Manage the Trainer sheet, catch creatures, organize the team and PC, check the Bag and follow breeding and Eggs.'**
  String get homeTourTrainerDescription;

  /// No description provided for @homeTourPokedexTitle.
  ///
  /// In en, this message translates to:
  /// **'The Pokédex'**
  String get homeTourPokedexTitle;

  /// No description provided for @homeTourPokedexDescription.
  ///
  /// In en, this message translates to:
  /// **'Open the Pokédex to browse creatures, apply filters and record which ones you have seen or caught.'**
  String get homeTourPokedexDescription;

  /// No description provided for @homeTourMasterTitle.
  ///
  /// In en, this message translates to:
  /// **'GM tools'**
  String get homeTourMasterTitle;

  /// No description provided for @homeTourMasterDescription.
  ///
  /// In en, this message translates to:
  /// **'This area contains generators, encounters, collections, NPC Trainers and tools for preparing and running battles.'**
  String get homeTourMasterDescription;

  /// No description provided for @homeTourProfilesTitle.
  ///
  /// In en, this message translates to:
  /// **'Profiles and help'**
  String get homeTourProfilesTitle;

  /// No description provided for @homeTourProfilesDescription.
  ///
  /// In en, this message translates to:
  /// **'Use Profiles to create or switch Trainers. Select INFO at any time to review this tour.'**
  String get homeTourProfilesDescription;

  /// No description provided for @tourSkip.
  ///
  /// In en, this message translates to:
  /// **'SKIP TOUR'**
  String get tourSkip;

  /// No description provided for @backAction.
  ///
  /// In en, this message translates to:
  /// **'BACK'**
  String get backAction;

  /// No description provided for @tourUnderstood.
  ///
  /// In en, this message translates to:
  /// **'GOT IT'**
  String get tourUnderstood;

  /// No description provided for @nextAction.
  ///
  /// In en, this message translates to:
  /// **'NEXT'**
  String get nextAction;

  /// No description provided for @homeOngoingSessionsTitle.
  ///
  /// In en, this message translates to:
  /// **'ONGOING SESSIONS'**
  String get homeOngoingSessionsTitle;

  /// No description provided for @homeOngoingSessionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Continue immediately from where you stopped.'**
  String get homeOngoingSessionsSubtitle;

  /// No description provided for @homeResumeBattleTitle.
  ///
  /// In en, this message translates to:
  /// **'Resume battle'**
  String get homeResumeBattleTitle;

  /// No description provided for @homeResumeBattleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Continue with the saved round, turn, PP and status conditions.'**
  String get homeResumeBattleSubtitle;

  /// No description provided for @homeResumeMasterFightTitle.
  ///
  /// In en, this message translates to:
  /// **'Resume GM Fight'**
  String get homeResumeMasterFightTitle;

  /// No description provided for @homeResumeMasterFightSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Reopen the GM session with saved HP, PP, status conditions and initiative.'**
  String get homeResumeMasterFightSubtitle;

  /// No description provided for @homeTrainerAndTeamTitle.
  ///
  /// In en, this message translates to:
  /// **'TRAINER AND TEAM'**
  String get homeTrainerAndTeamTitle;

  /// No description provided for @homeTrainerAndTeamSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage the character and caught creatures.'**
  String get homeTrainerAndTeamSubtitle;

  /// No description provided for @homeBattleCompanionTitle.
  ///
  /// In en, this message translates to:
  /// **'Battle Companion'**
  String get homeBattleCompanionTitle;

  /// No description provided for @homeBattleCompanionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Track rounds, HP, status conditions and PP during combat.'**
  String get homeBattleCompanionSubtitle;

  /// No description provided for @homeTrainerSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Trainer Sheet'**
  String get homeTrainerSheetTitle;

  /// No description provided for @homeTrainerSheetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Update level, money and campaign progression.'**
  String get homeTrainerSheetSubtitle;

  /// No description provided for @homeCaptureTitle.
  ///
  /// In en, this message translates to:
  /// **'Catch a creature'**
  String get homeCaptureTitle;

  /// No description provided for @homeCaptureSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a creature: it joins the team when there is room, otherwise it goes to the PC.'**
  String get homeCaptureSubtitle;

  /// No description provided for @homeTeamTitle.
  ///
  /// In en, this message translates to:
  /// **'Team'**
  String get homeTeamTitle;

  /// No description provided for @homeTeamSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose up to 6 creatures for the active profile.'**
  String get homeTeamSubtitle;

  /// No description provided for @homePcTitle.
  ///
  /// In en, this message translates to:
  /// **'Creature PC'**
  String get homePcTitle;

  /// No description provided for @homePcSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage caught creatures outside the active team.'**
  String get homePcSubtitle;

  /// No description provided for @homeBreedingTitle.
  ///
  /// In en, this message translates to:
  /// **'Breeding and Eggs'**
  String get homeBreedingTitle;

  /// No description provided for @homeBreedingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Check the parents, create Eggs, advance incubation and hatch creatures.'**
  String get homeBreedingSubtitle;

  /// No description provided for @homeBagTitle.
  ///
  /// In en, this message translates to:
  /// **'Bag'**
  String get homeBagTitle;

  /// No description provided for @homeBagSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Equipment, healing items and catching supplies.'**
  String get homeBagSubtitle;

  /// No description provided for @homeConsultationTitle.
  ///
  /// In en, this message translates to:
  /// **'REFERENCE'**
  String get homeConsultationTitle;

  /// No description provided for @homeConsultationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Find information and update your progress.'**
  String get homeConsultationSubtitle;

  /// No description provided for @homeOpenPokedexTitle.
  ///
  /// In en, this message translates to:
  /// **'Open Pokédex'**
  String get homeOpenPokedexTitle;

  /// No description provided for @homeOpenPokedexSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Browse, filter and mark creatures.'**
  String get homeOpenPokedexSubtitle;

  /// No description provided for @homeMasterToolsTitle.
  ///
  /// In en, this message translates to:
  /// **'GM TOOLS'**
  String get homeMasterToolsTitle;

  /// No description provided for @homeMasterToolsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Generate content, use libraries and prepare fights.'**
  String get homeMasterToolsSubtitle;

  /// No description provided for @homeOpenMasterToolsTitle.
  ///
  /// In en, this message translates to:
  /// **'Open GM Tools'**
  String get homeOpenMasterToolsTitle;

  /// No description provided for @homeOpenMasterToolsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Creature generators, encounters, collections and NPC Trainers.'**
  String get homeOpenMasterToolsSubtitle;

  /// No description provided for @homeAppManagementTitle.
  ///
  /// In en, this message translates to:
  /// **'APPLICATION MANAGEMENT'**
  String get homeAppManagementTitle;

  /// No description provided for @homeAppManagementSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage profiles and application data.'**
  String get homeAppManagementSubtitle;

  /// No description provided for @homeProfilesTitle.
  ///
  /// In en, this message translates to:
  /// **'Profiles'**
  String get homeProfilesTitle;

  /// No description provided for @homeProfilesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create, switch or delete Trainer profiles.'**
  String get homeProfilesSubtitle;

  /// No description provided for @trainerFallback.
  ///
  /// In en, this message translates to:
  /// **'Trainer'**
  String get trainerFallback;

  /// No description provided for @homeGreeting.
  ///
  /// In en, this message translates to:
  /// **'Hello, {name}'**
  String homeGreeting(String name);

  /// No description provided for @trainerLevelChip.
  ///
  /// In en, this message translates to:
  /// **'Lv. {level}'**
  String trainerLevelChip(int level);

  /// No description provided for @trainerMoneyChip.
  ///
  /// In en, this message translates to:
  /// **'₽ {amount}'**
  String trainerMoneyChip(int amount);

  /// No description provided for @trainerPokeslotChip.
  ///
  /// In en, this message translates to:
  /// **'Poké Slots {count}'**
  String trainerPokeslotChip(int count);

  /// No description provided for @trainerMaxSrChip.
  ///
  /// In en, this message translates to:
  /// **'Max SR {value}'**
  String trainerMaxSrChip(num value);

  /// No description provided for @pokedexProgressTitle.
  ///
  /// In en, this message translates to:
  /// **'Pokédex progress'**
  String get pokedexProgressTitle;

  /// No description provided for @seenLabel.
  ///
  /// In en, this message translates to:
  /// **'Seen'**
  String get seenLabel;

  /// No description provided for @caughtLabel.
  ///
  /// In en, this message translates to:
  /// **'Caught'**
  String get caughtLabel;

  /// No description provided for @errorWithMessage.
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String errorWithMessage(String message);

  /// No description provided for @retryAction.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retryAction;

  /// No description provided for @onboardingStartAdventure.
  ///
  /// In en, this message translates to:
  /// **'START YOUR ADVENTURE'**
  String get onboardingStartAdventure;

  /// No description provided for @onboardingConfirm.
  ///
  /// In en, this message translates to:
  /// **'CONFIRM'**
  String get onboardingConfirm;

  /// No description provided for @onboardingCreatingProfile.
  ///
  /// In en, this message translates to:
  /// **'CREATING PROFILE...'**
  String get onboardingCreatingProfile;

  /// No description provided for @onboardingBegin.
  ///
  /// In en, this message translates to:
  /// **'BEGIN!'**
  String get onboardingBegin;

  /// No description provided for @onboardingProfileCreationError.
  ///
  /// In en, this message translates to:
  /// **'The profile could not be created. Try again.'**
  String get onboardingProfileCreationError;

  /// No description provided for @onboardingProfessor.
  ///
  /// In en, this message translates to:
  /// **'Professor'**
  String get onboardingProfessor;

  /// No description provided for @onboardingWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to your new journey.'**
  String get onboardingWelcomeTitle;

  /// No description provided for @onboardingWelcomeBody.
  ///
  /// In en, this message translates to:
  /// **'Here you can create your Trainer, choose your first companion and prepare for tabletop adventures.'**
  String get onboardingWelcomeBody;

  /// No description provided for @onboardingWelcomeNote.
  ///
  /// In en, this message translates to:
  /// **'You can change these choices later from your profile.'**
  String get onboardingWelcomeNote;

  /// No description provided for @onboardingNameTitle.
  ///
  /// In en, this message translates to:
  /// **'Before we begin, tell me…'**
  String get onboardingNameTitle;

  /// No description provided for @onboardingNameBody.
  ///
  /// In en, this message translates to:
  /// **'What is your name?'**
  String get onboardingNameBody;

  /// No description provided for @onboardingTrainerNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Trainer name'**
  String get onboardingTrainerNameLabel;

  /// No description provided for @onboardingTrainerNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get onboardingTrainerNameHint;

  /// No description provided for @onboardingAgeTitle.
  ///
  /// In en, this message translates to:
  /// **'Great! How old are you?'**
  String get onboardingAgeTitle;

  /// No description provided for @onboardingAgeBody.
  ///
  /// In en, this message translates to:
  /// **'You can change this information later.'**
  String get onboardingAgeBody;

  /// No description provided for @onboardingOriginTitle.
  ///
  /// In en, this message translates to:
  /// **'Every Trainer carries a story.'**
  String get onboardingOriginTitle;

  /// No description provided for @onboardingOriginBody.
  ///
  /// In en, this message translates to:
  /// **'Where do you come from?'**
  String get onboardingOriginBody;

  /// No description provided for @onboardingOriginLabel.
  ///
  /// In en, this message translates to:
  /// **'Origin'**
  String get onboardingOriginLabel;

  /// No description provided for @onboardingOriginBonusLabel.
  ///
  /// In en, this message translates to:
  /// **'Ability bonuses'**
  String get onboardingOriginBonusLabel;

  /// No description provided for @onboardingProficienciesLabel.
  ///
  /// In en, this message translates to:
  /// **'Proficiencies'**
  String get onboardingProficienciesLabel;

  /// No description provided for @onboardingNoAutomaticBonuses.
  ///
  /// In en, this message translates to:
  /// **'No automatic bonuses'**
  String get onboardingNoAutomaticBonuses;

  /// No description provided for @onboardingNoAdditionalProficiencies.
  ///
  /// In en, this message translates to:
  /// **'No additional proficiencies'**
  String get onboardingNoAdditionalProficiencies;

  /// No description provided for @onboardingBackgroundTitle.
  ///
  /// In en, this message translates to:
  /// **'Which path brought you here?'**
  String get onboardingBackgroundTitle;

  /// No description provided for @onboardingBackgroundBody.
  ///
  /// In en, this message translates to:
  /// **'Choose the background that best describes your Trainer.'**
  String get onboardingBackgroundBody;

  /// No description provided for @onboardingBackgroundLabel.
  ///
  /// In en, this message translates to:
  /// **'Background'**
  String get onboardingBackgroundLabel;

  /// No description provided for @onboardingBackgroundResearcher.
  ///
  /// In en, this message translates to:
  /// **'Researcher'**
  String get onboardingBackgroundResearcher;

  /// No description provided for @onboardingBackgroundResearcherDescription.
  ///
  /// In en, this message translates to:
  /// **'You observe, catalogue and study every discovery before drawing conclusions.'**
  String get onboardingBackgroundResearcherDescription;

  /// No description provided for @onboardingBackgroundExplorer.
  ///
  /// In en, this message translates to:
  /// **'Explorer'**
  String get onboardingBackgroundExplorer;

  /// No description provided for @onboardingBackgroundExplorerDescription.
  ///
  /// In en, this message translates to:
  /// **'You feel at home on less-travelled roads and in the wilderness.'**
  String get onboardingBackgroundExplorerDescription;

  /// No description provided for @onboardingBackgroundBreeder.
  ///
  /// In en, this message translates to:
  /// **'Breeder'**
  String get onboardingBackgroundBreeder;

  /// No description provided for @onboardingBackgroundBreederDescription.
  ///
  /// In en, this message translates to:
  /// **'You understand the needs of creatures and build patient bonds.'**
  String get onboardingBackgroundBreederDescription;

  /// No description provided for @onboardingBackgroundFighter.
  ///
  /// In en, this message translates to:
  /// **'Fighter'**
  String get onboardingBackgroundFighter;

  /// No description provided for @onboardingBackgroundFighterDescription.
  ///
  /// In en, this message translates to:
  /// **'You face challenges with discipline, courage and a competitive spirit.'**
  String get onboardingBackgroundFighterDescription;

  /// No description provided for @onboardingBackgroundArtist.
  ///
  /// In en, this message translates to:
  /// **'Artist'**
  String get onboardingBackgroundArtist;

  /// No description provided for @onboardingBackgroundArtistDescription.
  ///
  /// In en, this message translates to:
  /// **'You express yourself through performance, creativity and sensitivity.'**
  String get onboardingBackgroundArtistDescription;

  /// No description provided for @onboardingBackgroundScholar.
  ///
  /// In en, this message translates to:
  /// **'Scholar'**
  String get onboardingBackgroundScholar;

  /// No description provided for @onboardingBackgroundScholarDescription.
  ///
  /// In en, this message translates to:
  /// **'You have devoted years to books, traditions and specialist knowledge.'**
  String get onboardingBackgroundScholarDescription;

  /// No description provided for @onboardingStarterTitle.
  ///
  /// In en, this message translates to:
  /// **'Finally, choose your first companion.'**
  String get onboardingStarterTitle;

  /// No description provided for @onboardingStarterBody.
  ///
  /// In en, this message translates to:
  /// **'You may choose any unevolved Pokémon with SR 1/2 or lower.'**
  String get onboardingStarterBody;

  /// No description provided for @onboardingStarterSearchLabel.
  ///
  /// In en, this message translates to:
  /// **'Search by name or type'**
  String get onboardingStarterSearchLabel;

  /// No description provided for @onboardingStarterSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Example: Bulbasaur, Grass, Fire…'**
  String get onboardingStarterSearchHint;

  /// No description provided for @onboardingNoStarterResults.
  ///
  /// In en, this message translates to:
  /// **'No Pokémon match your search.'**
  String get onboardingNoStarterResults;

  /// No description provided for @onboardingSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Here is your profile.'**
  String get onboardingSummaryTitle;

  /// No description provided for @onboardingSummaryBody.
  ///
  /// In en, this message translates to:
  /// **'Review your choices and get ready to begin.'**
  String get onboardingSummaryBody;

  /// No description provided for @onboardingNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get onboardingNameLabel;

  /// No description provided for @onboardingAgeLabel.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get onboardingAgeLabel;

  /// No description provided for @onboardingStarterLabel.
  ///
  /// In en, this message translates to:
  /// **'Starter'**
  String get onboardingStarterLabel;

  /// No description provided for @onboardingSavingTitle.
  ///
  /// In en, this message translates to:
  /// **'I am creating your profile.'**
  String get onboardingSavingTitle;

  /// No description provided for @onboardingSavingBody.
  ///
  /// In en, this message translates to:
  /// **'One moment… I am preparing your Trainer and first Pokémon.'**
  String get onboardingSavingBody;

  /// No description provided for @onboardingSavingErrorBody.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. You can try again without losing your choices.'**
  String get onboardingSavingErrorBody;

  /// No description provided for @onboardingDoneTitle.
  ///
  /// In en, this message translates to:
  /// **'All set!'**
  String get onboardingDoneTitle;

  /// No description provided for @onboardingDoneBody.
  ///
  /// In en, this message translates to:
  /// **'Your adventure is about to begin. See you in the world of Pokémon!'**
  String get onboardingDoneBody;

  /// No description provided for @onboardingDoneNote.
  ///
  /// In en, this message translates to:
  /// **'Your profile and starter were created successfully.'**
  String get onboardingDoneNote;

  /// No description provided for @onboardingTagline.
  ///
  /// In en, this message translates to:
  /// **'Your companion for tabletop adventures'**
  String get onboardingTagline;

  /// No description provided for @onboardingMissingCoverBackground.
  ///
  /// In en, this message translates to:
  /// **'COVER BACKGROUND'**
  String get onboardingMissingCoverBackground;

  /// No description provided for @onboardingMissingLabBackground.
  ///
  /// In en, this message translates to:
  /// **'LABORATORY BACKGROUND'**
  String get onboardingMissingLabBackground;

  /// No description provided for @onboardingMissingProfessor.
  ///
  /// In en, this message translates to:
  /// **'TRANSPARENT\nPROFESSOR PNG'**
  String get onboardingMissingProfessor;

  /// No description provided for @onboardingOriginDmApprovedName.
  ///
  /// In en, this message translates to:
  /// **'GM-approved 5e Origin'**
  String get onboardingOriginDmApprovedName;

  /// No description provided for @onboardingOriginAlolanDescription.
  ///
  /// In en, this message translates to:
  /// **'Ability bonuses: INT +2, CHA +1.\nProficiency: Nature.\nTrait: you can cast Speak with Pokémon once per long rest. A good origin for curious, sociable Trainers closely connected to the natural lives of Pokémon.'**
  String get onboardingOriginAlolanDescription;

  /// No description provided for @onboardingOriginHoennianDescription.
  ///
  /// In en, this message translates to:
  /// **'Ability bonuses: WIS +2, INT +1.\nProficiency: Survival.\nTrait: you are accustomed to travelling through difficult environments and handling climate, terrain and wild routes. It suits explorers, rangers and travelling Trainers.'**
  String get onboardingOriginHoennianDescription;

  /// No description provided for @onboardingOriginJohtoanDescription.
  ///
  /// In en, this message translates to:
  /// **'Ability bonuses: INT +2, STR +1.\nProficiency: History.\nTrait: your training draws on ancient traditions and physical discipline; the martial trait rewards critical hits with weapons. It suits Trainers connected to history, temples, ruins and legends.'**
  String get onboardingOriginJohtoanDescription;

  /// No description provided for @onboardingOriginKalosianDescription.
  ///
  /// In en, this message translates to:
  /// **'Ability bonuses: CHA +2, INT +1.\nProficiency: Persuasion.\nTrait: you may reroll a 1 according to the origin rules. It is designed for elegant, diplomatic Trainers who stay composed when presence and style matter.'**
  String get onboardingOriginKalosianDescription;

  /// No description provided for @onboardingOriginKantoanDescription.
  ///
  /// In en, this message translates to:
  /// **'Ability bonuses: +1 to two abilities of your choice. Assign these bonuses manually in the ability boxes.\nProficiency: Investigation.\nTrait: gain a feat approved by the GM. This is the most flexible origin and is ideal for building a highly customised Trainer.'**
  String get onboardingOriginKantoanDescription;

  /// No description provided for @onboardingOriginSinnoanDescription.
  ///
  /// In en, this message translates to:
  /// **'Ability bonuses: CON +2, STR +1.\nProficiency: Athletics.\nTrait: gain proficiency in Constitution saving throws. Ideal for resilient Trainers accustomed to mountains, snow and long expeditions.'**
  String get onboardingOriginSinnoanDescription;

  /// No description provided for @onboardingOriginUnovanDescription.
  ///
  /// In en, this message translates to:
  /// **'Ability bonuses: DEX +2, WIS +1.\nProficiency: Insight.\nTrait: gain two additional proficiencies of your choice. Perfect for quick, adaptable Trainers who can read people and situations.'**
  String get onboardingOriginUnovanDescription;

  /// No description provided for @onboardingOriginGalarianDescription.
  ///
  /// In en, this message translates to:
  /// **'Ability bonuses: choose DEX +2 and STR +1, or STR +2 and DEX +1. Assign these bonuses manually in the ability boxes.\nProficiency: Intimidation.\nTrait: gain a defensive reaction. It suits competitive, physical Trainers accustomed to handling the pressure of battle.'**
  String get onboardingOriginGalarianDescription;

  /// No description provided for @onboardingOriginDmApprovedDescription.
  ///
  /// In en, this message translates to:
  /// **'Use a classic or homebrew 5e origin approved by the GM. Record the agreed ability bonuses, proficiencies and traits manually.'**
  String get onboardingOriginDmApprovedDescription;
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
      <String>['en', 'it'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'it':
      return AppLocalizationsIt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
