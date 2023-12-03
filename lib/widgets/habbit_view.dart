import 'package:bitrec/custom_hooks/ui_refresh_controller_hook.dart';
import 'package:bitrec/screens/bottom_navbar.dart';
import 'package:bitrec/screens/habbit_hitstory.dart';
import 'package:bitrec/screens/home.dart';
import 'package:bitrec/utils/habbit.dart';
import 'package:bitrec/utils/habbit_calc.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:velocity_x/velocity_x.dart';
// import 'package:bitrec/themes/my_colors.dart';

class HabbitView extends HookConsumerWidget {
  const HabbitView({super.key, required this.habbitId, required this.habbitWithHistory});

  final String? habbitId;
  final List habbitWithHistory;

  dynamic get habbit => habbitWithHistory.firstWhere((e) => e['active'] as bool);
  int get totalAttempt => habbitWithHistory.length - 1;
  String? get name => habbit['name'];
  int? get target => habbit['target'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // final MyColors myColor = useMemoized(() => Theme.of(context).extension<MyColors>()!, const []);
    final hive = useMemoized<Box<dynamic>>(() => Hive.box('rex'), const []);

    final refreshController = useRefreshController(duration: const Duration(seconds: 1));

    return StreamBuilder<int>(
      stream: refreshController.stream,
      builder: (context, snapshot) {
        final diff = HabbitCalc.calculateDateDifference(
          target: target!,
          specificDate: HabbitCalc.memoryToStartDateTime(habbit),
        );

        final percentage = HabbitCalc.getPercentage(target: target!, diff: diff);
        final remaining = Duration(days: target!) - diff;

        return Scaffold(
          appBar: AppBar(
            title: (name ?? 'No Name').text.medium.minFontSize(25).make(),
            centerTitle: true,
            actions: [
              PopupMenuButton(
                itemBuilder: (context) {
                  final List? pinnedHabbits = hive.get('pinnedHabbits') ?? [];
                  const double iconSize = 18;
                  const sizer = SizedBox(width: 8);
                  return [
                    PopupMenuItem(
                      child: Row(
                        children: [
                          Icon(
                            pinnedHabbits!.contains(habbitId) ? CupertinoIcons.pin_slash : CupertinoIcons.pin,
                            size: iconSize,
                          ),
                          sizer,
                          Text(pinnedHabbits.contains(habbitId) ? "Unpin" : "Pin"),
                        ],
                      ),
                      onTap: () {
                        if (pinnedHabbits.isEmpty) {
                          hive.put('pinnedHabbits', [habbitId]);
                        } else {
                          if (pinnedHabbits.contains(habbitId)) {
                            pinnedHabbits.removeWhere((e) => e == habbitId);
                          } else {
                            pinnedHabbits.insert(0, habbitId);
                          }
                          hive.put('pinnedHabbits', pinnedHabbits);
                        }

                        final refresher = ref.read(habbitViewRefresherProvider);
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
                        Habbit.createOrEditHabbit(
                          context,
                          ref: ref,
                          edit: true,
                          habbitId: habbitId,
                          habbit: habbit,
                        );
                      },
                    ),
                    PopupMenuItem(
                      onTap: () {
                        Habbit.showDeleteAlert(
                          context,
                          habbitId: habbitId,
                          habbit: habbit,
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
                        Habbit.showRestartDialog(context, habbitId: habbitId, ref: ref);
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
                            builder: (context) => HabbitHistoryUI(
                              name: name,
                              habbitWithHistory: habbitWithHistory,
                              habbitId: habbitId,
                            ),
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
                        Habbit.showMoreAboutHabbit(
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
                    Habbit.showMoreAboutHabbit(
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
                    Habbit.showRestartDialog(context, ref: ref, habbitId: habbitId);
                  }).expand(),
                  const Icon(Icons.history, size: 20, color: Vx.zinc400).box.height(42).make().onTap(() {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HabbitHistoryUI(
                          name: name,
                          habbitWithHistory: habbitWithHistory,
                          habbitId: habbitId,
                        ),
                      ),
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

// class HabbitView extends ConsumerStatefulWidget {
//   const HabbitView({
//     super.key,
//     required this.habbitId,
//     required this.habbit,
//   });

//   final String? habbitId;
//   final dynamic habbit;

//   @override
//   ConsumerState<HabbitView> createState() => _HabbitViewState();
// }

// class _HabbitViewState extends ConsumerState<HabbitView> {
//   List get habbitWithHitstory => widget.habbit;
//   dynamic get habbit => habbitWithHitstory.firstWhere((e) => e['active'] as bool);
//   String? get habbitId => widget.habbitId;
//   String? get name => habbit['name'];
//   int? get target => habbit['target'];
//   late Function? refreshPage;

//   late StreamController<int> _refreshController;
//   late Timer _timer;
//   int _counter = 0;

//   final hive = Hive.box('rex');

//   Duration getRemainingDays(Duration diff, int target) {
//     return Duration(days: target) - diff;
//   }

//   void setRefreshFn() {
//     refreshPage = ref.read(habbitViewRefresherProvider);
//     setState(() {});
//   }

//   @override
//   void initState() {
//     setRefreshFn();
//     // Initialize the StreamController
//     _refreshController = StreamController<int>();

//     // Set up a periodic timer to refresh every minute
//     _timer = Timer.periodic(const Duration(seconds: 1), (_) {
//       // Add an event to the stream to trigger the refresh
//       _refreshController.add(_counter++);
//     });
//     super.initState();
//   }

//   @override
//   void dispose() {
//     // Cancel the timer and close the stream when the widget is disposed
//     _timer.cancel();
//     _refreshController.close();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final MyColors myColor = Theme.of(context).extension<MyColors>()!;

//     return StreamBuilder<int>(
//       stream: _refreshController.stream,
//       builder: (context, snapshot) {
//         final diff = HabbitCalc.calculateDateDifference(
//           target: target!,
//           specificDate: HabbitCalc.memoryToStartDateTime(habbit),
//         );

//         final percentage = HabbitCalc.getPercentage(target: target!, diff: diff);
//         final remaining = getRemainingDays(diff, target!);

//         return Scaffold(
//           appBar: AppBar(
//             title: (name ?? 'No Name').text.medium.xl3.make(),
//             centerTitle: true,
//             actions: [
//               PopupMenuButton(
//                 itemBuilder: (context) {
//                   final List? pinnedHabbits = hive.get('pinnedHabbits') ?? [];
//                   return [
//                     PopupMenuItem(
//                       child: Text(pinnedHabbits!.contains(habbitId) ? "Unpin" : "Pin"),
//                       onTap: () {
//                         if (pinnedHabbits.isEmpty) {
//                           hive.put('pinnedHabbits', [habbitId]);
//                         } else {
//                           if (pinnedHabbits.contains(habbitId)) {
//                             pinnedHabbits.removeWhere((e) => e == habbitId);
//                           } else {
//                             pinnedHabbits.insert(0, habbitId);
//                           }
//                           hive.put('pinnedHabbits', pinnedHabbits);
//                         }

//                         final refresher = ref.read(habbitViewRefresherProvider);
//                         final selectedIndex = ref.read(selectedIndexProvider);
//                         if (refresher != null && selectedIndex == 0) refresher();
//                       },
//                     ),
//                     PopupMenuItem(
//                       child: const Text("Edit"),
//                       onTap: () {
//                         Habbit.createOrEditHabbit(
//                           context,
//                           ref: ref,
//                           edit: true,
//                           habbitId: habbitId,
//                           habbit: habbit,
//                         );
//                       },
//                     ),
//                     PopupMenuItem(
//                       onTap: () {
//                         Habbit.showDeleteAlert(
//                           context,
//                           habbitId: habbitId,
//                           habbit: habbit,
//                           ref: ref,
//                         );
//                       },
//                       child: const Text("Delete"),
//                     ),
//                     PopupMenuItem(
//                       onTap: () {
//                         Habbit.restartHabbit(
//                           habbitId: habbitId,
//                           ref: ref,
//                         );
//                       },
//                       child: const Text("Restart"),
//                     ),
//                   ];
//                 },
//               )
//             ],
//           ),
//           body: Column(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             crossAxisAlignment: CrossAxisAlignment.center,
//             mainAxisSize: MainAxisSize.max,
//             children: [
//               const SizedBox.shrink(),
//               Stack(
//                 alignment: Alignment.center,
//                 children: [
//                   CircularProgressIndicator(
//                     color: myColor.reverseColor,
//                     strokeWidth: 8,
//                     strokeCap: StrokeCap.round,
//                     backgroundColor: myColor.primaryLight,
//                     value: percentage / 100,
//                   ).box.square(230).make(),
//                   Row(
//                     mainAxisSize: MainAxisSize.max,
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Column(
//                         crossAxisAlignment: CrossAxisAlignment.center,
//                         children: [
//                           Row(
//                             crossAxisAlignment: CrossAxisAlignment.end,
//                             children: [
//                               (diff.inDays).text.minFontSize(52).lineHeight(0.9).bold.make(),
//                               const SizedBox(width: 5),
//                               "Days".text.sm.make(),
//                             ],
//                           ).pOnly(left: 30),
//                           Row(
//                             // crossAxisAlignment: CrossAxisAlignment.end,
//                             children: [
//                               Row(
//                                 crossAxisAlignment: CrossAxisAlignment.end,
//                                 children: [
//                                   (diff.inHours % 24).text.minFontSize(40).lineHeight(0.9).semiBold.make(),
//                                   const SizedBox(width: 5),
//                                   "Hour".text.sm.make(),
//                                 ],
//                               ),
//                               const SizedBox(width: 6),
//                               Row(
//                                 crossAxisAlignment: CrossAxisAlignment.end,
//                                 children: [
//                                   (diff.inMinutes % 60).text.minFontSize(36).lineHeight(0.9).semiBold.make(),
//                                   const SizedBox(width: 5),
//                                   "Minute".text.sm.make(),
//                                 ],
//                               ).pOnly(top: 20)
//                             ],
//                           ),
//                           const SizedBox(height: 18),
//                           Row(
//                             crossAxisAlignment: CrossAxisAlignment.end,
//                             children: [
//                               (diff.inSeconds % 60).text.minFontSize(24).lineHeight(0.9).medium.make(),
//                               const SizedBox(width: 5),
//                               "Seconds".text.sm.make(),
//                             ],
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   RemainDurUI(
//                     firstTxt: remaining.inDays.toString(),
//                     secondTxt: 'Days Remaining',
//                     color: Vx.zinc400,
//                   ).when(remaining.inDays >= 0),
//                   RemainDurUI(
//                     firstTxt: 'Completed +',
//                     secondTxt: "${remaining.inDays.abs()} Days",
//                     color: Vx.zinc400,
//                   ).when(remaining.inDays < 0),
//                 ],
//               ),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.start,
//                 children: [
//                   IconButton.filledTonal(
//                     icon: const Icon(Icons.menu),
//                     iconSize: 22,
//                     onPressed: () {
//                       showModalBottomSheet(
//                         context: context,
//                         isScrollControlled: true,
//                         builder: (context) {
//                           return Wrap(
//                             children: [
//                               Container(
//                                 clipBehavior: Clip.hardEdge,
//                                 decoration: BoxDecoration(
//                                   color: Theme.of(context).scaffoldBackgroundColor,
//                                   borderRadius: const BorderRadius.only(
//                                     topLeft: Radius.circular(10.0),
//                                     topRight: Radius.circular(10.0),
//                                   ),
//                                 ),
//                                 child: Wrap(
//                                   children: [
//                                     ListTile(
//                                       title: 'Name'.text.make(),
//                                       trailing: (name ?? '').text.make(),
//                                     ),
//                                     ListTile(
//                                       title: 'Complete in Percentage'.text.make(),
//                                       trailing: "${percentage.toStringAsFixed(2)} %".text.make(),
//                                     ),
//                                     ListTile(
//                                       title: 'Target Days'.text.make(),
//                                       trailing: (target ?? 0).text.make(),
//                                     ),
//                                     ListTile(
//                                       title: 'Complete Days'.text.make(),
//                                       trailing: "${diff.inDays}d ${diff.inHours % 24}h ${diff.inMinutes % 60}m".text.make(),
//                                     ),
//                                     ListTile(
//                                       title: 'Remaing Days'.text.make(),
//                                       trailing: "${remaining.inDays}d ${remaining.inHours % 24}h ${remaining.inMinutes % 60}m".text.make(),
//                                     ).when(remaining.inDays >= 0),
//                                     ListTile(
//                                       title: 'Remaing Days'.text.make(),
//                                       trailing: "Completed + ${remaining.inDays.abs()}d ${remaining.inHours % 24}h ${remaining.inMinutes % 60}m"
//                                           .text
//                                           .make(),
//                                     ).when(remaining.inDays < 0),
//                                   ],
//                                 ),
//                               )
//                             ],
//                           );
//                         },
//                       );
//                     },
//                   ),
//                   IconButton.filledTonal(
//                     icon: const Icon(Icons.restart_alt_outlined),
//                     onPressed: () {
//                       Habbit.restartHabbit(habbitId: habbitId, ref: ref);
//                     },
//                   ),
//                   IconButton.filledTonal(
//                     icon: const Icon(Icons.history),
//                     onPressed: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (context) => HabbitHistoryUI(
//                             habbit: habbitWithHitstory,
//                             habbitId: habbitId,
//                           ),
//                         ),
//                       );
//                     },
//                   ),
//                   IconButton.filledTonal(
//                       onPressed: () {
//                         // final hive = Hive.box('habbits');
//                         if (kDebugMode) print(Hive.box('habbits').get(habbitId));
//                       },
//                       icon: const Icon(Icons.circle))
//                 ],
//               ).p16(),
//             ],
//           ).safeArea(),
//         );
//       },
//     );
//   }
// }

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
