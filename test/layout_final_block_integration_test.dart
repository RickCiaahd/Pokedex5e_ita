import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('l’ultimo blocco layout copre combattimenti e strumenti del Master', () {
    final battle = File(
      'lib/screens/battle/battle_screen.dart',
    ).readAsStringSync();
    final master = File(
      'lib/screens/battle/npc_battle_screen.dart',
    ).readAsStringSync();
    final tools = File(
      'lib/screens/tools/tools_screen.dart',
    ).readAsStringSync();

    expect(battle, contains('maxWidth: 1280'));
    expect(battle, contains('actions: const [HomeAppBarAction()]'));
    expect(battle, contains('useSafeArea: true'));
    expect(battle, contains('scrollable: true'));

    expect(master, contains('maxWidth: 1320'));
    expect(master, contains('const HomeAppBarAction()'));
    expect(master, contains('PopupMenuButton<_FightSessionAction>'));
    expect(master, contains('scrollable: true'));

    expect(tools, contains('maxWidth: 1180'));
    expect(tools, contains('class _ToolCardGrid'));
    expect(tools, contains('constraints.maxWidth >= 760'));
    expect(tools, contains('constraints.maxWidth < 430'));
  });
}
