import 'package:flutter/material.dart';

///
/// Emoji storage and parser.
/// You will need to instantiate one of this instance to start using.
///
class EmojiParser {
  static final RegExp REGEX_EMOJI = RegExp(
    r'(?![\u{2766}\u{2984}\u{3000}\u{3002}\u{301C}\u{3030}\u{303D}\u{309F}\u{30A0}\u{30FC}\u{30FF}\u{31F0}-\u{31FF}\u{3220}-\u{3243}\u{3250}\u{3251}-\u{325F}\u{32D0}-\u{32FE}\u{3300}-\u{33FF}\u{4E00}-\u{9FFF}\u{FF01}-\u{FF5E}\u{FF65}-\u{FF9F}'
    r'\u{0021}-\u{002F}\u{003A}-\u{003F}\u{005B}-\u{0060}\u{007B}-\u{007E}\u{00A1}-\u{00BF}\u{2000}-\u{206F}\u{3000}-\u{303F}\u{FE30}-\u{FE4F}\u{FE50}-\u{FE6F}\u{FF00}-\u{FF0F}\u{FF1A}-\u{FF1F}\u{FF3B}-\u{FF40}\u{FF5B}-\u{FF64}])'
    r'[\u{1F300}-\u{1F9FF}\u{1F600}-\u{1F64F}\u{1F680}-\u{1F6FF}\u{1F700}-\u{1F77F}\u{1F780}-\u{1F7FF}\u{1F800}-\u{1F8FF}\u{1F900}-\u{1F9FF}'
    r'\u{2000}-\u{206F}\u{2300}-\u{23FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}\u{2B50}\u{2B55}\u{2E80}-\u{2EFF}\u{3000}-\u{303F}'
    r'\u{1F004}\u{1F0CF}\u{1F170}-\u{1F171}\u{1F17E}-\u{1F17F}\u{1F18E}\u{203C}\u{2049}\u{20E3}\u{2122}\u{2139}\u{2194}-\u{2199}'
    r'\u{21A9}-\u{21AA}\u{231A}-\u{231B}\u{2328}\u{23CF}\u{23E9}-\u{23F3}\u{23F8}-\u{23FA}\u{24C2}\u{25AA}-\u{25AB}\u{25B6}\u{25C0}'
    r'\u{25FB}-\u{25FE}\u{2600}-\u{2604}\u{260E}\u{2611}\u{2614}-\u{2615}\u{2618}\u{261D}\u{2620}\u{2622}-\u{2623}\u{2626}\u{262A}'
    r'\u{262E}-\u{262F}\u{2638}-\u{263A}\u{2640}\u{2642}\u{2648}-\u{2653}\u{265F}-\u{2660}\u{2663}-\u{2666}\u{2668}\u{267B}\u{267E}-\u{267F}'
    r'\u{2692}-\u{2697}\u{2699}\u{269B}-\u{269C}\u{26A0}-\u{26A1}\u{26AA}-\u{26AB}\u{26B0}-\u{26B1}\u{26BD}-\u{26BE}\u{26C4}-\u{26C5}'
    r'\u{26C8}\u{26CE}-\u{26CF}\u{26D1}\u{26D3}-\u{26D4}\u{26E9}-\u{26EA}\u{26F0}-\u{26F5}\u{26F7}-\u{26FA}\u{26FD}\u{2702}\u{2705}'
    r'\u{2708}-\u{270D}\u{270F}\u{2712}\u{2714}\u{2716}\u{271D}\u{2721}\u{2728}\u{2733}-\u{2734}\u{2744}\u{2747}\u{274C}\u{274E}\u{2753}-\u{2755}'
    r'\u{2757}\u{2763}-\u{2764}\u{2795}-\u{2797}\u{27A1}\u{27B0}\u{27BF}\u{2934}-\u{2935}\u{2B05}-\u{2B07}\u{2B1B}-\u{2B1C}\u{2B50}\u{2B55}'
    r'\u{3030}\u{303D}\u{3297}\u{3299}\u{1F004}\u{1F0CF}\u{1F170}-\u{1F171}\u{1F17E}-\u{1F17F}\u{1F18E}\u{1F191}-\u{1F19A}\u{1F1E6}-\u{1F1FF}'
    r'\u{1F201}-\u{1F202}\u{1F21A}\u{1F22F}\u{1F232}-\u{1F23A}\u{1F250}-\u{1F251}\u{1F300}-\u{1F321}\u{1F324}-\u{1F393}\u{1F396}-\u{1F397}'
    r'\u{1F399}-\u{1F39B}\u{1F39E}-\u{1F3F0}\u{1F3F3}-\u{1F3F5}\u{1F3F7}-\u{1F4FD}\u{1F4FF}-\u{1F53D}\u{1F549}-\u{1F54E}\u{1F550}-\u{1F567}'
    r'\u{1F56F}-\u{1F570}\u{1F573}-\u{1F579}\u{1F587}\u{1F58A}-\u{1F58D}\u{1F590}\u{1F595}-\u{1F596}\u{1F5A4}-\u{1F5A5}\u{1F5A8}\u{1F5B1}-\u{1F5B2}'
    r'\u{1F5BC}\u{1F5C2}-\u{1F5C4}\u{1F5D1}-\u{1F5D3}\u{1F5DC}-\u{1F5DE}\u{1F5E1}\u{1F5E3}\u{1F5E8}\u{1F5EF}\u{1F5F3}\u{1F5FA}-\u{1F64F}'
    r'\u{1F680}-\u{1F6C5}\u{1F6CB}-\u{1F6CF}\u{1F6D2}-\u{1F6D5}\u{1F6E0}-\u{1F6E5}\u{1F6E9}\u{1F6EB}-\u{1F6EC}\u{1F6F0}\u{1F6F3}-\u{1F6F8}'
    r'\u{1F6FF}\u{1F700}-\u{1F773}\u{1F780}-\u{1F7D4}\u{1F7D6}-\u{1F7FF}\u{1F800}-\u{1F80B}\u{1F810}-\u{1F847}\u{1F850}-\u{1F859}'
    r'\u{1F860}-\u{1F887}\u{1F890}-\u{1F8AD}\u{1F900}-\u{1F90B}\u{1F90D}-\u{1F971}\u{1F973}-\u{1F976}\u{1F97A}-\u{1F9A2}\u{1F9B0}-\u{1F9B9}'
    r'\u{1F9C0}-\u{1F9C2}\u{1F9D0}-\u{1F9FF}\u{1FA60}-\u{1FA6D}\u{1FA70}-\u{1FA74}\u{1FA78}-\u{1FA7A}\u{1FA80}-\u{1FA86}\u{1FA90}-\u{1FAA8}'
    r'\u{1FAD0}-\u{1FAD6}\u{20000}-\u{2FFFD}\u{30000}-\u{3FFFD}\u{E000}-\u{F8FF}\u{F0000}-\u{FFFFD}\u{100000}-\u{10FFFD}]+',
    unicode: true,
  );

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
    for (final c in Characters(text))
      if (!REGEX_EMOJI.hasMatch(c)) res = false;
    return res;
  }
}
