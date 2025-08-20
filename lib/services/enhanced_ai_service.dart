// lib/services/enhanced_ai_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/ai_config.dart';

class EnhancedAIService {
  static final EnhancedAIService _instance = EnhancedAIService._internal();
  factory EnhancedAIService() => _instance;
  EnhancedAIService._internal();

  /// Public entry. If HF key is missing, skips remote calls and uses local only.
  Future<bool> verifyTaskCompletion(String taskTitle, File imageFile) async {
    if (AIConfig.remoteEnabled) {
      final verificationMethods = [
        () => _verifyWithModel(
          taskTitle,
          imageFile,
          AIConfig.availableModels['vision_primary']!,
        ),
        () => _verifyWithModel(
          taskTitle,
          imageFile,
          AIConfig.availableModels['vision_alternative']!,
        ),
        () => _verifyWithModel(
          taskTitle,
          imageFile,
          AIConfig.availableModels['vision_backup']!,
        ),
      ];

      for (final method in verificationMethods) {
        try {
          final result = await method();
          if (result != null) return result;
        } catch (e) {
          // try the next method
        }
      }
    }

    // Final fallback: entirely local, zero-cost, no network
    return _localVerification(taskTitle, imageFile);
  }

  Future<bool?> _verifyWithModel(
    String taskTitle,
    File imageFile,
    String modelName,
  ) async {
    try {
      final description = await _getImageCaption(imageFile, modelName);
      if (description != null && description.trim().isNotEmpty) {
        return _analyzeTaskMatch(taskTitle, description);
      }
    } catch (_) {}
    return null;
  }

  Future<String?> _getImageCaption(File imageFile, String modelName) async {
    final bytes = await imageFile.readAsBytes();

    for (int attempt = 0; attempt < AIConfig.maxRetries; attempt++) {
      try {
        final uri = Uri.parse('${AIConfig.baseUrl}/$modelName');
        final res = await http
            .post(
              uri,
              headers: {
                'Authorization': 'Bearer ${AIConfig.huggingFaceApiKey}',
                'Content-Type': 'application/octet-stream',
              },
              body: bytes,
            )
            .timeout(AIConfig.modelLoadTimeout);

        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          // Most captioning endpoints return: [{"generated_text": "..."}]
          if (data is List && data.isNotEmpty) {
            final first = data.first;
            if (first is Map && first['generated_text'] is String) {
              return first['generated_text'] as String;
            }
            // some models use {"caption": "..."} or string response
            if (first is Map && first['caption'] is String) {
              return first['caption'] as String;
            }
          } else if (data is Map && data['generated_text'] is String) {
            return data['generated_text'] as String;
          } else if (data is String) {
            return data;
          }
        } else if (res.statusCode == 503) {
          // Model is loading — wait & retry
          await Future.delayed(AIConfig.retryDelay);
          continue;
        } else {
          // Other API error, stop trying this model
          break;
        }
      } catch (_) {
        if (attempt < AIConfig.maxRetries - 1) {
          await Future.delayed(AIConfig.retryDelay);
        }
      }
    }
    return null;
  }

  bool _analyzeTaskMatch(String taskTitle, String imageDescription) {
    final taskWords = _extractKeywords(taskTitle);
    final descWords = _extractKeywords(imageDescription);

    final similarityScore = _calculateSimilarity(taskWords, descWords);
    final contextScore = _getContextScore(taskTitle, imageDescription);

    final finalScore = (similarityScore * 0.6) + (contextScore * 0.4);

    // Tune as you like. 0.3 is lenient to help users succeed without frustration.
    return finalScore > 0.3;
  }

  List<String> _extractKeywords(String text) {
    final words = text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 2)
        .toList();

    const stop = {
      'the',
      'and',
      'for',
      'are',
      'but',
      'not',
      'you',
      'all',
      'can',
      'had',
      'her',
      'was',
      'one',
      'our',
      'out',
      'day',
      'get',
      'has',
      'him',
      'his',
      'how',
      'its',
      'may',
      'new',
      'now',
      'old',
      'see',
      'two',
      'who',
      'did',
      'she',
      'use',
      'way',
      'many',
      'with',
      'from',
    };
    return words.where((w) => !stop.contains(w)).toList();
  }

  double _calculateSimilarity(List<String> a, List<String> b) {
    if (a.isEmpty || b.isEmpty) return 0.0;
    int matches = 0;
    for (final w in a) {
      if (b.any((x) => _similar(w, x))) matches++;
    }
    return matches / a.length;
  }

  bool _similar(String w1, String w2) {
    if (w1 == w2) return true;
    if (w1.contains(w2) || w2.contains(w1)) return true;
    return _levenshtein(w1, w2) <= 2;
  }

  int _levenshtein(String s1, String s2) {
    if (s1.length < s2.length) return _levenshtein(s2, s1);
    if (s2.isEmpty) return s1.length;
    final prev = List<int>.generate(s2.length + 1, (i) => i);
    var cur = <int>[];
    for (var i = 0; i < s1.length; i++) {
      cur = [i + 1];
      for (var j = 0; j < s2.length; j++) {
        final ins = prev[j + 1] + 1;
        final del = cur[j] + 1;
        final sub = prev[j] + (s1[i] == s2[j] ? 0 : 1);
        cur.add(ins < del ? (ins < sub ? ins : sub) : (del < sub ? del : sub));
      }
      for (var k = 0; k < prev.length; k++) {
        prev[k] = cur[k];
      }
    }
    return cur.last;
  }

  double _getContextScore(String taskTitle, String imageDescription) {
    final category = _getTaskCategory(taskTitle);
    final keywords = _contextKeywords(category);
    final desc = imageDescription.toLowerCase();

    int hits = 0;
    for (final kw in keywords) {
      if (desc.contains(kw)) hits++;
    }
    return keywords.isEmpty ? 0.0 : hits / keywords.length;
  }

  String _getTaskCategory(String title) {
    final t = title.toLowerCase();
    final cats = {
      'fitness': [
        'exercise',
        'workout',
        'gym',
        'run',
        'walk',
        'jog',
        'fitness',
        'sport',
      ],
      'study': [
        'study',
        'read',
        'book',
        'learn',
        'homework',
        'research',
        'write',
      ],
      'work': [
        'work',
        'project',
        'meeting',
        'email',
        'call',
        'presentation',
        'report',
      ],
      'cleaning': [
        'clean',
        'wash',
        'organize',
        'tidy',
        'vacuum',
        'dust',
        'mop',
      ],
      'cooking': [
        'cook',
        'meal',
        'food',
        'recipe',
        'kitchen',
        'prepare',
        'eat',
      ],
      'personal': ['shower', 'brush', 'dress', 'sleep', 'wake', 'medicine'],
    };
    for (final entry in cats.entries) {
      if (entry.value.any((kw) => t.contains(kw))) return entry.key;
    }
    return 'general';
  }

  List<String> _contextKeywords(String category) {
    final map = {
      'fitness': [
        'gym',
        'exercise',
        'workout',
        'running',
        'walking',
        'sports',
        'fitness',
        'training',
      ],
      'study': [
        'book',
        'reading',
        'studying',
        'desk',
        'computer',
        'notes',
        'writing',
        'learning',
      ],
      'work': [
        'office',
        'computer',
        'desk',
        'laptop',
        'meeting',
        'working',
        'business',
      ],
      'cleaning': [
        'clean',
        'tidy',
        'organized',
        'neat',
        'vacuum',
        'washing',
        'cleaning',
      ],
      'cooking': [
        'kitchen',
        'food',
        'cooking',
        'meal',
        'plate',
        'dish',
        'recipe',
        'eating',
      ],
      'personal': [
        'bathroom',
        'bedroom',
        'mirror',
        'bed',
        'personal',
        'hygiene',
      ],
      'general': ['person', 'people', 'indoor', 'outdoor', 'activity', 'doing'],
    };
    return map[category] ?? map['general']!;
  }

  bool _localVerification(String taskTitle, File imageFile) {
    // No uploads, no persistence. Just a few checks for "real-ish" photos:
    try {
      final size = imageFile.lengthSync();
      if (size < 10 * 1024) return false; // too small
      if (size > 12 * 1024 * 1024) return false; // unusually large
      return true; // give benefit of doubt to keep it user-friendly
    } catch (_) {
      return false;
    }
  }

  Future<int> calculatePoints(String taskTitle, bool isVerified) async {
    int base = 10;
    if (isVerified) base += 5;

    final cat = _getTaskCategory(taskTitle);
    const catPts = {
      'fitness': 8,
      'study': 6,
      'work': 5,
      'cleaning': 4,
      'cooking': 4,
      'personal': 3,
      'general': 2,
    };
    base += catPts[cat] ?? 2;

    final hour = DateTime.now().hour;
    if (hour >= 6 && hour <= 9) base += 3;
    if (hour >= 22 || hour <= 5) base += 2;

    final words = taskTitle.split(RegExp(r'\s+')).length;
    if (words > 4) base += 2;
    if (words > 7) base += 3;

    return base.clamp(5, 50);
  }
}
