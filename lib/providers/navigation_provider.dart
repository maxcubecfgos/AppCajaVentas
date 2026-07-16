import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider that tracks the currently selected screen index
/// Shared between HomeScreen and AppDrawer for navigation
final selectedScreenIndexProvider = StateProvider<int>((ref) => 0);

/// Provider that tracks the currently selected tab inside MoneyCounterScreen
/// 0 = Dinero, 1 = Calculadora
final moneyCounterTabIndexProvider = StateProvider<int>((ref) => 0);
