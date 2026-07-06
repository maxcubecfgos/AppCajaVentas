import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'presentation/theme/app_theme.dart';
import 'presentation/screens/pos_screen.dart';
import 'presentation/screens/catalog_screen.dart';
import 'presentation/screens/daily_close_screen.dart';
import 'presentation/screens/money_counter_screen.dart';
import 'providers/theme_provider.dart';

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
      title: 'CajaRápida',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('es', 'ES'), Locale('en', 'US')],
      locale: const Locale('es', 'ES'),
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
    return PopScope(
      canPop: false,
      child: Column(
        children: [
          Expanded(
            child: IndexedStack(index: _selectedIndex, children: _screens),
          ),
          NavigationBar(
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
        ],
      ),
    );
  }
}
