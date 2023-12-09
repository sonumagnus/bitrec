import 'package:bitrec/screens/home.dart';
import 'package:bitrec/screens/streak_screen.dart';
import 'package:bitrec/screens/task_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final selectedIndexProvider = StateProvider<int>((ref) => 0);

class BottomNavbar extends HookConsumerWidget {
  const BottomNavbar({super.key});

  static final List<Widget> _screens = [
    const Home(),
    const StreaksView(),
    const TaskScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = useState<int>(0);
    final pageController = usePageController(initialPage: 0);

    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        pageController.jumpToPage(selectedIndex.value);
        ref.read(selectedIndexProvider.notifier).update((state) => selectedIndex.value);
      });
      return null;
    }, [selectedIndex.value]);

    return Scaffold(
      body: PageView(
        pageSnapping: false,
        physics: const NeverScrollableScrollPhysics(),
        controller: pageController,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (i) => selectedIndex.value = i,
        selectedIndex: selectedIndex.value,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: "Home"),
          NavigationDestination(icon: Icon(Icons.list), label: "Streaks"),
          NavigationDestination(icon: Icon(Icons.task_alt), label: "Tasks"),
        ],
      ),
    );
  }
}
