import 'package:bitrec/hive/adapters/streak.dart';
import 'package:bitrec/utils/streak_methods.dart';
import 'package:bitrec/widgets/empty_screen_ui.dart';
import 'package:bitrec/widgets/streak_view.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:velocity_x/velocity_x.dart';

final streakViewRefresherProvider = StateProvider<Function?>((ref) => null);

class StreaksView extends ConsumerStatefulWidget {
  const StreaksView({super.key});

  @override
  ConsumerState<StreaksView> createState() => _StreaksViewState();
}

class _StreaksViewState extends ConsumerState<StreaksView> {
  final hiveBox = Hive.box('streaks');
  final PageController _pageController = PageController(initialPage: 0);
  late int pageCount;
  int currentPage = 0;

  void refreshPage() {
    setState(() {});
  }

  List getStreaksSequence() {
    final streaks = StreakMethods.getRealStreakOrder();
    setState(() {
      pageCount = streaks.length;
    });
    return streaks;
  }

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      ref.read(streakViewRefresherProvider.notifier).update((state) => refreshPage);
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.small(
        // shape: const CircleBorder(),
        backgroundColor: Colors.cyan.shade900,
        child: const Icon(Icons.add),
        onPressed: () {
          StreakMethods.createOrEditStreak(context, ref: ref);
        },
      ),
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: (value) {
              currentPage = value;
              setState(() {});
            },
            children: getStreaksSequence().isEmpty
                ? [const EmptyScreenUI()]
                : getStreaksSequence().map((id) {
                    final Streak streak = hiveBox.get(id);
                    return StreakView(streak);
                  }).toList(),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(pageCount, (index) {
              final bool isSelected = index == currentPage;
              return AnimatedContainer(
                curve: Curves.linear,
                duration: const Duration(milliseconds: 200),
                height: 10,
                width: isSelected ? 20 : 10,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.red : Colors.white,
                  borderRadius: BorderRadius.circular(50),
                ),
              ).pSymmetric(h: 3);
            }),
          ).box.width(context.mq.size.width).make().when(pageCount > 1).positioned(bottom: 18),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
