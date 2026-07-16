import 'package:flutter/material.dart';

/// Helper para mostrar SnackBars con estilo consistente en toda la app.
///
/// Por defecto usa `colorScheme.inverseSurface` como fondo y el color "on"
/// correspondiente como color de texto, de modo que el SnackBar **no se
/// camufle** con botones primarios (ej: "Cobrar" en la pantalla de ventas).
///
/// Acepta un `extraMargin` opcional para que pantallas con UI adicional
/// sobre el `bottomNavigationBar` (ej: `_CartSummaryBar` con el botón
/// "Cobrar") puedan empujar el SnackBar hacia arriba y evitar solapes
/// verticales con esos elementos.
class SnackBarHelper {
  SnackBarHelper._();

  /// Separación mínima sobre el `bottomNavigationBar` (NavigationBar
  /// clásico de Material 3).
  static const double _baseClearance = 16;

  static EdgeInsets _floatingMargin(BuildContext context, double extraMargin) {
    final safeInset = MediaQuery.of(context).padding.bottom;
    return EdgeInsets.fromLTRB(
      16,
      0,
      16,
      _baseClearance + safeInset + extraMargin,
    );
  }

  /// Devuelve el color "on..." apropiado para un color de fondo del theme.
  static Color _onColorFor(ColorScheme scheme, Color bg) {
    if (bg == scheme.inverseSurface) return scheme.onInverseSurface;
    if (bg == scheme.error) return scheme.onError;
    if (bg == scheme.tertiary) return scheme.onTertiary;
    if (bg == scheme.primary) return scheme.onPrimary;
    if (bg == scheme.secondary) return scheme.onSecondary;
    return Colors.white;
  }

  /// Muestra un SnackBar con estilo neutro de sistema.
  ///
  /// Si no se indica `backgroundColor`, usa `colorScheme.inverseSurface`
  /// para no chocar visualmente con los botones primarios.
  ///
  /// [extraMargin] añade píxeles extra al margen inferior, útil cuando
  /// la pantalla tiene UI adicional sobre el `bottomNavigationBar` que
  /// debe quedar descubierta por el SnackBar.
  static void show(
    BuildContext context,
    String message, {
    Color? backgroundColor,
    SnackBarAction? action,
    Duration? duration,
    double extraMargin = 0,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    final scheme = Theme.of(context).colorScheme;

    final effectiveBg = backgroundColor ?? scheme.inverseSurface;
    final effectiveFg = _onColorFor(scheme, effectiveBg);

    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: TextStyle(fontSize: 13, color: effectiveFg),
          ),
          backgroundColor: effectiveBg,
          action: action,
          duration: duration ?? const Duration(milliseconds: 3500),
          behavior: SnackBarBehavior.floating,
          margin: _floatingMargin(context, extraMargin),
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 10,
          ),
        ),
      );
  }

  /// Mensaje de error (rojo del tema).
  static void showError(
    BuildContext context,
    String message, {
    double extraMargin = 0,
  }) {
    show(
      context,
      message,
      backgroundColor: Theme.of(context).colorScheme.error,
      duration: const Duration(seconds: 3),
      extraMargin: extraMargin,
    );
  }

  /// Mensaje de advertencia (terciario).
  static void showWarning(
    BuildContext context,
    String message, {
    double extraMargin = 0,
  }) {
    show(
      context,
      message,
      backgroundColor: Theme.of(context).colorScheme.tertiary,
      extraMargin: extraMargin,
    );
  }

  /// Mensaje informativo breve (para confirmaciones rápidas de UI, ej: "+1").
  static void showBrief(
    BuildContext context,
    String message, {
    double extraMargin = 0,
  }) {
    show(
      context,
      message,
      duration: const Duration(milliseconds: 800),
      extraMargin: extraMargin,
    );
  }
}
