import '../localization/game_catalog_locale.dart';
import 'bag_item.dart';
import 'trainer_manual_options.dart';

class TrainerStartingEquipment {
  const TrainerStartingEquipment._();

  static const Map<String, int> baseInventory = {
    'poke-ball': 5,
    'potion': 1,
    'trainers-license': 1,
    'pokedex': 1,
  };

  static const Map<String, Map<String, int>> packInventory = {
    "Dungeoneer's pack": {
      'trainer-backpack': 1,
      'climbers-kit': 1,
      'flashlight': 1,
      'energy-cell': 5,
      'flint-and-steel': 1,
      'camping-ration': 10,
      'canteen': 1,
      'rope-30-feet': 1,
    },
    "Explorer's pack": {
      'trainer-backpack': 1,
      'sleeping-bag': 1,
      'mess-kit': 1,
      'flint-and-steel': 1,
      'flashlight': 1,
      'energy-cell': 5,
      'camping-ration': 10,
      'canteen': 1,
      'rope-30-feet': 1,
    },
    "Filcher's pack": {
      'trainer-backpack': 1,
      'thieves-tools': 1,
      'wire-20-feet': 1,
      'bell': 1,
      'lantern': 1,
      'energy-cell': 3,
      'camping-ration': 5,
      'flint-and-steel': 1,
      'canteen': 1,
    },
  };

  static Map<String, int> inventoryForPack(String pack) {
    final selected = packInventory[pack];
    if (selected == null) {
      throw ArgumentError.value(pack, 'pack', 'Unknown starting pack');
    }

    return Map<String, int>.unmodifiable({...baseInventory, ...selected});
  }

  static List<BagItem> get catalogItems {
    final italian = GameCatalogLocale.isItalian;
    String text(String it, String en) => italian ? it : en;

    return List<BagItem>.unmodifiable([
      BagItem(
        id: 'trainer-backpack',
        name: text('Zaino', 'Backpack'),
        sourceName: 'Backpack',
        type: 'trainer-gear',
        description: [
          text(
            'Contenitore da viaggio per trasportare equipaggiamento e provviste.',
            'Travel container used to carry equipment and supplies.',
          ),
        ],
        cost: null,
        spriteAssetPath: null,
      ),
      BagItem(
        id: 'climbers-kit',
        name: text('Kit da scalatore', "Climber's Kit"),
        sourceName: "Climber's Kit",
        type: 'trainer-gear',
        description: [
          text(
            'Attrezzatura concreta per affrontare arrampicate e pareti difficili.',
            'Practical equipment for climbing and difficult walls.',
          ),
        ],
        cost: null,
        spriteAssetPath: null,
      ),
      BagItem(
        id: 'flashlight',
        name: text('Torcia', 'Flashlight'),
        sourceName: 'Flashlight',
        type: 'trainer-gear',
        description: [
          text(
            'Fonte di luce portatile alimentata da celle energetiche.',
            'Portable light source powered by energy cells.',
          ),
        ],
        cost: null,
        spriteAssetPath: null,
      ),
      BagItem(
        id: 'energy-cell',
        name: text('Cella energetica', 'Energy Cell'),
        sourceName: 'Energy Cell',
        type: 'trainer-gear',
        description: [
          text(
            'Unità di alimentazione per torce, lanterne e altri dispositivi compatibili.',
            'Power unit for flashlights, lanterns, and compatible devices.',
          ),
        ],
        cost: null,
        spriteAssetPath: null,
      ),
      BagItem(
        id: 'flint-and-steel',
        name: text('Acciarino e pietra focaia', 'Flint and Steel'),
        sourceName: 'Flint and Steel',
        type: 'trainer-gear',
        description: [
          text(
            'Strumenti per produrre scintille e accendere un fuoco.',
            'Tools used to make sparks and light a fire.',
          ),
        ],
        cost: null,
        spriteAssetPath: null,
      ),
      BagItem(
        id: 'camping-ration',
        name: text('Razione da campeggio', 'Camping Ration'),
        sourceName: 'Camping Ration',
        type: 'trainer-gear',
        description: [
          text(
            'Una porzione di viveri conservabili per il viaggio.',
            'One portion of preserved food for travel.',
          ),
        ],
        cost: null,
        spriteAssetPath: null,
      ),
      BagItem(
        id: 'canteen',
        name: text('Borraccia', 'Canteen'),
        sourceName: 'Canteen',
        type: 'trainer-gear',
        description: [
          text(
            'Contenitore portatile per trasportare acqua o altre bevande.',
            'Portable container for carrying water or other drinks.',
          ),
        ],
        cost: null,
        spriteAssetPath: null,
      ),
      BagItem(
        id: 'rope-30-feet',
        name: text('Corda da 30 piedi', '30-foot Rope'),
        sourceName: '30-foot Rope',
        type: 'trainer-gear',
        description: [
          text(
            'Trenta piedi di corda utilizzabili per legare, calarsi, assicurare o improvvisare.',
            'Thirty feet of rope for tying, lowering, securing, or improvising.',
          ),
        ],
        cost: null,
        spriteAssetPath: null,
      ),
      BagItem(
        id: 'sleeping-bag',
        name: text('Sacco a pelo', 'Sleeping Bag'),
        sourceName: 'Sleeping Bag',
        type: 'trainer-gear',
        description: [
          text(
            'Giusta protezione per dormire durante i viaggi e i campeggi.',
            'Basic protection for sleeping during journeys and camps.',
          ),
        ],
        cost: null,
        spriteAssetPath: null,
      ),
      BagItem(
        id: 'mess-kit',
        name: text('Gavetta', 'Mess Kit'),
        sourceName: 'Mess Kit',
        type: 'trainer-gear',
        description: [
          text(
            'Utensili essenziali per preparare e consumare un pasto da campo.',
            'Essential utensils for preparing and eating a camp meal.',
          ),
        ],
        cost: null,
        spriteAssetPath: null,
      ),
      BagItem(
        id: 'thieves-tools',
        name: text('Arnesi da scasso', "Thieves' Tools"),
        sourceName: "Thieves' Tools",
        type: 'trainer-gear',
        description: [
          text(
            'Strumenti specialistici per lavorare su serrature e meccanismi.',
            'Specialized tools for working on locks and mechanisms.',
          ),
        ],
        cost: null,
        spriteAssetPath: null,
      ),
      BagItem(
        id: 'wire-20-feet',
        name: text('Filo da 20 piedi', '20-foot Wire'),
        sourceName: '20-foot Wire',
        type: 'trainer-gear',
        description: [
          text(
            'Venti piedi di filo sottile utilizzabili per legature, segnali o congegni improvvisati.',
            'Twenty feet of thin wire for bindings, signals, or improvised devices.',
          ),
        ],
        cost: null,
        spriteAssetPath: null,
      ),
      BagItem(
        id: 'bell',
        name: text('Campanella', 'Bell'),
        sourceName: 'Bell',
        type: 'trainer-gear',
        description: [
          text(
            'Piccola campana utile per segnali, allarmi e semplici congegni.',
            'Small bell useful for signals, alarms, and simple devices.',
          ),
        ],
        cost: null,
        spriteAssetPath: null,
      ),
      BagItem(
        id: 'lantern',
        name: text('Lanterna', 'Lantern'),
        sourceName: 'Lantern',
        type: 'trainer-gear',
        description: [
          text(
            'Fonte di luce protetta, alimentata da celle energetiche.',
            'Protected light source powered by energy cells.',
          ),
        ],
        cost: null,
        spriteAssetPath: null,
      ),
    ]);
  }

  static void validatePacks() {
    if (packInventory.keys
            .toSet()
            .difference(TrainerManualOptions.startingPacks.toSet())
            .isNotEmpty ||
        TrainerManualOptions.startingPacks
            .toSet()
            .difference(packInventory.keys.toSet())
            .isNotEmpty) {
      throw StateError('Starting pack inventory is out of sync');
    }
  }
}
