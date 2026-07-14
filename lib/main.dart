import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'presentation/theme/app_theme.dart';
import 'presentation/screens/pos_screen.dart';
import 'presentation/screens/catalog_screen.dart';
import 'presentation/screens/daily_close_screen.dart';
import 'presentation/screens/money_counter_screen.dart';
import 'providers/theme_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/navigation_provider.dart';
import 'core/i18n/app_strings.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final themeNotifier = ThemeModeNotifier();
  await themeNotifier.load();
  final localeNotifier = LocaleNotifier();
  await localeNotifier.load();
  runApp(
    ProviderScope(
      overrides: [
        themeModeProvider.overrideWith((ref) => themeNotifier),
        localeProvider.overrideWith((ref) => localeNotifier),
      ],
      child: const MicroPOSApp(),
    ),
  );
}

class MicroPOSApp extends ConsumerWidget {
  const MicroPOSApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final appLocale = ref.watch(localeProvider);
    return MaterialApp(
      title: 'Gestion Caja',
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
      locale: appLocale.locale,
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final selectedIndex = ref.watch(selectedScreenIndexProvider);

    final screens = [
      const PosScreen(),
      const CatalogScreen(),
      const DailyCloseScreen(),
      const MoneyCounterScreen(),
    ];

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Column(
          children: [
            Expanded(
              child: IndexedStack(index: selectedIndex, children: screens),
            ),
            NavigationBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: (index) {
                ref.read(selectedScreenIndexProvider.notifier).state = index;
              },
              destinations: [
                NavigationDestination(
                  selectedIcon: const Icon(Icons.point_of_sale),
                  icon: const Icon(Icons.point_of_sale_outlined),
                  label: strings.navSales,
                ),
                NavigationDestination(
                  selectedIcon: const Icon(Icons.inventory_2),
                  icon: const Icon(Icons.inventory_2_outlined),
                  label: strings.navProducts,
                ),
                NavigationDestination(
                  selectedIcon: const Icon(Icons.receipt_long),
                  icon: const Icon(Icons.receipt_long_outlined),
                  label: strings.navDailyClose,
                ),
                NavigationDestination(
                  selectedIcon: const Icon(Icons.account_balance_wallet),
                  icon: const Icon(Icons.account_balance_wallet_outlined),
                  label: strings.navCounter,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
