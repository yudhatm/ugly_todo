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

  testWidgets('should display stream and list view in dashboard',
      (tester) async {
    await appDatabase.createTodo('test title');
    await tester.pumpWidget(MaterialApp(
      home: TodoDashboard(database: appDatabase),
    ));

    await tester.pumpAndSettle();

    expect(find.byType(StreamBuilder<List<TodoWithTags>>), findsOneWidget);
    expect(find.byType(ListView), findsOneWidget);

    await appDatabase.close();
  });

  testWidgets('should show app bar and add button in dashboard',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: TodoDashboard(database: appDatabase),
    ));

    await tester.pumpAndSettle();

    expect(find.byType(AppBar), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);

    await appDatabase.close();
  });

  testWidgets(
      'should show list tile have title, content, and checkbox in dashboard',
      (tester) async {
    await appDatabase.createTodo('test title', content: 'test content');
    await tester.pumpWidget(MaterialApp(
      home: TodoDashboard(database: appDatabase),
    ));

    await tester.pumpAndSettle();

    expect(find.text('test title'), findsOneWidget);
    expect(find.text('test content'), findsOneWidget);
    expect(find.byType(Checkbox), findsOneWidget);

    await appDatabase.close();
  });

  testWidgets('should check if checkbox works', (tester) async {
    await appDatabase.createTodo('test title', content: 'test content');
    await tester.pumpWidget(MaterialApp(
      home: TodoDashboard(database: appDatabase),
    ));

    await tester.pumpAndSettle();

    final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
    expect(checkbox.value, false); // Initially unchecked

    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();

    final updatedCheckbox = tester.widget<Checkbox>(find.byType(Checkbox));
    expect(updatedCheckbox.value, true); // Now checked

    await appDatabase.close();
  });

  testWidgets('should test if slide-to-delete works', (tester) async {
    final todoId =
        await appDatabase.createTodo('test title', content: 'test content');
    await tester.pumpWidget(MaterialApp(
      home: TodoDashboard(database: appDatabase),
    ));

    await tester.pumpAndSettle();

    expect(find.byType(ListTile), findsOneWidget);

    final dismissibleFinder = find.byType(Dismissible);
    expect(dismissibleFinder, findsOneWidget);

    await tester.drag(dismissibleFinder, Offset(-500, 0)); // Swipe left
    await tester.pumpAndSettle();

    final todo = await appDatabase.findTodo(id: todoId);

    expect(find.text('Delete Todo'), findsOneWidget); // Dialog title
    expect(find.text('Are you sure you want to delete "${todo?.title ?? ''}"?'),
        findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.byType(ListTile), findsNothing); // Item removed
    expect(find.text('${todo?.title ?? ''} deleted'),
        findsOneWidget); // SnackBar// Wait for deletion to complete

    await appDatabase.close();
  });

  testWidgets('should navigate to CreateTodoView when add button is pressed',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: TodoDashboard(database: appDatabase),
      routes: {
        '/create-todos': (context) => CreateTodosView(database: appDatabase),
      },
    ));

    await tester.pumpAndSettle();

    expect(find.byType(CreateTodosView), findsNothing);

    final addButton = find.byIcon(Icons.add);
    expect(addButton, findsOneWidget);
    await tester.tap(addButton);
    await tester.pumpAndSettle();

    expect(find.byType(CreateTodosView), findsOneWidget);
    expect(find.byType(TodoDashboard), findsNothing);

    await appDatabase.close();
  });
}
