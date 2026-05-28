import 'package:flutter/material.dart';

// ── Character State ──────────────────────────────────────
enum CharacterState {
  idle, walk, run, attack, jump, fly, talk,
  angry, happy, sad, victory, death, cast, defend
}

// ── Background Type ──────────────────────────────────────
enum BackgroundType {
  city, cyberpunk, forest, space, underwater,
  volcano, castle, battlefield, beach, snow,
  desert, jungle, fantasy, school, laboratory
}

// ── Scene Time / Weather ─────────────────────────────────
enum SceneTimeOfDay { day, sunset, night }
enum WeatherType { none, rain, snow, storm, fog }
enum CameraEffect { none, shake, zoomIn, zoomOut, pan }
enum TransitionType { fade, flash, wipe, zoom, none }
enum ParticleEffectType { fire, smoke, explosion, magic, sparks, rain, snow }

// ── Asset Record ─────────────────────────────────────────
class AssetRecord {
  final String id;
  final String localPath;
  final String? firebaseUrl;
  final List<String> tags;
  final String category;
  final String generationPrompt;
  final DateTime createdAt;
  int usageCount;

  AssetRecord({
    required this.id,
    required this.localPath,
    this.firebaseUrl,
    required this.tags,
    required this.category,
    required this.generationPrompt,
    required this.createdAt,
    this.usageCount = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'localPath': localPath,
        'firebaseUrl': firebaseUrl,
        'tags': tags,
        'category': category,
        'generationPrompt': generationPrompt,
        'createdAt': createdAt.toIso8601String(),
        'usageCount': usageCount,
      };

  factory AssetRecord.fromJson(Map<String, dynamic> j) => AssetRecord(
        id: j['id'] ?? '',
        localPath: j['localPath'] ?? '',
        firebaseUrl: j['firebaseUrl'],
        tags: List<String>.from(j['tags'] ?? []),
        category: j['category'] ?? '',
        generationPrompt: j['generationPrompt'] ?? '',
        createdAt: DateTime.tryParse(j['createdAt'] ?? '') ?? DateTime.now(),
        usageCount: j['usageCount'] ?? 0,
      );
}

// ── Scene Character ──────────────────────────────────────
class SceneCharacter {
  String characterId;
  String state;
  double positionX;
  double positionY;
  bool facingRight;
  String dialogue;
  double scale;

  SceneCharacter({
    required this.characterId,
    this.state = 'idle',
    this.positionX = 0.3,
    this.positionY = 0.62,
    this.facingRight = true,
    this.dialogue = '',
    this.scale = 1.0,
  });

  Map<String, dynamic> toJson() => {
        'characterId': characterId,
        'state': state,
        'positionX': positionX,
        'positionY': positionY,
        'facingRight': facingRight,
        'dialogue': dialogue,
        'scale': scale,
      };

  factory SceneCharacter.fromJson(Map<String, dynamic> j) => SceneCharacter(
        characterId: j['characterId'] ?? 'hero',
        state: j['state'] ?? 'idle',
        positionX: (j['positionX'] ?? 0.3).toDouble(),
        positionY: (j['positionY'] ?? 0.62).toDouble(),
        facingRight: j['facingRight'] ?? true,
        dialogue: j['dialogue'] ?? '',
        scale: (j['scale'] ?? 1.0).toDouble(),
      );

  SceneCharacter copyWith({
    String? characterId,
    String? state,
    double? positionX,
    double? positionY,
    bool? facingRight,
    String? dialogue,
    double? scale,
  }) =>
      SceneCharacter(
        characterId: characterId ?? this.characterId,
        state: state ?? this.state,
        positionX: positionX ?? this.positionX,
        positionY: positionY ?? this.positionY,
        facingRight: facingRight ?? this.facingRight,
        dialogue: dialogue ?? this.dialogue,
        scale: scale ?? this.scale,
      );
}

// ── Story Scene ──────────────────────────────────────────
class StoryScene {
  String id;
  BackgroundType background;
  SceneTimeOfDay timeOfDay;
  WeatherType weather;
  List<SceneCharacter> characters;
  String narration;
  int durationSeconds;
  TransitionType transition;
  CameraEffect cameraEffect;
  String music;
  String ambience;
  List<ParticleEffectType> effects;

  StoryScene({
    required this.id,
    this.background = BackgroundType.city,
    this.timeOfDay = SceneTimeOfDay.day,
    this.weather = WeatherType.none,
    this.characters = const [],
    this.narration = '',
    this.durationSeconds = 4,
    this.transition = TransitionType.fade,
    this.cameraEffect = CameraEffect.none,
    this.music = 'epic',
    this.ambience = 'city',
    this.effects = const [],
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'background': background.name,
        'timeOfDay': timeOfDay.name,
        'weather': weather.name,
        'characters': characters.map((c) => c.toJson()).toList(),
        'narration': narration,
        'durationSeconds': durationSeconds,
        'transition': transition.name,
        'cameraEffect': cameraEffect.name,
        'music': music,
        'ambience': ambience,
        'effects': effects.map((e) => e.name).toList(),
      };

  factory StoryScene.fromJson(Map<String, dynamic> j) => StoryScene(
        id: j['id'] ?? DateTime.now().toString(),
        background: BackgroundType.values.firstWhere(
          (b) => b.name == j['background'],
          orElse: () => BackgroundType.city,
        ),
        timeOfDay: SceneTimeOfDay.values.firstWhere(
          (t) => t.name == j['timeOfDay'],
          orElse: () => SceneTimeOfDay.day,
        ),
        weather: WeatherType.values.firstWhere(
          (w) => w.name == j['weather'],
          orElse: () => WeatherType.none,
        ),
        characters: (j['characters'] as List? ?? [])
            .map((c) => SceneCharacter.fromJson(Map<String, dynamic>.from(c)))
            .toList(),
        narration: j['narration'] ?? '',
        durationSeconds: j['durationSeconds'] ?? 4,
        transition: TransitionType.values.firstWhere(
          (t) => t.name == j['transition'],
          orElse: () => TransitionType.fade,
        ),
        cameraEffect: CameraEffect.values.firstWhere(
          (c) => c.name == j['cameraEffect'],
          orElse: () => CameraEffect.none,
        ),
        music: j['music'] ?? 'none',
        ambience: j['ambience'] ?? 'none',
        effects: (j['effects'] as List? ?? [])
            .map((e) => ParticleEffectType.values.firstWhere(
                  (p) => p.name == e,
                  orElse: () => ParticleEffectType.magic,
                ))
            .toList(),
      );
}

// ── Video Project ─────────────────────────────────────────
class VideoProject {
  String id;
  String title;
  String prompt;
  List<StoryScene> scenes;
  DateTime createdAt;
  DateTime updatedAt;
  String? exportPath;
  String status;

  VideoProject({
    required this.id,
    required this.title,
    this.prompt = '',
    this.scenes = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
    this.exportPath,
    this.status = 'draft',
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'prompt': prompt,
        'scenes': scenes.map((s) => s.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'exportPath': exportPath,
        'status': status,
      };

  factory VideoProject.fromJson(Map<String, dynamic> j) => VideoProject(
        id: j['id'] ?? '',
        title: j['title'] ?? 'Untitled',
        prompt: j['prompt'] ?? '',
        scenes: (j['scenes'] as List? ?? [])
            .map((s) => StoryScene.fromJson(Map<String, dynamic>.from(s)))
            .toList(),
        createdAt: DateTime.tryParse(j['createdAt'] ?? '') ?? DateTime.now(),
        updatedAt: DateTime.tryParse(j['updatedAt'] ?? '') ?? DateTime.now(),
        exportPath: j['exportPath'],
        status: j['status'] ?? 'draft',
      );
}
