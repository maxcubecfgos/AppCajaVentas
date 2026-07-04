import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'presentation/theme/app_theme.dart';
import 'presentation/screens/pos_screen.dart';
import 'presentation/screens/catalog_screen.dart';
import 'presentation/screens/daily_close_screen.dart';
import 'presentation/screens/money_counter_screen.dart';
import 'presentation/screens/receive_report_screen.dart';

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.light);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: MicroPOSApp()));
}

class MicroPOSApp extends ConsumerWidget {
  const MicroPOSApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp(
      title: 'MicroPOS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _screens = [
    PosScreen(),
    CatalogScreen(),
    DailyCloseScreen(),
    MoneyCounterScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MicroPOS'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'Recibir Cuadre',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ReceiveReportScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(
              Theme.of(context).brightness == Brightness.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            tooltip: 'Cambiar tema',
            onPressed: () {
              final current = Theme.of(context).brightness;
              final newMode = current == Brightness.dark
                  ? ThemeMode.light
                  : ThemeMode.dark;
              ref.read(themeModeProvider.notifier).state = newMode;
            },
          ),
        ],
      ),
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: const [
          NavigationDestination(
            selectedIcon: Icon(Icons.point_of_sale),
            icon: Icon(Icons.point_of_sale_outlined),
            label: 'Ventas',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.inventory_2),
            icon: Icon(Icons.inventory_2_outlined),
            label: 'Productos',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.receipt_long),
            icon: Icon(Icons.receipt_long_outlined),
            label: 'Cuadre',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.account_balance_wallet),
            icon: Icon(Icons.account_balance_wallet_outlined),
            label: 'Contador',
          ),
        ],
      ),
    );
  }
}
