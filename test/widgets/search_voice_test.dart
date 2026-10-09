import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onespend/core/speech/voice_input.dart';
import 'package:onespend/widgets/one_ui_floating_search_field.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('onespend/speech');
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  late bool available;
  late String? heard;
  late List<String?> prompts;

  setUp(() {
    VoiceInput.resetForTesting();
    available = true;
    heard = 'netflix';
    prompts = [];
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'available') return available;
      prompts.add((call.arguments as Map)['prompt'] as String?);
      return heard;
    });
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
    VoiceInput.resetForTesting();
  });

  Future<(TextEditingController, List<String>)> pump(WidgetTester tester, {bool voice = true}) async {
    final controller = TextEditingController();
    final results = <String>[];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: OneUIFloatingSearchField(
            controller: controller,
            hintText: 'Search subscriptions',
            onVoiceResult: voice ? results.add : null,
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    return (controller, results);
  }

  testWidgets('the mic fills the search with what was said', (tester) async {
    final (controller, results) = await pump(tester);
    expect(find.bySemanticsLabel('Search by voice'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.mic_rounded));
    await tester.pumpAndSettle();
    expect(prompts, ['Search subscriptions']);
    expect(controller.text, 'netflix');
    expect(results, ['netflix']);
    // With text in the field, ✕ takes the mic's place.
    expect(find.byIcon(Icons.mic_rounded), findsNothing);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
  });

  testWidgets('cancelling the voice screen changes nothing', (tester) async {
    heard = null;
    final (controller, results) = await pump(tester);
    await tester.tap(find.byIcon(Icons.mic_rounded));
    await tester.pumpAndSettle();
    expect(controller.text, isEmpty);
    expect(results, isEmpty);
  });

  testWidgets('no mic without a voice app, or without a handler', (tester) async {
    available = false;
    await pump(tester);
    expect(find.byIcon(Icons.mic_rounded), findsNothing);

    VoiceInput.resetForTesting();
    available = true;
    await pump(tester, voice: false);
    expect(find.byIcon(Icons.mic_rounded), findsNothing);
  });
}
