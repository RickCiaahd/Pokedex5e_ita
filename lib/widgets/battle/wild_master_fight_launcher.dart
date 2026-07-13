import 'package:flutter/material.dart';

import '../../models/generated_encounter.dart';
import '../../models/pokemon.dart';
import '../../repositories/master_battle_session_repository.dart';
import '../../services/master_battle_service.dart';
import '../../screens/battle/npc_battle_screen.dart';

Future<bool> launchWildMasterFight({
  required BuildContext context,
  required String profileId,
  required GeneratedEncounter encounter,
  required List<Pokemon> catalog,
}) async {
  if (encounter.members.isEmpty) {
    throw const FormatException(
      'L’incontro non contiene Pokémon da aggiungere al fight.',
    );
  }

  final repository = MasterBattleSessionRepository();
  final hasActiveFight = await repository.hasSession(profileId);
  if (!context.mounted) return false;

  if (hasActiveFight) {
    final replace = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sostituire il fight attivo?'),
        content: const Text(
          'È già presente una sessione del Master. Avviandone una nuova perderai PF, PP, status, round e iniziativa della sessione corrente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Nuovo fight'),
          ),
        ],
      ),
    );
    if (replace != true || !context.mounted) return false;
  }

  final activeCount = await _showWildFightSetupDialog(
    context: context,
    memberCount: encounter.members.length,
    suggestedActiveCount: encounter.party.activePokemon,
  );
  if (activeCount == null || !context.mounted) return false;

  final session = const MasterBattleService().createWildSession(
    profileId: profileId,
    encounter: encounter,
    activeCount: activeCount,
    catalog: catalog,
  );
  await repository.saveSession(session);
  if (!context.mounted) return false;

  await Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => NpcBattleScreen(
        profileId: profileId,
        catalog: catalog,
        initialSession: session,
      ),
    ),
  );
  return true;
}

Future<int?> _showWildFightSetupDialog({
  required BuildContext context,
  required int memberCount,
  required int suggestedActiveCount,
}) {
  var activeCount = suggestedActiveCount.clamp(1, memberCount).toInt();

  return showDialog<int>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: const Text('Prepara il fight selvatico'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '$memberCount Pokémon verranno copiati nel Fight del Master. L’incontro e la Libreria Allenatori PNG non saranno modificati.',
              ),
              const SizedBox(height: 18),
              const Text(
                'Pokémon attivi contemporaneamente',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                initialValue: activeCount,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: [
                  for (var value = 1; value <= memberCount; value++)
                    DropdownMenuItem(value: value, child: Text('$value')),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setDialogState(() => activeCount = value);
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Annulla'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(dialogContext).pop(activeCount),
            icon: const Icon(Icons.sports_mma_outlined),
            label: const Text('Avvia fight'),
          ),
        ],
      ),
    ),
  );
}
