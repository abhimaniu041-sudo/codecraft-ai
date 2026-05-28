import 'dart:async';
import 'ai_provider.dart';

class AIManager {
  static final AIManager _instance = AIManager._internal();
  factory AIManager() => _instance;
  AIManager._internal();

  final List<AIProvider> _providers = [];
  int _currentIndex = 0;
  final Map<String, String> _cache = {};

  // ── Configure providers ───────────────────────────────
  void configure({
    required String groqKey,
    String geminiKey = '',
    String openRouterKey = '',
    String huggingFaceKey = '',
  }) {
    _providers.clear();
    _providers.add(GroqProvider(apiKey: groqKey));
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

  // ── Main generation with auto-fallback ────────────────
  Future<String> generate(
    String prompt, {
    int maxTokens = 2000,
    String systemPrompt = '',
    bool useCache = true,
  }) async {
    final fullPrompt = systemPrompt.isNotEmpty
        ? '$systemPrompt\n\n$prompt'
        : prompt;

    // Check cache first
    if (useCache && _cache.containsKey(fullPrompt)) {
      return _cache[fullPrompt]!;
    }

    if (_providers.isEmpty) {
      throw AIException('No AI providers configured');
    }

    int attempts = 0;
    int startIndex = _currentIndex;

    while (attempts < _providers.length) {
      final provider = _providers[_currentIndex];
      try {
        final result = await provider.generate(
          fullPrompt,
          maxTokens: maxTokens,
        );
        if (result.isNotEmpty) {
          // Cache successful result
          if (useCache) _cache[fullPrompt] = result;
          return result;
        }
        _switchToNext();
        attempts++;
      } on RateLimitException {
        _switchToNext();
        attempts++;
      } on AIException {
        _switchToNext();
        attempts++;
      } on TimeoutException {
        _switchToNext();
        attempts++;
      } catch (_) {
        _switchToNext();
        attempts++;
      }
    }

    throw AIException('All AI providers failed');
  }

  void _switchToNext() {
    _currentIndex = (_currentIndex + 1) % _providers.length;
  }

  String get currentProviderName =>
      _providers.isNotEmpty ? _providers[_currentIndex].name : 'None';

  void clearCache() => _cache.clear();

  int get providerCount => _providers.length;
}
