import 'package:flutter/material.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String _display = '0';
  String _expression = '';
  double? _lastValue;
  String? _lastOperator;
  bool _isNewNumber = true;

  void _onDigitPressed(String digit) {
    setState(() {
      if (_isNewNumber) {
        _display = digit;
        _isNewNumber = false;
      } else {
        _display = _display == '0' ? digit : _display + digit;
      }
    });
  }

  void _onDecimalPressed() {
    setState(() {
      if (_isNewNumber) {
        _display = '0.';
        _isNewNumber = false;
      } else if (!_display.contains('.')) {
        _display += '.';
      }
    });
  }

  void _onOperatorPressed(String operator) {
    setState(() {
      final current = double.tryParse(_display) ?? 0;
      if (_lastOperator != null && !_isNewNumber) {
        _performCalculation();
      } else {
        _lastValue = current;
      }
      _lastOperator = operator;
      _expression = '${_formatNumber(_lastValue!)} $operator';
      _isNewNumber = true;
    });
  }

  void _performCalculation() {
    final current = double.tryParse(_display) ?? 0;
    switch (_lastOperator) {
      case '+':
        _lastValue = (_lastValue ?? 0) + current;
        break;
      case '-':
        _lastValue = (_lastValue ?? 0) - current;
        break;
      case '×':
        _lastValue = (_lastValue ?? 0) * current;
        break;
      case '÷':
        if (current == 0) {
          _display = 'Error';
          _isNewNumber = true;
          return;
        }
        _lastValue = (_lastValue ?? 0) / current;
        break;
    }
    _display = _formatNumber(_lastValue!);
  }

  void _onEqualsPressed() {
    setState(() {
      if (_lastOperator != null) {
        _expression = '$_expression $_display =';
        _performCalculation();
        _lastOperator = null;
        _isNewNumber = true;
      }
    });
  }

  void _onClearPressed() {
    setState(() {
      _display = '0';
      _expression = '';
      _lastValue = null;
      _lastOperator = null;
      _isNewNumber = true;
    });
  }

  void _onDeletePressed() {
    setState(() {
      if (_display.length > 1) {
        _display = _display.substring(0, _display.length - 1);
      } else {
        _display = '0';
        _isNewNumber = true;
      }
    });
  }

  void _onPercentagePressed() {
    setState(() {
      final value = double.tryParse(_display) ?? 0;
      _display = _formatNumber(value / 100);
      _isNewNumber = true;
    });
  }

  void _onSignPressed() {
    setState(() {
      if (_display != '0' && _display != 'Error') {
        if (_display.startsWith('-')) {
          _display = _display.substring(1);
        } else {
          _display = '-$_display';
        }
      }
    });
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        // Display
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _expression,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                _display,
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        // Button grid
        Expanded(
          child: GridView.count(
            crossAxisCount: 4,
            padding: const EdgeInsets.all(8),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.3,
            children: [
              _CalcButton(
                label: 'AC',
                color: isDark ? const Color(0xFF44474E) : Colors.grey.shade300,
                textColor: isDark ? Colors.white : Colors.black,
                onPressed: _onClearPressed,
              ),
              _CalcButton(
                label: 'C',
                color: isDark ? const Color(0xFF44474E) : Colors.grey.shade300,
                textColor: isDark ? Colors.white : Colors.black,
                onPressed: _onDeletePressed,
              ),
              _CalcButton(
                label: '%',
                color: isDark ? const Color(0xFF44474E) : Colors.grey.shade300,
                textColor: isDark ? Colors.white : Colors.black,
                onPressed: _onPercentagePressed,
              ),
              _CalcButton(
                label: '÷',
                color: theme.colorScheme.primary,
                textColor: theme.colorScheme.onPrimary,
                onPressed: () => _onOperatorPressed('÷'),
              ),
              _CalcButton(
                label: '7',
                color: isDark ? const Color(0xFF1A1F2E) : Colors.white,
                textColor: isDark ? Colors.white : Colors.black,
                onPressed: () => _onDigitPressed('7'),
              ),
              _CalcButton(
                label: '8',
                color: isDark ? const Color(0xFF1A1F2E) : Colors.white,
                textColor: isDark ? Colors.white : Colors.black,
                onPressed: () => _onDigitPressed('8'),
              ),
              _CalcButton(
                label: '9',
                color: isDark ? const Color(0xFF1A1F2E) : Colors.white,
                textColor: isDark ? Colors.white : Colors.black,
                onPressed: () => _onDigitPressed('9'),
              ),
              _CalcButton(
                label: '×',
                color: theme.colorScheme.primary,
                textColor: theme.colorScheme.onPrimary,
                onPressed: () => _onOperatorPressed('×'),
              ),
              _CalcButton(
                label: '4',
                color: isDark ? const Color(0xFF1A1F2E) : Colors.white,
                textColor: isDark ? Colors.white : Colors.black,
                onPressed: () => _onDigitPressed('4'),
              ),
              _CalcButton(
                label: '5',
                color: isDark ? const Color(0xFF1A1F2E) : Colors.white,
                textColor: isDark ? Colors.white : Colors.black,
                onPressed: () => _onDigitPressed('5'),
              ),
              _CalcButton(
                label: '6',
                color: isDark ? const Color(0xFF1A1F2E) : Colors.white,
                textColor: isDark ? Colors.white : Colors.black,
                onPressed: () => _onDigitPressed('6'),
              ),
              _CalcButton(
                label: '-',
                color: theme.colorScheme.primary,
                textColor: theme.colorScheme.onPrimary,
                onPressed: () => _onOperatorPressed('-'),
              ),
              _CalcButton(
                label: '1',
                color: isDark ? const Color(0xFF1A1F2E) : Colors.white,
                textColor: isDark ? Colors.white : Colors.black,
                onPressed: () => _onDigitPressed('1'),
              ),
              _CalcButton(
                label: '2',
                color: isDark ? const Color(0xFF1A1F2E) : Colors.white,
                textColor: isDark ? Colors.white : Colors.black,
                onPressed: () => _onDigitPressed('2'),
              ),
              _CalcButton(
                label: '3',
                color: isDark ? const Color(0xFF1A1F2E) : Colors.white,
                textColor: isDark ? Colors.white : Colors.black,
                onPressed: () => _onDigitPressed('3'),
              ),
              _CalcButton(
                label: '+',
                color: theme.colorScheme.primary,
                textColor: theme.colorScheme.onPrimary,
                onPressed: () => _onOperatorPressed('+'),
              ),
              _CalcButton(
                label: '+/-',
                color: isDark ? const Color(0xFF44474E) : Colors.grey.shade300,
                textColor: isDark ? Colors.white : Colors.black,
                onPressed: _onSignPressed,
              ),
              _CalcButton(
                label: '0',
                color: isDark ? const Color(0xFF1A1F2E) : Colors.white,
                textColor: isDark ? Colors.white : Colors.black,
                onPressed: () => _onDigitPressed('0'),
              ),
              _CalcButton(
                label: '.',
                color: isDark ? const Color(0xFF1A1F2E) : Colors.white,
                textColor: isDark ? Colors.white : Colors.black,
                onPressed: _onDecimalPressed,
              ),
              _CalcButton(
                label: '=',
                color: theme.colorScheme.secondary,
                textColor: theme.colorScheme.onSecondary,
                onPressed: _onEqualsPressed,
                isLarge: false,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CalcButton extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;
  final VoidCallback onPressed;
  final bool isLarge;

  const _CalcButton({
    required this.label,
    required this.color,
    required this.textColor,
    required this.onPressed,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onPressed,
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
