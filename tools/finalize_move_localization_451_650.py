import json
import re
from pathlib import Path

OVERLAY_PATHS = [
    Path('assets/data/move_localization_it_451_500.json'),
    Path('assets/data/move_localization_it_501_550.json'),
    Path('assets/data/move_localization_it_551_600.json'),
    Path('assets/data/move_localization_it_601_650.json'),
]


def tidy_text(text: str) -> str:
    value = text
    replacements = {
        'contro il CD della mossa': 'contro la tua CD della mossa',
        'contro CD della mossa': 'contro la tua CD della mossa',
        'il caratteristica della mossa': 'la caratteristica della mossa',
        'danni a terra': 'danni di tipo Terra',
        'danno a terra': 'danni di tipo Terra',
        'danni del drago': 'danni di tipo Drago',
        'danno del drago': 'danni di tipo Drago',
        'danni da drago': 'danni di tipo Drago',
        'danno da drago': 'danni di tipo Drago',
        'danni da normale': 'danni di tipo Normale',
        'danno da normale': 'danni di tipo Normale',
        'danni da fata': 'danni di tipo Folletto',
        'danno da fata': 'danni di tipo Folletto',
        'danni da fantasma': 'danni di tipo Spettro',
        'danno da fantasma': 'danni di tipo Spettro',
        'danni da insetto': 'danni di tipo Coleottero',
        'danno da insetto': 'danni di tipo Coleottero',
        'danni da elettrico': 'danni di tipo Elettro',
        'danno da elettrico': 'danni di tipo Elettro',
        'tipo normale': 'tipo Normale',
        'tipo fuoco': 'tipo Fuoco',
        'tipo acqua': 'tipo Acqua',
        'tipo elettrico': 'tipo Elettro',
        'tipo erba': 'tipo Erba',
        'tipo ghiaccio': 'tipo Ghiaccio',
        'tipo lotta': 'tipo Lotta',
        'tipo veleno': 'tipo Veleno',
        'tipo terra': 'tipo Terra',
        'tipo volante': 'tipo Volante',
        'tipo psico': 'tipo Psico',
        'tipo coleottero': 'tipo Coleottero',
        'tipo roccia': 'tipo Roccia',
        'tipo spettro': 'tipo Spettro',
        'tipo drago': 'tipo Drago',
        'tipo buio': 'tipo Buio',
        'tipo acciaio': 'tipo Acciaio',
        'tipo folletto': 'tipo Folletto',
        'la metà di quel danni': 'la metà di quei danni',
        'un ulteriore 10 piedi': 'altri 10 piedi',
        "un'ulteriore 10 piedi": 'altri 10 piedi',
        'senza invocare un attacco di opportunità': 'senza provocare attacchi di opportunità',
        'senza effettuare un attacco di opportunità': 'senza provocare attacchi di opportunità',
        'punteggi delle abilità': 'punteggi di caratteristica',
        'punteggi di abilità': 'punteggi di caratteristica',
        'punti salute': 'valori di salute',
        'salute massima': 'salute massima',
        'la tua creatura': "l'utilizzatore",
        'del tuo CA': 'della tua CA',
        'al tuo CA': 'alla tua CA',
        'le creature CA': 'la CA della creatura',
        'a CA': 'alla CA',
        'per movimento': 'per mossa',
        'controlli di Forza': 'prove di FOR',
        'in un cono 15 piedi': 'in un cono di 15 piedi',
        'in un raggio 20 piedi': 'in un raggio di 20 piedi',
        'in un raggio 30 piedi': 'in un raggio di 30 piedi',
        'in un raggio 60 piedi': 'in un raggio di 60 piedi',
        'un tiro di attacco naturale': 'un tiro per colpire naturale',
        'un tiro di attacco': 'un tiro per colpire',
        'tiro di attacco naturale': 'tiro per colpire naturale',
        'ripetendo il salvataggio CAR': 'ripetendo il tiro salvezza su CAR',
        'ripetendo il salvataggio COS': 'ripetendo il tiro salvezza su COS',
        'ripetendo il salvataggio SAG': 'ripetendo il tiro salvezza su SAG',
        'ripetendo il salvataggio DES': 'ripetendo il tiro salvezza su DES',
        'In caso di colpo,': 'Se colpisci,',
        'in caso di colpo,': 'se colpisci,',
        'viene avvelenato': 'diventa avvelenato',
        'viene avvelenata': 'diventa avvelenata',
        'viene congelato': 'diventa congelato',
        'viene congelata': 'diventa congelata',
        'viene paralizzato': 'diventa paralizzato',
        'viene paralizzata': 'diventa paralizzata',
        'viene addormentato': 'si addormenta',
        'viene addormentata': 'si addormenta',
    }
    for source, target in replacements.items():
        value = value.replace(source, target)

    value = re.sub(
        r'((?:Tutte le|Le) creature[^.]*?) se lo fallisce',
        r'\1 se lo falliscono',
        value,
    )
    value = re.sub(
        r'((?:Tutte le|Le) creature[^.]*?) se lo supera',
        r'\1 se lo superano',
        value,
    )
    value = value.replace('se lo falliscono, o la metà se lo supera', 'se lo falliscono, o la metà se lo superano')
    value = value.replace('se lo falliscono, o metà se lo supera', 'se lo falliscono, o metà se lo superano')
    value = value.replace('Se colpisci, se il bersaglio', 'Se colpisci e il bersaglio')
    value = value.replace('Se colpisci, il bersaglio', 'Se colpisci, il bersaglio')
    value = value.replace(' .', '.')
    value = re.sub(r'\s+([,.;:])', r'\1', value)
    return value


def tidy_value(value):
    if isinstance(value, str):
        return tidy_text(value)
    if isinstance(value, list):
        return [tidy_value(item) for item in value]
    if isinstance(value, dict):
        return {key: tidy_value(item) for key, item in value.items()}
    return value


SPECIAL_DESCRIPTIONS = {
    'misty-explosion': [
        "Scateni un'esplosione in un raggio di 30 piedi e vai immediatamente KO prima che vengano inflitti i danni. Ogni creatura nell'area deve effettuare un tiro salvezza su DES contro la tua CD della mossa. Se l'utilizzatore aveva almeno metà dei suoi PF rimanenti oppure la mossa è stata usata su Campo Nebbioso, una creatura subisce 5d6 + MOVE danni di tipo Folletto se fallisce il tiro salvezza, o la metà se lo supera. Se l'utilizzatore aveva meno di metà dei suoi PF e non si trovava su Campo Nebbioso, subisce invece metà dei danni se fallisce il tiro salvezza e un quarto se lo supera."
    ],
    'misty-terrain': [
        "Ricopri il terreno con una nebbia sottile e curativa in un cerchio del raggio di 60 piedi centrato su di te. Per 3 turni, le creature a terra nella nebbia non possono subire nuove condizioni di stato. Sono considerate a terra le creature prive di velocità di volo, Levitazione, Magnetascesa o capacità simili. Inoltre, le creature a terra hanno resistenza ai danni di tipo Drago; se erano vulnerabili a tali danni, li subiscono invece normalmente."
    ],
    'moongeist-beam': [
        "Emetti un raggio sinistro in una linea lunga 100 piedi e larga 5 piedi. Ogni creatura nella linea deve effettuare un tiro salvezza su DES contro la tua CD della mossa, subendo 5d6 + MOVE danni di tipo Spettro se lo fallisce, o la metà se lo supera. Questa mossa ignora le abilità della creatura che impedirebbero all'utilizzatore di colpire o di infliggere danni completi."
    ],
    'mortal-spin': [
        "Ruoti a velocità incredibile. Ogni creatura entro la tua portata in mischia deve effettuare un tiro salvezza su DES contro la tua CD della mossa, subendo 1d4 + MOVE danni di tipo Veleno e diventando avvelenata se lo fallisce, o la metà dei danni se lo supera.",
        "Prima del tiro salvezza, questa mossa libera automaticamente l'utilizzatore da Parassiseme e da qualunque effetto che lo renda afferrato o trattenuto."
    ],
    'mountain-gale': [
        "Scagli enormi blocchi di ghiaccio contro il bersaglio. Effettua un attacco a distanza, infliggendo 4d4 + MOVE danni di tipo Ghiaccio se colpisci. Il bersaglio deve inoltre superare un tiro salvezza su COS contro la tua CD della mossa o diventare FLINCHED."
    ],
    'mud-bomb': [
        "Scagli una sfera compatta di fango contro una creatura. Effettua un attacco a distanza, infliggendo 1d10 + MOVE danni di tipo Terra se colpisci. Il bersaglio deve quindi effettuare un tiro salvezza su COS contro la tua CD della mossa. Se lo fallisce, ha svantaggio al suo prossimo tiro per colpire; se attiva una mossa che richiede un tiro salvezza, i bersagli hanno vantaggio."
    ],
    'mud-shot': [
        "Scagli un globo di fango contro una creatura a gittata. Effettua un attacco a distanza, infliggendo 1d8 + MOVE danni di tipo Terra se colpisci. Con un tiro per colpire naturale superiore a 15, la velocità del bersaglio diventa 0 fino alla fine del suo turno successivo."
    ],
    'nasty-plot': [
        "Stimoli la mente con pensieri maliziosi. Per la durata, hai vantaggio agli attacchi che usano Saggezza, Intelligenza o Carisma come caratteristica della mossa. Quando una di queste mosse richiede un tiro salvezza su Saggezza, Intelligenza o Carisma, il bersaglio ha svantaggio."
    ],
    'no-retreat': [
        "Per la durata, hai vantaggio ai tiri per colpire e ai tiri salvezza, ma non puoi essere sostituito né fuggire."
    ],
    'obstruct': [
        "Percepisci il pericolo e lo eviti rapidamente. Quando subisci i danni e/o gli effetti di una mossa, con il primo utilizzo di questa reazione li eviti automaticamente. Per gli utilizzi successivi nello stesso combattimento devi ottenere più di 15 con un d20. La reazione non può proteggerti dai danni o dagli effetti prodotti da un tiro per colpire naturale di 20.",
        "Se la mossa evitata era un attacco in mischia, l'attaccante deve superare un tiro salvezza su COS o diventare FLINCHED per il resto del turno attuale e per tutto il suo turno successivo."
    ],
    'octazooka': [
        "Scagli un getto d'inchiostro contro una creatura. Effettua un attacco a distanza, infliggendo 1d10 + MOVE danni di tipo Acqua se colpisci. Con un tiro per colpire naturale di 18 o più, il bersaglio subisce -1 ai tiri per colpire per il resto del combattimento."
    ],
    'octolock': [
        "Effettua una prova di lotta contro il bersaglio. Se hai successo, la sua CA si riduce di 1. All'inizio di ogni tuo turno puoi usare un'azione gratuita per ridurre di un ulteriore 1 la CA del bersaglio afferrato con questa mossa. La riduzione è cumulabile fino a 5 volte, per un massimo di -5 alla CA.",
        "La CA del bersaglio torna al valore normale quando la presa viene rilasciata o spezzata."
    ],
    'order-up': [
        "Effettua un attacco a distanza, infliggendo 2d6 + MOVE danni di tipo Drago se colpisci. Se hai un Tatsugiri in bocca, si applica un effetto aggiuntivo in base alla sua forma:",
    ],
    'origin-pulse': [
        "Il tuo corpo risplende di luce blu e scaglia tre raggi concentrati contro creature a gittata. Effettua un attacco a distanza per ciascun raggio, infliggendo 1d10 + MOVE danni di tipo Acqua per ogni colpo andato a segno."
    ],
    'outrage': [
        "Entri in una furia incontrollabile per 3 round. La mossa colpisce automaticamente e infligge 1d6 + MOVE danni di tipo Drago nel primo round, 2d6 + MOVE nel secondo e 4d6 + MOVE nel terzo. La mossa termina se perdi la concentrazione o diventi incapacitato. Quando termina, dopo il terzo round o per la perdita di concentrazione, diventi confuso."
    ],
    'photon-geyser': [
        "Un pilastro di luce erompe dal terreno in un cilindro di raggio 20 piedi e alto 80 piedi, centrato su un punto a gittata. Ogni creatura nell'area deve effettuare un tiro salvezza su DES contro la tua CD della mossa, subendo 5d6 + MOVE danni di tipo Psico se lo fallisce, o la metà se lo supera. Questa mossa ignora le abilità della creatura che impedirebbero all'utilizzatore di colpire o di infliggere danni completi."
    ],
    'plasma-fists': [
        "Carichi i pugni di elettricità e ti scagli contro un bersaglio. Effettua un attacco in mischia, infliggendo 4d4 + MOVE danni di tipo Elettro se colpisci. Se colpisci, fino alla fine del tuo turno successivo le mosse di tipo Normale tue e del bersaglio diventano di tipo Elettro."
    ],
    'pollen-puff': [
        "Scagli una sfera di polline contro un bersaglio a gittata. Effettua un attacco a distanza, infliggendo 2d8 + MOVE danni di tipo Coleottero se colpisci. Se il bersaglio è un alleato, la mossa colpisce automaticamente e gli fa recuperare PF pari ai danni che avrebbe inflitto."
    ],
    'pounce': [
        "Balzi sul bersaglio e subito dopo ti allontani. Effettua un attacco in mischia, infliggendo 1d8 + MOVE danni di tipo Coleottero se colpisci. Puoi quindi muoverti di altri 10 piedi senza provocare attacchi di opportunità."
    ],
    'quiver-dance': [
        "Esegui con leggerezza una danza mistica. Per la durata, ottieni +1 alla CA, ai tiri per colpire e ai tiri per i danni."
    ],
    'rage': [
        "Entri in preda all'ira e attacchi con furia implacabile. Finché dura, ottieni +1 ai tiri per i danni, una sola volta per mossa, hai resistenza ai danni di tipo Normale e vantaggio alle prove di FOR. L'ira termina se perdi la concentrazione oppure se concludi il turno senza aver attaccato una creatura ostile né aver subito danni dal tuo turno precedente."
    ],
    'rage-fist': [
        "Converti la rabbia in energia e attacchi. Effettua un attacco in mischia contro una creatura a gittata, infliggendo 1d8 + MOVE danni di tipo Spettro se colpisci. La mossa infligge 1 danno aggiuntivo per ogni 10 PF mancanti rispetto ai tuoi PF massimi."
    ],
    'rage-powder': [
        "Spargi una nube di polvere irritante che attira gli attacchi verso di te. Ogni creatura in un cono di 15 piedi deve effettuare un tiro salvezza su SAG contro la tua CD della mossa. Se lo fallisce, per la durata può usare soltanto mosse dannose che abbiano te come bersaglio. Una creatura influenzata può ripetere il tiro salvezza alla fine di ciascuno dei suoi turni, terminando l'effetto in caso di successo."
    ],
    'rapid-spin': [
        "Ruoti a velocità incredibile. Ogni creatura entro la tua portata in mischia deve effettuare un tiro salvezza su DES contro la tua CD della mossa, subendo 1d4 + MOVE danni di tipo Normale se lo fallisce, o la metà se lo supera. Prima del tiro salvezza, la mossa libera automaticamente l'utilizzatore da Parassiseme e da qualsiasi effetto che lo renda afferrato o trattenuto."
    ],
    'razor-leaf': [
        "Scagli una foglia affilata come un rasoio contro una creatura a gittata. Effettua un attacco a distanza, infliggendo 1d8 + MOVE danni di tipo Erba se colpisci. La mossa mette a segno un colpo critico con un tiro per colpire naturale di 19 o 20."
    ],
    'razor-shell': [
        "Colpisci una creatura con un guscio affilato come un rasoio. Effettua un attacco in mischia, infliggendo 1d12 + MOVE danni di tipo Acqua se colpisci. Con un tiro per colpire naturale di 18 o più, la CA del bersaglio si riduce di 1. La riduzione è cumulabile fino a un massimo di -5 alla CA."
    ],
}


def apply_special(entry: dict, move_id: str) -> None:
    blocks = SPECIAL_DESCRIPTIONS.get(move_id)
    if blocks is None:
        return
    current = entry['description']
    tables = [item for item in current if isinstance(item, dict)]
    rebuilt = list(blocks)
    if tables:
        rebuilt.extend(tables)
    entry['description'] = rebuilt


def patch_test() -> None:
    path = Path('test/move_localization_integrity_test.dart')
    text = path.read_text(encoding='utf-8')
    text = text.replace(
        "    final errors = <String>[];\n    for (final entry in localizedMoves.entries) {",
        "    final errors = <String>[];\n    var localizedPosition = 0;\n    for (final entry in localizedMoves.entries) {\n      localizedPosition += 1;",
    )
    text = text.replace(
        "        _mechanicalTokenCounts(sourceText),\n        _mechanicalTokenCounts(localizedText),",
        "        _mechanicalTokenCounts(\n          sourceText,\n          includeHealthPhrases: localizedPosition > 450,\n        ),\n        _mechanicalTokenCounts(\n          localizedText,\n          includeHealthPhrases: localizedPosition > 450,\n        ),",
    )
    old_function = """Map<String, int> _mechanicalTokenCounts(String value) {
  final expression = RegExp(
    r'\\b\\d+d\\d+\\b|\\bd\\d+\\b|[+\\-]\\s*\\d+|\\b\\d+[sx]\\b|\\b\\d+(?:ft|\\s*(?:feet|foot|piedi|piede))?\\b|\\b(?:hit points?|Hit Points?|punti ferita|Punti ferita)\\b|\\b(?:HP|PF|STR|FOR|DEX|DES|CON|COS|WIS|SAG|CHA|CAR|INT|AC|CA|STAB|DC|CD|MOVE|PP|SR|FLINCHED)\\b|\\b(?:flinch|flinches|flinched)\\b',
  );
  final result = <String, int>{};"""
    new_function = """Map<String, int> _mechanicalTokenCounts(
  String value, {
  bool includeHealthPhrases = false,
}) {
  final expression = RegExp(
    includeHealthPhrases
        ? r'\\b\\d+d\\d+\\b|\\bd\\d+\\b|[+\\-]\\s*\\d+|\\b\\d+[sx]\\b|\\b\\d+(?:ft|\\s*(?:feet|foot|piedi|piede))?\\b|\\b(?:hit points?|Hit Points?|punti ferita|Punti ferita)\\b|\\b(?:HP|PF|STR|FOR|DEX|DES|CON|COS|WIS|SAG|CHA|CAR|INT|AC|CA|STAB|DC|CD|MOVE|PP|SR|FLINCHED)\\b|\\b(?:flinch|flinches|flinched)\\b'
        : r'\\b\\d+d\\d+\\b|\\bd\\d+\\b|[+\\-]\\s*\\d+|\\b\\d+(?:ft|\\s*(?:feet|foot|piedi|piede))?\\b|\\b(?:HP|PF|STR|FOR|DEX|DES|CON|COS|WIS|SAG|CHA|CAR|INT|AC|CA|STAB|DC|CD|MOVE|PP|SR|FLINCHED|flinch(?:es|ed)?)\\b',
  );
  final result = <String, int>{};"""
    if old_function not in text:
        raise RuntimeError('Funzione dei token meccanici non trovata.')
    text = text.replace(old_function, new_function)
    path.write_text(text, encoding='utf-8')


def main() -> None:
    for path in OVERLAY_PATHS:
        document = json.loads(path.read_text(encoding='utf-8'))
        for move_id, entry in document['items'].items():
            entry['description'] = tidy_value(entry['description'])
            if entry.get('higherLevels') is not None:
                entry['higherLevels'] = tidy_text(entry['higherLevels'])
            apply_special(entry, move_id)
        path.write_text(
            json.dumps(document, ensure_ascii=False, indent=2) + '\n',
            encoding='utf-8',
        )
    patch_test()
    Path('docs/translation/move-451-650-test-diagnostic.txt').unlink(missing_ok=True)


if __name__ == '__main__':
    main()
