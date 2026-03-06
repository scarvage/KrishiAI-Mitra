import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/chat_message.dart';
import '../services/ai_service.dart';

// Maps language code → speech_to_text locale ID
const Map<String, String> _sttLocales = {
  'hi': 'hi_IN',
  'en': 'en_IN',
  'pa': 'pa_IN',
  'mr': 'mr_IN',
  'gu': 'gu_IN',
  'bn': 'bn_IN',
  'te': 'te_IN',
  'ta': 'ta_IN',
  'kn': 'kn_IN',
  'ml': 'ml_IN',
  'or': 'or_IN',
  'ur': 'ur_IN',
};

// Maps language code → flutter_tts language tag
const Map<String, String> _ttsLang = {
  'hi': 'hi-IN',
  'en': 'en-IN',
  'pa': 'pa-IN',
  'mr': 'mr-IN',
  'gu': 'gu-IN',
  'bn': 'bn-IN',
  'te': 'te-IN',
  'ta': 'ta-IN',
  'kn': 'kn-IN',
  'ml': 'ml-IN',
  'or': 'or-IN',
  'ur': 'ur-IN',
};

class VoiceProvider extends ChangeNotifier {
  final AIService _aiService = AIService();
  final SpeechToText _speech = SpeechToText();
  final FlutterTts _tts = FlutterTts();

  String _language = 'hi';
  bool _isListening = false;
  bool _isThinking = false;
  bool _speechAvailable = false;
  String? _partialText; // live partial transcript shown in UI
  List<ChatMessage> _messages = [];

  // Keep last 6 messages (3 turns) for context sent to backend
  final List<Map<String, String>> _history = [];

  String get language => _language;
  bool get isListening => _isListening;
  bool get isThinking => _isThinking;
  bool get speechAvailable => _speechAvailable;
  String? get partialText => _partialText;
  List<ChatMessage> get messages => List.unmodifiable(_messages);

  VoiceProvider() {
    _initializeWelcomeMessage();
    _initSpeech();
    _initTts();
  }

  Future<void> _initSpeech() async {
    // Request microphone permission before initializing STT
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      _speechAvailable = false;
      notifyListeners();
      return;
    }

    _speechAvailable = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          _isListening = false;
          _partialText = null;
          notifyListeners();
        }
      },
      onError: (error) {
        _isListening = false;
        _partialText = null;
        notifyListeners();
      },
    );
    notifyListeners();
  }

  Future<void> _initTts() async {
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    await _applyTtsLanguage(_language);
  }

  Future<void> _applyTtsLanguage(String lang) async {
    final tag = _ttsLang[lang] ?? 'hi-IN';
    await _tts.setLanguage(tag);
  }

  void _initializeWelcomeMessage() {
    _messages.add(ChatMessage(
      id: 'welcome',
      text: _language == 'hi'
          ? 'नमस्ते! मैं कृषि मित्र हूं। अपना सवाल माइक से बताइए।'
          : 'Hello! I am Krishi Mitra. Tap the mic and ask your farming question.',
      isUser: false,
    ));
  }

  void toggleLanguage() {
    _language = _language == 'hi' ? 'en' : 'hi';
    _onLanguageChanged();
  }

  void setLanguage(String code) {
    if (_language == code) return;
    _language = code;
    _onLanguageChanged();
  }

  void _onLanguageChanged() {
    _messages.clear();
    _history.clear();
    _initializeWelcomeMessage();
    _applyTtsLanguage(_language);
    notifyListeners();
  }

  /// Start microphone listening using speech_to_text.
  Future<void> startListening() async {
    if (!_speechAvailable) {
      // Microphone not available — show informative message
      _addBotMessage(_language == 'hi'
          ? 'माइक्रोफ़ोन उपलब्ध नहीं है। कृपया ऐप को माइक्रोफ़ोन की अनुमति दें और पुनः प्रयास करें।'
          : 'Microphone not available. Please grant microphone permission to the app and try again.');
      return;
    }

    if (_isListening) {
      await _speech.stop();
      return;
    }

    _isListening = true;
    _partialText = null;
    notifyListeners();

    final locale = _sttLocales[_language] ?? 'hi_IN';

    await _speech.listen(
      localeId: locale,
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      onResult: (result) {
        _partialText = result.recognizedWords;
        notifyListeners();

        if (result.finalResult && result.recognizedWords.trim().isNotEmpty) {
          _isListening = false;
          _partialText = null;
          notifyListeners();
          sendMessage(result.recognizedWords.trim(), isVoice: true);
        }
      },
    );
  }

  /// Called when user taps "Grant Permission" after initially denying mic access.
  Future<void> retryMicPermission() async {
    final status = await Permission.microphone.request();
    if (status.isPermanentlyDenied) {
      // User denied and checked "don't ask again" — open app settings
      await openAppSettings();
      return;
    }
    if (status.isGranted) {
      await _initSpeech();
    }
  }

  Future<void> stopListening() async {
    await _speech.stop();
    _isListening = false;
    _partialText = null;
    notifyListeners();
  }

  /// Send a text or transcribed message to the AI backend and play TTS reply.
  Future<void> sendMessage(String text, {bool isVoice = false}) async {
    if (text.trim().isEmpty) return;

    final messageId = DateTime.now().millisecondsSinceEpoch.toString();
    _messages.add(ChatMessage(id: messageId, text: text, isUser: true, isVoice: isVoice));
    _isThinking = true;
    notifyListeners();

    // Pass conversation history for context
    final response = await _aiService.getResponse(
      text,
      _language,
      history: List.unmodifiable(_history),
    );

    // Update rolling history (max 6 entries = 3 turns)
    _history.add({'role': 'user', 'text': text});
    _history.add({'role': 'assistant', 'text': response});
    if (_history.length > 6) {
      _history.removeRange(0, _history.length - 6);
    }

    _addBotMessage(response);
    _isThinking = false;
    notifyListeners();

    // Speak the response aloud
    await _tts.stop();
    await _tts.speak(response);
  }

  void _addBotMessage(String text) {
    _messages.add(ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      isUser: false,
    ));
    notifyListeners();
  }

  void clearChat() {
    _messages.clear();
    _history.clear();
    _tts.stop();
    _initializeWelcomeMessage();
    notifyListeners();
  }

  @override
  void dispose() {
    _speech.cancel();
    _tts.stop();
    super.dispose();
  }
}
