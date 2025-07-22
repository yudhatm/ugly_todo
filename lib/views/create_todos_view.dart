import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:ugly_todo/database/database.dart';
import 'package:ugly_todo/views/tag_list_view.dart';

class CreateTodosView extends StatefulWidget {
  final AppDatabase database;
  final TodoItem? todo;

  CreateTodosView({
    super.key,
    required this.database,
    this.todo,
  });

  @override
  State<CreateTodosView> createState() => _CreateTodosViewState();
}

class _CreateTodosViewState extends State<CreateTodosView> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  late List<Tag> activeTags = [];

  @override
  void initState() {
    super.initState();

    if (widget.todo != null) {
      _titleController.text = widget.todo!.title;
      _contentController.text = widget.todo!.content;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.todo == null ? 'Add Todo' : 'Edit Todo'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _saveTodo,
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

  void _saveTodo() {
    if (_formKey.currentState!.validate()) {
      if (widget.todo != null) {
        widget.database.updateTodo(widget.todo!.id,
            title: _titleController.text, content: _contentController.text);
      } else {
        widget.database.createTodo(_titleController.text,
            content: _contentController.text);
      }

      Navigator.pop(context);
    }
  }
}
