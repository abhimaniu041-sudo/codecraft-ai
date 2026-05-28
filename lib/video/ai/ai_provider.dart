import 'dart:convert';
import 'package:http/http.dart' as http;

// ── AI Provider Interface ─────────────────────────────────
abstract class AIProvider {
  String get name;
  Future<String> generate(String prompt, {int maxTokens = 2000});
  Future<bool> isAvailable();
}

// ── Groq Provider ─────────────────────────────────────────
class GroqProvider implements AIProvider {
  final String apiKey;
  final String model;

  GroqProvider({
    required this.apiKey,
    this.model = 'llama-3.3-70b-versatile',
  });

  @override
  String get name => 'Groq';

  @override
  Future<bool> isAvailable() async {
    try {
      final response = await generate('test', maxTokens: 10)
          .timeout(const Duration(seconds: 5));
      return response.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<String> generate(String prompt, {int maxTokens = 2000}) async {
    final response = await http.post(
      Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': model,
        'max_tokens': maxTokens,
        'messages': [
          {'role': 'user', 'content': prompt}
        ],
      }),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'] ?? '';
    } else if (response.statusCode == 429) {
      throw RateLimitException('Groq rate limit reached');
    } else {
      throw AIException('Groq error: ${response.statusCode}');
    }
  }
}

// ── Gemini Provider ───────────────────────────────────────
class GeminiProvider implements AIProvider {
  final String apiKey;

  GeminiProvider({required this.apiKey});

  @override
  String get name => 'Gemini';

  @override
  Future<bool> isAvailable() async {
    try {
      final response = await generate('test', maxTokens: 10)
          .timeout(const Duration(seconds: 5));
      return response.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<String> generate(String prompt, {int maxTokens = 2000}) async {
    final response = await http.post(
      Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=$apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ],
        'generationConfig': {'maxOutputTokens': maxTokens},
      }),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['candidates'][0]['content']['parts'][0]['text'] ?? '';
    } else if (response.statusCode == 429) {
      throw RateLimitException('Gemini rate limit reached');
    } else {
      throw AIException('Gemini error: ${response.statusCode}');
    }
  }
}

// ── OpenRouter Provider ───────────────────────────────────
class OpenRouterProvider implements AIProvider {
  final String apiKey;
  final String model;

  OpenRouterProvider({
    required this.apiKey,
    this.model = 'mistralai/mistral-7b-instruct:free',
  });

  @override
  String get name => 'OpenRouter';

  @override
  Future<bool> isAvailable() async {
    try {
      final response = await generate('test', maxTokens: 10)
          .timeout(const Duration(seconds: 5));
      return response.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<String> generate(String prompt, {int maxTokens = 2000}) async {
    final response = await http.post(
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
          {'role': 'user', 'content': prompt}
        ],
      }),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'] ?? '';
    } else if (response.statusCode == 429) {
      throw RateLimitException('OpenRouter rate limit reached');
    } else {
      throw AIException('OpenRouter error: ${response.statusCode}');
    }
  }
}

// ── HuggingFace Provider ──────────────────────────────────
class HuggingFaceProvider implements AIProvider {
  final String apiKey;
  final String model;

  HuggingFaceProvider({
    required this.apiKey,
    this.model = 'mistralai/Mistral-7B-Instruct-v0.2',
  });

  @override
  String get name => 'HuggingFace';

  @override
  Future<bool> isAvailable() async {
    try {
      final response = await generate('test', maxTokens: 50)
          .timeout(const Duration(seconds: 10));
      return response.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<String> generate(String prompt, {int maxTokens = 2000}) async {
    final response = await http.post(
      Uri.parse(
          'https://api-inference.huggingface.co/models/$model'),
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
    ).timeout(const Duration(seconds: 60));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List && data.isNotEmpty) {
        return data[0]['generated_text'] ?? '';
      }
      return '';
    } else if (response.statusCode == 503) {
      throw AIException('HuggingFace model loading, please retry');
    } else {
      throw AIException('HuggingFace error: ${response.statusCode}');
    }
  }
}

// ── Exceptions ────────────────────────────────────────────
class RateLimitException implements Exception {
  final String message;
  const RateLimitException(this.message);
  @override
  String toString() => message;
}

class AIException implements Exception {
  final String message;
  const AIException(this.message);
  @override
  String toString() => message;
}
