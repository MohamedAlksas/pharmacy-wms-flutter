/// Converts English text to Arabic script (transliteration).
/// No API calls â€” runs fully offline and instantly.
///
/// Designed for pharmaceutical / warehouse names:
///   Burfen        â†’ ط¨ط±ظˆظپظٹظ†
///   Paracetamol   â†’ ط¨ط§ط±ط§ط³ظٹطھط§ظ…ظˆظ„
///   Amoxicillin   â†’ ط£ظ…ظˆظƒط³ظٹط³ظٹظ„ظٹظ†
///   Aspirin       â†’ ط£ط³ط¨ط±ظٹظ†
library transliteration_service;

import 'package:pharmacy_wms/Models/app_localizations.dart';

class TransliterationService {
  // â”€â”€ In-memory cache â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static final Map<String, String> _cache = {};

  static void clearCache() => _cache.clear();

  // â”€â”€ Public API â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  /// Transliterate a single word/phrase.
  /// Returns the original string if language is English.
  static String transliterate(String text) {
    if (languageNotifier.value != AppLanguage.ar) return text;
    if (text.trim().isEmpty) return text;
    return _cache.putIfAbsent(text, () => _convert(text)));

  }

  /// Transliterate a list and return originalâ†’transliterated map.
  static Map<String, String> transliterateAll(List<String> texts) {
    final result = <String, String>{};
    for (final t in texts) {
      result[t] = transliterate(t);
    
return result;
  }

  // â”€â”€ Core conversion â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  static String _convert(String input) {
    // 1. Check the pharma dictionary first (exact match, case-insensitive)
    final lower = input.toLowerCase().trim();
    if (_pharmaDict.containsKey(lower)) return _pharmaDict[lower]!;

    // 2. Word-by-word: each word checked in dictionary, else letter-mapped
    final words = input.trim().split(RegExp(r'\s+')));

    return words.map(_convertWord).join(' ');
  
static String _convertWord(String word) {
    final key = word.toLowerCase();
    if (_pharmaDict.containsKey(key)) return _pharmaDict[key]!;
    return _letterMap(word);
  }

  /// Letter-by-letter mapping using common Englishâ†’Arabic phonetic rules.
  static String _letterMap(String word) {
    final buf = StringBuffer();
    final chars = word.toLowerCase().split('');
    int i = 0;

    while (i < chars.length) {
      final c = chars[i];
      final next = i + 1 < chars.length ? chars[i + 1] : '';
      final next2 = i + 2 < chars.length ? chars[i + 2] : '';

      // â”€â”€ Digraphs (must come before single-letter checks) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
      if (c == 'p' && next == 'h') {
        buf.write('ظپ'); i += 2; continue;
      }
      if (c == 'c' && next == 'h') {
        buf.write('ط´'); i += 2; continue;
      }
      if (c == 's' && next == 'h') {
        buf.write('ط´'); i += 2; continue;
      }
      if (c == 't' && next == 'h') {
        buf.write('ط«'); i += 2; continue;
      }
      if (c == 'g' && next == 'h') {
        // silent or 'f' sound (e.g. -ough)
        buf.write(''); i += 2; continue;
      }
      if (c == 'c' && next == 'k') {
        buf.write('ظƒ'); i += 2; continue;
      }
      if (c == 'q' && next == 'u') {
        buf.write('ظƒظˆ'); i += 2; continue;
      }
      if (c == 'x') {
        buf.write('ظƒط³'); i++; continue;
      }

      // â”€â”€ Vowels â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
      // Leading vowel gets hamza
      if (_isVowel(c) && i == 0) {
        buf.write(_leadingVowel(c, next)));
 i++; continue;
      }
      if (_isVowel(c)) {
        // Two consecutive vowels â€” write once
        if (_isVowel(next) && c == next) { i++; continue; }
        buf.write(_vowelMap[c] ?? ''); i++; continue;
      }

      // â”€â”€ Consonants â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
      // Double consonant â†’ write once
      if (c == next && !_isVowel(c)) {
        buf.write(_consonantMap[c] ?? c); i += 2; continue;
      }

      buf.write(_consonantMap[c] ?? c);
      i++;
    
return buf.toString();
  
static bool _isVowel(String c) => 'aeiou'.contains(c);

  static String _leadingVowel(String c, String next) {
    switch (c) {
      case 'a': return next == 'l' ? 'ط§ظ„' : 'ط£';
      case 'e': return 'ط¥';
      case 'i': return 'ط¥ظٹ';
      case 'o': return 'ط£ظˆ';
      case 'u': return 'ط£ظˆ';
      default:  return 'ط£';
    }
  
static const Map<String, String> _vowelMap = {
    'a': 'ط§',
    'e': 'ظٹ',
    'i': 'ظٹ',
    'o': 'ظˆ',
    'u': 'ظˆ',
  };

  static const Map<String, String> _consonantMap = {
    'b': 'ط¨',
    'c': 'ظƒ',  // default; overridden by digraphs above
    'd': 'ط¯',
    'f': 'ظپ',
    'g': 'ط¬',
    'h': 'ظ‡',
    'j': 'ط¬',
    'k': 'ظƒ',
    'l': 'ظ„',
    'm': 'ظ…',
    'n': 'ظ†',
    'p': 'ط¨',  // default; overridden by ph digraph
    'q': 'ظƒ',
    'r': 'ط±',
    's': 'ط³',
    't': 'طھ',
    'v': 'ظپ',
    'w': 'ظˆ',
    'y': 'ظٹ',
    'z': 'ط²',
    '-': '-',
    '/': '/',
    ' ': ' ',
  };

  // â”€â”€ Pharmaceutical dictionary â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // Common brand names and INN (International Nonproprietary Names).
  // Key = lowercase English.  Value = Arabic transliteration.
  static const Map<String, String> _pharmaDict = {
    // â”€â”€ Analgesics / Antipyretics â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    'paracetamol'      : 'ط¨ط§ط±ط§ط³ظٹطھط§ظ…ظˆظ„',
    'acetaminophen'    : 'ط£ط³ظٹطھط§ظ…ظٹظ†ظˆظپظٹظ†',
    'aspirin'          : 'ط£ط³ط¨ط±ظٹظ†',
    'ibuprofen'        : 'ط¥ظٹط¨ظˆط¨ط±ظˆظپظٹظ†',
    'burfen'           : 'ط¨ط±ظˆظپظٹظ†',
    'brufen'           : 'ط¨ط±ظˆظپظٹظ†',
    'diclofenac'       : 'ط¯ظٹظƒظ„ظˆظپظٹظ†ط§ظƒ',
    'naproxen'         : 'ظ†ط§ط¨ط±ظˆظƒط³ظٹظ†',
    'ketoprofen'       : 'ظƒظٹطھظˆط¨ط±ظˆظپظٹظ†',
    'ketorolac'        : 'ظƒظٹطھظˆط±ظˆظ„ط§ظƒ',
    'indomethacin'     : 'ط¥ظ†ط¯ظˆظ…ظٹط«ط§ط³ظٹظ†',
    'piroxicam'        : 'ط¨ظٹط±ظˆظƒط³ظٹظƒط§ظ…',
    'meloxicam'        : 'ظ…ظٹظ„ظˆظƒط³ظٹظƒط§ظ…',
    'celecoxib'        : 'ط³ظٹظ„ظٹظƒظˆظƒط³ظٹط¨',
    'tramadol'         : 'طھط±ط§ظ…ط§ط¯ظˆظ„',
    'morphine'         : 'ظ…ظˆط±ظپظٹظ†',
    'codeine'          : 'ظƒظˆط¯ظٹظٹظ†',
    'pethidine'        : 'ط¨ظٹط«ظٹط¯ظٹظ†',

    // â”€â”€ Antibiotics â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    'amoxicillin'      : 'ط£ظ…ظˆظƒط³ظٹط³ظٹظ„ظٹظ†',
    'ampicillin'       : 'ط£ظ…ط¨ظٹط³ظٹظ„ظٹظ†',
    'penicillin'       : 'ط¨ظ†ط³ظٹظ„ظٹظ†',
    'cephalexin'       : 'ط³ظٹظپط§ظ„ظٹظƒط³ظٹظ†',
    'cefuroxime'       : 'ط³ظٹظپظˆط±ظˆظƒط³ظٹظ…',
    'ceftriaxone'      : 'ط³ظٹظپطھط±ظٹط§ظƒط³ظˆظ†',
    'cefixime'         : 'ط³ظٹظپظٹظƒط³ظٹظ…',
    'azithromycin'     : 'ط£ط²ظٹط«ط±ظˆظ…ظٹط³ظٹظ†',
    'clarithromycin'   : 'ظƒظ„ط§ط±ظٹط«ط±ظˆظ…ظٹط³ظٹظ†',
    'erythromycin'     : 'ط¥ط±ظٹط«ط±ظˆظ…ظٹط³ظٹظ†',
    'ciprofloxacin'    : 'ط³ظٹط¨ط±ظˆظپظ„ظˆظƒط³ط§ط³ظٹظ†',
    'levofloxacin'     : 'ظ„ظٹظپظˆظپظ„ظˆظƒط³ط§ط³ظٹظ†',
    'doxycycline'      : 'ط¯ظˆظƒط³ظٹط³ظٹظƒظ„ظٹظ†',
    'tetracycline'     : 'طھظٹطھط±ط§ط³ظٹظƒظ„ظٹظ†',
    'metronidazole'    : 'ظ…ظٹطھط±ظˆظ†ظٹط¯ط§ط²ظˆظ„',
    'clindamycin'      : 'ظƒظ„ظٹظ†ط¯ط§ظ…ط§ظٹط³ظٹظ†',
    'trimethoprim'     : 'طھط±ظٹظ…ظٹط«ظˆط¨ط±ظٹظ…',
    'vancomycin'       : 'ظپط§ظ†ظƒظˆظ…ظٹط³ظٹظ†',
    'gentamicin'       : 'ط¬ظ†طھط§ظ…ظٹط³ظٹظ†',
    'augmentin'        : 'ط£ظˆط¬ظ…ظ†طھظٹظ†',
    'flagyl'           : 'ظپظ„ط§ط¬ظٹظ„',
    'zithromax'        : 'ط²ظٹط«ط±ظˆظ…ط§ظƒط³',
    'klacid'           : 'ظƒظ„ط§ط³ظٹط¯',

    // â”€â”€ Antifungals â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    'fluconazole'      : 'ظپظ„ظˆظƒظˆظ†ط§ط²ظˆظ„',
    'itraconazole'     : 'ط¥ظٹطھط±ط§ظƒظˆظ†ط§ط²ظˆظ„',
    'ketoconazole'     : 'ظƒظٹطھظˆظƒظˆظ†ط§ط²ظˆظ„',
    'clotrimazole'     : 'ظƒظ„ظˆطھط±ظٹظ…ط§ط²ظˆظ„',
    'miconazole'       : 'ظ…ظٹظƒظˆظ†ط§ط²ظˆظ„',
    'nystatin'         : 'ظ†ظٹط³طھط§طھظٹظ†',

    // â”€â”€ Antivirals â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    'acyclovir'        : 'ط£ط³ظٹظƒظ„ظˆظپظٹط±',
    'valacyclovir'     : 'ظپط§ظ„ط§ط³ظٹظƒظ„ظˆظپظٹط±',
    'oseltamivir'      : 'ط£ظˆط³ظٹظ„طھط§ظ…ظٹظپظٹط±',
    'tamiflu'          : 'طھط§ظ…ظٹظپظ„ظˆ',
    'remdesivir'       : 'ط±ظٹظ…ط¯ظٹط³ظٹظپظٹط±',

    // â”€â”€ Cardiovascular â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    'amlodipine'       : 'ط£ظ…ظ„ظˆط¯ظٹط¨ظٹظ†',
    'nifedipine'       : 'ظ†ظٹظپظٹط¯ظٹط¨ظٹظ†',
    'atenolol'         : 'ط£طھظٹظ†ظˆظ„ظˆظ„',
    'metoprolol'       : 'ظ…ظٹطھظˆط¨ط±ظˆظ„ظˆظ„',
    'propranolol'      : 'ط¨ط±ظˆط¨ط±ط§ظ†ظˆظ„ظˆظ„',
    'lisinopril'       : 'ظ„ظٹط³ظٹظ†ظˆط¨ط±ظٹظ„',
    'enalapril'        : 'ط¥ظ†ط§ظ„ط§ط¨ط±ظٹظ„',
    'ramipril'         : 'ط±ط§ظ…ظٹط¨ط±ظٹظ„',
    'losartan'         : 'ظ„ظˆط³ط§ط±طھط§ظ†',
    'valsartan'        : 'ظپط§ظ„ط³ط§ط±طھط§ظ†',
    'furosemide'       : 'ظپظٹظˆط±ظˆط³ظٹظ…ط§ظٹط¯',
    'spironolactone'   : 'ط³ط¨ظٹط±ظˆظ†ظˆظ„ط§ظƒطھظˆظ†',
    'hydrochlorothiazide': 'ظ‡ظٹط¯ط±ظˆظƒظ„ظˆط±ظˆط«ظٹط§ط²ظٹط¯',
    'digoxin'          : 'ط¯ظٹط¬ظˆظƒط³ظٹظ†',
    'warfarin'         : 'ظˆط§ط±ظپط§ط±ظٹظ†',
    'heparin'          : 'ظ‡ظٹط¨ط§ط±ظٹظ†',
    'clopidogrel'      : 'ظƒظ„ظˆط¨ظٹط¯ظˆط¬ط±ظٹظ„',
    'plavix'           : 'ط¨ظ„ط§ظپظٹظƒط³',
    'simvastatin'      : 'ط³ظٹظ…ظپط§ط³طھط§طھظٹظ†',
    'atorvastatin'     : 'ط£طھظˆط±ظپط§ط³طھط§طھظٹظ†',
    'rosuvastatin'     : 'ط±ظˆط³ظˆظپط§ط³طھط§طھظٹظ†',
    'isosorbide'       : 'ط¥ظٹط²ظˆط³ظˆط±ط¨ظٹط¯',
    'nitroglycerin'    : 'ظ†ظٹطھط±ظˆط¬ظ„ظٹط³ط±ظٹظ†',

    // â”€â”€ Respiratory â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    'salbutamol'       : 'ط³ط§ظ„ط¨ظٹظˆطھط§ظ…ظˆظ„',
    'albuterol'        : 'ط£ظ„ط¨ظٹظˆطھظٹط±ظˆظ„',
    'ventolin'         : 'ظپظ†طھظˆظ„ظٹظ†',
    'budesonide'       : 'ط¨ظٹظˆط¯ظٹط³ظˆظ†ظٹط¯',
    'fluticasone'      : 'ظپظ„ظˆطھظٹظƒط§ط²ظˆظ†',
    'salmeterol'       : 'ط³ط§ظ„ظ…ظٹطھظٹط±ظˆظ„',
    'theophylline'     : 'ط«ظٹظˆظپظٹظ„ظٹظ†',
    'montelukast'      : 'ظ…ظˆظ†طھظٹظ„ظˆظƒط§ط³طھ',
    'ipratropium'      : 'ط¥ط¨ط±ط§طھط±ظˆط¨ظٹظˆظ…',
    'cetirizine'       : 'ط³ظٹطھظٹط±ظٹط²ظٹظ†',
    'loratadine'       : 'ظ„ظˆط±ط§طھط§ط¯ظٹظ†',
    'fexofenadine'     : 'ظپظٹظƒط³ظˆظپظٹظ†ط§ط¯ظٹظ†',
    'promethazine'     : 'ط¨ط±ظˆظ…ظٹط«ط§ط²ظٹظ†',
    'chlorphenamine'   : 'ظƒظ„ظˆط±ظپظٹظ†ط§ظ…ظٹظ†',
    'dextromethorphan' : 'ط¯ظٹظƒط³طھط±ظˆظ…ظٹط«ظˆط±ظپط§ظ†',
    'guaifenesin'      : 'ط¬ظˆط§ظٹظپظٹظ†ظٹط³ظٹظ†',

    // â”€â”€ GIT â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    'omeprazole'       : 'ط£ظˆظ…ظٹط¨ط±ط§ط²ظˆظ„',
    'pantoprazole'     : 'ط¨ط§ظ†طھظˆط¨ط±ط§ط²ظˆظ„',
    'esomeprazole'     : 'ط¥ظٹط³ظˆظ…ظٹط¨ط±ط§ط²ظˆظ„',
    'ranitidine'       : 'ط±ط§ظ†ظٹطھظٹط¯ظٹظ†',
    'famotidine'       : 'ظپط§ظ…ظˆطھظٹط¯ظٹظ†',
    'metoclopramide'   : 'ظ…ظٹطھظˆظƒظ„ظˆط¨ط±ط§ظ…ظٹط¯',
    'domperidone'      : 'ط¯ظˆظ…ط¨ظٹط±ظٹط¯ظˆظ†',
    'ondansetron'      : 'ط£ظˆظ†ط¯ط§ظ†ط³ظٹطھط±ظˆظ†',
    'loperamide'       : 'ظ„ظˆط¨ظٹط±ط§ظ…ظٹط¯',
    'bisacodyl'        : 'ط¨ظٹط³ط§ظƒظˆط¯ظٹظ„',
    'lactulose'        : 'ظ„ط§ظƒطھظˆظ„ظˆط²',
    'sucralfate'       : 'ط³ظˆظƒط±ط§ظ„ظپظٹطھ',
    'antacid'          : 'ظ…ط¶ط§ط¯ ط­ظ…ظˆط¶ط©',
    'maalox'           : 'ظ…ط§ظ„ظˆظƒط³',
    'gaviscon'         : 'ط¬ط§ظپظٹط³ظƒظˆظ†',

    // â”€â”€ Endocrine / Diabetes â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    'metformin'        : 'ظ…ظٹطھظپظˆط±ظ…ظٹظ†',
    'glibenclamide'    : 'ط¬ظ„ظٹط¨ظٹظ†ظƒظ„ط§ظ…ظٹط¯',
    'glimepiride'      : 'ط¬ظ„ظٹظ…ظٹط¨ظٹط±ظٹط¯',
    'gliclazide'       : 'ط¬ظ„ظٹظƒظ„ط§ط²ظٹط¯',
    'sitagliptin'      : 'ط³ظٹطھط§ط¬ظ„ظٹط¨طھظٹظ†',
    'insulin'          : 'ط¥ظ†ط³ظˆظ„ظٹظ†',
    'levothyroxine'    : 'ظ„ظٹظپظˆط«ظٹط±ظˆظƒط³ظٹظ†',
    'thyroxine'        : 'ط«ظٹط±ظˆظƒط³ظٹظ†',
    'prednisolone'     : 'ط¨ط±ظٹط¯ظ†ظٹط²ظˆظ„ظˆظ†',
    'prednisone'       : 'ط¨ط±ظٹط¯ظ†ظٹط²ظˆظ†',
    'dexamethasone'    : 'ط¯ظٹظƒط³ط§ظ…ظٹط«ط§ط²ظˆظ†',
    'hydrocortisone'   : 'ظ‡ظٹط¯ط±ظˆظƒظˆط±طھظٹط²ظˆظ†',
    'methylprednisolone': 'ظ…ظٹط«ظٹظ„ ط¨ط±ظٹط¯ظ†ظٹط²ظˆظ„ظˆظ†',

    // â”€â”€ CNS / Psychiatry â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    'diazepam'         : 'ط¯ظٹط§ط²ظٹط¨ط§ظ…',
    'alprazolam'       : 'ط£ظ„ط¨ط±ط§ط²ظˆظ„ط§ظ…',
    'lorazepam'        : 'ظ„ظˆط±ط§ط²ظٹط¨ط§ظ…',
    'clonazepam'       : 'ظƒظ„ظˆظ†ط§ط²ظٹط¨ط§ظ…',
    'phenobarbital'    : 'ظپظٹظ†ظˆط¨ط§ط±ط¨ظٹطھط§ظ„',
    'phenytoin'        : 'ظپظٹظ†ظٹطھظˆظٹظ†',
    'carbamazepine'    : 'ظƒط§ط±ط¨ط§ظ…ط§ط²ظٹط¨ظٹظ†',
    'valproate'        : 'ظپط§ظ„ط¨ط±ظˆط§طھ',
    'valproic acid'    : 'ط­ظ…ط¶ ط§ظ„ظپط§ظ„ط¨ط±ظˆظٹظƒ',
    'levetiracetam'    : 'ظ„ظٹظپظٹطھظٹط±ط§ط³ظٹطھط§ظ…',
    'amitriptyline'    : 'ط£ظ…ظٹطھط±ظٹط¨طھظٹظ„ظٹظ†',
    'fluoxetine'       : 'ظپظ„ظˆظƒط³ظٹطھظٹظ†',
    'sertraline'       : 'ط³ظٹط±طھط±ط§ظ„ظٹظ†',
    'paroxetine'       : 'ط¨ط§ط±ظˆظƒط³ظٹطھظٹظ†',
    'escitalopram'     : 'ط¥ظٹط³ظٹطھط§ظ„ظˆط¨ط±ط§ظ…',
    'citalopram'       : 'ط³ظٹطھط§ظ„ظˆط¨ط±ط§ظ…',
    'haloperidol'      : 'ظ‡ط§ظ„ظˆط¨ظٹط±ظٹط¯ظˆظ„',
    'risperidone'      : 'ط±ظٹط³ط¨ظٹط±ظٹط¯ظˆظ†',
    'olanzapine'       : 'ط£ظˆظ„ط§ظ†ط²ط§ط¨ظٹظ†',
    'quetiapine'       : 'ظƒظˆظٹطھظٹط§ط¨ظٹظ†',
    'zolpidem'         : 'ط²ظˆظ„ط¨ظٹط¯ظٹظ…',

    // â”€â”€ Vitamins / Supplements â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    'vitamin c'        : 'ظپظٹطھط§ظ…ظٹظ† ط¬',
    'vitamin d'        : 'ظپظٹطھط§ظ…ظٹظ† ط¯',
    'vitamin b12'      : 'ظپظٹطھط§ظ…ظٹظ† ط¨ظ،ظ¢',
    'vitamin b6'       : 'ظپظٹطھط§ظ…ظٹظ† ط¨ظ¦',
    'folic acid'       : 'ط­ظ…ط¶ ط§ظ„ظپظˆظ„ظٹظƒ',
    'ferrous sulfate'  : 'ظƒط¨ط±ظٹطھط§طھ ط§ظ„ط­ط¯ظٹط¯',
    'iron'             : 'ط­ط¯ظٹط¯',
    'calcium'          : 'ظƒط§ظ„ط³ظٹظˆظ…',
    'zinc'             : 'ط²ظ†ظƒ',
    'magnesium'        : 'ظ…ط؛ظ†ظٹط³ظٹظˆظ…',
    'potassium'        : 'ط¨ظˆطھط§ط³ظٹظˆظ…',
    'omega 3'          : 'ط£ظˆظ…ظٹط¬ط§ 3',
    'fish oil'         : 'ط²ظٹطھ ط§ظ„ط³ظ…ظƒ',

    // â”€â”€ Topical / Dermatology â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    'betamethasone'    : 'ط¨ظٹطھط§ظ…ظٹط«ط§ط²ظˆظ†',
    'mometasone'       : 'ظ…ظˆظ…ظٹطھط§ط²ظˆظ†',
    'triamcinolone'    : 'طھط±ط§ظٹط§ظ…ط³ظٹظ†ظˆظ„ظˆظ†',
    'calamine'         : 'ظƒط§ظ„ط§ظ…ظٹظ†',
    'permethrin'       : 'ط¨ظٹط±ظ…ظٹط«ط±ظٹظ†',

    // â”€â”€ Ophthalmology â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    'timolol'          : 'طھظٹظ…ظˆظ„ظˆظ„',
    'latanoprost'      : 'ظ„ط§طھط§ظ†ظˆط¨ط±ظˆط³طھ',
    'pilocarpine'      : 'ط¨ظٹظ„ظˆظƒط§ط±ط¨ظٹظ†',
    'tobramycin'       : 'طھظˆط¨ط±ط§ظ…ظٹط³ظٹظ†',
    'ofloxacin'        : 'ط£ظˆظپظ„ظˆظƒط³ط§ط³ظٹظ†',

    // â”€â”€ Common brand names (Egypt market) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    'panadol'          : 'ط¨ط§ظ†ط§ط¯ظˆظ„',
    'cataflam'         : 'ظƒطھط§ظپظ„ط§ظ…',
    'voltaren'         : 'ظپظˆظ„طھط§ط±ظٹظ†',
    'norgesic'         : 'ظ†ظˆط±ط¬ظٹط²ظٹظƒ',
    'brufen retard'    : 'ط¨ط±ظˆظپظٹظ† ط±ظٹطھط§ط±ط¯',
    'nurofen'          : 'ظ†ظˆط±ظˆظپظٹظ†',
    // 'zithromax'        : 'ط²ظٹط«ط±ظˆظ…ط§ظƒط³',
    // 'augmentin'        : 'ط£ظˆط¬ظ…ظ†طھظٹظ†',
    'ospamox'          : 'ط£ظˆط³ط¨ط§ظ…ظˆظƒط³',
    'zinnat'           : 'ط²ظٹظ†ط§طھ',
    'suprax'           : 'ط³ظˆط¨ط±ط§ظƒط³',
    'nexium'           : 'ظ†ظٹظƒط³ظٹظˆظ…',
    'losec'            : 'ظ„ظˆط³ظٹظƒ',
    'zantac'           : 'ط²ط§ظ†طھط§ظƒ',
    'primperan'        : 'ط¨ط±ظٹظ…ط¨ظٹط±ط§ظ†',
    'motilium'         : 'ظ…ظˆطھظٹظ„ظٹظˆظ…',
    'zofran'           : 'ط²ظˆظپط±ط§ظ†',
    'imodium'          : 'ط¥ظٹظ…ظˆط¯ظٹظˆظ…',
    'glucophage'       : 'ط¬ظ„ظˆظƒظˆظپط§ط¬',
    'amaryl'           : 'ط£ظ…ط§ط±ظٹظ„',
    'concor'           : 'ظƒظˆظ†ظƒظˆط±',
    'norvasc'          : 'ظ†ظˆط±ظپط§ط³ظƒ',
    'cozaar'           : 'ظƒظˆط²ط§ط±',
    'diovan'           : 'ط¯ظٹظˆظپط§ظ†',
    'lipitor'          : 'ظ„ظٹط¨ظٹطھظˆط±',
    'zocor'            : 'ط²ظˆظƒظˆط±',
    'crestor'          : 'ظƒط±ظٹط³طھظˆط±',
    'xanax'            : 'ط²ط§ظ†ط§ظƒط³',
    'valium'           : 'ظپط§ظ„ظٹظˆظ…',
    'rivotril'         : 'ط±ظٹظپظˆطھط±ظٹظ„',
    'tegretol'         : 'طھظٹط¬ط±ظٹطھظˆظ„',
    'depakine'         : 'ط¯ظٹط¨ط§ظƒظٹظ†',
    'prozac'           : 'ط¨ط±ظˆط²ط§ظƒ',
    'zoloft'           : 'ط²ظˆظ„ظˆظپطھ',
    'cipralex'         : 'ط³ظٹط¨ط±ط§ظ„ظٹظƒط³',
    'lexapro'          : 'ظ„ظٹظƒط³ط§ط¨ط±ظˆ',
    'risperdal'        : 'ط±ظٹط³ط¨ظٹط±ط¯ط§ظ„',
    'zyprexa'          : 'ط²ظٹط¨ط±ظٹظƒط³ط§',
    'seroquel'         : 'ط³ظٹط±ظˆظƒظˆظٹظ„',
    'ambien'           : 'ط£ظ…ط¨ظٹط§ظ†',
    'stilnox'          : 'ط³طھظٹظ„ظ†ظˆظƒط³',
    'synthroid'        : 'ط³ظٹظ†ط«ط±ظˆظٹط¯',
    'eltroxin'         : 'ط¥ظ„طھط±ظˆظƒط³ظٹظ†',
    'decadron'         : 'ط¯ظٹظƒط§ط¯ط±ظˆظ†',
    'medrol'           : 'ظ…ظٹط¯ط±ظˆظ„',
    'betnovate'        : 'ط¨ظٹطھظ†ظˆظپظٹطھ',
    'elocon'           : 'ط¥ظٹظ„ظˆظƒظˆظ†',
    'zovirax'          : 'ط²ظˆظپظٹط±ط§ظƒط³',
    'diflucan'         : 'ط¯ظٹظپظ„ظˆظƒط§ظ†',
    'klaricid'         : 'ظƒظ„ط§ط±ظٹط³ظٹط¯',
  };
}
