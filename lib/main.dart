import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() => runApp(MyApp());

class Task {
  String title;
  bool isCompleted;
  DateTime? dueDate;
  PriorityLevel priority;

  Task({
    required this.title,
    this.isCompleted = false,
    this.dueDate,
    this.priority = PriorityLevel.low,
  });

  Task.fromJson(Map<String, dynamic> json)
      : title = json['title'],
        isCompleted = json['isCompleted'],
        dueDate =
            json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
        priority = PriorityLevel.values[json['priority'] ?? 0];

  Map<String, dynamic> toJson() => {
        'title': title,
        'isCompleted': isCompleted,
        'dueDate': dueDate?.toIso8601String(),
        'priority': priority.index,
      };
}

enum PriorityLevel { low, medium, high }

class TaskListProvider with ChangeNotifier {
  List<Task> _tasks = [];

  List<Task> get tasks => _tasks;

  void addTask(Task task) {
    _tasks.add(task);
    saveTasks();
    notifyListeners();
  }

  void updateTask(int index, Task task) {
    _tasks[index] = task;
    saveTasks();
    notifyListeners();
  }

  void deleteTask(int index) {
    _tasks.removeAt(index);
    saveTasks();
    notifyListeners();
  }

  Future<void> loadTasks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? tasksJson = prefs.getStringList('tasks');

    if (tasksJson != null) {
      _tasks = tasksJson
          .map((taskJson) =>
              Task.fromJson(Map<String, dynamic>.from(json.decode(taskJson))))
          .toList();
      notifyListeners();
    }
  }

  void saveTasks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> tasksJson =
        _tasks.map((task) => json.encode(task.toJson())).toList();
    prefs.setStringList('tasks', tasksJson);
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => TaskListProvider()..loadTasks(),
      child: MaterialApp(
        title: 'Task Manager',
        home: HomeScreen(),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Task Manager'),
      ),
      body: TaskList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddTaskScreen()),
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}

class TaskList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final taskListProvider = Provider.of<TaskListProvider>(context);

    return ListView.builder(
      itemCount: taskListProvider.tasks.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(taskListProvider.tasks[index].title),
          subtitle: Text(
              'Status: ${taskListProvider.tasks[index].isCompleted ? 'Completed' : 'Pending'}'),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => EditTaskScreen(index: index)),
            );
          },
          onLongPress: () {
            taskListProvider.deleteTask(index);
          },
        );
      },
    );
  }
}

class AddTaskScreen extends StatelessWidget {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _dueDateController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Task'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(labelText: 'Task Title'),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _dueDateController,
              decoration: InputDecoration(labelText: 'Due Date (optional)'),
              onTap: () async {
                DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2101),
                );

                if (pickedDate != null) {
                  _dueDateController.text =
                      pickedDate.toLocal().toString().split(' ')[0];
                }
              },
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                final String title = _titleController.text;
                final String dueDateStr = _dueDateController.text;

                DateTime? dueDate;
                if (dueDateStr.isNotEmpty) {
                  dueDate = DateTime.parse(dueDateStr);
                }

                if (title.isNotEmpty) {
                  Provider.of<TaskListProvider>(context, listen: false).addTask(
                    Task(title: title, dueDate: dueDate),
                  );
                  Navigator.pop(context);
                }
              },
              child: Text('Add Task'),
            ),
          ],
        ),
      ),
    );
  }
}

class EditTaskScreen extends StatelessWidget {
  final int index;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _dueDateController = TextEditingController();

  EditTaskScreen({required this.index}) {
    final Task task =
        Provider.of<TaskListProvider>(appContext, listen: false).tasks[index];
    _titleController.text = task.title;
    _dueDateController.text =
        task.dueDate?.toLocal().toString().split(' ')[0] ?? '';
  }

  late BuildContext appContext;

  @override
  Widget build(BuildContext context) {
    appContext = context;

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Task'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(labelText: 'Task Title'),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _dueDateController,
              decoration: InputDecoration(labelText: 'Due Date (optional)'),
              onTap: () async {
                DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2101),
                );

                if (pickedDate != null) {
                  _dueDateController.text =
                      pickedDate.toLocal().toString().split(' ')[0];
                }
              },
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                final String title = _titleController.text;
                final String dueDateStr = _dueDateController.text;

                DateTime? dueDate;
                if (dueDateStr.isNotEmpty) {
                  dueDate = DateTime.parse(dueDateStr);
                }

                if (title.isNotEmpty) {
                  Provider.of<TaskListProvider>(context, listen: false)
                      .updateTask(
                    index,
                    Task(title: title, dueDate: dueDate),
                  );
                  Navigator.pop(context);
                }
              },
              child: Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}
