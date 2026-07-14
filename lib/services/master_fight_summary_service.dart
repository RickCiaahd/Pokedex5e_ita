import '../models/master_battle_session.dart';
import '../models/pokemon.dart';
import '../models/pokemon_form_choice.dart';

class MasterFightSummaryService {
  const MasterFightSummaryService();

  String build({
    required MasterBattleSession session,
    required Map<int, Pokemon> pokemonById,
    DateTime? exportedAt,
  }) {
    final generatedAt = exportedAt ?? DateTime.now();
    final buffer = StringBuffer()
      ..writeln('POKÉDEX 5E ITA — RIEPILOGO FIGHT DEL MASTER')
      ..writeln('Esportato: ${generatedAt.toIso8601String()}')
      ..writeln('Round: ${session.round}')
      ..writeln('Allenatori PNG: ${session.participants.length}')
      ..writeln();

    buffer.writeln('INIZIATIVA');
    if (session.initiativeEntries.isEmpty) {
      buffer.writeln('- Nessun partecipante in iniziativa');
    } else {
      for (var index = 0; index < session.initiativeEntries.length; index++) {
        final entry = session.initiativeEntries[index];
        final current = index == session.turnIndex ? ' ← TURNO ATTUALE' : '';
        buffer.writeln('- ${entry.initiative}: ${entry.name}$current');
      }
    }

    for (final participant in session.participants) {
      buffer
        ..writeln()
        ..writeln(participant.displayName.toUpperCase())
        ..writeln(
          '${participant.rank} · limite attivi ${participant.activeLimit}',
        );
      if (participant.personality.trim().isNotEmpty) {
        buffer.writeln('Personalità: ${participant.personality.trim()}');
      }
      if (participant.tactics.trim().isNotEmpty) {
        buffer.writeln('Tattiche: ${participant.tactics.trim()}');
      }
      if (participant.rewardMoney > 0) {
        buffer.writeln('Ricompensa: ₽${participant.rewardMoney}');
      }
      if (participant.rewards.isNotEmpty) {
        buffer.writeln('Oggetti: ${participant.rewards.join(', ')}');
      }
      buffer.writeln('Squadra:');

      for (final state in participant.team) {
        final pokemon = pokemonById[state.pokemon.pokemonId];
        final name = pokemon == null
            ? '#${state.pokemon.pokemonId}'
            : pokemonFormDisplayName(pokemon.name, state.pokemon.formName);
        final active = participant.activeSlotIndices.contains(state.slotIndex)
            ? 'ATTIVO'
            : 'RISERVA';
        final fainted = state.isFainted ? ' · ESAUSTO' : '';
        final statuses = <String>[
          if (state.nonVolatileStatus != null) state.nonVolatileStatus!,
          ...(state.volatileStatuses.toList()..sort()),
        ];
        final statusText = statuses.isEmpty ? 'nessuno' : statuses.join(', ');
        buffer.writeln(
          '- [$active] $name Lv. ${state.pokemon.level} · '
          'PF ${state.currentHp}/${state.pokemon.maxHp}$fainted · '
          'Status: $statusText',
        );

        final moves = state.pokemon.selectedMoves;
        if (moves.isEmpty) {
          buffer.writeln('  Mosse: nessuna');
        } else {
          final pp = [
            for (final move in moves)
              '$move ${state.remainingPp.containsKey(move) ? state.remainingPp[move] : '?'} PP',
          ];
          buffer.writeln('  Mosse: ${pp.join(' · ')}');
        }
      }
    }

    return buffer.toString().trimRight();
  }

  String fileName(MasterBattleSession session, {DateTime? exportedAt}) {
    final date = (exportedAt ?? DateTime.now())
        .toIso8601String()
        .split('T')
        .first;
    return 'pokedex-5e-fight-master-round-${session.round}-$date.txt';
  }
}
