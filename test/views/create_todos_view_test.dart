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

  testWidgets('should become "edit todo" when todo item is passed',
      (tester) async {
    // await tester.pumpWidget(MaterialApp(
    //   home: CreateTodosView(
    //       database: appDatabase,
    //       todo: TodoItem(
    //         id: 1,
    //         title: 'title',
    //         content: 'content',
    //       )),
    // ));

    // expect(find.text('Edit Todo'), findsOneWidget);
    // expect(find.text('title'), findsOneWidget);
    // expect(find.text('content'), findsOneWidget);
  });

  testWidgets('should update todo after edit is done', (tester) async {
    await appDatabase.createTodo('title', content: 'content');
    final newTodo = await appDatabase.findTodo(titleQuery: 'title');
    final todoWithTagsList = await appDatabase.getAllTodoWithTags();

    await tester.pumpWidget(MaterialApp(
      home:
          CreateTodosView(database: appDatabase, todoTags: todoWithTagsList[0]),
    ));

    expect(find.text('Edit Todo'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, 'new title');
    await tester.enterText(find.byType(TextFormField).last, 'new content');

    await tester.tap(find.byIcon(Icons.save));
    await tester.pumpAndSettle();

    final todos = await appDatabase.getAllTodos();

    expect(todos.length, 1);
    expect(todos.first.title, 'new title');
    expect(todos.first.content, 'new content');

    await appDatabase.close();
  });

  testWidgets('should be able to create todotag association after hitting save',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: CreateTodosView(database: appDatabase),
    ));

    await tester.enterText(find.byType(TextFormField).first, 'valid title');
    await tester.enterText(find.byType(TextFormField).last, 'valid content');
    await tester.tap(find.byIcon(Icons.add));

    await tester.pumpAndSettle();

    // In Add Tag View
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.add));

    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'test tag');
    await tester.tap(find.text('Save'));

    await tester.pumpAndSettle();

    expect(find.text('test tag'), findsOneWidget);

    await tester.tap(find.text('test tag'));
    await tester.pumpAndSettle();

    // In Create Todo View
    expect(find.text('Add Todo'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.save));
    await tester.pumpAndSettle();

    //Find TodoTag
    final todoTag = await (appDatabase.select(appDatabase.todoTags)
          ..where((f) => f.todoId.equals(1)))
        .get();

    expect(todoTag.length, 1);
    expect(todoTag.first.tagId, 1);
    expect(todoTag.first.todoId, 1);

    await appDatabase.close();
  });

  testWidgets(
      'should be able to edit todo and add different tag after hitting save',
      (tester) async {
    final todoId = await appDatabase.createTodo('test title');
    final tagId = await appDatabase.tagsDao.createTag('test tag');
    await appDatabase.tagsDao.createTodoTagAssociation(
      todoId,
      tagId,
    );

    final todoWithTagsList = await appDatabase.getAllTodoWithTags();
    final todoTag = todoWithTagsList.first;

    await tester.pumpWidget(MaterialApp(
      home: CreateTodosView(database: appDatabase, todoTags: todoTag),
    ));

    expect(find.text('test title'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.add));

    // In Add Tag View
    await tester.pumpAndSettle();
    expect(find.text('test tag'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'test tag 2');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('test tag 2'), findsOneWidget);

    await tester.tap(find.text('test tag 2'));
    await tester.pumpAndSettle();

    // In Create Todo View
    expect(find.text('Edit Todo'), findsOneWidget);
    expect(find.text('test tag 2'), findsOneWidget);
    expect(find.text('test tag'), findsNothing);

    await tester.enterText(find.byType(TextFormField).first, 'updated title');
    await tester.tap(find.byIcon(Icons.save));
    await tester.pumpAndSettle();

    //Find TodoTag
    final todoTagList = await appDatabase.getAllTodoWithTags();
    final updatedTodoTag = todoTagList.first;

    expect(updatedTodoTag.todo.title, 'updated title');
    expect(updatedTodoTag.tags!.first.id, 2);
    expect(updatedTodoTag.tags!.first.name, 'test tag 2');

    await appDatabase.close();
  });
}
