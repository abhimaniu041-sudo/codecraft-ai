import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

abstract class AIProvider {
  String get name;
  Future<String> generate(String prompt, {int maxTokens = 2000});
}

class AIException implements Exception {
  final String message;
  const AIException(this.message);
  @override
  String toString() => 'AIException: $message';
}

// ─── GROQ ───────────────────────────────────────────────
class GroqProvider implements AIProvider {
  final String apiKey;
  final String model;

  const GroqProvider({
    required this.apiKey,
    this.model = 'llama3-70b-versatile',
  });

  @override
  String get name => 'Groq';

  @override
  Future<String> generate(String prompt, {int maxTokens = 2000}) async {
    final response = await http
        .post(
          Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $apiKey',
          },
          body: jsonEncode({
            'model': model,
            'max_tokens': maxTokens,
            'messages': [
              {'role': 'user', 'content': prompt},
            ],
          }),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['choices'][0]['message']['content'] as String?) ?? '';
    } else if (response.statusCode == 429) {
      throw const AIException('Groq rate limit reached');
    }
    throw AIException('Groq error: ${response.statusCode}');
  }
}

// ─── GEMINI ─────────────────────────────────────────────
class GeminiProvider implements AIProvider {
  final String apiKey;

  const GeminiProvider({required this.apiKey});

  @override
  String get name => 'Gemini';

  @override
  Future<String> generate(String prompt, {int maxTokens = 2000}) async {
    final response = await http
        .post(
          Uri.parse(
            'https://generativelanguage.googleapis.com/v1beta/models'
            '/gemini-pro:generateContent?key=$apiKey',
          ),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'contents': [
              {
                'parts': [
                  {'text': prompt},
                ],
              },
            ],
            'generationConfig': {'maxOutputTokens': maxTokens},
          }),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['candidates'][0]['content']['parts'][0]['text']
              as String?) ??
          '';
    } else if (response.statusCode == 429) {
      throw const AIException('Gemini rate limit reached');
    }
    throw AIException('Gemini error: ${response.statusCode}');
  }
}

// ─── OPENROUTER ─────────────────────────────────────────
class OpenRouterProvider implements AIProvider {
  final String apiKey;
  final String model;

  const OpenRouterProvider({
    required this.apiKey,
    this.model = 'mistralai/mistral-7b-instruct:free',
  });

  @override
  String get name => 'OpenRouter';

  @override
  Future<String> generate(String prompt, {int maxTokens = 2000}) async {
    final response = await http
        .post(
          Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $apiKey',
            'HTTP-Referer': 'https://codecraft.ai',
            'X-Title': 'CodeCraft AI',
          },
          body: jsonEncode({
            'model': model,
            'max_tokens': maxTokens,
            'messages': [
              {'role': 'user', 'content': prompt},
            ],
          }),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['choices'][0]['message']['content'] as String?) ?? '';
    } else if (response.statusCode == 429) {
      throw const AIException('OpenRouter rate limit reached');
    }
    throw AIException('OpenRouter error: ${response.statusCode}');
  }
}

// ─── HUGGING FACE ────────────────────────────────────────
class HuggingFaceProvider implements AIProvider {
  final String apiKey;
  final String model;

  const HuggingFaceProvider({
    required this.apiKey,
    this.model = 'mistralai/Mistral-7B-Instruct-v0.2',
  });

  @override
  String get name => 'HuggingFace';

  @override
  Future<String> generate(String prompt, {int maxTokens = 2000}) async {
    final response = await http
        .post(
          Uri.parse(
            'https://api-inference.huggingface.co/models/$model',
          ),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $apiKey',
          },
          body: jsonEncode({
            'inputs': prompt,
            'parameters': {
              'max_new_tokens': maxTokens,
              'return_full_text': false,
            },
          }),
        )
        .timeout(const Duration(seconds: 60));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List && data.isNotEmpty) {
        return (data[0]['generated_text'] as String?) ?? '';
      }
      return '';
    }
    throw AIException('HuggingFace error: ${response.statusCode}');
  }
}
