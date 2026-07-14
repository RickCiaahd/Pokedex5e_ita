from pathlib import Path


def replace_once(text: str, old: str, new: str, label: str) -> str:
    count = text.count(old)
    if count != 1:
        raise RuntimeError(f'{label}: attesa 1 occorrenza, trovate {count}')
    return text.replace(old, new, 1)


path = Path('lib/screens/breeding/breeding_screen.dart')
text = path.read_text(encoding='utf-8')
text = replace_once(
    text,
    "import '../../models/level_progression.dart';\nimport '../../models/pc_pokemon.dart';",
    "import '../../models/level_progression.dart';\nimport '../../models/pc_pokemon.dart';\nimport '../../models/trainer_progression.dart';",
    'import TrainerProgression',
)
text = replace_once(
    text,
    "    final catalog = results[0] as List<Pokemon>;\n    final team = results[1] as List<TeamSlot>;\n    final pc = results[2] as List<PcPokemon>;\n    final eggs = results[3] as List<BreedingEgg>;",
    "    final catalog = results[0] as List<Pokemon>;\n"
    "    var team = results[1] as List<TeamSlot>;\n"
    "    var pc = results[2] as List<PcPokemon>;\n"
    "    final eggs = results[3] as List<BreedingEgg>;\n"
    "    final unlockedPokeslots =\n"
    "        TrainerProgression.pokeslotsForLevel(profile.trainerLevel);\n"
    "    final occupiedLockedSlots = _breedingService.occupiedLockedTeamSlots(\n"
    "      team: team,\n"
    "      unlockedPokeslots: unlockedPokeslots,\n"
    "    );\n"
    "    if (occupiedLockedSlots.isNotEmpty) {\n"
    "      for (final slot in occupiedLockedSlots) {\n"
    "        await _pcRepository.depositTeamSlot(\n"
    "          profileId: profile.id,\n"
    "          slot: slot,\n"
    "        );\n"
    "        await _teamRepository.setPokemonInSlot(\n"
    "          profileId: profile.id,\n"
    "          slotIndex: slot.slotIndex,\n"
    "          pokemonId: null,\n"
    "        );\n"
    "      }\n"
    "      team = await _teamRepository.getTeam(profile.id);\n"
    "      pc = await _pcRepository.getPokemon(profile.id);\n"
    "    }",
    'recupero slot bloccati',
)
text = replace_once(
    text,
    "    final loyalty = egg.carriedEntireIncubation ? 2 : 1;\n    TeamSlot? emptySlot;\n    for (final slot in data.team) {\n      if (slot.pokemonId == null) {\n        emptySlot = slot;\n        break;\n      }\n    }",
    "    final loyalty = egg.carriedEntireIncubation ? 2 : 1;\n"
    "    final unlockedPokeslots = TrainerProgression.pokeslotsForLevel(\n"
    "      data.profile.trainerLevel,\n"
    "    );\n"
    "    final emptySlot = _breedingService.firstFreeUnlockedTeamSlot(\n"
    "      team: data.team,\n"
    "      unlockedPokeslots: unlockedPokeslots,\n"
    "    );",
    'scelta slot schiusa',
)
text = replace_once(
    text,
    "          '${_displayName(pokemon: pokemon, formName: egg.formName)} si è schiuso ed è stato aggiunto ${emptySlot == null ? 'al PC' : 'alla squadra'} con Lealtà +$loyalty.',",
    "          '${_displayName(pokemon: pokemon, formName: egg.formName)} si è schiuso ed è stato aggiunto ${emptySlot == null ? 'al PC perché tutti i Pokéslot sbloccati sono occupati' : 'alla squadra'} con Lealtà +$loyalty.',",
    'messaggio destinazione schiusa',
)
path.write_text(text, encoding='utf-8')
