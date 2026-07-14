import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider that tracks the currently selected screen index
/// Shared between HomeScreen and AppDrawer for navigation
final selectedScreenIndexProvider = StateProvider<int>((ref) => 0);
