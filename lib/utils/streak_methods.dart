import 'package:bitrec/hive/adapters/attempt.dart';
import 'package:bitrec/hive/adapters/streak.dart';
import 'package:bitrec/screens/bottom_navbar.dart';
import 'package:bitrec/screens/streak_screen.dart';
import 'package:bitrec/utils/streak_calc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:velocity_x/velocity_x.dart';

class StreakMethods {
  static final _hiveBox = Hive.box('streaks');
  static const _uuid = Uuid();
  static createOrEditStreak(
    BuildContext context, {
    required WidgetRef ref,
    Streak? streak,
    bool edit = false,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final attempt = streak?.attempts?.firstWhere((e) => e.active ?? false);
        return Dialog(
          backgroundColor: Colors.black.withGreen(5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.0),
          ),
          child: HookBuilder(
            builder: (context) {
              final formKey = useMemoized(() => GlobalKey<FormState>(), const []);

              final habitDateTime = useMemoized(
                () => edit ? attempt?.startDateTime : null,
                const [],
              );

              final nameFieldController = useTextEditingController(
                text: edit ? attempt?.name : null,
              );

              final targetFieldController = useTextEditingController(
                text: edit ? (attempt?.target).toString() : null,
              );

              final selectedDate = useState<DateTime>(
                edit ? habitDateTime! : DateTime.now(),
              );

              final selectedTime = useState<TimeOfDay>(edit
                  ? TimeOfDay(
                      hour: habitDateTime!.hour,
                      minute: habitDateTime.minute,
                    )
                  : TimeOfDay.now());

              String dateTimeFieldtxt() {
                String dgn(int n) => StreakCalc.formatTwoDigitNumber(n);
                return '${dgn(selectedDate.value.day)}-${dgn(selectedDate.value.month)}-${selectedDate.value.year}  ${dgn(selectedTime.value.hour)}:${dgn(selectedTime.value.minute)}';
              }

              final dateTimeFieldController = useTextEditingController(
                text: edit ? dateTimeFieldtxt() : null,
              );

              selectDate() async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate.value,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2101),
                );
                if (picked != selectedDate.value && picked != null) {
                  selectedDate.value = picked;
                }
              }

              selectTime() async {
                final TimeOfDay? picked = await showTimePicker(
                  context: context,
                  initialTime: selectedTime.value,
                );
                if (picked != selectedTime.value && picked != null) {
                  selectedTime.value = picked;
                }
              }

              void submitHandler() {
                final dateTimeNow = DateTime.now();

                final Attempt attempt = Attempt(
                  name: nameFieldController.text,
                  target: int.parse(targetFieldController.text),
                  active: true,
                  startDateTime: DateTime(
                    selectedDate.value.year,
                    selectedDate.value.month,
                    selectedDate.value.day,
                    selectedTime.value.hour,
                    selectedTime.value.minute,
                    edit ? (habitDateTime?.second)! : dateTimeNow.second,
                    edit ? (habitDateTime?.millisecond)! : dateTimeNow.millisecond,
                  ),
                );

                if (edit) {
                  final updatedAttemptList = streak?.attempts?.replaceWhere((e) => e.active ?? false, attempt).toList();
                  final Streak editedStreak = Streak(
                    streakId: streak?.streakId,
                    name: streak?.name,
                    attempts: updatedAttemptList,
                  );
                  _hiveBox.put(streak?.streakId, editedStreak);
                } else {
                  final streakId = _uuid.v4();
                  _hiveBox.put(
                    streakId,
                    Streak(
                      streakId: streakId,
                      name: nameFieldController.text,
                      attempts: [attempt],
                    ),
                  );
                }

                nameFieldController.clear();
                targetFieldController.clear();
                dateTimeFieldController.clear();

                Navigator.of(context).pop();
              }

              return Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameFieldController,
                      decoration: const InputDecoration(labelText: 'Streak Name'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Streak name is required';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: targetFieldController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Target (in Days)',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Target days is required';
                        }
                        return null;
                      },
                    ).py12(),
                    TextFormField(
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Date & Time is required';
                        }
                        return null;
                      },
                      readOnly: true,
                      controller: dateTimeFieldController,
                      onTap: () {
                        Future.wait([selectDate(), selectTime()]).then((value) {
                          dateTimeFieldController.text = dateTimeFieldtxt();
                        });
                      },
                      decoration: const InputDecoration(labelText: 'Select Date and Time'),
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
                              if (ref.read(selectedIndexProvider) == 1) {
                                ref.read(streakViewRefresherProvider)!();
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

  static void showDeleteAlert(
    BuildContext context, {
    required Streak streak,
    required WidgetRef ref,
  }) {
    final refreshPage = ref.read(streakViewRefresherProvider);
    final rexBox = Hive.box('rex');
    final List pinnedStreaks = rexBox.get('pinnedStreaks') ?? [];

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.black.withGreen(5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.0),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              "Are you sure you want to delete this streak!".text.center.make(),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
                    child: const Text('Cancel'),
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
                      if (pinnedStreaks.contains(streak.streakId)) {
                        pinnedStreaks.removeWhere((e) => e == streak.streakId);
                        rexBox.put('pinnedStreaks', pinnedStreaks);
                      }
                      _hiveBox.delete(streak.streakId);
                      if (refreshPage != null) refreshPage();
                      Navigator.of(context).pop();
                    },
                    child: const Text('Delete'),
                  ).expand(),
                ],
              ),
            ],
          ).box.padding(const EdgeInsets.all(20)).make(),
        );
      },
    );
  }

  static showRestartDialog(
    BuildContext ctx, {
    required WidgetRef ref,
    required Streak streak,
  }) {
    return showDialog(
      context: ctx,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.black.withGreen(5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.0),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              "Are you sure you want to restart this streak!".text.center.make(),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
                    child: const Text('Cancel'),
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
                      _restartStreak(streak: streak, ref: ref);
                      Navigator.pop(context);
                    },
                    child: const Text('Restart'),
                  ).expand(),
                ],
              )
            ],
          ).box.padding(const EdgeInsets.all(20)).make(),
        );
      },
    );
  }

  static void _restartStreak({
    required Streak streak,
    required WidgetRef ref,
  }) {
    final attempt = streak.attempts?.firstWhere((e) => e.active ?? false);

    final currDate = DateTime.now();
    final currTime = TimeOfDay.now();

    attempt?.active = false;
    attempt?.attemptId = _uuid.v4();

    attempt?.endDateTime = DateTime(
      currDate.year,
      currDate.month,
      currDate.day,
      currTime.hour,
      currTime.minute,
      currDate.second,
      currDate.millisecond,
    );

    final newActiveAttempt = Attempt(
      name: attempt?.name,
      target: attempt?.target,
      active: true,
      startDateTime: DateTime(
        currDate.year,
        currDate.month,
        currDate.day,
        currTime.hour,
        currTime.minute,
        currDate.second,
        currDate.millisecond,
      ),
    );

    final newStreak = Streak(
      streakId: streak.streakId,
      name: streak.name,
      attempts: [newActiveAttempt, ...(streak.attempts)!],
    );

    _hiveBox.put(streak.streakId, newStreak);

    final Function? refreshPage = ref.read(streakViewRefresherProvider);
    if (ref.read(selectedIndexProvider) == 0) {
      if (refreshPage != null) refreshPage();
    }
  }

  static List getRealStreakOrder() {
    final allStreakKeys = _hiveBox.keys.toList();
    final List? pinnedStreaks = Hive.box('rex').get('pinnedStreaks');
    if (pinnedStreaks == null) return allStreakKeys;

    for (final id in pinnedStreaks.reversed) {
      if (allStreakKeys.contains(id)) {
        final keyIndex = allStreakKeys.indexWhere((e) => e == id);
        final String removedId = allStreakKeys.removeAt(keyIndex);
        allStreakKeys.insertT(0, removedId);
      }
    }
    return allStreakKeys;
  }

  static void showMoreAboutStreak(
    BuildContext ctx, {
    required String? name,
    required double percentage,
    required int? target,
    required Duration diff,
    required Duration remaining,
    required int totalAttempt,
  }) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      builder: (context) {
        return Wrap(
          children: [
            Container(
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10.0),
                  topRight: Radius.circular(10.0),
                ),
              ),
              child: Wrap(
                children: [
                  ListTile(
                    title: 'Name'.text.make(),
                    trailing: (name ?? '').text.make(),
                  ),
                  ListTile(
                    title: 'Complete in Percentage'.text.make(),
                    trailing: "${percentage.toStringAsFixed(2)} %".text.make(),
                  ),
                  ListTile(
                    title: 'Target Days'.text.make(),
                    trailing: (target ?? 0).text.make(),
                  ),
                  ListTile(
                    title: 'Complete Days'.text.make(),
                    trailing: "${diff.inDays}d ${diff.inHours % 24}h ${diff.inMinutes % 60}m".text.make(),
                  ),
                  ListTile(
                    title: 'Remaing Days'.text.make(),
                    trailing: "${remaining.inDays}d ${remaining.inHours % 24}h ${remaining.inMinutes % 60}m".text.make(),
                  ).when(remaining.inDays >= 0),
                  ListTile(
                    title: 'Remaing Days'.text.make(),
                    trailing: "Completed + ${remaining.inDays.abs()}d ${remaining.inHours % 24}h ${remaining.inMinutes % 60}m".text.make(),
                  ).when(remaining.inDays < 0),
                  ListTile(
                    title: 'Total Attempt'.text.make(),
                    trailing: totalAttempt.text.make(),
                  ),
                ],
              ),
            )
          ],
        );
      },
    );
  }
}
