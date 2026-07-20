import json
from pathlib import Path

paths = [
    Path('assets/data/move_localization_it_451_500.json'),
    Path('assets/data/move_localization_it_501_550.json'),
    Path('assets/data/move_localization_it_551_600.json'),
    Path('assets/data/move_localization_it_601_650.json'),
]

for path in paths:
    document = json.loads(path.read_text(encoding='utf-8'))
    items = document['items']

    if 'octolock' in items:
        items['octolock']['description'][1] = (
            'Quando la presa viene rilasciata o spezzata, la riduzione della CA '
            'del bersaglio torna a 0.'
        )

    if 'outrage' in items:
        items['outrage']['description'][0] = (
            'Entri in una furia incontrollabile per tre round. La mossa colpisce '
            'automaticamente e infligge 1d6 + MOVE danni di tipo Drago nel primo '
            'round, 2d6 + MOVE nel secondo e 4d6 + MOVE nel terzo. La mossa termina '
            'se perdi la concentrazione o diventi incapacitato. Quando termina, dopo '
            'il terzo round o per la perdita di concentrazione, diventi confuso.'
        )

    if 'pollen-puff' in items:
        items['pollen-puff']['description'][0] = (
            'Scagli una sfera di polline contro un bersaglio a gittata. Effettua un '
            'attacco a distanza, infliggendo 2d8 + MOVE danni di tipo Coleottero se '
            'colpisci. Se il bersaglio è un alleato, la mossa colpisce automaticamente '
            'e gli restituisce salute per un ammontare pari ai danni che avrebbe inflitto.'
        )

    if 'rage' in items:
        items['rage']['description'][0] = (
            "Entri in preda all'ira e attacchi con furia implacabile. Finché dura, "
            'ottieni +1 ai tiri per i danni, una sola volta per mossa, hai resistenza '
            'ai danni di tipo Normale e vantaggio alle prove di Forza. L\'ira termina '
            'se perdi la concentrazione oppure se concludi il turno senza aver attaccato '
            'una creatura ostile né aver subito danni dal tuo turno precedente.'
        )

    path.write_text(
        json.dumps(document, ensure_ascii=False, indent=2) + '\n',
        encoding='utf-8',
    )

Path('docs/translation/move-451-650-final-test-diagnostic.txt').unlink(missing_ok=True)
