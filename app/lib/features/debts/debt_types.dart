import 'package:flutter/material.dart';

enum DebtFieldType { text, money, percent, number, choice, months, day }

class DebtFieldDef {
  final String key;
  final String label;
  final DebtFieldType type;
  final bool required;
  final List<String>? choices;
  final String? showIfKey;
  final String? showIfValue;

  const DebtFieldDef(
    this.key,
    this.label,
    this.type, {
    this.required = false,
    this.choices,
    this.showIfKey,
    this.showIfValue,
  });
}

class DebtTypeSchema {
  final String id;
  final String label;
  final IconData icon;
  final List<String> countries; // vacío = disponible en todos los países
  final List<DebtFieldDef> fields;

  const DebtTypeSchema(this.id, this.label, this.icon, this.countries, this.fields);
}

const List<DebtTypeSchema> debtTypes = [
  DebtTypeSchema('bank_loan', 'Préstamo bancario', Icons.account_balance, [], [
    DebtFieldDef('institution', 'Institución financiera', DebtFieldType.text, required: true),
    DebtFieldDef('initial_capital', 'Capital inicial', DebtFieldType.money),
    DebtFieldDef('balance', 'Valor pendiente', DebtFieldType.money, required: true),
    DebtFieldDef('interest', 'Tasa de interés anual (%)', DebtFieldType.percent),
    DebtFieldDef('monthly_payment', 'Cuota mensual', DebtFieldType.money),
    DebtFieldDef('due_date', 'Día de pago mensual', DebtFieldType.day),
    DebtFieldDef('total_installments', 'Cuotas totales', DebtFieldType.number),
    DebtFieldDef('paid_installments', 'Cuotas pagadas', DebtFieldType.number),
  ]),
  DebtTypeSchema('credit_card', 'Tarjeta de crédito', Icons.credit_card, [], [
    DebtFieldDef('institution', 'Entidad emisora', DebtFieldType.text, required: true),
    DebtFieldDef('credit_limit', 'Límite de crédito', DebtFieldType.money),
    DebtFieldDef('balance', 'Saldo pendiente', DebtFieldType.money, required: true),
    DebtFieldDef('interest', 'Tasa de interés anual (%)', DebtFieldType.percent),
    DebtFieldDef('payment_type', 'Tipo de pago', DebtFieldType.choice,
        required: true, choices: ['Pago mínimo', 'Pago de contado', 'Pago a la fecha']),
    DebtFieldDef('monthly_payment', 'Cuota mensual', DebtFieldType.money),
    DebtFieldDef('due_date', 'Día de pago mensual', DebtFieldType.day),
  ]),
  DebtTypeSchema('personal_loan', 'Préstamo personal', Icons.person, [], [
    DebtFieldDef('institution', 'Entidad', DebtFieldType.text),
    DebtFieldDef('balance', 'Valor pendiente', DebtFieldType.money, required: true),
    DebtFieldDef('interest', 'Tasa de interés anual (%)', DebtFieldType.percent),
    DebtFieldDef('monthly_payment', 'Cuota mensual', DebtFieldType.money),
    DebtFieldDef('due_date', 'Día de pago mensual', DebtFieldType.day),
    DebtFieldDef('total_installments', 'Cuotas totales', DebtFieldType.number),
    DebtFieldDef('paid_installments', 'Cuotas pagadas', DebtFieldType.number),
  ]),
  DebtTypeSchema('mortgage', 'Hipoteca', Icons.home_work, [], [
    DebtFieldDef('institution', 'Entidad financiera', DebtFieldType.text),
    DebtFieldDef('property_value', 'Valor de la propiedad', DebtFieldType.money),
    DebtFieldDef('balance', 'Capital pendiente', DebtFieldType.money, required: true),
    DebtFieldDef('interest', 'Tasa de interés anual (%)', DebtFieldType.percent),
    DebtFieldDef('rate_type', 'Tipo de interés', DebtFieldType.choice, choices: ['Fijo', 'Variable']),
    DebtFieldDef('monthly_payment', 'Cuota mensual', DebtFieldType.money),
    DebtFieldDef('due_date', 'Día de pago mensual', DebtFieldType.day),
    DebtFieldDef('total_installments', 'Cuotas totales', DebtFieldType.number),
    DebtFieldDef('paid_installments', 'Cuotas pagadas', DebtFieldType.number),
  ]),
  DebtTypeSchema('auto_loan', 'Crédito automotriz', Icons.directions_car, [], [
    DebtFieldDef('institution', 'Entidad', DebtFieldType.text),
    DebtFieldDef('vehicle_value', 'Valor del vehículo', DebtFieldType.money),
    DebtFieldDef('balance', 'Valor pendiente', DebtFieldType.money, required: true),
    DebtFieldDef('interest', 'Tasa de interés anual (%)', DebtFieldType.percent),
    DebtFieldDef('monthly_payment', 'Cuota mensual', DebtFieldType.money),
    DebtFieldDef('due_date', 'Día de pago mensual', DebtFieldType.day),
    DebtFieldDef('total_installments', 'Cuotas totales', DebtFieldType.number),
    DebtFieldDef('paid_installments', 'Cuotas pagadas', DebtFieldType.number),
  ]),
  DebtTypeSchema('student_loan', 'Préstamo estudiantil', Icons.school, [], [
    DebtFieldDef('institution', 'Entidad', DebtFieldType.text),
    DebtFieldDef('balance', 'Valor pendiente', DebtFieldType.money, required: true),
    DebtFieldDef('interest', 'Tasa de interés anual (%)', DebtFieldType.percent),
    DebtFieldDef('monthly_payment', 'Cuota mensual', DebtFieldType.money),
    DebtFieldDef('due_date', 'Día de pago mensual', DebtFieldType.day),
    DebtFieldDef('total_installments', 'Cuotas totales', DebtFieldType.number),
    DebtFieldDef('paid_installments', 'Cuotas pagadas', DebtFieldType.number),
    DebtFieldDef('grace_period', '¿En periodo de gracia?', DebtFieldType.choice, choices: ['Sí', 'No']),
  ]),
  DebtTypeSchema('payroll_loan', 'Crédito de nómina', Icons.work, ['MX', 'CO', 'AR', 'PE', 'CL', 'EC'], [
    DebtFieldDef('institution', 'Entidad', DebtFieldType.text),
    DebtFieldDef('balance', 'Valor pendiente', DebtFieldType.money, required: true),
    DebtFieldDef('interest', 'Tasa de interés anual (%)', DebtFieldType.percent),
    DebtFieldDef('monthly_payment', 'Descuento mensual por nómina', DebtFieldType.money),
    DebtFieldDef('due_date', 'Día de pago mensual', DebtFieldType.day),
    DebtFieldDef('total_installments', 'Cuotas totales', DebtFieldType.number),
    DebtFieldDef('paid_installments', 'Cuotas pagadas', DebtFieldType.number),
  ]),
  DebtTypeSchema('interest_free', 'Deuda familiar / sin interés', Icons.people, [], [
    DebtFieldDef('institution', 'Acreedor (persona)', DebtFieldType.text, required: true),
    DebtFieldDef('balance', 'Valor pendiente', DebtFieldType.money, required: true),
    DebtFieldDef('monthly_payment', 'Pago acordado', DebtFieldType.money),
    DebtFieldDef('due_date', 'Día de pago mensual', DebtFieldType.day),
    DebtFieldDef('total_installments', 'Cuotas totales', DebtFieldType.number),
    DebtFieldDef('paid_installments', 'Cuotas pagadas', DebtFieldType.number),
  ]),
];

List<DebtTypeSchema> debtTypesForCountry(String countryCode) {
  return debtTypes
      .where((t) => t.countries.isEmpty || t.countries.contains(countryCode))
      .toList();
}

DebtTypeSchema debtTypeById(String id) {
  return debtTypes.firstWhere((t) => t.id == id, orElse: () => debtTypes.first);
}

String debtTypeLabel(String id) {
  for (final t in debtTypes) {
    if (t.id == id) return t.label;
  }
  return id;
}

IconData debtTypeIcon(String id) {
  for (final t in debtTypes) {
    if (t.id == id) return t.icon;
  }
  return Icons.receipt_long;
}
