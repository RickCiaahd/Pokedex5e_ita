// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../localization/ui_text.dart';
import '../../localization/user_facing_error.dart';

import '../../models/level_progression.dart';
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
import '../../services/trainer_path_passive_service.dart';
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
  final ScrollController _scrollController = ScrollController();

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

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = context.userFacingError(
          error,
          action: UserFacingErrorAction.load,
        );
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

  Future<void> _reorderTeamSlot(int fromSlotIndex, int toSlotIndex) async {
    final profile = _profile;
    if (_isBusy || profile == null || fromSlotIndex == toSlotIndex) return;

    setState(() => _isBusy = true);
    try {
      final reordered = await _teamRepository.reorderSlots(
        profileId: profile.id,
        fromSlotIndex: fromSlotIndex,
        toSlotIndex: toSlotIndex,
      );
      if (!mounted) return;
      setState(() {
        _team = reordered..sort((a, b) => a.slotIndex.compareTo(b.slotIndex));
      });
      _setStatus(
        context.uiText(
          'Ordine della squadra aggiornato.',
          'Team order updated.',
        ),
      );
    } catch (error) {
      if (!mounted) return;
      _setStatus(
        context.userFacingError(error, action: UserFacingErrorAction.save),
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  void _autoScrollDuringDrag(DragUpdateDetails details) {
    if (!_scrollController.hasClients) return;

    final screenHeight = MediaQuery.sizeOf(context).height;
    const edgeSize = 96.0;
    const scrollStep = 14.0;
    final y = details.globalPosition.dy;
    var nextOffset = _scrollController.offset;

    if (y < edgeSize) {
      nextOffset -= scrollStep;
    } else if (y > screenHeight - edgeSize) {
      nextOffset += scrollStep;
    } else {
      return;
    }

    final position = _scrollController.position;
    _scrollController.jumpTo(
      nextOffset
          .clamp(position.minScrollExtent, position.maxScrollExtent)
          .toDouble(),
    );
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

  String _displayNameForSlot(TeamSlot slot) {
    final nickname = slot.nickname?.trim() ?? '';
    if (nickname.isNotEmpty) return nickname;
    return _pokemonById(slot.pokemonId)?.name ?? 'Pokémon';
  }

  int _maxHpForSlot(TeamSlot slot) {
    final profile = _profile;
    final basePokemon = _pokemonById(slot.pokemonId);
    if (profile == null || basePokemon == null) return 0;

    final pokemon = basePokemon.resolveVariant(
      formName: slot.effectiveFormName,
      gender: slot.gender,
    );
    return TrainerPathPassiveService.maxHp(
      profile: profile,
      pokemon: pokemon,
      slot: slot,
      level: LevelProgression.levelFromExperience(slot.experience),
    );
  }

  Future<PokemonTransferBundle?> _pickTransferFile() async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: context.uiText(
        'Seleziona un trasferimento Pokédex 5e',
        'Select a Pokémon 5e transfer',
      ),
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
        dialogTitle: uiTextForLanguage(
          'Esporta $displayName',
          """Export $displayName""",
        ),
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
            ? context.uiText('Esportazione annullata.', 'Export cancelled.')
            : uiTextForLanguage(
                '$displayName esportato correttamente.',
                """$displayName exported successfully.""",
              ),
      );
    } catch (error) {
      if (!mounted) return;
      _setStatus(
        context.userFacingError(
          error,
          action: UserFacingErrorAction.exportFile,
        ),
        isError: true,
      );
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
        context.uiText(
          'La squadra non contiene Pokémon da esportare.',
          'The team has no Pokémon to export.',
        ),
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
        dialogTitle: context.uiText(
          'Esporta la squadra di ${profile.name}',
          'Export ${profile.name}’s team',
        ),
        fileName: _transferService.fileNameForTeam(bundle),
        type: FileType.custom,
        allowedExtensions: const ['json'],
        bytes: Uint8List.fromList(utf8.encode(json)),
      );
      _setStatus(
        path == null
            ? context.uiText('Esportazione annullata.', 'Export cancelled.')
            : context.uiText(
                'Squadra esportata correttamente (${pokemonSlots.length} Pokémon).',
                'Team exported successfully (${pokemonSlots.length} Pokémon).',
              ),
      );
    } catch (error) {
      if (!mounted) return;
      _setStatus(
        context.userFacingError(
          error,
          action: UserFacingErrorAction.exportFile,
        ),
        isError: true,
      );
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
      if (!mounted) return;
      final displayName = _displayNameForSlot(slot);
      final outcome = await _shareService.shareTextFile(
        context: context,
        content: json,
        fileName: _transferService.fileNameForPokemon(
          bundle,
          displayName: displayName,
        ),
        mimeType: 'application/json',
        title: context.uiText('Condividi $displayName', 'Share $displayName'),
        subject: '$displayName · Trainer Atlas 5e',
        text: uiTextForLanguage(
          'Pokémon esportato da Trainer Atlas 5e.',
          """Pokémon exported by Trainer Atlas 5e.""",
        ),
      );
      _setStatus(
        _shareService.feedback(
          outcome,
          successMessage: uiTextForLanguage(
            '$displayName condiviso correttamente.',
            """$displayName shared successfully.""",
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      _setStatus(
        context.userFacingError(error, action: UserFacingErrorAction.share),
        isError: true,
      );
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
        context.uiText(
          'La squadra non contiene Pokémon da condividere.',
          'The team has no Pokémon to share.',
        ),
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
      if (!mounted) return;
      final outcome = await _shareService.shareTextFile(
        context: context,
        content: json,
        fileName: _transferService.fileNameForTeam(bundle),
        mimeType: 'application/json',
        title: context.uiText(
          'Condividi la squadra di ${profile.name}',
          'Share ${profile.name}’s team',
        ),
        subject: context.uiText(
          'Squadra di ${profile.name} · Trainer Atlas 5e',
          '${profile.name}’s team · Trainer Atlas 5e',
        ),
        text: context.uiText(
          'Squadra esportata da Trainer Atlas 5e.',
          'Team exported from Trainer Atlas 5e.',
        ),
      );
      _setStatus(
        _shareService.feedback(
          outcome,
          successMessage: context.uiText(
            'Squadra condivisa correttamente (${pokemonSlots.length} Pokémon).',
            'Team shared successfully (${pokemonSlots.length} Pokémon).',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      _setStatus(
        context.userFacingError(error, action: UserFacingErrorAction.share),
        isError: true,
      );
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
        _setStatus(
          context.uiText('Importazione annullata.', 'Import cancelled.'),
        );
        return;
      }
      if (bundle.kind != PokemonTransferKind.pokemon) {
        throw FormatException(
          context.uiText(
            'Seleziona un file esportato come singolo Pokémon.',
            'Select a file exported as a single Pokémon.',
          ),
        );
      }
      final importedSlot = bundle.pokemon.single;
      final importedPokemon = _pokemonFromTransfer(
        bundle,
        importedSlot.pokemonId,
      );
      if (importedPokemon == null) {
        throw FormatException(
          uiTextForLanguage(
            'Il Pokémon #${importedSlot.pokemonId} non è presente nel catalogo.',
            """Pokémon #${importedSlot.pokemonId} is not available in the catalog.""",
          ),
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
          title: Text(context.uiText('Importare Pokémon?', 'Import Pokémon?')),
          content: Text(
            replacedName == null
                ? uiTextForLanguage(
                    'Vuoi inserire $importedName nello slot ${target.slotIndex + 1}?',
                    """Add $importedName to slot ${target.slotIndex + 1}?""",
                  )
                : uiTextForLanguage(
                        'Vuoi inserire $importedName nello slot ${target.slotIndex + 1}? ',
                        """Add $importedName to slot ${target.slotIndex + 1}? """,
                      ) +
                      uiTextForLanguage(
                        '$replacedName verrà spostato nel PC Pokémon.',
                        """$replacedName will be moved to the Pokémon PC.""",
                      ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(uiTextForLanguage('ANNULLA', """CANCEL""")),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(uiTextForLanguage('IMPORTA', """IMPORT""")),
            ),
          ],
        ),
      );
      if (confirmed != true) {
        _setStatus(
          context.uiText('Importazione annullata.', 'Import cancelled.'),
        );
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
            ? uiTextForLanguage(
                '$importedName importato. Il Pokémon sostituito è stato spostato nel PC.',
                """$importedName imported. The replaced Pokémon was moved to the PC.""",
              )
            : uiTextForLanguage(
                '$importedName importato nello slot ${target.slotIndex + 1}.',
                """$importedName imported into slot ${target.slotIndex + 1}.""",
              ),
      );
    } catch (error) {
      if (!mounted) return;
      _setStatus(
        context.userFacingError(
          error,
          action: UserFacingErrorAction.importFile,
        ),
        isError: true,
      );
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
        _setStatus(
          context.uiText('Importazione annullata.', 'Import cancelled.'),
        );
        return;
      }
      if (bundle.kind != PokemonTransferKind.team) {
        throw FormatException(
          context.uiText(
            'Seleziona un file esportato come squadra.',
            'Select a file exported as a team.',
          ),
        );
      }
      final unknownIds = <int>{
        for (final slot in bundle.pokemon)
          if (_pokemonFromTransfer(bundle, slot.pokemonId) == null)
            slot.pokemonId!,
      };
      if (unknownIds.isNotEmpty) {
        throw FormatException(
          uiTextForLanguage(
            'Il catalogo non contiene i Pokémon: ${unknownIds.join(', ')}.',
            'The catalog does not contain these Pokémon: ${unknownIds.join(', ')}.',
          ),
        );
      }

      final availableSlots = _visibleTeam.where((slot) => !slot.isEgg).length;
      if (availableSlots == 0) {
        throw StateError(
          uiTextForLanguage(
            'Non ci sono Pokéslot disponibili: gli slot sbloccati contengono uova.',
            """No Poké Slots are available: the unlocked slots contain eggs.""",
          ),
        );
      }
      final replaced = _visibleTeam.where((slot) => slot.isPokemon).length;
      final overflow = bundle.pokemon.length > availableSlots
          ? bundle.pokemon.length - availableSlots
          : 0;
      if (!mounted) return;
      final source = bundle.sourceTrainerName.isEmpty
          ? ''
          : uiTextForLanguage(
              ' di ${bundle.sourceTrainerName}',
              """ from ${bundle.sourceTrainerName}""",
            );
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(context.uiText('Importare squadra?', 'Import team?')),
          content: Text(
            uiTextForLanguage(
              'Stai importando ${bundle.pokemon.length} Pokémon$source. '
                  '${replaced > 0 ? 'I $replaced Pokémon attualmente in squadra verranno spostati nel PC. ' : ''}'
                  'Le uova resteranno nei loro slot. '
                  '${overflow > 0 ? '$overflow Pokémon importati finiranno nel PC perché non ci sono abbastanza Pokéslot disponibili.' : ''}',
              'You are importing ${bundle.pokemon.length} Pokémon$source. '
                  '${replaced > 0 ? 'The $replaced Pokémon currently in the team will be moved to the PC. ' : ''}'
                  'Eggs will remain in their slots. '
                  '${overflow > 0 ? '$overflow imported Pokémon will be sent to the PC because there are not enough Poké Slots available.' : ''}',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(uiTextForLanguage('ANNULLA', """CANCEL""")),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(context.uiText('IMPORTA SQUADRA', 'IMPORT TEAM')),
            ),
          ],
        ),
      );
      if (confirmed != true) {
        _setStatus(
          context.uiText('Importazione annullata.', 'Import cancelled.'),
        );
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
          : context.uiText(
              ' ${result.movedToPc} Pokémon sono stati salvati nel PC.',
              ' ${result.movedToPc} Pokémon were stored in the PC.',
            );
      _setStatus(
        context.uiText(
          'Squadra importata: ${result.importedToTeam} Pokémon nei Pokéslot.$pcDetail',
          'Team imported: ${result.importedToTeam} Pokémon in Poké Slots.$pcDetail',
        ),
      );
    } catch (error) {
      if (!mounted) return;
      _setStatus(
        context.userFacingError(
          error,
          action: UserFacingErrorAction.importFile,
        ),
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Widget _buildTeamSlots(List<TeamSlot> visibleTeam) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 8.0;
        final columns = constraints.maxWidth >= 1000
            ? 4
            : constraints.maxWidth >= 680
            ? 3
            : 2;
        final cardWidth =
            (constraints.maxWidth - (spacing * (columns - 1))) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final slot in visibleTeam)
              DragTarget<int>(
                key: ValueKey('team-slot-drop-${slot.slotIndex}'),
                onWillAcceptWithDetails: (details) =>
                    !_isBusy && details.data != slot.slotIndex,
                onAcceptWithDetails: (details) {
                  _reorderTeamSlot(details.data, slot.slotIndex);
                },
                builder: (context, candidateData, rejectedData) {
                  final isDropTarget = candidateData.isNotEmpty;
                  final card = SizedBox(
                    width: cardWidth,
                    child: _TeamSlotCard(
                      slot: slot,
                      pokemon: _pokemonById(slot.pokemonId),
                      maxHp: _maxHpForSlot(slot),
                      isDropTarget: isDropTarget,
                      onOpen: () => _openPokemonDetail(slot),
                      onChange: () => _openPokemonPicker(slot),
                      onExport: slot.isPokemon
                          ? () => _exportPokemon(slot)
                          : null,
                      onShare: slot.isPokemon
                          ? () => _sharePokemon(slot)
                          : null,
                      onImport: slot.isEgg
                          ? null
                          : () => _importPokemonInto(slot),
                      onRemove: slot.isPokemon
                          ? () => _setPokemonInSlot(slot.slotIndex, null)
                          : null,
                    ),
                  );

                  if (!slot.isPokemon || _isBusy) return card;

                  return LongPressDraggable<int>(
                    data: slot.slotIndex,
                    hapticFeedbackOnStart: true,
                    onDragUpdate: _autoScrollDuringDrag,
                    feedback: Material(
                      color: Colors.transparent,
                      elevation: 8,
                      borderRadius: BorderRadius.circular(14),
                      child: IgnorePointer(
                        child: SizedBox(
                          width: cardWidth,
                          child: _TeamSlotCard(
                            slot: slot,
                            pokemon: _pokemonById(slot.pokemonId),
                            maxHp: _maxHpForSlot(slot),
                            onOpen: () {},
                            onChange: () {},
                            onExport: null,
                            onShare: null,
                            onImport: null,
                            onRemove: null,
                          ),
                        ),
                      ),
                    ),
                    childWhenDragging: Opacity(opacity: 0.3, child: card),
                    child: card,
                  );
                },
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleTeam = _visibleTeam;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.uiText('Squadra', 'Team')),
        actions: [
          IconButton(
            onPressed: _isBusy || _isLoading ? null : _shareTeam,
            tooltip: context.uiText('Condividi squadra', 'Share team'),
            icon: const Icon(Icons.ios_share_outlined),
          ),
          PopupMenuButton<_TeamTransferAction>(
            enabled: !_isBusy && !_isLoading,
            tooltip: context.uiText(
              'Esporta o importa squadra',
              'Export or import team',
            ),
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
            itemBuilder: (context) => [
              PopupMenuItem(
                value: _TeamTransferAction.exportTeam,
                child: ListTile(
                  leading: Icon(Icons.upload_file_outlined),
                  title: Text(context.uiText('Esporta squadra', 'Export team')),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: _TeamTransferAction.shareTeam,
                child: ListTile(
                  leading: Icon(Icons.ios_share_outlined),
                  title: Text(
                    context.uiText('Condividi squadra', 'Share team'),
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: _TeamTransferAction.importTeam,
                child: ListTile(
                  leading: Icon(Icons.download_outlined),
                  title: Text(context.uiText('Importa squadra', 'Import team')),
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
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              if (_isBusy) const LinearProgressIndicator(),
              if (_isLoading)
                Padding(
                  padding: EdgeInsets.only(top: 120),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_errorMessage != null)
                _TeamErrorState(message: _errorMessage!, onRetry: _loadTeam)
              else ...[
                if (_statusMessage != null) ...[
                  _TeamStatusBanner(
                    message: _statusMessage!,
                    isError: _statusIsError,
                    onDismiss: () => setState(() => _statusMessage = null),
                  ),
                ],
                const SizedBox(height: 16),
                if (visibleTeam.any((slot) => slot.isPokemon) &&
                    visibleTeam.length > 1) ...[
                  _TeamReorderHint(isBusy: _isBusy),
                  const SizedBox(height: 8),
                ],
                _buildTeamSlots(visibleTeam),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TeamReorderHint extends StatelessWidget {
  const _TeamReorderHint({required this.isBusy});

  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: false,
      child: Row(
        children: [
          Icon(
            Icons.drag_indicator,
            color: isBusy
                ? colorScheme.onSurfaceVariant.withValues(alpha: 0.45)
                : colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              context.uiText(
                'Tieni premuto un Pokémon e trascinalo per cambiare l’ordine.',
                'Press and hold a Pokémon, then drag it to change the order.',
              ),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isBusy
                    ? colorScheme.onSurfaceVariant.withValues(alpha: 0.45)
                    : colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
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
    required this.maxHp,
    required this.onOpen,
    required this.onChange,
    required this.onExport,
    required this.onShare,
    required this.onImport,
    required this.onRemove,
    this.isDropTarget = false,
  });

  final TeamSlot slot;
  final Pokemon? pokemon;
  final int maxHp;
  final VoidCallback onOpen;
  final VoidCallback onChange;
  final VoidCallback? onExport;
  final VoidCallback? onShare;
  final VoidCallback? onImport;
  final VoidCallback? onRemove;
  final bool isDropTarget;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final basePokemon = pokemon;
    final resolvedPokemon = basePokemon?.resolveVariant(
      formName: slot.effectiveFormName,
      gender: slot.gender,
    );
    final nickname = slot.nickname?.trim() ?? '';
    final title = slot.isEgg
        ? context.uiText('Uovo', 'Egg')
        : nickname.isEmpty
        ? resolvedPokemon?.name ?? context.uiText('Slot vuoto', 'Empty slot')
        : nickname;
    final level = resolvedPokemon == null
        ? null
        : LevelProgression.levelFromExperience(slot.experience);
    final currentHp = maxHp <= 0 ? 0 : slot.currentHp.clamp(0, maxHp).toInt();
    final hpProgress = maxHp <= 0
        ? 0.0
        : (currentHp / maxHp).clamp(0.0, 1.0).toDouble();
    final hasHeldItem = slot.heldItem?.trim().isNotEmpty == true;
    final hasStatus = slot.statusEffects.isNotEmpty;
    final enlargedText = MediaQuery.textScalerOf(context).scale(1) > 1.25;
    final cardHeight = enlargedText ? 244.0 : 194.0;

    return Semantics(
      button: true,
      label: slot.isEgg
          ? context.uiText(
              'Pokéslot ${slot.slotIndex + 1}, uovo in incubazione',
              'Poké Slot ${slot.slotIndex + 1}, incubating egg',
            )
          : resolvedPokemon == null
          ? context.uiText(
              'Pokéslot ${slot.slotIndex + 1}, vuoto',
              'Poké Slot ${slot.slotIndex + 1}, empty',
            )
          : '$title, ${context.uiText('livello', 'level')} $level',
      child: Card(
        margin: EdgeInsets.zero,
        color: isDropTarget ? colorScheme.primaryContainer : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: isDropTarget
              ? BorderSide(color: colorScheme.primary, width: 2)
              : BorderSide(color: colorScheme.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onOpen,
          child: SizedBox(
            height: cardHeight,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 7, 6, 8),
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Text(
                            context.uiText(
                              'SLOT ${slot.slotIndex + 1}',
                              'SLOT ${slot.slotIndex + 1}',
                            ),
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const Spacer(),
                          if (slot.isEgg)
                            Icon(
                              Icons.chevron_right,
                              size: 20,
                              color: colorScheme.onSurfaceVariant,
                            )
                          else
                            _TeamSlotMenu(
                              pokemon: resolvedPokemon,
                              onChange: onChange,
                              onExport: onExport,
                              onShare: onShare,
                              onImport: onImport,
                              onRemove: onRemove,
                            ),
                        ],
                      ),
                      Expanded(
                        child: Center(
                          child: _SlotAvatar(
                            slot: slot,
                            pokemon: resolvedPokemon,
                          ),
                        ),
                      ),
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (slot.isEgg)
                        Text(
                          context.uiText('Tocca per gestire', 'Tap to manage'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                        )
                      else if (resolvedPokemon == null)
                        Text(
                          context.uiText(
                            'Tocca per scegliere',
                            'Tap to choose',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w800,
                              ),
                        )
                      else ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${context.uiText('Liv.', 'Lv.')} $level',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                            if (resolvedPokemon.types.isNotEmpty) ...[
                              const SizedBox(width: 5),
                              Flexible(
                                child: Wrap(
                                  alignment: WrapAlignment.center,
                                  spacing: 3,
                                  runSpacing: 2,
                                  children: [
                                    for (final type
                                        in resolvedPokemon.types.take(2))
                                      PokemonTypeBadge(type: type, height: 15),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    context.uiText(
                                      'PF $currentHp/$maxHp',
                                      'HP $currentHp/$maxHp',
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                  const SizedBox(height: 2),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(999),
                                    child: LinearProgressIndicator(
                                      value: hpProgress,
                                      minHeight: 6,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        _teamHpProgressColor(hpProgress),
                                      ),
                                      backgroundColor:
                                          colorScheme.surfaceContainerHighest,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (hasStatus) ...[
                              const SizedBox(width: 5),
                              Tooltip(
                                message: context.uiText(
                                  'Status attivi: ${slot.statusEffects.length}',
                                  'Active conditions: ${slot.statusEffects.length}',
                                ),
                                child: Icon(
                                  Icons.warning_amber_rounded,
                                  size: 18,
                                  color: colorScheme.error,
                                ),
                              ),
                            ],
                            if (hasHeldItem) ...[
                              const SizedBox(width: 4),
                              Tooltip(
                                message: context.uiText(
                                  'Strumento tenuto',
                                  'Held item',
                                ),
                                child: Icon(
                                  Icons.inventory_2_outlined,
                                  size: 17,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ],
                  ),
                  if (resolvedPokemon == null && !slot.isEgg)
                    Positioned.fill(
                      top: 24,
                      bottom: 45,
                      child: IgnorePointer(
                        child: Center(
                          child: Icon(
                            Icons.add_circle_outline,
                            size: 42,
                            color: colorScheme.primary.withValues(alpha: 0.72),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TeamSlotMenu extends StatelessWidget {
  const _TeamSlotMenu({
    required this.pokemon,
    required this.onChange,
    required this.onExport,
    required this.onShare,
    required this.onImport,
    required this.onRemove,
  });

  final Pokemon? pokemon;
  final VoidCallback onChange;
  final VoidCallback? onExport;
  final VoidCallback? onShare;
  final VoidCallback? onImport;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 30,
      child: PopupMenuButton<_SlotAction>(
        padding: EdgeInsets.zero,
        iconSize: 19,
        tooltip: context.uiText('Altre azioni', 'More actions'),
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
                  ? context.uiText('Scegli Pokémon', 'Choose Pokémon')
                  : context.uiText('Cambia Pokémon', 'Change Pokémon'),
            ),
          ),
          if (pokemon != null)
            PopupMenuItem(
              value: _SlotAction.export,
              child: Text(context.uiText('Esporta Pokémon', 'Export Pokémon')),
            ),
          if (pokemon != null)
            PopupMenuItem(
              value: _SlotAction.share,
              child: Text(context.uiText('Condividi Pokémon', 'Share Pokémon')),
            ),
          if (onImport != null)
            PopupMenuItem(
              value: _SlotAction.import,
              child: Text(
                context.uiText('Importa Pokémon qui', 'Import Pokémon here'),
              ),
            ),
          if (pokemon != null)
            PopupMenuItem(
              value: _SlotAction.remove,
              child: Text(
                context.uiText('Rimuovi dallo slot', 'Remove from slot'),
              ),
            ),
        ],
      ),
    );
  }
}

Color _teamHpProgressColor(double value) {
  if (value <= 0.25) return Colors.red;
  if (value <= 0.5) return Colors.amber;
  return Colors.green;
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
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        color: pokemon != null
            ? colorScheme.primaryContainer.withValues(alpha: 0.48)
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
      ),
      alignment: Alignment.center,
      child: slot.isEgg
          ? const EggAssetImage(size: 54)
          : pokemon == null
          ? const SizedBox.shrink()
          : PokemonAssetImage(
              pokemon: pokemon,
              formName: slot.effectiveFormName,
              gender: slot.gender,
              isShiny: slot.isShiny,
              size: 70,
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
                    uiTextForLanguage('Scegli Pokémon', """Choose Pokémon"""),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: context.uiText(
                        'Cerca per nome, numero o tipo...',
                        'Search by name, number or type...',
                      ),
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
          tooltip: uiTextForLanguage('Chiudi', """Close"""),
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
          Text(
            context.uiText('Errore: $message', 'Error: $message'),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: onRetry,
            child: Text(uiTextForLanguage('Riprova', """Retry""")),
          ),
        ],
      ),
    );
  }
}
