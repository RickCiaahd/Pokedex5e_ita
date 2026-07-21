# Texture maschio e femmina

Il risolutore supporta le differenze estetiche tra maschio e femmina senza
trasformarle in forme separate del Pokédex. Il sesso continua a essere salvato
nel singolo Pokémon della squadra o del PC.

## File da caricare

Non servono nuove cartelle né modifiche al `pubspec.yaml`: aggiungi i file nella
cartella della specie già esistente, per esempio
`assets/textures/textures_webapp/pokemon/pikachu/`.

| Aspetto | Artwork grande | Sprite | Artwork shiny | Sprite shiny |
|---|---|---|---|---|
| Maschio | `main-m.png` | `sprite-m.png` | `main-shiny-m.png` | `sprite-shiny-m.png` |
| Femmina | `main-f.png` | `sprite-f.png` | `main-shiny-f.png` | `sprite-shiny-f.png` |

Sono accettati anche i nomi estesi `male` e `female`, le varianti con underscore
e le cartelle già esistenti del tipo `indeedee-m/`, `indeedee-f/`,
`meowstic-m/`, `meowstic-f/`, `pyroar-m/` e `pyroar-f/`.

Quando manca una texture shiny del sesso selezionato, l'app preferisce la
texture normale dello stesso sesso rispetto a una silhouette shiny errata.

## Specie con differenze visive

### Generazione I
Venusaur, Butterfree, Rattata, Raticate, Pikachu, Raichu, Zubat, Golbat,
Gloom, Vileplume, Kadabra, Alakazam, Doduo, Dodrio, Hypno, Rhyhorn, Rhydon,
Goldeen, Seaking, Scyther, Magikarp, Gyarados, Eevee.

### Generazione II
Meganium, Ledyba, Ledian, Xatu, Sudowoodo, Politoed, Aipom, Wooper,
Quagsire, Murkrow, Wobbuffet, Girafarig, Gligar, Steelix, Scizor, Heracross,
Sneasel, Ursaring, Piloswine, Octillery, Houndoom, Donphan.

La differenza si applica anche alla forma di Hisui di Sneasel: in quel caso i
file possono essere inseriti nella cartella della forma regionale già presente.

### Generazione III
Torchic, Combusken, Blaziken, Beautifly, Dustox, Ludicolo, Nuzleaf, Shiftry,
Meditite, Medicham, Roselia, Gulpin, Swalot, Numel, Camerupt, Cacturne,
Milotic, Relicanth.

### Generazione IV
Starly, Staravia, Staraptor, Bidoof, Bibarel, Kricketot, Kricketune, Shinx,
Luxio, Luxray, Roserade, Combee, Pachirisu, Buizel, Floatzel, Ambipom, Gible,
Gabite, Garchomp, Hippopotas, Hippowdon, Croagunk, Toxicroak, Finneon,
Lumineon, Snover, Abomasnow, Weavile, Rhyperior, Tangrowth, Mamoswine.

### Generazione V
Unfezant, Frillish, Jellicent.

### Generazione VI
Pyroar, Meowstic.

### Generazione VIII
Indeedee, Basculegion.

### Generazione IX
Oinkologne.
