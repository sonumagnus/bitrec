import 'package:bitrec/themes/my_colors.dart';
import 'package:flutter/material.dart';

class ThemeConstatnt {
  static final light = ThemeData(
    extensions: <ThemeExtension<dynamic>>{MyColors.light},
    brightness: Brightness.light,
    useMaterial3: true,
  );
  static final dark = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,

    // scaffoldBackgroundColor: _primaryColor,
    extensions: <ThemeExtension<dynamic>>{MyColors.dark},
    // floatingActionButtonTheme: const FloatingActionButtonThemeData(backgroundColor: _primaryColor),
    // appBarTheme: const AppBarTheme(backgroundColor: _primaryColor),
    // navigationBarTheme: const NavigationBarThemeData(backgroundColor: _primaryColor),
  );
}
