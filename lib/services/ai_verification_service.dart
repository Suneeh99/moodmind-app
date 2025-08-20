import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class AIVerificationService {
  static const String _baseUrl = 'https://api-inference.huggingface.co/models';
  static const String _apiKey =
      'YOUR_HUGGING_FACE_API_KEY'; // Get free API key from huggingface.co

  // Using BLIP-2 for image captioning and analysis
  static const String _visionModel = 'Salesforce/blip2-opt-2.7b';

  // Using a text classification model for task verification
  static const String textModel = 'microsoft/DialoGPT-medium';

  Future<bool> verifyTaskCompletion(String taskTitle, File imageFile) async {
    try {
      // Step 1: Get image description using BLIP-2
      final imageDescription = await _getImageDescription(imageFile);

      if (imageDescription == null) {
        print('Failed to get image description');
        return false;
      }

      // Step 2: Analyze if the description matches the task
      final isVerified = await _analyzeTaskCompletion(
        taskTitle,
        imageDescription,
      );

      return isVerified;
    } catch (e) {
      print('AI Verification Error: $e');
      return false;
    }
  }

  Future<String?> _getImageDescription(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();

      final response = await http.post(
        Uri.parse('$_baseUrl/$_visionModel'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/octet-stream',
        },
        body: bytes,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List && data.isNotEmpty) {
          return data[0]['generated_text'] as String?;
        }
      } else if (response.statusCode == 503) {
        // Model is loading, wait and retry
        await Future.delayed(const Duration(seconds: 10));
        return _getImageDescription(imageFile);
      } else {
        print(
          'Image description API Error: ${response.statusCode} - ${response.body}',
        );
      }

      return null;
    } catch (e) {
      print('Error getting image description: $e');
      return null;
    }
  }

  Future<bool> _analyzeTaskCompletion(
    String taskTitle,
    String imageDescription,
  ) async {
    try {
      // Create a prompt for task verification
      final prompt = _createVerificationPrompt(taskTitle, imageDescription);

      final response = await http.post(
        Uri.parse('$_baseUrl/microsoft/DialoGPT-medium'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'inputs': prompt,
          'parameters': {'max_length': 50, 'temperature': 0.1},
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List && data.isNotEmpty) {
          final generatedText = data[0]['generated_text'] as String;
          return _parseVerificationResult(generatedText);
        }
      } else if (response.statusCode == 503) {
        // Model is loading, wait and retry
        await Future.delayed(const Duration(seconds: 10));
        return _analyzeTaskCompletion(taskTitle, imageDescription);
      } else {
        print(
          'Text analysis API Error: ${response.statusCode} - ${response.body}',
        );
      }

      // Fallback to keyword matching if API fails
      return _fallbackVerification(taskTitle, imageDescription);
    } catch (e) {
      print('Error analyzing task completion: $e');
      return _fallbackVerification(taskTitle, imageDescription);
    }
  }

  String _createVerificationPrompt(String taskTitle, String imageDescription) {
    return '''
Task: $taskTitle
Image shows: $imageDescription

Question: Does the image show evidence that the task "$taskTitle" has been completed?
Answer with YES or NO only:
''';
  }

  bool _parseVerificationResult(String result) {
    final cleanResult = result.toLowerCase().trim();
    return cleanResult.contains('yes') ||
        cleanResult.contains('completed') ||
        cleanResult.contains('done') ||
        cleanResult.contains('finished');
  }

  bool _fallbackVerification(String taskTitle, String imageDescription) {
    // Simple keyword matching as fallback
    final taskWords = taskTitle.toLowerCase().split(' ');
    final descriptionWords = imageDescription.toLowerCase().split(' ');

    // Check for task-related keywords in the image description
    int matchCount = 0;
    for (final taskWord in taskWords) {
      if (taskWord.length > 3) {
        // Only consider meaningful words
        for (final descWord in descriptionWords) {
          if (descWord.contains(taskWord) || taskWord.contains(descWord)) {
            matchCount++;
            break;
          }
        }
      }
    }

    // Additional context-based verification
    final taskContext = _getTaskContext(taskTitle);
    final contextMatch = _checkContextMatch(taskContext, imageDescription);

    // Verification logic: require either good keyword match or context match
    return (matchCount >= 2) || contextMatch;
  }

  String _getTaskContext(String taskTitle) {
    final title = taskTitle.toLowerCase();

    if (title.contains('exercise') ||
        title.contains('workout') ||
        title.contains('gym')) {
      return 'fitness';
    } else if (title.contains('study') ||
        title.contains('read') ||
        title.contains('book')) {
      return 'education';
    } else if (title.contains('clean') ||
        title.contains('wash') ||
        title.contains('organize')) {
      return 'cleaning';
    } else if (title.contains('cook') ||
        title.contains('meal') ||
        title.contains('food')) {
      return 'cooking';
    } else if (title.contains('work') ||
        title.contains('project') ||
        title.contains('meeting')) {
      return 'work';
    } else if (title.contains('walk') ||
        title.contains('run') ||
        title.contains('jog')) {
      return 'outdoor';
    }

    return 'general';
  }

  bool _checkContextMatch(String context, String description) {
    final desc = description.toLowerCase();

    switch (context) {
      case 'fitness':
        return desc.contains('gym') ||
            desc.contains('exercise') ||
            desc.contains('workout') ||
            desc.contains('fitness') ||
            desc.contains('running') ||
            desc.contains('weights');

      case 'education':
        return desc.contains('book') ||
            desc.contains('study') ||
            desc.contains('reading') ||
            desc.contains('desk') ||
            desc.contains('computer') ||
            desc.contains('notes');

      case 'cleaning':
        return desc.contains('clean') ||
            desc.contains('tidy') ||
            desc.contains('organized') ||
            desc.contains('neat') ||
            desc.contains('vacuum') ||
            desc.contains('wash');

      case 'cooking':
        return desc.contains('kitchen') ||
            desc.contains('food') ||
            desc.contains('cooking') ||
            desc.contains('meal') ||
            desc.contains('plate') ||
            desc.contains('dish');

      case 'work':
        return desc.contains('computer') ||
            desc.contains('desk') ||
            desc.contains('office') ||
            desc.contains('laptop') ||
            desc.contains('meeting') ||
            desc.contains('work');

      case 'outdoor':
        return desc.contains('outside') ||
            desc.contains('park') ||
            desc.contains('street') ||
            desc.contains('nature') ||
            desc.contains('walking') ||
            desc.contains('running');

      default:
        return false;
    }
  }

  Future<int> calculatePoints(String taskTitle, bool isVerified) async {
    // Base points calculation
    int basePoints = 10;

    // Bonus points for verification
    if (isVerified) {
      basePoints += 5;
    }

    // Additional points based on task complexity and type
    final title = taskTitle.toLowerCase();
    final words = title.split(' ');

    // Length bonus
    if (words.length > 3) basePoints += 2;
    if (words.length > 6) basePoints += 3;

    // Category bonuses
    if (title.contains('exercise') ||
        title.contains('workout') ||
        title.contains('gym')) {
      basePoints += 5; // Fitness tasks get more points
    } else if (title.contains('study') ||
        title.contains('read') ||
        title.contains('learn')) {
      basePoints += 4; // Education tasks
    } else if (title.contains('work') ||
        title.contains('project') ||
        title.contains('meeting')) {
      basePoints += 3; // Work tasks
    } else if (title.contains('clean') || title.contains('organize')) {
      basePoints += 2; // Cleaning tasks
    }

    // Time-based bonus (morning tasks get extra points)
    final now = DateTime.now();
    if (now.hour >= 6 && now.hour <= 10) {
      basePoints += 2; // Morning bonus
    }

    return basePoints.clamp(5, 50); // Ensure points are within reasonable range
  }

  // Alternative method using a different free model
  Future<bool> verifyWithAlternativeModel(
    String taskTitle,
    File imageFile,
  ) async {
    try {
      // Using ViT-GPT2 for image captioning as alternative
      const alternativeModel = 'nlpconnect/vit-gpt2-image-captioning';

      final bytes = await imageFile.readAsBytes();

      final response = await http.post(
        Uri.parse('$_baseUrl/$alternativeModel'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/octet-stream',
        },
        body: bytes,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List && data.isNotEmpty) {
          final caption = data[0]['generated_text'] as String;
          return _fallbackVerification(taskTitle, caption);
        }
      }

      return false;
    } catch (e) {
      print('Alternative verification error: $e');
      return false;
    }
  }
}
