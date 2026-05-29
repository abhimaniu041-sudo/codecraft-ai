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

  static const String _dbKey = 'asset_db_v1';
  final Map<String, AssetRecord> _cache = {};
  final _uuid = const Uuid();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    await _load();
    _initialized = true;
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_dbKey);
      if (raw != null) {
        final List data = jsonDecode(raw);
        for (final item in data) {
          final record =
              AssetRecord.fromJson(Map<String, dynamic>.from(item));
          _cache[record.id] = record;
        }
      }
    } catch (_) {}
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = _cache.values.map((r) => r.toJson()).toList();
      await prefs.setString(_dbKey, jsonEncode(data));
    } catch (_) {}
  }

  AssetRecord? findByTags(List<String> tags, String category) {
    final lowerTags = tags.map((t) => t.toLowerCase()).toList();
    final matches = _cache.values.where((r) {
      if (r.category != category) return false;
      final matched =
          lowerTags.where((t) => r.tags.contains(t)).length;
      return matched >= (lowerTags.length * 0.5).ceil();
    }).toList();

    if (matches.isEmpty) return null;
    matches.sort((a, b) => b.usageCount.compareTo(a.usageCount));
    return matches.first;
  }

  Future<AssetRecord> register({
    required String localPath,
    required List<String> tags,
    required String category,
    required String prompt,
    String? firebaseUrl,
  }) async {
    final record = AssetRecord(
      id: _uuid.v4(),
      localPath: localPath,
      firebaseUrl: firebaseUrl,
      tags: tags.map((t) => t.toLowerCase()).toList(),
      category: category,
      generationPrompt: prompt,
      createdAt: DateTime.now(),
    );
    _cache[record.id] = record;
    await _save();
    return record;
  }

  Future<void> incrementUsage(String id) async {
    if (_cache.containsKey(id)) {
      _cache[id]!.usageCount++;
      await _save();
    }
  }

  Future<String?> downloadToCache(String url, String filename) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final cacheDir = Directory('${dir.path}/asset_cache');
      if (!cacheDir.existsSync()) {
        cacheDir.createSync(recursive: true);
      }

      final filePath = '${cacheDir.path}/$filename';
      final file = File(filePath);
      if (file.existsSync()) return filePath;

      final response = await http
          .get(Uri.parse(url))
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

  List<String> extractTagsFromPrompt(String prompt) {
    final keywords = [
      'dragon', 'fire', 'city', 'forest', 'space', 'hero', 'villain',
      'robot', 'wizard', 'ninja', 'warrior', 'princess', 'alien', 'zombie',
      'explosion', 'magic', 'night', 'day', 'sunset', 'rain', 'snow',
      'cyberpunk', 'battle', 'castle', 'underwater', 'volcano', 'beach',
    ];
    final lower = prompt.toLowerCase();
    return keywords.where((k) => lower.contains(k)).toList();
  }

  int get totalCount => _cache.length;
  List<AssetRecord> get all => _cache.values.toList();
}
