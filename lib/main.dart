import 'package:flutter/material.dart';
import 'package:ugly_todo/database/database.dart';
import 'package:ugly_todo/views/create_todos_view.dart';
import 'package:ugly_todo/views/todo_dashboard.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final database = AppDatabase();

  runApp(MainApp(database: database));
}

class MainApp extends StatelessWidget {
  final AppDatabase database;

  const MainApp({super.key, required this.database});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UglyTodo',
      initialRoute: '/',
      routes: {
        '/': (context) => TodoDashboard(database: database),
        '/create-todos': (context) => CreateTodosView(database: database)
      },
    );
  }
}
