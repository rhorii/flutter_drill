import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_drill/main.dart';

void main() {
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
      expect(textField.keyboardType, isNull);
    });

    testWidgets('button does nothing when text field is empty', (WidgetTester tester) async {
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
  });
}
