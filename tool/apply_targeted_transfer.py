# Applied and removed automatically by GitHub Actions.
from pathlib import Path


def replace_once(text: str, old: str, new: str, label: str) -> str:
    count = text.count(old)
    if count != 1:
        raise SystemExit(f"{label}: expected 1 occurrence, found {count}")
    return text.replace(old, new)


path = Path('lib/screens/team/team_selection_screen.dart')
text = path.read_text(encoding='utf-8')

text = replace_once(
    text,
    """import 'package:flutter/material.dart';

import '../../models/pokemon.dart';
""",
    """import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../models/pokemon.dart';
import '../../models/pokemon_transfer_bundle.dart';
""",
    'imports header',
)

text = replace_once(
    text,
    """import '../../repositories/team_repository.dart';
import '../../widgets/pokemon/egg_asset_image.dart';
""",
    """import '../../repositories/team_repository.dart';
import '../../services/pokemon_transfer_service.dart';
import '../../widgets/pokemon/egg_asset_image.dart';
""",
    'service import',
)

text = replace_once(
    text,
    """  final PokemonRepository _pokemonRepository = PokemonRepository();
  final TeamRepository _teamRepository = TeamRepository();

  UserProfile? _profile;
""",
    """  final PokemonRepository _pokemonRepository = PokemonRepository();
  final TeamRepository _teamRepository = TeamRepository();
  final PokemonTransferService _transferService = PokemonTransferService();

  UserProfile? _profile;
""",
    'service field',
)

text = replace_once(
    text,
    """  bool _isLoading = true;
  String? _errorMessage;
""",
    """  bool _isLoading = true;
  bool _isBusy = false;
  String? _errorMessage;
  String? _statusMessage;
  bool _statusIsError = false;
""",
    'state fields',
)

methods = r'''

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
    final result = await FilePicker.pickFiles(
      dialogTitle: 'Seleziona un trasferimento Pokédex 5e',
      type: FileType.custom,
      allowedExtensions: const ['json'],
      allowMultiple: false,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;
    final picked = result.files.single;
    final bytes = picked.bytes ?? await picked.xFile.readAsBytes();
    return _transferService.decode(
      utf8.decode(bytes, allowMalformed: false),
    );
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
      final json = _transferService.encode(bundle);
      final displayName = _displayNameForSlot(slot);
      final path = await FilePicker.saveFile(
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
      _setStatus('La squadra non contiene Pokémon da esportare.', isError: true);
      return;
    }

    setState(() => _isBusy = true);
    try {
      final bundle = PokemonTransferBundle.team(
        slots: pokemonSlots,
        sourceTrainerName: profile.name,
      );
      final json = _transferService.encode(bundle);
      final path = await FilePicker.saveFile(
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
      final importedPokemon = _pokemonById(importedSlot.pokemonId);
      if (importedPokemon == null) {
        throw FormatException(
          'Il Pokémon #${importedSlot.pokemonId} non è presente nel catalogo.',
        );
      }
      if (!mounted) return;
      final importedName = importedSlot.nickname?.trim().isNotEmpty == true
          ? importedSlot.nickname!.trim()
          : importedPokemon.name;
      final replacedName = target.isPokemon ? _displayNameForSlot(target) : null;
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
          if (_pokemonById(slot.pokemonId) == null) slot.pokemonId!,
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
'''

text = replace_once(
    text,
    """    await _setPokemonInSlot(slot.slotIndex, selectedPokemonId);
  }

  @override
""",
    """    await _setPokemonInSlot(slot.slotIndex, selectedPokemonId);
  }$methods

  @override
""",
    'methods insertion',
)

text = replace_once(
    text,
    """    return Scaffold(
      appBar: AppBar(title: const Text('Squadra')),
""",
    """    return Scaffold(
      appBar: AppBar(
        title: const Text('Squadra'),
        actions: [
          PopupMenuButton<_TeamTransferAction>(
            enabled: !_isBusy && !_isLoading,
            tooltip: 'Esporta o importa squadra',
            onSelected: (action) {
              switch (action) {
                case _TeamTransferAction.exportTeam:
                  _exportTeam();
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
""",
    'app bar',
)

text = replace_once(
    text,
    """          children: [
            if (_isLoading)
""",
    """          children: [
            if (_isBusy) const LinearProgressIndicator(),
            if (_isLoading)
""",
    'busy indicator',
)

text = replace_once(
    text,
    """              _TeamHeader(
                profileName: profileName,
                filledSlots: filledSlots,
                totalSlots: visibleTeam.length,
              ),
              const SizedBox(height: 16),
""",
    """              _TeamHeader(
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
""",
    'status banner use',
)

text = replace_once(
    text,
    """                  onChange: () => _openPokemonPicker(slot),
                  onRemove: slot.isPokemon
                      ? () => _setPokemonInSlot(slot.slotIndex, null)
                      : null,
""",
    """                  onChange: () => _openPokemonPicker(slot),
                  onExport: slot.isPokemon ? () => _exportPokemon(slot) : null,
                  onImport: slot.isEgg ? null : () => _importPokemonInto(slot),
                  onRemove: slot.isPokemon
                      ? () => _setPokemonInSlot(slot.slotIndex, null)
                      : null,
""",
    'slot callbacks',
)

text = replace_once(
    text,
    """    required this.onOpen,
    required this.onChange,
    required this.onRemove,
""",
    """    required this.onOpen,
    required this.onChange,
    required this.onExport,
    required this.onImport,
    required this.onRemove,
""",
    'slot constructor',
)

text = replace_once(
    text,
    """  final VoidCallback onOpen;
  final VoidCallback onChange;
  final VoidCallback? onRemove;
""",
    """  final VoidCallback onOpen;
  final VoidCallback onChange;
  final VoidCallback? onExport;
  final VoidCallback? onImport;
  final VoidCallback? onRemove;
""",
    'slot fields',
)

old_menu = """              slot.isEgg
                  ? const Icon(Icons.chevron_right)
                  : pokemon == null
                  ? IconButton.filled(
                      tooltip: 'Scegli',
                      icon: const Icon(Icons.add),
                      onPressed: onChange,
                    )
                  : PopupMenuButton<_SlotAction>(
                      tooltip: 'Azioni slot',
                      onSelected: (action) {
                        switch (action) {
                          case _SlotAction.change:
                            onChange();
                            break;
                          case _SlotAction.remove:
                            onRemove?.call();
                            break;
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: _SlotAction.change,
                          child: Text('Cambia Pokémon'),
                        ),
                        PopupMenuItem(
                          value: _SlotAction.remove,
                          child: Text('Rimuovi dallo slot'),
                        ),
                      ],
                    ),
"""
new_menu = """              slot.isEgg
                  ? const Icon(Icons.chevron_right)
                  : PopupMenuButton<_SlotAction>(
                      tooltip: 'Azioni slot',
                      onSelected: (action) {
                        switch (action) {
                          case _SlotAction.change:
                            onChange();
                            break;
                          case _SlotAction.export:
                            onExport?.call();
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
"""
text = replace_once(text, old_menu, new_menu, 'slot menu')

text = replace_once(
    text,
    """enum _SlotAction { change, remove }
""",
    """enum _TeamTransferAction { exportTeam, importTeam }

enum _SlotAction { change, export, import, remove }
""",
    'enums',
)

banner = r'''

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
'''

text = replace_once(
    text,
    """
class _TeamErrorState extends StatelessWidget {
""",
    f"""{banner}
class _TeamErrorState extends StatelessWidget {{
""",
    'status banner class',
)

path.write_text(text, encoding='utf-8')

readme_path = Path('README.md')
readme = readme_path.read_text(encoding='utf-8')
readme = replace_once(
    readme,
    """I dati applicativi sono salvati localmente tramite Hive. La schermata Profili permette di esportare e importare backup JSON, compresi squadra, Pokémon Center, inventario, impostazioni e sessioni di combattimento supportate.
""",
    """I dati applicativi sono salvati localmente tramite Hive. La schermata Profili permette di esportare e importare backup JSON, compresi squadra, Pokémon Center, inventario, impostazioni e sessioni di combattimento supportate. Dalla schermata Squadra è inoltre possibile esportare e importare singoli Pokémon o una formazione completa senza sostituire l'intero profilo; i Pokémon rimpiazzati e gli eventuali esuberi vengono conservati nel PC.
""",
    'readme data section',
)
readme_path.write_text(readme, encoding='utf-8')

changelog_path = Path('CHANGELOG.md')
changelog = changelog_path.read_text(encoding='utf-8')
changelog = replace_once(
    changelog,
    """- la Classe Armatura effettiva del Pokémon è ora visibile accanto al nome nel Battle Companion, con l’eventuale bonus ambientale evidenziato.

### In programma

- condivisione nativa ed esportazioni mirate.
""",
    """- la Classe Armatura effettiva del Pokémon è ora visibile accanto al nome nel Battle Companion, con l’eventuale bonus ambientale evidenziato;
- aggiunti file JSON portabili per esportare e importare un singolo Pokémon o l'intera squadra, preservando mosse, esperienza, natura, abilità, talenti, forma, sesso, Lealtà e personalizzazioni;
- durante l'importazione i Pokémon sostituiti e gli esuberi vengono trasferiti automaticamente nel PC, mentre le uova restano nei propri Pokéslot.

### In programma

- condivisione tramite menu nativo ed esportazioni mirate di Allenatori, incontri e riepiloghi del Fight del Master.
""",
    'changelog',
)
changelog_path.write_text(changelog, encoding='utf-8')
