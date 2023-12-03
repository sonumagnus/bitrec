import 'package:bitrec/screens/home.dart';
import 'package:bitrec/themes/my_colors.dart';
import 'package:bitrec/utils/habbit_calc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:velocity_x/velocity_x.dart';

class HabbitHistoryUI extends ConsumerStatefulWidget {
  const HabbitHistoryUI({
    super.key,
    required this.habbitWithHistory,
    required this.habbitId,
    required this.name,
  });

  final List habbitWithHistory;
  final String? habbitId, name;

  @override
  ConsumerState<HabbitHistoryUI> createState() => _HabbitHistoryUIState();
}

class _HabbitHistoryUIState extends ConsumerState<HabbitHistoryUI> {
  String? get name => widget.name;
  String? get habbitId => widget.habbitId;
  late List habbit;

  final List<String> selectedAttemptList = [];
  final hive = Hive.box('habbits');
  bool selectionEnabled = false;

  void getHabbit() {
    final attempts = widget.habbitWithHistory.where((e) => !(e['active'] as bool)).toList();
    attempts.sort(
      (a, b) => HabbitCalc.memoryToEndDateTime(a).compareTo(
        HabbitCalc.memoryToEndDateTime(b),
      ),
    );
    habbit = attempts;
  }

  Duration diffDuration({required Map habbit}) {
    return HabbitCalc.memoryToEndDateTime(habbit).difference(HabbitCalc.memoryToStartDateTime(habbit));
  }

  @override
  void initState() {
    super.initState();
    getHabbit();
  }

  @override
  Widget build(BuildContext context) {
    final MyColors myColor = Theme.of(context).extension<MyColors>()!;

    return WillPopScope(
      onWillPop: () async {
        if (selectionEnabled || selectedAttemptList.isNotEmpty) {
          setState(() {
            selectionEnabled = false;
            selectedAttemptList.clear();
          });
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: "$name ( ${habbit.length} Attempts )".text.make(),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                selectedAttemptList.forEachIndexed((int index, String element) {
                  habbit.removeWhere((e) => e['attemptId'] == element);
                });
                habbit = habbit;

                final habbitStreakList = widget.habbitWithHistory.where((e) => e['active'] as bool).toList();
                habbitStreakList.addAll(habbit);
                hive.put(habbitId, habbitStreakList);

                setState(() {
                  selectionEnabled = false;
                  selectedAttemptList.clear();
                });

                final refreshPage = ref.read(habbitViewRefresherProvider);
                if (refreshPage != null) refreshPage();
              },
            ).when(selectionEnabled && selectedAttemptList.isNotEmpty),
          ],
        ),
        body: AnimationLimiter(
          child: ListView.builder(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            itemCount: habbit.length,
            itemBuilder: (context, index) {
              final attempt = habbit.elementAt(index);
              final target = attempt['target'] as int;
              final diff = diffDuration(habbit: attempt);
              final attemptId = attempt['attemptId'] as String;
              final isSelected = selectedAttemptList.contains(attemptId);
              final startDate = HabbitCalc.memoryToStartDateTime(attempt);
              final endDate = HabbitCalc.memoryToEndDateTime(attempt);
              final percentage = HabbitCalc.getPercentage(target: target, diff: diff);
              final differnce = HabbitCalc.calculateDateDifference(
                target: target,
                specificDate: startDate,
              );

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
                          selectedAttemptList.add(attemptId);
                        } else if (isSelected) {
                          selectedAttemptList.remove(attemptId);
                        } else {
                          // Navigator.push(
                          //   context,
                          //   MaterialPageRoute(
                          //     builder: (context) => HabbitView(
                          //       habbitId: habbitKey,
                          //       habbitWithHistory: habbitWithHistory,
                          //     ),
                          //   ),
                          // );
                        }
                        setState(() {});
                      },
                      onLongPress: () {
                        selectionEnabled = true;
                        if (!isSelected && selectionEnabled) {
                          selectedAttemptList.add(attemptId);
                        } else {
                          selectedAttemptList.remove(attemptId);
                        }
                        setState(() {});
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  "Attempt ${index + 1}".text.lg.make(),
                                  Row(
                                    children: [
                                      HabbitCalc.formatDateTime(startDate).text.zinc400.sm.make(),
                                      ' - '.text.zinc400.sm.make(),
                                      HabbitCalc.formatDateTime(endDate).text.zinc400.sm.make(),
                                    ],
                                  ),
                                ],
                              ),
                              LinearProgressIndicator(
                                value: percentage / 100,
                                borderRadius: BorderRadius.circular(50),
                              ).box.height(2).make().py8(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  '${differnce.inDays}/$target Days'.text.zinc400.sm.make(),
                                  "${percentage.toStringAsFixed(0)}%".text.zinc400.sm.make(),
                                ],
                              ),
                            ],
                          ).expand(),
                        ],
                      )
                          .box
                          .padding(const EdgeInsets.symmetric(horizontal: 12, vertical: 6))
                          .border(
                            width: 1.5,
                            color: Vx.zinc600,
                            style: isSelected ? BorderStyle.solid : BorderStyle.none,
                          )
                          .color(isSelected ? Vx.zinc700 : myColor.secondaryLight!)
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
      ),
    );
  }
}
