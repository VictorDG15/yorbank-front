class LoanProduct {
  const LoanProduct({
    required this.id,
    required this.name,
    required this.annualRate,
    required this.minAmount,
    required this.maxAmount,
    required this.minMonths,
    required this.maxMonths,
  });

  final int id;
  final String name;
  final double annualRate;
  final double minAmount;
  final double maxAmount;
  final int minMonths;
  final int maxMonths;

  factory LoanProduct.fromJson(Map<String, dynamic> json) {
    return LoanProduct(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name']?.toString() ?? 'Prestamo',
      annualRate: double.tryParse(json['annualRate']?.toString() ?? '') ?? 0,
      minAmount: double.tryParse(json['minAmount']?.toString() ?? '') ?? 500,
      maxAmount: double.tryParse(json['maxAmount']?.toString() ?? '') ?? 10000,
      minMonths: int.tryParse(json['minMonths']?.toString() ?? '') ?? 6,
      maxMonths: int.tryParse(json['maxMonths']?.toString() ?? '') ?? 36,
    );
  }
}

class LoanSimulation {
  const LoanSimulation({
    required this.applicationId,
    required this.operationId,
    required this.status,
    required this.productName,
    required this.amount,
    required this.months,
    required this.annualRate,
    required this.monthlyPayment,
    required this.totalInterest,
    required this.totalInsurance,
    required this.totalCommission,
    required this.totalPayment,
    required this.tcea,
    required this.startDate,
    required this.firstDueDate,
    required this.paymentDay,
    required this.purpose,
    required this.declaredMonthlyIncome,
    required this.capacityStatus,
    required this.advice,
    required this.schedule,
  });

  final int? applicationId;
  final String? operationId;
  final String status;
  final String productName;
  final double amount;
  final int months;
  final double annualRate;
  final double monthlyPayment;
  final double totalInterest;
  final double totalInsurance;
  final double totalCommission;
  final double totalPayment;
  final double tcea;
  final DateTime? startDate;
  final DateTime? firstDueDate;
  final int paymentDay;
  final String purpose;
  final double declaredMonthlyIncome;
  final String capacityStatus;
  final String advice;
  final List<LoanInstallment> schedule;

  factory LoanSimulation.fromJson(Map<String, dynamic> json) {
    final scheduleItems = json['schedule'] as List<dynamic>? ?? const [];
    return LoanSimulation(
      applicationId: int.tryParse(json['applicationId']?.toString() ?? ''),
      operationId: json['operationId']?.toString(),
      status: json['status']?.toString() ?? 'SIMULATED',
      productName: json['productName']?.toString() ?? 'Prestamo',
      amount: double.tryParse(json['amount']?.toString() ?? '') ?? 0,
      months: int.tryParse(json['months']?.toString() ?? '') ?? 0,
      annualRate: double.tryParse(json['annualRate']?.toString() ?? '') ?? 0,
      monthlyPayment:
          double.tryParse(json['monthlyPayment']?.toString() ?? '') ?? 0,
      totalInterest:
          double.tryParse(json['totalInterest']?.toString() ?? '') ?? 0,
      totalInsurance:
          double.tryParse(json['totalInsurance']?.toString() ?? '') ?? 0,
      totalCommission:
          double.tryParse(json['totalCommission']?.toString() ?? '') ?? 0,
      totalPayment:
          double.tryParse(json['totalPayment']?.toString() ?? '') ?? 0,
      tcea: double.tryParse(json['tcea']?.toString() ?? '') ?? 0,
      startDate: DateTime.tryParse(json['startDate']?.toString() ?? ''),
      firstDueDate: DateTime.tryParse(json['firstDueDate']?.toString() ?? ''),
      paymentDay: int.tryParse(json['paymentDay']?.toString() ?? '') ?? 15,
      purpose: json['purpose']?.toString() ?? 'Libre disponibilidad',
      declaredMonthlyIncome:
          double.tryParse(json['declaredMonthlyIncome']?.toString() ?? '') ?? 0,
      capacityStatus: json['capacityStatus']?.toString() ?? '',
      advice: json['advice']?.toString() ?? '',
      schedule: scheduleItems
          .map((e) => LoanInstallment.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

class LoanInstallment {
  const LoanInstallment({
    required this.number,
    required this.dueDate,
    required this.openingBalance,
    required this.amortization,
    required this.interest,
    required this.insurance,
    required this.commission,
    required this.paymentAmount,
    required this.closingBalance,
  });

  final int number;
  final DateTime? dueDate;
  final double openingBalance;
  final double amortization;
  final double interest;
  final double insurance;
  final double commission;
  final double paymentAmount;
  final double closingBalance;

  factory LoanInstallment.fromJson(Map<String, dynamic> json) {
    return LoanInstallment(
      number: int.tryParse(json['number']?.toString() ?? '') ?? 0,
      dueDate: DateTime.tryParse(json['dueDate']?.toString() ?? ''),
      openingBalance:
          double.tryParse(json['openingBalance']?.toString() ?? '') ?? 0,
      amortization:
          double.tryParse(json['amortization']?.toString() ?? '') ?? 0,
      interest: double.tryParse(json['interest']?.toString() ?? '') ?? 0,
      insurance: double.tryParse(json['insurance']?.toString() ?? '') ?? 0,
      commission: double.tryParse(json['commission']?.toString() ?? '') ?? 0,
      paymentAmount:
          double.tryParse(json['paymentAmount']?.toString() ?? '') ?? 0,
      closingBalance:
          double.tryParse(json['closingBalance']?.toString() ?? '') ?? 0,
    );
  }
}

class LoanApplicationResult {
  const LoanApplicationResult({
    required this.applicationId,
    required this.operationId,
    required this.status,
    required this.simulation,
  });

  final int applicationId;
  final String operationId;
  final String status;
  final LoanSimulation simulation;

  factory LoanApplicationResult.fromJson(Map<String, dynamic> json) {
    return LoanApplicationResult(
      applicationId: int.tryParse(json['applicationId']?.toString() ?? '') ?? 0,
      operationId: json['operationId']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      simulation: LoanSimulation.fromJson(
        Map<String, dynamic>.from(json['simulation'] ?? const {}),
      ),
    );
  }
}

class LoanApplicationSummary {
  const LoanApplicationSummary({
    required this.id,
    required this.operationId,
    required this.productName,
    required this.amount,
    required this.months,
    required this.monthlyPayment,
    required this.status,
    required this.createdAt,
  });

  final int id;
  final String operationId;
  final String productName;
  final double amount;
  final int months;
  final double monthlyPayment;
  final String status;
  final DateTime? createdAt;

  factory LoanApplicationSummary.fromJson(Map<String, dynamic> json) {
    return LoanApplicationSummary(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      operationId: json['operationId']?.toString() ?? '',
      productName: json['productName']?.toString() ?? 'Prestamo',
      amount: double.tryParse(json['amount']?.toString() ?? '') ?? 0,
      months: int.tryParse(json['months']?.toString() ?? '') ?? 0,
      monthlyPayment:
          double.tryParse(json['monthlyPayment']?.toString() ?? '') ?? 0,
      status: json['status']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
    );
  }
}
