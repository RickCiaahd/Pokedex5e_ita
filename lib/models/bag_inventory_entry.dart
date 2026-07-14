class BagInventoryEntry {
  const BagInventoryEntry({
    required this.profileId,
    required this.itemId,
    required this.quantity,
  });

  final String profileId;
  final String itemId;
  final int quantity;

  String get storageKey => keyFor(profileId, itemId);

  BagInventoryEntry copyWith({int? quantity}) {
    return BagInventoryEntry(
      profileId: profileId,
      itemId: itemId,
      quantity: quantity ?? this.quantity,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'profileId': profileId,
      'itemId': itemId,
      'quantity': quantity,
    };
  }

  factory BagInventoryEntry.fromJson(Map<String, dynamic> json) {
    return BagInventoryEntry(
      profileId: json['profileId']?.toString() ?? '',
      itemId: json['itemId']?.toString() ?? '',
      quantity: json['quantity'] is int ? json['quantity'] as int : 0,
    );
  }

  static String keyFor(String profileId, String itemId) => '$profileId::$itemId';
}
