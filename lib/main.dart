import 'package:flutter/material.dart';
import 'home.dart';
import 'theme_notifier.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
final themeNotifier = ThemeNotifier();

void main() async {
  await initializeDateFormatting('fr_FR', null);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentTheme, _) {
        return MaterialApp(
          title: 'Mon App Attirante',
          theme: ThemeData.light(useMaterial3: true),
          darkTheme: ThemeData.dark(useMaterial3: true),
          themeMode: currentTheme,
          home: const HomePage(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
