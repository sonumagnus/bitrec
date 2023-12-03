import 'package:flutter/material.dart';
import 'package:velocity_x/velocity_x.dart';

class MyColors extends ThemeExtension<MyColors> {
  final Color? primaryLight, reverseColor, secondaryLight;
  MyColors({this.primaryLight, this.reverseColor, this.secondaryLight});

  @override
  ThemeExtension<MyColors> copyWith({
    Color? primaryLight,
    Color? reverseColor,
    Color? secondaryLight,
  }) =>
      MyColors(
        primaryLight: primaryLight ?? this.primaryLight,
        reverseColor: reverseColor ?? this.reverseColor,
        secondaryLight: secondaryLight ?? this.secondaryLight,
      );

  @override
  ThemeExtension<MyColors> lerp(covariant ThemeExtension<MyColors>? other, double t) {
    if (other is! MyColors) {
      return this;
    }

    return MyColors(
      primaryLight: Color.lerp(primaryLight, other.primaryLight, t),
      reverseColor: Color.lerp(reverseColor, other.reverseColor, t),
      secondaryLight: Color.lerp(secondaryLight, other.secondaryLight, t),
    );
  }

  static final light = MyColors(
    primaryLight: Vx.zinc200,
    reverseColor: Vx.zinc900,
    secondaryLight: Vx.zinc300,
  );
  static final dark = MyColors(
    primaryLight: Vx.zinc800,
    reverseColor: Vx.zinc100,
    secondaryLight: Vx.zinc900,
  );
}
