import 'package:bitrec/utils/habbit.dart';
import 'package:bitrec/widgets/empty_screen_ui.dart';
import 'package:bitrec/widgets/habbit_view.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:velocity_x/velocity_x.dart';

final habbitViewRefresherProvider = StateProvider<Function?>((ref) => null);

class Home extends ConsumerStatefulWidget {
  const Home({super.key});

  @override
  ConsumerState<Home> createState() => _HomeState();
}

class _HomeState extends ConsumerState<Home> {
  final hiveBox = Hive.box('habbits');
  final PageController _pageController = PageController(initialPage: 0);
  late int pageCount;
  int currentPage = 0;

  void refreshPage() {
    setState(() {});
  }

  List getHabbitData() {
    final habbits = Habbit.getRealHabbitOrder();
    setState(() {
      pageCount = habbits.length;
    });
    return habbits;
  }

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      ref.read(habbitViewRefresherProvider.notifier).update((state) => refreshPage);
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: (value) {
              currentPage = value;
              setState(() {});
            },
            children: getHabbitData().isEmpty
                ? [const EmptyScreenUI()]
                : getHabbitData().map((id) {
                    final List habbitWithHistory = hiveBox.get(id);
                    return HabbitView(habbitWithHistory: habbitWithHistory, habbitId: id);
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
