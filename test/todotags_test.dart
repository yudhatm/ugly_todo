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
    ))
      ..customStatement('PRAGMA foreign_keys = ON;');
    tagsDao = TagsDao(appDatabase);
  });

  tearDown(() async {
    await appDatabase.close();
  });

  test('should be able to create todo-tag association', () async {
    final todoId = await appDatabase.createTodo('test title');
    final tagId = await tagsDao.createTag('test tag');

    //create association
    await tagsDao.createTodoTagAssociation(todoId, tagId);

    final association = await appDatabase.select(appDatabase.todoTags).get();
    expect(association.length, 1);
    expect(association[0].todoId, todoId);
    expect(association[0].tagId, tagId);

    await appDatabase.close();
  });

  test('should prevent duplicate association', () async {
    final todoId = await appDatabase.createTodo('test title');
    final tagId = await tagsDao.createTag('urgent');

    //create association
    await tagsDao.createTodoTagAssociation(todoId, tagId);

    expect(
      () async => await tagsDao.createTodoTagAssociation(todoId, tagId),
      throwsA(isA<SqliteException>()),
    );
  });

  test('should get todos with their tags', () async {
    final todoId = await appDatabase.createTodo('test title');
    final tag1 = await tagsDao.createTag('urgent');
    final tag2 = await tagsDao.createTag('need work');

    await appDatabase.batch((batch) {
      batch.insertAll(appDatabase.todoTags, [
        TodoTagsCompanion.insert(
          todoId: todoId,
          tagId: tag2,
        ),
        TodoTagsCompanion.insert(
          todoId: todoId,
          tagId: tag1,
        ),
      ]);
    });

    final query = appDatabase.select(appDatabase.todoItems).join([
      leftOuterJoin(
        appDatabase.todoTags,
        appDatabase.todoTags.todoId.equalsExp(appDatabase.todoItems.id),
      ),
      leftOuterJoin(
        appDatabase.tags,
        appDatabase.tags.id.equalsExp(appDatabase.todoTags.tagId),
      ),
    ]);

    final results = await query.get();

    expect(results.length, 2);
    expect(results.first.readTable(appDatabase.todoItems).title, 'test title');

    final tagNames = results
        .map((row) => row.readTableOrNull(appDatabase.tags)?.name)
        .where((name) => name != null)
        .toList();

    expect(tagNames, containsAll(['urgent', 'need work']));
  });

  test('should get tags for specific todo', () async {
    final todo1 = await appDatabase.createTodo('todo 1');
    final todo2 = await appDatabase.createTodo('todo 2');

    final urgentTag = await tagsDao.createTag('urgent');
    final needWorkTag = await tagsDao.createTag('need work');

    await appDatabase.batch((batch) {
      batch.insertAll(appDatabase.todoTags, [
        TodoTagsCompanion.insert(
          todoId: todo1,
          tagId: urgentTag,
        ),
        TodoTagsCompanion.insert(
          todoId: todo1,
          tagId: needWorkTag,
        ),
        TodoTagsCompanion.insert(
          todoId: todo2,
          tagId: urgentTag,
        ),
      ]);
    });

    final tagsTodo1 = await appDatabase.select(appDatabase.tags).join([
      innerJoin(
        appDatabase.todoTags,
        appDatabase.todoTags.tagId.equalsExp(appDatabase.tags.id),
      )
    ])
      ..where(appDatabase.todoTags.todoId.equals(todo1));

    final result =
        await tagsTodo1.map((row) => row.readTable(appDatabase.tags)).get();

    expect(result.length, 2);
    expect(result.map((tag) => tag.name), containsAll(['urgent', 'need work']));
  });

  test('should delete todo-tag association', () async {
    final todoId = await appDatabase.createTodo('test title');
    final tagId = await tagsDao.createTag('urgent');

    //create association
    await tagsDao.createTodoTagAssociation(todoId, tagId);

    final association = await appDatabase.select(appDatabase.todoTags).get();
    expect(association.length, 1);

    //delete association
    await tagsDao.deleteTodoTagAssociation(todoId, tagId);

    final association2 = await appDatabase.select(appDatabase.todoTags).get();
    expect(association2.length, 0);
  });

  test('should enforce foreign key constraints', () async {
    // Try to insert with non-existent todo ID
    expect(
      () async => await appDatabase.into(appDatabase.todoTags).insert(
            TodoTagsCompanion.insert(todoId: 999, tagId: 1),
          ),
      throwsA(isA<SqliteException>()),
    );
  });

  test('should get todo with tags list when using stream', () async {
    final todo = await appDatabase.createTodo('test title');
    final tag = await tagsDao.createTag('urgent');
    final todoTag = await tagsDao.createTodoTagAssociation(todo, tag);
  });
}
