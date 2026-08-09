import '../models/master_battle_session.dart';
import '../localization/ui_text.dart';
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
      ..writeln(
        uiTextForLanguage(
          'POKÉDEX 5E ITA — RIEPILOGO FIGHT DEL MASTER',
          'TRAINER ATLAS 5E — MASTER FIGHT SUMMARY',
        ),
      )
      ..writeln(
        uiTextForLanguage('Esportato: $generatedAt', 'Exported: $generatedAt'),
      )
      ..writeln(
        uiTextForLanguage('Round: ${session.round}', 'Round: ${session.round}'),
      )
      ..writeln(
        uiTextForLanguage(
          'Allenatori PNG: ${session.participants.length}',
          'NPC Trainers: ${session.participants.length}',
        ),
      )
      ..writeln();

    buffer.writeln(uiTextForLanguage('INIZIATIVA', 'INITIATIVE'));
    if (session.initiativeEntries.isEmpty) {
      buffer.writeln(
        uiTextForLanguage(
          '- Nessun partecipante in iniziativa',
          '- No initiative entries',
        ),
      );
    } else {
      for (var index = 0; index < session.initiativeEntries.length; index++) {
        final entry = session.initiativeEntries[index];
        final current = index == session.turnIndex
            ? uiTextForLanguage(' ← TURNO ATTUALE', ' ← CURRENT TURN')
            : '';
        buffer.writeln('- ${entry.initiative}: ${entry.name}$current');
      }
    }

    for (final participant in session.participants) {
      buffer
        ..writeln()
        ..writeln(participant.displayName.toUpperCase())
        ..writeln(
          uiTextForLanguage(
            '${participant.rank} · limite attivi ${participant.activeLimit}',
            '${participant.rank} · active limit ${participant.activeLimit}',
          ),
        );
      if (participant.personality.trim().isNotEmpty) {
        buffer.writeln(
          uiTextForLanguage(
            'Personalità: ${participant.personality.trim()}',
            'Personality: ${participant.personality.trim()}',
          ),
        );
      }
      if (participant.tactics.trim().isNotEmpty) {
        buffer.writeln(
          uiTextForLanguage(
            'Tattiche: ${participant.tactics.trim()}',
            'Tactics: ${participant.tactics.trim()}',
          ),
        );
      }
      if (participant.rewardMoney > 0) {
        buffer.writeln(
          uiTextForLanguage(
            'Ricompensa: ₽${participant.rewardMoney}',
            'Reward: ₽${participant.rewardMoney}',
          ),
        );
      }
      if (participant.rewards.isNotEmpty) {
        buffer.writeln(
          uiTextForLanguage(
            'Oggetti: ${participant.rewards.join(', ')}',
            'Items: ${participant.rewards.join(', ')}',
          ),
        );
      }
      buffer.writeln(uiTextForLanguage('Squadra:', 'Team:'));

      for (final state in participant.team) {
        final pokemon = pokemonById[state.pokemon.pokemonId];
        final name = pokemon == null
            ? '#${state.pokemon.pokemonId}'
            : pokemonFormDisplayName(pokemon.name, state.pokemon.formName);
        final active = participant.activeSlotIndices.contains(state.slotIndex)
            ? uiTextForLanguage('ATTIVO', 'ACTIVE')
            : uiTextForLanguage('RISERVA', 'RESERVE');
        final fainted = state.isFainted
            ? uiTextForLanguage(' · ESAUSTO', ' · FAINTED')
            : '';
        final statuses = <String>[
          if (state.nonVolatileStatus != null) state.nonVolatileStatus!,
          ...(state.volatileStatuses.toList()..sort()),
        ];
        final statusText = statuses.isEmpty
            ? uiTextForLanguage('nessuno', 'none')
            : statuses.join(', ');
        buffer.writeln(
          uiTextForLanguage(
            '- [$active] $name Lv. ${state.pokemon.level} · PF ${state.currentHp}/${state.pokemon.maxHp}$fainted · Status: $statusText',
            '- [$active] $name Lv. ${state.pokemon.level} · HP ${state.currentHp}/${state.pokemon.maxHp}$fainted · Conditions: $statusText',
          ),
        );

        final moves = state.pokemon.selectedMoves;
        if (moves.isEmpty) {
          buffer.writeln(
            uiTextForLanguage('  Mosse: nessuna', '  Moves: none'),
          );
        } else {
          final pp = [
            for (final move in moves)
              '$move ${state.remainingPp.containsKey(move) ? state.remainingPp[move] : '?'} PP',
          ];
          buffer.writeln(
            uiTextForLanguage(
              '  Mosse: ${pp.join(' · ')}',
              '  Moves: ${pp.join(' · ')}',
            ),
          );
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
