import '../models/denomination.dart';
import '../models/currency_type.dart';

abstract class DenominationRepository {
  Future<List<Denomination>> getDenominations();
  Future<void> saveDenominations(List<Denomination> denominations);
  Future<CurrencyType> getCurrencyType();
  Future<void> saveCurrencyType(CurrencyType currencyType);
}
