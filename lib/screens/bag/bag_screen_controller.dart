part of 'bag_screen.dart';

class BagScreen extends StatefulWidget {
  const BagScreen({super.key});

  @override
  State<BagScreen> createState() => _BagScreenState();
}

class _BagScreenState extends State<BagScreen> {
  final ItemRepository _itemRepository = ItemRepository();
  final ProfileRepository _profileRepository = ProfileRepository();
  final BagInventoryRepository _bagRepository = BagInventoryRepository();
  final MoveRepository _moveRepository = MoveRepository();
  final PokemonRepository _pokemonRepository = PokemonRepository();
  final TeamRepository _teamRepository = TeamRepository();
  final TmRepository _tmRepository = TmRepository();
  final Random _random = Random();

  late Future<_BagData> _dataFuture;
  String? _selectedType;
  String? _message;
  UserProfile? _activeProfile;

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadBagData();
  }

  Future<_BagData> _loadBagData() async {
    final profile = await _profileRepository.getActiveProfile();
    _activeProfile = profile;
    final catalog = await _itemRepository.getWebItems();
    final inventory = await _bagRepository.getInventory(profile.id);
    final team = await _teamRepository.getTeam(profile.id);
    final pokemonList = await _pokemonRepository.getAllPokemon();
    final pokemonById = {
      for (final pokemon in pokemonList) pokemon.id: pokemon,
    };

    return _BagData(
      profile: profile,
      catalog: catalog,
      inventory: inventory,
      team: team,
      pokemonById: pokemonById,
    );
  }

  Future<void> _reload({String? message}) async {
    if (!mounted) return;

    setState(() {
      _message = message;
      _dataFuture = _loadBagData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_BagData>(
      future: _dataFuture,
      builder: (context, snapshot) {
        final data = snapshot.data;

        return Scaffold(
          appBar: AppBar(
            leading: const HomeLeadingButton(),
            title: Text(context.uiText('Zaino', 'Bag')),
            actions: [
              if (data != null)
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Center(
                    child: Text(
                      '₽ ${data.profile.money}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          body: ResponsiveContent(
            maxWidth: 1180,
            child: Builder(
              builder: (context) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return _BagError(
                    message: context.userFacingError(
                      snapshot.error!,
                      action: UserFacingErrorAction.load,
                    ),
                  );
                }

                if (data == null) return const _BagEmpty();

                return _BagContent(
                  data: data,
                  selectedType: _selectedType,
                  message: _message,
                  onTypeSelected: (type) =>
                      setState(() => _selectedType = type),
                  onUseItem: (entry) => _useBagItem(data, entry),
                  onEquipItem: (entry) => _useHeldItem(data, entry),
                  onDiscardItem: (entry) => _discardBagItem(data, entry),
                  onRemoveHeldItem: (entry) => _removeHeldItem(data, entry),
                );
              },
            ),
          ),
          bottomNavigationBar: data == null
              ? null
              : _BagActions(
                  onFindItem: () => _openFinder(data, _BagAction.find),
                  onBuyItem: () => _openFinder(data, _BagAction.buy),
                  onSellItems: () => _openSellCart(data),
                ),
        );
      },
    );
  }
}
