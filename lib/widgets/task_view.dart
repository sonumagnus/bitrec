import 'package:bitrec/hive/adapters/task.dart';
import 'package:bitrec/widgets/task_calender.dart';
import 'package:flutter/material.dart';

class TaskView extends StatelessWidget {
  const TaskView(this.task, {super.key});

  final Task task;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          bottom: const TabBar(
            tabs: [
              Tab(icon: Text("Data 1")),
              Tab(icon: Text("Data 2")),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            TaskCalender(),
            Placeholder(),
          ],
        ),
      ),
    );
  }
}
