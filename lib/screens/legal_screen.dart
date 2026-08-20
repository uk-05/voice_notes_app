import 'package:flutter/material.dart';

/// Simple scrollable screen for showing legal text (Privacy Policy,
/// Terms & Conditions) inside the app. Pass in the title/content from
/// `lib/legal/legal_content.dart`.
class LegalScreen extends StatelessWidget {
  final String title;
  final String content;

  const LegalScreen({super.key, required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: SelectableText(
            content,
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
        ),
      ),
    );
  }
}
