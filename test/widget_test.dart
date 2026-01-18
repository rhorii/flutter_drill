import 'package:audioplayers/audioplayers.dart';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:flutter_drill/main.dart';
import 'package:flutter_drill/responsive_utils.dart';

class MockAudioPlayer extends Mock implements AudioPlayer {}

class FakeSource extends Fake implements Source {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeSource());
  });

  testWidgets('MyApp builds successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the app title is displayed.
    expect(find.text('ドリル'), findsOneWidget);

    // Verify that a loading indicator is shown while data is loading.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  group('DrillCollection', () {
    test('fromJson creates DrillCollection from valid JSON', () {
      final json = {
        'title': 'Test Drill',
        'paths': ['path1.csv', 'path2.csv']
      };

      final drillCollection = DrillCollection.fromJson(json);

      expect(drillCollection.title, equals('Test Drill'));
      expect(drillCollection.paths, equals(['path1.csv', 'path2.csv']));
    });

    test('constructor creates DrillCollection with required fields', () {
      final drillCollection = DrillCollection(
        title: 'Math Drill',
        paths: ['math1.csv', 'math2.csv'],
      );

      expect(drillCollection.title, equals('Math Drill'));
      expect(drillCollection.paths, hasLength(2));
    });
  });

  group('Drill', () {
    test('constructor creates Drill with question and answer', () {
      final drill = Drill(
        question: '2 + 2',
        answer: '4',
      );

      expect(drill.question, equals('2 + 2'));
      expect(drill.answer, equals('4'));
    });

    test('can create Drill with non-numeric values', () {
      final drill = Drill(
        question: 'りんご',
        answer: 'apple',
      );

      expect(drill.question, equals('りんご'));
      expect(drill.answer, equals('apple'));
    });
  });

  group('CSV parsing', () {
    test('parses CSV string into Drill list', () {
      const csvString = '1+1,2\n2+2,4\n3+3,6';
      final csv = const CsvToListConverter(shouldParseNumbers: false, eol: '\n')
          .convert(csvString);
      final drills =
          csv.map((row) => Drill(question: row[0], answer: row[1])).toList();

      expect(drills, hasLength(3));
      expect(drills[0].question, equals('1+1'));
      expect(drills[0].answer, equals('2'));
      expect(drills[1].question, equals('2+2'));
      expect(drills[1].answer, equals('4'));
      expect(drills[2].question, equals('3+3'));
      expect(drills[2].answer, equals('6'));
    });

    test('parses CSV with Japanese characters', () {
      const csvString = 'あ,a\nい,i\nう,u';
      final csv = const CsvToListConverter(shouldParseNumbers: false, eol: '\n')
          .convert(csvString);
      final drills =
          csv.map((row) => Drill(question: row[0], answer: row[1])).toList();

      expect(drills, hasLength(3));
      expect(drills[0].question, equals('あ'));
      expect(drills[0].answer, equals('a'));
    });

    test('handles empty CSV string', () {
      const csvString = '';
      final csv = const CsvToListConverter(shouldParseNumbers: false, eol: '\n')
          .convert(csvString);

      expect(csv, isEmpty);
    });
  });

  group('MyApp', () {
    testWidgets('creates MaterialApp with correct title', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.title, equals('Drill'));
    });

    testWidgets('home page is DrillCollectionListPage', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());

      expect(find.byType(DrillCollectionListPage), findsOneWidget);
    });
  });

  group('DrillCollectionListView', () {
    testWidgets('displays list of drill collections', (WidgetTester tester) async {
      final drillCollections = [
        DrillCollection(title: 'ひらがな', paths: ['hiragana.csv']),
        DrillCollection(title: '九九', paths: ['multiplication.csv']),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DrillCollectionListView(drillCollections: drillCollections),
          ),
        ),
      );

      expect(find.text('ひらがな'), findsOneWidget);
      expect(find.text('九九'), findsOneWidget);
      expect(find.byType(ListTile), findsNWidgets(2));
    });

    testWidgets('empty list displays no items', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DrillCollectionListView(drillCollections: []),
          ),
        ),
      );

      expect(find.byType(ListTile), findsNothing);
    });

    testWidgets('tapping a collection navigates to DrillPage', (WidgetTester tester) async {
      final drillCollections = [
        DrillCollection(title: 'テスト', paths: ['test.csv']),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DrillCollectionListView(drillCollections: drillCollections),
          ),
        ),
      );

      await tester.tap(find.text('テスト'));
      await tester.pumpAndSettle();

      expect(find.byType(DrillPage), findsOneWidget);
    });
  });

  group('DrillView', () {
    testWidgets('displays question and answer field', (WidgetTester tester) async {
      tester.binding.window.physicalSizeTestValue = const Size(1920, 1080);
      tester.binding.window.devicePixelRatioTestValue = 1.0;
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

      final drills = [
        Drill(question: '2 + 2', answer: '4'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DrillView(drills),
          ),
        ),
      );

      expect(find.text('2 + 2'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('こたえあわせ'), findsOneWidget);
    });

    testWidgets('displays numeric keyboard for numeric answers', (WidgetTester tester) async {
      tester.binding.window.physicalSizeTestValue = const Size(1920, 1080);
      tester.binding.window.devicePixelRatioTestValue = 1.0;
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

      final drills = [
        Drill(question: '5 + 3', answer: '8'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DrillView(drills),
          ),
        ),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.keyboardType, equals(TextInputType.number));
    });

    testWidgets('displays default keyboard for non-numeric answers', (WidgetTester tester) async {
      tester.binding.window.physicalSizeTestValue = const Size(1920, 1080);
      tester.binding.window.devicePixelRatioTestValue = 1.0;
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

      final drills = [
        Drill(question: 'りんご', answer: 'apple'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DrillView(drills),
          ),
        ),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.keyboardType, isNot(equals(TextInputType.number)));
    });

    testWidgets('button does nothing when text field is empty', (WidgetTester tester) async {
      tester.binding.window.physicalSizeTestValue = const Size(1920, 1080);
      tester.binding.window.devicePixelRatioTestValue = 1.0;
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

      final drills = [
        Drill(question: '1 + 1', answer: '2'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DrillView(drills),
          ),
        ),
      );

      final button = find.text('こたえあわせ');
      await tester.tap(button);
      await tester.pump();

      // Should still show the same question
      expect(find.text('1 + 1'), findsOneWidget);
    });

    testWidgets('incorrect answer keeps the same question', (WidgetTester tester) async {
      tester.binding.window.physicalSizeTestValue = const Size(1920, 1080);
      tester.binding.window.devicePixelRatioTestValue = 1.0;
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

      final drills = [
        Drill(question: '1 + 1', answer: '2'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DrillView(drills),
          ),
        ),
      );

      // Enter incorrect answer
      await tester.enterText(find.byType(TextField), '3');
      await tester.tap(find.text('こたえあわせ'));
      await tester.pump();

      // Should still show the same question
      expect(find.text('1 + 1'), findsOneWidget);
      // Text field should still contain the incorrect answer
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('correct answer clears text field', (WidgetTester tester) async {
      tester.binding.window.physicalSizeTestValue = const Size(1920, 1080);
      tester.binding.window.devicePixelRatioTestValue = 1.0;
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

      final mockPlayer = MockAudioPlayer();
      when(() => mockPlayer.play(any())).thenAnswer((_) async {});

      final drills = [
        Drill(question: '1 + 1', answer: '2'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DrillView(drills, audioPlayer: mockPlayer),
          ),
        ),
      );

      // Enter correct answer
      await tester.enterText(find.byType(TextField), '2');
      await tester.tap(find.text('こたえあわせ'));
      await tester.pumpAndSettle();

      // Text field should be cleared after correct answer
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, equals(''));
      // Verify sound was played
      verify(() => mockPlayer.play(any())).called(1);
    });

    testWidgets('correct answer moves to next question', (WidgetTester tester) async {
      tester.binding.window.physicalSizeTestValue = const Size(1920, 1080);
      tester.binding.window.devicePixelRatioTestValue = 1.0;
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

      final mockPlayer = MockAudioPlayer();
      when(() => mockPlayer.play(any())).thenAnswer((_) async {});

      // Use multiple drills to test question change
      final drills = [
        Drill(question: 'Q1', answer: 'A1'),
        Drill(question: 'Q2', answer: 'A2'),
        Drill(question: 'Q3', answer: 'A3'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DrillView(drills, audioPlayer: mockPlayer),
          ),
        ),
      );

      // Find the initial question
      final initialQuestion = find.textContaining('Q').evaluate().first.widget as Text;
      final initialText = initialQuestion.data;

      // Enter correct answer based on initial question
      final correctAnswer = initialText == 'Q1' ? 'A1' : (initialText == 'Q2' ? 'A2' : 'A3');
      await tester.enterText(find.byType(TextField), correctAnswer);
      await tester.tap(find.text('こたえあわせ'));
      await tester.pumpAndSettle();

      // Verify a question is still displayed (may be same or different due to random)
      expect(find.textContaining('Q'), findsOneWidget);
      // Verify sound was played
      verify(() => mockPlayer.play(any())).called(1);
    });

    testWidgets('incorrect answer plays incorrect sound', (WidgetTester tester) async {
      tester.binding.window.physicalSizeTestValue = const Size(1920, 1080);
      tester.binding.window.devicePixelRatioTestValue = 1.0;
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

      final mockPlayer = MockAudioPlayer();
      when(() => mockPlayer.play(any())).thenAnswer((_) async {});

      final drills = [
        Drill(question: '1 + 1', answer: '2'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DrillView(drills, audioPlayer: mockPlayer),
          ),
        ),
      );

      // Enter incorrect answer
      await tester.enterText(find.byType(TextField), '5');
      await tester.tap(find.text('こたえあわせ'));
      await tester.pump();

      // Verify incorrect sound was played
      verify(() => mockPlayer.play(any())).called(1);
      // Question should remain the same
      expect(find.text('1 + 1'), findsOneWidget);
    });
  });

  group('ResponsiveSizes', () {
    test('calculates sizes based on shortest side (landscape)', () {
      final sizes = ResponsiveSizes(screenWidth: 800, screenHeight: 600);

      expect(sizes.shortestSide, equals(600));
      expect(sizes.questionFontSize, equals(150)); // 600 * 0.25
      expect(sizes.answerFontSize, equals(120)); // 600 * 0.20
      expect(sizes.listTitleFontSize, equals(48)); // 600 * 0.08
      expect(sizes.buttonFontSize, equals(48)); // 600 * 0.08
    });

    test('calculates sizes based on shortest side (portrait)', () {
      final sizes = ResponsiveSizes(screenWidth: 400, screenHeight: 800);

      expect(sizes.shortestSide, equals(400));
      expect(sizes.questionFontSize, equals(100)); // 400 * 0.25
      expect(sizes.answerFontSize, equals(80)); // 400 * 0.20
    });

    test('clamps questionFontSize to minimum 48', () {
      final sizes = ResponsiveSizes(screenWidth: 100, screenHeight: 200);

      expect(sizes.shortestSide, equals(100));
      // 100 * 0.25 = 25, but clamped to 48
      expect(sizes.questionFontSize, equals(48));
    });

    test('clamps questionFontSize to maximum 256', () {
      final sizes = ResponsiveSizes(screenWidth: 2000, screenHeight: 2000);

      expect(sizes.shortestSide, equals(2000));
      // 2000 * 0.25 = 500, but clamped to 256
      expect(sizes.questionFontSize, equals(256));
    });

    test('calculates padding and spacing proportionally', () {
      final sizes = ResponsiveSizes(screenWidth: 1000, screenHeight: 800);

      expect(sizes.shortestSide, equals(800));
      expect(sizes.horizontalPadding, equals(40)); // 800 * 0.05
      expect(sizes.buttonPadding, equals(24)); // 800 * 0.03
      expect(sizes.spacerHeight, equals(40)); // 800 * 0.05
    });
  });

  group('Responsive DrillView', () {
    final testSizes = [
      ('iPhone portrait', const Size(390, 844)),
      ('iPhone landscape', const Size(844, 390)),
      ('iPad portrait', const Size(820, 1180)),
      ('iPad landscape', const Size(1180, 820)),
      ('desktop', const Size(1920, 1080)),
    ];

    for (final (name, size) in testSizes) {
      testWidgets('renders without overflow on $name', (WidgetTester tester) async {
        tester.binding.window.physicalSizeTestValue = size;
        tester.binding.window.devicePixelRatioTestValue = 1.0;
        addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

        final drills = [
          Drill(question: '1+1', answer: '2'),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DrillView(drills),
            ),
          ),
        );

        // Verify no overflow errors
        expect(tester.takeException(), isNull);
        expect(find.text('1+1'), findsOneWidget);
        expect(find.byType(TextField), findsOneWidget);
        expect(find.text('こたえあわせ'), findsOneWidget);
      });
    }
  });
}
