import '../models/pokemon.dart';
import 'game_catalog_locale.dart';

class PokemonFormLocalizedText {
  const PokemonFormLocalizedText({
    required this.genus,
    required this.description,
  });

  final String genus;
  final String description;
}

/// Visible labels and localized metadata for Pokémon forms.
///
/// Technical form names stay unchanged in saves and asset lookup. This class
/// only translates what the user sees.
class PokemonFormLocalization {
  const PokemonFormLocalization._();

  static String formLabel(Pokemon pokemon, String? formName) {
    final raw = formName?.trim() ?? '';
    final key = Pokemon.formReferenceKey(raw, pokemon.name);

    if (!GameCatalogLocale.isItalian) {
      if (key == 'base') return 'Base form';
      return raw.isEmpty ? 'Base form' : raw;
    }

    if (pokemon.id == 999) {
      if (key == 'base') return 'Scrigno';
      if (key == 'roaming') return 'Ambulante';
    }

    switch (key) {
      case 'base':
        return 'Forma base';
      case 'alolan':
        return 'Forma di Alola';
      case 'galarian':
        return 'Forma di Galar';
      case 'hisuian':
        return 'Forma di Hisui';
      case 'paldean':
        return 'Forma di Paldea';
      default:
        return raw.isEmpty ? 'Forma base' : raw;
    }
  }

  static String evolutionName(String value) {
    final trimmed = value.trim();
    if (!GameCatalogLocale.isItalian || trimmed.isEmpty) return trimmed;

    final regional = RegExp(
      r'^(Alolan|Galarian|Hisuian|Paldean)\s+(.+)$',
      caseSensitive: false,
    ).firstMatch(trimmed);
    if (regional != null) {
      final region = switch (regional.group(1)!.toLowerCase()) {
        'alolan' => 'Alola',
        'galarian' => 'Galar',
        'hisuian' => 'Hisui',
        'paldean' => 'Paldea',
        _ => regional.group(1)!,
      };
      return '${regional.group(2)} di $region';
    }

    final gendered = RegExp(r'^(.+)\s+([MF])$').firstMatch(trimmed);
    if (gendered != null) {
      return '${gendered.group(1)} ${gendered.group(2) == 'M' ? '♂' : '♀'}';
    }

    return trimmed;
  }

  static PokemonFormLocalizedText? textFor(Pokemon pokemon) {
    if (!GameCatalogLocale.isItalian) return null;
    final slug = pokemon.assetSlug?.trim().toLowerCase();
    if (slug == null || slug.isEmpty) return null;
    return italianTextForAssetSlug(slug, speciesName: pokemon.name);
  }

  static PokemonFormLocalizedText? italianTextForAssetSlug(
    String rawSlug, {
    required String speciesName,
  }) {
    final slug = rawSlug.trim().toLowerCase();
    final exact = _italianByAssetSlug[slug];
    if (exact != null) return exact;
    final region = regionForAssetSlug(slug);
    if (region == null) return null;
    return PokemonFormLocalizedText(
      genus: 'Pokémon regionale',
      description:
          'Forma regionale di $speciesName originaria di $region. '
          'La descrizione italiana specifica di questa forma non è ancora disponibile.',
    );
  }

  static bool hasSpecificItalianTextForAssetSlug(String rawSlug) =>
      _italianByAssetSlug.containsKey(rawSlug.trim().toLowerCase());

  static bool isRegionalAssetSlug(String rawSlug) =>
      regionForAssetSlug(rawSlug) != null;

  static String? regionForAssetSlug(String rawSlug) {
    final slug = rawSlug.trim().toLowerCase();
    if (slug.startsWith('alolan-')) return 'Alola';
    if (slug.startsWith('galarian-') || slug.contains('-galar')) return 'Galar';
    if (slug.contains('-hisui')) return 'Hisui';
    if (slug.contains('-paldea')) return 'Paldea';
    return null;
  }

  static const Map<String, PokemonFormLocalizedText> _italianByAssetSlug = {
    'alolan-rattata': PokemonFormLocalizedText(genus: 'Pokémon Topo', description: 'Notte dopo notte si intrufola nelle case delle persone in cerca di cibo. Un\'enorme infestazione di questi Pokémon è diventata un problema di interesse pubblico.'),
    'alolan-raticate': PokemonFormLocalizedText(genus: 'Pokémon Topo', description: 'Ha un\'indole incredibilmente ingorda. Il suo nido è colmo di così tanto cibo raccolto dai Rattata sotto la sua direzione che non potrebbe mai mangiarlo tutto.'),
    'alolan-raichu': PokemonFormLocalizedText(genus: 'Pokémon Topo', description: 'Adora i pancake preparati con una ricetta segreta di Alola. C\'è chi si chiede se proprio quella ricetta nasconda il segreto dell\'evoluzione di questo Pokémon.'),
    'alolan-sandshrew': PokemonFormLocalizedText(genus: 'Pokémon Topo', description: 'Un\'antica tradizione delle feste di Alola, praticata ancora oggi, consiste in una gara a chi riesce a far scivolare più lontano un Sandshrew sul ghiaccio.'),
    'alolan-sandslash': PokemonFormLocalizedText(genus: 'Pokémon Topo', description: 'Usa i suoi grandi artigli ricurvi per aprirsi un varco nella neve profonda mentre corre. Sulle montagne innevate, questo Sandslash è più veloce di qualunque altro Pokémon.'),
    'alolan-vulpix': PokemonFormLocalizedText(genus: 'Pokémon Volpe', description: 'Se ti avvicini con leggerezza perché lo trovi carino, il capo del branco, Ninetales, comparirà e ti congelerà.'),
    'alolan-ninetales': PokemonFormLocalizedText(genus: 'Pokémon Volpe', description: 'Il motivo per cui accompagna le persone fino ai piedi della montagna è che vuole che si sbrighino ad andarsene.'),
    'alolan-diglett': PokemonFormLocalizedText(genus: 'Pokémon Talpa', description: 'I suoi tre capelli cambiano forma a seconda del suo umore. Quando comunica con i compagni, i suoi baffi oscillano avanti e indietro.'),
    'alolan-dugtrio': PokemonFormLocalizedText(genus: 'Pokémon Talpa', description: 'La sua splendente chioma dorata gli offre protezione. Si dice che conservare uno dei suoi capelli caduti porti sfortuna.'),
    'alolan-meowth': PokemonFormLocalizedText(genus: 'Pokémon Graffimiao', description: 'Quando il suo delicato orgoglio viene ferito, o la moneta d\'oro sulla fronte si sporca, va incontro a una crisi d\'ira incontrollabile.'),
    'alolan-persian': PokemonFormLocalizedText(genus: 'Pokémon Gatto Elegante', description: 'Guarda tutti dall\'alto in basso, tranne sé stesso. Le sue tattiche preferite sono i colpi bassi e gli attacchi alle spalle.'),
    'alolan-geodude': PokemonFormLocalizedText(genus: 'Pokémon Roccia', description: 'La sua testa di pietra è impregnata di elettricità e magnetismo. Se lo calpesti distrattamente, ti aspetta una dolorosa scossa.'),
    'alolan-graveler': PokemonFormLocalizedText(genus: 'Pokémon Roccia', description: 'Mangiano rocce e spesso finiscono per azzuffarsi per esse. L\'urto tra Graveler provoca lampi di luce e boati.'),
    'alolan-golem': PokemonFormLocalizedText(genus: 'Pokémon Megatone', description: 'Poiché non riesce a sparare massi a raffica, è noto che afferri i Geodude nelle vicinanze e li scagli dalla schiena.'),
    'alolan-grimer': PokemonFormLocalizedText(genus: 'Pokémon Melma', description: 'Portato ad Alola per risolvere il problema dei rifiuti, Grimer sembra apprezzare qualsiasi tipo di spazzatura.'),
    'alolan-muk': PokemonFormLocalizedText(genus: 'Pokémon Melma', description: 'Nonostante sia sorprendentemente tranquillo e amichevole, se non riceve spazzatura da mangiare per un po\', distrugge i mobili del suo Allenatore e ne divora i pezzi.'),
    'alolan-exeggutor': PokemonFormLocalizedText(genus: 'Pokémon Noce di Cocco', description: 'Crescendo sempre più in altezza, ha smesso di dipendere dai poteri psichici, mentre dentro di lui si è risvegliato il potere del drago dormiente.'),
    'alolan-marowak': PokemonFormLocalizedText(genus: 'Pokémon Custode d\'Ossa', description: 'Le ossa che possiede appartenevano un tempo a sua madre. Il rimpianto di sua madre è diventato come uno spirito vendicativo che protegge questo Pokémon.'),
    'galarian-meowth': PokemonFormLocalizedText(genus: 'Pokémon Graffimiao', description: 'Vivere con un popolo selvaggio di navigatori ha irrobustito così tanto il suo corpo che alcune parti si sono trasformate in ferro.'),
    'galarian-ponyta': PokemonFormLocalizedText(genus: 'Pokémon Unicorno', description: 'Il suo piccolo corno nasconde un potere curativo. Bastano pochi sfregamenti del suo corno perché una ferita lieve venga rimarginata.'),
    'galarian-rapidash': PokemonFormLocalizedText(genus: 'Pokémon Unicorno', description: 'Fiero e impavido, Rapidash usa i poteri psichici accumulati nel pelo fluente sopra gli zoccoli per sfrecciare agilmente nella foresta.'),
    'galarian-slowpoke': PokemonFormLocalizedText(genus: 'Pokémon Ronfone', description: 'Di solito ha lo sguardo perso nel vuoto, ma a volte la sua espressione si fa improvvisamente acuta. La causa sembra risiedere nella sua alimentazione.'),
    'galarian-slowbro': PokemonFormLocalizedText(genus: 'Pokémon Paguro', description: 'Il morso di uno Shellder ha innescato una reazione chimica con le spezie presenti nel corpo di Slowbro, trasformandolo in un Pokémon di tipo Veleno.'),
    'galarian-farfetchd': PokemonFormLocalizedText(genus: 'Pokémon Anatra Selvatica', description: 'Porta sempre con sé un porro lungo e pesante il doppio del suo corpo e non lo lascia mai andare.'),
    'galarian-weezing': PokemonFormLocalizedText(genus: 'Pokémon Gas Velenoso', description: 'Consuma le particelle che contaminano l\'aria. Al posto degli escrementi, espelle aria pulita.'),
    'galarian-mr-mime': PokemonFormLocalizedText(genus: 'Pokémon Danza', description: 'È molto abile nel tip tap. Può anche manipolare la temperatura per creare un pavimento di ghiaccio, che solleva a calci e usa come barriera.'),
    'articuno-galar': PokemonFormLocalizedText(genus: 'Pokémon Crudele', description: 'Le sue lame simili a piume sono composte di energia psichica e possono tranciare spesse lastre di ferro come fossero carta.'),
    'zapdos-galar': PokemonFormLocalizedText(genus: 'Pokémon Zampe Forti', description: 'Un calcio delle sue possenti zampe può polverizzare un autocarro. Si dice che corra tra le montagne a oltre 290 km/h.'),
    'moltres-galar': PokemonFormLocalizedText(genus: 'Pokémon Malevolo', description: 'La sua sinistra aura, simile a fiamme, consuma lo spirito di qualunque creatura colpisca. Le vittime restano ombre svuotate di sé stesse.'),
    'galarian-slowking': PokemonFormLocalizedText(genus: 'Pokémon Esperto di Maledizioni', description: 'Una combinazione di tossine e lo shock dell\'evoluzione ha aumentato l\'intelligenza di Shellder al punto che ora è Shellder a controllare Slowking.'),
    'galarian-corsola': PokemonFormLocalizedText(genus: 'Pokémon Corallo', description: 'Un improvviso cambiamento climatico ha spazzato via questa antica varietà di Corsola. Assorbe la forza vitale degli altri attraverso i suoi rami.'),
    'galarian-zigzagoon': PokemonFormLocalizedText(genus: 'Pokémon Procione Minuto', description: 'La sua irrequietezza lo spinge a correre continuamente. Se vede un altro Pokémon, gli corre addosso di proposito per provocare una lotta.'),
    'galarian-linoone': PokemonFormLocalizedText(genus: 'Pokémon Sfrecciante', description: 'Usa la lunga lingua per provocare gli avversari. Quando questi si infuriano, si scaglia contro di loro con un violento placcaggio.'),
    'galarian-darumaka': PokemonFormLocalizedText(genus: 'Pokémon Amuleto Zen', description: 'Ha vissuto così a lungo in zone innevate che la sua sacca del fuoco si è raffreddata e atrofizzata. Al suo posto ora possiede un organo che genera freddo.'),
    'galarian-darmanitan': PokemonFormLocalizedText(genus: 'Pokémon Modalità Zen', description: 'Nei giorni di bufera scende nelle zone abitate. Nasconde il cibo nella palla di neve sulla testa e lo porta a casa per conservarlo.'),
    'galarian-yamask': PokemonFormLocalizedText(genus: 'Pokémon Spirito', description: 'Una lastra d\'argilla incisa da una maledizione ha preso possesso di Yamask. Si dice che la lastra stia assorbendo il suo potere oscuro.'),
    'galarian-stunfisk': PokemonFormLocalizedText(genus: 'Pokémon Trappola', description: 'Le sue labbra vistose attirano le prede mentre resta nascosto nel fango. Quando si avvicinano, le blocca con le sue pinne d\'acciaio seghettate.'),
    'growlithe-hisui': PokemonFormLocalizedText(genus: 'Pokémon Esploratore', description: 'Pattugliano il territorio in coppia. Ritengo che le componenti di roccia ignea presenti nel pelo di questa specie siano il risultato dell\'attività vulcanica del suo habitat.'),
    'arcanine-hisui': PokemonFormLocalizedText(genus: 'Pokémon Leggendario', description: 'Azzanna i nemici con zanne avvolte da fiamme ardenti. Nonostante la mole, finta con grande agilità in ogni direzione, trascinando gli avversari in un inseguimento ingannevole quasi danzando attorno a loro.'),
    'voltorb-hisui': PokemonFormLocalizedText(genus: 'Pokémon Sfera', description: 'Un Pokémon enigmatico che somiglia a una Poké Ball. Quando si agita, scarica la corrente elettrica accumulata nel ventre e poi scoppia in una fragorosa risata.'),
    'electrode-hisui': PokemonFormLocalizedText(genus: 'Pokémon Sfera', description: 'Il tessuto sulla superficie del suo corpo ha una composizione curiosamente simile a quella di una Ghicocca. Quando si irrita, sprigiona una corrente elettrica pari a quella di 20 fulmini.'),
    'typhlosion-hisui': PokemonFormLocalizedText(genus: 'Pokémon Fiamma Spettrale', description: 'Si dice che purifichi con le sue fiamme le anime perdute e abbandonate, guidandole nell\'aldilà. Ritengo che la sua forma sia stata influenzata dall\'energia del monte sacro che svetta al centro di Hisui.'),
    'qwilfish-hisui': PokemonFormLocalizedText(genus: 'Pokémon Pallone', description: 'I pescatori detestano questo Pokémon molesto perché spruzza veleno dagli aculei, spargendolo ovunque. In altre regioni vive una forma diversa di Qwilfish.'),
    'sneasel-hisui': PokemonFormLocalizedText(genus: 'Pokémon Artiglio Affilato', description: 'I suoi robusti artigli ricurvi sono ideali per scalare dirupi scoscesi. Dalle punte cola un veleno che penetra nei nervi delle prede afferrate da Sneasel.'),
    'samurott-hisui': PokemonFormLocalizedText(genus: 'Pokémon Formidabile', description: 'Duro di cuore e abilissimo con le lame, questa rara forma di Samurott è il risultato della sua evoluzione nella regione di Hisui. I suoi colpi impetuosi si abbattono sui nemici come onde incessanti.'),
    'lilligant-hisui': PokemonFormLocalizedText(genus: 'Pokémon Rotante', description: 'Sospetto che le sue gambe ben sviluppate siano il risultato di una vita trascorsa su montagne coperte da neve profonda. Il profumo emanato dalla corona di fiori rincuora chi gli sta vicino.'),
    'zorua-hisui': PokemonFormLocalizedText(genus: 'Pokémon Volpe Rancorosa', description: 'Un\'anima un tempo defunta, tornata in vita a Hisui. Trae potere dal rancore, che si innalza come energia sopra la sua testa assumendo la forma dei nemici. In questo modo Zorua sfoga la malizia rimasta.'),
    'zoroark-hisui': PokemonFormLocalizedText(genus: 'Pokémon Volpe Funesta', description: 'Con il suo pelo bianco e scompigliato sembra un\'incarnazione della morte. Senza badare alla propria incolumità, attacca i nemici con un\'energia amara così intensa da lacerare persino il suo stesso corpo.'),
    'braviary-hisui': PokemonFormLocalizedText(genus: 'Pokémon Grido di Battaglia', description: 'Emettendo un grido di battaglia agghiacciante, questo enorme e feroce Pokémon uccello va a caccia. Colpisce i laghi con onde d\'urto e poi raccoglie le prede che affiorano in superficie.'),
    'sliggoo-hisui': PokemonFormLocalizedText(genus: 'Pokémon Lumaca', description: 'Creatura incline alla malinconia. Sospetto che il suo guscio metallico si sia sviluppato per la reazione tra il muco sulla pelle e il ferro presente nelle acque di Hisui.'),
    'goodra-hisui': PokemonFormLocalizedText(genus: 'Pokémon Bunker Guscio', description: 'Può controllare liberamente la durezza del suo guscio metallico. Detesta la solitudine ed è estremamente appiccicoso: se chi gli è caro lo lascia, si infuria e va su tutte le furie.'),
    'avalugg-hisui': PokemonFormLocalizedText(genus: 'Pokémon Iceberg', description: 'L\'armatura di ghiaccio che ricopre la mandibola è più dura dell\'acciaio e frantuma facilmente le rocce. Questo Pokémon si lancia lungo ripidi sentieri di montagna fendendo la neve profonda.'),
    'decidueye-hisui': PokemonFormLocalizedText(genus: 'Pokémon Penna-Freccia', description: 'L\'aria immagazzinata nei rachidi delle piume lo isola dal freddo estremo di Hisui. È una prova evidente che l\'evoluzione può essere influenzata dall\'ambiente.'),
    'tauros-paldea-combat-breed': PokemonFormLocalizedText(genus: 'Pokémon Toro Selvatico', description: 'Ha un corpo muscoloso ed eccelle nel combattimento ravvicinato. Usa le corte corna per colpire i punti deboli dell\'avversario.'),
    'tauros-paldea-blaze-breed': PokemonFormLocalizedText(genus: 'Pokémon Toro Selvatico', description: 'Quando vengono riscaldate dall\'energia del fuoco, le sue corna possono superare i 980 °C. Chi viene incornato subisce sia ferite sia ustioni.'),
    'tauros-paldea-aqua-breed': PokemonFormLocalizedText(genus: 'Pokémon Toro Selvatico', description: 'Spara acqua dai fori sulla punta delle corna: i getti ad alta pressione perforano i nemici di Tauros.'),
    'wooper-paldea': PokemonFormLocalizedText(genus: 'Pokémon Pesce Velenoso', description: 'Dopo aver perso una lotta per il territorio, Wooper ha iniziato a vivere sulla terraferma. Col tempo il Pokémon è cambiato, sviluppando una pellicola velenosa per proteggere il corpo.'),
  };
}
