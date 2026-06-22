import 'package:cliker/screens/home_screen.dart';
import 'package:cliker/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Root application widget.
///
/// Wires the single dark/neon [appTheme] to the [HomeScreen]. State is provided
/// by the [ProviderScope] mounted above this widget in `main`.
class ClikerApp extends StatelessWidget {
  const ClikerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'cliker',
      theme: appTheme(),
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
    );
  }
}
