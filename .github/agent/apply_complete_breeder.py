from pathlib import Path
import re


def replace_once(text: str, old: str, new: str, label: str) -> str:
    count = text.count(old)
    if count != 1:
        raise RuntimeError(f'{label}: atteso 1 match, trovati {count}')
    return text.replace(old, new, 1)


def replace_regex(text: str, pattern: str, replacement: str, label: str) -> str:
    updated, count = re.subn(pattern, replacement, text, count=1, flags=re.S)
    if count != 1:
        raise RuntimeError(f'{label}: atteso 1 match, trovati {count}')
    return updated


# Dialogs use the dedicated pure feature service.
path = Path('lib/widgets/breeding/breeder_feature_dialogs.dart')
text = path.read_text(encoding='utf-8')
text = replace_once(
    text,
    "import '../../services/breeding_service.dart';",
    "import '../../services/breeder_feature_service.dart';",
    'dialog feature import',
)
text = text.replace(
    'BreedingService service = const BreedingService()',
    'BreederFeatureService service = const BreederFeatureService()',
)
if text.count('BreederFeatureService service = const BreederFeatureService()') != 2:
    raise RuntimeError('dialog feature service replacements incomplete')
path.write_text(text, encoding='utf-8')


# Breeding screen.
path = Path('lib/screens/breeding/breeding_screen.dart')
text = path.read_text(encoding='utf-8')
text = replace_once(
    text,
    "import '../../models/breeding_candidate.dart';",
    "import '../../models/bag_inventory_entry.dart';\nimport '../../models/breeding_candidate.dart';",
    'screen inventory model import',
)
text = replace_once(
    text,
    "import '../../repositories/breeding_egg_repository.dart';",
    "import '../../repositories/bag_inventory_repository.dart';\nimport '../../repositories/breeding_egg_repository.dart';\nimport '../../repositories/feat_repository.dart';",
    'screen repositories import',
)
text = replace_once(
    text,
    "import '../../services/breeding_service.dart';\nimport '../../services/pokemon_generator_service.dart';",
    "import '../../services/breeder_feature_service.dart';\nimport '../../services/breeding_service.dart';\nimport '../../services/trainer_path_passive_service.dart';",
    'screen services import',
)
text = replace_once(
    text,
    "import '../../widgets/navigation/home_leading_button.dart';",
    "import '../../widgets/breeding/breeder_feature_dialogs.dart';\nimport '../../widgets/navigation/home_leading_button.dart';",
    'screen breeder dialogs import',
)
text = replace_once(
    text,
    '''  final BreedingEggRepository _eggRepository = BreedingEggRepository();
  final BreedingDataService _dataService = BreedingDataService();
  final BreedingService _breedingService = const BreedingService();
  final PokemonGeneratorService _generator = const PokemonGeneratorService();''',
    '''  final BreedingEggRepository _eggRepository = BreedingEggRepository();
  final BagInventoryRepository _inventoryRepository = BagInventoryRepository();
  final FeatRepository _featRepository = FeatRepository();
  final BreedingDataService _dataService = BreedingDataService();
  final BreedingService _breedingService = const BreedingService();
  final BreederFeatureService _breederFeatures = const BreederFeatureService();''',
    'screen repository fields',
)
text = replace_once(
    text,
    '''      _eggRepository.getEggs(profile.id),
      _dataService.load(),''',
    '''      _eggRepository.getEggs(profile.id),
      _inventoryRepository.getInventory(profile.id),
      _featRepository.getFeatDescriptions(),
      _dataService.load(),''',
    'screen load futures',
)
text = replace_once(
    text,
    '''    var eggs = results[3] as List<BreedingEgg>;
    final unlockedPokeslots''',
    '''    var eggs = results[3] as List<BreedingEgg>;
    final inventory = results[4] as List<BagInventoryEntry>;
    final featDescriptions = results[5] as Map<String, String>;
    final unlockedPokeslots''',
    'screen load results',
)
text = replace_once(
    text,
    '    final speciesData = results[4] as Map<int, BreedingSpeciesData>;',
    '    final speciesData = results[6] as Map<int, BreedingSpeciesData>;',
    'screen species data index',
)
text = replace_once(
    text,
    '''      eggs: eggs,
      speciesData: speciesData,''',
    '''      eggs: eggs,
      speciesData: speciesData,
      inventory: inventory,
      featDescriptions: featDescriptions,''',
    'screen data return',
)

advanced_methods = r'''
  Future<void> _assignIncubator(
    _BreedingScreenData data,
    BreedingEgg egg,
    EggIncubator incubator,
  ) async {
    if (incubator == EggIncubator.none) return;
    if (egg.incubator != EggIncubator.none) {
      setState(() {
        _message =
            'Questo uovo ha già utilizzato un incubatore. Un incubatore perde efficacia dopo un solo uovo.';
      });
      return;
    }
    final itemId = incubator.inventoryItemId;
    if (itemId == null || data.inventoryQuantity(itemId) <= 0) {
      setState(() {
        _message =
            'Non hai un Incubatore ${incubator.label} nello Zaino.';
      });
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Usare Incubatore ${incubator.label}?'),
        content: const Text(
          'L’incubatore verrà consumato dallo Zaino e resterà assegnato a questo uovo. Non potrà essere recuperato o sostituito.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('ANNULLA'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('USA INCUBATORE'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;

    final consumed = await _inventoryRepository.consumeItem(
      profileId: data.profile.id,
      itemId: itemId,
    );
    if (!consumed) {
      await _reload(
        message: 'L’incubatore non è più disponibile nello Zaino.',
      );
      return;
    }
    await _eggRepository.saveEgg(
      data.profile.id,
      egg.copyWith(incubator: incubator),
    );
    await _reload(
      message:
          'Incubatore ${incubator.label} assegnato e consumato dallo Zaino.',
    );
  }

  Future<void> _customizeMasterTraits(
    _BreedingScreenData data,
    BreedingEgg egg,
  ) async {
    final base = data.catalogById[egg.speciesId];
    if (base == null) return;
    final customized = await showMasterTraitsDialog(
      context,
      egg: egg,
      pokemon: base,
      service: _breederFeatures,
    );
    if (!mounted || customized == null) return;
    await _eggRepository.saveEgg(data.profile.id, customized);
    await _reload(message: 'Scelte di Master of Traits salvate.');
  }

  Future<void> _editEggHp(
    _BreedingScreenData data,
    BreedingEgg egg,
  ) async {
    if (_teamSlotForEgg(data, egg) == null) {
      setState(() {
        _message =
            'I PF dell’uovo si gestiscono soltanto mentre viene trasportato in squadra.';
      });
      return;
    }
    final controller = TextEditingController(text: egg.currentHp.toString());
    final value = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifica PF dell’uovo'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'PF attuali (0-10)',
            helperText: 'Da manuale: CA 8 e 10 PF.',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ANNULLA'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(
              int.tryParse(controller.text.trim()),
            ),
            child: const Text('SALVA'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (!mounted || value == null) return;
    if (value < 0 || value > BreedingEgg.maxHitPoints) {
      setState(() => _message = 'I PF dell’uovo devono essere tra 0 e 10.');
      return;
    }
    if (value == 0) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('L’uovo viene distrutto'),
          content: const Text(
            'Il manuale stabilisce che un uovo viene distrutto quando raggiunge 0 PF. Questa operazione eliminerà definitivamente l’uovo.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('ANNULLA'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('DISTRUGGI UOVO'),
            ),
          ],
        ),
      );
      if (!mounted || confirmed != true) return;
      final slot = _teamSlotForEgg(data, egg);
      if (slot != null) {
        await _teamRepository.clearSlot(
          profileId: data.profile.id,
          slotIndex: slot.slotIndex,
        );
      }
      await _eggRepository.deleteEgg(data.profile.id, egg.id);
      await _reload(message: 'L’uovo è stato distrutto a 0 PF.');
      return;
    }
    await _eggRepository.saveEgg(
      data.profile.id,
      egg.copyWith(currentHp: value),
    );
    await _reload(message: 'PF dell’uovo aggiornati a $value/10.');
  }

'''
text = replace_once(
    text,
    '  Future<void> _advanceEgg(_BreedingScreenData data, BreedingEgg egg) async {',
    advanced_methods +
        '  Future<void> _advanceEgg(_BreedingScreenData data, BreedingEgg egg) async {',
    'insert advanced breeder methods',
)

old_hatch_setup = r'''    final pokemon = base.resolveVariant(
      formName: egg.formName,
      gender: egg.gender,
    );
    final level = max(1, pokemon.minLevelFound);
    final experience = LevelProgression.thresholdForLevel(level);
    final maxHp = _generator.maxHpFor(
      pokemon: pokemon,
      level: level,
      nature: egg.nature,
    );
    final loyalty = egg.carriedEntireIncubation ? 2 : 1;
    final eggSlot = _teamSlotForEgg(data, egg);
'''
new_hatch_setup = r'''    final pokemon = base.resolveVariant(
      formName: egg.formName,
      gender: egg.gender,
    );
    GoodGenesChoice? goodGenes;
    if (_breederFeatures.hasGoodGenes(data.profile)) {
      goodGenes = await showGoodGenesDialog(
        context,
        pokemon: pokemon,
        featDescriptions: data.featDescriptions,
        service: _breederFeatures,
      );
      if (!mounted || goodGenes == null) return;
    }

    final level = max(1, pokemon.minLevelFound);
    final experience = LevelProgression.thresholdForLevel(level);
    final loyalty = egg.carriedEntireIncubation ? 2 : 1;
    final eggSlot = _teamSlotForEgg(data, egg);
    final goodGenesBonuses = goodGenes?.abilityBonuses ?? const <String, int>{};
    final goodGenesFeats = goodGenes?.feat == null
        ? const <String>[]
        : <String>[goodGenes!.feat!];
    final previewSlot = TeamSlot(
      slotIndex: eggSlot?.slotIndex ?? 0,
      pokemonId: egg.speciesId,
      experience: experience,
      selectedMoves: egg.selectedMoves,
      gender: egg.gender,
      formName: egg.formName,
      nature: egg.nature,
      abilities: egg.ability == null ? const [] : [egg.ability!],
      feats: goodGenesFeats,
      customAbilityScores: goodGenesBonuses,
      loyalty: loyalty,
    );
    final maxHp = TrainerPathPassiveService.maxHp(
      profile: data.profile,
      pokemon: pokemon,
      slot: previewSlot,
      level: level,
    );
    final goodGenesNote = goodGenes == null
        ? ''
        : ' Good Genes: ${goodGenes.summary}.';
'''
text = replace_once(text, old_hatch_setup, new_hatch_setup, 'hatch good genes setup')
text = replace_once(
    text,
    '''          abilities: egg.ability == null ? const [] : [egg.ability!],
          loyalty: loyalty,''',
    '''          abilities: egg.ability == null ? const [] : [egg.ability!],
          feats: goodGenesFeats,
          customAbilityScores: goodGenesBonuses,
          loyalty: loyalty,''',
    'team hatch good genes',
)
text = replace_once(
    text,
    '''        abilities: egg.ability == null ? const [] : [egg.ability!],
        loyalty: loyalty,
        notes: egg.inheritedMoves.isEmpty
            ? 'Nato da un uovo nella Pensione Pokémon.'
            : 'Nato da un uovo nella Pensione Pokémon. Mosse ereditate: ${egg.inheritedMoves.join(', ')}.',''',
    '''        abilities: egg.ability == null ? const [] : [egg.ability!],
        feats: goodGenesFeats,
        customAbilityScores: goodGenesBonuses,
        loyalty: loyalty,
        notes: egg.inheritedMoves.isEmpty
            ? 'Nato da un uovo nella Pensione Pokémon.$goodGenesNote'
            : 'Nato da un uovo nella Pensione Pokémon. Mosse ereditate: ${egg.inheritedMoves.join(', ')}.$goodGenesNote',''',
    'pc hatch good genes',
)
text = replace_once(
    text,
    '''          '${_displayName(pokemon: pokemon, formName: egg.formName)} si è schiuso, $destination, con Lealtà +$loyalty.',''',
    '''          '${_displayName(pokemon: pokemon, formName: egg.formName)} si è schiuso, $destination, con Lealtà +$loyalty.${goodGenes == null ? '' : ' ${goodGenes.summary}.'}',''',
    'hatch message good genes',
)

text = replace_once(
    text,
    '''                _RulesCard(
                  profile: data.profile,
                  rollModifier: modifier,
                  incubationAdvantage: _breedingService.hasIncubationAdvantage(
                    data.profile,
                  ),
                ),''',
    '''                _RulesCard(
                  profile: data.profile,
                  rollModifier: modifier,
                  incubationAdvantage: _breedingService.hasIncubationAdvantage(
                    data.profile,
                  ),
                  goodGenes: _breederFeatures.hasGoodGenes(data.profile),
                  masterOfTraits: _breederFeatures.hasMasterOfTraits(
                    data.profile,
                  ),
                ),''',
    'rules card advanced flags',
)
text = replace_once(
    text,
    '''                       onDelete: () => _deleteEgg(data, egg),
                       onIncubatorChanged: (incubator) =>
                           _updateEgg(data, egg.copyWith(incubator: incubator)),
                       onMoveToDayCare: () => _moveEggToDayCare(data, egg),
                        onMoveToPc: () => _moveEggToPc(data, egg),
                       onMoveToTeam: () => _moveEggToTeam(data, egg),''',
    '''                       onDelete: () => _deleteEgg(data, egg),
                       incubatorQuantities: data.incubatorQuantities,
                       onIncubatorChanged: (incubator) =>
                           _assignIncubator(data, egg, incubator),
                       canCustomizeTraits: _breederFeatures.hasMasterOfTraits(
                         data.profile,
                       ),
                       onCustomizeTraits: () =>
                           _customizeMasterTraits(data, egg),
                       onEditHp: () => _editEggHp(data, egg),
                       onMoveToDayCare: () => _moveEggToDayCare(data, egg),
                       onMoveToPc: () => _moveEggToPc(data, egg),
                       onMoveToTeam: () => _moveEggToTeam(data, egg),''',
    'egg card advanced callbacks',
)

rules_class = r'''class _RulesCard extends StatelessWidget {
  const _RulesCard({
    required this.profile,
    required this.rollModifier,
    required this.incubationAdvantage,
    required this.goodGenes,
    required this.masterOfTraits,
  });

  final UserProfile profile;
  final int rollModifier;
  final bool incubationAdvantage;
  final bool goodGenes;
  final bool masterOfTraits;

  @override
  Widget build(BuildContext context) {
    final breeder = profile.trainerPath == 'Pokémon Breeder';
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'ALLEVAMENTO POKÉMON',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            const Text(
              'Servono Lealtà +2, sesso compatibile e un Gruppo Uova condiviso. Ditto ignora sesso e Gruppo Uova; Undiscovered non può riprodursi.',
            ),
            if (breeder || rollModifier != 0 || incubationAdvantage) ...[
              const SizedBox(height: 10),
              Text(
                'Pokémon Breeder: tiro di accoppiamento ${rollModifier >= 0 ? '+' : ''}$rollModifier${incubationAdvantage ? ' · vantaggio ai d100 di incubazione' : ''}.',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
            if (goodGenes) ...[
              const SizedBox(height: 6),
              const Text(
                'Good Genes: alla schiusa scegli 2 punti caratteristiche oppure un talento.',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
            if (masterOfTraits) ...[
              const SizedBox(height: 6),
              const Text(
                'Master of Traits: personalizza sesso, Natura, abilità e le Egg Moves ereditate prima della schiusa.',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CandidateDropdown'''
text = replace_regex(
    text,
    r'class _RulesCard extends StatelessWidget \{.*?\n\}\n\nclass _CandidateDropdown',
    rules_class,
    'replace rules card',
)

egg_card_class = r'''class _EggCard extends StatelessWidget {
  const _EggCard({
    required this.egg,
    required this.pokemon,
    required this.incubationAdvantage,
    required this.onAdvance,
    required this.onHatch,
    required this.teamSlotIndex,
    required this.canMoveToTeam,
    required this.onDelete,
    required this.incubatorQuantities,
    required this.onIncubatorChanged,
    required this.canCustomizeTraits,
    required this.onCustomizeTraits,
    required this.onEditHp,
    required this.onMoveToDayCare,
    required this.onMoveToPc,
    required this.onMoveToTeam,
  });

  final BreedingEgg egg;
  final Pokemon? pokemon;
  final bool incubationAdvantage;
  final VoidCallback onAdvance;
  final VoidCallback onHatch;
  final int? teamSlotIndex;
  final bool canMoveToTeam;
  final VoidCallback onDelete;
  final Map<EggIncubator, int> incubatorQuantities;
  final ValueChanged<EggIncubator> onIncubatorChanged;
  final bool canCustomizeTraits;
  final VoidCallback onCustomizeTraits;
  final VoidCallback onEditHp;
  final VoidCallback onMoveToDayCare;
  final VoidCallback onMoveToPc;
  final VoidCallback onMoveToTeam;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final incubatorLocked = egg.incubator != EggIncubator.none;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const EggAssetImage(size: 54),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        egg.isReady
                            ? 'Uovo pronto a schiudersi'
                            : 'Uovo di ${pokemon?.name ?? '#${egg.speciesId}'}',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      Text('Genitori: ${egg.parentNames.join(' + ')}'),
                      Text(
                        egg.isReady
                            ? 'Incubazione completata'
                            : '${egg.incubationRemaining}/${egg.hatchTime} punti rimanenti',
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Elimina uovo',
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: egg.progress, minHeight: 8),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(label: Text(egg.nature)),
                if (egg.gender != null) Chip(label: Text(egg.gender!)),
                if (egg.ability != null) Chip(label: Text(egg.ability!)),
                if (egg.masterTraitsCustomized)
                  const Chip(
                    avatar: Icon(Icons.auto_awesome, size: 18),
                    label: Text('Master of Traits'),
                  ),
              ],
            ),
            if (egg.inheritedMoves.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Mosse ereditate: ${egg.inheritedMoves.join(', ')}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
            if (canCustomizeTraits) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: onCustomizeTraits,
                icon: const Icon(Icons.tune),
                label: Text(
                  egg.masterTraitsCustomized
                      ? 'MODIFICA MASTER OF TRAITS'
                      : 'PERSONALIZZA CON MASTER OF TRAITS',
                ),
              ),
            ],
            const SizedBox(height: 10),
            DropdownButtonFormField<EggIncubator>(
              initialValue: egg.incubator,
              decoration: InputDecoration(
                labelText: 'Incubatore',
                border: const OutlineInputBorder(),
                isDense: true,
                helperText: incubatorLocked
                    ? 'Già utilizzato: non può essere recuperato o sostituito.'
                    : 'Selezionandolo, viene consumato dallo Zaino.',
              ),
              items: [
                for (final incubator in EggIncubator.values)
                  DropdownMenuItem(
                    value: incubator,
                    enabled: incubator == EggIncubator.none ||
                        incubator == egg.incubator ||
                        (incubatorQuantities[incubator] ?? 0) > 0,
                    child: Text(
                      incubator.extraD20 == 0
                          ? incubator.label
                          : '${incubator.label} (+${incubator.extraD20}d20) · Zaino ${(incubatorQuantities[incubator] ?? 0)}',
                    ),
                  ),
              ],
              onChanged: incubatorLocked
                  ? null
                  : (value) {
                      if (value != null) onIncubatorChanged(value);
                    },
            ),
            const SizedBox(height: 10),
            Card(
              margin: EdgeInsets.zero,
              color: colors.errorContainer.withValues(alpha: 0.45),
              child: ListTile(
                leading: const Icon(Icons.shield_outlined),
                title: Text(
                  'Integrità: ${egg.currentHp}/${BreedingEgg.maxHitPoints} PF · CA ${BreedingEgg.armorClass}',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                subtitle: Text(
                  teamSlotIndex == null
                      ? 'Fuori dalla squadra l’uovo è custodito e i PF non vengono gestiti.'
                      : 'Il manuale prevede che l’uovo venga distrutto a 0 PF. I danni sono inseriti manualmente.',
                ),
                trailing: teamSlotIndex == null
                    ? null
                    : IconButton(
                        tooltip: 'Modifica PF uovo',
                        onPressed: onEditHp,
                        icon: const Icon(Icons.edit_outlined),
                      ),
              ),
            ),
            const SizedBox(height: 10),
            Card(
              margin: EdgeInsets.zero,
              color: colors.surfaceContainerHighest,
              child: ListTile(
                leading: Icon(
                  egg.isInPc
                      ? Icons.computer_outlined
                      : teamSlotIndex == null
                      ? Icons.home_work_outlined
                      : Icons.group_outlined,
                ),
                title: Text(
                  egg.isInPc
                      ? 'PC Pokémon'
                      : teamSlotIndex == null
                      ? 'Pensione Pokémon'
                      : 'Squadra · Slot ${teamSlotIndex! + 1}',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                subtitle: Text(
                  egg.isInPc
                      ? 'L’incubazione è in pausa e l’uovo non occupa un Pokéslot.'
                      : egg.carriedEntireIncubation
                      ? 'Occupa un Pokéslot e nascerà con Lealtà +2.'
                      : 'Non ha trascorso tutta l’incubazione in squadra: Lealtà +1.',
                ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (teamSlotIndex == null)
                  OutlinedButton.icon(
                    onPressed: canMoveToTeam ? onMoveToTeam : null,
                    icon: const Icon(Icons.login),
                    label: Text(
                      canMoveToTeam
                          ? 'RITIRA IN SQUADRA'
                          : 'NESSUN POKÉSLOT LIBERO',
                    ),
                  ),
                if (teamSlotIndex != null || egg.isInDayCare)
                  OutlinedButton.icon(
                    onPressed: onMoveToPc,
                    icon: const Icon(Icons.computer_outlined),
                    label: const Text('DEPOSITA NEL PC'),
                  ),
                if (teamSlotIndex != null || egg.isInPc)
                  OutlinedButton.icon(
                    onPressed: onMoveToDayCare,
                    icon: const Icon(Icons.home_work_outlined),
                    label: const Text('SPOSTA IN PENSIONE'),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            if (egg.isInPc)
              FilledButton.icon(
                onPressed: null,
                icon: const Icon(Icons.pause_circle_outline),
                label: Text(
                  egg.isReady
                      ? 'RITIRA L’UOVO PER SCHIUDERLO'
                      : 'INCUBAZIONE IN PAUSA NEL PC',
                ),
              )
            else if (egg.isReady)
              FilledButton.icon(
                onPressed: onHatch,
                icon: const Icon(Icons.egg_alt_outlined),
                label: const Text('FAI SCHIUDERE'),
              )
            else
              FilledButton.icon(
                onPressed: onAdvance,
                icon: const Icon(Icons.calendar_today_outlined),
                label: Text(
                  incubationAdvantage
                      ? 'AVANZA INCUBAZIONE (2d100, migliore)'
                      : 'AVANZA INCUBAZIONE (1d100)',
                ),
              ),
            if (egg.isReady) ...[
              const SizedBox(height: 6),
              Text(
                egg.isInPc
                    ? 'Nel PC l’uovo resta conservato ma non può schiudersi.'
                    : teamSlotIndex == null
                    ? 'Alla schiusa il Pokémon verrà inviato al PC dalla Pensione.'
                    : 'Alla schiusa il Pokémon sostituirà l’uovo nello stesso Pokéslot.',
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BreedingScreenData'''
text = replace_regex(
    text,
    r'class _EggCard extends StatelessWidget \{.*?\n\}\n\nclass _BreedingScreenData',
    egg_card_class,
    'replace egg card',
)

data_class = r'''class _BreedingScreenData {
  const _BreedingScreenData({
    required this.profile,
    required this.catalog,
    required this.catalogById,
    required this.team,
    required this.candidates,
    required this.eggs,
    required this.speciesData,
    required this.inventory,
    required this.featDescriptions,
  });

  final UserProfile profile;
  final List<Pokemon> catalog;
  final Map<int, Pokemon> catalogById;
  final List<TeamSlot> team;
  final List<BreedingCandidate> candidates;
  final List<BreedingEgg> eggs;
  final Map<int, BreedingSpeciesData> speciesData;
  final List<BagInventoryEntry> inventory;
  final Map<String, String> featDescriptions;

  int inventoryQuantity(String itemId) {
    for (final entry in inventory) {
      if (entry.itemId == itemId) return entry.quantity;
    }
    return 0;
  }

  Map<EggIncubator, int> get incubatorQuantities => {
    for (final incubator in EggIncubator.values)
      incubator: incubator.inventoryItemId == null
          ? 0
          : inventoryQuantity(incubator.inventoryItemId!),
  };
}
'''
text = replace_regex(
    text,
    r'class _BreedingScreenData \{.*?\n\}\s*$',
    data_class,
    'replace breeding data class',
)
path.write_text(text, encoding='utf-8')


# Add incubators to the catalog without reformatting the large JSON file.
path = Path('assets/data_webapp/items.json')
text = path.read_text(encoding='utf-8')
if '"id": "egg-incubator-basic"' not in text:
    insertion = r''',
        {
            "id": "egg-incubator-basic",
            "name": "Incubatore Basic",
            "type": "trainer gear",
            "cost": 1000,
            "description": [
                "Si consuma quando viene assegnato a un uovo. Aggiunge 1d20 alla riduzione del contatore di incubazione."
            ],
            "media": {
                "sprite": "assets/textures/sprites/egg.png"
            }
        },
        {
            "id": "egg-incubator-plus",
            "name": "Incubatore Plus",
            "type": "trainer gear",
            "cost": 3000,
            "description": [
                "Si consuma quando viene assegnato a un uovo. Aggiunge 2d20 alla riduzione del contatore di incubazione."
            ],
            "media": {
                "sprite": "assets/textures/sprites/egg.png"
            }
        },
        {
            "id": "egg-incubator-super",
            "name": "Incubatore Super",
            "type": "trainer gear",
            "cost": 10000,
            "description": [
                "Si consuma quando viene assegnato a un uovo. Aggiunge 3d20 alla riduzione del contatore di incubazione."
            ],
            "media": {
                "sprite": "assets/textures/sprites/egg.png"
            }
        }'''
    closing = '\n\t]\n}'
    if closing not in text:
        raise RuntimeError('items.json closing marker not found')
    text = text.replace(closing, insertion + closing, 1)
path.write_text(text, encoding='utf-8')


# Changelog.
path = Path('CHANGELOG.md')
text = path.read_text(encoding='utf-8')
anchor = '- deposito delle uova nel PC Pokémon, con incubazione in pausa, ritiro in squadra e visualizzazione nel PC Box.'
addition = '- completamento del Trainer Path Pokémon Breeder: Good Genes alla schiusa, Master of Traits, incubatori consumabili dallo Zaino e integrità manuale delle uova secondo il manuale.'
if addition not in text:
    text = replace_once(text, anchor, anchor + '\n' + addition, 'changelog complete breeder')
path.write_text(text, encoding='utf-8')
