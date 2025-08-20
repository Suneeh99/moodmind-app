class AIConfig {
  // Hugging Face public inference API
  // Leave the key empty to use ONLY local (free) verification.
  static const String huggingFaceApiKey =
      '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';

  static const String baseUrl = 'https://api-inference.huggingface.co/models';

  // Captioning models (all have free tiers on HF Inference, but rate-limited)
  static const Map<String, String> availableModels = {
    'vision_primary': 'Salesforce/blip-image-captioning-base',
    'vision_alternative': 'nlpconnect/vit-gpt2-image-captioning',
    'vision_backup': 'microsoft/git-base-coco',
  };

  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 3);
  static const Duration modelLoadTimeout = Duration(seconds: 25);

  // Convenience
  static bool get remoteEnabled => huggingFaceApiKey.trim().isNotEmpty;
}
