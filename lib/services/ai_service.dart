import 'dart:convert';
import 'package:http/http.dart' as http;

class AIService {
  static const String _apiKey = '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';
  static const String _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';
  static const String _model = 'llama-3.3-70b-versatile';

  static Future<String> sendMessage({
    required String userMessage,
    required String systemPrompt,
    int maxTokens = 4096,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': _model,
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': userMessage},
          ],
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
      throw Exception('Error: $e');
    }
  }
}
