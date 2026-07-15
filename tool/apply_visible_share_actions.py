from pathlib import Path


def replace_once(path_value: str, old: str, new: str, label: str) -> None:
    path = Path(path_value)
    text = path.read_text(encoding='utf-8')
    count = text.count(old)
    if count != 1:
        raise SystemExit(f'{label}: attesa 1 occorrenza, trovate {count}')
    path.write_text(text.replace(old, new, 1), encoding='utf-8')


replace_once(
    'lib/screens/team/team_selection_screen.dart',
    """        actions: [
          PopupMenuButton<_TeamTransferAction>(
""",
    """        actions: [
          IconButton(
            onPressed: _isBusy || _isLoading ? null : _shareTeam,
            tooltip: 'Condividi squadra',
            icon: const Icon(Icons.ios_share_outlined),
          ),
          PopupMenuButton<_TeamTransferAction>(
""",
    'pulsante squadra',
)

replace_once(
    'lib/screens/team/team_selection_screen.dart',
    """              slot.isEgg
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
""",
    """              slot.isEgg
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
""",
    'pulsante Pokémon',
)

replace_once(
    'lib/screens/tools/encounter_library_screen.dart',
    """                  PopupMenuButton<String>(
                    enabled: !isBusy,
""",
    """                  IconButton(
                    onPressed: isBusy ? null : onShare,
                    tooltip: 'Condividi incontro',
                    icon: const Icon(Icons.ios_share_outlined),
                  ),
                  PopupMenuButton<String>(
                    enabled: !isBusy,
""",
    'pulsante incontro',
)

replace_once(
    'lib/screens/tools/npc_trainer_library_screen.dart',
    """                PopupMenuButton<String>(
                  enabled: !disabled,
""",
    """                IconButton(
                  onPressed: disabled ? null : onShare,
                  tooltip: 'Condividi Allenatore',
                  icon: const Icon(Icons.ios_share_outlined),
                ),
                PopupMenuButton<String>(
                  enabled: !disabled,
""",
    'pulsante Allenatore PNG',
)

replace_once(
    'CHANGELOG.md',
    """- Pokémon, squadre, incontri, Allenatori PNG e riepiloghi del Fight del Master possono essere condivisi tramite il menu nativo del dispositivo, con fallback al download sul Web.
""",
    """- Pokémon, squadre, incontri, Allenatori PNG e riepiloghi del Fight del Master possono essere condivisi tramite il menu nativo del dispositivo, con fallback al download sul Web;
- le azioni di condivisione principali sono ora visibili direttamente nelle barre e nelle schede, senza dover aprire il menu con i tre puntini.
""",
    'changelog',
)

print('Azioni di condivisione rese visibili.')
