import 'package:flutter/material.dart';
import 'package:ugly_todo/database/database.dart';

class TagListView extends StatefulWidget {
  final AppDatabase database;

  const TagListView({super.key, required this.database});

  @override
  State<TagListView> createState() => _TagListViewState();
}

class _TagListViewState extends State<TagListView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Tag List'),
          actions: [
            IconButton(
              icon: Icon(Icons.add),
              onPressed: () {
                _showAddTagDialog();
              },
            )
          ],
        ),
        body: StreamBuilder<List<Tag>>(
            stream: widget.database.tagsDao.watchAllTags(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text('Error: ${snapshot.error}'),
                );
              }

              if (snapshot.data!.isEmpty) {
                return Center(
                  child: Text('No tags found\nCreate one!',
                      textAlign: TextAlign.center),
                );
              }

              final items = snapshot.data!;

              return ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return Dismissible(
                    key: Key(item.id.toString()),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      child: Icon(
                        Icons.delete,
                        color: Colors.white,
                      ),
                    ),
                    confirmDismiss: (direction) async {
                      return await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('Delete Todo'),
                          content: Text(
                              'Are you sure you want to delete "${item.name}"?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              style: TextButton.styleFrom(
                                  foregroundColor: Colors.red),
                              child: Text('Delete'),
                            ),
                          ],
                        ),
                      );
                    },
                    onDismissed: (direction) {
                      widget.database.tagsDao.deleteTag(item);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${item.name} deleted')),
                      );
                    },
                    child: ListTile(
                      title: Text(item.name),
                      leading: Icon(
                        Icons.label_outline,
                        color: Colors.black,
                      ),
                      onTap: () {
                        Navigator.pop(context, item);
                      },
                    ),
                  );
                },
              );
            }));
  }

  void _showAddTagDialog() {
    showDialog(
        context: context,
        builder: (context) {
          final textController = TextEditingController();

          return AlertDialog(
            title: Text('Add Tag'),
            content: TextField(
              controller: textController,
              decoration: InputDecoration(labelText: 'Tag Name'),
            ),
            actions: [
              TextButton(
                child: Text('Cancel'),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              TextButton(
                child: Text('Save'),
                onPressed: () {
                  widget.database.tagsDao.createTag(textController.text);
                  Navigator.pop(context);
                },
              ),
            ],
          );
        });
  }
}
