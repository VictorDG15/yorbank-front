import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/main_bottom_nav.dart';
import '../../../core/widgets/yb_card.dart';
import '../data/banking_api.dart';
import '../domain/account_movement.dart';
import '../domain/home_summary.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(homeSummaryProvider);
    final movements = ref.watch(accountMovementsProvider);
    final currentSummary = summary.valueOrNull;

    void showOptions(String title, List<_HomeShortcutOption> options) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.white,
        barrierColor: Colors.black54,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        builder: (_) => _HomeOptionsSheet(title: title, options: options),
      );
    }

    final onContact = () => showOptions('Contacto YORBANK', [
      const _HomeShortcutOption(Icons.phone_rounded, 'Llamar al 311-9898'),
      const _HomeShortcutOption(
        Icons.chat_bubble_outline_rounded,
        'Chat en linea',
      ),
      const _HomeShortcutOption(
        Icons.phone_android_rounded,
        'WhatsApp YordBank',
      ),
    ]);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6FA),
        bottomNavigationBar: const MainBottomNav(currentIndex: 0),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  _HomeHeader(
                    userName: currentSummary?.firstName ?? 'Cliente',
                    onHelp: onContact,
                    onNotifications: () => context.push('/notifications'),
                    onMenu: () => context.push('/profile'),
                  ),
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: -80,
                    child: summary.when(
                      data: (data) => _BalanceSummaryCard(summary: data),
                      loading: () => const _BalanceLoadingCard(),
                      error: (error, _) => _BalanceErrorCard(
                        message: error.toString(),
                        onRetry: () => ref.invalidate(homeSummaryProvider),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 82),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 96),
                child: Column(
                  children: [
                    _HomeShortcutCard(
                      onYape: () => showOptions('Yape', [
                        const _HomeShortcutOption(
                          Icons.send_rounded,
                          'Enviar dinero con Yape',
                        ),
                        const _HomeShortcutOption(
                          Icons.history_rounded,
                          'Ver movimientos Yape',
                        ),
                      ]),
                      onQR: () => showOptions('Pagar con QR', [
                        const _HomeShortcutOption(
                          Icons.qr_code_scanner_rounded,
                          'Escanear codigo QR',
                        ),
                        const _HomeShortcutOption(
                          Icons.qr_code_rounded,
                          'Mostrar mi QR de cobro',
                        ),
                      ]),
                      onAgencies: () => showOptions('Agencias y cajeros', [
                        const _HomeShortcutOption(
                          Icons.account_balance_rounded,
                          'Agencias YORBANK',
                        ),
                        const _HomeShortcutOption(
                          Icons.local_atm_rounded,
                          'Cajeros automaticos',
                        ),
                        const _HomeShortcutOption(
                          Icons.store_rounded,
                          'Agentes YORBANK',
                        ),
                      ]),
                      onContact: onContact,
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        _Action(
                          icon: Icons.swap_horiz,
                          label: 'Transferir',
                          onTap: () => context.push('/transfers/new'),
                        ),
                        const SizedBox(width: 10),
                        _Action(
                          icon: Icons.credit_card,
                          label: 'Tarjetas',
                          onTap: () => context.push('/cards'),
                        ),
                        const SizedBox(width: 10),
                        _Action(
                          icon: Icons.trending_up,
                          label: 'Prestamo',
                          onTap: () => context.push('/loans'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    movements.when(
                      data: (items) => _MovementsPanel(movements: items),
                      loading: () => const _MovementsLoadingPanel(),
                      error: (error, _) => _MovementsErrorPanel(
                        message: error.toString(),
                        onRetry: () => ref.invalidate(accountMovementsProvider),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  final String userName;
  final VoidCallback onHelp;
  final VoidCallback onNotifications;
  final VoidCallback onMenu;

  const _HomeHeader({
    required this.userName,
    required this.onHelp,
    required this.onNotifications,
    required this.onMenu,
  });

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, topPadding + 16, 20, 92),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.navy, AppColors.blue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Hola,',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  userName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          _HeaderIconButton(icon: Icons.headset_mic_outlined, onTap: onHelp),
          const SizedBox(width: 8),
          _HeaderIconButton(
            icon: Icons.notifications_none_rounded,
            onTap: onNotifications,
            showDot: true,
          ),
          const SizedBox(width: 8),
          _HeaderIconButton(icon: Icons.menu_rounded, onTap: onMenu),
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool showDot;

  const _HeaderIconButton({
    required this.icon,
    required this.onTap,
    this.showDot = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.14),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 22),
            if (showDot)
              Positioned(
                top: 9,
                right: 9,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF5C5C),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.navy, width: 1.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BalanceSummaryCard extends StatefulWidget {
  final HomeSummary summary;

  const _BalanceSummaryCard({required this.summary});

  @override
  State<_BalanceSummaryCard> createState() => _BalanceSummaryCardState();
}

class _BalanceSummaryCardState extends State<_BalanceSummaryCard> {
  bool _hidden = false;

  @override
  Widget build(BuildContext context) {
    final summary = widget.summary;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.blue, AppColors.navy],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withOpacity(0.28),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Saldo disponible',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              InkWell(
                onTap: () => setState(() => _hidden = !_hidden),
                borderRadius: BorderRadius.circular(20),
                child: Icon(
                  _hidden
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: Colors.white70,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _hidden
                ? '${summary.moneySymbol} ******'
                : summary.formattedBalance,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${summary.accountLabel} - ${summary.accountTail}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${summary.cardType} ${summary.maskedCard}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _BalanceLoadingCard extends StatelessWidget {
  const _BalanceLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 158,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.blue, AppColors.navy],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const CircularProgressIndicator(color: Colors.white),
    );
  }
}

class _BalanceErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _BalanceErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryDeep,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'No se pudo cargar tu saldo',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}

class _HomeShortcutCard extends StatelessWidget {
  final VoidCallback onYape;
  final VoidCallback onQR;
  final VoidCallback onAgencies;
  final VoidCallback onContact;

  const _HomeShortcutCard({
    required this.onYape,
    required this.onQR,
    required this.onAgencies,
    required this.onContact,
  });

  @override
  Widget build(BuildContext context) {
    return YBCard(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: _HomeShortcutItem(
              icon: Icons.account_balance_wallet_outlined,
              label: 'Yape',
              onTap: onYape,
            ),
          ),
          Expanded(
            child: _HomeShortcutItem(
              icon: Icons.qr_code_scanner_rounded,
              label: 'Pagar QR',
              onTap: onQR,
            ),
          ),
          Expanded(
            child: _HomeShortcutItem(
              icon: Icons.location_on_outlined,
              label: 'Agencias',
              onTap: onAgencies,
            ),
          ),
          Expanded(
            child: _HomeShortcutItem(
              icon: Icons.headset_mic_outlined,
              label: 'Contacto',
              onTap: onContact,
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeShortcutItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _HomeShortcutItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: const Color(0xFFEDEAFF),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, color: AppColors.blue, size: 30),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.blue,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: YBCard(
          child: Column(
            children: [
              Icon(icon),
              const SizedBox(height: 8),
              Text(label, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

class _MovementsPanel extends StatelessWidget {
  final List<AccountMovement> movements;

  const _MovementsPanel({required this.movements});

  @override
  Widget build(BuildContext context) {
    return YBCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Movimientos recientes',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          const SizedBox(height: 12),
          if (movements.isEmpty)
            const Text(
              'Aun no hay movimientos recientes para mostrar.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            )
          else
            ...movements.take(5).map(_Movement.new),
        ],
      ),
    );
  }
}

class _Movement extends StatelessWidget {
  const _Movement(this.movement);

  final AccountMovement movement;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: movement.isCredit
              ? const Color(0xFFE7F8EE)
              : const Color(0xFFFFEEF0),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          movement.isCredit
              ? Icons.arrow_downward_rounded
              : Icons.arrow_upward_rounded,
          color: movement.isCredit
              ? const Color(0xFF11985B)
              : const Color(0xFFD23F57),
          size: 20,
        ),
      ),
      title: Text(
        movement.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: movement.description.isEmpty
          ? null
          : Text(
              movement.description,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
      trailing: Text(
        movement.formattedAmount,
        style: TextStyle(
          color: movement.isCredit
              ? const Color(0xFF11985B)
              : const Color(0xFFD23F57),
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _MovementsLoadingPanel extends StatelessWidget {
  const _MovementsLoadingPanel();

  @override
  Widget build(BuildContext context) {
    return const YBCard(
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(14),
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}

class _MovementsErrorPanel extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _MovementsErrorPanel({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return YBCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'No se pudo cargar movimientos',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 8),
          TextButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}

class _HomeShortcutOption {
  final IconData icon;
  final String label;

  const _HomeShortcutOption(this.icon, this.label);
}

class _HomeOptionsSheet extends StatelessWidget {
  final String title;
  final List<_HomeShortcutOption> options;

  const _HomeOptionsSheet({required this.title, required this.options});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF162B4D),
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),
          ...options.map(
            (option) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF3FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(option.icon, color: AppColors.blue, size: 22),
              ),
              title: Text(
                option.label,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF162B4D),
                  fontSize: 14,
                ),
              ),
              trailing: const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF61708C),
              ),
              onTap: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: Color(0xFFD7DEE9)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Cancelar',
                style: TextStyle(
                  color: AppColors.blue,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
