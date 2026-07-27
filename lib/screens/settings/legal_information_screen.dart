import 'package:flutter/material.dart';

import '../../localization/ui_text.dart';
import '../../widgets/layout/responsive_content.dart';

enum LegalInformationSection { about, licenses, privacy }

class LegalInformationScreen extends StatelessWidget {
  const LegalInformationScreen({super.key, required this.section});

  final LegalInformationSection section;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_title(context))),
      body: ResponsiveContent(
        maxWidth: 820,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 36),
          children: _content(context),
        ),
      ),
    );
  }

  String _title(BuildContext context) {
    return switch (section) {
      LegalInformationSection.about => context.uiText(
        'Informazioni sull’app',
        'About the app',
      ),
      LegalInformationSection.licenses => context.uiText(
        'Licenze e attribuzioni',
        'Licenses and attributions',
      ),
      LegalInformationSection.privacy => context.uiText('Privacy', 'Privacy'),
    };
  }

  List<Widget> _content(BuildContext context) {
    return switch (section) {
      LegalInformationSection.about => _about(context),
      LegalInformationSection.licenses => _licenses(context),
      LegalInformationSection.privacy => _privacy(context),
    };
  }

  List<Widget> _about(BuildContext context) {
    return [
      const _DocumentHeader(
        icon: Icons.info_outline,
        title: 'Trainer Atlas 5e',
        subtitle: '1.3.2+8',
      ),
      const SizedBox(height: 20),
      _SectionTitle(context.uiText('PROGETTO', 'PROJECT')),
      _Paragraph(
        context.uiText(
          'Trainer Atlas 5e è un companion amatoriale e non ufficiale per campagne da tavolo. L’app è sviluppata in Flutter e conserva i dati di gioco principalmente sul dispositivo.',
          'Trainer Atlas 5e is an unofficial, fan-made companion for tabletop campaigns. The app is built with Flutter and stores game data primarily on the device.',
        ),
      ),
      _Paragraph(
        context.uiText(
          'Il progetto non è affiliato, sponsorizzato o approvato da Nintendo, Game Freak, Creatures Inc., The Pokémon Company o Wizards of the Coast.',
          'The project is not affiliated with, sponsored by or endorsed by Nintendo, Game Freak, Creatures Inc., The Pokémon Company or Wizards of the Coast.',
        ),
      ),
      const SizedBox(height: 16),
      _SectionTitle(context.uiText('CODICE SORGENTE', 'SOURCE CODE')),
      _Paragraph(
        context.uiText(
          'Il codice sorgente e la cronologia delle modifiche sono pubblicati nel repository GitHub del progetto:',
          'The source code and change history are published in the project GitHub repository:',
        ),
      ),
      const SelectableText(
        'https://github.com/RickCiaahd/Pokedex5e_ita',
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 16),
      _SectionTitle(context.uiText('STATO DELLA BETA', 'BETA STATUS')),
      _Paragraph(
        context.uiText(
          'La pubblicazione pubblica resta subordinata alla verifica finale di licenze, attribuzioni, asset, funzionamento offline, accessibilità e requisiti Google Play.',
          'Public release remains subject to the final review of licenses, attributions, assets, offline operation, accessibility and Google Play requirements.',
        ),
      ),
    ];
  }

  List<Widget> _licenses(BuildContext context) {
    return [
      _DocumentHeader(
        icon: Icons.balance_outlined,
        title: context.uiText(
          'Licenze e attribuzioni',
          'Licenses and attributions',
        ),
        subtitle: context.uiText(
          'Informazioni preliminari per la beta',
          'Preliminary beta information',
        ),
      ),
      const SizedBox(height: 20),
      _SectionTitle(context.uiText('CODICE DEL PROGETTO', 'PROJECT CODE')),
      _Paragraph(
        context.uiText(
          'Trainer Atlas 5e è distribuito come software libero secondo la GNU General Public License, versione 3 (GPL-3.0-only). Il repository deve accompagnare ogni distribuzione binaria con accesso al corrispondente codice sorgente.',
          'Trainer Atlas 5e is distributed as free software under the GNU General Public License, version 3 (GPL-3.0-only). Every binary distribution must provide access to the corresponding source code.',
        ),
      ),
      _Paragraph(
        context.uiText(
          'Il progetto deriva e rielabora funzionalità e dati del progetto open source Jerakin/Pokedex5E, pubblicato con licenza GPL-3.0.',
          'The project derives and reworks functionality and data from the open-source Jerakin/Pokedex5E project, published under GPL-3.0.',
        ),
      ),
      const SelectableText(
        'https://github.com/Jerakin/Pokedex5E',
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 16),
      _SectionTitle(context.uiText('CONTENUTI E ASSET', 'CONTENT AND ASSETS')),
      _Paragraph(
        context.uiText(
          'La GPL copre il software licenziabile, ma non concede diritti sui marchi, sui personaggi, sulle illustrazioni o sugli altri contenuti appartenenti a terzi.',
          'The GPL covers licensable software, but it does not grant rights over third-party trademarks, characters, illustrations or other content.',
        ),
      ),
      _Paragraph(
        context.uiText(
          'Pokémon, i nomi dei personaggi e le relative immagini appartengono ai rispettivi titolari. Dungeons & Dragons appartiene ai rispettivi titolari. Alcuni asset storici del progetto non hanno ancora una licenza di ridistribuzione verificata e devono essere sostituiti o autorizzati prima della beta pubblica.',
          'Pokémon, character names and related images belong to their respective owners. Dungeons & Dragons belongs to its respective owners. Some historical project assets do not yet have a verified redistribution license and must be replaced or authorised before the public beta.',
        ),
      ),
      const SizedBox(height: 16),
      _SectionTitle(
        context.uiText('PACCHETTI OPEN SOURCE', 'OPEN-SOURCE PACKAGES'),
      ),
      _Paragraph(
        context.uiText(
          'Flutter e i pacchetti usati dall’app mantengono le rispettive licenze. Usa il pulsante seguente per consultare gli avvisi generati dal framework.',
          'Flutter and the packages used by the app retain their respective licenses. Use the following button to view the notices generated by the framework.',
        ),
      ),
      const SizedBox(height: 8),
      FilledButton.tonalIcon(
        onPressed: () {
          showLicensePage(
            context: context,
            applicationName: 'Trainer Atlas 5e',
            applicationVersion: '1.3.2+8',
            applicationLegalese: context.uiText(
              'Software libero GPL-3.0-only. Progetto amatoriale e non ufficiale.',
              'GPL-3.0-only free software. Unofficial fan-made project.',
            ),
          );
        },
        icon: const Icon(Icons.description_outlined),
        label: Text(
          context.uiText(
            'MOSTRA LICENZE OPEN SOURCE',
            'SHOW OPEN-SOURCE LICENSES',
          ),
        ),
      ),
      const SizedBox(height: 16),
      _Paragraph(
        context.uiText(
          'L’inventario dettagliato e lo stato delle verifiche sono mantenuti nella cartella docs/compliance del repository.',
          'The detailed inventory and review status are maintained in the repository docs/compliance folder.',
        ),
      ),
    ];
  }

  List<Widget> _privacy(BuildContext context) {
    return [
      _DocumentHeader(
        icon: Icons.privacy_tip_outlined,
        title: context.uiText('Privacy', 'Privacy'),
        subtitle: context.uiText(
          'Bozza per la beta pubblica · 27 luglio 2026',
          'Public beta draft · 27 July 2026',
        ),
      ),
      const SizedBox(height: 20),
      _SectionTitle(context.uiText('DATI LOCALI', 'LOCAL DATA')),
      _Paragraph(
        context.uiText(
          'Profili, schede, squadre, inventari, Pokédex, raccolte e sessioni vengono salvati localmente sul dispositivo tramite Hive. Trainer Atlas 5e non richiede la creazione di un account.',
          'Profiles, sheets, teams, inventories, Pokédex progress, collections and sessions are stored locally on the device through Hive. Trainer Atlas 5e does not require an account.',
        ),
      ),
      _Paragraph(
        context.uiText(
          'La versione corrente non integra pubblicità, analytics, Crashlytics o sistemi di profilazione gestiti dallo sviluppatore.',
          'The current version does not integrate advertising, analytics, Crashlytics or developer-operated profiling systems.',
        ),
      ),
      const SizedBox(height: 16),
      _SectionTitle(
        context.uiText('ESPORTAZIONE E CONDIVISIONE', 'EXPORT AND SHARING'),
      ),
      _Paragraph(
        context.uiText(
          'Quando esporti o condividi un backup, un Pokémon, una squadra o un riepilogo, scegli volontariamente un’app o una destinazione esterna. Da quel momento il file è trattato dal servizio scelto e dalle sue condizioni.',
          'When you export or share a backup, creature, team or summary, you voluntarily choose an external app or destination. From that point the file is handled by the selected service and its terms.',
        ),
      ),
      const SizedBox(height: 16),
      _SectionTitle(
        context.uiText('CONNESSIONE DI RETE', 'NETWORK CONNECTION'),
      ),
      _Paragraph(
        context.uiText(
          'La versione corrente non carica immagini o dati di gioco da host remoti durante l’uso ordinario e la build Android non richiede il permesso Internet. I collegamenti a repository e documentazione sono riferimenti consultabili dall’utente e non vengono contattati automaticamente dall’app.',
          'The current version does not load game images or data from remote hosts during normal use, and the Android build does not require Internet permission. Repository and documentation links are references that users may consult and are not contacted automatically by the app.',
        ),
      ),
      const SizedBox(height: 16),
      _SectionTitle(
        context.uiText('CONTROLLO E CANCELLAZIONE', 'CONTROL AND DELETION'),
      ),
      _Paragraph(
        context.uiText(
          'Puoi esportare i dati dalla schermata Profili ed eliminare completamente un profilo non attivo. La disinstallazione dell’app rimuove normalmente i dati locali secondo il comportamento del sistema operativo, salvo copie o backup creati dall’utente.',
          'You can export data from the Profiles screen and completely delete a non-active profile. Uninstalling the app normally removes local data according to the operating system, except for copies or backups created by the user.',
        ),
      ),
      const SizedBox(height: 16),
      _SectionTitle(
        context.uiText('CONTATTI E AGGIORNAMENTI', 'CONTACT AND UPDATES'),
      ),
      _Paragraph(
        context.uiText(
          'Problemi e richieste possono essere aperti nel repository GitHub. Questa informativa verrà aggiornata prima della pubblicazione e ogni volta che cambieranno raccolta dati, servizi di rete o funzionalità di condivisione.',
          'Issues and requests can be opened in the GitHub repository. This notice will be updated before release and whenever data collection, network services or sharing features change.',
        ),
      ),
      const SelectableText(
        'https://github.com/RickCiaahd/Pokedex5e_ita/issues',
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
    ];
  }
}

class _DocumentHeader extends StatelessWidget {
  const _DocumentHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      color: colors.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 34, color: colors.onPrimaryContainer),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: colors.onPrimaryContainer,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(color: colors.onPrimaryContainer),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _Paragraph extends StatelessWidget {
  const _Paragraph(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(text, style: Theme.of(context).textTheme.bodyLarge),
    );
  }
}
