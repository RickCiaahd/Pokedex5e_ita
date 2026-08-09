part of 'bag_screen.dart';

extension _BagScreenItemUse on _BagScreenState {
  Future<void> _useBagItem(_BagData data, _OwnedBagItem entry) async {
    final item = entry.item;

    if (item.type == 'tm') {
      await _useTm(data, entry);
      return;
    }

    if (item.type == 'medicine') {
      await _useMedicine(data, entry);
      return;
    }

    if (item.type == 'berry') {
      await _useBerry(data, entry);
      return;
    }

    if (item.type == 'held-item') {
      await _useHeldItem(data, entry);
      return;
    }

    await _reload(
      message: context.uiText(
        '${item.name} non è ancora utilizzabile dallo zaino.',
        '${item.name} cannot be used from the Bag yet.',
      ),
    );
  }

  Future<void> _useBerry(_BagData data, _OwnedBagItem entry) async {
    if (!_berryMedicineItemIds.contains(entry.item.id)) {
      await _reload(
        message: context.uiText(
          '${entry.item.name} può essere data a un Pokémon, ma non usata direttamente.',
          '${entry.item.name} can be given to a Pokémon, but cannot be used directly.',
        ),
      );
      return;
    }

    final candidates = <_MedicineCandidate>[];

    for (final slot in data.team) {
      final pokemonId = slot.pokemonId;
      if (pokemonId == null) continue;

      final basePokemon = data.pokemonById[pokemonId];
      if (basePokemon == null) continue;
      final pokemon = basePokemon.resolveVariant(
        formName: slot.effectiveFormName,
        gender: slot.gender,
      );

      candidates.add(_MedicineCandidate(slot: slot, pokemon: pokemon));
    }

    if (candidates.isEmpty) {
      await _reload(
        message: context.uiText(
          'Non hai Pokémon in squadra su cui usare ${entry.item.name}.',
          'There are no Pokémon in the team that can use ${entry.item.name}.',
        ),
      );
      return;
    }

    if (!mounted) return;

    final candidate = await showModalBottomSheet<_MedicineCandidate>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _MedicinePokemonPickerSheet(
        item: entry.item,
        candidates: candidates,
        maxHpBuilder: _maxHpFor,
      ),
    );

    if (!mounted || candidate == null) return;

    final result = _applyMedicine(
      item: entry.item,
      slot: candidate.slot,
      pokemon: candidate.pokemon,
    );

    final consumed = await _bagRepository.consumeItem(
      profileId: data.profile.id,
      itemId: entry.item.id,
    );
    if (!mounted) return;
    if (!consumed) {
      await _reload(
        message: context.uiText(
          'Non hai più ${entry.item.name} nello zaino.',
          'You have no more ${entry.item.name} in the Bag.',
        ),
      );
      return;
    }

    if (result != null) {
      await _teamRepository.updateSlot(
        profileId: data.profile.id,
        updatedSlot: result.updatedSlot,
      );
      await _reload(message: result.message);
      return;
    }

    await _reload(
      message: context.uiText(
        '${candidate.displayName} ha consumato ${entry.item.name}, ma non ha avuto effetto.',
        '${candidate.displayName} consumed ${entry.item.name}, but it had no effect.',
      ),
    );
  }

  Future<void> _useHeldItem(_BagData data, _OwnedBagItem entry) async {
    final candidates = <_HeldItemCandidate>[];

    for (final slot in data.team) {
      final pokemonId = slot.pokemonId;
      if (pokemonId == null) continue;

      final basePokemon = data.pokemonById[pokemonId];
      if (basePokemon == null) continue;
      final pokemon = basePokemon.resolveVariant(
        formName: slot.effectiveFormName,
        gender: slot.gender,
      );

      candidates.add(_HeldItemCandidate(slot: slot, pokemon: pokemon));
    }

    if (candidates.isEmpty) {
      await _reload(
        message: context.uiText(
          'Non hai Pokémon in squadra a cui dare ${entry.item.name}.',
          'There are no Pokémon in the team that can hold ${entry.item.name}.',
        ),
      );
      return;
    }

    if (!mounted) return;

    final candidate = await showModalBottomSheet<_HeldItemCandidate>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _HeldItemPokemonPickerSheet(
        item: entry.item,
        candidates: candidates,
        itemByReference: data.itemByReference,
      ),
    );

    if (!mounted || candidate == null) return;

    final previousItemReference = candidate.slot.heldItem;
    final previousItem = previousItemReference == null
        ? null
        : data.itemByReference(previousItemReference);

    if (previousItem?.id == entry.item.id) {
      await _reload(
        message: context.uiText(
          '${candidate.displayName} tiene già ${entry.item.name}.',
          '${candidate.displayName} is already holding ${entry.item.name}.',
        ),
      );
      return;
    }

    final consumed = await _bagRepository.consumeItem(
      profileId: data.profile.id,
      itemId: entry.item.id,
    );
    if (!mounted) return;
    if (!consumed) {
      await _reload(
        message: context.uiText(
          'Non hai più ${entry.item.name} nello zaino.',
          'You have no more ${entry.item.name} in the Bag.',
        ),
      );
      return;
    }

    if (previousItem != null) {
      await _bagRepository.addItem(
        profileId: data.profile.id,
        itemId: previousItem.id,
      );
    }

    await _teamRepository.updateSlot(
      profileId: data.profile.id,
      updatedSlot: candidate.slot.copyWith(heldItem: entry.item.id),
    );
    if (!mounted) return;

    final replacementText = previousItem == null
        ? ''
        : context.uiText(
            ' ${previousItem.name} è tornato nello zaino.',
            ' ${previousItem.name} was returned to the Bag.',
          );
    await _reload(
      message: context.uiText(
        '${candidate.displayName} ora tiene ${entry.item.name}.$replacementText',
        '${candidate.displayName} is now holding ${entry.item.name}.$replacementText',
      ),
    );
  }

  Future<void> _removeHeldItem(_BagData data, _EquippedHeldItem entry) async {
    await _bagRepository.addItem(
      profileId: data.profile.id,
      itemId: entry.item.id,
    );
    await _teamRepository.updateSlot(
      profileId: data.profile.id,
      updatedSlot: entry.slot.copyWith(heldItem: null),
    );
    if (!mounted) return;

    await _reload(
      message: context.uiText(
        '${entry.displayName} non tiene più ${entry.item.name}. L’oggetto è tornato nello zaino.',
        '${entry.displayName} is no longer holding ${entry.item.name}. The item was returned to the Bag.',
      ),
    );
  }

  Future<void> _useTm(_BagData data, _OwnedBagItem entry) async {
    final tmNumber = _tmNumberFromItemId(entry.item.id);
    if (tmNumber == null) {
      await _reload(
        message: context.uiText(
          context.uiText(
            'Questa MT non è collegata a una mossa valida.',
            'This TM is not linked to a valid move.',
          ),
          'This TM is not linked to a valid move.',
        ),
      );
      return;
    }

    final tmMap = await _tmRepository.getTmMap();
    if (!mounted) return;
    final tm = tmMap[tmNumber];
    if (tm == null) {
      await _reload(
        message: context.uiText(
          'Dati della MT non disponibili.',
          'TM data is unavailable.',
        ),
      );
      return;
    }

    final move = await _moveRepository.getMove(tm.moveId);
    if (!mounted) return;
    if (move == null) {
      await _reload(
        message: context.uiText(
          context.uiText(
            'Dati della mossa non disponibili.',
            'Move data is not available.',
          ),
          'Move data is unavailable.',
        ),
      );
      return;
    }

    final team = await _teamRepository.getTeam(data.profile.id);
    final pokemonList = await _pokemonRepository.getAllPokemon();
    if (!mounted) return;
    final pokemonById = {
      for (final pokemon in pokemonList) pokemon.id: pokemon,
    };
    final candidates = <_TmCandidate>[];

    for (final slot in team) {
      final pokemonId = slot.pokemonId;
      if (pokemonId == null) continue;

      final basePokemon = pokemonById[pokemonId];
      if (basePokemon == null) continue;
      final pokemon = basePokemon.resolveVariant(
        formName: slot.effectiveFormName,
        gender: slot.gender,
      );

      if (pokemon.moves.tmMoves.contains(tm.number)) {
        candidates.add(_TmCandidate(slot: slot, pokemon: pokemon));
      }
    }

    if (candidates.isEmpty) {
      await _reload(
        message: context.uiText(
          'Nessun Pokémon in squadra può imparare ${move.name} tramite ${entry.item.name}.',
          'No Pokémon in the team can learn ${move.name} from ${entry.item.name}.',
        ),
      );
      return;
    }

    if (!mounted) return;

    final candidate = await showModalBottomSheet<_TmCandidate>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _TmPokemonPickerSheet(
        item: entry.item,
        move: move,
        candidates: candidates,
      ),
    );

    if (!mounted || candidate == null) return;

    final selectedMoves = _normalizedMoves(candidate.slot.selectedMoves);
    if (_knowsMove(selectedMoves, move)) {
      final pokemonName = candidate.slot.nickname ?? candidate.pokemon.name;
      await _reload(
        message: context.uiText(
          context.uiText(
            '$pokemonName conosce già ${move.name}.',
            '$pokemonName already knows ${move.name}.',
          ),
          '$pokemonName already knows ${move.name}.',
        ),
      );
      return;
    }

    final learnedMoveReference = move.id;
    final updatedMoves = [...selectedMoves];
    String? replacedMoveName;

    if (updatedMoves.length < 4) {
      updatedMoves.add(learnedMoveReference);
    } else {
      final currentMoveData = <String, MoveData?>{};
      for (final reference in updatedMoves) {
        currentMoveData[reference] = await _moveRepository.getMove(reference);
      }

      if (!mounted) return;

      final replaceIndex = await showModalBottomSheet<int>(
        context: context,
        isScrollControlled: true,
        builder: (_) => _MoveReplaceSheet(
          pokemonName: candidate.slot.nickname ?? candidate.pokemon.name,
          newMove: move,
          selectedMoves: updatedMoves,
          moveData: currentMoveData,
        ),
      );

      if (!mounted || replaceIndex == null) return;

      replacedMoveName =
          currentMoveData[updatedMoves[replaceIndex]]?.name ??
          updatedMoves[replaceIndex];
      updatedMoves[replaceIndex] = learnedMoveReference;
    }

    final consumed = await _bagRepository.consumeItem(
      profileId: data.profile.id,
      itemId: entry.item.id,
    );
    if (!mounted) return;
    if (!consumed) {
      await _reload(
        message: context.uiText(
          'Non hai più ${entry.item.name} nello zaino.',
          'You have no more ${entry.item.name} in the Bag.',
        ),
      );
      return;
    }

    await _teamRepository.updateSlot(
      profileId: data.profile.id,
      updatedSlot: candidate.slot.copyWith(selectedMoves: updatedMoves),
    );

    final pokemonName = candidate.slot.nickname ?? candidate.pokemon.name;
    final replacementText = replacedMoveName == null
        ? ''
        : ' al posto di $replacedMoveName';
    await _reload(
      message:
          '$pokemonName ha imparato ${move.name}$replacementText usando ${entry.item.name}.',
    );
  }

  Future<void> _useMedicine(_BagData data, _OwnedBagItem entry) async {
    if (!_isSupportedMedicine(entry.item.id)) {
      await _reload(
        message: context.uiText(
          '${entry.item.name} non è ancora utilizzabile automaticamente.',
          '${entry.item.name} cannot be used automatically yet.',
        ),
      );
      return;
    }

    final team = await _teamRepository.getTeam(data.profile.id);
    final pokemonList = await _pokemonRepository.getAllPokemon();
    if (!mounted) return;
    final pokemonById = {
      for (final pokemon in pokemonList) pokemon.id: pokemon,
    };
    final candidates = <_MedicineCandidate>[];

    for (final slot in team) {
      final pokemonId = slot.pokemonId;
      if (pokemonId == null) continue;

      final pokemon = pokemonById[pokemonId];
      if (pokemon == null) continue;

      candidates.add(_MedicineCandidate(slot: slot, pokemon: pokemon));
    }

    if (candidates.isEmpty) {
      await _reload(
        message: context.uiText(
          'Non hai Pokémon in squadra su cui usare ${entry.item.name}.',
          'There are no Pokémon in the team that can use ${entry.item.name}.',
        ),
      );
      return;
    }

    if (!mounted) return;

    final candidate = await showModalBottomSheet<_MedicineCandidate>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _MedicinePokemonPickerSheet(
        item: entry.item,
        candidates: candidates,
        maxHpBuilder: _maxHpFor,
      ),
    );

    if (!mounted || candidate == null) return;

    final result = _applyMedicine(
      item: entry.item,
      slot: candidate.slot,
      pokemon: candidate.pokemon,
    );

    if (result == null) {
      await _reload(
        message:
            '${entry.item.name} non avrebbe effetto su ${candidate.displayName}.',
      );
      return;
    }

    final consumed = await _bagRepository.consumeItem(
      profileId: data.profile.id,
      itemId: entry.item.id,
    );
    if (!mounted) return;
    if (!consumed) {
      await _reload(
        message: context.uiText(
          'Non hai più ${entry.item.name} nello zaino.',
          'You have no more ${entry.item.name} in the Bag.',
        ),
      );
      return;
    }

    await _teamRepository.updateSlot(
      profileId: data.profile.id,
      updatedSlot: result.updatedSlot,
    );

    await _reload(message: result.message);
  }
}
