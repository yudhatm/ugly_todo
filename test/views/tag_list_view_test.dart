import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ugly_todo/database/database.dart';
import 'package:ugly_todo/views/create_todos_view.dart';
import 'package:ugly_todo/views/tag_list_view.dart';

void main() {
  late AppDatabase appDatabase;

  setUp(() {
    appDatabase = AppDatabase(DatabaseConnection(
      NativeDatabase.memory(),
    ));
  });

  tearDown(() async {
    await appDatabase.close();
  });

  testWidgets('should display tag list', (tester) async {
    await appDatabase.tagsDao.createTag('test tag');

    await tester.pumpWidget(MaterialApp(
      home: TagListView(database: appDatabase),
    ));

    await tester.pumpAndSettle();

    expect(find.text('Tag List'), findsOneWidget);
    expect(find.byType(ListView), findsOneWidget);

    expect(find.text('test tag'), findsOneWidget);

    await appDatabase.close();
  });

  testWidgets('should be able to add tag', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: TagListView(database: appDatabase),
    ));

    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.add));

    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'test tag');
    await tester.tap(find.text('Save'));

    await tester.pumpAndSettle();

    expect(find.text('test tag'), findsOneWidget);

    await appDatabase.close();
  });

  testWidgets('should be able to transfer back tag data to add todo view',
      (tester) async {
    await appDatabase.tagsDao.createTag('test tag');

    await tester.pumpWidget(MaterialApp(
      home: CreateTodosView(database: appDatabase),
    ));

    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.add));

    await tester.pumpAndSettle();

    expect(find.text('test tag'), findsOneWidget);

    await tester.tap(find.text('test tag'));
    await tester.pumpAndSettle();

    expect(find.text('Add Todo'), findsOneWidget);
    expect(find.text('test tag'), findsOneWidget);

    await appDatabase.close();
  });
}
