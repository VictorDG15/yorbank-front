import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/main_bottom_nav.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/yb_card.dart';
import '../../home/data/banking_api.dart';
import '../../home/domain/account_summary.dart';
import '../../home/domain/banking_catalog.dart';

class ServicePaymentPage extends ConsumerStatefulWidget {
  const ServicePaymentPage({super.key});

  @override
  ConsumerState<ServicePaymentPage> createState() => _ServicePaymentPageState();
}

class _ServicePaymentPageState extends ConsumerState<ServicePaymentPage> {
  final _amountController = TextEditingController();
  String? _accountNumber;
  String? _serviceCode;
  bool _loading = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(accountSummariesProvider);
    final services = ref.watch(serviceBillsProvider);
    final account = _selectedAccount(accounts.valueOrNull ?? []);
    final service = _selectedService(services.valueOrNull ?? []);

    return _OperationScaffold(
      title: 'Pago de servicios',
      children: [
        _AccountsAsyncDropdown(
          accounts: accounts,
          selectedAccount: account,
          onChanged: _loading
              ? null
              : (value) => setState(() => _accountNumber = value),
        ),
        const SizedBox(height: 14),
        services.when(
          data: (items) => DropdownButtonFormField<String>(
            value: service?.code,
            decoration: const InputDecoration(labelText: 'Servicio'),
            onChanged: _loading
                ? null
                : (value) => setState(() => _serviceCode = value),
            items: items
                .map(
                  (item) => DropdownMenuItem(
                    value: item.code,
                    child: Text('${item.provider} - ${item.title}'),
                  ),
                )
                .toList(),
          ),
          loading: () => const LinearProgressIndicator(),
          error: (error, _) => _ErrorCard(message: error.toString()),
        ),
        const SizedBox(height: 14),
        _AmountField(controller: _amountController, enabled: !_loading),
        const SizedBox(height: 24),
        PrimaryButton(
          label: 'Pagar',
          loading: _loading,
          onPressed: account == null || service == null
              ? null
              : () => _submit(account, service),
        ),
      ],
    );
  }

  AccountSummary? _selectedAccount(List<AccountSummary> accounts) {
    if (accounts.isEmpty) return null;
    final selected = _accountNumber;
    if (selected == null) return accounts.first;
    return accounts.firstWhere(
      (account) => account.number == selected,
      orElse: () => accounts.first,
    );
  }

  ServiceBill? _selectedService(List<ServiceBill> services) {
    if (services.isEmpty) return null;
    final selected = _serviceCode;
    if (selected == null) return services.first;
    return services.firstWhere(
      (service) => service.code == selected,
      orElse: () => services.first,
    );
  }

  Future<void> _submit(AccountSummary account, ServiceBill service) async {
    final amount =
        double.tryParse(_amountController.text.trim().replaceAll(',', '.'));
    if (amount == null || amount <= 0) {
      _showMessage(context, 'Ingresa un monto valido');
      return;
    }
    setState(() => _loading = true);
    try {
      final receipt = await ref.read(bankingApiProvider).payService(
            accountNumber: account.number,
            serviceCode: service.code,
            amount: amount,
          );
      _refreshBankingData(ref);
      if (!mounted) return;
      _showMessage(context, 'Pago ${receipt.status}: ${receipt.operationId}');
      context.go('/home');
    } on DioException catch (error) {
      _showMessage(context, _messageFromDio(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

class YapePaymentPage extends ConsumerStatefulWidget {
  const YapePaymentPage({super.key});

  @override
  ConsumerState<YapePaymentPage> createState() => _YapePaymentPageState();
}

class _YapePaymentPageState extends ConsumerState<YapePaymentPage> {
  final _phoneController = TextEditingController();
  final _amountController = TextEditingController();
  String? _accountNumber;
  bool _loading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(accountSummariesProvider);
    final contacts = ref.watch(yapeContactsProvider);
    final account = _selectedAccount(accounts.valueOrNull ?? []);

    return _OperationScaffold(
      title: 'Yape',
      children: [
        _AccountsAsyncDropdown(
          accounts: accounts,
          selectedAccount: account,
          onChanged: _loading
              ? null
              : (value) => setState(() => _accountNumber = value),
        ),
        const SizedBox(height: 14),
        contacts.when(
          data: (items) => _ContactsPanel(
            contacts: items,
            onTap: _loading
                ? null
                : (contact) => setState(() {
                      _phoneController.text = contact.phone;
                    }),
          ),
          loading: () => const LinearProgressIndicator(),
          error: (error, _) => _ErrorCard(message: error.toString()),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _phoneController,
          enabled: !_loading,
          keyboardType: TextInputType.phone,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(labelText: 'Celular'),
        ),
        const SizedBox(height: 14),
        _AmountField(controller: _amountController, enabled: !_loading),
        const SizedBox(height: 24),
        PrimaryButton(
          label: 'Enviar Yape',
          loading: _loading,
          onPressed: account == null ? null : () => _submit(account),
        ),
      ],
    );
  }

  AccountSummary? _selectedAccount(List<AccountSummary> accounts) {
    if (accounts.isEmpty) return null;
    final selected = _accountNumber;
    if (selected == null) return accounts.first;
    return accounts.firstWhere(
      (account) => account.number == selected,
      orElse: () => accounts.first,
    );
  }

  Future<void> _submit(AccountSummary account) async {
    final amount =
        double.tryParse(_amountController.text.trim().replaceAll(',', '.'));
    final phone = _phoneController.text.trim();
    if (phone.length < 9 || amount == null || amount <= 0) {
      _showMessage(context, 'Completa celular y monto valido');
      return;
    }
    setState(() => _loading = true);
    try {
      final receipt = await ref.read(bankingApiProvider).payYape(
            originAccount: account.number,
            phone: phone,
            amount: amount,
          );
      _refreshBankingData(ref);
      if (!mounted) return;
      _showMessage(context, 'Yape ${receipt.status}: ${receipt.operationId}');
      context.go('/home');
    } on DioException catch (error) {
      _showMessage(context, _messageFromDio(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

class MobileRechargePage extends ConsumerStatefulWidget {
  const MobileRechargePage({super.key});

  @override
  ConsumerState<MobileRechargePage> createState() => _MobileRechargePageState();
}

class _MobileRechargePageState extends ConsumerState<MobileRechargePage> {
  final _phoneController = TextEditingController();
  final _amountController = TextEditingController();
  String? _accountNumber;
  String? _operatorCode;
  bool _loading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(accountSummariesProvider);
    final operators = ref.watch(mobileOperatorsProvider);
    final account = _selectedAccount(accounts.valueOrNull ?? []);
    final operator = _selectedOperator(operators.valueOrNull ?? []);

    return _OperationScaffold(
      title: 'Recargas',
      children: [
        _AccountsAsyncDropdown(
          accounts: accounts,
          selectedAccount: account,
          onChanged: _loading
              ? null
              : (value) => setState(() => _accountNumber = value),
        ),
        const SizedBox(height: 14),
        operators.when(
          data: (items) => DropdownButtonFormField<String>(
            value: operator?.code,
            decoration: const InputDecoration(labelText: 'Operador'),
            onChanged: _loading
                ? null
                : (value) => setState(() => _operatorCode = value),
            items: items
                .map(
                  (item) => DropdownMenuItem(
                    value: item.code,
                    child: Text(item.name),
                  ),
                )
                .toList(),
          ),
          loading: () => const LinearProgressIndicator(),
          error: (error, _) => _ErrorCard(message: error.toString()),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _phoneController,
          enabled: !_loading,
          keyboardType: TextInputType.phone,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(labelText: 'Celular'),
        ),
        const SizedBox(height: 14),
        _AmountField(controller: _amountController, enabled: !_loading),
        const SizedBox(height: 24),
        PrimaryButton(
          label: 'Recargar',
          loading: _loading,
          onPressed: account == null || operator == null
              ? null
              : () => _submit(account, operator),
        ),
      ],
    );
  }

  AccountSummary? _selectedAccount(List<AccountSummary> accounts) {
    if (accounts.isEmpty) return null;
    final selected = _accountNumber;
    if (selected == null) return accounts.first;
    return accounts.firstWhere(
      (account) => account.number == selected,
      orElse: () => accounts.first,
    );
  }

  MobileOperator? _selectedOperator(List<MobileOperator> operators) {
    if (operators.isEmpty) return null;
    final selected = _operatorCode;
    if (selected == null) return operators.first;
    return operators.firstWhere(
      (operator) => operator.code == selected,
      orElse: () => operators.first,
    );
  }

  Future<void> _submit(AccountSummary account, MobileOperator operator) async {
    final amount =
        double.tryParse(_amountController.text.trim().replaceAll(',', '.'));
    final phone = _phoneController.text.trim();
    if (phone.length < 9 || amount == null || amount <= 0) {
      _showMessage(context, 'Completa celular y monto valido');
      return;
    }
    setState(() => _loading = true);
    try {
      final receipt = await ref.read(bankingApiProvider).rechargeMobile(
            originAccount: account.number,
            operatorCode: operator.code,
            phone: phone,
            amount: amount,
          );
      _refreshBankingData(ref);
      if (!mounted) return;
      _showMessage(context, 'Recarga ${receipt.status}: ${receipt.operationId}');
      context.go('/home');
    } on DioException catch (error) {
      _showMessage(context, _messageFromDio(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

class _OperationScaffold extends StatelessWidget {
  const _OperationScaffold({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      bottomNavigationBar: const MainBottomNav(currentIndex: 1),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 96),
        children: children,
      ),
    );
  }
}

class _AccountsAsyncDropdown extends StatelessWidget {
  const _AccountsAsyncDropdown({
    required this.accounts,
    required this.selectedAccount,
    required this.onChanged,
  });

  final AsyncValue<List<AccountSummary>> accounts;
  final AccountSummary? selectedAccount;
  final ValueChanged<String?>? onChanged;

  @override
  Widget build(BuildContext context) {
    return accounts.when(
      data: (items) {
        if (items.isEmpty) return const _ErrorCard(message: 'No hay cuentas');
        return DropdownButtonFormField<String>(
          value: selectedAccount?.number,
          decoration: const InputDecoration(labelText: 'Cuenta origen'),
          onChanged: onChanged,
          items: items
              .map(
                (account) => DropdownMenuItem(
                  value: account.number,
                  child: Text(
                    '${account.accountTail} - ${account.formattedBalance}',
                  ),
                ),
              )
              .toList(),
        );
      },
      loading: () => const LinearProgressIndicator(),
      error: (error, _) => _ErrorCard(message: error.toString()),
    );
  }
}

class _ContactsPanel extends StatelessWidget {
  const _ContactsPanel({required this.contacts, required this.onTap});

  final List<YapeContact> contacts;
  final ValueChanged<YapeContact>? onTap;

  @override
  Widget build(BuildContext context) {
    if (contacts.isEmpty) return const SizedBox.shrink();
    return YBCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: contacts
            .map(
              (contact) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(contact.alias),
                subtitle: Text(contact.phone),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: onTap == null ? null : () => onTap!(contact),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _AmountField extends StatelessWidget {
  const _AmountField({required this.controller, required this.enabled});

  final TextEditingController controller;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: const InputDecoration(labelText: 'Monto'),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return YBCard(
      child: Text(
        message,
        style: const TextStyle(color: AppColors.textMuted),
      ),
    );
  }
}

String _messageFromDio(DioException error) {
  final data = error.response?.data;
  if (data is Map && data['message'] != null) return data['message'].toString();
  return 'No se pudo procesar la operacion';
}

void _showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

void _refreshBankingData(WidgetRef ref) {
  ref.invalidate(homeSummaryProvider);
  ref.invalidate(accountSummariesProvider);
  ref.invalidate(accountMovementsProvider);
}
