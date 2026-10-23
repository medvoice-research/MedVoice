import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:med_voice/app/pages/home/recording/recording/recording_view.dart';
import 'package:med_voice/app/widgets/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('recorder keeps language selector and microphone reachable on a compact phone',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.binding.setSurfaceSize(const Size(390, 667));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: MaterialApp(home: RecordingView()),
    ));
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('Tiếng Việt'), findsOneWidget);
    expect(find.byIcon(Icons.mic_off), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('English'));
    await tester.pump();
    expect(tester.widget<SegmentedButton<String>>(find.byType(SegmentedButton<String>)).selected,
        {'en'});
  });
}
