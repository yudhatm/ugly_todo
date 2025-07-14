import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ugly_todo/database/database.dart';
import 'package:ugly_todo/views/create_todos_view.dart';
import 'package:ugly_todo/views/todo_dashboard.dart';

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

  testWidgets('should display create todo view', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: CreateTodosView(database: appDatabase),
    ));

    // App Bar
    expect(find.byType(AppBar), findsOneWidget);
    expect(find.text('Add Todo'), findsOneWidget);
    expect(find.byIcon(Icons.save), findsOneWidget);

    //Form
    expect(find.byType(Form), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.text('Title'), findsOneWidget);
    expect(find.text('Content'), findsOneWidget);

    await appDatabase.close();
  });

  testWidgets('should show error message when title is empty', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: CreateTodosView(database: appDatabase),
    ));

    await tester.tap(find.byIcon(Icons.save));
    await tester.pump();

    expect(find.text('Please enter a title'), findsOneWidget);
  });

  testWidgets('should accept valid form without content', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: CreateTodosView(database: appDatabase),
    ));

    await tester.enterText(find.byType(TextFormField).first, 'valid title');
    await tester.tap(find.byIcon(Icons.save));
    await tester.pump();

    expect(find.text('Please enter a title'), findsNothing);
  });

  testWidgets('should create todo on save', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: CreateTodosView(database: appDatabase),
    ));

    await tester.enterText(find.byType(TextFormField).first, 'valid title');
    await tester.enterText(find.byType(TextFormField).last, 'valid content');
    await tester.tap(find.byIcon(Icons.save));
    await tester.pump();

    final todo = await appDatabase.findTodo(titleQuery: 'valid title');

    expect(todo!.title, 'valid title');
    expect(todo.content, 'valid content');
  });

  testWidgets('should return to previous view after save', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: TodoDashboard(database: appDatabase),
      routes: {
        '/create-todos': (context) => CreateTodosView(database: appDatabase)
      },
    ));

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.byType(CreateTodosView), findsOneWidget);
    expect(find.byType(TodoDashboard), findsNothing);

    await tester.enterText(find.byType(TextFormField).first, 'valid title');
    await tester.tap(find.byIcon(Icons.save));
    await tester.pumpAndSettle();

    expect(find.byType(TodoDashboard), findsOneWidget);
    expect(find.byType(CreateTodosView), findsNothing);
    expect(find.text('valid title'), findsOneWidget);

    await appDatabase.close();
  });
}
