import 'package:bitrec/custom_hooks/ui_refresh_controller_hook.dart';
import 'package:bitrec/hive/adapters/task.dart';
import 'package:bitrec/themes/my_colors.dart';
import 'package:bitrec/utils/streak_calc.dart';

import 'package:bitrec/utils/task_methods.dart';
import 'package:bitrec/widgets/empty_screen_ui.dart';
import 'package:bitrec/widgets/task_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:velocity_x/velocity_x.dart';

final taskViewRefresherProvider = StateProvider<Function?>((ref) => null);

class TaskScreen extends ConsumerStatefulWidget {
  const TaskScreen({super.key});

  @override
  ConsumerState<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends ConsumerState<TaskScreen> {
  final _hive = Hive.box('tasks');
  final selectedTask = [];
  bool selectionEnabled = false;

  void refreshFn() {
    setState(() {});
  }

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(taskViewRefresherProvider.notifier).update((state) => refreshFn);
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final MyColors myColor = Theme.of(context).extension<MyColors>()!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Streaks'),
        actions: [
          IconButton(
            onPressed: () async {
              for (final streakId in selectedTask) {
                await _hive.delete(streakId);
              }
              selectionEnabled = false;
              selectedTask.clear();
              setState(() {});
            },
            icon: const Icon(Icons.delete),
          ).when(selectionEnabled && selectedTask.isNotEmpty),
        ],
      ),
      floatingActionButton: FloatingActionButton.small(
        // shape: const CircleBorder(),
        backgroundColor: Colors.cyan.shade900,
        child: const Icon(Icons.add),
        onPressed: () {
          TaskMethods.createOrEditTask(context, ref: ref);
        },
      ),
      body: AnimationLimiter(
        child: _hive.keys.isEmpty
            ? const EmptyScreenUI(text: 'Here All Your Streaks and Streaks WIll be Listed...')
            : ListView.builder(
                itemCount: _hive.keys.length,
                physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                itemBuilder: (context, index) {
                  final taskKey = _hive.keys.elementAt(index);
                  final bool isSelected = selectedTask.contains(taskKey);
                  final Task task = _hive.get(taskKey);
                  DateTime? startDate;
                  final bool isActive = task.sessions?.any((e) {
                        final status = (e.active ?? false);
                        if (status) startDate = e.startDateTime;
                        return status;
                      }) ??
                      false;

                  return AnimationConfiguration.staggeredList(
                    position: index,
                    delay: const Duration(milliseconds: 100),
                    child: SlideAnimation(
                      duration: const Duration(milliseconds: 1500),
                      curve: Curves.fastLinearToSlowEaseIn,
                      child: FadeInAnimation(
                        curve: Curves.fastLinearToSlowEaseIn,
                        duration: const Duration(milliseconds: 1500),
                        child: GestureDetector(
                          onTap: () {
                            if (selectionEnabled && !isSelected) {
                              selectedTask.add(taskKey);
                            } else if (isSelected) {
                              selectedTask.remove(taskKey);
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TaskView(task),
                                ),
                              );
                            }
                            setState(() {});
                          },
                          onLongPress: () {
                            selectionEnabled = true;
                            if (!isSelected && selectionEnabled) {
                              selectedTask.add(taskKey);
                            } else {
                              selectedTask.remove(taskKey);
                            }
                            setState(() {});
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      (task.name ?? '').text.medium.lg.make(),
                                    ],
                                  )
                                ],
                              ),
                              _MiniTaskTimerUI(startDate),
                              IconButton(
                                icon: Icon(isActive ? Icons.pause : Icons.play_arrow),
                                onPressed: () {
                                  if (isActive) {
                                    TaskMethods.endTaskActiveSession(task: task);
                                  } else {
                                    TaskMethods.startNewTaskSession(task: task);
                                  }
                                  setState(() {});
                                },
                              ),
                            ],
                          )
                              .box
                              .padding(const EdgeInsets.symmetric(horizontal: 12, vertical: 6))
                              .border(
                                width: 1.5,
                                color: Vx.zinc600,
                                style: isSelected ? BorderStyle.solid : BorderStyle.none,
                              )
                              .color(isSelected ? Vx.zinc800 : myColor.secondaryLight!)
                              .withRounded(value: 10)
                              .make()
                              .pSymmetric(h: 12, v: 8),
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _MiniTaskTimerUI extends HookWidget {
  const _MiniTaskTimerUI(this.startDate);

  final DateTime? startDate;

  @override
  Widget build(BuildContext context) {
    if (startDate == null) return const VxNone();
    final refreshController = useRefreshController(duration: const Duration(seconds: 1));

    final timeString = useCallback((Duration d) {
      final hour = StreakCalc.formatTwoDigitNumber(d.inHours % 24);
      final minute = StreakCalc.formatTwoDigitNumber(d.inMinutes % 60);
      final second = StreakCalc.formatTwoDigitNumber(d.inSeconds % 60);
      return '$hour : $minute : $second';
    });

    return StreamBuilder(
      stream: refreshController.stream,
      builder: (context, snapshot) {
        final Duration diff = DateTime.now().difference((startDate)!);
        return timeString(diff).text.make();
      },
    );
  }
}
