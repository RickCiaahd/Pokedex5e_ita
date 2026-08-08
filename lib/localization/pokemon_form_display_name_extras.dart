import '../models/pokemon.dart';
import 'game_catalog_locale.dart';

/// Extra labels for catalog families whose technical form identifiers are
/// driven by held items or contain names that should never leak into the
/// Italian UI.
class PokemonFormDisplayNameExtras {
  const PokemonFormDisplayNameExtras._();

  static String? label(Pokemon pokemon, String? formName) {
    if (!GameCatalogLocale.isItalian) return null;
    final key = Pokemon.formReferenceKey(formName?.trim() ?? '', pokemon.name);
    switch (pokemon.name.trim().toLowerCase()) {
      case 'arceus':
      case 'silvally':
        return _typeFormLabels[key];
      case 'genesect':
        return _genesectLabels[key];
      case 'alcremie':
        return _alcremieLabels[key];
      case 'floette':
        if (key == 'eternal-flower') return 'Fiore Eterno';
        return null;
      case 'wormadam':
        if (key == 'sand-cloak') return 'Manto Sabbia';
        return null;
      default:
        return null;
    }
  }

  static const Map<String, String> _typeFormLabels = {
    'base': 'Tipo Normale',
    'bug': 'Tipo Coleottero',
    'dark': 'Tipo Buio',
    'dragon': 'Tipo Drago',
    'electric': 'Tipo Elettro',
    'fairy': 'Tipo Folletto',
    'fighting': 'Tipo Lotta',
    'fire': 'Tipo Fuoco',
    'flying': 'Tipo Volante',
    'ghost': 'Tipo Spettro',
    'grass': 'Tipo Erba',
    'ground': 'Tipo Terra',
    'ice': 'Tipo Ghiaccio',
    'poison': 'Tipo Veleno',
    'psychic': 'Tipo Psico',
    'rock': 'Tipo Roccia',
    'steel': 'Tipo Acciaio',
    'water': 'Tipo Acqua',
  };

  static const Map<String, String> _genesectLabels = {
    'base': 'Forma Normale',
    'normal-drive': 'Forma Normale',
    'douse-drive': 'Idromodulo',
    'shock-drive': 'Voltmodulo',
    'burn-drive': 'Piromodulo',
    'chill-drive': 'Gelomodulo',
  };

  static const Map<String, String> _alcremieLabels = {
    'base': 'Crema Vaniglia',
    'vanilla-cream': 'Crema Vaniglia',
    'ruby-cream': 'Crema Rubino',
    'matcha-cream': 'Crema Matcha',
    'mint-cream': 'Crema Menta',
    'lemon-cream': 'Crema Limone',
    'salted-cream': 'Crema Salata',
    'ruby-swirl': 'Vortice Rubino',
    'caramel-swirl': 'Vortice Caramello',
    'rainbow-swirl': 'Vortice Arcobaleno',
  };
}
