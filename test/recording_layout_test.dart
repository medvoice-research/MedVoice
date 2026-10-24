import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:med_voice/app/pages/home/recording/recording/recording_view.dart';
import 'package:med_voice/app/pages/home/recording/recording/recording_controller.dart';
import 'package:med_voice/domain/entities/recording/recording_detail.dart';
import 'package:med_voice/app/widgets/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets(
      'recorder keeps language selector and microphone reachable on a compact phone',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.binding.setSurfaceSize(const Size(390, 667));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: MaterialApp(home: RecordingView()),
    ));
    await tester.pump(const Duration(milliseconds: 250));

    expect(
        tester
            .widget<SegmentedButton<String>>(
                find.byType(SegmentedButton<String>))
            .selected,
        {'vi'});
    expect(find.text('Upload language'), findsOneWidget);
    expect(find.text('Tiếng Việt'), findsOneWidget);
    expect(find.byIcon(Icons.mic_off), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('English'));
    await tester.pump();
    expect(
        tester
            .widget<SegmentedButton<String>>(
                find.byType(SegmentedButton<String>))
            .selected,
        {'en'});

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 250));
  });

  testWidgets('medical term result leaves New recording above the tab bar',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.binding.setSurfaceSize(const Size(390, 667));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: MaterialApp(
        home: Stack(children: [
          RecordingView(),
          const Align(
            alignment: Alignment.bottomCenter,
            child: SizedBox(height: 82, child: ColoredBox(color: Colors.black)),
          ),
        ]),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 250));

    final controller = Provider.of<RecordingController>(
        tester.element(find.text('Upload language')),
        listen: false);
    controller.uploadResult = RecordingDetail.fromJson({
      'recording_id': 'rec_1',
      'transcript': {
        'full_text': List.filled(70, 'consultation').join(' '),
        'segments': [],
        'term_review': {
          'status': 'ok',
          'terms': [
            {'original': 'men hormone', 'replacement': 'metformin'}
          ]
        },
      },
    });
    controller.refreshUI();
    await tester.pump();
    expect(find.text('Medical terms to check'), findsOneWidget);
    await tester.scrollUntilVisible(
        find.text('New recording'), 300,
        scrollable: find.descendant(
            of: find.byType(ListView), matching: find.byType(Scrollable)));
    await tester.pumpAndSettle();

    expect(tester.getBottomLeft(find.byType(FilledButton)).dy, lessThan(585));
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 250));
  });
}
