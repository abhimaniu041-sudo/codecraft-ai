import 'dart:async';
import 'ai_provider.dart';

class AIManager {
  static final AIManager _instance = AIManager._internal();
  factory AIManager() => _instance;
  AIManager._internal();

  final List<AIProvider> _providers = [];
  int _currentIndex = 0;
  final Map<String, String> _responseCache = {};

  void configure({
    required String groqKey,
    String geminiKey = '',
    String openRouterKey = '',
    String huggingFaceKey = '',
  }) {
    _providers.clear();

    if (groqKey.isNotEmpty) {
      _providers.add(GroqProvider(apiKey: groqKey));
    }
    if (geminiKey.isNotEmpty) {
      _providers.add(GeminiProvider(apiKey: geminiKey));
    }
    if (openRouterKey.isNotEmpty) {
      _providers.add(OpenRouterProvider(apiKey: openRouterKey));
    }
    if (huggingFaceKey.isNotEmpty) {
      _providers.add(HuggingFaceProvider(apiKey: huggingFaceKey));
    }

    _currentIndex = 0;
  }

  Future<String> generate(
    String prompt, {
    int maxTokens = 2000,
    String systemPrompt = '',
    bool useCache = true,
  }) async {
    final cacheKey = '${prompt.hashCode}_$maxTokens';

    if (useCache && _responseCache.containsKey(cacheKey)) {
      return _responseCache[cacheKey]!;
    }

    if (_providers.isEmpty) {
      throw AIProviderException('No AI providers configured');
    }

    final fullPrompt =
        systemPrompt.isNotEmpty ? '$systemPrompt\n\n$prompt' : prompt;

    for (int attempt = 0; attempt < _providers.length; attempt++) {
      final index = (_currentIndex + attempt) % _providers.length;
      final provider = _providers[index];

      try {
        final result = await provider.generate(
          fullPrompt,
          maxTokens: maxTokens,
        );
        if (result.isNotEmpty) {
          if (useCache) _responseCache[cacheKey] = result;
          return result;
        }
      } on RateLimitException {
        continue;
      } on AIProviderException {
        continue;
      } on TimeoutException {
        continue;
      } catch (_) {
        continue;
      }
    }

    throw AIProviderException('All AI providers failed');
  }

  String get currentProviderName =>
      _providers.isNotEmpty ? _providers[_currentIndex].name : 'None';

  void clearCache() => _responseCache.clear();

  int get providerCount => _providers.length;
}
