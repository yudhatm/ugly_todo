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

              return Dismissible(
                key: Key(todo.id.toString()),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: EdgeInsets.only(right: 20),
                  child: Icon(
                    Icons.delete,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                confirmDismiss: (direction) async {
                  return await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Delete Todo'),
                      content: Text(
                          'Are you sure you want to delete "${todo.title}"?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style:
                              TextButton.styleFrom(foregroundColor: Colors.red),
                          child: Text('Delete'),
                        ),
                      ],
                    ),
                  );
                },
                onDismissed: (direction) {
                  database.deleteTodo(todo.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${todo.title} deleted')),
                  );
                },
                child: ListTile(
                  title: Text(todo.title),
                  subtitle: Text(todo.content),
                  trailing: Checkbox(
                      value: todo.completed,
                      onChanged: (value) {
                        database.toggleTodo(todo.id);
                      }),
                  onTap: () => Navigator.pushNamed(context, '/create-todos',
                      arguments: {'todo': todo}),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
