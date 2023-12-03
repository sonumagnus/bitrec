import 'package:bitrec/themes/my_colors.dart';
import 'package:bitrec/utils/habbit_calc.dart';
import 'package:bitrec/widgets/empty_screen_ui.dart';
import 'package:bitrec/widgets/habbit_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:velocity_x/velocity_x.dart';

class HabbitList extends StatefulWidget {
  const HabbitList({super.key});

  @override
  State<HabbitList> createState() => _HabbitListState();
}

class _HabbitListState extends State<HabbitList> {
  final selectedHabbit = [];
  final hive = Hive.box('habbits');
  bool selectionEnabled = false;

  @override
  Widget build(BuildContext context) {
    final MyColors myColor = Theme.of(context).extension<MyColors>()!;
    return WillPopScope(
      onWillPop: () async {
        if (selectionEnabled || selectedHabbit.isNotEmpty) {
          setState(() {
            selectionEnabled = false;
            selectedHabbit.clear();
          });
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Habbits'),
          actions: [
            IconButton(
              onPressed: () async {
                for (final habbitId in selectedHabbit) {
                  await hive.delete(habbitId);
                }
                selectionEnabled = false;
                selectedHabbit.clear();
                setState(() {});
              },
              icon: const Icon(Icons.delete),
            ).when(selectionEnabled && selectedHabbit.isNotEmpty),
          ],
        ),
        body: AnimationLimiter(
          child: hive.keys.isEmpty
              ? const EmptyScreenUI(text: 'Here All Your Habbits and Streaks WIll be Listed...')
              : ListView.builder(
                  physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                  itemCount: hive.keys.length,
                  itemBuilder: (context, index) {
                    final habbitKey = hive.keys.elementAt(index);
                    final bool isSelected = selectedHabbit.contains(habbitKey);
                    final List habbitWithHistory = hive.get(habbitKey);
                    final habbit = habbitWithHistory.firstWhere((e) => e['active'] as bool);
                    final target = habbit['target'] as int;
                    final startDate = HabbitCalc.memoryToStartDateTime(habbit);
                    final Duration differnce = HabbitCalc.calculateDateDifference(
                      target: target,
                      specificDate: startDate,
                    );
                    final percentage = HabbitCalc.getPercentage(target: habbit['target'], diff: differnce);
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
                                selectedHabbit.add(habbitKey);
                              } else if (isSelected) {
                                selectedHabbit.remove(habbitKey);
                              } else {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => HabbitView(
                                      habbitId: habbitKey,
                                      habbitWithHistory: habbitWithHistory,
                                    ),
                                  ),
                                );
                              }
                              setState(() {});
                            },
                            onLongPress: () {
                              selectionEnabled = true;
                              if (!isSelected && selectionEnabled) {
                                selectedHabbit.add(habbitKey);
                              } else {
                                selectedHabbit.remove(habbitKey);
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
                                        (habbit['name']).toString().text.medium.lg.make(),
                                        HabbitCalc.formatDateTime(startDate).text.zinc400.sm.make(),
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
