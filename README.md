# CajaRápida

Punto de Venta offline-first para pequeños negocios. Registra ventas, administra productos, realiza cuadres diarios y cuenta dinero en efectivo — todo sin conexión a internet.

## Características

- **Ventas rápidas**: Agrega productos al carrito con un toque y registra la venta en un solo paso.
- **Catálogo de productos**: Crea, edita y elimina productos con validación de duplicados y búsqueda instantánea.
- **Cuadre diario**: Visualiza ingresos, transacciones y desglose por producto del día. Genera QR y exporta a PDF.
- **Recibir cuadres**: Escanea códigos QR de cuadres diarios para importar reportes.
- **Contador de dinero**: Suma billetes y monedas con denominaciones configurables.
- **Tema claro/oscuro**: Interfaz adaptable con paleta profesional azul noche + terracota.
- **Respaldo y restauración**: Exporta e importa la base de datos completa.
- **Offline-first**: Funciona sin internet. Los datos se guardan localmente con SQLite.

## Arquitectura

- **UI**: Flutter + Material 3
- **Estado**: Riverpod
- **Persistencia**: SQLite (sqflite)
- **Internacionalización**: flutter_localizations (español por defecto)

## Estructura del proyecto

lib/
├── main.dart
├── core/
│   ├── database/
│   │   └── app_database.dart
│   └── utils/
│       ├── currency_formatter.dart
│       ├── daily_report_helper.dart
│       ├── qr_report_helper.dart
│       └── backup_helper.dart
├── data/
│   └── datasources/
│       └── pos_database_datasource.dart
├── domain/
│   └── models/
│       ├── product.dart
│       ├── transaction.dart
│       ├── daily_summary.dart
│       └── received_report.dart
├── presentation/
│   ├── theme/
│   │   └── app_theme.dart
│   └── screens/
│       ├── pos_screen.dart
│       ├── catalog_screen.dart
│       ├── daily_close_screen.dart
│       ├── money_counter_screen.dart
│       └── receive_report_screen.dart
└── providers/
    ├── theme_provider.dart
    ├── database_provider.dart
    ├── product_providers.dart
    ├── transaction_providers.dart
    └── daily_summary_providers.dart

## Requisitos

- Flutter 3.x
- Dart 3.x
- Android SDK 34+
- AGP 8.11.1+

## Instalación

flutter pub get
flutter run

## Build de release

flutter build apk --release
