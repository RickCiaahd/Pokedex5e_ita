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
}
