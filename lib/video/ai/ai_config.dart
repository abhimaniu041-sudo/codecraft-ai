class AIConfig {
  static String groqApiKey = '';
  static String geminiApiKey = '';
  static String openRouterApiKey = '';
  static String huggingFaceApiKey = '';

  static const String groqBaseUrl =
      'https://api.groq.com/openai/v1';
  static const String openRouterBaseUrl =
      'https://openrouter.ai/api/v1';

  static void setKeys({
    String groq = '',
    String gemini = '',
    String openRouter = '',
    String huggingFace = '',
  }) {
    groqApiKey = groq;
    geminiApiKey = gemini;
    openRouterApiKey = openRouter;
    huggingFaceApiKey = huggingFace;
  }
}
