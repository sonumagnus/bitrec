import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:velocity_x/velocity_x.dart';

class EmptyScreenUI extends StatelessWidget {
  const EmptyScreenUI({
    super.key,
    this.text = 'Click + Button to Add New Streak',
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      alignment: Alignment.center,
      width: context.mq.size.width,
      child: DefaultTextStyle(
        style: const TextStyle(
          fontSize: 30.0,
          fontFamily: 'Agne',
        ),
        child: AnimatedTextKit(
          animatedTexts: [
            TypewriterAnimatedText(
              text,
              textStyle: const TextStyle(fontSize: 20),
            ),
          ],
        ),
      ),
    ).centered();
  }
}
