import 'package:drift/drift.dart';
import 'package:ugly_todo/database/database.dart';

part 'tags_dao.g.dart';

@DriftAccessor(tables: [Tags, TodoTags])
class TagsDao extends DatabaseAccessor<AppDatabase> with _$TagsDaoMixin {
  TagsDao(AppDatabase db) : super(db);

  Future<int> createTag(String name) {
    return into(tags).insert(TagsCompanion(name: Value(name)));
  }

  Future<Tag?> getTag(int id) {
    return (select(tags)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<List<Tag>> searchTags(String nameQuery) {
    return (select(tags)..where((t) => t.name.contains(nameQuery))).get();
  }

  Stream<List<Tag>> watchAllTags() {
    return select(tags).watch();
  }

  Future<List<Tag>> getAllTags() {
    return select(tags).get();
  }

  Future<bool> updateTag(Tag tag) {
    return update(tags).replace(tag);
  }

  Future<int> deleteTag(Tag tag) {
    return delete(tags).delete(tag);
  }

  Future<void> createTodoTagAssociation(int todoId, int tagId) async {
    await into(todoTags).insert(TodoTagsCompanion(
      todoId: Value(todoId),
      tagId: Value(tagId),
    ));
  }

  Future<void> deleteTodoTagAssociation(int todoId, int tagId) async {
    await (delete(todoTags)
          ..where((t) => t.todoId.equals(todoId))
          ..where((t) => t.tagId.equals(tagId)))
        .go();
  }
}
