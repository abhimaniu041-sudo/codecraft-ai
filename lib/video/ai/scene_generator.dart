import 'dart:convert';
import 'package:codecraft_ai/video/ai/ai_manager.dart';

class SceneGenerator {
  static Future<List<Map<String, dynamic>>> generateScenes(
    String prompt,
  ) async {
    AIManager.configure();

    final aiPrompt = '''
Generate a video scene list for: "$prompt"
Return only a JSON array. No explanation.
Format: [{"title":"Scene Name","description":"What happens","duration":3}]
Maximum 5 scenes. Duration in seconds (2-8).
''';

    try {
      final result = await AIManager.generate(
        aiPrompt,
        maxTokens: 800,
      );
      return _parseScenes(result);
    } catch (_) {
      return _defaultScenes(prompt);
    }
  }

  static List<Map<String, dynamic>> _parseScenes(String text) {
    try {
      final start = text.indexOf('[');
      final end = text.lastIndexOf(']');
      if (start == -1 || end == -1 || end <= start) {
        return _defaultScenes('');
      }
      final jsonStr = text.substring(start, end + 1);
      final List<dynamic> parsed = jsonDecode(jsonStr);
      return parsed
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } catch (_) {
      return _defaultScenes('');
    }
  }

  static List<Map<String, dynamic>> _defaultScenes(String topic) {
    return [
      {
        'title': 'Opening',
        'description': topic.isNotEmpty ? topic : 'Introduction',
        'duration': 3,
      },
      {
        'title': 'Main Scene',
        'description': 'Main content',
        'duration': 5,
      },
      {
        'title': 'Ending',
        'description': 'Conclusion',
        'duration': 3,
      },
    ];
  }
}
