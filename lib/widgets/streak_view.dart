import 'package:bitrec/custom_hooks/ui_refresh_controller_hook.dart';
import 'package:bitrec/hive/adapters/attempt.dart';
import 'package:bitrec/hive/adapters/streak.dart';
import 'package:bitrec/screens/bottom_navbar.dart';
import 'package:bitrec/screens/streak_hitstory.dart';
import 'package:bitrec/screens/streak_screen.dart';
import 'package:bitrec/utils/streak_methods.dart';
import 'package:bitrec/utils/streak_calc.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:velocity_x/velocity_x.dart';

class StreakView extends HookConsumerWidget {
  const StreakView(this.streak, {super.key});

  final Streak streak;

  Attempt? get attempt => streak.attempts?.firstWhere((e) => e.active ?? false);
  int get totalAttempt => (streak.attempts?.length)! - 1;
  int get target => (attempt?.target)!;
  String get name => (attempt?.name)!;
  String get streakId => (streak.streakId)!;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hive = useMemoized<Box<dynamic>>(() => Hive.box('rex'), const []);
    final refreshController = useRefreshController(duration: const Duration(seconds: 1));

    return StreamBuilder<int>(
      stream: refreshController.stream,
      builder: (context, snapshot) {
        final diff = DateTime.now().difference((attempt?.startDateTime)!);
        final percentage = StreakCalc.getPercentage(target: target, diff: diff);
        final remaining = Duration(days: target) - diff;

        return Scaffold(
          appBar: AppBar(
            title: name.text.medium.minFontSize(25).make(),
            centerTitle: true,
            actions: [
              PopupMenuButton(
                itemBuilder: (context) {
                  final List? pinnedStreaks = hive.get('pinnedStreaks') ?? [];
                  const double iconSize = 18;
                  const sizer = SizedBox(width: 8);
                  return [
                    PopupMenuItem(
                      child: Row(
                        children: [
                          Icon(
                            pinnedStreaks!.contains(streakId) ? CupertinoIcons.pin_slash : CupertinoIcons.pin,
                            size: iconSize,
                          ),
                          sizer,
                          Text(pinnedStreaks.contains(streakId) ? "Unpin" : "Pin"),
                        ],
                      ),
                      onTap: () {
                        if (pinnedStreaks.isEmpty) {
                          hive.put('pinnedStreaks', [streakId]);
                        } else {
                          if (pinnedStreaks.contains(streakId)) {
                            pinnedStreaks.removeWhere((e) => e == streakId);
                          } else {
                            pinnedStreaks.insert(0, streakId);
                          }
                          hive.put('pinnedStreaks', pinnedStreaks);
                        }

                        final refresher = ref.read(streakViewRefresherProvider);
                        final selectedIndex = ref.read(selectedIndexProvider);
                        if (refresher != null && selectedIndex == 0) refresher();
                      },
                    ),
                    PopupMenuItem(
                      child: const Row(
                        children: [
                          Icon(Icons.edit, size: iconSize),
                          sizer,
                          Text('Edit'),
                        ],
                      ),
                      onTap: () {
                        StreakMethods.createOrEditStreak(
                          context,
                          ref: ref,
                          edit: true,
                          streak: streak,
                        );
                      },
                    ),
                    PopupMenuItem(
                      onTap: () {
                        StreakMethods.showDeleteAlert(
                          context,
                          streak: streak,
                          ref: ref,
                        );
                      },
                      child: const Row(
                        children: [
                          Icon(CupertinoIcons.delete, size: iconSize),
                          sizer,
                          Text('Delete'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      onTap: () {
                        StreakMethods.showRestartDialog(context, streak: streak, ref: ref);
                      },
                      child: const Row(
                        children: [
                          Icon(CupertinoIcons.restart, size: iconSize),
                          sizer,
                          Text('Restart'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => StreakHistoryUI(streak),
                          ),
                        );
                      },
                      child: const Row(
                        children: [
                          Icon(Icons.history, size: iconSize),
                          sizer,
                          Text('History'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      onTap: () {
                        StreakMethods.showMoreAboutStreak(
                          context,
                          name: name,
                          diff: diff,
                          target: target,
                          remaining: remaining,
                          percentage: percentage,
                          totalAttempt: totalAttempt,
                        );
                      },
                      child: const Row(
                        children: [
                          Icon(CupertinoIcons.info_circle, size: iconSize),
                          sizer,
                          Text('More'),
                        ],
                      ),
                    )
                  ];
                },
              )
            ],
          ),
          body: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: [
              const SizedBox.shrink(),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    height: 300,
                    width: 300,
                    child: SfRadialGauge(
                      axes: <RadialAxis>[
                        RadialAxis(
                          showLabels: false,
                          showTicks: false,
                          radiusFactor: 0.8,
                          axisLineStyle: const AxisLineStyle(
                            thickness: 0.08,
                            cornerStyle: CornerStyle.bothCurve,
                            gradient: SweepGradient(
                              colors: <Color>[
                                Colors.deepPurple,
                                Colors.red,
                                Color(0xFFFFDD00),
                                Color(0xFFFFDD00),
                                Color(0xFF30B32D),
                              ],
                              stops: <double>[0, 0.03, 0.5833333, 0.73, 1],
                            ),
                            // color: myColor.primaryLight,
                            thicknessUnit: GaugeSizeUnit.factor,
                          ),
                          pointers: <GaugePointer>[
                            RangePointer(
                              color: Colors.white.withOpacity(0.5),
                              value: percentage,
                              cornerStyle: CornerStyle.bothCurve,
                              width: 0.08,
                              sizeUnit: GaugeSizeUnit.factor,
                              enableAnimation: true,
                              animationDuration: 20,
                              animationType: AnimationType.linear,
                            )
                          ],
                          annotations: <GaugeAnnotation>[
                            GaugeAnnotation(
                              positionFactor: percentage * 100,
                              angle: 90,
                              widget: const VxNone(),
                            )
                          ],
                        )
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              (diff.inDays).text.minFontSize(52).lineHeight(0.9).bold.make(),
                              const SizedBox(width: 5),
                              "Days".text.sm.make(),
                            ],
                          ).pOnly(left: 30),
                          Row(
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  (diff.inHours % 24).text.minFontSize(40).lineHeight(0.9).semiBold.make(),
                                  const SizedBox(width: 5),
                                  "Hour".text.sm.make(),
                                ],
                              ),
                              const SizedBox(width: 6),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  (diff.inMinutes % 60).text.minFontSize(36).lineHeight(0.9).semiBold.make(),
                                  const SizedBox(width: 5),
                                  "Minute".text.sm.make(),
                                ],
                              ).pOnly(top: 20)
                            ],
                          ),
                          const SizedBox(height: 18),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              (diff.inSeconds % 60).text.minFontSize(24).lineHeight(0.9).medium.make(),
                              const SizedBox(width: 5),
                              "Seconds".text.sm.make(),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(Icons.menu, size: 20, color: Vx.zinc400).box.height(42).make().onTap(() {
                    StreakMethods.showMoreAboutStreak(
                      context,
                      name: name,
                      percentage: percentage,
                      target: target,
                      diff: diff,
                      remaining: remaining,
                      totalAttempt: totalAttempt,
                    );
                  }).expand(),
                  const Icon(CupertinoIcons.restart, size: 20, color: Vx.zinc400).box.height(42).make().onTap(() {
                    StreakMethods.showRestartDialog(context, ref: ref, streak: streak);
                  }).expand(),
                  const Icon(Icons.history, size: 20, color: Vx.zinc400).box.height(42).make().onTap(() {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => StreakHistoryUI(streak)),
                    );
                  }).expand(),
                ],
              )
                  .box
                  .roundedLg
                  .clip(Clip.hardEdge)
                  .width(
                    context.mq.size.width * (3 / 4),
                  )
                  .border(color: Vx.zinc700)
                  .make(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  RemainDurUI(
                    firstTxt: remaining.inDays.toString(),
                    secondTxt: 'Days Remaining',
                    color: Vx.zinc400,
                  ).when(remaining.inDays >= 0),
                  RemainDurUI(
                    firstTxt: 'Completed +',
                    secondTxt: "${remaining.inDays.abs()} Days",
                    color: Vx.zinc400,
                  ).when(remaining.inDays < 0),
                ],
              ),
              const SizedBox()
            ],
          ).safeArea(),
        );
      },
    );
  }
}

class RemainDurUI extends StatelessWidget {
  const RemainDurUI({
    super.key,
    required this.firstTxt,
    required this.secondTxt,
    this.color = Colors.white,
  });

  final String firstTxt;
  final String secondTxt;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        firstTxt.text.xl.color(color).make(),
        const SizedBox(width: 4),
        secondTxt.text.color(color).xl.make(),
      ],
    );
  }
}
