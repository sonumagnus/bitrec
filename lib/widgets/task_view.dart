import 'package:bitrec/hive/adapters/task.dart';
import 'package:bitrec/screens/test.dart';
import 'package:flutter/material.dart';

class TaskView extends StatelessWidget {
  const TaskView(this.task, {super.key});

  final Task task;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          bottom: const TabBar(
            tabs: [
              Tab(icon: Text("Data 1")),
              Tab(icon: Text("Data 2")),
              Tab(icon: Text("Data 3")),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            Test(),
            Placeholder(),
            Placeholder(),
          ],
        ),
      ),
    );
  }
}
