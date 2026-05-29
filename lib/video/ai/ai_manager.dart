import 'dart:convert';
import 'package:codecraft_ai/video/ai/ai_provider.dart';
import 'package:codecraft_ai/video/ai/ai_config.dart';
import 'package:http/http.dart' as http;

class RateLimitException implements Exception {
  final String message;
  const RateLimitException(this.message);
  @override
  String toString() => 'RateLimitException: $message';
}

class AIProviderException implements Exception {
  final String message;
  const AIProviderException(this.message);
  @override
  String toString() => 'AIProviderException: $message';
}

class AIManager {
  static bool _configured = false;
  static final List<AIProvider> _providers = [];

  static void configure() {
    _providers.clear();
    if (AIConfig.groqApiKey.isNotEmpty) {
      _providers.add(GroqProvider(apiKey: AIConfig.groqApiKey));
    }
    if (AIConfig.geminiApiKey.isNotEmpty) {
      _providers.add(GeminiProvider(apiKey: AIConfig.geminiApiKey));
    }
    if (AIConfig.openRouterApiKey.isNotEmpty) {
      _providers.add(
        OpenRouterProvider(apiKey: AIConfig.openRouterApiKey),
      );
    }
    if (AIConfig.huggingFaceApiKey.isNotEmpty) {
      _providers.add(
        HuggingFaceProvider(apiKey: AIConfig.huggingFaceApiKey),
      );
    }
    if (_providers.isEmpty) {
      _providers.add(
        const OpenRouterProvider(apiKey: 'free'),
      );
    }
    _configured = true;
  }

  static Future<String> generate(
    String prompt, {
    int maxTokens = 2000,
  }) async {
    if (!_configured || _providers.isEmpty) configure();

    Exception? lastError;
    for (final provider in _providers) {
      try {
        final result = await provider.generate(
          prompt,
          maxTokens: maxTokens,
        );
        if (result.isNotEmpty) return result;
      } catch (e) {
        lastError = e is Exception ? e : Exception(e.toString());
        continue;
      }
    }
    throw AIProviderException(
      'All AI providers failed: ${lastError?.toString() ?? "unknown"}',
    );
  }
}
