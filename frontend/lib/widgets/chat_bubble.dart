import 'package:flutter/material.dart';

import '../models/chat_message.dart';
import '../utils/app_colors.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({Key? key, required this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.only(
          left: isUser ? 60 : 16,
          right: isUser ? 16 : 60,
          top: 8,
          bottom: 8,
        ),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: isUser
                    ? null
                    : Border.all(
                        color: Colors.grey.shade300,
                        width: 1,
                      ),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  fontSize: 15,
                  color: isUser ? Colors.white : AppColors.textPrimary,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (message.isVoice && isUser)
                  const Padding(
                    padding: EdgeInsets.only(right: 4),
                    child: Icon(
                      Icons.mic,
                      size: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                Text(
                  message.getFormattedTime(),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
