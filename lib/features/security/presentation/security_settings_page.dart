import 'package:flutter/material.dart';
import '../../../core/widgets/yb_card.dart';

class SecuritySettingsPage extends StatelessWidget {
  const SecuritySettingsPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Seguridad')),
        body: ListView(padding: const EdgeInsets.all(20), children: const [
          YBCard(child: SwitchListTile(value: true, onChanged: null, title: Text('Biometría'), subtitle: Text('Huella o Face ID'))),
          YBCard(child: SwitchListTile(value: true, onChanged: null, title: Text('Verificación 2FA'), subtitle: Text('OTP para operaciones sensibles'))),
          YBCard(child: ListTile(title: Text('Tiempo de sesión'), subtitle: Text('Cierre automático tras inactividad'))),
        ]),
      );
}
