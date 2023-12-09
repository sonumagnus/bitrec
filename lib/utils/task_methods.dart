import 'package:bitrec/hive/adapters/session.dart';
import 'package:bitrec/hive/adapters/task.dart';
import 'package:bitrec/screens/bottom_navbar.dart';
import 'package:bitrec/screens/task_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:velocity_x/velocity_x.dart';

class TaskMethods {
  static final _hiveBox = Hive.box('tasks');
  static const _uuid = Uuid();

  static void createOrEditTask(
    BuildContext ctx, {
    bool edit = false,
    required WidgetRef ref,
    Task? task,
  }) {
    showDialog(
      context: ctx,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.black.withGreen(5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.0),
          ),
          child: HookBuilder(
            builder: (context) {
              final formKey = useMemoized(() => GlobalKey<FormState>(), const []);
              final taskNameFieldController = useTextEditingController(text: edit ? task?.name : null);

              void submitHandler() {
                final newTaskId = _uuid.v4();
                final newTask = Task(
                  name: taskNameFieldController.text,
                  taskId: newTaskId,
                );
                _hiveBox.put(newTaskId, newTask);
                Navigator.of(context).pop();
              }

              return Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: taskNameFieldController,
                      decoration: const InputDecoration(labelText: 'Task Name'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Task name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        ElevatedButton(
                          style: const ButtonStyle(
                            textStyle: MaterialStatePropertyAll(
                              TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                            ),
                            side: MaterialStatePropertyAll(
                              BorderSide(width: 1, color: Vx.gray500),
                            ),
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancal'),
                        ).expand(),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          style: const ButtonStyle(
                            backgroundColor: MaterialStatePropertyAll(Vx.violet500),
                            textStyle: MaterialStatePropertyAll(
                              TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                            ),
                            side: MaterialStatePropertyAll(
                              BorderSide(width: 1, color: Vx.violet500),
                            ),
                          ),
                          onPressed: () {
                            if (formKey.currentState?.validate() ?? false) {
                              submitHandler();
                              if (ref.read(selectedIndexProvider) == 2) {
                                ref.read(taskViewRefresherProvider)!();
                              }
                            } else {
                              debugPrint('validation failed');
                              return;
                            }
                          },
                          child: const Text('Add'),
                        ).expand(),
                      ],
                    ),
                  ],
                ),
              ).p20();
            },
          ),
        );
      },
    );
  }

  static List getRealTaskOrder() {
    final allTaskKeys = _hiveBox.keys.toList();
    final List? pinnedTasks = Hive.box('rex').get('pinnedTasks');
    if (pinnedTasks == null) return allTaskKeys;

    for (final id in pinnedTasks.reversed) {
      if (allTaskKeys.contains(id)) {
        final keyIndex = allTaskKeys.indexWhere((e) => e == id);
        final String removedId = allTaskKeys.removeAt(keyIndex);
        allTaskKeys.insertT(0, removedId);
      }
    }
    return allTaskKeys;
  }

  static startNewTaskSession({required Task task}) {
    final session = Session(
      name: task.name,
      active: true,
      startDateTime: DateTime.now(),
      sessionId: _uuid.v4(),
    );
    final newSessionList = task.sessions == null ? [session] : [session, ...(task.sessions)!];
    final updatedTask = Task(name: task.name, taskId: task.taskId, sessions: newSessionList);
    _hiveBox.put(task.taskId, updatedTask);
  }

  static endTaskActiveSession({required Task task}) {
    if (task.sessions == null) return;
    final Session? activeSession = task.sessions?.firstWhere((e) => (e.active ?? false));

    final closedSession = Session(
      name: activeSession?.name,
      active: false,
      startDateTime: activeSession?.startDateTime,
      endDateTime: DateTime.now(),
      sessionId: activeSession?.sessionId,
    );

    final List<Session>? newSessionList = task.sessions?.replaceWhere((c) => (c.active ?? false), closedSession).toList();
    final Task updatedTask = Task(name: task.name, taskId: task.taskId, sessions: newSessionList);
    _hiveBox.put(task.taskId, updatedTask);
  }
}
