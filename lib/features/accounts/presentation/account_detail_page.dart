import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/main_bottom_nav.dart';
import '../../../core/widgets/yb_card.dart';
import '../../home/data/banking_api.dart';
import '../../home/domain/account_summary.dart';

class AccountDetailPage extends ConsumerWidget {
  const AccountDetailPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(accountSummariesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mis cuentas')),
      bottomNavigationBar: const MainBottomNav(currentIndex: 1),
      body: accounts.when(
        data: (items) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
          children: [
            if (items.isEmpty)
              const YBCard(
                child: Text(
                  'No hay cuentas activas.',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              )
            else
              ...items.map((account) => _AccountCard(account: account)),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
          children: [
            YBCard(
              child: Text(
                error.toString(),
                style: const TextStyle(color: AppColors.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  final AccountSummary account;

  const _AccountCard({required this.account});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: YBCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cuenta',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            Text(account.number),
            const SizedBox(height: 8),
            Text('Moneda: ${account.currency}'),
            Text('Saldo disponible: ${account.balance.toStringAsFixed(2)}'),
          ],
        ),
      ),
    );
  }
}
