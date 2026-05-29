import 'package:codecraft_ai/video/ai/ai_provider.dart';
import 'package:codecraft_ai/video/ai/ai_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AIManager {
  static Future<String> generateText(String prompt) async {
    try {
      return await _tryGroq(prompt);
    } catch (_) {
      try {
        return await _tryGemini(prompt);
      } catch (e) {
        throw AIException('All AI providers failed: $e');
      }
    }
  }

  static Future<String> _tryGroq(String prompt) async {
    if (AIConfig.groqKey.isEmpty) throw AIException('No key');
    final response = await http.post(
      Uri.parse('${AIConfig.groqBaseUrl}/chat/completions'),
      headers: {
        'Authorization': 'Bearer ${AIConfig.groqKey}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': 'llama3-8b-8192',
        'messages': [
          {'role': 'user', 'content': prompt}
        ],
        'max_tokens': 500,
      }),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'];
    }
    throw AIException('Groq failed: ${response.statusCode}');
  }

  static Future<String> _tryGemini(String prompt) async {
    if (AIConfig.geminiKey.isEmpty) throw AIException('No key');
    final response = await http.post(
      Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/'
        'models/gemini-pro:generateContent'
        '?key=${AIConfig.geminiKey}',
      ),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ],
      }),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['candidates'][0]['content']['parts'][0]['text'];
    }
    throw AIException('Gemini failed: ${response.statusCode}');
  }
}
