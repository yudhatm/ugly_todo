import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

part 'database.g.dart';

class TodoItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 3, max: 32)();
  TextColumn get content => text().named('body')();
  DateTimeColumn get createdAt => dateTime().nullable()();
  BoolColumn get completed => boolean().nullable()();
}

@DriftDatabase(tables: [TodoItems])
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

  Future<int> createTodo(String title, {String content = ''}) {
    return into(todoItems).insert(
      TodoItemsCompanion(
          title: Value(title),
          content: Value(content),
          createdAt: Value(DateTime.now()),
          completed: Value(false)),
    );
  }

  Future<TodoItem?> getTodo(int id) =>
      managers.todoItems.filter((f) => f.id.equals(id)).getSingleOrNull();

  Future<int> updateTodo(int id, {String? title, String? content}) {
    return managers.todoItems
        .filter((f) => f.id.equals(id))
        .update((obj) => obj(
              title: title != null ? Value(title) : const Value.absent(),
              content: content != null ? Value(content) : const Value.absent(),
            ));
  }

  Future<void> deleteTodo(int id) =>
      managers.todoItems.filter((f) => f.id.equals(id)).delete();
}
