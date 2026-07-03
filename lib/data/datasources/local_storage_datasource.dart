import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/currency_type.dart';
import '../../domain/models/denomination.dart';

class LocalStorageDatasource {
  static const _denominationsKey = 'money_counter_denominations';
  static const _currencyKey = 'money_counter_currency';

  Future<List<Denomination>> loadDenominations() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_denominationsKey);
    if (jsonString == null) return _defaultDenominations();

    try {
      final List<dynamic> jsonList = json.decode(jsonString) as List<dynamic>;
      return jsonList
          .map((e) => Denomination.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return _defaultDenominations();
    }
  }

  Future<void> saveDenominations(List<Denomination> denominations) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(
      denominations.map((d) => d.toJson()).toList(),
    );
    await prefs.setString(_denominationsKey, jsonString);
  }

  Future<CurrencyType> loadCurrencyType() async {
    final prefs = await SharedPreferences.getInstance();
    final currencyCode = prefs.getString(_currencyKey);
    if (currencyCode == null) return CurrencyType.usd;

    return CurrencyType.values.firstWhere(
      (c) => c.name == currencyCode,
      orElse: () => CurrencyType.usd,
    );
  }

  Future<void> saveCurrencyType(CurrencyType currencyType) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currencyKey, currencyType.name);
  }

  List<Denomination> _defaultDenominations() {
    return const [
      Denomination(value: 1, label: '1'),
      Denomination(value: 5, label: '5'),
      Denomination(value: 10, label: '10'),
      Denomination(value: 20, label: '20'),
      Denomination(value: 50, label: '50'),
      Denomination(value: 100, label: '100'),
      Denomination(value: 200, label: '200'),
      Denomination(value: 500, label: '500'),
    ];
  }
}
