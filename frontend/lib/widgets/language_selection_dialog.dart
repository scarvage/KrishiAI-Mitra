import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/language_provider.dart';
import '../utils/app_colors.dart';

class LanguageSelectionDialog extends StatefulWidget {
  /// If [showAsDialog] is false, it renders inline (used from settings).
  final bool showAsDialog;

  const LanguageSelectionDialog({super.key, this.showAsDialog = true});

  /// Shows the full-screen language picker as a dialog.
  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const LanguageSelectionDialog(showAsDialog: true),
    );
  }

  @override
  State<LanguageSelectionDialog> createState() =>
      _LanguageSelectionDialogState();
}

class _LanguageSelectionDialogState extends State<LanguageSelectionDialog> {
  String? _selected;

  @override
  void initState() {
    super.initState();
    final provider = context.read<LanguageProvider>();
    _selected = provider.languageCode;
  }

  Future<void> _confirm(LanguageProvider provider) async {
    if (_selected == null) return;
    await provider.setLanguage(_selected!);
    if (widget.showAsDialog && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LanguageProvider>();
    final content = _buildContent(provider);

    if (!widget.showAsDialog) return content;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: content,
    );
  }

  Widget _buildContent(LanguageProvider provider) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'अपनी भाषा चुनें',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Choose Your Language',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          // Language grid
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: LanguageProvider.supportedLanguages.map((lang) {
                  final isSelected = _selected == lang.code;
                  return GestureDetector(
                    onTap: () => setState(() => _selected = lang.code),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: (MediaQuery.of(context).size.width - 40 - 32 - 10) / 2,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withOpacity(0.12)
                            : Colors.grey.shade50,
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : Colors.grey.shade300,
                          width: isSelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Text(lang.flag, style: const TextStyle(fontSize: 22)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  lang.nativeName,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  lang.name,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary
                                        .withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Icon(Icons.check_circle,
                                color: AppColors.primary, size: 18),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          // Confirm button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _selected != null ? () => _confirm(provider) : null,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _selected != null
                      ? 'जारी रखें  •  Continue'
                      : 'Select a language',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
