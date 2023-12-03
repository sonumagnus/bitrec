import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

StreamController<int> useRefreshController({Duration duration = const Duration(minutes: 1)}) {
  return use(_UiRefreshController(duration: duration));
}

class _UiRefreshController extends Hook<StreamController<int>> {
  const _UiRefreshController({required this.duration});

  final Duration duration;

  @override
  _UiRefreshControllerState createState() => _UiRefreshControllerState();
}

class _UiRefreshControllerState extends HookState<StreamController<int>, _UiRefreshController> {
  late StreamController<int> _refreshController;
  late Timer _timer;
  int _counter = 0;

  @override
  void initHook() {
    super.initHook();
    // Initialize the StreamController
    _refreshController = StreamController<int>();

    // Set up a periodic timer to refresh every minute
    _timer = Timer.periodic(hook.duration, (_) {
      // Add an event to the stream to trigger the refresh
      _refreshController.add(_counter++);
    });
  }

  @override
  void dispose() {
    // Cancel the timer and close the stream when the widget is disposed
    _timer.cancel();
    _refreshController.close();
    super.dispose();
  }

  @override
  StreamController<int> build(BuildContext context) => _refreshController;
}
