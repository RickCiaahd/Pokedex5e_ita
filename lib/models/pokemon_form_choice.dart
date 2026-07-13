import 'pokedex_entry.dart';

String pokemonFormChoiceKey({
  required int pokemonId,
  required String speciesName,
  String? formName,
}) {
  final formKey = PokedexEntry.formKey(formName, speciesName: speciesName);
  return '$pokemonId|$formKey';
}

String pokemonFormDisplayName(String speciesName, String? formName) {
  final raw = formName?.trim() ?? '';
  if (raw.isEmpty ||
      PokedexEntry.formKey(raw, speciesName: speciesName) == 'base') {
    return speciesName;
  }

  final normalized = raw.toLowerCase();
  if (normalized.contains('alola')) return '$speciesName di Alola';
  if (normalized.contains('galar')) return '$speciesName di Galar';
  if (normalized.contains('hisui')) return '$speciesName di Hisui';
  if (normalized.contains('paldea')) return '$speciesName di Paldea';

  return '$speciesName — $raw';
}

String pokemonFormSubtitle(String? formName) {
  final raw = formName?.trim() ?? '';
  return raw.isEmpty ? 'Forma base' : 'Forma selezionata: $raw';
}
