import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/i18n/app_strings.dart';
import '../../providers/locale_provider.dart';

class LanguageToggle extends ConsumerWidget {
  const LanguageToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLocale = ref.watch(localeProvider);
    final theme = Theme.of(context);

    return PopupMenuButton<AppLocale>(
      tooltip: AppStrings.of(context).language,
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(appLocale.flag, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(
              appLocale.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ],
        ),
      ),
      itemBuilder: (context) => AppLocale.values.map((locale) {
        final isActive = locale == appLocale;
        return PopupMenuItem<AppLocale>(
          value: locale,
          child: Row(
            children: [
              Text(locale.flag, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 12),
              Text(
                locale.label,
                style: TextStyle(
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  color: isActive ? theme.colorScheme.primary : null,
                ),
              ),
              const Spacer(),
              if (isActive)
                Icon(
                  Icons.check_circle_rounded,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
            ],
          ),
        );
      }).toList(),
      onSelected: (locale) {
        ref.read(localeProvider.notifier).setLocale(locale);
      },
    );
  }
}
