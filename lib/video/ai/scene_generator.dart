import 'dart:convert';
import '../models/video_models.dart';
import 'ai_manager.dart';
import 'ai_config.dart';

class SceneGenerator {
  SceneGenerator() {
    AIManager().configure(
      groqKey: AIConfig.groqApiKey,
      geminiKey: AIConfig.geminiApiKey,
      openRouterKey: AIConfig.openRouterApiKey,
      huggingFaceKey: AIConfig.huggingFaceApiKey,
    );
  }

  final AIManager _ai = AIManager();

  Future<List<StoryScene>> generateStory(String prompt) async {
    try {
      final result = await _ai.generate(
        _buildPrompt(prompt),
        systemPrompt:
            'You are a cinematic AI cartoon director. Return ONLY valid JSON array. No markdown. No explanation.',
        maxTokens: 3000,
      );
      return _parseScenes(result);
    } catch (_) {
      return _fallbackScenes();
    }
  }

  List<StoryScene> _parseScenes(String raw) {
    try {
      final clean =
          raw.replaceAll('```json', '').replaceAll('```', '').trim();
      final start = clean.indexOf('[');
      final end = clean.lastIndexOf(']');
      if (start == -1 || end == -1) return _fallbackScenes();

      final List data = jsonDecode(clean.substring(start, end + 1));
      final scenes = <StoryScene>[];

      for (int i = 0; i < data.length; i++) {
        final s = Map<String, dynamic>.from(data[i]);
        s['id'] = '${DateTime.now().millisecondsSinceEpoch}_$i';
        scenes.add(StoryScene.fromJson(s));
      }

      return scenes.isNotEmpty ? scenes : _fallbackScenes();
    } catch (_) {
      return _fallbackScenes();
    }
  }

  List<StoryScene> _fallbackScenes() {
    return [
      StoryScene(
        id: '${DateTime.now().millisecondsSinceEpoch}_0',
        background: BackgroundType.city,
        timeOfDay: SceneTimeOfDay.day,
        weather: WeatherType.none,
        characters: [
          SceneCharacter(
            characterId: 'hero',
            state: 'idle',
            positionX: 0.35,
            positionY: 0.62,
            dialogue: 'The adventure begins!',
          ),
        ],
        narration: 'A new story unfolds...',
        durationSeconds: 4,
        cameraEffect: CameraEffect.zoomIn,
      ),
      StoryScene(
        id: '${DateTime.now().millisecondsSinceEpoch}_1',
        background: BackgroundType.cyberpunk,
        timeOfDay: SceneTimeOfDay.night,
        weather: WeatherType.none,
        characters: [
          SceneCharacter(
            characterId: 'hero',
            state: 'attack',
            positionX: 0.3,
            positionY: 0.62,
            dialogue: 'I will protect everyone!',
          ),
          SceneCharacter(
            characterId: 'villain',
            state: 'angry',
            positionX: 0.72,
            positionY: 0.62,
            facingRight: false,
            dialogue: 'You cannot stop me!',
          ),
        ],
        narration: 'The battle begins...',
        durationSeconds: 5,
        cameraEffect: CameraEffect.shake,
        effects: [ParticleEffectType.explosion],
      ),
      StoryScene(
        id: '${DateTime.now().millisecondsSinceEpoch}_2',
        background: BackgroundType.city,
        timeOfDay: SceneTimeOfDay.sunset,
        weather: WeatherType.none,
        characters: [
          SceneCharacter(
            characterId: 'hero',
            state: 'victory',
            positionX: 0.5,
            positionY: 0.62,
            dialogue: 'The city is safe!',
          ),
        ],
        narration: 'Peace is restored.',
        durationSeconds: 4,
        cameraEffect: CameraEffect.zoomOut,
      ),
    ];
  }

  String _buildPrompt(String prompt) {
    return '''Create 6 cinematic cartoon scenes for: "$prompt"

Return ONLY valid JSON array:
[
  {
    "background": "city",
    "timeOfDay": "day",
    "weather": "none",
    "characters": [
      {
        "characterId": "hero",
        "state": "idle",
        "positionX": 0.3,
        "positionY": 0.62,
        "facingRight": true,
        "dialogue": "I will save everyone!",
        "scale": 1.0
      }
    ],
    "narration": "In the heart of the city...",
    "durationSeconds": 4,
    "transition": "fade",
    "cameraEffect": "none",
    "effects": []
  }
]

backgrounds: city,cyberpunk,forest,space,underwater,volcano,castle,battlefield,beach,snow,desert,jungle,fantasy
timeOfDay: day,sunset,night
weather: none,rain,snow,fog
characterIds: hero,villain,robot,wizard,ninja,princess,warrior,alien,zombie,dragon
states: idle,walk,run,attack,jump,fly,talk,angry,happy,sad,victory,death,cast,defend
cameraEffect: none,shake,zoomIn,zoomOut,pan
effects: fire,smoke,explosion,magic,sparks
transitions: fade,flash,wipe,zoom,none''';
  }
}
