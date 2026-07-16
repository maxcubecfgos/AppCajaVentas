import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/i18n/app_strings.dart';
import '../../providers/navigation_provider.dart';
import '../../providers/theme_provider.dart';
import '../screens/receive_report_screen.dart';
import 'language_toggle.dart';

class AppDrawer extends ConsumerStatefulWidget {
  const AppDrawer({super.key});

  @override
  ConsumerState<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends ConsumerState<AppDrawer> {
  // Llave del PopupMenuButton de idioma para poder abrirlo
  // programáticamente desde el `onTap` de la fila completa.
  final GlobalKey<PopupMenuButtonState<AppLocale>> _languageMenuKey =
      GlobalKey<PopupMenuButtonState<AppLocale>>();

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final selectedIndex = ref.watch(selectedScreenIndexProvider);

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.75,
      child: SafeArea(
        child: Column(
          children: [
            // ── Header ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.store_rounded,
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    strings.appTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            // ── Settings (arriba para que sean visibles) ──
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SectionHeader(text: strings.drawerSettings),
                  _SettingsTile(
                    icon: Icons.language_rounded,
                    label: strings.language,
                    // Cualquier punto de la fila abre el menú.
                    onTap: () =>
                        _languageMenuKey.currentState?.showButtonMenu(),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        LanguageToggle(menuKey: _languageMenuKey),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.expand_more_rounded,
                          size: 18,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                  _SettingsTile(
                    icon: theme.brightness == Brightness.dark
                        ? Icons.light_mode_rounded
                        : Icons.dark_mode_rounded,
                    label: strings.switchTheme,
                    onTap: () {
                      final current = theme.brightness;
                      final newMode = current == Brightness.dark
                          ? ThemeMode.light
                          : ThemeMode.dark;
                      ref.read(themeModeProvider.notifier).setMode(newMode);
                      Navigator.pop(context);
                    },
                  ),
                  const SizedBox(height: 4),
                ],
              ),
            ),
            const Divider(),
            // ── Navigation ────────────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 4),
                children: [
                  _SectionHeader(text: strings.drawerMain),
                  _NavItem(
                    icon: Icons.point_of_sale_rounded,
                    label: strings.drawerSales,
                    index: 0,
                    selectedIndex: selectedIndex,
                    onTap: () => _navigateTo(context, 0),
                  ),
                  _NavItem(
                    icon: Icons.inventory_2_rounded,
                    label: strings.drawerProducts,
                    index: 1,
                    selectedIndex: selectedIndex,
                    onTap: () => _navigateTo(context, 1),
                  ),
                  _NavItem(
                    icon: Icons.receipt_long_rounded,
                    label: strings.drawerDailyClose,
                    index: 2,
                    selectedIndex: selectedIndex,
                    onTap: () => _navigateTo(context, 2),
                  ),
                  _NavItem(
                    icon: Icons.account_balance_wallet_rounded,
                    label: strings.drawerCounter,
                    index: 3,
                    selectedIndex: selectedIndex,
                    onTap: () => _navigateTo(context, 3),
                  ),
                  _SectionHeader(text: strings.drawerTools),
                  _NavItem(
                    icon: Icons.qr_code_scanner_rounded,
                    label: strings.drawerReceiveReport,
                    index: null,
                    selectedIndex: selectedIndex,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ReceiveReportScreen(),
                        ),
                      );
                    },
                  ),
                  _NavItem(
                    icon: Icons.calculate_rounded,
                    label: strings.calculatorShort,
                    index: null,
                    selectedIndex: selectedIndex,
                    onTap: () {
                      ref.read(selectedScreenIndexProvider.notifier).state = 3;
                      ref.read(moneyCounterTabIndexProvider.notifier).state = 1;
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateTo(BuildContext context, int index) {
    ref.read(selectedScreenIndexProvider.notifier).state = index;
    Navigator.pop(context);
  }
}

// ─── Section Header ─────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String text;

  const _SectionHeader({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 6),
      child: Text(
        text,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

// ─── Nav Item ────────────────────────────────────────────────────
class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int? index;
  final int selectedIndex;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSelected = index != null && index == selectedIndex;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected
                  ? theme.colorScheme.primary.withValues(alpha: 0.1)
                  : null,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: 22,
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      label,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  if (isSelected)
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Settings Tile ───────────────────────────────────────────────
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _SettingsTile({
    required this.icon,
    required this.label,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            if (trailing != null) trailing!,
            if (onTap != null && trailing == null)
              Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.onSurfaceVariant,
                size: 18,
              ),
          ],
        ),
      ),
    );
  }
}
