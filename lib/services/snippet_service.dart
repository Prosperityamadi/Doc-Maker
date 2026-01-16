import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SnippetService {
  // Singleton instance
  static final SnippetService _instance = SnippetService._internal();
  factory SnippetService() => _instance;
  SnippetService._internal();

  // In-memory snippets for now (can be moved to DB later)
  final Map<String, String> _snippets = {
    '!date': '', // Dynamic
    '!time': '', // Dynamic
    '!todo': '[] ',
    '!email': 'example@email.com',
    '!sign': 'Best regards,\nUnknown User',
    '!lorem': 'Lorem ipsum dolor sit amet, consectetur adipiscing elit.',
  };

  /// Check if the last word in the text matches a snippet.
  /// Returns the replacement text or null if no match.
  String? checkForSnippet(String text) {
    if (text.isEmpty) return null;

    // We only check when the user types a trigger character like space or enter.
    // However, the controller gives us the full text or delta.
    // Ideally, we look at the word immediately preceding the cursor.
    // For simplicity in this helper, we'll just check if the text *ends* with a snippet key.
    // The calling code (Editor) is responsible for extracting the word before cursor.

    // Actually, let's make this function take the "word before cursor".
    return null;
  }

  /// Get replacement for a specific keyword
  String? getReplacement(String keyword) {
    if (!_snippets.containsKey(keyword)) return null;

    // Handle dynamic snippets
    if (keyword == '!date') {
      return DateFormat('yyyy-MM-dd').format(DateTime.now());
    }
    if (keyword == '!time') {
      return DateFormat('HH:mm').format(DateTime.now());
    }

    return _snippets[keyword];
  }
}
