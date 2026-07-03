import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'presentation/screens/counting_screen.dart';
import 'presentation/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: MoneyCounterApp()));
}

class MoneyCounterApp extends StatelessWidget {
  const MoneyCounterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Money Counter',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const CountingScreen(),
    );
  }
}
