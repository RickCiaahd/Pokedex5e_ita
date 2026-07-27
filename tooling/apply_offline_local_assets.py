from __future__ import annotations

import re
from pathlib import Path
from textwrap import dedent


def replace_once(text: str, old: str, new: str, label: str) -> str:
    count = text.count(old)
    if count != 1:
        raise RuntimeError(f"{label}: attesa 1 occorrenza, trovate {count}")
    return text.replace(old, new, 1)


def update_bag_item_model() -> None:
    path = Path("lib/models/bag_item.dart")
    text = path.read_text(encoding="utf-8")

    text, count = re.subn(
        r"\n  List<String> get spriteUrls \{.*?\n  \}\n\n  factory BagItem\.fromWebJson",
        "\n\n  factory BagItem.fromWebJson",
        text,
        count=1,
        flags=re.S,
    )
    if count != 1:
        raise RuntimeError("bag_item.dart: blocco degli URL remoti non trovato")

    text, count = re.subn(
        r"\n  static String _poke5eAssetUrl\(String path\) \{.*?\n  \}\n",
        "\n",
        text,
        count=1,
        flags=re.S,
    )
    if count != 1:
        raise RuntimeError("bag_item.dart: helper poke5e remoto non trovato")

    text, count = re.subn(
        r"\n  static const Map<String, String> _fallbackSpritePathById = \{.*?\n  \};\n\n"
        r"  static const Map<String, String> _fallbackSpritePathByType = \{.*?\n  \};\n",
        "\n",
        text,
        count=1,
        flags=re.S,
    )
    if count != 1:
        raise RuntimeError("bag_item.dart: mappe fallback remote non trovate")

    for token in (
        "poke5e.app",
        "raw.githubusercontent.com",
        "remoteSpriteUrl",
        "spriteUrls",
    ):
        if token in text:
            raise RuntimeError(f"bag_item.dart conserva ancora {token}")

    path.write_text(text, encoding="utf-8")


def localize_item_images() -> None:
    paths = [
        Path("lib/screens/bag/bag_screen.dart"),
        Path("lib/screens/battle/battle_screen.dart"),
        Path("lib/screens/pokemon/pokemon_detail_screen_legacy.dart"),
    ]

    for path in paths:
        text = path.read_text(encoding="utf-8")
        if text.count("Image.network(") != 1:
            raise RuntimeError(f"{path}: loader remoto inatteso")

        text = replace_once(
            text,
            "final remoteUrl = item.remoteSpriteUrl;",
            "final assetPath = item.spriteAssetPath;",
            f"{path}: variabile sprite",
        )
        text = replace_once(
            text,
            "if (remoteUrl == null)",
            "if (assetPath == null || !assetPath.startsWith('assets/'))",
            f"{path}: controllo sprite",
        )
        text = replace_once(
            text,
            "Image.network(\n        remoteUrl,",
            "Image.asset(\n        assetPath,",
            f"{path}: loader sprite",
        )

        text, loading_count = re.subn(
            r"\n\s*loadingBuilder: \(context, child, loadingProgress\) \{\s*"
            r"if \(loadingProgress == null\) return child;\s*return .*?;\s*\},",
            "",
            text,
            count=1,
            flags=re.S,
        )
        if loading_count != 1:
            raise RuntimeError(f"{path}: loadingBuilder remoto non trovato")

        if "Image.network(" in text or "remoteSpriteUrl" in text:
            raise RuntimeError(f"{path}: riferimenti remoti residui")

        path.write_text(text, encoding="utf-8")


def remove_android_internet_permission() -> None:
    path = Path("android/app/src/main/AndroidManifest.xml")
    text = path.read_text(encoding="utf-8")
    text = replace_once(
        text,
        '    <uses-permission android:name="android.permission.INTERNET" />\n\n',
        "",
        "AndroidManifest: permesso Internet",
    )
    path.write_text(text, encoding="utf-8")


def update_legal_information() -> None:
    path = Path("lib/screens/settings/legal_information_screen.dart")
    text = path.read_text(encoding="utf-8")
    text = replace_once(
        text,
        "Android dichiara attualmente il permesso Internet. Alcune schermate conservano fallback remoti per immagini mancanti: una richiesta a un host esterno può comunicare al gestore del servizio dati tecnici ordinari, come indirizzo IP e user agent. Questo comportamento deve essere eliminato o documentato definitivamente prima della beta.",
        "La versione corrente non carica immagini o dati di gioco da host remoti durante l’uso ordinario e la build Android non richiede il permesso Internet. I collegamenti a repository e documentazione sono riferimenti consultabili dall’utente e non vengono contattati automaticamente dall’app.",
        "privacy italiana offline",
    )
    text = replace_once(
        text,
        "Android currently declares Internet permission. Some screens retain remote fallbacks for missing images: a request to an external host may disclose ordinary technical data, such as IP address and user agent, to that service. This behaviour must be removed or fully documented before beta.",
        "The current version does not load game images or data from remote hosts during normal use, and the Android build does not require Internet permission. Repository and documentation links are references that users may consult and are not contacted automatically by the app.",
        "privacy inglese offline",
    )
    path.write_text(text, encoding="utf-8")


def update_readme() -> None:
    path = Path("README.md")
    text = path.read_text(encoding="utf-8")
    marker = (
        "I dati applicativi sono salvati localmente tramite Hive. La schermata Profili permette di esportare e importare backup JSON, compresi squadra, Pokémon Center, inventario, impostazioni e sessioni di combattimento supportate."
    )
    replacement = marker + (
        " Le immagini e i dati di gioco usati durante il normale funzionamento vengono risolti dagli asset inclusi nel pacchetto; la build Android non richiede il permesso Internet."
    )
    text = replace_once(text, marker, replacement, "README: funzionamento offline")
    path.write_text(text, encoding="utf-8")


def write_offline_audit() -> None:
    Path("docs/compliance").mkdir(parents=True, exist_ok=True)
    content = dedent(
        """\
        # Audit del funzionamento offline

        Stato: controllo tecnico automatico introdotto per la roadmap #129.

        ## Risultato del blocco

        - gli sprite degli oggetti vengono caricati esclusivamente da `spriteAssetPath` e da asset inclusi nel bundle;
        - sono stati rimossi i fallback verso `poke5e.app` e `raw.githubusercontent.com`;
        - `Image.network` non viene più usato dal codice applicativo;
        - il manifest Android principale non richiede `android.permission.INTERNET`;
        - un test verifica che ogni percorso locale dichiarato per gli sprite degli oggetti sia incluso nell'AssetManifest;
        - un controllo sorgente impedisce di reintrodurre loader di immagini remote o host di fallback noti.

        ## Funzioni che possono coinvolgere applicazioni esterne

        Esportazione, condivisione e selezione di file avvengono soltanto su iniziativa dell'utente tramite i picker o il menu di condivisione del sistema operativo. Trainer Atlas 5e non invia automaticamente profili, backup o telemetria a un server dello sviluppatore.

        ## Verifiche manuali ancora consigliate

        1. installare una build release su un dispositivo in modalità aereo;
        2. aprire Pokédex, squadra, PC, Zaino, allevamento e strumenti del Master;
        3. verificare artwork, sprite, tipi e icone di stato;
        4. creare, chiudere e riprendere una battaglia;
        5. riavviare l'app e verificare la persistenza dei dati;
        6. controllare che soltanto condivisione ed esportazione richiedano un'app esterna scelta dall'utente.

        Il test manuale su dispositivi reali resta necessario prima della beta pubblica.
        """
    )
    Path("docs/compliance/offline-audit.md").write_text(content, encoding="utf-8")


def write_offline_test() -> None:
    content = dedent(
        """\
        import 'dart:io';

        import 'package:flutter/services.dart';
        import 'package:flutter_test/flutter_test.dart';
        import 'package:pokedex_5e_ita/repositories/item_repository.dart';

        void main() {
          TestWidgetsFlutterBinding.ensureInitialized();

          test('il codice applicativo non usa loader di immagini remoti', () {
            const sourcePaths = <String>[
              'lib/models/bag_item.dart',
              'lib/screens/bag/bag_screen.dart',
              'lib/screens/battle/battle_screen.dart',
              'lib/screens/pokemon/pokemon_detail_screen_legacy.dart',
            ];

            for (final path in sourcePaths) {
              final source = File(path).readAsStringSync();
              expect(source, isNot(contains('Image.network(')), reason: path);
              expect(source, isNot(contains('NetworkImage(')), reason: path);
              expect(source, isNot(contains('poke5e.app')), reason: path);
              expect(source, isNot(contains('raw.githubusercontent.com')), reason: path);
              expect(source, isNot(contains('remoteSpriteUrl')), reason: path);
            }

            final manifest = File(
              'android/app/src/main/AndroidManifest.xml',
            ).readAsStringSync();
            expect(manifest, isNot(contains('android.permission.INTERNET')));
          });

          test('gli sprite locali degli oggetti sono inclusi nel bundle', () async {
            final assetManifest = await AssetManifest.loadFromAssetBundle(rootBundle);
            final bundledAssets = assetManifest.listAssets().toSet();
            final items = await ItemRepository().getWebItems();
            final errors = <String>[];

            for (final item in items) {
              final path = item.spriteAssetPath;
              if (path == null || path.trim().isEmpty) continue;
              if (!path.startsWith('assets/')) {
                errors.add('${item.id}: percorso non locale $path');
              } else if (!bundledAssets.contains(path)) {
                errors.add('${item.id}: asset non incluso $path');
              }
            }

            expect(errors, isEmpty, reason: errors.join('\\n'));
          });
        }
        """
    )
    Path("test/offline_operation_test.dart").write_text(content, encoding="utf-8")


def main() -> None:
    update_bag_item_model()
    localize_item_images()
    remove_android_internet_permission()
    update_legal_information()
    update_readme()
    write_offline_audit()
    write_offline_test()
    print("Migrazione offline completata.")


if __name__ == "__main__":
    main()
