import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_version_provider.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Banner que aparece quando há nova versão disponível
class UpdateBanner extends ConsumerStatefulWidget {
  const UpdateBanner({super.key});

  @override
  ConsumerState<UpdateBanner> createState() => _UpdateBannerState();
}

class _UpdateBannerState extends ConsumerState<UpdateBanner> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();

    final versionCheck = ref.watch(versionCheckProvider);

    return versionCheck.when(
      data: (hasNewVersion) {
        if (!hasNewVersion) return const SizedBox.shrink();

        return MaterialBanner(
          backgroundColor: Theme.of(context).primaryColor,
          leading: const Icon(
            Icons.system_update_rounded,
            color: Colors.white,
            size: 32,
          ),
          content: const Text(
            '🎉 Nova versão disponível! Clique em "Atualizar" para obter as últimas melhorias.',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
          actions: [
            TextButton.icon(
              onPressed: () {
                // Recarregar página para pegar nova versão
                html.window.location.reload();
              },
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text(
                'ATUALIZAR AGORA',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: TextButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.2),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () {
                setState(() {
                  _dismissed = true;
                });
              },
              child: const Text(
                'Depois',
                style: TextStyle(
                  color: Colors.white70,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

/// Widget compacto para mostrar versão atual (para debug)
class VersionDisplay extends ConsumerWidget {
  final bool showInProduction;
  
  const VersionDisplay({
    super.key,
    this.showInProduction = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Só mostra em desenvolvimento ou se explicitamente solicitado
    const bool kDebugMode = bool.fromEnvironment('dart.vm.product') == false;
    if (!kDebugMode && !showInProduction) {
      return const SizedBox.shrink();
    }

    final version = ref.watch(appVersionProvider);

    return version.when(
      data: (appVersion) => Padding(
        padding: const EdgeInsets.all(8.0),
        child: Chip(
          avatar: const Icon(Icons.info_outline, size: 16),
          label: Text(
            'v${appVersion.version}',
            style: const TextStyle(fontSize: 11),
          ),
          backgroundColor: Colors.grey[200],
          visualDensity: VisualDensity.compact,
        ),
      ),
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
