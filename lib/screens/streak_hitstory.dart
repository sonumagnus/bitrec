import 'package:bitrec/hive/adapters/attempt.dart';
import 'package:bitrec/hive/adapters/streak.dart';
import 'package:bitrec/screens/streak_screen.dart';
import 'package:bitrec/themes/my_colors.dart';
import 'package:bitrec/utils/streak_calc.dart';
import 'package:bitrec/widgets/streak_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:velocity_x/velocity_x.dart';

class StreakHistoryUI extends ConsumerStatefulWidget {
  const StreakHistoryUI(this.streak, {super.key});
  final Streak streak;

  @override
  ConsumerState<StreakHistoryUI> createState() => _StreakHistoryUIState();
}

class _StreakHistoryUIState extends ConsumerState<StreakHistoryUI> {
  String? get name => widget.streak.name;
  String? get streakId => widget.streak.streakId;
  late List<Attempt>? attempts;

  final List<String> selectedAttemptList = [];
  final hive = Hive.box('streaks');
  bool selectionEnabled = false;

  void getStreak() {
    final streakAttempts = widget.streak.attempts?.where((e) => !(e.active ?? false)).toList();
    streakAttempts?.sort((a, b) => (a.endDateTime)!.compareTo((b.startDateTime)!));
    attempts = streakAttempts!;
  }

  Duration diffDuration({required Attempt a}) {
    return (a.endDateTime)!.difference((a.startDateTime)!);
  }

  @override
  void initState() {
    super.initState();
    getStreak();
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
          title: "$name ( ${attempts?.length} Attempts )".text.make(),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                selectedAttemptList.forEachIndexed((int index, String element) {
                  attempts?.removeWhere((e) => e.attemptId == element);
                });
                attempts = attempts;

                final List<Attempt>? streakStreakList = widget.streak.attempts?.where((e) => e.active ?? false).toList();
                streakStreakList?.addAll(attempts ?? []);
                hive.put(streakId, streakStreakList);

                setState(() {
                  selectionEnabled = false;
                  selectedAttemptList.clear();
                });

                final refreshPage = ref.read(streakViewRefresherProvider);
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
            itemCount: attempts?.length,
            itemBuilder: (context, index) {
              final Attempt attempt = attempts!.elementAt(index);
              final Duration diff = diffDuration(a: attempt);
              final String attemptId = (attempt.attemptId)!;
              final bool isSelected = selectedAttemptList.contains(attempt.attemptId);
              final DateTime startDate = (attempt.startDateTime)!;
              final DateTime endDate = (attempt.endDateTime)!;
              final double percentage = StreakCalc.getPercentage(target: (attempt.target)!, diff: diff);
              final Duration differnce = DateTime.now().difference(startDate);

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
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => StreakView(widget.streak),
                            ),
                          );
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
                                      StreakCalc.formatDateTime(startDate).text.zinc400.sm.make(),
                                      ' - '.text.zinc400.sm.make(),
                                      StreakCalc.formatDateTime(endDate).text.zinc400.sm.make(),
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
                                  '${differnce.inDays}/${(attempt.target)!} Days'.text.zinc400.sm.make(),
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
