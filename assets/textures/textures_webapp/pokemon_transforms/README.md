# Pokemon transform textures

Questa cartella prepara la struttura per immagini che verranno aggiunte in seguito.

Struttura consigliata:

```text
pokemon_transforms/
  mega/<pokemon-slug>/main.png
  mega/<pokemon-slug>/sprite.png
  dynamax/<pokemon-slug>/main.png
  dynamax/<pokemon-slug>/sprite.png
  gigamax/<pokemon-slug>/main.png
  gigamax/<pokemon-slug>/sprite.png
  terastal/<pokemon-slug>/main.png
  terastal/<pokemon-slug>/sprite.png
```

Per forme specifiche puoi usare sottocartelle o nomi file con slug della forma, per esempio:

```text
gigamax/charizard/main.png
gigamax/charizard/sprite.png
mega/charizard/x/main.png
mega/charizard/y/main.png
```

Il codice cerca già queste directory come fallback grafico; le immagini possono essere aggiunte progressivamente.
