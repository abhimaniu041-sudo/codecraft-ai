import 'package:codecraft_ai/video/ai/ai_provider.dart';
import 'package:codecraft_ai/video/ai/ai_config.dart';

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
      // Free fallback — no key needed
      _providers.add(
        OpenRouterProvider(apiKey: 'free'),
      );
    }
  }

  static Future<String> generate(
    String prompt, {
    int maxTokens = 2000,
  }) async {
    if (_providers.isEmpty) configure();

    for (final provider in _providers) {
      try {
        final result = await provider.generate(
          prompt,
          maxTokens: maxTokens,
        );
        if (result.isNotEmpty) return result;
      } on RateLimitException {
        continue;
      } on AIException catch (e) {
        if (e.message.contains('429') ||
            e.message.contains('rate limit')) {
          continue;
        }
        rethrow;
      } catch (_) {
        continue;
      }
    }
    throw const AIProviderException('All AI providers failed');
  }
}
