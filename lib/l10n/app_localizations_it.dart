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

  @override
  String get onboardingStartAdventure => 'INIZIA LA TUA AVVENTURA';

  @override
  String get onboardingConfirm => 'CONFERMA';

  @override
  String get onboardingCreatingProfile => 'CREAZIONE IN CORSO...';

  @override
  String get onboardingBegin => 'INIZIA!';

  @override
  String get onboardingProfileCreationError =>
      'Non è stato possibile creare il profilo. Riprova.';

  @override
  String get onboardingProfessor => 'Professore';

  @override
  String get onboardingWelcomeTitle => 'Benvenuto nel tuo nuovo viaggio.';

  @override
  String get onboardingWelcomeBody =>
      'Qui potrai creare il tuo Allenatore, scegliere il primo compagno e prepararti alle avventure da tavolo.';

  @override
  String get onboardingWelcomeNote =>
      'Le tue scelte potranno essere modificate in seguito dal profilo.';

  @override
  String get onboardingNameTitle => 'Prima di iniziare, dimmi…';

  @override
  String get onboardingNameBody => 'Come ti chiami?';

  @override
  String get onboardingTrainerNameLabel => 'Nome Allenatore';

  @override
  String get onboardingTrainerNameHint => 'Inserisci il tuo nome';

  @override
  String get onboardingAgeTitle => 'Bene! E quanti anni hai?';

  @override
  String get onboardingAgeBody =>
      'Puoi sempre modificare questa informazione in seguito.';

  @override
  String get onboardingOriginTitle =>
      'Ogni Allenatore porta con sé una storia.';

  @override
  String get onboardingOriginBody => 'Da dove provieni?';

  @override
  String get onboardingOriginLabel => 'Origine';

  @override
  String get onboardingOriginBonusLabel => 'Bonus caratteristiche';

  @override
  String get onboardingProficienciesLabel => 'Competenze';

  @override
  String get onboardingNoAutomaticBonuses => 'Nessun bonus automatico';

  @override
  String get onboardingNoAdditionalProficiencies =>
      'Nessuna competenza aggiuntiva';

  @override
  String get onboardingBackgroundTitle => 'Quale strada ti ha portato fin qui?';

  @override
  String get onboardingBackgroundBody =>
      'Scegli il background che descrive meglio il tuo Allenatore.';

  @override
  String get onboardingBackgroundLabel => 'Background';

  @override
  String get onboardingBackgroundResearcher => 'Ricercatore';

  @override
  String get onboardingBackgroundResearcherDescription =>
      'Osservi, cataloghi e studi ogni scoperta prima di trarre conclusioni.';

  @override
  String get onboardingBackgroundExplorer => 'Esploratore';

  @override
  String get onboardingBackgroundExplorerDescription =>
      'Ti senti a casa sulle strade meno battute e negli ambienti selvaggi.';

  @override
  String get onboardingBackgroundBreeder => 'Allevatore';

  @override
  String get onboardingBackgroundBreederDescription =>
      'Conosci le necessità delle creature e costruisci legami pazienti.';

  @override
  String get onboardingBackgroundFighter => 'Combattente';

  @override
  String get onboardingBackgroundFighterDescription =>
      'Affronti le difficoltà con disciplina, coraggio e spirito competitivo.';

  @override
  String get onboardingBackgroundArtist => 'Artista';

  @override
  String get onboardingBackgroundArtistDescription =>
      'Esprimi te stesso attraverso spettacolo, creatività e sensibilità.';

  @override
  String get onboardingBackgroundScholar => 'Studioso';

  @override
  String get onboardingBackgroundScholarDescription =>
      'Hai dedicato anni a libri, tradizioni e conoscenze specialistiche.';

  @override
  String get onboardingStarterTitle => 'Infine, scegli il tuo primo compagno.';

  @override
  String get onboardingStarterBody =>
      'Puoi scegliere qualunque Pokémon non evoluto con SR 1/2 o inferiore.';

  @override
  String get onboardingStarterSearchLabel => 'Cerca per nome o tipo';

  @override
  String get onboardingStarterSearchHint => 'Esempio: Bulbasaur, Erba, Fuoco…';

  @override
  String get onboardingNoStarterResults =>
      'Nessun Pokémon corrisponde alla ricerca.';

  @override
  String get onboardingSummaryTitle => 'Ecco il tuo profilo.';

  @override
  String get onboardingSummaryBody =>
      'Controlla le scelte e preparati a iniziare.';

  @override
  String get onboardingNameLabel => 'Nome';

  @override
  String get onboardingAgeLabel => 'Età';

  @override
  String get onboardingStarterLabel => 'Starter';

  @override
  String get onboardingSavingTitle => 'Sto creando il tuo profilo.';

  @override
  String get onboardingSavingBody =>
      'Un momento… sto preparando il tuo Allenatore e il primo Pokémon.';

  @override
  String get onboardingSavingErrorBody =>
      'Qualcosa non ha funzionato. Puoi riprovare senza perdere le tue scelte.';

  @override
  String get onboardingDoneTitle => 'Tutto pronto!';

  @override
  String get onboardingDoneBody =>
      'La tua avventura sta per iniziare. Ci vediamo nel mondo dei Pokémon!';

  @override
  String get onboardingDoneNote =>
      'Il profilo e il tuo starter sono stati creati correttamente.';

  @override
  String get onboardingTagline => 'Il tuo compagno per le avventure da tavolo';

  @override
  String get onboardingMissingCoverBackground => 'SFONDO COPERTINA';

  @override
  String get onboardingMissingLabBackground => 'SFONDO LABORATORIO';

  @override
  String get onboardingMissingProfessor => 'PROFESSORE PNG\nTRASPARENTE';

  @override
  String get onboardingOriginDmApprovedName => 'Origine 5e approvata dal DM';

  @override
  String get onboardingOriginAlolanDescription =>
      'Bonus caratteristiche: INT +2, CHA +1.\nCompetenza: Nature.\nTratto: puoi lanciare Speak with Pokémon una volta per riposo lungo. È una buona origine per trainer curiosi, sociali e molto legati alla vita naturale dei Pokémon.';

  @override
  String get onboardingOriginHoennianDescription =>
      'Bonus caratteristiche: WIS +2, INT +1.\nCompetenza: Survival.\nTratto: sei abituato a viaggiare in ambienti difficili e a cavartela tra clima, terreno e rotte selvagge. Funziona bene per esploratori, ranger e allenatori da viaggio.';

  @override
  String get onboardingOriginJohtoanDescription =>
      'Bonus caratteristiche: INT +2, STR +1.\nCompetenza: History.\nTratto: la tua formazione richiama tradizioni antiche e disciplina fisica; il tratto marziale premia i colpi critici con armi. Adatta a trainer legati a storia, templi, rovine e leggende.';

  @override
  String get onboardingOriginKalosianDescription =>
      'Bonus caratteristiche: CHA +2, INT +1.\nCompetenza: Persuasion.\nTratto: puoi ritirare un 1 secondo le regole dell’origine. È pensata per trainer eleganti, diplomatici e capaci di restare lucidi quando contano presenza e stile.';

  @override
  String get onboardingOriginKantoanDescription =>
      'Bonus caratteristiche: +1 a due caratteristiche a scelta. Questo bonus va assegnato manualmente nei box delle caratteristiche.\nCompetenza: Investigation.\nTratto: ottieni un talento approvato dal DM. È l’origine più flessibile, ottima per costruire un trainer molto personalizzato.';

  @override
  String get onboardingOriginSinnoanDescription =>
      'Bonus caratteristiche: CON +2, STR +1.\nCompetenza: Athletics.\nTratto: ottieni competenza nei tiri salvezza di Costituzione. Ideale per allenatori resistenti, abituati a montagna, neve e lunghe spedizioni.';

  @override
  String get onboardingOriginUnovanDescription =>
      'Bonus caratteristiche: DEX +2, WIS +1.\nCompetenza: Insight.\nTratto: ottieni due competenze aggiuntive a scelta. Perfetta per trainer rapidi, adattabili e capaci di leggere persone e situazioni.';

  @override
  String get onboardingOriginGalarianDescription =>
      'Bonus caratteristiche: scegli DEX +2 e STR +1 oppure STR +2 e DEX +1. Questo bonus va assegnato manualmente nei box delle caratteristiche.\nCompetenza: Intimidation.\nTratto: ottieni una reazione difensiva. Adatta a trainer competitivi, fisici e abituati a reggere la pressione dello scontro.';

  @override
  String get onboardingOriginDmApprovedDescription =>
      'Usa un’origine 5e classica o homebrew approvata dal DM. Segna manualmente bonus caratteristiche, competenze e tratti concordati al tavolo.';
}
