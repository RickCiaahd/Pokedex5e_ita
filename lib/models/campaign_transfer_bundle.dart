import 'saved_encounter.dart';
import 'saved_npc_trainer.dart';

enum CampaignTransferKind { encounter, npcTrainer }

class CampaignTransferBundle {
  const CampaignTransferBundle({
    required this.kind,
    required this.exportedAt,
    required this.sourceProfileName,
    this.encounter,
    this.npcTrainer,
  });

  static const String applicationId = 'pokedex-5e-ita';
  static const int currentFormatVersion = 1;

  final CampaignTransferKind kind;
  final DateTime exportedAt;
  final String sourceProfileName;
  final SavedEncounter? encounter;
  final SavedNpcTrainer? npcTrainer;

  factory CampaignTransferBundle.forEncounter({
    required SavedEncounter encounter,
    required String sourceProfileName,
    DateTime? exportedAt,
  }) {
    return CampaignTransferBundle(
      kind: CampaignTransferKind.encounter,
      exportedAt: exportedAt ?? DateTime.now(),
      sourceProfileName: sourceProfileName.trim(),
      encounter: encounter,
    );
  }

  factory CampaignTransferBundle.forNpcTrainer({
    required SavedNpcTrainer npcTrainer,
    required String sourceProfileName,
    DateTime? exportedAt,
  }) {
    return CampaignTransferBundle(
      kind: CampaignTransferKind.npcTrainer,
      exportedAt: exportedAt ?? DateTime.now(),
      sourceProfileName: sourceProfileName.trim(),
      npcTrainer: npcTrainer,
    );
  }

  void validate() {
    switch (kind) {
      case CampaignTransferKind.encounter:
        if (encounter == null || npcTrainer != null || !encounter!.isValid) {
          throw const FormatException(
            'Il file non contiene un incontro valido.',
          );
        }
        break;
      case CampaignTransferKind.npcTrainer:
        if (npcTrainer == null || encounter != null || !npcTrainer!.isValid) {
          throw const FormatException(
            'Il file non contiene un Allenatore PNG valido.',
          );
        }
        break;
    }
  }

  Map<String, dynamic> toJson() {
    validate();
    return {
      'application': applicationId,
      'formatVersion': currentFormatVersion,
      'kind': kind.name,
      'exportedAt': exportedAt.toIso8601String(),
      'sourceProfileName': sourceProfileName,
      'data': switch (kind) {
        CampaignTransferKind.encounter => encounter!.toJson(),
        CampaignTransferKind.npcTrainer => npcTrainer!.toJson(),
      },
    };
  }

  factory CampaignTransferBundle.fromJson(Map<String, dynamic> json) {
    if (json['application']?.toString() != applicationId) {
      throw const FormatException('Il file non appartiene a Pokédex 5e ITA.');
    }
    final version = _readInt(json['formatVersion']);
    if (version != currentFormatVersion) {
      throw FormatException(
        'Versione del trasferimento non supportata: $version.',
      );
    }
    final kindName = json['kind']?.toString() ?? '';
    final kind = CampaignTransferKind.values.firstWhere(
      (candidate) => candidate.name == kindName,
      orElse: () => throw const FormatException(
        'Tipo di trasferimento non riconosciuto.',
      ),
    );
    final data = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'] as Map)
        : throw const FormatException('Il contenuto del file non è valido.');
    final bundle = CampaignTransferBundle(
      kind: kind,
      exportedAt:
          DateTime.tryParse(json['exportedAt']?.toString() ?? '') ??
          DateTime.now(),
      sourceProfileName: json['sourceProfileName']?.toString().trim() ?? '',
      encounter: kind == CampaignTransferKind.encounter
          ? SavedEncounter.fromJson(data)
          : null,
      npcTrainer: kind == CampaignTransferKind.npcTrainer
          ? SavedNpcTrainer.fromJson(data)
          : null,
    );
    bundle.validate();
    return bundle;
  }
}

int _readInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
