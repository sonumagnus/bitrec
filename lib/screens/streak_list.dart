import 'package:bitrec/hive/adapters/attempt.dart';
import 'package:bitrec/hive/adapters/streak.dart';
import 'package:bitrec/themes/my_colors.dart';
import 'package:bitrec/utils/streak_calc.dart';
import 'package:bitrec/widgets/empty_screen_ui.dart';
import 'package:bitrec/widgets/streak_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:velocity_x/velocity_x.dart';

class StreakList extends StatefulWidget {
  const StreakList({super.key});

  @override
  State<StreakList> createState() => _StreakListState();
}

class _StreakListState extends State<StreakList> {
  final selectedStreak = [];
  final hive = Hive.box('streaks');
  bool selectionEnabled = false;

  @override
  Widget build(BuildContext context) {
    final MyColors myColor = Theme.of(context).extension<MyColors>()!;
    return WillPopScope(
      onWillPop: () async {
        if (selectionEnabled || selectedStreak.isNotEmpty) {
          setState(() {
            selectionEnabled = false;
            selectedStreak.clear();
          });
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Streaks'),
          actions: [
            IconButton(
              onPressed: () async {
                for (final streakId in selectedStreak) {
                  await hive.delete(streakId);
                }
                selectionEnabled = false;
                selectedStreak.clear();
                setState(() {});
              },
              icon: const Icon(Icons.delete),
            ).when(selectionEnabled && selectedStreak.isNotEmpty),
          ],
        ),
        body: AnimationLimiter(
          child: hive.keys.isEmpty
              ? const EmptyScreenUI(text: 'Here All Your Streaks and Streaks WIll be Listed...')
              : ListView.builder(
                  physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                  itemCount: hive.keys.length,
                  itemBuilder: (context, index) {
                    final streakKey = hive.keys.elementAt(index);
                    final bool isSelected = selectedStreak.contains(streakKey);
                    final Streak streak = hive.get(streakKey);
                    final Attempt? attempt = streak.attempts?.firstWhere((e) => e.active ?? false);
                    final int target = (attempt?.target)!;
                    final DateTime startDate = (attempt?.startDateTime)!;
                    final Duration differnce = DateTime.now().difference(startDate);
                    final double percentage = StreakCalc.getPercentage(target: target, diff: differnce);

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
                                selectedStreak.add(streakKey);
                              } else if (isSelected) {
                                selectedStreak.remove(streakKey);
                              } else {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => StreakView(streak),
                                  ),
                                );
                              }
                              setState(() {});
                            },
                            onLongPress: () {
                              selectionEnabled = true;
                              if (!isSelected && selectionEnabled) {
                                selectedStreak.add(streakKey);
                              } else {
                                selectedStreak.remove(streakKey);
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
                                        (attempt?.name ?? '').text.medium.lg.make(),
                                        StreakCalc.formatDateTime(startDate).text.zinc400.sm.make(),
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
      ),
    );
  }
}
