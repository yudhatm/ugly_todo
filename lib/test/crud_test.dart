import 'dart:math';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ugly_todo/database/database.dart';

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
  group('CRUD', () {
    test('should be able to Create a new todo', () async {
      final todoId =
          await appDatabase.createTodo('test title', content: 'content');

      expect(todoId, isNonZero);
    });

    test('should be able to Read a todo', () async {
      final todoId = await appDatabase.createTodo('read title');
      final todo = await appDatabase.getTodo(todoId);

      expect(todo!.title, 'read title');
    });

    test('id after copying item should be the same', () async {
      final todoId = await appDatabase.createTodo('original title');
      final todo = await appDatabase.getTodo(todoId);
      final copyTodo = todo!.copyWith(title: 'new title');

      expect(copyTodo.id, todo.id);
      expect(copyTodo.title, 'new title');
    });

    test('should be able to Update todo', () async {
      final todoId = await appDatabase.createTodo('old title');
      final result = await appDatabase.updateTodo(
        todoId,
        title: 'new title',
      );
      final updatedTodo = await appDatabase.getTodo(result);

      expect(todoId, result);
      expect(updatedTodo!.title, 'new title');
    });

    test('should be able to Delete todo', () async {
      final todoId = await appDatabase.createTodo('existing title');
      await appDatabase.deleteTodo(todoId);

      final findTodo = await appDatabase.getTodo(todoId);

      expect(findTodo, null);
    });
  });
}
