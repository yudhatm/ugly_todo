import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:ugly_todo/database/database.dart';

class CreateTodosView extends StatefulWidget {
  final AppDatabase database;

  const CreateTodosView({super.key, required this.database});

  @override
  State<CreateTodosView> createState() => _CreateTodosViewState();
}

class _CreateTodosViewState extends State<CreateTodosView> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Todo'),
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
              )
            ],
          ),
        ),
      ),
    );
  }

  void _saveTodo() {
    if (_formKey.currentState!.validate()) {
      widget.database
          .createTodo(_titleController.text, content: _contentController.text);
      Navigator.pop(context);
    }
  }
}
