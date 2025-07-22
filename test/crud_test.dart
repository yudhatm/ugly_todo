import 'dart:math';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ugly_todo/database/database.dart';
import 'package:ugly_todo/database/tags_dao.dart';

void main() {
  late AppDatabase appDatabase;
  late TagsDao tagsDao;

  setUp(() {
    appDatabase = AppDatabase(DatabaseConnection(
      NativeDatabase.memory(),
    ));
    tagsDao = TagsDao(appDatabase);
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
      final todo = await appDatabase.findTodo(id: todoId);

      expect(todo!.title, 'read title');
    });

    test('should be able to get all todos', () async {
      final todo1 = await appDatabase.createTodo('test title 1');
      final todo2 = await appDatabase.createTodo('test title 2');

      final result = await appDatabase.getAllTodos();

      expect(result.length, 2);
      expect(result[0].id, todo1);
      expect(result[1].id, todo2);
    });

    test('should be able to search list of todos', () async {
      final todo1 = await appDatabase.createTodo('test title 1');
      final todo2 = await appDatabase.createTodo('test title 2');
      await appDatabase.createTodo('not a title');

      final result = await appDatabase.searchTodos(titleQuery: 'test');

      expect(result.length, 2);
      expect(result[0].id, todo1);
      expect(result[1].id, todo2);
    });

    test('id after copying item should be the same', () async {
      final todoId = await appDatabase.createTodo('original title');
      final todo = await appDatabase.findTodo(id: todoId);
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
      final updatedTodo = await appDatabase.findTodo(id: result);

      expect(todoId, result);
      expect(updatedTodo!.title, 'new title');
    });

    test('should be able to update todo to completed', () async {
      final todoId = await appDatabase.createTodo('old title');
      await appDatabase.toggleTodo(todoId);
      final result = await appDatabase.findTodo(id: todoId);

      expect(todoId, result!.id);
      expect(result.completed, true);

      await appDatabase.toggleTodo(todoId);
      final result2 = await appDatabase.findTodo(id: todoId);

      expect(result2!.completed, false);
    });

    test('should be able to Delete todo', () async {
      final todoId = await appDatabase.createTodo('existing title');
      await appDatabase.deleteTodo(todoId);

      final findTodo = await appDatabase.findTodo(id: todoId);

      expect(findTodo, null);
    });
  });

  group('Stream CRUD', () {
    test('should stream todos correctly', () async {
      await appDatabase.createTodo('stream title 1');
      await appDatabase.createTodo('stream title 2');
      await appDatabase.createTodo('stream title 3');

      final stream = appDatabase.watchAllTodos();

      await expectLater(stream, emits((List<TodoWithTags> value) {
        return value.length == 3;
      }));
    });

    test('should stream newly created todo correctly', () async {
      final stream = appDatabase.watchAllTodos();
      await appDatabase.createTodo('stream title 1');

      await expectLater(stream, emits((List<TodoWithTags> value) {
        return value.length == 1;
      }));
    });

    test('should stream updated todos', () async {
      final stream = appDatabase.watchAllTodos();
      final newTodo = await appDatabase.createTodo('stream title 1',
          content: 'this is old');

      await expectLater(stream, emits((List<TodoWithTags> value) {
        return value.first.todo.id == newTodo &&
            value.first.todo.content == 'this is old';
      }));

      await appDatabase.updateTodo(newTodo, content: 'this is new');

      await expectLater(stream, emits((List<TodoWithTags> value) {
        return value.first.todo.id == newTodo &&
            value.first.todo.content == 'this is new';
      }));
    });

    test('should stream deleted todos', () async {
      final stream = appDatabase.watchAllTodos();
      final todo1 = await appDatabase.createTodo('title 1');
      final todo2 = await appDatabase.createTodo('title 2');

      expectLater(stream, emits((List<TodoWithTags> value) {
        return value.length == 2;
      }));

      await appDatabase.deleteTodo(todo1);

      expectLater(stream, emits((List<TodoWithTags> value) {
        return value.length == 1 && value.first.todo.id == todo2;
      }));
    });

    test('should be able to stream empty list', () async {
      final stream = appDatabase.watchAllTodos();

      expectLater(stream, emits((List<TodoWithTags> value) {
        return value.isEmpty;
      }));
    });
  });

  group('Tag CRUD', () {
    test('should be able to create tag', () async {
      final tagId = await tagsDao.createTag('test tag');

      expect(tagId, 1);
    });

    test('should be able to get single tag', () async {
      final tagId = await tagsDao.createTag('test tag');
      final tag = await tagsDao.getTag(tagId);

      expect(tag?.id, tagId);
      expect(tag?.name, 'test tag');
    });

    test('should be able to search and get multiple tags', () async {
      final tagId1 = await tagsDao.createTag('test tag 1');
      final tagId2 = await tagsDao.createTag('test tag 2');
      final tagId3 = await tagsDao.createTag('personal');

      final tags = await tagsDao.searchTags('tag');

      expect(tags.length, 2);
      expect(tags.first.id, tagId1);
      expect(tags.last.id, tagId2);
    });

    test('should be able to get all tags', () async {
      final tagId1 = await tagsDao.createTag('test tag 1');
      final _ = await tagsDao.createTag('test tag 2');
      final tagId3 = await tagsDao.createTag('test tag 3');

      final tags = await tagsDao.getAllTags();

      expect(tags.length, 3);
      expect(tags.first.id, tagId1);
      expect(tags.last.id, tagId3);
    });

    test('should be able to update tag', () async {
      final tagId = await tagsDao.createTag('test tag');
      final tagId2 = await tagsDao.createTag('test tag 2');

      final tag = await tagsDao.getTag(tagId);
      final updatedTag = tag!.copyWith(name: 'updated tag');

      final status = await tagsDao.updateTag(updatedTag);

      expect(status, true);

      final updated = await tagsDao.getTag(tagId);
      expect(updated?.name, 'updated tag');

      final notUpdated = await tagsDao.getTag(tagId2);
      expect(notUpdated?.name, 'test tag 2');
    });

    test('should be able to delete tag', () async {
      final tagId = await tagsDao.createTag('test tag');
      final tag = await tagsDao.getTag(tagId);

      await tagsDao.deleteTag(tag!);

      expect(await tagsDao.getTag(tagId), null);
    });
  });
}
