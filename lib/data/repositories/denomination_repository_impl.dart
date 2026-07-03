import '../../domain/models/currency_type.dart';
import '../../domain/models/denomination.dart';
import '../../domain/repositories/denomination_repository.dart';
import '../datasources/local_storage_datasource.dart';

class DenominationRepositoryImpl implements DenominationRepository {
  final LocalStorageDatasource _datasource;

  DenominationRepositoryImpl(this._datasource);

  @override
  Future<List<Denomination>> getDenominations() {
    return _datasource.loadDenominations();
  }

  @override
  Future<void> saveDenominations(List<Denomination> denominations) {
    return _datasource.saveDenominations(denominations);
  }

  @override
  Future<CurrencyType> getCurrencyType() {
    return _datasource.loadCurrencyType();
  }

  @override
  Future<void> saveCurrencyType(CurrencyType currencyType) {
    return _datasource.saveCurrencyType(currencyType);
  }
}
