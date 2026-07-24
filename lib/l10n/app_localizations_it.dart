// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'Trainer Atlas 5e';

  @override
  String get infoAction => 'INFO';

  @override
  String get reviewTourTooltip => 'INFO · Rivedi il tour';

  @override
  String get settingsTitle => 'Impostazioni';

  @override
  String get settingsSubtitle => 'Lingua e preferenze dell’applicazione.';

  @override
  String get languageSectionTitle => 'LINGUA';

  @override
  String get languageSectionSubtitle =>
      'Scegli come Trainer Atlas 5e determina la lingua dell’interfaccia.';

  @override
  String get languageSystemTitle => 'Lingua del dispositivo';

  @override
  String get languageSystemSubtitle =>
      'Usa italiano o inglese quando disponibili e passa all’inglese per ogni altra lingua del dispositivo.';

  @override
  String get languageItalianTitle => 'Italiano';

  @override
  String get languageItalianSubtitle => 'Usa sempre l’interfaccia italiana.';

  @override
  String get languageEnglishTitle => 'English';

  @override
  String get languageEnglishSubtitle => 'Usa sempre l’interfaccia inglese.';

  @override
  String get homeTourDashboardTitle => 'La tua dashboard';

  @override
  String get homeTourDashboardDescription =>
      'Qui trovi subito il profilo attivo, il livello, il denaro, i Pokéslot disponibili e il grado sfida massimo che puoi controllare.';

  @override
  String get homeTourTrainerTitle => 'Allenatore e squadra';

  @override
  String get homeTourTrainerDescription =>
      'Da questa sezione gestisci la scheda dell’Allenatore, catturi Pokémon, organizzi squadra e PC, controlli lo Zaino e segui allevamento e uova.';

  @override
  String get homeTourPokedexTitle => 'Il Pokédex';

  @override
  String get homeTourPokedexDescription =>
      'Apri il Pokédex per consultare le creature, applicare filtri e registrare quali Pokémon hai visto o catturato.';

  @override
  String get homeTourMasterTitle => 'Strumenti del Master';

  @override
  String get homeTourMasterDescription =>
      'Quest’area raccoglie generatori, incontri, raccolte, Allenatori PNG e strumenti per preparare e gestire i combattimenti.';

  @override
  String get homeTourProfilesTitle => 'Profili e aiuto';

  @override
  String get homeTourProfilesDescription =>
      'In Profili puoi creare o cambiare Allenatore. Per rivedere questa spiegazione in qualsiasi momento usa il pulsante INFO in alto.';

  @override
  String get tourSkip => 'SALTA TOUR';

  @override
  String get backAction => 'INDIETRO';

  @override
  String get tourUnderstood => 'HO CAPITO';

  @override
  String get nextAction => 'AVANTI';

  @override
  String get homeOngoingSessionsTitle => 'SESSIONI IN CORSO';

  @override
  String get homeOngoingSessionsSubtitle =>
      'Riprendi subito da dove avevi lasciato.';

  @override
  String get homeResumeBattleTitle => 'Riprendi battaglia';

  @override
  String get homeResumeBattleSubtitle =>
      'Continua dal round, turno, PP e status salvati.';

  @override
  String get homeResumeMasterFightTitle => 'Riprendi Fight del Master';

  @override
  String get homeResumeMasterFightSubtitle =>
      'Riapri la sessione del Master con PF, PP, status e iniziativa salvati.';

  @override
  String get homeTrainerAndTeamTitle => 'ALLENATORE E SQUADRA';

  @override
  String get homeTrainerAndTeamSubtitle =>
      'Gestisci il personaggio e i Pokémon catturati.';

  @override
  String get homeBattleCompanionTitle => 'Battle Companion';

  @override
  String get homeBattleCompanionSubtitle =>
      'Traccia round, PF, status e PP durante il combattimento.';

  @override
  String get homeTrainerSheetTitle => 'Scheda Allenatore';

  @override
  String get homeTrainerSheetSubtitle =>
      'Aggiorna livello, soldi e progressione campagna.';

  @override
  String get homeCaptureTitle => 'Cattura Pokémon';

  @override
  String get homeCaptureSubtitle =>
      'Scegli il Pokémon: va in squadra se c’è posto, altrimenti nel PC.';

  @override
  String get homeTeamTitle => 'Squadra';

  @override
  String get homeTeamSubtitle =>
      'Scegli fino a 6 Pokémon per il profilo attivo.';

  @override
  String get homePcTitle => 'PC Pokémon';

  @override
  String get homePcSubtitle => 'Gestisci i Pokémon catturati fuori squadra.';

  @override
  String get homeBreedingTitle => 'Allevamento e uova';

  @override
  String get homeBreedingSubtitle =>
      'Verifica i genitori, crea uova, avanza l’incubazione e fai schiudere i Pokémon.';

  @override
  String get homeBagTitle => 'Zaino';

  @override
  String get homeBagSubtitle => 'Equipaggiamento, cure e oggetti da cattura.';

  @override
  String get homeConsultationTitle => 'CONSULTAZIONE';

  @override
  String get homeConsultationSubtitle =>
      'Cerca informazioni e aggiorna i progressi.';

  @override
  String get homeOpenPokedexTitle => 'Apri Pokédex';

  @override
  String get homeOpenPokedexSubtitle => 'Consulta, filtra e marca i Pokémon.';

  @override
  String get homeMasterToolsTitle => 'STRUMENTI DEL MASTER';

  @override
  String get homeMasterToolsSubtitle =>
      'Genera contenuti, usa le librerie e prepara i fight.';

  @override
  String get homeOpenMasterToolsTitle => 'Apri Strumenti del Master';

  @override
  String get homeOpenMasterToolsSubtitle =>
      'Generatori Pokémon, incontri, raccolte e Allenatori PNG.';

  @override
  String get homeAppManagementTitle => 'GESTIONE APPLICAZIONE';

  @override
  String get homeAppManagementSubtitle =>
      'Gestisci i profili e i dati dell’app.';

  @override
  String get homeProfilesTitle => 'Profili';

  @override
  String get homeProfilesSubtitle =>
      'Crea, cambia o elimina profili allenatore.';

  @override
  String get trainerFallback => 'Allenatore';

  @override
  String homeGreeting(String name) {
    return 'Ciao, $name';
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
    return 'Pokéslot $count';
  }

  @override
  String trainerMaxSrChip(num value) {
    return 'SR max $value';
  }

  @override
  String get pokedexProgressTitle => 'Progresso Pokédex';

  @override
  String get seenLabel => 'Visti';

  @override
  String get caughtLabel => 'Catturati';

  @override
  String errorWithMessage(String message) {
    return 'Errore: $message';
  }

  @override
  String get retryAction => 'Riprova';
}
