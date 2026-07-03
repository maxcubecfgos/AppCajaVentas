import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/models/count_entry.dart';

class DenominationRow extends StatelessWidget {
  final CountEntry entry;
  final int index;
  final ValueChanged<int> onQuantityChanged;

  const DenominationRow({
    super.key,
    required this.entry,
    required this.index,
    required this.onQuantityChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtotal = entry.subtotal;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Denominación
              SizedBox(
                width: 80,
                child: Text(
                  '\$${entry.denomination.label}',
                  style: theme.textTheme.titleLarge,
                ),
              ),
              const SizedBox(width: 12),
              // Campo de cantidad
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: TextField(
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium,
                    decoration: InputDecoration(
                      hintText: '0',
                      hintStyle: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade400,
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                    ),
                    onChanged: (value) {
                      final qty = int.tryParse(value) ?? 0;
                      onQuantityChanged(qty);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Subtotal con animación
              AnimatedOpacity(
                duration: const Duration(milliseconds: 150),
                opacity: subtotal > 0 ? 1.0 : 0.4,
                child: SizedBox(
                  width: 100,
                  child: Text(
                    _formatSubtotal(subtotal),
                    textAlign: TextAlign.right,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: subtotal > 0
                          ? theme.colorScheme.primary
                          : theme.textTheme.bodyMedium?.color,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatSubtotal(double value) {
    if (value == 0) return '\$0.00';
    return '\$${value.toStringAsFixed(2)}';
  }
}
