import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/evolution_data.dart';

class EvolutionRepository {
  Future<Map<String, EvolutionData>> getEvolutionData() async {
    final jsonString = await rootBundle.loadString('assets/data/evolve.json');
    final Map<String, dynamic> json = jsonDecode(jsonString);

    return json.map(
      (name, data) => MapEntry(
        name,
        EvolutionData.fromJson(Map<String, dynamic>.from(data)),
      ),
    );
  }
}
