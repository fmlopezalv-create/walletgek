import 'dart:math' as math;

/// Calcula la cuota mensual de un préstamo amortizado (fórmula estándar).
double monthlyPaymentFromPrincipal({
  required double principal,
  required double annualRatePercent,
  required int months,
}) {
  if (principal <= 0 || months <= 0) return 0;
  final r = annualRatePercent / 100 / 12;
  if (r <= 0) return principal / months;
  final f = math.pow(1 + r, months);
  return principal * r * f / (f - 1);
}

/// Calcula el número de cuotas a partir de la cuota mensual.
int? monthsFromPayment({
  required double principal,
  required double annualRatePercent,
  required double payment,
}) {
  if (principal <= 0 || payment <= 0) return null;
  final r = annualRatePercent / 100 / 12;
  if (r <= 0) return (principal / payment).ceil();
  final ratio = principal * r / payment;
  if (ratio >= 1) return null; // la cuota no cubre ni los intereses
  final n = -math.log(1 - ratio) / math.log(1 + r);
  return n.ceil();
}
