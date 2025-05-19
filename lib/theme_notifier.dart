import 'package:flutter/material.dart';

class ThemeNotifier extends ValueNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.light);

  void toggleTheme(bool isDarkMode) {
    value = isDarkMode ? ThemeMode.dark : ThemeMode.light;
  }
}
