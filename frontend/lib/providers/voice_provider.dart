import 'package:flutter/material.dart';

import '../models/chat_message.dart';
import '../services/ai_service.dart';

class VoiceProvider extends ChangeNotifier {
  final AIService _aiService = AIService();

  String _language = 'hi'; // 'hi' or 'en'
  bool _isListening = false; // mic animation state
  bool _isThinking = false; // AI processing animation
  List<ChatMessage> _messages = [];

  // Getters
  String get language => _language;
  bool get isListening => _isListening;
  bool get isThinking => _isThinking;
  List<ChatMessage> get messages => List.unmodifiable(_messages);

  VoiceProvider() {
    _initializeWelcomeMessage();
  }

  void _initializeWelcomeMessage() {
    _messages.add(ChatMessage(
      id: 'welcome',
      text: _language == 'hi'
          ? 'नमस्ते! मैं कृषि मित्र हूं। अपना सवाल माइक से बताइए।'
          : 'Hello! I am Krishi Mitra. Tell me your farming question.',
      isUser: false,
    ));
  }

  void toggleLanguage() {
    _language = _language == 'hi' ? 'en' : 'hi';
    _messages.clear();
    _initializeWelcomeMessage();
    notifyListeners();
  }

  void setLanguage(String code) {
    if (_language == code) return;
    _language = code;
    _messages.clear();
    _initializeWelcomeMessage();
    notifyListeners();
  }

  // Called when the mic button is tapped
  void startListening() {
    _isListening = true;
    notifyListeners();

    // Simulate listening for 2 seconds, then use a canned query
    Future.delayed(const Duration(seconds: 2), () => _stopListeningDemo());
  }

  void _stopListeningDemo() {
    _isListening = false;
    final demoQueries = {
      'hi': 'गेहूं की बीमारी का इलाज क्या है?',
      'en': 'What is the treatment for wheat disease?',
    };
    sendMessage(demoQueries[_language]!, isVoice: true);
  }

  Future<void> sendMessage(String text, {bool isVoice = false}) async {
    final messageId = DateTime.now().millisecondsSinceEpoch.toString();
    _messages.add(
      ChatMessage(id: messageId, text: text, isUser: true, isVoice: isVoice),
    );
    _isThinking = true;
    notifyListeners();

    final response = await _aiService.getResponse(text, _language);

    _messages.add(ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: response,
      isUser: false,
    ));
    _isThinking = false;
    notifyListeners();
  }

  void clearChat() {
    _messages.clear();
    _initializeWelcomeMessage();
    notifyListeners();
  }
}
