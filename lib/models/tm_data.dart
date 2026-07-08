class TmData {
  const TmData({
    required this.number,
    required this.moveId,
    required this.cost,
  });

  final int number;
  final String moveId;
  final int cost;

  String get id {
    final padded = number.toString().padLeft(3, '0');
    return 'tm-$padded';
  }

  String get label {
    final padded = number.toString().padLeft(2, '0');
    return 'MT$padded';
  }

  factory TmData.fromWebJson(Map<String, dynamic> json) {
    return TmData(
      number: _readInt(json['id']) ?? 0,
      moveId: json['move']?.toString() ?? '',
      cost: _readInt(json['cost']) ?? 0,
    );
  }

  static int? _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }
}
