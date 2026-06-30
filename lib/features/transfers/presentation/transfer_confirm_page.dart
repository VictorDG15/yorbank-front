import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/main_bottom_nav.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/yb_card.dart';

class TransferConfirmPage extends StatelessWidget {
  const TransferConfirmPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Confirmar transferencia')),
        bottomNavigationBar: const MainBottomNav(currentIndex: 2),
        body: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 96),
          child: Column(
            children: [
              const YBCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Revision pendiente',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text('Verifica los datos ingresados antes de confirmar.'),
                  ],
                ),
              ),
              const Spacer(),
              PrimaryButton(
                label: 'Confirmar',
                onPressed: () => context.go('/home'),
              ),
            ],
          ),
        ),
      );
}
