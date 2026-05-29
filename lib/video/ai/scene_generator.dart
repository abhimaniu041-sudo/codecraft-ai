import 'package:codecraft_ai/video/ai/ai_manager.dart';
import 'package:codecraft_ai/video/ai/ai_config.dart';

class SceneGenerator {
  static Future<List<Map<String, dynamic>>> generateScenes(
    String prompt,
  ) async {
    AIManager.configure();

    final aiPrompt = '''
Generate a video scene list for: "$prompt"
Return JSON array only, no explanation.
Format: [{"title":"...","description":"...","duration":3}]
Maximum 5 scenes.
''';

    try {
      final result = await AIManager.generate(aiPrompt, maxTokens: 1000);
      return _parseScenes(result);
    } catch (e) {
      return _defaultScenes(prompt);
    }
  }

  static List<Map<String, dynamic>> _parseScenes(String json) {
    try {
      // Basic JSON extraction
      final start = json.indexOf('[');
      final end = json.lastIndexOf(']');
      if (start == -1 || end == -1) return [];
      // Return default for now — add dart:convert if needed
      return _defaultScenes('');
    } catch (_) {
      return [];
    }
  }

  static List<Map<String, dynamic>> _defaultScenes(String topic) {
    return [
      {
        'title': 'Opening',
        'description': topic.isNotEmpty ? topic : 'Introduction scene',
        'duration': 3,
      },
      {
        'title': 'Main Content',
        'description': 'Main story scene',
        'duration': 5,
      },
      {
        'title': 'Closing',
        'description': 'Ending scene',
        'duration': 3,
      },
    ];
  }
}
