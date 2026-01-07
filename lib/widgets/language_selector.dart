import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../providers/localization_provider.dart';
import '../services/localization_service.dart';

class LanguageSelector extends ConsumerWidget {
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLanguage = ref.watch(currentLanguageProvider);
    final languageOptions = ref.watch(languageOptionsProvider);

    return PopupMenuButton<String>(
      icon: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.language, size: 20),
          const SizedBox(width: 4),
          Text(
            LocalizationService.getLanguageName(currentLanguage),
            style: const TextStyle(fontSize: 14),
          ),
          const Icon(Icons.arrow_drop_down, size: 16),
        ],
      ),
      onSelected: (String languageCode) {
        ref.read(currentLanguageProvider.notifier).setLanguage(context, languageCode);
      },
      itemBuilder: (BuildContext context) {
        return languageOptions.map((language) {
          final isSelected = language['code'] == currentLanguage;
          return PopupMenuItem<String>(
            value: language['code']!,
            child: Row(
              children: [
                if (isSelected)
                  Icon(Icons.check, size: 16, color: Theme.of(context).primaryColor),
                SizedBox(width: isSelected ? 8 : 24),
                Text(
                  language['name']!,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Theme.of(context).primaryColor : null,
                  ),
                ),
              ],
            ),
          );
        }).toList();
      },
    );
  }
}

class LanguageSelectorCard extends ConsumerWidget {
  const LanguageSelectorCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLanguage = ref.watch(currentLanguageProvider);
    final languageOptions = ref.watch(languageOptionsProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.language, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'settings.language'.tr(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...languageOptions.map((language) {
              final isSelected = language['code'] == currentLanguage;
              return RadioListTile<String>(
                title: Text(language['name']!),
                value: language['code']!,
                toggleable: false,
                onChanged: (String? value) {
                  if (value != null) {
                    ref.read(currentLanguageProvider.notifier).setLanguage(context, value);
                  }
                },
                selected: language['code'] == currentLanguage,
                activeColor: Theme.of(context).primaryColor,
                contentPadding: EdgeInsets.zero,
              );
            }),
          ],
        ),
      ),
    );
  }
}

class LanguageSelectorDialog extends ConsumerWidget {
  const LanguageSelectorDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLanguage = ref.watch(currentLanguageProvider);
    final languageOptions = ref.watch(languageOptionsProvider);

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.language, color: Theme.of(context).primaryColor),
          const SizedBox(width: 8),
          Text('settings.language'.tr()),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: languageOptions.map((language) {
          final isSelected = language['code'] == currentLanguage;
          return ListTile(
            leading: Radio<String>(
              value: language['code']!,
              toggleable: false,
              onChanged: (String? value) {
                if (value != null) {
                  ref.read(currentLanguageProvider.notifier).setLanguage(context, value);
                }
              },
              activeColor: Theme.of(context).primaryColor,
            ),
            title: Text(
              language['name']!,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Theme.of(context).primaryColor : null,
              ),
            ),
            onTap: () {
              ref.read(currentLanguageProvider.notifier).setLanguage(context, language['code']!);
            },
          );
        }).toList(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('common.close'.tr()),
        ),
      ],
    );
  }
}

// Widget para mostrar o idioma atual
class CurrentLanguageDisplay extends ConsumerWidget {
  const CurrentLanguageDisplay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLanguage = ref.watch(currentLanguageProvider);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.language, size: 16),
        const SizedBox(width: 4),
        Text(
          LocalizationService.getLanguageName(currentLanguage),
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}

// Widget para mostrar bandeira do idioma (se disponível)
class LanguageFlag extends StatelessWidget {
  final String languageCode;
  final double size;

  const LanguageFlag({
    super.key,
    required this.languageCode,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    String flag;
    switch (languageCode) {
      case 'en':
        flag = '🇺🇸';
        break;
      case 'pt':
        flag = '🇧🇷';
        break;
      case 'es':
        flag = '🇪🇸';
        break;
      default:
        flag = '🌐';
    }

    return Text(
      flag,
      style: TextStyle(fontSize: size),
    );
  }
} 
