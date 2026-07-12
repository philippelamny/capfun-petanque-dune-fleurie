import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/tournament.dart';

/// Persists all tournaments to a single JSON file in the app's documents
/// directory. There is no backend: everything lives on this device.
class StorageService {
  static const _fileName = 'tournaments.json';

  Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  Future<List<Tournament>> loadAll() async {
    try {
      final file = await _file();
      if (!await file.exists()) return [];
      final content = await file.readAsString();
      if (content.trim().isEmpty) return [];
      final list = jsonDecode(content) as List;
      return list
          .map((e) => Tournament.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveAll(List<Tournament> tournaments) async {
    final file = await _file();
    final data = jsonEncode(tournaments.map((t) => t.toJson()).toList());
    await file.writeAsString(data);
  }
}
