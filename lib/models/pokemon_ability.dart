class PokemonAbility {
  const PokemonAbility({
    required this.id,
    required this.name,
    required this.description,
    required this.deprecated,
    String? displayName,
  }) : displayName = displayName ?? name;

  final String id;

  /// Nome tecnico conservato nei dati e nei salvataggi.
  final String name;

  /// Nome mostrato all'utente, localizzato quando esiste un equivalente
  /// ufficiale nei videogiochi.
  final String displayName;

  final String description;
  final bool deprecated;

  factory PokemonAbility.fromWebJson(Map<String, dynamic> json) {
    return PokemonAbility(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Abilità sconosciuta',
      description: json['description']?.toString() ?? '',
      deprecated: json['deprecated'] == true,
    );
  }
}
