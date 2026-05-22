import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:http/http.dart' as http;

import 'package:pharmacy_wms/Models/app_localizations.dart';

/// Translates arbitrary strings to Arabic using the Anthropic API.
/// Results are cached in memory so each unique string is only translated once
/// per app session.
class TranslationService {
  static const String _apiUrl = 'https://api.anthropic.com/v1/messages';

  //  In-memory cache:  original → translated 
  static final Map<String, String> _cache = {};

  //  Pending futures to avoid duplicate in-flight requests 
  static final Map<String, Future<String>> _inflight = {};

  // 
  /// Translate a single string.
  /// Returns the original string immediately if the language is English,
  /// or if the string is already in the cache.
  static Future<String> translate(String text) async {
    if (languageNotifier.value != AppLanguage.ar) return text;
    if (text.trim().isEmpty) return text;

    // Return cached result instantly
    if (_cache.containsKey(text)) return _cache[text]!;

    // Deduplicate concurrent requests for the same string
    if (_inflight.containsKey(text)) return _inflight[text]!;

    final future = _doTranslate(text);
    _inflight[text] = future;

    try {
      final result = await future;
      _cache[text] = result;
      return result;
    } catch (e) {
      debugPrint('[TranslationService] Error translating "$text": $e');
      return text; // fallback: show original
    }
 finally {
      _inflight.remove(text);
    }
  }

  // 
  /// Translate a batch of strings in ONE API call (much more efficient).
  /// Returns a map of original → translated.
  static Future<Map<String, String>> translateBatch(
      List<String> texts) async {
    if (languageNotifier.value != AppLanguage.ar) {
      return {for (final t in texts) t: t};
    }


    final results = <String, String>{};
    final toFetch = <String>[];

    for (final text in texts) {
      if (text.trim().isEmpty) {
        results[text] = text;
      } else if (_cache.containsKey(text)) {
        results[text] = _cache[text]!;
      } else {
        toFetch.add(text);
      }
    }

    if (toFetch.isEmpty) return results;

    try {
      final translated = await _doTranslateBatch(toFetch);
      for (int i = 0; i < toFetch.length; i++) {
        final original = toFetch[i];
        final tr = i < translated.length ? translated[i] : original;
        _cache[original] = tr;
        results[original] = tr;
      }
    } catch (e) {
      debugPrint('[TranslationService] Batch error: $e');
      for (final t in toFetch) {
        results[t] = t;
      }
    }

    return results;
  }

  // 
  /// Clear the cache (e.g. when switching language back to English).
  static void clearCache() {
    _cache.clear();
    _inflight.clear();
  }

  //  Private helpers 

  static Future<String> _doTranslate(String text) async {
    final response = await http
        .post(
          Uri.parse(_apiUrl),
          headers: {
            'Content-Type': 'application/json',
            'anthropic-version': '2023-06-01',
          },
          body: jsonEncode({
            'model': 'claude-haiku-4-5-20251001',
            'max_tokens': 200,
            'messages': [
              {
                'role': 'user',
                'content':
                    'Translate the following pharmaceutical/warehouse term to Arabic. '
                    'Return ONLY the Arabic translation, nothing else, no explanation.\n\n'
                    'Text: $text',
              }
            ],
          }),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}');
    }


    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final content = decoded['content'] as List<dynamic>;
    return (content.first['text'] as String).trim();
  }


  static Future<List<String>> _doTranslateBatch(List<String> texts) async {
    // Build a numbered list so the model returns a numbered list back
    final numbered =
        texts.asMap().entries.map((e) => '${e.key + 1}. ${e.value}').join('\n');

    final response = await http
        .post(
          Uri.parse(_apiUrl),
          headers: {
            'Content-Type': 'application/json',
            'anthropic-version': '2023-06-01',
          },
          body: jsonEncode({
            'model': 'claude-haiku-4-5-20251001',
            'max_tokens': 1000,
            'messages': [
              {
                'role': 'user',
                'content':
                    'Translate the following pharmaceutical/warehouse terms to Arabic. '
                    'Return ONLY a numbered list with the Arabic translations in the same order. '
                    'No explanations, no extra text.\n\n'
                    '$numbered',
              }
            ],
          }),
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}');
    }


    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final content = decoded['content'] as List<dynamic>;
    final raw = (content.first['text'] as String).trim();

    // Parse "1. كلمة\n2. كلمة" → ['كلمة', 'كلمة']
    final lines = raw
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    return lines.map((line) {
      // Remove leading "1. " or "١. " etc.
      return line.replaceFirst(RegExp(r'^[\d١٢٣٤٥٦٧٨٩٠]+[.\-\)]\s*'), '').trim();
    }).toList();
  }
}
