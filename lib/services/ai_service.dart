import 'dart:convert';
import 'package:http/http.dart' as http;

class AIService {
  static const String _apiKey = 'apni_groq_key_yahan';
  static const String _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';
  static const String _model = 'llama-3.3-70b-versatile';

  static Future<String> sendMessage({
    required String userMessage,
    required String systemPrompt,
    List<Map<String, String>> history = const [],
    int maxTokens = 4096,
  }) async {
    try {
      final List<Map<String, dynamic>> messages = [
        {'role': 'system', 'content': systemPrompt},
        ...history,
        {'role': 'user', 'content': userMessage},
      ];

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': _model,
          'messages': messages,
          'max_tokens': maxTokens,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        final err = jsonDecode(response.body);
        throw Exception(err['error']['message'] ?? 'API Error');
      }
    } catch (e) {
      throw Exception('$e');
    }
  }
}
