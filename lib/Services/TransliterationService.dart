/// Converts English text to Arabic script (transliteration).
/// No API calls — runs fully offline and instantly.
///
/// Designed for pharmaceutical / warehouse names:
///   Burfen        → بروفين
///   Paracetamol   → باراسيتامول
///   Amoxicillin   → أموكسيسيلين
///   Aspirin       → أسبرين
library transliteration_service;


import 'package:pharmacy_wms/Models/app_localizations.dart';


class TransliterationService {
  //  In-memory cache 
  static final Map<String, String> _cache = {};

  static void clearCache() => _cache.clear();

  //  Public API 

  /// Transliterate a single word/phrase.
  /// Returns the original string if language is English.
  static String transliterate(String text) {
    if (languageNotifier.value != AppLanguage.ar) return text;
    if (text.trim().isEmpty) return text;
    return _cache.putIfAbsent(text, () => _convert(text));
  }

  /// Transliterate a list and return original→transliterated map.
  static Map<String, String> transliterateAll(List<String> texts) {
    final result = <String, String>{};
    for (final t in texts) {
      result[t] = transliterate(t);
    }
    return result;
  }

  //  Core conversion 

  static String _convert(String input) {
    // 1. Check the pharma dictionary first (exact match, case-insensitive)
    final lower = input.toLowerCase().trim();
    if (_pharmaDict.containsKey(lower)) return _pharmaDict[lower]!;

    // 2. Word-by-word: each word checked in dictionary, else letter-mapped
    final words = input.trim().split(RegExp(r'\s+'));
    return words.map(_convertWord).join(' ');
  }



  static String _convertWord(String word) {
    final key = word.toLowerCase();
    if (_pharmaDict.containsKey(key)) return _pharmaDict[key]!;
    return _letterMap(word);
  }

  /// Letter-by-letter mapping using common English→Arabic phonetic rules.
  static String _letterMap(String word) {
    final buf = StringBuffer();
    final chars = word.toLowerCase().split('');
    int i = 0;

    while (i < chars.length) {
      final c = chars[i];
      final next = i + 1 < chars.length ? chars[i + 1] : '';
      final next2 = i + 2 < chars.length ? chars[i + 2] : '';

      //  Digraphs (must come before single-letter checks) 
      if (c == 'p' && next == 'h') {
        buf.write('ف'); i += 2; continue;
      }
      if (c == 'c' && next == 'h') {
        buf.write('ش'); i += 2; continue;
      }
      if (c == 's' && next == 'h') {
        buf.write('ش'); i += 2; continue;
      }
      if (c == 't' && next == 'h') {
        buf.write('ث'); i += 2; continue;
      }
      if (c == 'g' && next == 'h') {
        // silent or 'f' sound (e.g. -ough)
        buf.write(''); i += 2; continue;
      }
      if (c == 'c' && next == 'k') {
        buf.write('ك'); i += 2; continue;
      }
      if (c == 'q' && next == 'u') {
        buf.write('كو'); i += 2; continue;
      }
      if (c == 'x') {
        buf.write('كس'); i++; continue;
      }

      //  Vowels 
      // Leading vowel gets hamza
      if (_isVowel(c) && i == 0) {
        buf.write(_leadingVowel(c, next)); i++; continue;
      }
      if (_isVowel(c)) {
        // Two consecutive vowels — write once
        if (_isVowel(next) && c == next) { i++; continue; }
        buf.write(_vowelMap[c] ?? ''); i++; continue;
      }

      //  Consonants 
      // Double consonant → write once
      if (c == next && !_isVowel(c)) {
        buf.write(_consonantMap[c] ?? c); i += 2; continue;
      }

      buf.write(_consonantMap[c] ?? c);
      i++;
    }

    return buf.toString();
  }



  static bool _isVowel(String c) => 'aeiou'.contains(c);

  static String _leadingVowel(String c, String next) {
    switch (c) {
      case 'a': return next == 'l' ? 'ال' : 'أ';
      case 'e': return 'إ';
      case 'i': return 'إي';
      case 'o': return 'أو';
      case 'u': return 'أو';
      default:  return 'أ';
    }
  }



  static const Map<String, String> _vowelMap = {
    'a': 'ا',
    'e': 'ي',
    'i': 'ي',
    'o': 'و',
    'u': 'و',
  };

  static const Map<String, String> _consonantMap = {
    'b': 'ب',
    'c': 'ك',  // default; overridden by digraphs above
    'd': 'د',
    'f': 'ف',
    'g': 'ج',
    'h': 'ه',
    'j': 'ج',
    'k': 'ك',
    'l': 'ل',
    'm': 'م',
    'n': 'ن',
    'p': 'ب',  // default; overridden by ph digraph
    'q': 'ك',
    'r': 'ر',
    's': 'س',
    't': 'ت',
    'v': 'ف',
    'w': 'و',
    'y': 'ي',
    'z': 'ز',
    '-': '-',
    '/': '/',
    ' ': ' ',
  };

  //  Pharmaceutical dictionary 
  // Common brand names and INN (International Nonproprietary Names).
  // Key = lowercase English.  Value = Arabic transliteration.
  static const Map<String, String> _pharmaDict = {
    //  Analgesics / Antipyretics 
    'paracetamol'      : 'باراسيتامول',
    'acetaminophen'    : 'أسيتامينوفين',
    'aspirin'          : 'أسبرين',
    'ibuprofen'        : 'إيبوبروفين',
    'burfen'           : 'بروفين',
    'brufen'           : 'بروفين',
    'diclofenac'       : 'ديكلوفيناك',
    'naproxen'         : 'نابروكسين',
    'ketoprofen'       : 'كيتوبروفين',
    'ketorolac'        : 'كيتورولاك',
    'indomethacin'     : 'إندوميثاسين',
    'piroxicam'        : 'بيروكسيكام',
    'meloxicam'        : 'ميلوكسيكام',
    'celecoxib'        : 'سيليكوكسيب',
    'tramadol'         : 'ترامادول',
    'morphine'         : 'مورفين',
    'codeine'          : 'كوديين',
    'pethidine'        : 'بيثيدين',

    //  Antibiotics 
    'amoxicillin'      : 'أموكسيسيلين',
    'ampicillin'       : 'أمبيسيلين',
    'penicillin'       : 'بنسيلين',
    'cephalexin'       : 'سيفاليكسين',
    'cefuroxime'       : 'سيفوروكسيم',
    'ceftriaxone'      : 'سيفترياكسون',
    'cefixime'         : 'سيفيكسيم',
    'azithromycin'     : 'أزيثروميسين',
    'clarithromycin'   : 'كلاريثروميسين',
    'erythromycin'     : 'إريثروميسين',
    'ciprofloxacin'    : 'سيبروفلوكساسين',
    'levofloxacin'     : 'ليفوفلوكساسين',
    'doxycycline'      : 'دوكسيسيكلين',
    'tetracycline'     : 'تيتراسيكلين',
    'metronidazole'    : 'ميترونيدازول',
    'clindamycin'      : 'كليندامايسين',
    'trimethoprim'     : 'تريميثوبريم',
    'vancomycin'       : 'فانكوميسين',
    'gentamicin'       : 'جنتاميسين',
    'augmentin'        : 'أوجمنتين',
    'flagyl'           : 'فلاجيل',
    'zithromax'        : 'زيثروماكس',
    'klacid'           : 'كلاسيد',

    //  Antifungals 
    'fluconazole'      : 'فلوكونازول',
    'itraconazole'     : 'إيتراكونازول',
    'ketoconazole'     : 'كيتوكونازول',
    'clotrimazole'     : 'كلوتريمازول',
    'miconazole'       : 'ميكونازول',
    'nystatin'         : 'نيستاتين',

    //  Antivirals 
    'acyclovir'        : 'أسيكلوفير',
    'valacyclovir'     : 'فالاسيكلوفير',
    'oseltamivir'      : 'أوسيلتاميفير',
    'tamiflu'          : 'تاميفلو',
    'remdesivir'       : 'ريمديسيفير',

    //  Cardiovascular 
    'amlodipine'       : 'أملوديبين',
    'nifedipine'       : 'نيفيديبين',
    'atenolol'         : 'أتينولول',
    'metoprolol'       : 'ميتوبرولول',
    'propranolol'      : 'بروبرانولول',
    'lisinopril'       : 'ليسينوبريل',
    'enalapril'        : 'إنالابريل',
    'ramipril'         : 'راميبريل',
    'losartan'         : 'لوسارتان',
    'valsartan'        : 'فالسارتان',
    'furosemide'       : 'فيوروسيمايد',
    'spironolactone'   : 'سبيرونولاكتون',
    'hydrochlorothiazide': 'هيدروكلوروثيازيد',
    'digoxin'          : 'ديجوكسين',
    'warfarin'         : 'وارفارين',
    'heparin'          : 'هيبارين',
    'clopidogrel'      : 'كلوبيدوجريل',
    'plavix'           : 'بلافيكس',
    'simvastatin'      : 'سيمفاستاتين',
    'atorvastatin'     : 'أتورفاستاتين',
    'rosuvastatin'     : 'روسوفاستاتين',
    'isosorbide'       : 'إيزوسوربيد',
    'nitroglycerin'    : 'نيتروجليسرين',

    //  Respiratory 
    'salbutamol'       : 'سالبيوتامول',
    'albuterol'        : 'ألبيوتيرول',
    'ventolin'         : 'فنتولين',
    'budesonide'       : 'بيوديسونيد',
    'fluticasone'      : 'فلوتيكازون',
    'salmeterol'       : 'سالميتيرول',
    'theophylline'     : 'ثيوفيلين',
    'montelukast'      : 'مونتيلوكاست',
    'ipratropium'      : 'إبراتروبيوم',
    'cetirizine'       : 'سيتيريزين',
    'loratadine'       : 'لوراتادين',
    'fexofenadine'     : 'فيكسوفينادين',
    'promethazine'     : 'بروميثازين',
    'chlorphenamine'   : 'كلورفينامين',
    'dextromethorphan' : 'ديكستروميثورفان',
    'guaifenesin'      : 'جوايفينيسين',

    //  GIT 
    'omeprazole'       : 'أوميبرازول',
    'pantoprazole'     : 'بانتوبرازول',
    'esomeprazole'     : 'إيسوميبرازول',
    'ranitidine'       : 'رانيتيدين',
    'famotidine'       : 'فاموتيدين',
    'metoclopramide'   : 'ميتوكلوبراميد',
    'domperidone'      : 'دومبيريدون',
    'ondansetron'      : 'أوندانسيترون',
    'loperamide'       : 'لوبيراميد',
    'bisacodyl'        : 'بيساكوديل',
    'lactulose'        : 'لاكتولوز',
    'sucralfate'       : 'سوكرالفيت',
    'antacid'          : 'مضاد حموضة',
    'maalox'           : 'مالوكس',
    'gaviscon'         : 'جافيسكون',

    //  Endocrine / Diabetes 
    'metformin'        : 'ميتفورمين',
    'glibenclamide'    : 'جليبينكلاميد',
    'glimepiride'      : 'جليميبيريد',
    'gliclazide'       : 'جليكلازيد',
    'sitagliptin'      : 'سيتاجليبتين',
    'insulin'          : 'إنسولين',
    'levothyroxine'    : 'ليفوثيروكسين',
    'thyroxine'        : 'ثيروكسين',
    'prednisolone'     : 'بريدنيزولون',
    'prednisone'       : 'بريدنيزون',
    'dexamethasone'    : 'ديكساميثازون',
    'hydrocortisone'   : 'هيدروكورتيزون',
    'methylprednisolone': 'ميثيل بريدنيزولون',

    //  CNS / Psychiatry 
    'diazepam'         : 'ديازيبام',
    'alprazolam'       : 'ألبرازولام',
    'lorazepam'        : 'لورازيبام',
    'clonazepam'       : 'كلونازيبام',
    'phenobarbital'    : 'فينوباربيتال',
    'phenytoin'        : 'فينيتوين',
    'carbamazepine'    : 'كاربامازيبين',
    'valproate'        : 'فالبروات',
    'valproic acid'    : 'حمض الفالبرويك',
    'levetiracetam'    : 'ليفيتيراسيتام',
    'amitriptyline'    : 'أميتريبتيلين',
    'fluoxetine'       : 'فلوكسيتين',
    'sertraline'       : 'سيرترالين',
    'paroxetine'       : 'باروكسيتين',
    'escitalopram'     : 'إيسيتالوبرام',
    'citalopram'       : 'سيتالوبرام',
    'haloperidol'      : 'هالوبيريدول',
    'risperidone'      : 'ريسبيريدون',
    'olanzapine'       : 'أولانزابين',
    'quetiapine'       : 'كويتيابين',
    'zolpidem'         : 'زولبيديم',

    //  Vitamins / Supplements 
    'vitamin c'        : 'فيتامين ج',
    'vitamin d'        : 'فيتامين د',
    'vitamin b12'      : 'فيتامين ب١٢',
    'vitamin b6'       : 'فيتامين ب٦',
    'folic acid'       : 'حمض الفوليك',
    'ferrous sulfate'  : 'كبريتات الحديد',
    'iron'             : 'حديد',
    'calcium'          : 'كالسيوم',
    'zinc'             : 'زنك',
    'magnesium'        : 'مغنيسيوم',
    'potassium'        : 'بوتاسيوم',
    'omega 3'          : 'أوميجا 3',
    'fish oil'         : 'زيت السمك',

    //  Topical / Dermatology 
    'betamethasone'    : 'بيتاميثازون',
    'mometasone'       : 'موميتازون',
    'triamcinolone'    : 'ترايامسينولون',
    'calamine'         : 'كالامين',
    'permethrin'       : 'بيرميثرين',

    //  Ophthalmology 
    'timolol'          : 'تيمولول',
    'latanoprost'      : 'لاتانوبروست',
    'pilocarpine'      : 'بيلوكاربين',
    'tobramycin'       : 'توبراميسين',
    'ofloxacin'        : 'أوفلوكساسين',

    //  Common brand names (Egypt market) 
    'panadol'          : 'بانادول',
    'cataflam'         : 'كتافلام',
    'voltaren'         : 'فولتارين',
    'norgesic'         : 'نورجيزيك',
    'brufen retard'    : 'بروفين ريتارد',
    'nurofen'          : 'نوروفين',
    // 'zithromax'        : 'زيثروماكس',
    // 'augmentin'        : 'أوجمنتين',
    'ospamox'          : 'أوسباموكس',
    'zinnat'           : 'زينات',
    'suprax'           : 'سوبراكس',
    'nexium'           : 'نيكسيوم',
    'losec'            : 'لوسيك',
    'zantac'           : 'زانتاك',
    'primperan'        : 'بريمبيران',
    'motilium'         : 'موتيليوم',
    'zofran'           : 'زوفران',
    'imodium'          : 'إيموديوم',
    'glucophage'       : 'جلوكوفاج',
    'amaryl'           : 'أماريل',
    'concor'           : 'كونكور',
    'norvasc'          : 'نورفاسك',
    'cozaar'           : 'كوزار',
    'diovan'           : 'ديوفان',
    'lipitor'          : 'ليبيتور',
    'zocor'            : 'زوكور',
    'crestor'          : 'كريستور',
    'xanax'            : 'زاناكس',
    'valium'           : 'فاليوم',
    'rivotril'         : 'ريفوتريل',
    'tegretol'         : 'تيجريتول',
    'depakine'         : 'ديباكين',
    'prozac'           : 'بروزاك',
    'zoloft'           : 'زولوفت',
    'cipralex'         : 'سيبراليكس',
    'lexapro'          : 'ليكسابرو',
    'risperdal'        : 'ريسبيردال',
    'zyprexa'          : 'زيبريكسا',
    'seroquel'         : 'سيروكويل',
    'ambien'           : 'أمبيان',
    'stilnox'          : 'ستيلنوكس',
    'synthroid'        : 'سينثرويد',
    'eltroxin'         : 'إلتروكسين',
    'decadron'         : 'ديكادرون',
    'medrol'           : 'ميدرول',
    'betnovate'        : 'بيتنوفيت',
    'elocon'           : 'إيلوكون',
    'zovirax'          : 'زوفيراكس',
    'diflucan'         : 'ديفلوكان',
    'klaricid'         : 'كلاريسيد',
  };
}
