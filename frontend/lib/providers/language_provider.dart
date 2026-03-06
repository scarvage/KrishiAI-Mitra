import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class AppLanguage {
  final String code;
  final String name;
  final String nativeName;
  final String flag;

  const AppLanguage({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.flag,
  });
}

class LanguageProvider extends ChangeNotifier {
  static const String _boxName = 'app_settings';
  static const String _languageKey = 'selected_language';
  static const String _languageSetKey = 'language_set';

  late Box _box;

  String _languageCode = 'hi';
  bool _isInitialized = false;

  String get languageCode => _languageCode;
  bool get isInitialized => _isInitialized;
  bool get isLanguageSet => _box.get(_languageSetKey, defaultValue: false) as bool;

  static const List<AppLanguage> supportedLanguages = [
    AppLanguage(code: 'hi', name: 'Hindi', nativeName: 'हिंदी', flag: '🇮🇳'),
    AppLanguage(code: 'en', name: 'English', nativeName: 'English', flag: '🇬🇧'),
    AppLanguage(code: 'pa', name: 'Punjabi', nativeName: 'ਪੰਜਾਬੀ', flag: '🌾'),
    AppLanguage(code: 'mr', name: 'Marathi', nativeName: 'मराठी', flag: '🌻'),
    AppLanguage(code: 'gu', name: 'Gujarati', nativeName: 'ગુજરાતી', flag: '🌿'),
    AppLanguage(code: 'bn', name: 'Bengali', nativeName: 'বাংলা', flag: '🌸'),
    AppLanguage(code: 'te', name: 'Telugu', nativeName: 'తెలుగు', flag: '🌴'),
    AppLanguage(code: 'ta', name: 'Tamil', nativeName: 'தமிழ்', flag: '🏵️'),
    AppLanguage(code: 'kn', name: 'Kannada', nativeName: 'ಕನ್ನಡ', flag: '🌺'),
    AppLanguage(code: 'ml', name: 'Malayalam', nativeName: 'മലയാളം', flag: '🌴'),
    AppLanguage(code: 'or', name: 'Odia', nativeName: 'ଓଡ଼ିଆ', flag: '🪷'),
    AppLanguage(code: 'ur', name: 'Urdu', nativeName: 'اردو', flag: '🌙'),
  ];

  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
    _languageCode = _box.get(_languageKey, defaultValue: 'hi') as String;
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> setLanguage(String code) async {
    _languageCode = code;
    await _box.put(_languageKey, code);
    await _box.put(_languageSetKey, true);
    notifyListeners();
  }

  AppLanguage get currentLanguage {
    return supportedLanguages.firstWhere(
      (l) => l.code == _languageCode,
      orElse: () => supportedLanguages.first,
    );
  }

  // Dashboard translations keyed by language code. Falls back to Hindi.
  static const Map<String, Map<String, String>> _translations = {
    'hi': {
      'greeting': 'नमस्ते, किसान भाई!',
      'what_to_do': 'क्या करना है?',
      'what_to_do_sub': 'आप क्या करना चाहेंगे?',
      'voice_title': 'आवाज़ से पूछो',
      'voice_sub': 'AI मित्र से सवाल पूछें',
      'disease_title': 'फसल की बीमारी',
      'disease_sub': 'फोटो से रोग पहचानें',
      'mandi_title': 'मंडी भाव',
      'mandi_sub': 'रीयल-टाइम फसल भाव',
      'crops_label': 'फसलें',
      'wheat_label': 'गेहूं भाव',
      'nav_home': 'होम',
      'nav_voice': 'आवाज़',
      'nav_disease': 'रोग',
      'nav_mandi': 'मंडी',
    },
    'en': {
      'greeting': 'Hello, Farmer!',
      'what_to_do': 'What to do?',
      'what_to_do_sub': 'What would you like to do?',
      'voice_title': 'Ask by Voice',
      'voice_sub': 'Ask farming questions',
      'disease_title': 'Disease Check',
      'disease_sub': 'Detect crop disease',
      'mandi_title': 'Market Prices',
      'mandi_sub': 'Real-time crop prices',
      'crops_label': 'Crops',
      'wheat_label': 'Wheat Price',
      'nav_home': 'Home',
      'nav_voice': 'Voice',
      'nav_disease': 'Disease',
      'nav_mandi': 'Market',
    },
    'pa': {
      'greeting': 'ਸਤਿ ਸ੍ਰੀ ਅਕਾਲ, ਕਿਸਾਨ ਵੀਰੇ!',
      'what_to_do': 'ਕੀ ਕਰਨਾ ਹੈ?',
      'what_to_do_sub': 'ਤੁਸੀਂ ਕੀ ਕਰਨਾ ਚਾਹੁੰਦੇ ਹੋ?',
      'voice_title': 'ਆਵਾਜ਼ ਨਾਲ ਪੁੱਛੋ',
      'voice_sub': 'AI ਮਿੱਤਰ ਤੋਂ ਸਵਾਲ ਪੁੱਛੋ',
      'disease_title': 'ਫਸਲ ਦੀ ਬੀਮਾਰੀ',
      'disease_sub': 'ਫੋਟੋ ਤੋਂ ਰੋਗ ਪਛਾਣੋ',
      'mandi_title': 'ਮੰਡੀ ਭਾਅ',
      'mandi_sub': 'ਅਸਲ-ਸਮੇਂ ਦੇ ਭਾਅ',
      'crops_label': 'ਫਸਲਾਂ',
      'wheat_label': 'ਕਣਕ ਭਾਅ',
      'nav_home': 'ਹੋਮ',
      'nav_voice': 'ਆਵਾਜ਼',
      'nav_disease': 'ਰੋਗ',
      'nav_mandi': 'ਮੰਡੀ',
    },
    'mr': {
      'greeting': 'नमस्कार, शेतकरी बंधू!',
      'what_to_do': 'काय करायचे?',
      'what_to_do_sub': 'तुम्हाला काय करायचे आहे?',
      'voice_title': 'आवाजाने विचारा',
      'voice_sub': 'AI मित्राला प्रश्न विचारा',
      'disease_title': 'पिकाचा रोग',
      'disease_sub': 'फोटोवरून रोग ओळखा',
      'mandi_title': 'बाजार भाव',
      'mandi_sub': 'रिअल-टाइम भाव',
      'crops_label': 'पिके',
      'wheat_label': 'गहू भाव',
      'nav_home': 'होम',
      'nav_voice': 'आवाज',
      'nav_disease': 'रोग',
      'nav_mandi': 'बाजार',
    },
    'gu': {
      'greeting': 'નમસ્તે, ખેડૂત ભાઈ!',
      'what_to_do': 'શું કરવું છે?',
      'what_to_do_sub': 'તમે શું કરવા માંગો છો?',
      'voice_title': 'અવાજ દ્વારા પૂછો',
      'voice_sub': 'AI મિત્રને પ્રશ્ન પૂછો',
      'disease_title': 'પાકનો રોગ',
      'disease_sub': 'ફોટોથી રોગ ઓળખો',
      'mandi_title': 'મંડી ભાવ',
      'mandi_sub': 'રિયલ-ટાઇમ ભાવ',
      'crops_label': 'પાક',
      'wheat_label': 'ઘઉં ભાવ',
      'nav_home': 'હોમ',
      'nav_voice': 'અવાજ',
      'nav_disease': 'રોગ',
      'nav_mandi': 'મંડી',
    },
    'bn': {
      'greeting': 'নমস্কার, কৃষক ভাই!',
      'what_to_do': 'কী করতে হবে?',
      'what_to_do_sub': 'আপনি কী করতে চান?',
      'voice_title': 'কণ্ঠে জিজ্ঞেস করুন',
      'voice_sub': 'AI বন্ধুকে প্রশ্ন করুন',
      'disease_title': 'ফসলের রোগ',
      'disease_sub': 'ছবি থেকে রোগ চিহ্নিত করুন',
      'mandi_title': 'মান্ডি মূল্য',
      'mandi_sub': 'রিয়েল-টাইম মূল্য',
      'crops_label': 'ফসল',
      'wheat_label': 'গম মূল্য',
      'nav_home': 'হোম',
      'nav_voice': 'কণ্ঠ',
      'nav_disease': 'রোগ',
      'nav_mandi': 'মান্ডি',
    },
    'te': {
      'greeting': 'నమస్కారం, రైతు అన్నా!',
      'what_to_do': 'ఏమి చేయాలి?',
      'what_to_do_sub': 'మీరు ఏమి చేయాలనుకుంటున్నారు?',
      'voice_title': 'గొంతుతో అడగండి',
      'voice_sub': 'AI మిత్రుడిని ప్రశ్నలు అడగండి',
      'disease_title': 'పంట వ్యాధి',
      'disease_sub': 'ఫోటో ద్వారా వ్యాధిని గుర్తించండి',
      'mandi_title': 'మండి ధరలు',
      'mandi_sub': 'రియల్-టైమ్ ధరలు',
      'crops_label': 'పంటలు',
      'wheat_label': 'గోధుమ ధర',
      'nav_home': 'హోమ్',
      'nav_voice': 'గొంతు',
      'nav_disease': 'వ్యాధి',
      'nav_mandi': 'మండి',
    },
    'ta': {
      'greeting': 'வணக்கம், விவசாயி!',
      'what_to_do': 'என்ன செய்ய வேண்டும்?',
      'what_to_do_sub': 'நீங்கள் என்ன செய்ய விரும்புகிறீர்கள்?',
      'voice_title': 'குரலில் கேளுங்கள்',
      'voice_sub': 'AI நண்பரிடம் கேளுங்கள்',
      'disease_title': 'பயிர் நோய்',
      'disease_sub': 'புகைப்படத்தில் நோயை கண்டறியவும்',
      'mandi_title': 'மண்டி விலைகள்',
      'mandi_sub': 'நிகழ்நேர விலைகள்',
      'crops_label': 'பயிர்கள்',
      'wheat_label': 'கோதுமை விலை',
      'nav_home': 'முகப்பு',
      'nav_voice': 'குரல்',
      'nav_disease': 'நோய்',
      'nav_mandi': 'சந்தை',
    },
    'kn': {
      'greeting': 'ನಮಸ್ಕಾರ, ರೈತ ಭಾಯಿ!',
      'what_to_do': 'ಏನು ಮಾಡಬೇಕು?',
      'what_to_do_sub': 'ನೀವು ಏನು ಮಾಡಲು ಬಯಸುತ್ತೀರಿ?',
      'voice_title': 'ಧ್ವನಿಯಿಂದ ಕೇಳಿ',
      'voice_sub': 'AI ಮಿತ್ರರಿಗೆ ಪ್ರಶ್ನೆ ಕೇಳಿ',
      'disease_title': 'ಬೆಳೆ ರೋಗ',
      'disease_sub': 'ಫೋಟೋದಿಂದ ರೋಗ ಗುರುತಿಸಿ',
      'mandi_title': 'ಮಂಡಿ ಬೆಲೆಗಳು',
      'mandi_sub': 'ರಿಯಲ್-ಟೈಮ್ ಬೆಲೆಗಳು',
      'crops_label': 'ಬೆಳೆಗಳು',
      'wheat_label': 'ಗೋಧಿ ಬೆಲೆ',
      'nav_home': 'ಮನೆ',
      'nav_voice': 'ಧ್ವನಿ',
      'nav_disease': 'ರೋಗ',
      'nav_mandi': 'ಮಂಡಿ',
    },
    'ml': {
      'greeting': 'നമസ്കാരം, കർഷക സഹോദരാ!',
      'what_to_do': 'എന്ത് ചെയ്യണം?',
      'what_to_do_sub': 'നിങ്ങൾ എന്ത് ചെയ്യാൻ ആഗ്രഹിക്കുന്നു?',
      'voice_title': 'ശബ്ദം ഉപയോഗിച്ച് ചോദിക്കുക',
      'voice_sub': 'AI സുഹൃത്തിനോട് ചോദിക്കുക',
      'disease_title': 'വിള രോഗം',
      'disease_sub': 'ഫോട്ടോ ഉപയോഗിച്ച് രോഗം കണ്ടെത്തുക',
      'mandi_title': 'മണ്ടി വിലകൾ',
      'mandi_sub': 'റിയൽ-ടൈം വിലകൾ',
      'crops_label': 'വിളകൾ',
      'wheat_label': 'ഗോതമ്പ് വില',
      'nav_home': 'ഹോം',
      'nav_voice': 'ശബ്ദം',
      'nav_disease': 'രോഗം',
      'nav_mandi': 'മണ്ടി',
    },
    'or': {
      'greeting': 'ନମସ୍କାର, କୃଷକ ଭାଇ!',
      'what_to_do': 'କ\'ଣ କରିବେ?',
      'what_to_do_sub': 'ଆପଣ କ\'ଣ କରିବାକୁ ଚାହୁଁଛନ୍ତି?',
      'voice_title': 'ଆଵାଜ଼ ଦ୍ଵାରା ପଚାରନ୍ତୁ',
      'voice_sub': 'AI ମିତ୍ରଙ୍କୁ ପ୍ରଶ୍ନ କରନ୍ତୁ',
      'disease_title': 'ଫସଲ ରୋଗ',
      'disease_sub': 'ଫୋଟୋ ଦ୍ଵାରା ରୋଗ ଚିହ୍ନଟ',
      'mandi_title': 'ମଣ୍ଡି ଭାବ',
      'mandi_sub': 'ରିଅଲ-ଟାଇମ ଭାବ',
      'crops_label': 'ଫସଲ',
      'wheat_label': 'ଗହମ ଭାବ',
      'nav_home': 'ହୋମ',
      'nav_voice': 'ଆଵାଜ',
      'nav_disease': 'ରୋଗ',
      'nav_mandi': 'ମଣ୍ଡି',
    },
    'ur': {
      'greeting': 'السلام علیکم، کسان بھائی!',
      'what_to_do': 'کیا کرنا ہے؟',
      'what_to_do_sub': 'آپ کیا کرنا چاہتے ہیں؟',
      'voice_title': 'آواز سے پوچھیں',
      'voice_sub': 'AI دوست سے سوال پوچھیں',
      'disease_title': 'فصل کی بیماری',
      'disease_sub': 'تصویر سے بیماری پہچانیں',
      'mandi_title': 'منڈی بھاؤ',
      'mandi_sub': 'ریئل-ٹائم بھاؤ',
      'crops_label': 'فصلیں',
      'wheat_label': 'گندم بھاؤ',
      'nav_home': 'ہوم',
      'nav_voice': 'آواز',
      'nav_disease': 'بیماری',
      'nav_mandi': 'منڈی',
    },
  };

  String t(String key) {
    final map = _translations[_languageCode] ?? _translations['hi']!;
    return map[key] ?? _translations['hi']![key] ?? key;
  }
}
