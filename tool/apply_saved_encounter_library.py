from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding='utf-8')


def write(path: str, content: str) -> None:
    file_path = ROOT / path
    file_path.parent.mkdir(parents=True, exist_ok=True)
    file_path.write_text(content, encoding='utf-8')


def replace_once(source: str, old: str, new: str, label: str) -> str:
    count = source.count(old)
    if count != 1:
        raise RuntimeError(f'{label}: expected one match, found {count}')
    return source.replace(old, new, 1)


write(
    'lib/models/saved_encounter.dart',
    r'''import 'generated_encounter.dart';

class SavedEncounterMember {
  const SavedEncounterMember({
    required this.pokemonId,
    required this.level,
    required this.nature,
    required this.selectedMoves,
    required this.isShiny,
    required this.maxHp,
    this.formName,
    this.gender,
    this.ability,
    this.isLocked = false,
  });

  final int pokemonId;
  final String? formName;
  final int level;
  final String? gender;
  final String nature;
  final String? ability;
  final List<String> selectedMoves;
  final bool isShiny;
  final int maxHp;
  final bool isLocked;

  Map<String, dynamic> toJson() => {
    'pokemonId': pokemonId,
    'formName': formName,
    'level': level,
    'gender': gender,
    'nature': nature,
    'ability': ability,
    'selectedMoves': selectedMoves,
    'isShiny': isShiny,
    'maxHp': maxHp,
    'isLocked': isLocked,
  };

  factory SavedEncounterMember.fromJson(Map<String, dynamic> json) {
    return SavedEncounterMember(
      pokemonId: _readInt(json['pokemonId']),
      formName: _readNullableString(json['formName']),
      level: _readInt(json['level'], fallback: 1),
      gender: _readNullableString(json['gender']),
      nature: json['nature']?.toString() ?? 'No Nature',
      ability: _readNullableString(json['ability']),
      selectedMoves: [
        for (final value in json['selectedMoves'] is List
            ? List<dynamic>.from(json['selectedMoves'] as List)
            : const <dynamic>[])
          if (value.toString().trim().isNotEmpty) value.toString(),
      ],
      isShiny: json['isShiny'] == true,
      maxHp: _readInt(json['maxHp'], fallback: 1),
      isLocked: json['isLocked'] == true,
    );
  }
}

class SavedEncounter {
  const SavedEncounter({
    required this.id,
    required this.name,
    required this.source,
    required this.party,
    required this.filters,
    required this.targetDifficulty,
    required this.members,
    required this.createdAt,
    required this.updatedAt,
    this.notes = '',
    this.collectionId,
    this.collectionName,
  });

  final String id;
  final String name;
  final String notes;
  final EncounterSource source;
  final EncounterPartyProfile party;
  final EncounterGeneratorFilters filters;
  final EncounterDifficulty targetDifficulty;
  final List<SavedEncounterMember> members;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? collectionId;
  final String? collectionName;

  int get enemyCount => members.length;

  double get averageEnemyLevel {
    if (members.isEmpty) return 0;
    return members.fold<int>(0, (sum, member) => sum + member.level) /
        members.length;
  }

  bool get isValid =>
      id.trim().isNotEmpty &&
      name.trim().isNotEmpty &&
      members.isNotEmpty &&
      members.every(
        (member) =>
            member.pokemonId > 0 &&
            member.level > 0 &&
            member.maxHp > 0 &&
            member.nature.trim().isNotEmpty,
      );

  SavedEncounter copyWith({
    String? id,
    String? name,
    String? notes,
    List<SavedEncounterMember>? members,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SavedEncounter(
      id: id ?? this.id,
      name: name ?? this.name,
      notes: notes ?? this.notes,
      source: source,
      party: party,
      filters: filters,
      targetDifficulty: targetDifficulty,
      members: members ?? this.members,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      collectionId: collectionId,
      collectionName: collectionName,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'notes': notes,
    'source': source.name,
    'party': {
      'trainerCount': party.trainerCount,
      'activePokemon': party.activePokemon,
      'averageLevel': party.averageLevel,
    },
    'filters': {
      'habitat': filters.habitat,
      'type': filters.type,
      'minSr': filters.minSr,
      'maxSr': filters.maxSr,
      'minGeneration': filters.minGeneration,
      'maxGeneration': filters.maxGeneration,
      'level': filters.level,
      'includeForms': filters.includeForms,
      'allowLegendary': filters.allowLegendary,
    },
    'targetDifficulty': targetDifficulty.name,
    'members': members.map((member) => member.toJson()).toList(growable: false),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'collectionId': collectionId,
    'collectionName': collectionName,
  };

  factory SavedEncounter.fromJson(Map<String, dynamic> json) {
    final partyJson = json['party'] is Map
        ? Map<String, dynamic>.from(json['party'] as Map)
        : const <String, dynamic>{};
    final filtersJson = json['filters'] is Map
        ? Map<String, dynamic>.from(json['filters'] as Map)
        : const <String, dynamic>{};
    final now = DateTime.now();
    return SavedEncounter(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
      source: _sourceFrom(json['source']),
      party: EncounterPartyProfile(
        trainerCount: _readInt(partyJson['trainerCount'], fallback: 1),
        activePokemon: _readInt(partyJson['activePokemon'], fallback: 1),
        averageLevel: _readInt(partyJson['averageLevel'], fallback: 5),
      ),
      filters: EncounterGeneratorFilters(
        habitat: filtersJson['habitat']?.toString() ?? 'Qualsiasi',
        type: _readNullableString(filtersJson['type']),
        minSr: _readDouble(filtersJson['minSr']),
        maxSr: _readDouble(filtersJson['maxSr'], fallback: 20),
        minGeneration: _readInt(filtersJson['minGeneration'], fallback: 1),
        maxGeneration: _readInt(filtersJson['maxGeneration'], fallback: 9),
        level: _readInt(filtersJson['level']),
        includeForms: filtersJson['includeForms'] != false,
        allowLegendary: filtersJson['allowLegendary'] == true,
      ),
      targetDifficulty: _difficultyFrom(json['targetDifficulty']),
      members: [
        for (final value in json['members'] is List
            ? List<dynamic>.from(json['members'] as List)
            : const <dynamic>[])
          if (value is Map)
            SavedEncounterMember.fromJson(Map<String, dynamic>.from(value)),
      ],
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? now,
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ?? now,
      collectionId: _readNullableString(json['collectionId']),
      collectionName: _readNullableString(json['collectionName']),
    );
  }
}

EncounterSource _sourceFrom(dynamic value) {
  final name = value?.toString();
  return EncounterSource.values.firstWhere(
    (candidate) => candidate.name == name,
    orElse: () => EncounterSource.manual,
  );
}

EncounterDifficulty _difficultyFrom(dynamic value) {
  final name = value?.toString();
  return EncounterDifficulty.values.firstWhere(
    (candidate) => candidate.name == name,
    orElse: () => EncounterDifficulty.medium,
  );
}

int _readInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

double _readDouble(dynamic value, {double fallback = 0}) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? fallback;
}

String? _readNullableString(dynamic value) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? null : text;
}
''',
)

write(
    'lib/repositories/saved_encounter_repository.dart',
    r'''import 'package:hive_flutter/hive_flutter.dart';

import '../database/hive_boxes.dart';
import '../models/saved_encounter.dart';

class SavedEncounterRepository {
  Future<Box> _box() => Hive.openBox(HiveBoxes.savedEncounters);

  Future<List<SavedEncounter>> getEncounters(String profileId) async {
    final box = await _box();
    final data = box.get(profileId);
    if (data == null) return const [];

    final encounters = [
      for (final value in List<dynamic>.from(data as List))
        if (value is Map)
          SavedEncounter.fromJson(Map<String, dynamic>.from(value)),
    ];
    encounters.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return encounters;
  }

  Future<void> replaceEncounters(
    String profileId,
    List<SavedEncounter> encounters,
  ) async {
    final box = await _box();
    await box.put(
      profileId,
      encounters.map((encounter) => encounter.toJson()).toList(growable: false),
    );
    await box.flush();
  }

  Future<void> saveEncounter({
    required String profileId,
    required SavedEncounter encounter,
  }) async {
    if (!encounter.isValid) {
      throw const FormatException('L’incontro da salvare non è valido.');
    }
    final encounters = await getEncounters(profileId);
    final updated = [
      encounter,
      for (final existing in encounters)
        if (existing.id != encounter.id) existing,
    ];
    await replaceEncounters(profileId, updated);
  }

  Future<void> deleteEncounter({
    required String profileId,
    required String encounterId,
  }) async {
    final encounters = await getEncounters(profileId);
    await replaceEncounters(profileId, [
      for (final encounter in encounters)
        if (encounter.id != encounterId) encounter,
    ]);
  }

  Future<void> deleteEncounters(String profileId) async {
    final box = await _box();
    await box.delete(profileId);
    await box.flush();
  }
}
''',
)

write(
    'lib/services/saved_encounter_mapper_service.dart',
    r'''import '../models/generated_encounter.dart';
import '../models/generated_pokemon.dart';
import '../models/pokemon.dart';
import '../models/saved_encounter.dart';
import 'encounter_generator_service.dart';

class SavedEncounterMapperService {
  const SavedEncounterMapperService({
    this.encounterService = const EncounterGeneratorService(),
  });

  final EncounterGeneratorService encounterService;

  SavedEncounter fromGenerated(
    GeneratedEncounter encounter, {
    required String name,
    String notes = '',
    SavedEncounter? existing,
    DateTime? now,
  }) {
    final timestamp = now ?? DateTime.now();
    return SavedEncounter(
      id: existing?.id ?? timestamp.microsecondsSinceEpoch.toString(),
      name: name.trim(),
      notes: notes.trim(),
      source: encounter.source,
      party: encounter.party,
      filters: encounter.filters,
      targetDifficulty: encounter.targetDifficulty,
      members: [
        for (final member in encounter.members)
          SavedEncounterMember(
            pokemonId: member.pokemon.basePokemon.id,
            formName: member.pokemon.formName,
            level: member.pokemon.level,
            gender: member.pokemon.gender,
            nature: member.pokemon.nature,
            ability: member.pokemon.ability,
            selectedMoves: member.pokemon.selectedMoves,
            isShiny: member.pokemon.isShiny,
            maxHp: member.pokemon.maxHp,
            isLocked: member.isLocked,
          ),
      ],
      createdAt: existing?.createdAt ?? timestamp,
      updatedAt: timestamp,
      collectionId: encounter.collectionId,
      collectionName: encounter.collectionName,
    );
  }

  GeneratedEncounter toGenerated({
    required SavedEncounter saved,
    required List<Pokemon> catalog,
  }) {
    final byId = {for (final pokemon in catalog) pokemon.id: pokemon};
    final members = <EncounterMember>[];
    for (final savedMember in saved.members) {
      final basePokemon = byId[savedMember.pokemonId];
      if (basePokemon == null) {
        throw StateError(
          'Il Pokémon #${savedMember.pokemonId} non è più disponibile nel catalogo.',
        );
      }
      final resolvedPokemon = basePokemon.resolveVariant(
        formName: savedMember.formName,
        gender: savedMember.gender,
      );
      members.add(
        EncounterMember(
          pokemon: GeneratedPokemon(
            basePokemon: basePokemon,
            pokemon: resolvedPokemon,
            formName: savedMember.formName,
            level: savedMember.level,
            gender: savedMember.gender,
            nature: savedMember.nature,
            ability: savedMember.ability,
            selectedMoves: savedMember.selectedMoves,
            isShiny: savedMember.isShiny,
            maxHp: savedMember.maxHp,
          ),
          isLocked: savedMember.isLocked,
        ),
      );
    }

    final estimate = encounterService.estimate(
      party: saved.party,
      generated: members.map((member) => member.pokemon),
      targetDifficulty: saved.targetDifficulty,
    );
    return GeneratedEncounter(
      id: saved.id,
      source: saved.source,
      title: saved.name,
      party: saved.party,
      filters: saved.filters,
      targetDifficulty: saved.targetDifficulty,
      members: members,
      estimate: estimate,
      createdAt: saved.createdAt,
      collectionId: saved.collectionId,
      collectionName: saved.collectionName,
    );
  }
}
''',
)

write(
    'lib/screens/tools/encounter_library_screen.dart',
    r'''import 'package:flutter/material.dart';

import '../../models/generated_encounter.dart';
import '../../models/pokemon.dart';
import '../../models/pokemon_form_choice.dart';
import '../../models/saved_encounter.dart';
import '../../models/user_profile.dart';
import '../../repositories/pokemon_repository.dart';
import '../../repositories/profile_repository.dart';
import '../../repositories/saved_encounter_repository.dart';
import '../../services/saved_encounter_mapper_service.dart';
import '../../widgets/navigation/home_leading_button.dart';
import 'encounter_result_screen.dart';

class EncounterLibraryScreen extends StatefulWidget {
  const EncounterLibraryScreen({super.key});

  @override
  State<EncounterLibraryScreen> createState() => _EncounterLibraryScreenState();
}

class _EncounterLibraryScreenState extends State<EncounterLibraryScreen> {
  final ProfileRepository _profileRepository = ProfileRepository();
  final PokemonRepository _pokemonRepository = PokemonRepository();
  final SavedEncounterRepository _repository = SavedEncounterRepository();
  final SavedEncounterMapperService _mapper =
      const SavedEncounterMapperService();

  UserProfile? _profile;
  List<Pokemon> _catalog = const [];
  List<SavedEncounter> _encounters = const [];
  bool _isLoading = true;
  bool _isBusy = false;
  String? _message;
  bool _messageIsError = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _message = null;
    });
    try {
      final profile = await _profileRepository.getActiveProfile();
      final catalog = await _pokemonRepository.getAllPokemon();
      final encounters = await _repository.getEncounters(profile.id);
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _catalog = catalog;
        _encounters = encounters;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _message = _friendlyError(error);
        _messageIsError = true;
        _isLoading = false;
      });
    }
  }

  void _setMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    setState(() {
      _message = message;
      _messageIsError = isError;
    });
  }

  Future<void> _openEncounter(SavedEncounter saved) async {
    final profile = _profile;
    if (profile == null || _isBusy) return;
    setState(() => _isBusy = true);
    try {
      final encounter = _mapper.toGenerated(saved: saved, catalog: _catalog);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => EncounterResultScreen(
            encounter: encounter,
            catalog: _catalog,
            profileId: profile.id,
            savedEncounter: saved,
          ),
        ),
      );
      await _load();
    } catch (error) {
      _setMessage(_friendlyError(error), isError: true);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _duplicateEncounter(SavedEncounter saved) async {
    final profile = _profile;
    if (profile == null || _isBusy) return;
    setState(() => _isBusy = true);
    try {
      final now = DateTime.now();
      final copy = saved.copyWith(
        id: now.microsecondsSinceEpoch.toString(),
        name: _copyName(saved.name),
        createdAt: now,
        updatedAt: now,
      );
      await _repository.saveEncounter(profileId: profile.id, encounter: copy);
      await _load();
      _setMessage('${copy.name} duplicato.');
    } catch (error) {
      _setMessage(_friendlyError(error), isError: true);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _deleteEncounter(SavedEncounter saved) async {
    final profile = _profile;
    if (profile == null || _isBusy) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminare l’incontro?'),
        content: Text('“${saved.name}” verrà rimosso dalla libreria.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isBusy = true);
    try {
      await _repository.deleteEncounter(
        profileId: profile.id,
        encounterId: saved.id,
      );
      await _load();
      _setMessage('${saved.name} eliminato.');
    } catch (error) {
      _setMessage(_friendlyError(error), isError: true);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  String _copyName(String original) {
    final names = _encounters.map((encounter) => encounter.name).toSet();
    var candidate = '$original (copia)';
    var index = 2;
    while (names.contains(candidate)) {
      candidate = '$original (copia $index)';
      index++;
    }
    return candidate;
  }

  Pokemon? _pokemonById(int id) {
    for (final pokemon in _catalog) {
      if (pokemon.id == id) return pokemon;
    }
    return null;
  }

  String _friendlyError(Object error) {
    return error
        .toString()
        .replaceFirst('Bad state: ', '')
        .replaceFirst('FormatException: ', '')
        .trim();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const HomeLeadingButton(),
        title: const Text('Libreria incontri'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            _LibraryIntroCard(count: _encounters.length),
            if (_isBusy) ...[
              const SizedBox(height: 8),
              const LinearProgressIndicator(),
            ],
            if (_message != null) ...[
              const SizedBox(height: 10),
              _LibraryMessage(
                message: _message!,
                isError: _messageIsError,
              ),
            ],
            const SizedBox(height: 14),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 100),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_encounters.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(Icons.bookmarks_outlined, size: 48),
                      SizedBox(height: 12),
                      Text(
                        'Nessun incontro salvato',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Genera un incontro e premi Salva nella schermata del risultato.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              for (final saved in _encounters) ...[
                _SavedEncounterCard(
                  saved: saved,
                  pokemonById: _pokemonById,
                  isBusy: _isBusy,
                  onOpen: () => _openEncounter(saved),
                  onDuplicate: () => _duplicateEncounter(saved),
                  onDelete: () => _deleteEncounter(saved),
                ),
                const SizedBox(height: 10),
              ],
          ],
        ),
      ),
    );
  }
}

class _LibraryIntroCard extends StatelessWidget {
  const _LibraryIntroCard({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      color: colors.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.bookmarks_outlined,
              size: 38,
              color: colors.onPrimaryContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Incontri preparati',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: colors.onPrimaryContainer,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$count incontri salvati nel profilo attivo. Aprili, modificali, rigenerali e salvali di nuovo.',
                    style: TextStyle(color: colors.onPrimaryContainer),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SavedEncounterCard extends StatelessWidget {
  const _SavedEncounterCard({
    required this.saved,
    required this.pokemonById,
    required this.isBusy,
    required this.onOpen,
    required this.onDuplicate,
    required this.onDelete,
  });

  final SavedEncounter saved;
  final Pokemon? Function(int) pokemonById;
  final bool isBusy;
  final VoidCallback onOpen;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final composition = <String, int>{};
    for (final member in saved.members) {
      final pokemon = pokemonById(member.pokemonId);
      final label = pokemon == null
          ? '#${member.pokemonId}'
          : pokemonFormDisplayName(pokemon.name, member.formName);
      composition[label] = (composition[label] ?? 0) + 1;
    }
    final labels = composition.entries
        .map((entry) => entry.value == 1 ? entry.key : '${entry.value}× ${entry.key}')
        .toList(growable: false);
    final summary = labels.take(4).join(' · ');
    final remaining = labels.length - 4;

    return Card(
      child: InkWell(
        onTap: isBusy ? null : onOpen,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      saved.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    enabled: !isBusy,
                    onSelected: (value) {
                      switch (value) {
                        case 'duplicate':
                          onDuplicate();
                          break;
                        case 'delete':
                          onDelete();
                          break;
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'duplicate',
                        child: Text('Duplica'),
                      ),
                      PopupMenuItem(value: 'delete', child: Text('Elimina')),
                    ],
                  ),
                ],
              ),
              if (saved.notes.isNotEmpty) ...[
                Text(saved.notes),
                const SizedBox(height: 7),
              ],
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: [
                  Chip(label: Text('${saved.enemyCount} avversari')),
                  Chip(
                    label: Text(
                      'Lv medio ${_formatLevel(saved.averageEnemyLevel)}',
                    ),
                  ),
                  Chip(label: Text(saved.targetDifficulty.label)),
                  Chip(label: Text(_sourceLabel(saved.source))),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                remaining > 0 ? '$summary · +$remaining specie' : summary,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    'Aggiornato ${_formatDate(saved.updatedAt)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const Spacer(),
                  FilledButton.tonalIcon(
                    onPressed: isBusy ? null : onOpen,
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('APRI'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatLevel(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toStringAsFixed(1);
  }

  String _formatDate(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day/$month/${value.year}';
  }

  String _sourceLabel(EncounterSource source) => switch (source) {
    EncounterSource.automatic => 'Automatico',
    EncounterSource.manual => 'Manuale',
    EncounterSource.collection => 'Raccolta',
  };
}

class _LibraryMessage extends StatelessWidget {
  const _LibraryMessage({required this.message, required this.isError});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      color: isError ? colors.errorContainer : colors.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          message,
          style: TextStyle(
            color: isError
                ? colors.onErrorContainer
                : colors.onSecondaryContainer,
          ),
        ),
      ),
    );
  }
}
''',
)

# Hive box.
path = 'lib/database/hive_boxes.dart'
source = read(path)
source = replace_once(
    source,
    "  static const encounterCollections = 'encounter_collections';\n",
    "  static const encounterCollections = 'encounter_collections';\n  static const savedEncounters = 'saved_encounters';\n",
    'saved encounters hive box',
)
write(path, source)

# Tools entry.
path = 'lib/screens/tools/tools_screen.dart'
source = read(path)
source = replace_once(
    source,
    "import 'encounter_generator_screen.dart';\n",
    "import 'encounter_generator_screen.dart';\nimport 'encounter_library_screen.dart';\n",
    'tools library import',
)
source = replace_once(
    source,
    r'''          const SizedBox(height: 10),
          const _ToolCard(
            icon: Icons.groups_2_outlined,
''',
    r'''          const SizedBox(height: 10),
          _ToolCard(
            icon: Icons.bookmarks_outlined,
            title: 'Libreria incontri',
            subtitle:
                'Salva, riapri, duplica e modifica gli incontri preparati per le sessioni.',
            actionLabel: 'APRI',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const EncounterLibraryScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          const _ToolCard(
            icon: Icons.groups_2_outlined,
''',
    'tools library card',
)
write(path, source)

# Generated encounter screen passes the active profile to the result.
path = 'lib/screens/tools/encounter_generator_screen.dart'
source = read(path)
source = replace_once(
    source,
    r'''  Future<void> _openResult(GeneratedEncounter encounter) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            EncounterResultScreen(encounter: encounter, catalog: _catalog),
      ),
    );
  }
''',
    r'''  Future<void> _openResult(GeneratedEncounter encounter) async {
    final profileId = _profile?.id;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EncounterResultScreen(
          encounter: encounter,
          catalog: _catalog,
          profileId: profileId,
        ),
      ),
    );
  }
''',
    'pass profile to encounter result',
)
write(path, source)

# Result screen save/update support.
path = 'lib/screens/tools/encounter_result_screen.dart'
source = read(path)
source = replace_once(
    source,
    "import '../../models/pokemon_nature.dart';\n",
    "import '../../models/pokemon_nature.dart';\nimport '../../models/saved_encounter.dart';\n",
    'result saved model import',
)
source = replace_once(
    source,
    "import '../../repositories/move_repository.dart';\n",
    "import '../../repositories/move_repository.dart';\nimport '../../repositories/saved_encounter_repository.dart';\n",
    'result repository import',
)
source = replace_once(
    source,
    "import '../../services/pokemon_generator_service.dart';\n",
    "import '../../services/pokemon_generator_service.dart';\nimport '../../services/saved_encounter_mapper_service.dart';\n",
    'result mapper import',
)
source = replace_once(
    source,
    r'''  const EncounterResultScreen({
    super.key,
    required this.encounter,
    required this.catalog,
  });

  final GeneratedEncounter encounter;
  final List<Pokemon> catalog;
''',
    r'''  const EncounterResultScreen({
    super.key,
    required this.encounter,
    required this.catalog,
    this.profileId,
    this.savedEncounter,
  });

  final GeneratedEncounter encounter;
  final List<Pokemon> catalog;
  final String? profileId;
  final SavedEncounter? savedEncounter;
''',
    'result constructor save fields',
)
source = replace_once(
    source,
    r'''  final MoveRepository _moveRepository = MoveRepository();

  late GeneratedEncounter _encounter;
  Map<String, MoveData?> _moves = const {};
  bool _isWorking = false;
  String? _message;
''',
    r'''  final MoveRepository _moveRepository = MoveRepository();
  final SavedEncounterRepository _savedEncounterRepository =
      SavedEncounterRepository();
  final SavedEncounterMapperService _savedEncounterMapper =
      const SavedEncounterMapperService();

  late GeneratedEncounter _encounter;
  SavedEncounter? _savedEncounter;
  Map<String, MoveData?> _moves = const {};
  bool _isWorking = false;
  bool _isSaving = false;
  String? _message;
''',
    'result save state',
)
source = replace_once(
    source,
    r'''    _encounter = widget.encounter;
    _loadMoves();
''',
    r'''    _encounter = widget.encounter;
    _savedEncounter = widget.savedEncounter;
    _loadMoves();
''',
    'result initialize saved encounter',
)
source = replace_once(
    source,
    r'''  Future<void> _openDetails(GeneratedPokemon generated) async {
''',
    r'''  Future<void> _saveEncounter() async {
    final profileId = widget.profileId;
    if (profileId == null || _isSaving || _encounter.members.isEmpty) return;
    final details = await showDialog<_EncounterSaveDetails>(
      context: context,
      builder: (_) => _EncounterSaveDialog(
        initialName: _savedEncounter?.name ?? _encounter.title,
        initialNotes: _savedEncounter?.notes ?? '',
        isUpdate: _savedEncounter != null,
      ),
    );
    if (details == null) return;

    setState(() {
      _isSaving = true;
      _message = null;
    });
    try {
      final saved = _savedEncounterMapper.fromGenerated(
        _encounter,
        name: details.name,
        notes: details.notes,
        existing: _savedEncounter,
      );
      await _savedEncounterRepository.saveEncounter(
        profileId: profileId,
        encounter: saved,
      );
      if (!mounted) return;
      setState(() {
        final wasUpdate = _savedEncounter != null;
        _savedEncounter = saved;
        _encounter = _encounter.copyWith(title: saved.name);
        _message = wasUpdate
            ? 'Incontro aggiornato nella libreria.'
            : 'Incontro salvato nella libreria.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _message = error
            .toString()
            .replaceFirst('FormatException: ', '')
            .replaceFirst('Bad state: ', '');
      });
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _openDetails(GeneratedPokemon generated) async {
''',
    'result save method',
)
source = replace_once(
    source,
    r'''        actions: [
          IconButton(
            onPressed: _encounter.members.isEmpty || _isWorking
''',
    r'''        actions: [
          if (widget.profileId != null)
            IconButton(
              onPressed:
                  _encounter.members.isEmpty || _isWorking || _isSaving
                  ? null
                  : _saveEncounter,
              tooltip: _savedEncounter == null
                  ? 'Salva nella libreria'
                  : 'Aggiorna incontro salvato',
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      _savedEncounter == null
                          ? Icons.bookmark_add_outlined
                          : Icons.bookmark_added,
                    ),
            ),
          IconButton(
            onPressed: _encounter.members.isEmpty || _isWorking
''',
    'result save appbar action',
)
source = replace_once(
    source,
    r'''          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: _encounter.members.isEmpty || _isWorking
''',
    r'''          const SizedBox(height: 14),
          if (widget.profileId != null) ...[
            OutlinedButton.icon(
              onPressed:
                  _encounter.members.isEmpty || _isWorking || _isSaving
                  ? null
                  : _saveEncounter,
              icon: Icon(
                _savedEncounter == null
                    ? Icons.bookmark_add_outlined
                    : Icons.bookmark_added,
              ),
              label: Text(
                _savedEncounter == null
                    ? 'SALVA NELLA LIBRERIA'
                    : 'AGGIORNA INCONTRO SALVATO',
              ),
            ),
            const SizedBox(height: 8),
          ],
          FilledButton.icon(
            onPressed: _encounter.members.isEmpty || _isWorking
''',
    'result bottom save button',
)
source = replace_once(
    source,
    r'''class _EncounterMemberCard extends StatelessWidget {
''',
    r'''class _EncounterSaveDetails {
  const _EncounterSaveDetails({required this.name, required this.notes});

  final String name;
  final String notes;
}

class _EncounterSaveDialog extends StatefulWidget {
  const _EncounterSaveDialog({
    required this.initialName,
    required this.initialNotes,
    required this.isUpdate,
  });

  final String initialName;
  final String initialNotes;
  final bool isUpdate;

  @override
  State<_EncounterSaveDialog> createState() => _EncounterSaveDialogState();
}

class _EncounterSaveDialogState extends State<_EncounterSaveDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _notesController = TextEditingController(text: widget.initialNotes);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    Navigator.of(context).pop(
      _EncounterSaveDetails(name: name, notes: _notesController.text.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isUpdate ? 'Aggiorna incontro' : 'Salva incontro'),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Nome incontro',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Note facoltative',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annulla'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(widget.isUpdate ? 'Aggiorna' : 'Salva'),
        ),
      ],
    );
  }
}

class _EncounterMemberCard extends StatelessWidget {
''',
    'result save dialog classes',
)
write(path, source)

# Backup model v3 includes saved encounters.
path = 'lib/models/profile_backup.dart'
source = read(path)
source = replace_once(
    source,
    "import 'profile_settings.dart';\n",
    "import 'profile_settings.dart';\nimport 'saved_encounter.dart';\n",
    'backup saved encounter import',
)
source = replace_once(
    source,
    '  static const int currentFormatVersion = 2;\n',
    '  static const int currentFormatVersion = 3;\n',
    'backup format v3',
)
source = replace_once(
    source,
    r'''    required this.battleSession,
    this.encounterCollections = const [],
  });
''',
    r'''    required this.battleSession,
    this.encounterCollections = const [],
    this.savedEncounters = const [],
  });
''',
    'backup constructor saved encounters',
)
source = replace_once(
    source,
    r'''  final BattleSession? battleSession;
  final List<EncounterCollection> encounterCollections;
''',
    r'''  final BattleSession? battleSession;
  final List<EncounterCollection> encounterCollections;
  final List<SavedEncounter> savedEncounters;
''',
    'backup saved field',
)
source = replace_once(
    source,
    r'''      'encounterCollections': encounterCollections
          .map((collection) => collection.toJson())
          .toList(growable: false),
''',
    r'''      'encounterCollections': encounterCollections
          .map((collection) => collection.toJson())
          .toList(growable: false),
      'savedEncounters': savedEncounters
          .map((encounter) => encounter.toJson())
          .toList(growable: false),
''',
    'backup serialize saved encounters',
)
source = replace_once(
    source,
    r'''      encounterCollections: [
        for (final value in _readMapList(
          json['encounterCollections'],
          'encounterCollections',
        ))
          EncounterCollection.fromJson(value),
      ],
''',
    r'''      encounterCollections: [
        for (final value in _readMapList(
          json['encounterCollections'],
          'encounterCollections',
        ))
          EncounterCollection.fromJson(value),
      ],
      savedEncounters: [
        for (final value in _readMapList(
          json['savedEncounters'],
          'savedEncounters',
        ))
          SavedEncounter.fromJson(value),
      ],
''',
    'backup deserialize saved encounters',
)
source = replace_once(
    source,
    r'''    for (final collection in encounterCollections) {
      if (collection.id.trim().isEmpty || collection.name.trim().isEmpty) {
        throw const FormatException(
          'Il backup contiene una raccolta incontri non valida.',
        );
      }
      if (!collectionIds.add(collection.id)) {
        throw FormatException(
          'La raccolta ${collection.name} è presente più volte.',
        );
      }
      if (!collection.isReady) {
        throw FormatException(
          'La raccolta ${collection.name} non totalizza il 100%.',
        );
      }
    }
''',
    r'''    for (final collection in encounterCollections) {
      if (collection.id.trim().isEmpty || collection.name.trim().isEmpty) {
        throw const FormatException(
          'Il backup contiene una raccolta incontri non valida.',
        );
      }
      if (!collectionIds.add(collection.id)) {
        throw FormatException(
          'La raccolta ${collection.name} è presente più volte.',
        );
      }
      if (!collection.isReady) {
        throw FormatException(
          'La raccolta ${collection.name} non totalizza il 100%.',
        );
      }
    }

    final savedEncounterIds = <String>{};
    for (final encounter in savedEncounters) {
      if (!encounter.isValid) {
        throw const FormatException(
          'Il backup contiene un incontro salvato non valido.',
        );
      }
      if (!savedEncounterIds.add(encounter.id)) {
        throw FormatException(
          'L’incontro ${encounter.name} è presente più volte.',
        );
      }
    }
''',
    'backup validate saved encounters',
)
write(path, source)

# Backup service reads, writes, clears saved encounters.
path = 'lib/services/profile_backup_service.dart'
source = read(path)
source = replace_once(
    source,
    "import '../repositories/profile_repository.dart';\n",
    "import '../repositories/profile_repository.dart';\nimport '../repositories/saved_encounter_repository.dart';\n",
    'backup service repository import',
)
source = replace_once(
    source,
    r'''    BattleSessionRepository? battleSessionRepository,
    EncounterCollectionRepository? encounterCollectionRepository,
  }) : _profileRepository = profileRepository ?? ProfileRepository(),
''',
    r'''    BattleSessionRepository? battleSessionRepository,
    EncounterCollectionRepository? encounterCollectionRepository,
    SavedEncounterRepository? savedEncounterRepository,
  }) : _profileRepository = profileRepository ?? ProfileRepository(),
''',
    'backup service constructor arg',
)
source = replace_once(
    source,
    r'''       _encounterCollectionRepository =
            encounterCollectionRepository ?? EncounterCollectionRepository();
''',
    r'''       _encounterCollectionRepository =
            encounterCollectionRepository ?? EncounterCollectionRepository(),
       _savedEncounterRepository =
            savedEncounterRepository ?? SavedEncounterRepository();
''',
    'backup service initializer',
)
source = replace_once(
    source,
    r'''  final BattleSessionRepository _battleSessionRepository;
  final EncounterCollectionRepository _encounterCollectionRepository;
''',
    r'''  final BattleSessionRepository _battleSessionRepository;
  final EncounterCollectionRepository _encounterCollectionRepository;
  final SavedEncounterRepository _savedEncounterRepository;
''',
    'backup service field',
)
source = replace_once(
    source,
    r'''    final encounterCollections = await _encounterCollectionRepository
        .getCollections(profileId);
''',
    r'''    final encounterCollections = await _encounterCollectionRepository
        .getCollections(profileId);
    final savedEncounters = await _savedEncounterRepository.getEncounters(
      profileId,
    );
''',
    'backup service read saved encounters',
)
source = replace_once(
    source,
    r'''      battleSession: battleSession,
      encounterCollections: encounterCollections,
    );
''',
    r'''      battleSession: battleSession,
      encounterCollections: encounterCollections,
      savedEncounters: savedEncounters,
    );
''',
    'backup service include saved encounters',
)
source = replace_once(
    source,
    r'''    await _encounterCollectionRepository.replaceCollections(
      destinationId,
      backup.encounterCollections,
    );
''',
    r'''    await _encounterCollectionRepository.replaceCollections(
      destinationId,
      backup.encounterCollections,
    );
    await _savedEncounterRepository.replaceEncounters(
      destinationId,
      backup.savedEncounters,
    );
''',
    'backup service restore saved encounters',
)
source = replace_once(
    source,
    r'''    await _encounterCollectionRepository.deleteCollections(profileId);
''',
    r'''    await _encounterCollectionRepository.deleteCollections(profileId);
    await _savedEncounterRepository.deleteEncounters(profileId);
''',
    'backup service clear saved encounters',
)
write(path, source)

# Profile UI copy and import summary.
path = 'lib/screens/profile/profiles_screen.dart'
source = read(path)
source = replace_once(
    source,
    r'''          'Pokédex, squadra, PC, zaino, impostazioni e battaglia salvata.',
''',
    r'''          'Pokédex, squadra, PC, zaino, impostazioni, incontri e battaglia salvata.',
''',
    'profile delete copy',
)
source = replace_once(
    source,
    r'''                'PC, zaino, impostazioni e battaglie.',
''',
    r'''                'PC, zaino, impostazioni, raccolte e incontri salvati.',
''',
    'profile description copy',
)
source = replace_once(
    source,
    r'''                  _SummaryChip(
                    icon: Icons.flash_on_outlined,
                    label: backup.battleSession == null
                        ? 'Nessuna battaglia'
                        : 'Battaglia salvata',
                  ),
''',
    r'''                  _SummaryChip(
                    icon: Icons.bookmarks_outlined,
                    label: '${backup.savedEncounters.length} incontri',
                  ),
                  _SummaryChip(
                    icon: Icons.flash_on_outlined,
                    label: backup.battleSession == null
                        ? 'Nessuna battaglia'
                        : 'Battaglia salvata',
                  ),
''',
    'profile import saved encounter chip',
)
write(path, source)

# Mapper and model tests.
write(
    'test/saved_encounter_mapper_service_test.dart',
    r'''import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_5e_ita/models/generated_encounter.dart';
import 'package:pokedex_5e_ita/models/generated_pokemon.dart';
import 'package:pokedex_5e_ita/models/pokemon.dart';
import 'package:pokedex_5e_ita/models/pokemon_attributes.dart';
import 'package:pokedex_5e_ita/models/pokemon_moves.dart';
import 'package:pokedex_5e_ita/models/saved_encounter.dart';
import 'package:pokedex_5e_ita/services/encounter_generator_service.dart';
import 'package:pokedex_5e_ita/services/saved_encounter_mapper_service.dart';

void main() {
  const mapper = SavedEncounterMapperService();
  const encounterService = EncounterGeneratorService();
  final rattata = _pokemon();

  test('saved encounter JSON preserves every generated member field', () {
    final saved = SavedEncounter(
      id: 'route-24-night',
      name: 'Percorso 24 notte',
      notes: 'Incontro vicino al ponte.',
      source: EncounterSource.collection,
      party: const EncounterPartyProfile(
        trainerCount: 2,
        activePokemon: 2,
        averageLevel: 5,
      ),
      filters: const EncounterGeneratorFilters(
        habitat: 'Prateria',
        level: 4,
      ),
      targetDifficulty: EncounterDifficulty.hard,
      members: const [
        SavedEncounterMember(
          pokemonId: 19,
          formName: 'Alolan',
          level: 4,
          gender: 'Female',
          nature: 'Jolly',
          ability: 'Gluttony',
          selectedMoves: ['Tackle', 'Quick Attack'],
          isShiny: true,
          maxHp: 22,
          isLocked: true,
        ),
      ],
      createdAt: DateTime.utc(2026, 7, 13, 10),
      updatedAt: DateTime.utc(2026, 7, 13, 11),
      collectionId: 'route-24',
      collectionName: 'Percorso 24',
    );

    final decoded = SavedEncounter.fromJson(saved.toJson());

    expect(decoded.name, saved.name);
    expect(decoded.notes, saved.notes);
    expect(decoded.source, EncounterSource.collection);
    expect(decoded.targetDifficulty, EncounterDifficulty.hard);
    expect(decoded.members.single.formName, 'Alolan');
    expect(decoded.members.single.selectedMoves, ['Tackle', 'Quick Attack']);
    expect(decoded.members.single.isLocked, isTrue);
    expect(decoded.collectionName, 'Percorso 24');
  });

  test('mapper restores an exact form and recalculates the estimate', () {
    final alolan = rattata.copyWith(types: const ['Dark', 'Normal'], sr: 1);
    final catalog = [
      rattata.copyWith(
        formDefinitions: [
          PokemonFormDefinition(
            key: 'Alolan',
            displayName: 'Alolan',
            pokemon: alolan,
          ),
        ],
      ),
    ];
    final generated = GeneratedPokemon(
      basePokemon: catalog.single,
      pokemon: alolan,
      formName: 'Alolan',
      level: 4,
      gender: 'Female',
      nature: 'Jolly',
      ability: 'Gluttony',
      selectedMoves: const ['Tackle'],
      isShiny: false,
      maxHp: 20,
    );
    final encounter = encounterService.buildEncounter(
      source: EncounterSource.manual,
      title: 'Incontro personalizzato',
      party: const EncounterPartyProfile(averageLevel: 4),
      filters: const EncounterGeneratorFilters(level: 4),
      targetDifficulty: EncounterDifficulty.medium,
      generated: [generated],
    );

    final saved = mapper.fromGenerated(
      encounter,
      name: 'Rattata di Alola',
      notes: 'Forma bloccata',
      now: DateTime.utc(2026, 7, 13),
    );
    final restored = mapper.toGenerated(saved: saved, catalog: catalog);

    expect(restored.title, 'Rattata di Alola');
    expect(restored.members.single.pokemon.formName, 'Alolan');
    expect(restored.members.single.pokemon.pokemon.types, contains('Dark'));
    expect(restored.estimate.encounterCost, greaterThan(0));
  });
}

Pokemon _pokemon() {
  return const Pokemon(
    id: 19,
    name: 'Rattata',
    types: ['Normal'],
    armorClass: 12,
    hitPoints: 12,
    size: 'Small',
    speed: 9,
    attributes: PokemonAttributes(
      strength: 7,
      dexterity: 15,
      constitution: 10,
      intelligence: 6,
      wisdom: 9,
      charisma: 8,
    ),
    abilities: ['Run Away'],
    hiddenAbility: 'Hustle',
    skills: [],
    savingThrows: [],
    moves: PokemonMoves(
      startingMoves: ['Tackle'],
      levelMoves: {},
      tmMoves: [],
    ),
    hitDice: 6,
    sr: 0.5,
    minLevelFound: 1,
    description: 'A small mouse Pokémon.',
  );
}
''',
)

# Backup integration test stores and restores the library.
path = 'test/profile_backup_service_test.dart'
source = read(path)
source = replace_once(
    source,
    "import 'package:pokedex_5e_ita/models/profile_settings.dart';\n",
    "import 'package:pokedex_5e_ita/models/profile_settings.dart';\nimport 'package:pokedex_5e_ita/models/generated_encounter.dart';\nimport 'package:pokedex_5e_ita/models/saved_encounter.dart';\n",
    'backup service test saved model imports',
)
source = replace_once(
    source,
    "import 'package:pokedex_5e_ita/repositories/profile_repository.dart';\n",
    "import 'package:pokedex_5e_ita/repositories/profile_repository.dart';\nimport 'package:pokedex_5e_ita/repositories/saved_encounter_repository.dart';\n",
    'backup service test saved repo import',
)
source = replace_once(
    source,
    r'''  final battleRepository = BattleSessionRepository();
  final backupService = ProfileBackupService();
''',
    r'''  final battleRepository = BattleSessionRepository();
  final savedEncounterRepository = SavedEncounterRepository();
  final backupService = ProfileBackupService();
''',
    'backup service test repo instance',
)
source = replace_once(
    source,
    r'''      await battleRepository.saveSession(
        BattleSession(
''',
    r'''      await savedEncounterRepository.saveEncounter(
        profileId: source.id,
        encounter: SavedEncounter(
          id: 'saved-route-24',
          name: 'Percorso 24',
          source: EncounterSource.manual,
          party: const EncounterPartyProfile(averageLevel: 5),
          filters: const EncounterGeneratorFilters(level: 4),
          targetDifficulty: EncounterDifficulty.medium,
          members: const [
            SavedEncounterMember(
              pokemonId: 19,
              level: 4,
              nature: 'Jolly',
              selectedMoves: ['Tackle'],
              isShiny: false,
              maxHp: 18,
            ),
          ],
          createdAt: DateTime.utc(2026, 7, 11),
          updatedAt: DateTime.utc(2026, 7, 11),
        ),
      );
      await battleRepository.saveSession(
        BattleSession(
''',
    'backup service test save encounter',
)
source = replace_once(
    source,
    r'''      final importedBattle = await battleRepository.getSession(imported.id);
''',
    r'''      final importedEncounters = await savedEncounterRepository.getEncounters(
        imported.id,
      );
      expect(importedEncounters.single.name, 'Percorso 24');
      expect(importedEncounters.single.members.single.pokemonId, 19);
      final importedBattle = await battleRepository.getSession(imported.id);
''',
    'backup service test restored encounter assertion',
)
source = replace_once(
    source,
    r'''      expect(await battleRepository.getSession(imported.id), isNull);
''',
    r'''      expect(await battleRepository.getSession(imported.id), isNull);
      expect(
        await savedEncounterRepository.getEncounters(imported.id),
        isEmpty,
      );
''',
    'backup service test deleted encounter assertion',
)
write(path, source)

# Backup JSON test includes a saved encounter.
path = 'test/profile_backup_test.dart'
source = read(path)
source = replace_once(
    source,
    "import 'package:pokedex_5e_ita/models/pc_pokemon.dart';\n",
    "import 'package:pokedex_5e_ita/models/pc_pokemon.dart';\nimport 'package:pokedex_5e_ita/models/generated_encounter.dart';\n",
    'backup test encounter model import',
)
source = replace_once(
    source,
    "import 'package:pokedex_5e_ita/models/profile_settings.dart';\n",
    "import 'package:pokedex_5e_ita/models/profile_settings.dart';\nimport 'package:pokedex_5e_ita/models/saved_encounter.dart';\n",
    'backup test saved model import',
)
source = replace_once(
    source,
    r'''      battleSession: battleSession,
    );
''',
    r'''      battleSession: battleSession,
      savedEncounters: [
        SavedEncounter(
          id: 'route-24',
          name: 'Percorso 24',
          source: EncounterSource.collection,
          party: const EncounterPartyProfile(averageLevel: 5),
          filters: const EncounterGeneratorFilters(level: 4),
          targetDifficulty: EncounterDifficulty.medium,
          members: const [
            SavedEncounterMember(
              pokemonId: 19,
              formName: 'Alolan',
              level: 4,
              nature: 'Jolly',
              selectedMoves: ['Tackle'],
              isShiny: false,
              maxHp: 18,
            ),
          ],
          createdAt: now,
          updatedAt: now,
        ),
      ],
    );
''',
    'backup test saved encounter fixture',
)
source = replace_once(
    source,
    r'''    expect(decoded.battleSession?.round, 4);
''',
    r'''    expect(decoded.battleSession?.round, 4);
    expect(decoded.savedEncounters.single.name, 'Percorso 24');
    expect(decoded.savedEncounters.single.members.single.formName, 'Alolan');
''',
    'backup test saved encounter assertions',
)
write(path, source)
