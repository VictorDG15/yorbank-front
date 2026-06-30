import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/primary_button.dart';

class OtpPage extends StatelessWidget {
  const OtpPage({super.key});

  @override
  Widget build(BuildContext context) {
    final code = TextEditingController(text: '123456');
    return Scaffold(
      appBar: AppBar(title: const Text('Verificación 2FA')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Confirma tu identidad', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            TextField(controller: code, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Código OTP')),
            const SizedBox(height: 24),
            PrimaryButton(label: 'Verificar', onPressed: () => context.go('/home')),
          ],
        ),
      ),
    );
  }
}
