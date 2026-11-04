
import 'package:flutter/material.dart';
import 'app_locale_controller.dart';

class LanguageSwitcher extends StatelessWidget {
  final AppLocaleController controller;

  const LanguageSwitcher({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Change language',
      icon: const Icon(
        Icons.language,
        color: Color(0xFFF8ED00),
      ),
      onSelected: controller.changeLocale,
      color: const Color(0xFF242424),
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: 'en',
          child: Text(
            'English',
            style: TextStyle(color: Colors.white),
          ),
        ),
        PopupMenuItem(
          value: 'ar',
          child: Text(
            'العربية',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}
