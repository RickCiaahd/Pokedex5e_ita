from pathlib import Path


def replace_once(path: Path, old: str, new: str) -> None:
    text = path.read_text(encoding="utf-8")
    if old not in text:
        raise RuntimeError(f"Expected block not found in {path}: {old[:120]!r}")
    path.write_text(text.replace(old, new, 1), encoding="utf-8")


edit = Path("lib/screens/pokemon/pokemon_edit_screen.dart")

replace_once(
    edit,
    """      builder: (_) => _FormPickerSheet(
        pokemon: widget.pokemon,
        currentFormName: _formName,
        choices: _formChoices,
      ),
""",
    """      builder: (_) => _FormPickerSheet(
        pokemon: widget.pokemon,
        currentFormName: _formName,
        gender: _gender,
        isShiny: _isShiny,
        choices: _formChoices,
      ),
""",
)

replace_once(
    edit,
    """                    child: _FormSelector(
                      pokemon: widget.pokemon,
                      formName: _formName ?? _formChoices.first.name,
                      onTap: _pickForm,
                    ),
""",
    """                    child: _FormSelector(
                      pokemon: widget.pokemon,
                      formName: _formName ?? _formChoices.first.name,
                      gender: _gender,
                      isShiny: _isShiny,
                      onTap: _pickForm,
                    ),
""",
)

replace_once(
    edit,
    """class _FormSelector extends StatelessWidget {
  const _FormSelector({
    required this.pokemon,
    required this.formName,
    required this.onTap,
  });

  final Pokemon pokemon;
  final String formName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: PokemonAssetImage(
          pokemon: pokemon,
          formName: formName,
          size: 52,
        ),
""",
    """class _FormSelector extends StatelessWidget {
  const _FormSelector({
    required this.pokemon,
    required this.formName,
    required this.gender,
    required this.isShiny,
    required this.onTap,
  });

  final Pokemon pokemon;
  final String formName;
  final String? gender;
  final bool isShiny;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: PokemonAssetImage(
          pokemon: pokemon,
          formName: formName,
          gender: gender,
          isShiny: isShiny,
          size: 52,
        ),
""",
)

replace_once(
    edit,
    """class _FormPickerSheet extends StatelessWidget {
  const _FormPickerSheet({
    required this.pokemon,
    required this.currentFormName,
    required this.choices,
  });

  final Pokemon pokemon;
  final String? currentFormName;
  final List<PokemonFormChoice> choices;
""",
    """class _FormPickerSheet extends StatelessWidget {
  const _FormPickerSheet({
    required this.pokemon,
    required this.currentFormName,
    required this.gender,
    required this.isShiny,
    required this.choices,
  });

  final Pokemon pokemon;
  final String? currentFormName;
  final String? gender;
  final bool isShiny;
  final List<PokemonFormChoice> choices;
""",
)

replace_once(
    edit,
    """                  leading: PokemonAssetImage(
                    pokemon: pokemon,
                    formName: choice.name,
                    size: 52,
                  ),
""",
    """                  leading: PokemonAssetImage(
                    pokemon: pokemon,
                    formName: choice.name,
                    gender: gender,
                    isShiny: isShiny,
                    size: 52,
                  ),
""",
)

capture = Path("lib/screens/capture/capture_pokemon_screen.dart")

replace_once(
    capture,
    """                PokemonAssetImage(
                  pokemon: widget.pokemon,
                  formName: _formName,
                  useLargeArtwork: true,
                  size: 86,
                ),
""",
    """                PokemonAssetImage(
                  pokemon: widget.pokemon,
                  formName: _formName,
                  gender: _gender,
                  isShiny: _isShiny,
                  useLargeArtwork: true,
                  size: 86,
                ),
""",
)

detail = Path("lib/screens/pokemon/pokemon_detail_screen.dart")

replace_once(
    detail,
    """                          child: PokemonAssetImage(
                            pokemon: pokemon,
                            useLargeArtwork: true,
                            size: 112,
                          ),
""",
    """                          child: PokemonAssetImage(
                            pokemon: pokemon,
                            formName: slot?.formName,
                            gender: slot?.gender,
                            isShiny: slot?.isShiny,
                            useLargeArtwork: true,
                            size: 112,
                          ),
""",
)

pc = Path("lib/screens/pc/pokemon_pc_screen.dart")

replace_once(
    pc,
    """                    : PokemonAssetImage(
                        pokemon: pokemon,
                        size: spriteSize,
                        formName: slot.formName,
                      ),
""",
    """                    : PokemonAssetImage(
                        pokemon: pokemon,
                        size: spriteSize,
                        formName: slot.formName,
                        gender: slot.gender,
                        isShiny: slot.isShiny,
                      ),
""",
)

replace_once(
    pc,
    """                  : PokemonAssetImage(
                      pokemon: pokemon,
                      size: 58,
                      formName: pcPokemon.formName,
                    ),
""",
    """                  : PokemonAssetImage(
                      pokemon: pokemon,
                      size: 58,
                      formName: pcPokemon.formName,
                      gender: pcPokemon.gender,
                      isShiny: pcPokemon.isShiny,
                    ),
""",
)

replace_once(
    pc,
    """                    : PokemonAssetImage(
                        pokemon: pokemon,
                        size: 58,
                        formName: pcPokemon.formName,
                      ),
""",
    """                    : PokemonAssetImage(
                        pokemon: pokemon,
                        size: 58,
                        formName: pcPokemon.formName,
                        gender: pcPokemon.gender,
                        isShiny: pcPokemon.isShiny,
                      ),
""",
)

replace_once(
    pc,
    """            : PokemonAssetImage(
                pokemon: pokemon,
                size: 48,
                formName: slot.formName,
              ),
""",
    """            : PokemonAssetImage(
                pokemon: pokemon,
                size: 48,
                formName: slot.formName,
                gender: slot.gender,
                isShiny: slot.isShiny,
              ),
""",
)

team = Path("lib/screens/team/team_selection_screen.dart")

replace_once(
    team,
    """              _SlotAvatar(slotIndex: slot.slotIndex, pokemon: pokemon),
""",
    """              _SlotAvatar(slot: slot, pokemon: pokemon),
""",
)

replace_once(
    team,
    """class _SlotAvatar extends StatelessWidget {
  const _SlotAvatar({required this.slotIndex, required this.pokemon});

  final int slotIndex;
  final Pokemon? pokemon;
""",
    """class _SlotAvatar extends StatelessWidget {
  const _SlotAvatar({required this.slot, required this.pokemon});

  final TeamSlot slot;
  final Pokemon? pokemon;
""",
)

replace_once(
    team,
    """                '${slotIndex + 1}',
""",
    """                '${slot.slotIndex + 1}',
""",
)

replace_once(
    team,
    """            : PokemonAssetImage(pokemon: pokemon, size: 48),
""",
    """            : PokemonAssetImage(
                pokemon: pokemon,
                formName: slot.formName,
                gender: slot.gender,
                isShiny: slot.isShiny,
                size: 48,
              ),
""",
)

print("Patched Pokemon form previews across edit, capture, detail, PC, and team screens.")
