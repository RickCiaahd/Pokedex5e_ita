# Pokemon transformation textures

Questa cartella contiene gli asset grafici usati dal Battle Companion per le trasformazioni.

## Struttura

- `mega/<form-id>.png` e `mega/<form-id>-shiny.png`: artwork della Mega Evoluzione.
- `gigamax/<form-id>.png` e `gigamax/<form-id>-shiny.png`: artwork Gigamax.
- Dynamax riutilizza l'immagine normale/shiny del Pokémon e applica l'aura rosso-magenta a runtime.
- Teracristal riutilizza l'immagine normale/shiny e aggiunge il badge del Tera Tipo a runtime.

Gli identificatori seguono le forme di PokeAPI (per esempio `charizard-mega-x` e
`charizard-gmax`).

## Fonte immagini

Gli asset sono tratti dal repository pubblico `PokeAPI/sprites`, cartella
`other/official-artwork`, preferita perché fornisce illustrazioni 2D con
trasparenza e relative varianti shiny.

Per le poche forme recenti prive di uno dei corrispondenti `official-artwork`
si usa il relativo sprite 2D dello stesso repository, senza ricorrere ai render
3D di gioco:

- Garchomp Mega Z shiny;
- Magearna Forma Originale Mega shiny;
- Tatsugiri Curly Mega (normale e shiny);
- Tatsugiri Droopy Mega (normale e shiny).

Fonte: https://github.com/PokeAPI/sprites
