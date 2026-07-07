import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/trainer_manual_content.dart';

class TrainerManualRepository {
  Future<List<TrainerOrigin>> getOrigins() async {
    final jsonString = await rootBundle.loadString(
      'assets/data/trainer_origins.json',
    );
    final items = jsonDecode(jsonString) as List;

    return [
      for (final item in items)
        TrainerOrigin.fromJson(Map<String, dynamic>.from(item as Map)),
    ];
  }

  Future<List<TrainerPath>> getTrainerPaths() async {
    final jsonString = await rootBundle.loadString(
      'assets/data/trainer_paths.json',
    );
    final items = jsonDecode(jsonString) as List;

    return [
      for (final item in items)
        TrainerPath.fromJson(Map<String, dynamic>.from(item as Map)),
    ];
  }
}
