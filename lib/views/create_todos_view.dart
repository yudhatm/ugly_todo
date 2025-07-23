import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:ugly_todo/database/database.dart';
import 'package:ugly_todo/views/tag_list_view.dart';

class CreateTodosView extends StatefulWidget {
  final AppDatabase database;
  final TodoWithTags? todoTags;

  const CreateTodosView({
    super.key,
    required this.database,
    this.todoTags,
  });

  @override
  State<CreateTodosView> createState() => _CreateTodosViewState();
}

class _CreateTodosViewState extends State<CreateTodosView> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  late TodoItem? todo;
  late List<Tag> activeTags = [];

  @override
  void initState() {
    super.initState();

    if (widget.todoTags != null) {
      widget.database.findTodo(id: widget.todoTags!.todo.id).then((todo) {
        if (todo != null) {
          _titleController.text = todo.title;
          _contentController.text = todo.content;
        }

        setState(() {
          activeTags.addAll(
            widget.todoTags!.tags != null ? widget.todoTags!.tags! : [],
          );
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.todoTags == null ? 'Add Todo' : 'Edit Todo'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: () {
              _saveTodo().then((_) {
                if (context.mounted) {
                  Navigator.pop(context);
                }
              });
            },
          )
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16.0),
              TextFormField(
                controller: _contentController,
                decoration: InputDecoration(
                    labelText: 'Content',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true),
                maxLines: 5,
                validator: (value) {
                  return null;
                },
              ),
              SizedBox(height: 16.0),
              Row(
                children: [
                  Text(
                    'Tags',
                    style: TextStyle(fontSize: 20.0),
                  ),
                  Spacer(),
                  IconButton(
                    onPressed: () {
                      final selectedTag = Navigator.push<Tag>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TagListView(
                            database: widget.database,
                          ),
                        ),
                      );

                      selectedTag.then((value) {
                        if (value != null) {
                          activeTags.clear();
                          setState(() {
                            activeTags.add(value);
                          });
                        }
                      });
                    },
                    icon: Icon(Icons.add),
                  ),
                ],
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  alignment: WrapAlignment.start,
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children: List.generate(
                    activeTags.length,
                    (int index) => Chip(
                      label: Text(activeTags[index].name),
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveTodo() async {
    if (_formKey.currentState!.validate()) {
      if (widget.todoTags != null) {
        widget.database.updateTodo(widget.todoTags!.todo.id,
            title: _titleController.text, content: _contentController.text);

        await widget.database.todoTags
            .deleteWhere((t) => t.todoId.equals(widget.todoTags!.todo.id));

        for (final tag in activeTags) {
          widget.database.tagsDao
              .createTodoTagAssociation(widget.todoTags!.todo.id, tag.id);
        }
      } else {
        final todoId = await widget.database.createTodo(_titleController.text,
            content: _contentController.text);

        for (final tag in activeTags) {
          widget.database.tagsDao.createTodoTagAssociation(todoId, tag.id);
        }
      }
    }
  }
}
