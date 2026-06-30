import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/main_bottom_nav.dart';
import '../../../core/widgets/yb_card.dart';
import '../../home/data/banking_api.dart';
import '../../home/domain/account_summary.dart';
import '../../home/domain/home_summary.dart';

class OperationsPage extends ConsumerWidget {
  const OperationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(homeSummaryProvider);
    final accounts = ref.watch(accountSummariesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Operaciones')),
      bottomNavigationBar: const MainBottomNav(currentIndex: 1),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(homeSummaryProvider);
          ref.invalidate(accountSummariesProvider);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            summary.when(
              data: (data) => _RealCard(summary: data),
              loading: () => const _LoadingPanel(),
              error: (error, _) => _ErrorPanel(
                message: error.toString(),
                onRetry: () => ref.invalidate(homeSummaryProvider),
              ),
            ),
            const SizedBox(height: 18),
            _OperationGrid(
              onTransfer: () => context.go('/transfers/new'),
              onServices: () => context.push('/payments/services'),
              onYape: () => context.push('/payments/yape'),
              onRecharges: () => context.push('/payments/recharges'),
              onCards: () => context.push('/cards'),
              onLoans: () => context.push('/loans'),
              onAccount: () => context.push('/accounts/detail'),
            ),
            const SizedBox(height: 18),
            accounts.when(
              data: (items) => _AccountsPanel(accounts: items),
              loading: () => const _LoadingPanel(),
              error: (error, _) => _ErrorPanel(
                message: error.toString(),
                onRetry: () => ref.invalidate(accountSummariesProvider),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RealCard extends StatelessWidget {
  final HomeSummary summary;

  const _RealCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDeep],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            summary.customerName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            summary.formattedBalance,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${summary.accountLabel} - ${summary.accountTail}',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 4),
          Text(
            '${summary.cardType} ${summary.maskedCard}',
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _OperationGrid extends StatelessWidget {
  final VoidCallback onTransfer;
  final VoidCallback onServices;
  final VoidCallback onYape;
  final VoidCallback onRecharges;
  final VoidCallback onCards;
  final VoidCallback onLoans;
  final VoidCallback onAccount;

  const _OperationGrid({
    required this.onTransfer,
    required this.onServices,
    required this.onYape,
    required this.onRecharges,
    required this.onCards,
    required this.onLoans,
    required this.onAccount,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.55,
      children: [
        _OperationTile(
          icon: Icons.swap_horiz_rounded,
          label: 'Transferir',
          onTap: onTransfer,
        ),
        _OperationTile(
          icon: Icons.receipt_long_rounded,
          label: 'Servicios',
          onTap: onServices,
        ),
        _OperationTile(
          icon: Icons.send_to_mobile_rounded,
          label: 'Yape',
          onTap: onYape,
        ),
        _OperationTile(
          icon: Icons.phone_android_rounded,
          label: 'Recargas',
          onTap: onRecharges,
        ),
        _OperationTile(
          icon: Icons.credit_card_rounded,
          label: 'Tarjetas',
          onTap: onCards,
        ),
        _OperationTile(
          icon: Icons.account_balance_wallet_rounded,
          label: 'Mis cuentas',
          onTap: onAccount,
        ),
        _OperationTile(
          icon: Icons.trending_up_rounded,
          label: 'Prestamos',
          onTap: onLoans,
        ),
      ],
    );
  }
}

class _OperationTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _OperationTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: YBCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.text,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountsPanel extends StatelessWidget {
  final List<AccountSummary> accounts;

  const _AccountsPanel({required this.accounts});

  @override
  Widget build(BuildContext context) {
    return YBCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cuentas',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          if (accounts.isEmpty)
            const Text(
              'No hay cuentas activas.',
              style: TextStyle(color: AppColors.textMuted),
            )
          else
            ...accounts.map(
              (account) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(account.number),
                subtitle: Text(account.currency),
                trailing: Text(
                  account.balance.toStringAsFixed(2),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LoadingPanel extends StatelessWidget {
  const _LoadingPanel();

  @override
  Widget build(BuildContext context) {
    return const YBCard(
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorPanel({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return YBCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'No se pudo cargar la informacion',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.textMuted),
          ),
          const SizedBox(height: 8),
          TextButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}
