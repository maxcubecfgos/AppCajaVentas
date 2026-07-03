import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/currency_type.dart';
import '../../domain/models/denomination.dart';
import '../../providers/repository_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late List<Denomination> _denominations;
  late CurrencyType _selectedCurrency;
  bool _isLoading = true;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final repository = ref.read(denominationRepositoryProvider);
    final denominations = await repository.getDenominations();
    final currency = await repository.getCurrencyType();

    if (mounted) {
      setState(() {
        _denominations = List.from(denominations);
        _selectedCurrency = currency;
        _isLoading = false;
      });
    }
  }

  void _addDenomination() {
    setState(() {
      _denominations.add(const Denomination(value: 0, label: ''));
      _hasChanges = true;
    });
  }

  void _removeDenomination(int index) {
    if (_denominations.length <= 1) return;
    setState(() {
      _denominations.removeAt(index);
      _hasChanges = true;
    });
  }

  void _updateDenominationValue(int index, double value) {
    setState(() {
      _denominations[index] = _denominations[index].copyWith(value: value);
      _hasChanges = true;
    });
  }

  void _updateDenominationLabel(int index, String label) {
    setState(() {
      _denominations[index] = _denominations[index].copyWith(label: label);
      _hasChanges = true;
    });
  }

  Future<void> _saveSettings() async {
    // Filtrar denominaciones inválidas (value <= 0)
    final validDenominations = _denominations.where((d) => d.value > 0).toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    if (validDenominations.isEmpty) return;

    final repository = ref.read(denominationRepositoryProvider);
    await repository.saveDenominations(validDenominations);
    await repository.saveCurrencyType(_selectedCurrency);

    if (mounted) {
      setState(() => _hasChanges = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Configuración guardada'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Ajustes')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes'),
        actions: [
          if (_hasChanges)
            TextButton.icon(
              onPressed: _saveSettings,
              icon: const Icon(Icons.save_rounded),
              label: const Text('Guardar'),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Sección: Moneda
          _buildSectionTitle(theme, 'Moneda'),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<CurrencyType>(
                  value: _selectedCurrency,
                  isExpanded: true,
                  items: CurrencyType.values.map((currency) {
                    return DropdownMenuItem(
                      value: currency,
                      child: Text(
                        '${currency.symbol} - ${currency.name}',
                        style: theme.textTheme.bodyLarge,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedCurrency = value;
                        _hasChanges = true;
                      });
                    }
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Sección: Denominaciones
          _buildSectionTitle(theme, 'Denominaciones'),
          const SizedBox(height: 8),
          ..._denominations.asMap().entries.map((entry) {
            final index = entry.key;
            final denom = entry.value;
            return _buildDenominationCard(theme, index, denom);
          }),
          const SizedBox(height: 12),

          // Botón agregar
          Center(
            child: TextButton.icon(
              onPressed: _addDenomination,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Agregar denominación'),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title.toUpperCase(),
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildDenominationCard(
    ThemeData theme,
    int index,
    Denomination denom,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            // Label
            Expanded(
              flex: 2,
              child: TextField(
                controller: TextEditingController(text: denom.label)
                  ..selection = TextSelection.collapsed(
                    offset: denom.label.length,
                  ),
                decoration: const InputDecoration(
                  labelText: 'Etiqueta',
                  isDense: true,
                ),
                style: theme.textTheme.bodyLarge,
                onChanged: (value) => _updateDenominationLabel(index, value),
              ),
            ),
            const SizedBox(width: 12),
            // Value
            Expanded(
              flex: 2,
              child: TextField(
                controller: TextEditingController(
                  text: denom.value > 0 ? denom.value.toStringAsFixed(0) : '',
                ),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Valor',
                  prefixText: '\$ ',
                  isDense: true,
                ),
                style: theme.textTheme.bodyLarge,
                onChanged: (value) {
                  final parsed = double.tryParse(value);
                  if (parsed != null) {
                    _updateDenominationValue(index, parsed);
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            // Delete button
            IconButton(
              icon: Icon(
                Icons.remove_circle_outline_rounded,
                color: theme.colorScheme.error,
              ),
              onPressed: () => _removeDenomination(index),
              tooltip: 'Eliminar',
            ),
          ],
        ),
      ),
    );
  }
}
