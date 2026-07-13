import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/tournament.dart';

/// Persists all tournaments as a single JSON blob. There is no backend:
/// everything lives on this device. On native platforms that's a file in
/// the app's documents directory; on web (no filesystem) it's a
/// SharedPreferences entry, backed by the browser's localStorage.
class StorageService {
  static const _fileName = 'tournaments.json';
  static const _webKey = 'tournaments_json';

  Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  Future<String?> _read() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_webKey);
    }
    final file = await _file();
    if (!await file.exists()) return null;
    return file.readAsString();
  }

  Future<void> _write(String contents) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_webKey, contents);
      return;
    }
    final file = await _file();
    await file.writeAsString(contents);
  }

  Future<List<Tournament>> loadAll() async {
    try {
      final content = await _read();
      if (content == null || content.trim().isEmpty) return [];
      final list = jsonDecode(content) as List;
      return list
          .map((e) => Tournament.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveAll(List<Tournament> tournaments) async {
    final data = jsonEncode(tournaments.map((t) => t.toJson()).toList());
    await _write(data);
  }
}
