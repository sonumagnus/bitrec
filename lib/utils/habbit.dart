import 'package:bitrec/screens/bottom_navbar.dart';
import 'package:bitrec/screens/home.dart';
import 'package:bitrec/utils/habbit_calc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:velocity_x/velocity_x.dart';

class Habbit {
  static final _hiveBox = Hive.box('habbits');
  static const _uuid = Uuid();
  static createOrEditHabbit(
    BuildContext context, {
    required WidgetRef ref,
    String? habbitId,
    dynamic habbit,
    bool edit = false,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.black.withGreen(5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.0),
          ),
          child: HookBuilder(
            builder: (context) {
              final formKey = useMemoized(() => GlobalKey<FormState>(), const []);

              final habitDateTime = useMemoized(
                () => edit ? HabbitCalc.memoryToStartDateTime(habbit) : null,
                const [],
              );

              final nameFieldController = useTextEditingController(
                text: edit ? habbit['name'] : null,
              );

              final targetFieldController = useTextEditingController(
                text: edit ? (habbit['target']).toString() : null,
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
                String dgn(int n) => HabbitCalc.formatTwoDigitNumber(n);
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
                final habbitObj = {
                  'name': nameFieldController.text,
                  'target': int.parse(targetFieldController.text),
                  'active': true,
                  'attemptId': null,
                  'endDateTime': {
                    'millisecond': null,
                    'second': null,
                    'minute': null,
                    'hour': null,
                    'day': null,
                    'month': null,
                    'year': null,
                  },
                  'dateTime': {
                    'millisecond': edit ? habitDateTime?.millisecond : dateTimeNow.millisecond,
                    'second': edit ? habitDateTime?.second : dateTimeNow.second,
                    'minute': selectedTime.value.minute,
                    'hour': selectedTime.value.hour,
                    'day': selectedDate.value.day,
                    'month': selectedDate.value.month,
                    'year': selectedDate.value.year,
                  },
                };

                if (edit) {
                  final List habbitWithHitstory = _hiveBox.get(habbitId);

                  final newHabitObjList = habbitWithHitstory
                      .replaceWhere(
                        (e) => e['active'] as bool,
                        habbitObj,
                      )
                      .toList();

                  _hiveBox.put(habbitId, newHabitObjList);
                } else {
                  _hiveBox.put(_uuid.v4(), [habbitObj]);
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
                      decoration: const InputDecoration(labelText: 'Habbit Name'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Habbit name is required';
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
                              if (ref.read(selectedIndexProvider) == 0) {
                                ref.read(habbitViewRefresherProvider)!();
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
    required String? habbitId,
    required dynamic habbit,
    required WidgetRef ref,
  }) {
    final refreshPage = ref.read(habbitViewRefresherProvider);
    final rexBox = Hive.box('rex');
    final List pinnedHabbits = rexBox.get('pinnedHabbits') ?? [];

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
              "Are you sure you want to delete this habbit!".text.center.make(),
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
                      if (pinnedHabbits.contains(habbitId)) {
                        pinnedHabbits.removeWhere((e) => e == habbitId);
                        rexBox.put('pinnedHabbits', pinnedHabbits);
                      }
                      _hiveBox.delete(habbitId);
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
    required String? habbitId,
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
              "Are you sure you want to restart this habbit!".text.center.make(),
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
                      _restartHabbit(habbitId: habbitId, ref: ref);
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

  static void _restartHabbit({
    required String? habbitId,
    required WidgetRef ref,
  }) {
    final List<dynamic> habbitWithHistory = _hiveBox.get(habbitId);
    final habbit = habbitWithHistory.firstWhere((e) => e['active'] as bool);
    final currDate = DateTime.now();
    final currTime = TimeOfDay.now();

    habbit['active'] = false;
    habbit['attemptId'] = _uuid.v4();

    habbit['endDateTime'] = {
      'year': currDate.year,
      'month': currDate.month,
      'day': currDate.day,
      'hour': currTime.hour,
      'minute': currTime.minute,
      'second': currDate.second,
      'millisecond': currDate.millisecond,
    };

    final dynamic newHabbit = {
      'name': habbit['name'],
      'target': habbit['target'],
      'active': true,
      'attemptId': null,
      'endDateTime': {
        'millisecond': null,
        'second': null,
        'minute': null,
        'hour': null,
        'day': null,
        'month': null,
        'year': null,
      },
      'dateTime': {
        'millisecond': currDate.millisecond,
        'second': currDate.second,
        'minute': currTime.minute,
        'hour': currTime.hour,
        'day': currDate.day,
        'month': currDate.month,
        'year': currDate.year,
      },
    };

    final List<dynamic> newHabbitWithHistory = [newHabbit, ...habbitWithHistory];

    _hiveBox.put(habbitId, newHabbitWithHistory);

    final Function? refreshPage = ref.read(habbitViewRefresherProvider);
    if (ref.read(selectedIndexProvider) == 0) {
      if (refreshPage != null) refreshPage();
    }
  }

  static List getRealHabbitOrder() {
    final allHabbitKeys = _hiveBox.keys.toList();
    final List? pinnedHabbits = Hive.box('rex').get('pinnedHabbits');
    if (pinnedHabbits == null) return allHabbitKeys;

    for (final id in pinnedHabbits.reversed) {
      if (allHabbitKeys.contains(id)) {
        final keyIndex = allHabbitKeys.indexWhere((e) => e == id);
        final String removedId = allHabbitKeys.removeAt(keyIndex);
        allHabbitKeys.insertT(0, removedId);
      }
    }
    return allHabbitKeys;
  }

  static void showMoreAboutHabbit(
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
