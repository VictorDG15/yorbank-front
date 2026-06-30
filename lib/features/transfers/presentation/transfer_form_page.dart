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

class TransferFormPage extends ConsumerStatefulWidget {
  const TransferFormPage({super.key});

  @override
  ConsumerState<TransferFormPage> createState() => _TransferFormPageState();
}

class _TransferFormPageState extends ConsumerState<TransferFormPage> {
  final _destinationController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _originAccount;
  String? _bankCode;
  bool _loading = false;

  @override
  void dispose() {
    _destinationController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(accountSummariesProvider);
    final banks = ref.watch(transferBanksProvider);
    final accountItems = accounts.valueOrNull ?? const <AccountSummary>[];
    final bankItems = banks.valueOrNull ?? const <TransferBank>[];
    final selectedAccount = _selectedAccount(accountItems);
    final selectedBank = _selectedBank(bankItems);

    return Scaffold(
      appBar: AppBar(title: const Text('Nueva transferencia')),
      bottomNavigationBar: const MainBottomNav(currentIndex: 2),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 96),
        children: [
          accounts.when(
            data: (items) => _OriginAccountCard(
              accounts: items,
              selectedAccount: selectedAccount,
              onChanged: _loading
                  ? null
                  : (value) => setState(() => _originAccount = value),
            ),
            loading: () => const LinearProgressIndicator(),
            error: (error, _) => _ErrorCard(message: error.toString()),
          ),
          const SizedBox(height: 18),
          banks.when(
            data: (items) => _BankSelector(
              banks: items,
              selectedBank: selectedBank,
              onChanged: _loading
                  ? null
                  : (value) => setState(() => _bankCode = value),
            ),
            loading: () => const LinearProgressIndicator(),
            error: (error, _) => _ErrorCard(message: error.toString()),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _destinationController,
            enabled: !_loading,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9-]')),
            ],
            decoration: const InputDecoration(
              labelText: 'Cuenta destino',
              hintText: '001-102-00889900',
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _amountController,
            enabled: !_loading,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Monto'),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _descriptionController,
            enabled: !_loading,
            decoration: const InputDecoration(labelText: 'Descripcion'),
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: 'Transferir',
            loading: _loading,
            onPressed: selectedAccount == null || selectedBank == null
                ? null
                : () => _submit(selectedAccount, selectedBank),
          ),
        ],
      ),
    );
  }

  AccountSummary? _selectedAccount(List<AccountSummary> accounts) {
    if (accounts.isEmpty) return null;
    final selected = _originAccount;
    if (selected == null) return accounts.first;
    return accounts.firstWhere(
      (account) => account.number == selected,
      orElse: () => accounts.first,
    );
  }

  TransferBank? _selectedBank(List<TransferBank> banks) {
    if (banks.isEmpty) return null;
    final selected = _bankCode;
    if (selected == null) return banks.first;
    return banks.firstWhere((bank) => bank.code == selected, orElse: () {
      return banks.first;
    });
  }

  Future<void> _submit(AccountSummary account, TransferBank bank) async {
    final destination = _destinationController.text.trim();
    final amount =
        double.tryParse(_amountController.text.trim().replaceAll(',', '.'));
    if (destination.isEmpty || amount == null || amount <= 0) {
      _showMessage('Completa cuenta destino y monto valido');
      return;
    }

    setState(() => _loading = true);
    try {
      final receipt = await ref.read(bankingApiProvider).createTransfer(
            originAccount: account.number,
            destinationAccount: destination,
            destinationBankCode: bank.code,
            amount: amount,
            currency: account.currency,
            description: _descriptionController.text.trim(),
          );
      ref.invalidate(homeSummaryProvider);
      ref.invalidate(accountSummariesProvider);
      ref.invalidate(accountMovementsProvider);
      if (!mounted) return;
      _showMessage('Transferencia ${receipt.status}: ${receipt.operationId}');
      context.go('/home');
    } on DioException catch (error) {
      _showMessage(_messageFromDio(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _messageFromDio(DioException error) {
    final data = error.response?.data;
    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }
    return 'No se pudo procesar la operacion';
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _OriginAccountCard extends StatelessWidget {
  const _OriginAccountCard({
    required this.accounts,
    required this.selectedAccount,
    required this.onChanged,
  });

  final List<AccountSummary> accounts;
  final AccountSummary? selectedAccount;
  final ValueChanged<String?>? onChanged;

  @override
  Widget build(BuildContext context) {
    if (accounts.isEmpty) {
      return const _ErrorCard(message: 'No hay cuentas activas');
    }

    return YBCard(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedAccount?.number,
          isExpanded: true,
          onChanged: onChanged,
          items: accounts
              .map(
                (account) => DropdownMenuItem(
                  value: account.number,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.account_balance_wallet_rounded,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Cuenta - ${account.accountTail}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              account.formattedBalance,
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _BankSelector extends StatelessWidget {
  const _BankSelector({
    required this.banks,
    required this.selectedBank,
    required this.onChanged,
  });

  final List<TransferBank> banks;
  final TransferBank? selectedBank;
  final ValueChanged<String?>? onChanged;

  @override
  Widget build(BuildContext context) {
    if (banks.isEmpty) return const _ErrorCard(message: 'No hay bancos activos');

    return DropdownButtonFormField<String>(
      value: selectedBank?.code,
      decoration: const InputDecoration(labelText: 'Banco destino'),
      onChanged: onChanged,
      items: banks
          .map(
            (bank) => DropdownMenuItem(
              value: bank.code,
              child: Text(bank.name),
            ),
          )
          .toList(),
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
