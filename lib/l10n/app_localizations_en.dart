// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Trainer Atlas 5e';

  @override
  String get infoAction => 'INFO';

  @override
  String get reviewTourTooltip => 'INFO · Review the tour';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsSubtitle => 'Language and application preferences.';

  @override
  String get languageSectionTitle => 'LANGUAGE';

  @override
  String get languageSectionSubtitle =>
      'Choose how Trainer Atlas 5e selects the interface language.';

  @override
  String get languageSystemTitle => 'Device language';

  @override
  String get languageSystemSubtitle =>
      'Uses Italian or English when available and falls back to English for every other device language.';

  @override
  String get languageItalianTitle => 'Italiano';

  @override
  String get languageItalianSubtitle => 'Always use the Italian interface.';

  @override
  String get languageEnglishTitle => 'English';

  @override
  String get languageEnglishSubtitle => 'Always use the English interface.';

  @override
  String get homeTourDashboardTitle => 'Your dashboard';

  @override
  String get homeTourDashboardDescription =>
      'See the active profile, level, money, available Poké Slots and the maximum challenge rating you can control.';

  @override
  String get homeTourTrainerTitle => 'Trainer and team';

  @override
  String get homeTourTrainerDescription =>
      'Manage the Trainer sheet, catch creatures, organize the team and PC, check the Bag and follow breeding and Eggs.';

  @override
  String get homeTourPokedexTitle => 'The Pokédex';

  @override
  String get homeTourPokedexDescription =>
      'Open the Pokédex to browse creatures, apply filters and record which ones you have seen or caught.';

  @override
  String get homeTourMasterTitle => 'GM tools';

  @override
  String get homeTourMasterDescription =>
      'This area contains generators, encounters, collections, NPC Trainers and tools for preparing and running battles.';

  @override
  String get homeTourProfilesTitle => 'Profiles and help';

  @override
  String get homeTourProfilesDescription =>
      'Use Profiles to create or switch Trainers. Select INFO at any time to review this tour.';

  @override
  String get tourSkip => 'SKIP TOUR';

  @override
  String get backAction => 'BACK';

  @override
  String get tourUnderstood => 'GOT IT';

  @override
  String get nextAction => 'NEXT';

  @override
  String get homeOngoingSessionsTitle => 'ONGOING SESSIONS';

  @override
  String get homeOngoingSessionsSubtitle =>
      'Continue immediately from where you stopped.';

  @override
  String get homeResumeBattleTitle => 'Resume battle';

  @override
  String get homeResumeBattleSubtitle =>
      'Continue with the saved round, turn, PP and status conditions.';

  @override
  String get homeResumeMasterFightTitle => 'Resume GM Fight';

  @override
  String get homeResumeMasterFightSubtitle =>
      'Reopen the GM session with saved HP, PP, status conditions and initiative.';

  @override
  String get homeTrainerAndTeamTitle => 'TRAINER AND TEAM';

  @override
  String get homeTrainerAndTeamSubtitle =>
      'Manage the character and caught creatures.';

  @override
  String get homeBattleCompanionTitle => 'Battle Companion';

  @override
  String get homeBattleCompanionSubtitle =>
      'Track rounds, HP, status conditions and PP during combat.';

  @override
  String get homeTrainerSheetTitle => 'Trainer Sheet';

  @override
  String get homeTrainerSheetSubtitle =>
      'Update level, money and campaign progression.';

  @override
  String get homeCaptureTitle => 'Catch a creature';

  @override
  String get homeCaptureSubtitle =>
      'Choose a creature: it joins the team when there is room, otherwise it goes to the PC.';

  @override
  String get homeTeamTitle => 'Team';

  @override
  String get homeTeamSubtitle =>
      'Choose up to 6 creatures for the active profile.';

  @override
  String get homePcTitle => 'Creature PC';

  @override
  String get homePcSubtitle =>
      'Manage caught creatures outside the active team.';

  @override
  String get homeBreedingTitle => 'Breeding and Eggs';

  @override
  String get homeBreedingSubtitle =>
      'Check the parents, create Eggs, advance incubation and hatch creatures.';

  @override
  String get homeBagTitle => 'Bag';

  @override
  String get homeBagSubtitle =>
      'Equipment, healing items and catching supplies.';

  @override
  String get homeConsultationTitle => 'REFERENCE';

  @override
  String get homeConsultationSubtitle =>
      'Find information and update your progress.';

  @override
  String get homeOpenPokedexTitle => 'Open Pokédex';

  @override
  String get homeOpenPokedexSubtitle => 'Browse, filter and mark creatures.';

  @override
  String get homeMasterToolsTitle => 'GM TOOLS';

  @override
  String get homeMasterToolsSubtitle =>
      'Generate content, use libraries and prepare fights.';

  @override
  String get homeOpenMasterToolsTitle => 'Open GM Tools';

  @override
  String get homeOpenMasterToolsSubtitle =>
      'Creature generators, encounters, collections and NPC Trainers.';

  @override
  String get homeAppManagementTitle => 'APPLICATION MANAGEMENT';

  @override
  String get homeAppManagementSubtitle =>
      'Manage profiles and application data.';

  @override
  String get homeProfilesTitle => 'Profiles';

  @override
  String get homeProfilesSubtitle =>
      'Create, switch or delete Trainer profiles.';

  @override
  String get trainerFallback => 'Trainer';

  @override
  String homeGreeting(String name) {
    return 'Hello, $name';
  }

  @override
  String trainerLevelChip(int level) {
    return 'Lv. $level';
  }

  @override
  String trainerMoneyChip(int amount) {
    return '₽ $amount';
  }

  @override
  String trainerPokeslotChip(int count) {
    return 'Poké Slots $count';
  }

  @override
  String trainerMaxSrChip(num value) {
    return 'Max SR $value';
  }

  @override
  String get pokedexProgressTitle => 'Pokédex progress';

  @override
  String get seenLabel => 'Seen';

  @override
  String get caughtLabel => 'Caught';

  @override
  String errorWithMessage(String message) {
    return 'Error: $message';
  }

  @override
  String get retryAction => 'Retry';

  @override
  String get onboardingStartAdventure => 'START YOUR ADVENTURE';

  @override
  String get onboardingConfirm => 'CONFIRM';

  @override
  String get onboardingCreatingProfile => 'CREATING PROFILE...';

  @override
  String get onboardingBegin => 'BEGIN!';

  @override
  String get onboardingProfileCreationError =>
      'The profile could not be created. Try again.';

  @override
  String get onboardingProfessor => 'Professor';

  @override
  String get onboardingWelcomeTitle => 'Welcome to your new journey.';

  @override
  String get onboardingWelcomeBody =>
      'Here you can create your Trainer, choose your first companion and prepare for tabletop adventures.';

  @override
  String get onboardingWelcomeNote =>
      'You can change these choices later from your profile.';

  @override
  String get onboardingNameTitle => 'Before we begin, tell me…';

  @override
  String get onboardingNameBody => 'What is your name?';

  @override
  String get onboardingTrainerNameLabel => 'Trainer name';

  @override
  String get onboardingTrainerNameHint => 'Enter your name';

  @override
  String get onboardingAgeTitle => 'Great! How old are you?';

  @override
  String get onboardingAgeBody => 'You can change this information later.';

  @override
  String get onboardingOriginTitle => 'Every Trainer carries a story.';

  @override
  String get onboardingOriginBody => 'Where do you come from?';

  @override
  String get onboardingOriginLabel => 'Origin';

  @override
  String get onboardingOriginBonusLabel => 'Ability bonuses';

  @override
  String get onboardingProficienciesLabel => 'Proficiencies';

  @override
  String get onboardingNoAutomaticBonuses => 'No automatic bonuses';

  @override
  String get onboardingNoAdditionalProficiencies =>
      'No additional proficiencies';

  @override
  String get onboardingBackgroundTitle => 'Which path brought you here?';

  @override
  String get onboardingBackgroundBody =>
      'Choose the background that best describes your Trainer.';

  @override
  String get onboardingBackgroundLabel => 'Background';

  @override
  String get onboardingBackgroundResearcher => 'Researcher';

  @override
  String get onboardingBackgroundResearcherDescription =>
      'You observe, catalogue and study every discovery before drawing conclusions.';

  @override
  String get onboardingBackgroundExplorer => 'Explorer';

  @override
  String get onboardingBackgroundExplorerDescription =>
      'You feel at home on less-travelled roads and in the wilderness.';

  @override
  String get onboardingBackgroundBreeder => 'Breeder';

  @override
  String get onboardingBackgroundBreederDescription =>
      'You understand the needs of creatures and build patient bonds.';

  @override
  String get onboardingBackgroundFighter => 'Fighter';

  @override
  String get onboardingBackgroundFighterDescription =>
      'You face challenges with discipline, courage and a competitive spirit.';

  @override
  String get onboardingBackgroundArtist => 'Artist';

  @override
  String get onboardingBackgroundArtistDescription =>
      'You express yourself through performance, creativity and sensitivity.';

  @override
  String get onboardingBackgroundScholar => 'Scholar';

  @override
  String get onboardingBackgroundScholarDescription =>
      'You have devoted years to books, traditions and specialist knowledge.';

  @override
  String get onboardingStarterTitle => 'Finally, choose your first companion.';

  @override
  String get onboardingStarterBody =>
      'You may choose any unevolved Pokémon with SR 1/2 or lower.';

  @override
  String get onboardingStarterSearchLabel => 'Search by name or type';

  @override
  String get onboardingStarterSearchHint => 'Example: Bulbasaur, Grass, Fire…';

  @override
  String get onboardingNoStarterResults => 'No Pokémon match your search.';

  @override
  String get onboardingSummaryTitle => 'Here is your profile.';

  @override
  String get onboardingSummaryBody =>
      'Review your choices and get ready to begin.';

  @override
  String get onboardingNameLabel => 'Name';

  @override
  String get onboardingAgeLabel => 'Age';

  @override
  String get onboardingStarterLabel => 'Starter';

  @override
  String get onboardingSavingTitle => 'I am creating your profile.';

  @override
  String get onboardingSavingBody =>
      'One moment… I am preparing your Trainer and first Pokémon.';

  @override
  String get onboardingSavingErrorBody =>
      'Something went wrong. You can try again without losing your choices.';

  @override
  String get onboardingDoneTitle => 'All set!';

  @override
  String get onboardingDoneBody =>
      'Your adventure is about to begin. See you in the world of Pokémon!';

  @override
  String get onboardingDoneNote =>
      'Your profile and starter were created successfully.';

  @override
  String get onboardingTagline => 'Your companion for tabletop adventures';

  @override
  String get onboardingMissingCoverBackground => 'COVER BACKGROUND';

  @override
  String get onboardingMissingLabBackground => 'LABORATORY BACKGROUND';

  @override
  String get onboardingMissingProfessor => 'TRANSPARENT\nPROFESSOR PNG';

  @override
  String get onboardingOriginDmApprovedName => 'GM-approved 5e Origin';

  @override
  String get onboardingOriginAlolanDescription =>
      'Ability bonuses: INT +2, CHA +1.\nProficiency: Nature.\nTrait: you can cast Speak with Pokémon once per long rest. A good origin for curious, sociable Trainers closely connected to the natural lives of Pokémon.';

  @override
  String get onboardingOriginHoennianDescription =>
      'Ability bonuses: WIS +2, INT +1.\nProficiency: Survival.\nTrait: you are accustomed to travelling through difficult environments and handling climate, terrain and wild routes. It suits explorers, rangers and travelling Trainers.';

  @override
  String get onboardingOriginJohtoanDescription =>
      'Ability bonuses: INT +2, STR +1.\nProficiency: History.\nTrait: your training draws on ancient traditions and physical discipline; the martial trait rewards critical hits with weapons. It suits Trainers connected to history, temples, ruins and legends.';

  @override
  String get onboardingOriginKalosianDescription =>
      'Ability bonuses: CHA +2, INT +1.\nProficiency: Persuasion.\nTrait: you may reroll a 1 according to the origin rules. It is designed for elegant, diplomatic Trainers who stay composed when presence and style matter.';

  @override
  String get onboardingOriginKantoanDescription =>
      'Ability bonuses: +1 to two abilities of your choice. Assign these bonuses manually in the ability boxes.\nProficiency: Investigation.\nTrait: gain a feat approved by the GM. This is the most flexible origin and is ideal for building a highly customised Trainer.';

  @override
  String get onboardingOriginSinnoanDescription =>
      'Ability bonuses: CON +2, STR +1.\nProficiency: Athletics.\nTrait: gain proficiency in Constitution saving throws. Ideal for resilient Trainers accustomed to mountains, snow and long expeditions.';

  @override
  String get onboardingOriginUnovanDescription =>
      'Ability bonuses: DEX +2, WIS +1.\nProficiency: Insight.\nTrait: gain two additional proficiencies of your choice. Perfect for quick, adaptable Trainers who can read people and situations.';

  @override
  String get onboardingOriginGalarianDescription =>
      'Ability bonuses: choose DEX +2 and STR +1, or STR +2 and DEX +1. Assign these bonuses manually in the ability boxes.\nProficiency: Intimidation.\nTrait: gain a defensive reaction. It suits competitive, physical Trainers accustomed to handling the pressure of battle.';

  @override
  String get onboardingOriginDmApprovedDescription =>
      'Use a classic or homebrew 5e origin approved by the GM. Record the agreed ability bonuses, proficiencies and traits manually.';
}
