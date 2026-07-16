import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../models/pokemon.dart';
import '../../models/pokemon_transfer_bundle.dart';
import '../../models/team_slot.dart';
import '../../models/trainer_progression.dart';
import '../../models/user_profile.dart';
import '../../repositories/pokemon_repository.dart';
import '../../repositories/profile_repository.dart';
import '../../repositories/team_repository.dart';
import '../../services/native_share_service.dart';
import '../../services/pokemon_transfer_service.dart';
import '../../widgets/layout/responsive_content.dart';
import '../../widgets/pokemon/egg_asset_image.dart';
import '../../widgets/pokemon/pokemon_asset_image.dart';
import '../pokemon/pokemon_detail_screen.dart';
import '../breeding/breeding_screen.dart';

class TeamSelectionScreen extends StatefulWidget {
  const TeamSelectionScreen({super.key, required this.nickname});

  final String nickname;

  @override
  State<TeamSelectionScreen> createState() => _TeamSelectionScreenState();
}

class _TeamSelectionScreenState extends State<TeamSelectionScreen> {
  final ProfileRepository _profileRepository = ProfileRepository();
  final PokemonRepository _pokemonRepository = PokemonRepository();
  final TeamRepository _teamRepository = TeamRepository();
  final PokemonTransferService _transferService = PokemonTransferService();
  final NativeShareService _shareService = const NativeShareService();

  UserProfile? _profile;
  List<Pokemon> _allPokemon = [];
  List<TeamSlot> _team = [];

  bool _isLoading = true;
  bool _isBusy = false;
  String? _errorMessage;
  String? _statusMessage;
  bool _statusIsError = false;

  @override
  void initState() {
    super.initState();
    _loadTeam();
  }

  Future<void> _loadTeam() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final profile = await _profileRepository.getActiveProfile();
      final pokemon = await _pokemonRepository.getAllPokemon();
      final team = await _teamRepository.getTeam(profile.id);

      if (!mounted) return;

      setState(() {
        _profile = profile;
        _allPokemon = pokemon;
        _team = team..sort((a, b) => a.slotIndex.compareTo(b.slotIndex));
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Pokemon? _pokemonById(int? pokemonId) {
    if (pokemonId == null) return null;

    for (final pokemon in _allPokemon) {
      if (pokemon.id == pokemonId) return pokemon;
    }

    return null;
  }

  Pokemon? _pokemonFromTransfer(PokemonTransferBundle bundle, int? pokemonId) {
    final catalogPokemon = _pokemonById(pokemonId);
    if (catalogPokemon != null || pokemonId == null) {
      return catalogPokemon;
    }
    for (final definition in bundle.customPokemon) {
      if (definition.pokemonId == pokemonId) {
        return definition.toPokemon();
      }
    }
    return null;
  }

  int get _unlockedPokeslots {
    final level = _profile?.trainerLevel ?? TrainerProgression.minLevel;

    return TrainerProgression.pokeslotsForLevel(level);
  }

  List<TeamSlot> get _visibleTeam {
    return [
      for (final slot in _team)
        if (slot.slotIndex < _unlockedPokeslots) slot,
    ]..sort((a, b) => a.slotIndex.compareTo(b.slotIndex));
  }

  Future<void> _setPokemonInSlot(int slotIndex, int? pokemonId) async {
    final profile = _profile;
    if (profile == null) return;
    if (slotIndex >= _unlockedPokeslots) return;

    await _teamRepository.setPokemonInSlot(
      profileId: profile.id,
      slotIndex: slotIndex,
      pokemonId: pokemonId,
      initialCurrentHp: _pokemonById(pokemonId)?.hitPoints,
    );

    await _loadTeam();
  }

  Future<void> _updateSlot(TeamSlot slot) async {
    final profile = _profile;
    if (profile == null) return;

    await _teamRepository.updateSlot(profileId: profile.id, updatedSlot: slot);

    await _loadTeam();
  }

  Future<void> _openPokemonDetail(TeamSlot slot) async {
    if (slot.isEgg) {
      await Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const BreedingScreen()));
      await _loadTeam();
      return;
    }
    final pokemon = _pokemonById(slot.pokemonId);
    if (pokemon == null) {
      await _openPokemonPicker(slot);
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PokemonDetailScreen(
          pokemon: pokemon,
          teamSlot: slot,
          allPokemon: _allPokemon,
          team: _visibleTeam,
          onTeamSlotChanged: (updatedSlot) {
            _updateSlot(updatedSlot);
          },
        ),
      ),
    );

    await _loadTeam();
  }

  Future<void> _openPokemonPicker(TeamSlot slot) async {
    if (slot.isEgg) return;
    final selectedPokemonId = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _PokemonPickerSheet(pokemon: _allPokemon),
    );

    if (selectedPokemonId == null) return;

    await _setPokemonInSlot(slot.slotIndex, selectedPokemonId);
  }

  void _setStatus(String message, {bool isError = false}) {
    if (!mounted) return;
    setState(() {
      _statusMessage = message;
      _statusIsError = isError;
    });
  }

  String _friendlyError(Object error) {
    return error
        .toString()
        .replaceFirst('FormatException: ', '')
        .replaceFirst('Bad state: ', '')
        .trim();
  }

  String _displayNameForSlot(TeamSlot slot) {
    final nickname = slot.nickname?.trim() ?? '';
    if (nickname.isNotEmpty) return nickname;
    return _pokemonById(slot.pokemonId)?.name ?? 'Pokémon';
  }

  Future<PokemonTransferBundle?> _pickTransferFile() async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Seleziona un trasferimento Pokédex 5e',
      type: FileType.custom,
      allowedExtensions: const ['json'],
      allowMultiple: false,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;
    final picked = result.files.single;
    final bytes = picked.bytes ?? await picked.xFile.readAsBytes();
    return _transferService.decode(utf8.decode(bytes, allowMalformed: false));
  }

  Future<void> _exportPokemon(TeamSlot slot) async {
    final profile = _profile;
    if (_isBusy || profile == null || !slot.isPokemon) return;
    setState(() => _isBusy = true);
    try {
      final bundle = PokemonTransferBundle.single(
        slot: slot,
        sourceTrainerName: profile.name,
      );
      final json = await _transferService.encodePortable(bundle);
      final displayName = _displayNameForSlot(slot);
      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Esporta $displayName',
        fileName: _transferService.fileNameForPokemon(
          bundle,
          displayName: displayName,
        ),
        type: FileType.custom,
        allowedExtensions: const ['json'],
        bytes: Uint8List.fromList(utf8.encode(json)),
      );
      _setStatus(
        path == null
            ? 'Esportazione annullata.'
            : '$displayName esportato correttamente.',
      );
    } catch (error) {
      _setStatus(_friendlyError(error), isError: true);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _exportTeam() async {
    final profile = _profile;
    if (_isBusy || profile == null) return;
    final pokemonSlots = _visibleTeam.where((slot) => slot.isPokemon).toList();
    if (pokemonSlots.isEmpty) {
      _setStatus(
        'La squadra non contiene Pokémon da esportare.',
        isError: true,
      );
      return;
    }

    setState(() => _isBusy = true);
    try {
      final bundle = PokemonTransferBundle.team(
        slots: pokemonSlots,
        sourceTrainerName: profile.name,
      );
      final json = await _transferService.encodePortable(bundle);
      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Esporta la squadra di ${profile.name}',
        fileName: _transferService.fileNameForTeam(bundle),
        type: FileType.custom,
        allowedExtensions: const ['json'],
        bytes: Uint8List.fromList(utf8.encode(json)),
      );
      _setStatus(
        path == null
            ? 'Esportazione annullata.'
            : 'Squadra esportata correttamente (${pokemonSlots.length} Pokémon).',
      );
    } catch (error) {
      _setStatus(_friendlyError(error), isError: true);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _sharePokemon(TeamSlot slot) async {
    final profile = _profile;
    if (_isBusy || profile == null || !slot.isPokemon) return;
    setState(() => _isBusy = true);
    try {
      final bundle = PokemonTransferBundle.single(
        slot: slot,
        sourceTrainerName: profile.name,
      );
      final json = await _transferService.encodePortable(bundle);
      final displayName = _displayNameForSlot(slot);
      final outcome = await _shareService.shareTextFile(
        context: context,
        content: json,
        fileName: _transferService.fileNameForPokemon(
          bundle,
          displayName: displayName,
        ),
        mimeType: 'application/json',
        title: 'Condividi $displayName',
        subject: '$displayName · Pokédex 5e ITA',
        text: 'Pokémon esportato da Pokédex 5e ITA.',
      );
      _setStatus(
        _shareService.feedback(
          outcome,
          successMessage: '$displayName condiviso correttamente.',
        ),
      );
    } catch (error) {
      _setStatus(_friendlyError(error), isError: true);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _shareTeam() async {
    final profile = _profile;
    if (_isBusy || profile == null) return;
    final pokemonSlots = _visibleTeam.where((slot) => slot.isPokemon).toList();
    if (pokemonSlots.isEmpty) {
      _setStatus(
        'La squadra non contiene Pokémon da condividere.',
        isError: true,
      );
      return;
    }

    setState(() => _isBusy = true);
    try {
      final bundle = PokemonTransferBundle.team(
        slots: pokemonSlots,
        sourceTrainerName: profile.name,
      );
      final json = await _transferService.encodePortable(bundle);
      final outcome = await _shareService.shareTextFile(
        context: context,
        content: json,
        fileName: _transferService.fileNameForTeam(bundle),
        mimeType: 'application/json',
        title: 'Condividi la squadra di ${profile.name}',
        subject: 'Squadra di ${profile.name} · Pokédex 5e ITA',
        text: 'Squadra esportata da Pokédex 5e ITA.',
      );
      _setStatus(
        _shareService.feedback(
          outcome,
          successMessage:
              'Squadra condivisa correttamente (${pokemonSlots.length} Pokémon).',
        ),
      );
    } catch (error) {
      _setStatus(_friendlyError(error), isError: true);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _importPokemonInto(TeamSlot target) async {
    final profile = _profile;
    if (_isBusy || profile == null || target.isEgg) return;
    setState(() => _isBusy = true);
    try {
      final bundle = await _pickTransferFile();
      if (bundle == null) {
        _setStatus('Importazione annullata.');
        return;
      }
      if (bundle.kind != PokemonTransferKind.pokemon) {
        throw const FormatException(
          'Seleziona un file esportato come singolo Pokémon.',
        );
      }
      final importedSlot = bundle.pokemon.single;
      final importedPokemon = _pokemonFromTransfer(
        bundle,
        importedSlot.pokemonId,
      );
      if (importedPokemon == null) {
        throw FormatException(
          'Il Pokémon #${importedSlot.pokemonId} non è presente nel catalogo.',
        );
      }
      if (!mounted) return;
      final importedName = importedSlot.nickname?.trim().isNotEmpty == true
          ? importedSlot.nickname!.trim()
          : importedPokemon.name;
      final replacedName = target.isPokemon
          ? _displayNameForSlot(target)
          : null;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Importare Pokémon?'),
          content: Text(
            replacedName == null
                ? 'Vuoi inserire $importedName nello slot ${target.slotIndex + 1}?'
                : 'Vuoi inserire $importedName nello slot ${target.slotIndex + 1}? '
                      '$replacedName verrà spostato nel PC Pokémon.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('ANNULLA'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('IMPORTA'),
            ),
          ],
        ),
      );
      if (confirmed != true) {
        _setStatus('Importazione annullata.');
        return;
      }

      final result = await _transferService.importPokemon(
        profileId: profile.id,
        bundle: bundle,
        targetSlotIndex: target.slotIndex,
      );
      await _loadTeam();
      _setStatus(
        result.replacedPokemon > 0
            ? '$importedName importato. Il Pokémon sostituito è stato spostato nel PC.'
            : '$importedName importato nello slot ${target.slotIndex + 1}.',
      );
    } catch (error) {
      _setStatus(_friendlyError(error), isError: true);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _importTeam() async {
    final profile = _profile;
    if (_isBusy || profile == null) return;
    setState(() => _isBusy = true);
    try {
      final bundle = await _pickTransferFile();
      if (bundle == null) {
        _setStatus('Importazione annullata.');
        return;
      }
      if (bundle.kind != PokemonTransferKind.team) {
        throw const FormatException(
          'Seleziona un file esportato come squadra.',
        );
      }
      final unknownIds = <int>{
        for (final slot in bundle.pokemon)
          if (_pokemonFromTransfer(bundle, slot.pokemonId) == null)
            slot.pokemonId!,
      };
      if (unknownIds.isNotEmpty) {
        throw FormatException(
          'Il catalogo non contiene i Pokémon: ${unknownIds.join(', ')}.',
        );
      }

      final availableSlots = _visibleTeam.where((slot) => !slot.isEgg).length;
      if (availableSlots == 0) {
        throw StateError(
          'Non ci sono Pokéslot disponibili: gli slot sbloccati contengono uova.',
        );
      }
      final replaced = _visibleTeam.where((slot) => slot.isPokemon).length;
      final overflow = bundle.pokemon.length > availableSlots
          ? bundle.pokemon.length - availableSlots
          : 0;
      if (!mounted) return;
      final source = bundle.sourceTrainerName.isEmpty
          ? ''
          : ' di ${bundle.sourceTrainerName}';
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Importare squadra?'),
          content: Text(
            'Stai importando ${bundle.pokemon.length} Pokémon$source. '
            '${replaced > 0 ? 'I $replaced Pokémon attualmente in squadra verranno spostati nel PC. ' : ''}'
            'Le uova resteranno nei loro slot. '
            '${overflow > 0 ? '$overflow Pokémon importati finiranno nel PC perché non ci sono abbastanza Pokéslot disponibili.' : ''}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('ANNULLA'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('IMPORTA SQUADRA'),
            ),
          ],
        ),
      );
      if (confirmed != true) {
        _setStatus('Importazione annullata.');
        return;
      }

      final result = await _transferService.importTeam(
        profileId: profile.id,
        bundle: bundle,
        unlockedPokeslots: _unlockedPokeslots,
      );
      await _loadTeam();
      final pcDetail = result.movedToPc == 0
          ? ''
          : ' ${result.movedToPc} Pokémon sono stati salvati nel PC.';
      _setStatus(
        'Squadra importata: ${result.importedToTeam} Pokémon nei Pokéslot.$pcDetail',
      );
    } catch (error) {
      _setStatus(_friendlyError(error), isError: true);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Widget _buildTeamSlots(List<TeamSlot> visibleTeam) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 12.0;
        final usesTwoColumns = constraints.maxWidth >= 840;
        final cardWidth = usesTwoColumns
            ? (constraints.maxWidth - spacing) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: spacing,
          runSpacing: 0,
          children: [
            for (final slot in visibleTeam)
              SizedBox(
                width: cardWidth,
                child: _TeamSlotCard(
                  slot: slot,
                  pokemon: _pokemonById(slot.pokemonId),
                  onOpen: () => _openPokemonDetail(slot),
                  onChange: () => _openPokemonPicker(slot),
                  onExport: slot.isPokemon ? () => _exportPokemon(slot) : null,
                  onShare: slot.isPokemon ? () => _sharePokemon(slot) : null,
                  onImport: slot.isEgg ? null : () => _importPokemonInto(slot),
                  onRemove: slot.isPokemon
                      ? () => _setPokemonInSlot(slot.slotIndex, null)
                      : null,
                ),
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileName = _profile?.name ?? widget.nickname;
    final visibleTeam = _visibleTeam;
    final filledSlots = visibleTeam.where((slot) => !slot.isEmpty).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Squadra'),
        actions: [
          IconButton(
            onPressed: _isBusy || _isLoading ? null : _shareTeam,
            tooltip: 'Condividi squadra',
            icon: const Icon(Icons.ios_share_outlined),
          ),
          PopupMenuButton<_TeamTransferAction>(
            enabled: !_isBusy && !_isLoading,
            tooltip: 'Esporta o importa squadra',
            onSelected: (action) {
              switch (action) {
                case _TeamTransferAction.exportTeam:
                  _exportTeam();
                  break;
                case _TeamTransferAction.shareTeam:
                  _shareTeam();
                  break;
                case _TeamTransferAction.importTeam:
                  _importTeam();
                  break;
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: _TeamTransferAction.exportTeam,
                child: ListTile(
                  leading: Icon(Icons.upload_file_outlined),
                  title: Text('Esporta squadra'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: _TeamTransferAction.shareTeam,
                child: ListTile(
                  leading: Icon(Icons.ios_share_outlined),
                  title: Text('Condividi squadra'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: _TeamTransferAction.importTeam,
                child: ListTile(
                  leading: Icon(Icons.download_outlined),
                  title: Text('Importa squadra'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: ResponsiveContent(
        maxWidth: 1180,
        child: RefreshIndicator(
          onRefresh: _loadTeam,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              if (_isBusy) const LinearProgressIndicator(),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 120),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_errorMessage != null)
                _TeamErrorState(message: _errorMessage!, onRetry: _loadTeam)
              else ...[
                _TeamHeader(
                  profileName: profileName,
                  filledSlots: filledSlots,
                  totalSlots: visibleTeam.length,
                ),
                if (_statusMessage != null) ...[
                  const SizedBox(height: 12),
                  _TeamStatusBanner(
                    message: _statusMessage!,
                    isError: _statusIsError,
                    onDismiss: () => setState(() => _statusMessage = null),
                  ),
                ],
                const SizedBox(height: 16),
                _buildTeamSlots(visibleTeam),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TeamHeader extends StatelessWidget {
  const _TeamHeader({
    required this.profileName,
    required this.filledSlots,
    required this.totalSlots,
  });

  final String profileName;
  final int filledSlots;
  final int totalSlots;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
            ),
            child: const Icon(
              Icons.catching_pokemon,
              color: Colors.white,
              size: 34,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Squadra di'.toUpperCase(),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Colors.white70,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  profileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$filledSlots/$totalSlots Pokéslot occupati',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamSlotCard extends StatelessWidget {
  const _TeamSlotCard({
    required this.slot,
    required this.pokemon,
    required this.onOpen,
    required this.onChange,
    required this.onExport,
    required this.onShare,
    required this.onImport,
    required this.onRemove,
  });

  final TeamSlot slot;
  final Pokemon? pokemon;
  final VoidCallback onOpen;
  final VoidCallback onChange;
  final VoidCallback? onExport;
  final VoidCallback? onShare;
  final VoidCallback? onImport;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final number = pokemon == null
        ? null
        : '#${pokemon!.id.toString().padLeft(3, '0')}';
    final nickname = slot.nickname?.trim() ?? '';
    final title = slot.isEgg
        ? 'Uovo in incubazione'
        : nickname.isEmpty
        ? pokemon?.name ?? 'Slot vuoto'
        : nickname;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _SlotAvatar(slot: slot, pokemon: pokemon),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                        ),
                        if (pokemon != null)
                          Text(
                            number!,
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (slot.isEgg)
                      Text(
                        'Occupa un Pokéslot · Tocca per gestirlo',
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      )
                    else if (pokemon == null)
                      Text(
                        'Tocca per scegliere un Pokémon',
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      )
                    else ...[
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final type in pokemon!.types)
                            PokemonTypeBadge(type: type, height: 20),
                          _SmallChip(label: 'HP ${pokemon!.hitPoints}'),
                          _SmallChip(label: 'AC ${pokemon!.armorClass}'),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              slot.isEgg
                  ? const Icon(Icons.chevron_right)
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (pokemon != null)
                          IconButton(
                            onPressed: onShare,
                            tooltip: 'Condividi Pokémon',
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.ios_share_outlined),
                          ),
                        PopupMenuButton<_SlotAction>(
                          tooltip: 'Altre azioni',
                          onSelected: (action) {
                            switch (action) {
                              case _SlotAction.change:
                                onChange();
                                break;
                              case _SlotAction.export:
                                onExport?.call();
                                break;
                              case _SlotAction.share:
                                onShare?.call();
                                break;
                              case _SlotAction.import:
                                onImport?.call();
                                break;
                              case _SlotAction.remove:
                                onRemove?.call();
                                break;
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: _SlotAction.change,
                              child: Text(
                                pokemon == null
                                    ? 'Scegli Pokémon'
                                    : 'Cambia Pokémon',
                              ),
                            ),
                            if (pokemon != null)
                              const PopupMenuItem(
                                value: _SlotAction.export,
                                child: Text('Esporta Pokémon'),
                              ),
                            if (pokemon != null)
                              const PopupMenuItem(
                                value: _SlotAction.share,
                                child: Text('Condividi Pokémon'),
                              ),
                            const PopupMenuItem(
                              value: _SlotAction.import,
                              child: Text('Importa Pokémon qui'),
                            ),
                            if (pokemon != null)
                              const PopupMenuItem(
                                value: _SlotAction.remove,
                                child: Text('Rimuovi dallo slot'),
                              ),
                          ],
                        ),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _TeamTransferAction { exportTeam, shareTeam, importTeam }

enum _SlotAction { change, export, share, import, remove }

class _SlotAvatar extends StatelessWidget {
  const _SlotAvatar({required this.slot, required this.pokemon});

  final TeamSlot slot;
  final Pokemon? pokemon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final pokemon = this.pokemon;

    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: pokemon != null
            ? colorScheme.primaryContainer.withValues(alpha: 0.72)
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: slot.isEgg
            ? const EggAssetImage(size: 38)
            : pokemon == null
            ? Text(
                '${slot.slotIndex + 1}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w900,
                ),
              )
            : PokemonAssetImage(
                pokemon: pokemon,
                formName: slot.formName,
                gender: slot.gender,
                isShiny: slot.isShiny,
                size: 48,
              ),
      ),
    );
  }
}

class _SmallChip extends StatelessWidget {
  const _SmallChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _PokemonPickerSheet extends StatefulWidget {
  const _PokemonPickerSheet({required this.pokemon});

  final List<Pokemon> pokemon;

  @override
  State<_PokemonPickerSheet> createState() => _PokemonPickerSheetState();
}

class _PokemonPickerSheetState extends State<_PokemonPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredPokemon = widget.pokemon.where((pokemon) {
      final query = _query.toLowerCase().trim();

      return query.isEmpty ||
          pokemon.name.toLowerCase().contains(query) ||
          pokemon.id.toString().contains(query) ||
          pokemon.types.any((type) => type.toLowerCase().contains(query));
    }).toList();

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.82,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Scegli Pokémon',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Cerca per nome, numero o tipo...',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _query = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                itemCount: filteredPokemon.length,
                itemBuilder: (context, index) {
                  final pokemon = filteredPokemon[index];
                  final number = '#${pokemon.id.toString().padLeft(3, '0')}';

                  return Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      leading: _PokemonPickerSprite(pokemon: pokemon),
                      title: Text(
                        pokemon.name,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 5,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              number,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            for (final type in pokemon.types)
                              PokemonTypeBadge(type: type, height: 18),
                            _SmallChip(label: 'HP ${pokemon.hitPoints}'),
                            _SmallChip(label: 'AC ${pokemon.armorClass}'),
                          ],
                        ),
                      ),
                      trailing: const Icon(Icons.add_circle_outline),
                      onTap: () {
                        Navigator.of(context).pop(pokemon.id);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PokemonPickerSprite extends StatelessWidget {
  const _PokemonPickerSprite({required this.pokemon});

  final Pokemon pokemon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.48),
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: PokemonAssetImage(pokemon: pokemon, size: 48),
    );
  }
}

class _TeamStatusBanner extends StatelessWidget {
  const _TeamStatusBanner({
    required this.message,
    required this.isError,
    required this.onDismiss,
  });

  final String message;
  final bool isError;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final background = isError
        ? colors.errorContainer
        : colors.primaryContainer;
    final foreground = isError
        ? colors.onErrorContainer
        : colors.onPrimaryContainer;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(
          isError ? Icons.error_outline : Icons.check_circle_outline,
          color: foreground,
        ),
        title: Text(message, style: TextStyle(color: foreground)),
        trailing: IconButton(
          tooltip: 'Chiudi',
          onPressed: onDismiss,
          icon: Icon(Icons.close, color: foreground),
        ),
      ),
    );
  }
}

class _TeamErrorState extends StatelessWidget {
  const _TeamErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          const Icon(Icons.error_outline, size: 48),
          const SizedBox(height: 16),
          Text('Errore: $message', textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton(onPressed: onRetry, child: const Text('Riprova')),
        ],
      ),
    );
  }
}
