import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/voice_provider.dart';
import '../utils/app_colors.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/language_toggle.dart';

class VoiceChatScreen extends StatefulWidget {
  const VoiceChatScreen({Key? key}) : super(key: key);

  @override
  State<VoiceChatScreen> createState() => _VoiceChatScreenState();
}

class _VoiceChatScreenState extends State<VoiceChatScreen> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<VoiceProvider>(
          builder: (context, provider, _) {
            return Text(provider.language == 'hi' ? 'कृषि मित्र AI' : 'Krishi Mitra AI');
          },
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Consumer<VoiceProvider>(
                builder: (context, provider, _) {
                  return LanguageToggle(
                    currentLanguage: provider.language,
                    onToggle: () => provider.toggleLanguage(),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      body: Consumer<VoiceProvider>(
        builder: (context, provider, _) {
          return Column(
            children: [
              // Messages ListView
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(12),
                  itemCount: provider.messages.length +
                      (provider.isThinking ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == provider.messages.length) {
                      // Thinking indicator
                      return Padding(
                        padding: const EdgeInsets.all(12),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Row(
                            children: [
                              const SizedBox(width: 60),
                              const Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                child: _ThinkingIndicator(),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    WidgetsBinding.instance
                        .addPostFrameCallback((_) => _scrollToBottom());
                    return ChatBubble(
                      message: provider.messages[index],
                    );
                  },
                ),
              ),
              // Mic Button Area
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(
                      color: Colors.grey.shade300,
                      width: 1,
                    ),
                  ),
                ),
                padding: EdgeInsets.fromLTRB(0, 16, 0, 16 + MediaQuery.of(context).padding.bottom),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Live partial transcript or status hint
                    if (provider.isListening &&
                        provider.partialText != null &&
                        provider.partialText!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          provider.partialText!,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                            color: AppColors.primary.withOpacity(0.9),
                          ),
                        ),
                      )
                    else
                      Text(
                        provider.isListening
                            ? (provider.language == 'hi' ? 'सुन रहा हूँ...' : 'Listening...')
                            : (provider.speechAvailable
                                ? (provider.language == 'hi' ? 'माइक दबाएं और बोलें' : 'Tap mic and speak')
                                : (provider.language == 'hi' ? 'माइक उपलब्ध नहीं — अनुमति दें' : 'Mic unavailable — grant permission')),
                        style: TextStyle(
                          fontSize: 13,
                          color: provider.speechAvailable
                              ? AppColors.textSecondary.withOpacity(0.7)
                              : AppColors.warning,
                        ),
                      ),
                    if (!provider.speechAvailable)
                      TextButton(
                        onPressed: () => provider.retryMicPermission(),
                        child: Text(provider.language == 'hi' ? 'अनुमति दें' : 'Grant Permission'),
                      ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: provider.isThinking
                          ? null
                          : () {
                              if (provider.isListening) {
                                provider.stopListening();
                              } else {
                                provider.startListening();
                              }
                            },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: provider.isListening ? 90 : 80,
                        height: provider.isListening ? 90 : 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: provider.isThinking
                              ? Colors.grey
                              : (provider.isListening
                                  ? AppColors.warning
                                  : AppColors.primary),
                          boxShadow: [
                            if (provider.isListening)
                              BoxShadow(
                                color: AppColors.warning.withOpacity(0.4),
                                blurRadius: 12,
                                spreadRadius: 4,
                              ),
                          ],
                        ),
                        child: Icon(
                          provider.isListening ? Icons.stop : Icons.mic,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ThinkingIndicator extends StatefulWidget {
  const _ThinkingIndicator();

  @override
  State<_ThinkingIndicator> createState() => __ThinkingIndicatorState();
}

class __ThinkingIndicatorState extends State<_ThinkingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final offset =
                sin((_controller.value * 2 * pi) + (index * pi / 3)) * 6;
            return Transform.translate(
              offset: Offset(0, offset),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
