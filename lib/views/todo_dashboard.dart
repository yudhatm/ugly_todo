import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:ugly_todo/database/database.dart';

class TodoDashboard extends StatelessWidget {
  final AppDatabase database;

  const TodoDashboard({super.key, required this.database});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('UglyTodo'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () => Navigator.pushNamed(context, '/create-todos'),
          )
        ],
      ),
      body: StreamBuilder<List<TodoItem>>(
        stream: database.watchAllTodos(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final todos = snapshot.data!;

          if (todos.isEmpty) {
            return Center(
              child: Text('No todos yet. Add your first todo!'),
            );
          }

          return ListView.builder(
            itemCount: todos.length,
            itemBuilder: (context, index) {
              final todo = todos[index];

              return ListTile(
                  title: Text(todo.title),
                  subtitle: Text(todo.content),
                  trailing: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () => database.deleteTodo(todo.id),
                  ));
            },
          );
        },
      ),
    );
  }
}
