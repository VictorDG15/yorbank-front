import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/main_bottom_nav.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/yb_card.dart';
import '../../home/data/banking_api.dart';
import '../../home/domain/account_summary.dart';
import '../data/loan_api.dart';
import '../domain/loan_models.dart';

class LoanSimulatorPage extends ConsumerStatefulWidget {
  const LoanSimulatorPage({super.key});

  @override
  ConsumerState<LoanSimulatorPage> createState() => _LoanSimulatorPageState();
}

class _LoanSimulatorPageState extends ConsumerState<LoanSimulatorPage> {
  final _amountController = TextEditingController(text: '0');
  final _incomeController = TextEditingController(text: '0');
  String? _accountNumber;
  int? _productId;
  int _months = 12;
  int _paymentDay = 15;
  DateTime _startDate = DateTime.now();
  String _purpose = 'Libre disponibilidad';
  LoanSimulation? _simulation;
  int? _applicationId;
  bool _simulating = false;
  bool _applying = false;
  bool _downloading = false;

  static const _maxAmount = 10000.0;
  static const _paymentDays = [5, 10, 15, 20, 25, 28];
  static const _purposes = [
    'Libre disponibilidad',
    'Consolidar deudas',
    'Capital de trabajo',
    'Estudios',
    'Salud',
  ];

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_clearSimulation);
    _incomeController.addListener(_clearSimulation);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _incomeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(loanProductsProvider);
    final accounts = ref.watch(accountSummariesProvider);
    final applications = ref.watch(loanApplicationsProvider);
    final product = _selectedProduct(products.valueOrNull ?? const []);
    final account = _selectedAccount(accounts.valueOrNull ?? const []);
    final amount = _amount;
    final canGenerate =
        product != null &&
        account != null &&
        amount >= 500 &&
        amount <= _maxAmount &&
        !_simulating &&
        !_applying;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(title: const Text('Prestamo')),
      bottomNavigationBar: const MainBottomNav(currentIndex: 1),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 96),
        children: [
          _HeaderCard(amount: amount),
          const SizedBox(height: 14),
          applications.when(
            data: (items) => _ApplicationsCard(
              applications: items,
              downloading: _downloading,
              onDownload: _downloadApplicationPdf,
            ),
            loading: () => const LinearProgressIndicator(),
            error: (error, _) => _ErrorCard(message: error.toString()),
          ),
          const SizedBox(height: 14),
          products.when(
            data: (items) => _ProductSelector(
              products: items,
              selected: product,
              onChanged: _busy
                  ? null
                  : (value) => setState(() {
                      _productId = value;
                      _months = _fitMonths(_months, _selectedProduct(items));
                      _simulation = null;
                      _applicationId = null;
                    }),
            ),
            loading: () => const LinearProgressIndicator(),
            error: (error, _) => _ErrorCard(message: error.toString()),
          ),
          const SizedBox(height: 14),
          accounts.when(
            data: (items) => _AccountSelector(
              accounts: items,
              selected: account,
              onChanged: _busy
                  ? null
                  : (value) => setState(() {
                      _accountNumber = value;
                      _simulation = null;
                      _applicationId = null;
                    }),
            ),
            loading: () => const LinearProgressIndicator(),
            error: (error, _) => _ErrorCard(message: error.toString()),
          ),
          const SizedBox(height: 14),
          _AmountCard(
            controller: _amountController,
            amount: amount,
            enabled: !_busy,
            maxAmount: _maxAmount,
            onSliderChanged: (value) {
              setState(() {
                _amountController.text = value.round().toString();
              });
            },
          ),
          const SizedBox(height: 14),
          _WindowDataCard(
            incomeController: _incomeController,
            purpose: _purpose,
            months: _months,
            termOptions: _termOptions(product),
            startDate: _startDate,
            paymentDay: _paymentDay,
            paymentDays: _paymentDays,
            enabled: !_busy,
            onPurposeChanged: (value) => setState(() {
              _purpose = value ?? _purpose;
              _simulation = null;
              _applicationId = null;
            }),
            onMonthsChanged: (value) => setState(() {
              _months = value ?? _months;
              _simulation = null;
              _applicationId = null;
            }),
            onPaymentDayChanged: (value) => setState(() {
              _paymentDay = value ?? _paymentDay;
              _simulation = null;
              _applicationId = null;
            }),
            onPickDate: _pickStartDate,
          ),
          const SizedBox(height: 18),
          PrimaryButton(
            label: 'Generar cronograma',
            loading: _simulating,
            onPressed: canGenerate && product != null && account != null
                ? () => _simulate(product, account)
                : null,
          ),
          if (_simulation != null) ...[
            const SizedBox(height: 18),
            _SimulationSummary(simulation: _simulation!),
            const SizedBox(height: 14),
            _AdviceCard(simulation: _simulation!),
            const SizedBox(height: 14),
            _ScheduleCard(schedule: _simulation!.schedule),
            const SizedBox(height: 18),
            PrimaryButton(
              label: _applicationId == null
                  ? 'Aceptar y desembolsar'
                  : 'Prestamo aprobado',
              loading: _applying,
              onPressed:
                  _applicationId == null &&
                      !_applying &&
                      !_simulating &&
                      product != null &&
                      account != null
                  ? () => _apply(product, account)
                  : null,
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _applicationId == null || _downloading
                  ? null
                  : _downloadPdf,
              icon: _downloading
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.picture_as_pdf_rounded),
              label: const Text('Descargar cronograma PDF'),
            ),
          ],
        ],
      ),
    );
  }

  bool get _busy => _simulating || _applying || _downloading;

  double get _amount {
    return double.tryParse(
          _amountController.text.trim().replaceAll(',', '.'),
        ) ??
        0;
  }

  double get _income {
    return double.tryParse(
          _incomeController.text.trim().replaceAll(',', '.'),
        ) ??
        0;
  }

  LoanProduct? _selectedProduct(List<LoanProduct> products) {
    if (products.isEmpty) return null;
    final selected = _productId;
    if (selected == null) return products.first;
    return products.firstWhere(
      (product) => product.id == selected,
      orElse: () => products.first,
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

  List<int> _termOptions(LoanProduct? product) {
    const base = [6, 12, 18, 24, 36, 48, 60];
    if (product == null) return const [6, 12, 18, 24, 36];
    final filtered = base
        .where(
          (months) =>
              months >= product.minMonths && months <= product.maxMonths,
        )
        .toList();
    return filtered.isEmpty ? [product.minMonths] : filtered;
  }

  int _fitMonths(int current, LoanProduct? product) {
    final options = _termOptions(product);
    return options.contains(current) ? current : options.first;
  }

  Future<void> _pickStartDate() async {
    if (_busy) return;
    final today = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _startDate.isBefore(today) ? today : _startDate,
      firstDate: DateTime(today.year, today.month, today.day),
      lastDate: today.add(const Duration(days: 60)),
    );
    if (selected == null) return;
    setState(() {
      _startDate = selected;
      _simulation = null;
      _applicationId = null;
    });
  }

  Future<void> _simulate(LoanProduct product, AccountSummary account) async {
    setState(() {
      _simulating = true;
      _simulation = null;
      _applicationId = null;
    });
    try {
      final result = await ref
          .read(loanApiProvider)
          .simulate(
            productId: product.id,
            amount: _amount,
            months: _months,
            accountNumber: account.number,
            startDate: _startDate,
            paymentDay: _paymentDay,
            purpose: _purpose,
            declaredMonthlyIncome: _income,
          );
      if (mounted) setState(() => _simulation = result);
    } on DioException catch (error) {
      _showMessage(_messageFromDio(error));
    } finally {
      if (mounted) setState(() => _simulating = false);
    }
  }

  Future<void> _apply(LoanProduct product, AccountSummary account) async {
    setState(() => _applying = true);
    try {
      final result = await ref
          .read(loanApiProvider)
          .apply(
            productId: product.id,
            amount: _amount,
            months: _months,
            accountNumber: account.number,
            startDate: _startDate,
            paymentDay: _paymentDay,
            purpose: _purpose,
            declaredMonthlyIncome: _income,
          );
      ref.invalidate(homeSummaryProvider);
      ref.invalidate(accountSummariesProvider);
      ref.invalidate(accountMovementsProvider);
      ref.invalidate(loanApplicationsProvider);
      if (!mounted) return;
      setState(() {
        _applicationId = result.applicationId;
        _simulation = result.simulation;
      });
      _showMessage('Prestamo aprobado: ${result.operationId}');
    } on DioException catch (error) {
      _showMessage(_messageFromDio(error));
    } finally {
      if (mounted) setState(() => _applying = false);
    }
  }

  Future<void> _downloadPdf() async {
    final id = _applicationId;
    if (id == null) return;
    await _downloadApplicationPdf(id);
  }

  Future<void> _downloadApplicationPdf(int id) async {
    setState(() => _downloading = true);
    try {
      final path = await ref.read(loanApiProvider).downloadSchedulePdf(id);
      _showMessage('PDF descargado: $path');
    } on DioException catch (error) {
      _showMessage(_messageFromDio(error));
    } catch (error) {
      _showMessage(
        'No se pudo guardar el PDF. Reinicia la app si usaste hot reload.',
      );
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  void _clearSimulation() {
    setState(() {
      _simulation = null;
      _applicationId = null;
    });
  }

  String _messageFromDio(DioException error) {
    final data = error.response?.data;
    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }
    return 'No se pudo procesar el prestamo';
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.amount});

  final double amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryDeep, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Prestamo digital',
            style: TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Simula como en ventanilla: producto, cuenta, fecha, capacidad de pago y cronograma.',
            style: TextStyle(color: Colors.white70, height: 1.35),
          ),
          const SizedBox(height: 16),
          Text(
            _money(amount),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ApplicationsCard extends StatelessWidget {
  const _ApplicationsCard({
    required this.applications,
    required this.downloading,
    required this.onDownload,
  });

  final List<LoanApplicationSummary> applications;
  final bool downloading;
  final ValueChanged<int> onDownload;

  @override
  Widget build(BuildContext context) {
    return YBCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Prestamos solicitados',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
          const SizedBox(height: 10),
          if (applications.isEmpty)
            const Text(
              'Aun no tienes prestamos solicitados.',
              style: TextStyle(color: AppColors.textMuted),
            )
          else
            ...applications
                .take(4)
                .map(
                  (item) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      item.productName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(
                      '${_statusLabel(item.status)} · ${item.months} meses · cuota ${_money(item.monthlyPayment)}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: IconButton(
                      tooltip: 'Descargar cronograma',
                      onPressed: downloading ? null : () => onDownload(item.id),
                      icon: downloading
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.picture_as_pdf_rounded),
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

class _ProductSelector extends StatelessWidget {
  const _ProductSelector({
    required this.products,
    required this.selected,
    required this.onChanged,
  });

  final List<LoanProduct> products;
  final LoanProduct? selected;
  final ValueChanged<int?>? onChanged;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return const _ErrorCard(message: 'No hay productos de prestamo activos');
    }
    return DropdownButtonFormField<int>(
      value: selected?.id,
      isExpanded: true,
      decoration: const InputDecoration(labelText: 'Producto'),
      selectedItemBuilder: (_) => products
          .map(
            (product) => Text(
              product.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          )
          .toList(),
      onChanged: onChanged,
      items: products
          .map(
            (product) => DropdownMenuItem(
              value: product.id,
              child: Text(
                '${product.name} - TEA ${product.annualRate.toStringAsFixed(2)}%',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
    );
  }
}

class _AccountSelector extends StatelessWidget {
  const _AccountSelector({
    required this.accounts,
    required this.selected,
    required this.onChanged,
  });

  final List<AccountSummary> accounts;
  final AccountSummary? selected;
  final ValueChanged<String?>? onChanged;

  @override
  Widget build(BuildContext context) {
    if (accounts.isEmpty) {
      return const _ErrorCard(message: 'No hay cuentas para desembolso');
    }
    return DropdownButtonFormField<String>(
      value: selected?.number,
      isExpanded: true,
      decoration: const InputDecoration(labelText: 'Cuenta de desembolso'),
      selectedItemBuilder: (_) => accounts
          .map(
            (account) => Text(
              '${account.accountTail} - ${account.formattedBalance}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          )
          .toList(),
      onChanged: onChanged,
      items: accounts
          .map(
            (account) => DropdownMenuItem(
              value: account.number,
              child: Text(
                '${account.accountTail} - ${account.formattedBalance}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
    );
  }
}

class _AmountCard extends StatelessWidget {
  const _AmountCard({
    required this.controller,
    required this.amount,
    required this.enabled,
    required this.maxAmount,
    required this.onSliderChanged,
  });

  final TextEditingController controller;
  final double amount;
  final bool enabled;
  final double maxAmount;
  final ValueChanged<double> onSliderChanged;

  @override
  Widget build(BuildContext context) {
    final error = amount > maxAmount
        ? 'Maximo S/ 10,000'
        : amount > 0 && amount < 500
        ? 'Minimo S/ 500'
        : null;
    return YBCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Monto solicitado',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            enabled: enabled,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
            decoration: InputDecoration(
              prefixText: 'S/ ',
              helperText: 'Disponible hasta S/ 10,000',
              errorText: error,
            ),
          ),
          Slider(
            min: 0,
            max: maxAmount,
            divisions: 100,
            value: amount.clamp(0, maxAmount).toDouble(),
            onChanged: enabled ? onSliderChanged : null,
          ),
        ],
      ),
    );
  }
}

class _WindowDataCard extends StatelessWidget {
  const _WindowDataCard({
    required this.incomeController,
    required this.purpose,
    required this.months,
    required this.termOptions,
    required this.startDate,
    required this.paymentDay,
    required this.paymentDays,
    required this.enabled,
    required this.onPurposeChanged,
    required this.onMonthsChanged,
    required this.onPaymentDayChanged,
    required this.onPickDate,
  });

  final TextEditingController incomeController;
  final String purpose;
  final int months;
  final List<int> termOptions;
  final DateTime startDate;
  final int paymentDay;
  final List<int> paymentDays;
  final bool enabled;
  final ValueChanged<String?> onPurposeChanged;
  final ValueChanged<int?> onMonthsChanged;
  final ValueChanged<int?> onPaymentDayChanged;
  final VoidCallback onPickDate;

  @override
  Widget build(BuildContext context) {
    return YBCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Datos de evaluacion',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: purpose,
            decoration: const InputDecoration(labelText: 'Finalidad'),
            onChanged: enabled ? onPurposeChanged : null,
            items: _LoanSimulatorPageState._purposes
                .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                .toList(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: incomeController,
            enabled: enabled,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Ingreso mensual declarado',
              prefixText: 'S/ ',
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            value: termOptions.contains(months) ? months : termOptions.first,
            decoration: const InputDecoration(labelText: 'Plazo'),
            onChanged: enabled ? onMonthsChanged : null,
            items: termOptions
                .map(
                  (item) =>
                      DropdownMenuItem(value: item, child: Text('$item meses')),
                )
                .toList(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: enabled ? onPickDate : null,
                  icon: const Icon(Icons.calendar_month_rounded),
                  label: Text(_date(startDate)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: paymentDay,
                  decoration: const InputDecoration(labelText: 'Dia de pago'),
                  onChanged: enabled ? onPaymentDayChanged : null,
                  items: paymentDays
                      .map(
                        (item) => DropdownMenuItem(
                          value: item,
                          child: Text('Dia $item'),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SimulationSummary extends StatelessWidget {
  const _SimulationSummary({required this.simulation});

  final LoanSimulation simulation;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDeep],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Cuota estimada', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 6),
          Text(
            '${_money(simulation.monthlyPayment)} / mes',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Tag('TEA ${simulation.annualRate.toStringAsFixed(2)}%'),
              _Tag('TCEA ${simulation.tcea.toStringAsFixed(2)}%'),
              _Tag('${simulation.months} meses'),
            ],
          ),
          const SizedBox(height: 14),
          _SummaryLine('Intereses', _money(simulation.totalInterest)),
          _SummaryLine('Seguro', _money(simulation.totalInsurance)),
          _SummaryLine('Comisiones', _money(simulation.totalCommission)),
          _SummaryLine('Total a pagar', _money(simulation.totalPayment)),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdviceCard extends StatelessWidget {
  const _AdviceCard({required this.simulation});

  final LoanSimulation simulation;

  @override
  Widget build(BuildContext context) {
    return YBCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.psychology_alt_rounded),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _capacityLabel(simulation.capacityStatus),
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  simulation.advice,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({required this.schedule});

  final List<LoanInstallment> schedule;

  static const _headers = [
    'N',
    'Vence',
    'Saldo',
    'Interes',
    'Amort.',
    'Seguro',
    'Cuota',
  ];
  static const _widths = [34.0, 84.0, 90.0, 80.0, 82.0, 76.0, 88.0];

  @override
  Widget build(BuildContext context) {
    return YBCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Cronograma',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                  ),
                ),
                Text(
                  '${schedule.length} cuotas',
                  style: const TextStyle(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: _widths.fold<double>(0, (sum, item) => sum + item),
              child: Column(
                children: [
                  _ScheduleRow(values: _headers, widths: _widths, header: true),
                  ...schedule.map(
                    (item) => _ScheduleRow(
                      values: [
                        item.number.toString(),
                        _date(item.dueDate),
                        _moneyShort(item.openingBalance),
                        _moneyShort(item.interest),
                        _moneyShort(item.amortization),
                        _moneyShort(item.insurance),
                        _moneyShort(item.paymentAmount),
                      ],
                      widths: _widths,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
        ],
      ),
    );
  }
}

class _ScheduleRow extends StatelessWidget {
  const _ScheduleRow({
    required this.values,
    required this.widths,
    this.header = false,
  });

  final List<String> values;
  final List<double> widths;
  final bool header;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: header ? AppColors.primaryDeep : Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: List.generate(values.length, (index) {
          return SizedBox(
            width: widths[index],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                values[index],
                textAlign: index == 0 ? TextAlign.center : TextAlign.right,
                style: TextStyle(
                  color: header ? Colors.white : AppColors.text,
                  fontSize: 11.5,
                  fontWeight: header ? FontWeight.w900 : FontWeight.w600,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return YBCard(
      child: Text(message, style: const TextStyle(color: AppColors.textMuted)),
    );
  }
}

String _capacityLabel(String value) {
  return switch (value) {
    'SALUDABLE' => 'Capacidad saludable',
    'AJUSTADO' => 'Capacidad ajustada',
    'RIESGO_ALTO' => 'Riesgo alto',
    _ => 'Ingreso por confirmar',
  };
}

String _statusLabel(String value) {
  return switch (value) {
    'APPROVED_DISBURSED' => 'Aprobado y desembolsado',
    'SIMULATED' => 'Simulado',
    'REJECTED' => 'Rechazado',
    _ => value.isEmpty ? 'Registrado' : value,
  };
}

String _date(DateTime? value) {
  if (value == null) return '-';
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  return '$day/$month/${value.year}';
}

String _money(double value) => 'S/ ${_format(value)}';

String _moneyShort(double value) => _format(value);

String _format(double value) {
  final fixed = value.toStringAsFixed(2);
  final parts = fixed.split('.');
  final whole = parts.first;
  final decimals = parts.last;
  final buffer = StringBuffer();
  for (var i = 0; i < whole.length; i++) {
    if (i > 0 && (whole.length - i) % 3 == 0) buffer.write(',');
    buffer.write(whole[i]);
  }
  return '${buffer.toString()}.$decimals';
}
