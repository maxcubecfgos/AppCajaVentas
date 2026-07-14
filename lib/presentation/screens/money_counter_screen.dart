import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/i18n/app_strings.dart';
import '../../core/utils/currency_formatter.dart';
import '../widgets/app_drawer.dart';
import 'calculator_screen.dart';

class MoneyCounterScreen extends ConsumerStatefulWidget {
  const MoneyCounterScreen({super.key});

  @override
  ConsumerState<MoneyCounterScreen> createState() => _MoneyCounterScreenState();
}

class _MoneyCounterScreenState extends ConsumerState<MoneyCounterScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final Map<double, TextEditingController> _controllers = {};
  double _total = 0;

  static const List<_Denomination> _denominations = [
    _Denomination(value: 5000, label: '\$5,000'),
    _Denomination(value: 2000, label: '\$2,000'),
    _Denomination(value: 1000, label: '\$1,000'),
    _Denomination(value: 500, label: '\$500'),
    _Denomination(value: 200, label: '\$200'),
    _Denomination(value: 100, label: '\$100'),
    _Denomination(value: 50, label: '\$50'),
    _Denomination(value: 20, label: '\$20'),
    _Denomination(value: 10, label: '\$10'),
    _Denomination(value: 5, label: '\$5'),
    _Denomination(value: 3, label: '\$3'),
    _Denomination(value: 1, label: '\$1'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    for (final d in _denominations) {
      _controllers[d.value] = TextEditingController();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _calculateTotal() {
    double total = 0;
    for (final d in _denominations) {
      final text = _controllers[d.value]?.text ?? '';
      final qty = int.tryParse(text) ?? 0;
      total += d.value * qty;
    }
    setState(() => _total = total);
  }

  void _clearAll() {
    for (final c in _controllers.values) {
      c.clear();
    }
    setState(() => _total = 0);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: Text(strings.counterTitle),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: const Icon(Icons.monetization_on),
              text: strings.moneyTab,
            ),
            Tab(icon: const Icon(Icons.calculate), text: strings.calculatorTab),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _clearAll,
            tooltip: strings.clear,
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMoneyCounter(theme, strings),
          const CalculatorScreen(),
        ],
      ),
    );
  }

  Widget _buildMoneyCounter(ThemeData theme, AppStrings strings) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          color: theme.colorScheme.primaryContainer,
          child: Column(
            children: [
              Text(
                strings.totalCounted,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                CurrencyFormatter.format(_total),
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: _denominations.length,
            itemBuilder: (context, index) {
              final d = _denominations[index];
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 80,
                      child: Text(
                        d.label,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _controllers[d.value],
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: '0',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                        onChanged: (_) => _calculateTotal(),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 80,
                      child: Text(
                        CurrencyFormatter.format(
                          d.value *
                              (int.tryParse(
                                    _controllers[d.value]?.text ?? '0',
                                  ) ??
                                  0),
                        ),
                        textAlign: TextAlign.right,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _Denomination {
  final double value;
  final String label;

  const _Denomination({required this.value, required this.label});
}
