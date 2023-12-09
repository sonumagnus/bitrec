import 'package:bitrec/hive/adapters/attempt.dart';
import 'package:bitrec/hive/adapters/streak.dart';
import 'package:bitrec/hive/adapters/session.dart';
import 'package:bitrec/hive/adapters/task.dart';
import 'package:bitrec/screens/bottom_navbar.dart';
import 'package:bitrec/themes/theme_contant.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(StreakAdapter());
  Hive.registerAdapter(AttemptAdapter());
  Hive.registerAdapter(TaskAdapter());
  Hive.registerAdapter(SessionAdapter());
  await Hive.openBox('streaks');
  await Hive.openBox('tasks');
  await Hive.openBox('rex');
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends HookConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BitRec',
      theme: ThemeConstatnt.light,
      darkTheme: ThemeConstatnt.dark,
      themeMode: ThemeMode.dark,
      home: const BottomNavbar(),
    );
  }
}
