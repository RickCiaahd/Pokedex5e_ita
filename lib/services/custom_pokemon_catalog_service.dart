import 'dart:convert';

import '../models/custom_pokemon_catalog_bundle.dart';
import '../repositories/custom_pokemon_repository.dart';
import 'embedded_custom_pokemon_transfer_service.dart';

class CustomPokemonCatalogImportResult {
  const CustomPokemonCatalogImportResult({
    required this.total,
    required this.installed,
    required this.updated,
    required this.remapped,
  });

  final int total;
  final int installed;
  final int updated;
  final int remapped;
}

class CustomPokemonCatalogService {
  CustomPokemonCatalogService({
    CustomPokemonRepository? repository,
    EmbeddedCustomPokemonTransferService? embeddedTransferService,
  }) : _repository = repository ?? CustomPokemonRepository(),
       _embeddedTransferService =
           embeddedTransferService ?? EmbeddedCustomPokemonTransferService();

  final CustomPokemonRepository _repository;
  final EmbeddedCustomPokemonTransferService _embeddedTransferService;

  Future<CustomPokemonCatalogBundle> createBundle() async {
    final definitions = await _repository.getAll();
    if (definitions.isEmpty) {
      throw StateError('Non ci sono Fakemon da esportare.');
    }
    return CustomPokemonCatalogBundle.create(definitions);
  }

  String encode(CustomPokemonCatalogBundle bundle) {
    return const JsonEncoder.withIndent('  ').convert(bundle.toJson());
  }

  CustomPokemonCatalogBundle decode(String source) {
    final normalized = source.startsWith('\uFEFF')
        ? source.substring(1)
        : source;
    final decoded = jsonDecode(normalized);
    if (decoded is! Map) {
      throw const FormatException(
        'Il file selezionato non è un catalogo Fakemon valido.',
      );
    }
    return CustomPokemonCatalogBundle.fromJson(
      Map<String, dynamic>.from(decoded),
    );
  }

  Future<CustomPokemonCatalogImportResult> importBundle(
    CustomPokemonCatalogBundle bundle,
  ) async {
    final result = await _embeddedTransferService.installDefinitions(
      bundle.definitions,
    );
    return CustomPokemonCatalogImportResult(
      total: bundle.definitions.length,
      installed: result.installed,
      updated: result.updated,
      remapped: result.remapped,
    );
  }

  String fileNameFor(CustomPokemonCatalogBundle bundle) {
    final date = bundle.exportedAt.toIso8601String().split('T').first;
    return 'pokedex-5e-catalogo-fakemon-$date.p5fakemonpack';
  }
}
