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
      body: StreamBuilder<List<TodoWithTags>>(
        stream: database.watchAllTodos(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            print('Loading...');
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            print('Error: ${snapshot.error}');
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final items = snapshot.data!;
          print('Items: $items');

          if (items.isEmpty) {
            return Center(
              child: Text('No todos yet. Add your first todo!'),
            );
          }

          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];

              return Dismissible(
                key: Key(item.todo.id.toString()),
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
                          'Are you sure you want to delete "${item.todo.title}"?'),
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
                  database.deleteTodo(item.todo.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${item.todo.title} deleted')),
                  );
                },
                child: ListTile(
                  title: Text(item.todo.title),
                  subtitle: Text(item.todo.content),
                  trailing: Checkbox(
                      value: item.todo.completed,
                      onChanged: (value) {
                        database.toggleTodo(item.todo.id);
                      }),
                  onTap: () => Navigator.pushNamed(context, '/create-todos',
                      arguments: {'todo': item}),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
