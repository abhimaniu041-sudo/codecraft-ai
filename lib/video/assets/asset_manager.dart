import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/video_models.dart';

class AssetManager {
  static final AssetManager _instance = AssetManager._internal();
  factory AssetManager() => _instance;
  AssetManager._internal();

  static const String _dbKey = 'asset_database';
  final Map<String, AssetRecord> _localCache = {};
  final _uuid = const Uuid();

  // ── Initialize ────────────────────────────────────────
  Future<void> init() async {
    await _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_dbKey);
    if (raw != null) {
      try {
        final List data = jsonDecode(raw);
        for (final item in data) {
          final record = AssetRecord.fromJson(Map<String, dynamic>.from(item));
          _localCache[record.id] = record;
        }
      } catch (_) {}
    }
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final data = _localCache.values.map((r) => r.toJson()).toList();
    await prefs.setString(_dbKey, jsonEncode(data));
  }

  // ── Search assets by tags ─────────────────────────────
  List<AssetRecord> searchByTags(List<String> tags) {
    if (tags.isEmpty) return [];
    final results = <AssetRecord>[];
    for (final record in _localCache.values) {
      final matchCount =
          tags.where((t) => record.tags.contains(t.toLowerCase())).length;
      if (matchCount > 0) results.add(record);
    }
    results.sort((a, b) {
      final aMatch =
          tags.where((t) => a.tags.contains(t.toLowerCase())).length;
      final bMatch =
          tags.where((t) => b.tags.contains(t.toLowerCase())).length;
      return bMatch.compareTo(aMatch);
    });
    return results;
  }

  // ── Search by category ────────────────────────────────
  List<AssetRecord> searchByCategory(String category) {
    return _localCache.values
        .where((r) => r.category == category)
        .toList()
      ..sort((a, b) => b.usageCount.compareTo(a.usageCount));
  }

  // ── Check if asset exists ─────────────────────────────
  AssetRecord? findAsset(List<String> tags, String category) {
    final matches = _localCache.values.where((r) {
      if (r.category != category) return false;
      final tagMatches =
          tags.where((t) => r.tags.contains(t.toLowerCase())).length;
      return tagMatches >= (tags.length * 0.6).floor();
    }).toList();

    if (matches.isEmpty) return null;
    matches.sort((a, b) => b.usageCount.compareTo(a.usageCount));
    return matches.first;
  }

  // ── Register new asset ────────────────────────────────
  Future<AssetRecord> registerAsset({
    required String localPath,
    required List<String> tags,
    required String category,
    required String generationPrompt,
    String? firebaseUrl,
  }) async {
    final record = AssetRecord(
      id: _uuid.v4(),
      localPath: localPath,
      firebaseUrl: firebaseUrl,
      tags: tags.map((t) => t.toLowerCase()).toList(),
      category: category,
      generationPrompt: generationPrompt,
      createdAt: DateTime.now(),
    );
    _localCache[record.id] = record;
    await _saveToPrefs();
    return record;
  }

  // ── Increment usage ───────────────────────────────────
  Future<void> incrementUsage(String id) async {
    if (_localCache.containsKey(id)) {
      _localCache[id]!.usageCount++;
      await _saveToPrefs();
    }
  }

  // ── Download asset from URL ───────────────────────────
  Future<String?> downloadAsset(String url, String filename) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final assetsDir = Directory('${dir.path}/assets');
      if (!assetsDir.existsSync()) assetsDir.createSync(recursive: true);

      final filePath = '${assetsDir.path}/$filename';
      final file = File(filePath);

      if (file.existsSync()) return filePath;

      final response = await http.get(Uri.parse(url))
          .timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        return filePath;
      }
      return null;
    } catch (e) {
      debugPrint('Download failed: $e');
      return null;
    }
  }

  // ── Extract tags from prompt ──────────────────────────
  List<String> extractTags(String prompt) {
    final keywords = [
      'dragon', 'fire', 'city', 'forest', 'space', 'hero', 'villain',
      'robot', 'wizard', 'ninja', 'warrior', 'princess', 'alien', 'zombie',
      'explosion', 'magic', 'night', 'day', 'sunset', 'rain', 'snow',
      'cyberpunk', 'battle', 'castle', 'underwater', 'volcano', 'beach',
    ];
    final lower = prompt.toLowerCase();
    return keywords.where((k) => lower.contains(k)).toList();
  }

  int get totalAssets => _localCache.length;

  List<AssetRecord> get allAssets => _localCache.values.toList();
}
