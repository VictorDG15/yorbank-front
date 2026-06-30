import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/http/api_client.dart';
import '../../../core/widgets/main_bottom_nav.dart';
import '../../../core/widgets/yb_card.dart';
import '../../home/data/banking_api.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(homeSummaryProvider);
    final data = summary.valueOrNull;
    final name = data?.customerName ?? 'Cliente';

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      bottomNavigationBar: const MainBottomNav(currentIndex: 3),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
        children: [
          YBCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: AppColors.primarySoft,
                child: Text(
                  _initials(name),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              title: Text(
                name,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              subtitle: Text(
                data == null
                    ? 'Cargando datos'
                    : '${data.accountLabel} - ${data.accountTail}',
              ),
            ),
          ),
          const SizedBox(height: 12),
          ListTile(
            title: const Text('Seguridad'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/security'),
          ),
          ListTile(
            title: const Text('Centro de ayuda'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            title: const Text('Cerrar sesion'),
            trailing: const Icon(Icons.logout),
            onTap: () async {
              await ref.read(tokenStorageProvider).clear();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
    );
  }

  String _initials(String value) {
    final parts = value.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'CL';
    final first = parts.first[0];
    final second = parts.length > 1 && parts[1].isNotEmpty ? parts[1][0] : '';
    return (first + second).toUpperCase();
  }
}
