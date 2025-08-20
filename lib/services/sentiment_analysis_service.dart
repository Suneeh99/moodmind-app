import 'dart:convert';
import 'package:http/http.dart' as http;

class SentimentAnalysisService {
  static const String _apiUrl = 'https://api.meaningcloud.com/sentiment-2.1';
  static const String _apiKey =
      'YOUR_HUGGING_FACE_API_KEY'; // Replace with actual API key

  // Reduced timeout for better UX
  static const Duration _timeout = Duration(seconds: 3);

  // Analyze sentiment using external API with faster timeout
  static Future<Map<String, dynamic>> analyzeSentiment(String text) async {
    try {
      print('Starting fast sentiment analysis...');

      // Quick validation
      if (text.trim().isEmpty) {
        return _getDefaultResult();
      }

      // Use faster API call with reduced timeout
      final response = await http
          .post(
            Uri.parse(_apiUrl),
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: {
              'key': _apiKey,
              'txt': text.length > 500
                  ? text.substring(0, 500)
                  : text, // Limit text length
              'lang': 'en',
            },
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status']['code'] == '0') {
          return _parseApiResponse(data);
        }
      }

      print('API failed, using fast local analysis');
      return analyzeLocalSentiment(text);
    } catch (e) {
      print('API error: $e, using fast local analysis');
      return analyzeLocalSentiment(text);
    }
  }

  // Optimized local sentiment analysis
  static Map<String, dynamic> analyzeLocalSentiment(String text) {
    try {
      print('Running optimized local sentiment analysis...');

      if (text.trim().isEmpty) {
        return _getDefaultResult();
      }

      // Convert to lowercase for faster processing
      final lowerText = text.toLowerCase();

      // Optimized keyword matching with scores
      final sentimentScores = <String, double>{
        'joy': 0.0,
        'sadness': 0.0,
        'anger': 0.0,
        'fear': 0.0,
        'neutral': 0.2, // Base neutral score
      };

      // Fast keyword detection with weighted scores
      final keywordMap = {
        'joy': {
          'happy': 0.8,
          'joy': 0.9,
          'excited': 0.7,
          'great': 0.6,
          'amazing': 0.8,
          'wonderful': 0.7,
          'fantastic': 0.8,
          'awesome': 0.7,
          'love': 0.6,
          'perfect': 0.7,
          'excellent': 0.8,
          'brilliant': 0.7,
          'good': 0.5,
          'smile': 0.6,
          'laugh': 0.7,
          'celebrate': 0.8,
          'success': 0.6,
        },
        'sadness': {
          'sad': 0.8,
          'cry': 0.8,
          'depressed': 0.9,
          'lonely': 0.7,
          'hurt': 0.6,
          'pain': 0.7,
          'disappointed': 0.6,
          'upset': 0.6,
          'down': 0.5,
          'miserable': 0.8,
          'heartbroken': 0.9,
          'grief': 0.8,
          'sorrow': 0.7,
        },
        'anger': {
          'angry': 0.8,
          'mad': 0.7,
          'furious': 0.9,
          'hate': 0.8,
          'annoyed': 0.6,
          'frustrated': 0.7,
          'irritated': 0.6,
          'rage': 0.9,
          'pissed': 0.8,
          'outraged': 0.8,
          'livid': 0.9,
          'disgusted': 0.7,
        },
        'fear': {
          'scared': 0.8,
          'afraid': 0.8,
          'anxious': 0.7,
          'worried': 0.6,
          'panic': 0.9,
          'nervous': 0.6,
          'terrified': 0.9,
          'frightened': 0.8,
          'stress': 0.6,
          'overwhelmed': 0.7,
          'concern': 0.5,
          'doubt': 0.5,
        },
      };

      // Fast keyword matching
      for (final emotion in keywordMap.keys) {
        for (final entry in keywordMap[emotion]!.entries) {
          if (lowerText.contains(entry.key)) {
            sentimentScores[emotion] = sentimentScores[emotion]! + entry.value;
          }
        }
      }

      // Normalize scores
      final totalScore = sentimentScores.values.reduce((a, b) => a + b);
      if (totalScore > 0) {
        sentimentScores.updateAll((key, value) => value / totalScore);
      }

      // Find dominant emotion
      String dominantEmotion = 'neutral';
      double maxScore = sentimentScores['neutral']!;

      for (final entry in sentimentScores.entries) {
        if (entry.value > maxScore) {
          maxScore = entry.value;
          dominantEmotion = entry.key;
        }
      }

      print('Fast local analysis completed: $dominantEmotion ($maxScore)');

      return {
        'success': true,
        'emotions': sentimentScores,
        'dominantEmotion': dominantEmotion,
        'confidenceScore': maxScore,
      };
    } catch (e) {
      print('Error in local sentiment analysis: $e');
      return _getDefaultResult();
    }
  }

  static Map<String, dynamic> _parseApiResponse(Map<String, dynamic> data) {
    try {
      // Parse API response and convert to our format
      final score = data['score_tag'] ?? 'NEU';
      final confidence = double.tryParse(data['confidence'] ?? '50') ?? 50.0;

      // Convert API response to our emotion format
      final emotions = <String, double>{
        'joy': 0.0,
        'sadness': 0.0,
        'anger': 0.0,
        'fear': 0.0,
        'neutral': 0.0,
      };

      String dominantEmotion = 'neutral';

      switch (score) {
        case 'P+':
        case 'P':
          emotions['joy'] = confidence / 100;
          dominantEmotion = 'joy';
          break;
        case 'N+':
        case 'N':
          emotions['sadness'] = confidence / 100;
          dominantEmotion = 'sadness';
          break;
        case 'NEU':
        default:
          emotions['neutral'] = confidence / 100;
          dominantEmotion = 'neutral';
          break;
      }

      return {
        'success': true,
        'emotions': emotions,
        'dominantEmotion': dominantEmotion,
        'confidenceScore': confidence / 100,
      };
    } catch (e) {
      print('Error parsing API response: $e');
      return _getDefaultResult();
    }
  }

  static Map<String, dynamic> _getDefaultResult() {
    return {
      'success': false,
      'emotions': {
        'joy': 0.0,
        'sadness': 0.0,
        'anger': 0.0,
        'fear': 0.0,
        'neutral': 1.0,
      },
      'dominantEmotion': 'neutral',
      'confidenceScore': 0.5,
    };
  }
}
