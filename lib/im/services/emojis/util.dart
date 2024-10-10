import 'package:emoji_regex/emoji_regex.dart';
import 'package:flutter/material.dart';

///
/// Emoji storage and parser.
/// You will need to instantiate one of this instance to start using.
///
class EmojiParser {
  static final RegExp REGEX_EMOJI = emojiRegex();

  /// Returns true if the given text contains only emojis.
  ///
  /// "👋" -> true
  /// "👋 Hello" -> false
  /// ":wave:" --> false
  /// "👋👋" -> true
  /// "👋 👋" -> false (if [ignoreWhitespace] is true, result is true)
  static bool hasOnlyEmojis(String text, {bool ignoreWhitespace = false}) {
    if (ignoreWhitespace) text = text.replaceAll(' ', '');
    bool res = true;
    for (final c in Characters(text)) {
      if (!REGEX_EMOJI.hasMatch(c)) res = false;
    }
    return res;
  }

  static Iterable<RegExpMatch> getEmojis(
    String text, {
    bool ignoreWhitespace = false,
  }) {
    if (ignoreWhitespace) text = text.replaceAll(' ', '');
    return REGEX_EMOJI.allMatches(text);
  }
}
