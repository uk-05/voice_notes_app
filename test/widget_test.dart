import 'package:flutter_test/flutter_test.dart';

import 'package:voice_notes_app/main.dart';

void main() {
  testWidgets('App loads without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const VoiceNotesApp());
    expect(find.byType(VoiceNotesApp), findsOneWidget);
  });
}
