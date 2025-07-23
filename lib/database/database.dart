import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ugly_todo/database/tags_dao.dart';

part 'database.g.dart';

class TodoItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 3, max: 32)();
  TextColumn get content => text().named('body')();
  DateTimeColumn get createdAt => dateTime().nullable()();
  BoolColumn get completed => boolean().nullable()();
}

class Tags extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
}

class TodoTags extends Table {
  IntColumn get todoId => integer().references(TodoItems, #id)();
  IntColumn get tagId => integer().references(Tags, #id)();

  @override
  Set<Column> get primaryKey => {todoId, tagId};
}

class TodoWithTags {
  final TodoItem todo;
  final List<Tag>? tags;

  TodoWithTags({required this.todo, required this.tags});
}

@DriftDatabase(tables: [TodoItems, Tags, TodoTags], daos: [TagsDao])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'my_database.db',
      native: const DriftNativeOptions(
        databaseDirectory: getApplicationDocumentsDirectory,
      ),
    );
  }

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        beforeOpen: (details) async {
          // This runs every time the database opens
          await customStatement('PRAGMA foreign_keys = ON;');
        },
      );

  Stream<List<TodoWithTags>> watchAllTodos() {
    var stream = select(todoItems).join([
      leftOuterJoin(todoTags, todoItems.id.equalsExp(todoTags.todoId)),
      leftOuterJoin(tags, todoTags.tagId.equalsExp(tags.id))
    ]).map((row) {
      var tag = row.readTableOrNull(tags);
      return TodoWithTags(
          todo: TodoItem(
            id: row.readTable(todoItems).id,
            title: row.readTable(todoItems).title,
            content: row.readTable(todoItems).content,
            createdAt: row.readTable(todoItems).createdAt,
            completed: row.readTable(todoItems).completed,
          ),
          tags: tag == null ? null : [tag]);
    }).watch();

    return stream;
  }

  Future<List<TodoItem>> getAllTodos() {
    return managers.todoItems.get();
  }

  Future<List<TodoWithTags>> getAllTodoWithTags() {
    return select(todoItems).join([
      leftOuterJoin(todoTags, todoItems.id.equalsExp(todoTags.todoId)),
      leftOuterJoin(tags, todoTags.tagId.equalsExp(tags.id))
    ]).map((row) {
      var tag = row.readTableOrNull(tags);
      return TodoWithTags(
          todo: TodoItem(
            id: row.readTable(todoItems).id,
            title: row.readTable(todoItems).title,
            content: row.readTable(todoItems).content,
            createdAt: row.readTable(todoItems).createdAt,
            completed: row.readTable(todoItems).completed,
          ),
          tags: tag == null ? null : [tag]);
    }).get();
  }

  Future<int> createTodo(String title, {String content = ''}) async {
    return await managers.todoItems.create((o) {
      return o(
        title: title,
        content: content,
        createdAt: Value(DateTime.now()),
        completed: Value(false),
      );
    });
  }

  Future<TodoItem?> findTodo({int? id, String? titleQuery}) async {
    var query = managers.todoItems;

    if (id != null) {
      return await query.filter((f) => f.id.equals(id)).getSingleOrNull();
    }

    if (titleQuery != null) {
      return await query
          .filter((f) => f.title.equals(titleQuery))
          .getSingleOrNull();
    }

    return null;
  }

  Future<List<TodoItem>> searchTodos({int? id, String? titleQuery}) async {
    var query = managers.todoItems;

    if (id != null) {
      return await query.filter((f) => f.id.equals(id)).get();
    }

    if (titleQuery != null) {
      return await query.filter((f) => f.title.contains(titleQuery)).get();
    }

    return [];
  }

  Future<int> updateTodo(int id,
      {String? title, String? content, bool? completed}) {
    return managers.todoItems
        .filter((f) => f.id.equals(id))
        .update((obj) => obj(
              title: title != null ? Value(title) : const Value.absent(),
              content: content != null ? Value(content) : const Value.absent(),
              completed:
                  completed != null ? Value(completed) : const Value.absent(),
            ));
  }

  Future<void> toggleTodo(int id) async {
    var obj =
        await managers.todoItems.filter((f) => f.id.equals(id)).getSingle();
    obj = obj.copyWith(completed: Value(!obj.completed!));
    await managers.todoItems.replace(obj);
  }

  Future<void> deleteTodo(int id) =>
      managers.todoItems.filter((f) => f.id.equals(id)).delete();
}
