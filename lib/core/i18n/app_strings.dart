import 'package:flutter/material.dart';

enum AppLocale { es, en }

extension AppLocaleX on AppLocale {
  String get code => name;
  String get flag => this == AppLocale.es ? '🇪🇸' : '🇺🇸';
  String get label => this == AppLocale.es ? 'ES' : 'EN';
  Locale get locale => Locale(code);
}

class AppStrings {
  final AppLocale locale;

  const AppStrings(this.locale);

  static AppStrings of(BuildContext context) {
    final locale = Localizations.localeOf(context);
    if (locale.languageCode == 'es') return const AppStrings(AppLocale.es);
    return const AppStrings(AppLocale.en);
  }

  String get appTitle => _t('CajaRápida', 'CajaRápida');

  // Navigation
  String get navSales => _t('Ventas', 'Sales');
  String get navProducts => _t('Productos', 'Products');
  String get navDailyClose => _t('Cuadre', 'Daily Close');
  String get navCounter => _t('Contador', 'Counter');

  // Sales screen
  String get salesTitle => _t('Ventas', 'Sales');
  String get noProducts => _t('No hay productos', 'No products');
  String get addFromCatalog =>
      _t('Agrega productos desde el catálogo', 'Add products from the catalog');
  String itemAdded(String name) => _t('$name +1', '$name +1');
  String get cartEmpty => _t('Carrito vacío', 'Cart is empty');
  String get confirmSale => _t('Confirmar Venta', 'Confirm Sale');
  String get totalLabel => _t('Total', 'Total');
  String get productsLabel => _t('Productos', 'Products');
  String get cancel => _t('Cancelar', 'Cancel');
  String get sell => _t('Vender', 'Sell');
  String get saleSuccess =>
      _t('Venta registrada exitosamente', 'Sale registered successfully');
  String items(int n) => _t('$n artículo(s)', '$n item(s)');
  String get checkout => _t('Cobrar', 'Checkout');
  String get cartTitle => _t('Carrito de Ventas', 'Shopping Cart');
  String get perUnit => _t('c/u', 'each');
  String get removeProduct => _t('Eliminar producto', 'Remove product');

  // Catalog screen
  String get catalogTitle => _t('Productos', 'Products');
  String get searchProduct => _t('Buscar producto...', 'Search product...');
  String noResults(String q) =>
      _t('Sin resultados para "$q"', 'No results for "$q"');
  String get tryAnother =>
      _t('Intenta con otro nombre', 'Try a different name');
  String get newProduct => _t('Nuevo Producto', 'New Product');
  String get editProduct => _t('Editar Producto', 'Edit Product');
  String get productName => _t('Nombre del producto', 'Product name');
  String get price => _t('Precio', 'Price');
  String get required => _t('Requerido', 'Required');
  String get invalidPrice => _t('Precio inválido', 'Invalid price');
  String get save => _t('Guardar', 'Save');
  String get create => _t('Crear', 'Create');
  String get deleteProduct => _t('Eliminar Producto', 'Delete Product');
  String confirmDelete(String name) =>
      _t('¿Eliminar "$name"?', 'Delete "$name"?');
  String get delete => _t('Eliminar', 'Delete');
  String deleted(String name) => _t('$name eliminado', '$name deleted');
  String restored(String name) => _t('$name restaurado', '$name restored');
  String get undo => _t('Deshacer', 'Undo');
  String get backup => _t('Respaldo', 'Backup');
  String get exportBackup => _t('Exportar respaldo', 'Export backup');
  String get exportSub => _t('Compartir archivo .db', 'Share .db file');
  String get restoreBackup => _t('Restaurar respaldo', 'Restore backup');
  String get restoreSub => _t('Seleccionar archivo .db', 'Select .db file');
  String get restoreSuccess =>
      _t('Respaldo restaurado correctamente', 'Backup restored successfully');
  String duplicateName(String name) => _t(
    'Ya existe un producto con el nombre "$name"',
    'A product named "$name" already exists',
  );

  // Daily close screen
  String get dailyCloseTitle => _t('Cuadre Diario', 'Daily Close');
  String get receiveReport => _t('Recibir Cuadre', 'Receive Report');
  String get generateQr => _t('Generar QR', 'Generate QR');
  String get exportPdf => _t('Exportar cuadre', 'Export report');
  String get noDataForDate => _t('Sin ventas para', 'No sales for');
  String get totalIncome => _t('Ingresos Totales', 'Total Income');
  String get transactions => _t('Transacciones', 'Transactions');
  String get breakdownByProduct =>
      _t('Desglose por Producto', 'Breakdown by Product');
  String get noProductData =>
      _t('No hay datos de productos', 'No product data');
  String sold(int n) => _t('$n vendido(s)', '$n sold');
  String get qrTitle => _t('Código QR del Cuadre', 'Daily Close QR Code');
  String get close => _t('Cerrar', 'Close');
  String get noDataQr =>
      _t('No hay datos para generar QR', 'No data to generate QR');
  String get errorQr => _t('Error al generar QR', 'Error generating QR');

  // Receive report screen
  String get receiveTitle => _t('Recibir Cuadre', 'Receive Report');
  String get scanQr => _t('Escanea un código QR', 'Scan a QR code');
  String get scanHint => _t(
    'Apunta la cámara hacia el código QR del cuadre',
    'Point the camera at the daily close QR code',
  );
  String get reportReceived => _t('Cuadre Recibido', 'Report Received');
  String get dateLabel => _t('Fecha', 'Date');
  String get accept => _t('Aceptar', 'Accept');
  String get errorProcessing =>
      _t('Error al procesar el código QR', 'Error processing QR code');

  // Money counter screen
  String get counterTitle => _t('Contador', 'Counter');
  String get moneyTab => _t('Dinero', 'Money');
  String get calculatorTab => _t('Calculadora', 'Calculator');
  String get totalCounted => _t('Total Contado', 'Total Counted');
  String get clear => _t('Limpiar', 'Clear');

  // Theme
  String get switchTheme => _t('Cambiar tema', 'Switch theme');

  // Language
  String get language => _t('Idioma', 'Language');

  // Calculator
  String get error => _t('Error', 'Error');

  // Generic errors
  String get errorOccurred =>
      _t('Ocurrió un error inesperado', 'An unexpected error occurred');
  String get dbLocked => _t(
    'La base de datos está ocupada. Intenta nuevamente.',
    'Database is busy. Please try again.',
  );
  String get constraintError => _t(
    'No se pudo guardar por una restricción de datos.',
    'Could not save due to a data constraint.',
  );

  String _t(String es, String en) => locale == AppLocale.es ? es : en;
}
