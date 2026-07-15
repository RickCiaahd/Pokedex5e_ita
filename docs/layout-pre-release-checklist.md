# Checklist layout pre-release

Verificare le schermate principali a 360 px, 412 px, tablet e desktop/Web largo.
Ripetere almeno il controllo smartphone con dimensione testo di sistema aumentata.

## Navigazione

- La freccia torna alla schermata precedente.
- Il pulsante Home torna alla schermata iniziale.
- Le azioni delle AppBar restano raggiungibili senza sovrapporsi al titolo.

## Battle Companion

- Header, squadra, iniziativa, ambiente, Pokémon attivo e mosse restano leggibili.
- I selettori orizzontali scorrono senza overflow.
- Dialog di PF, status, iniziativa e ambiente restano utilizzabili con tastiera aperta.
- I bottom sheet rispettano le aree sicure del dispositivo.

## Fight del Master

- Home, condivisione e menu delle azioni sono visibili a 360 px.
- La selezione degli Allenatori scorre orizzontalmente.
- Scheda Allenatore, iniziativa, squadra, Pokémon attivo, status e mosse non hanno overflow.
- Azzera e Termina fight richiedono conferma e restano accessibili dal menu.

## Strumenti del Master

- Una colonna su smartphone e due colonne sulle finestre ampie.
- Titoli e descrizioni delle card vanno a capo senza tagli.
- Generatori, librerie e ripresa del fight aprono la schermata corretta.

## Controllo finale

- Nessun testo troncato o RenderFlex overflow.
- Stati di caricamento, vuoto ed errore sono leggibili.
- Refresh, scroll verticale e scroll orizzontale funzionano.
- Tema, spaziature, card e gerarchia tipografica restano coerenti.
