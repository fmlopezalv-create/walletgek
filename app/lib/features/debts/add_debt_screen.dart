import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import 'debt_calculations.dart';
import 'debt_colors.dart';
import 'debt_service.dart';
import 'debt_types.dart';

class AddDebtScreen extends StatefulWidget {
  const AddDebtScreen({super.key});

  @override
  State<AddDebtScreen> createState() => _AddDebtScreenState();
}

class _AddDebtScreenState extends State<AddDebtScreen> {
  final _service = DebtService();
  DebtTypeSchema? _type; // null = paso 1 (elegir categoría)
  bool _isCustom = false;
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, String> _choices = {};
  final Set<String> _customFields = {
    'institution',
    'interest',
    'monthly_payment',
    'due_date',
  };
  bool _saving = false;
  String? _error;
  String? _pendingTypeId;
  String? _color;

  static const _autoCalcKeys = {
    'balance',
    'interest',
    'monthly_interest',
    'total_installments',
    'monthly_payment',
  };

  bool _calculating = false;
  String? _suggestionLabel;
  String? _suggestionValue;
  bool _suggestionIsMoney = false;
  String? _suggestionField;

  TextEditingController _ctrl(String key) {
    return _controllers.putIfAbsent(key, () {
      final c = TextEditingController();
      if (_autoCalcKeys.contains(key)) {
        c.addListener(_onFieldChanged);
      }
      return c;
    });
  }

  void _onFieldChanged() {
    if (_calculating) return;
    _calculating = true;
    try {
      _computeSuggestion();
    } finally {
      _calculating = false;
    }
  }

  double? _effectiveAnnualRate() {
    final annual = _num('interest');
    if (annual != null) return annual;
    final monthly = _num('monthly_interest');
    if (monthly != null) return monthly * 12;
    return null;
  }

  void _computeSuggestion() {
    final balance = _num('balance');
    if (balance == null || balance <= 0) {
      _clearSuggestion();
      return;
    }
    final annualRate = _effectiveAnnualRate() ?? 0;

    final totalInstallments =
        int.tryParse(_ctrl('total_installments').text.trim());
    final monthlyPayment =
        double.tryParse(_ctrl('monthly_payment').text.replaceAll(',', '.'));

    final hasTotal = totalInstallments != null && totalInstallments > 0;
    final hasPayment = monthlyPayment != null && monthlyPayment > 0;

    // balance + interés + cuotas totales → sugiere cuota mensual
    if (hasTotal && !hasPayment) {
      final pmt = monthlyPaymentFromPrincipal(
        principal: balance,
        annualRatePercent: annualRate,
        months: totalInstallments,
      );
      if (pmt > 0) {
        setState(() {
          _suggestionLabel = 'Cuota mensual';
          _suggestionValue = pmt.toStringAsFixed(2);
          _suggestionIsMoney = true;
          _suggestionField = 'monthly_payment';
        });
        return;
      }
    }
    // balance + interés + cuota mensual → sugiere cuotas totales
    else if (hasPayment && !hasTotal) {
      final n = monthsFromPayment(
        principal: balance,
        annualRatePercent: annualRate,
        payment: monthlyPayment,
      );
      if (n != null) {
        setState(() {
          _suggestionLabel = 'Cuotas totales';
          _suggestionValue = n.toString();
          _suggestionIsMoney = false;
          _suggestionField = 'total_installments';
        });
        return;
      }
    }
    _clearSuggestion();
  }

  void _clearSuggestion() {
    if (_suggestionField == null) return;
    setState(() {
      _suggestionLabel = null;
      _suggestionValue = null;
      _suggestionField = null;
    });
  }

  void _applySuggestion() {
    final field = _suggestionField;
    final value = _suggestionValue;
    if (field == null || value == null) return;
    _calculating = true;
    _ctrl(field).text = value;
    _calculating = false;
    _clearSuggestion();
  }

  double? _num(String key) =>
      double.tryParse(_ctrl(key).text.replaceAll(',', '.'));

  /// Convierte el día del mes seleccionado (1-31) en la próxima fecha de
  /// vencimiento. Si el día ya pasó este mes, usa el mes siguiente.
  DateTime? _dayToDate(String? dayStr) {
    if (dayStr == null) return null;
    final day = int.tryParse(dayStr);
    if (day == null || day < 1 || day > 31) return null;
    final now = DateTime.now();
    var date = DateTime(now.year, now.month, day.clamp(1, 28));
    if (date.isBefore(DateTime(now.year, now.month, now.day))) {
      date = DateTime(now.year, now.month + 1, day.clamp(1, 28));
    }
    return date;
  }

  bool _visible(DebtFieldDef f) {
    if (f.showIfKey == null) return true;
    return _choices[f.showIfKey] == f.showIfValue;
  }

  void _selectType(DebtTypeSchema t) {
    setState(() {
      _type = t;
      _isCustom = false;
      _controllers.clear();
      _choices.clear();
      _error = null;
    });
  }

  void _selectCustom() {
    setState(() {
      _type = null;
      _isCustom = true;
      _controllers.clear();
      _choices.clear();
      _error = null;
    });
  }

  Future<void> _save() async {
    final balance = _num('balance');
    if (balance == null || balance <= 0) {
      setState(() => _error = 'Introduce el valor pendiente');
      return;
    }

    String typeId;
    String? institution;
    String? status;
    int? monthsLate;
    String? paymentType;
    double interest = 0;
    double minimumPayment = 0;
    int? totalInstallments;
    int paidInstallments = 0;
    DateTime? dueDate;
    final details = <String, dynamic>{};

    if (_isCustom) {
      final customName = _ctrl('custom_name').text.trim();
      if (customName.isEmpty) {
        setState(() => _error = 'Escribe el nombre del tipo de deuda');
        return;
      }
      typeId = customName;
      if (_customFields.contains('institution')) {
        final v = _ctrl('institution').text.trim();
        institution = v.isEmpty ? null : v;
      }
      if (_customFields.contains('monthly_interest')) {
        final monthly = _num('monthly_interest') ?? 0;
        interest = monthly * 12; // convertir mensual a anual para el plan
        details['interest_period'] = 'monthly';
      } else if (_customFields.contains('interest')) {
        interest = _num('interest') ?? 0;
      }
      if (_customFields.contains('monthly_payment')) {
        minimumPayment = _num('monthly_payment') ?? 0;
      }
      if (_customFields.contains('due_date')) {
        dueDate = _dayToDate(_choices['due_date']);
      }
      if (_customFields.contains('total_installments')) {
        totalInstallments = int.tryParse(_ctrl('total_installments').text);
      }
      if (_customFields.contains('paid_installments')) {
        paidInstallments =
            int.tryParse(_ctrl('paid_installments').text) ?? 0;
      }
    } else {
      typeId = _type!.id;
      for (final f in _type!.fields) {
        final text = _ctrl(f.key).text.trim();
        switch (f.key) {
          case 'institution':
            institution = text.isEmpty ? null : text;
            break;
          case 'interest':
            interest = _num(f.key) ?? 0;
            break;
          case 'monthly_payment':
            minimumPayment = _num(f.key) ?? 0;
            break;
          case 'status':
            status = _choices[f.key] == 'Atrasado' ? 'late' : 'up_to_date';
            if (status == 'late') {
              monthsLate = (_num('months_late') ?? 0).toInt();
            }
            break;
          case 'months_late':
            break; // se maneja con status
          case 'payment_type':
            final p = _choices[f.key];
            paymentType = p == 'Pago mínimo'
                ? 'minimum'
                : p == 'Pago de contado'
                    ? 'full'
                    : 'due_date';
            break;
          case 'total_installments':
            totalInstallments = int.tryParse(text);
            break;
          case 'paid_installments':
            paidInstallments = int.tryParse(text) ?? 0;
            break;
          case 'due_date':
            dueDate = _dayToDate(_choices[f.key]);
            break;
          default:
            if (text.isNotEmpty) {
              final n = _num(f.key);
              details[f.key] = n ?? text;
            }
        }
      }
    }

    final name = (institution != null && institution.isNotEmpty)
        ? institution
        : (_isCustom ? _ctrl('custom_name').text.trim() : _type!.label);

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _service.createDebt(
        name: name,
        type: typeId,
        color: _color,
        balance: balance,
        interestRate: interest,
        minimumPayment: minimumPayment,
        dueDate: dueDate,
        institution: institution,
        status: status,
        monthsLate: monthsLate,
        paymentType: paymentType,
        totalInstallments: totalInstallments,
        paidInstallments: paidInstallments,
        details: details.isEmpty ? null : details,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _isCustom
        ? 'Deuda personalizada'
        : (_type != null ? _type!.label : 'Nueva deuda');
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: (_type != null || _isCustom)
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() {
                  _type = null;
                  _isCustom = false;
                  _error = null;
                  _pendingTypeId = null;
                }),
              )
            : null,
      ),
      body: (_type == null && !_isCustom)
          ? _buildTypeSelection()
          : Stack(
              children: [
                _buildForm(),
                if (_suggestionField != null)
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: _SuggestionBubble(
                      label: _suggestionLabel!,
                      value: _suggestionIsMoney
                          ? '${AppState.instance.symbol}$_suggestionValue'
                          : _suggestionValue!,
                      onUse: _applySuggestion,
                      onDismiss: _clearSuggestion,
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildTypeSelection() {
    final types = debtTypesForCountry(AppState.instance.countryCode);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Selecciona el tipo de deuda',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _pendingTypeId,
            decoration: const InputDecoration(
              labelText: 'Categoría',
              border: OutlineInputBorder(),
            ),
            items: [
              ...types.map((t) => DropdownMenuItem(
                    value: t.id,
                    child: Row(
                      children: [
                        Icon(t.icon, size: 20),
                        const SizedBox(width: 8),
                        Text(t.label),
                      ],
                    ),
                  )),
              const DropdownMenuItem(
                value: 'custom',
                child: Row(
                  children: [
                    Icon(Icons.edit_note, size: 20),
                    SizedBox(width: 8),
                    Text('Otra (personalizada)'),
                  ],
                ),
              ),
            ],
            onChanged: (v) => setState(() => _pendingTypeId = v),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _pendingTypeId == null
                ? null
                : () {
                    if (_pendingTypeId == 'custom') {
                      _selectCustom();
                    } else {
                      _selectType(debtTypeById(_pendingTypeId!));
                    }
                  },
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_isCustom) ...[
            TextField(
              controller: _ctrl('custom_name'),
              decoration:
                  const InputDecoration(labelText: 'Nombre del tipo de deuda'),
            ),
            const SizedBox(height: 12),
            Text('Campos a incluir:',
                style: Theme.of(context).textTheme.titleSmall),
            _check('institution', 'Institución / acreedor'),
            _check('interest', 'Tasa de interés anual (%)',
                exclusiveWith: 'monthly_interest'),
            _check('monthly_interest', 'Interés mensual (%)',
                exclusiveWith: 'interest'),
            _check('monthly_payment', 'Pago mensual'),
            _check('total_installments', 'Cuotas totales'),
            _check('paid_installments', 'Cuotas pagadas'),
            const SizedBox(height: 16),
          ],
          ..._formFields(),
          const SizedBox(height: 8),
          Text('Color', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          _colorPicker(),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(_error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Guardar deuda'),
          ),
        ],
      ),
    );
  }

  Widget _check(String key, String label, {String? exclusiveWith}) {
    final on = _customFields.contains(key);
    return CheckboxListTile(
      value: on,
      onChanged: (v) => setState(() {
        if (v == true) {
          _customFields.add(key);
          if (exclusiveWith != null) _customFields.remove(exclusiveWith);
        } else {
          _customFields.remove(key);
        }
      }),
      title: Text(label),
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _colorPicker() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: debtColors.map((c) {
        final selected = _color == colorToHex(c);
        return GestureDetector(
          onTap: () => setState(() => _color = colorToHex(c)),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: c,
              shape: BoxShape.circle,
              border: selected
                  ? Border.all(color: Colors.black, width: 3)
                  : null,
            ),
            child: selected
                ? const Icon(Icons.check, color: Colors.white, size: 20)
                : null,
          ),
        );
      }).toList(),
    );
  }

  List<Widget> _formFields() {
    final widgets = <Widget>[];
    void gap() => widgets.add(const SizedBox(height: 16));

    if (_isCustom) {
      if (_customFields.contains('institution')) {
        widgets.add(_text('institution', 'Institución / acreedor'));
        gap();
      }
      widgets.add(_money('balance', 'Valor pendiente'));
      gap();
      if (_customFields.contains('monthly_interest')) {
        widgets.add(_percent('monthly_interest', 'Tasa de interés mensual'));
        gap();
      } else if (_customFields.contains('interest')) {
        widgets.add(_percent('interest', 'Tasa de interés anual'));
        gap();
      }
      if (_customFields.contains('monthly_payment')) {
        widgets.add(_money('monthly_payment', 'Pago mensual'));
        gap();
      }
      if (_customFields.contains('total_installments')) {
        widgets.add(_number('total_installments', 'Cuotas totales'));
        gap();
      }
      if (_customFields.contains('paid_installments')) {
        widgets.add(_number('paid_installments', 'Cuotas pagadas'));
        gap();
      }
      return widgets;
    }

    for (final f in _type!.fields) {
      if (!_visible(f)) continue;
      widgets.add(_fieldWidget(f));
      gap();
    }
    return widgets;
  }

  Widget _fieldWidget(DebtFieldDef f) {
    switch (f.type) {
      case DebtFieldType.text:
        return _text(f.key, f.label);
      case DebtFieldType.money:
        return _money(f.key, f.label);
      case DebtFieldType.percent:
        return _percent(f.key, f.label);
      case DebtFieldType.number:
        return _number(f.key, f.label);
      case DebtFieldType.months:
        return _number(f.key, f.label);
      case DebtFieldType.choice:
        return _choice(f.key, f.label, f.choices ?? []);
      case DebtFieldType.day:
        return _day(f.key, f.label);
    }
  }

  Widget _text(String key, String label) => TextField(
        controller: _ctrl(key),
        decoration: InputDecoration(labelText: label),
      );

  Widget _money(String key, String label) => TextField(
        controller: _ctrl(key),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          prefixText: '${AppState.instance.symbol} ',
        ),
      );

  Widget _percent(String key, String label) => TextField(
        controller: _ctrl(key),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          suffixText: '%',
        ),
      );

  Widget _number(String key, String label) => TextField(
        controller: _ctrl(key),
        keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: label),
      );

  Widget _day(String key, String label) {
    final days = List.generate(31, (i) => '${i + 1}');
    return DropdownButtonFormField<String>(
      initialValue: _choices[key],
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: days
          .map((d) => DropdownMenuItem(value: d, child: Text('Día $d')))
          .toList(),
      onChanged: (v) => setState(() {
        if (v != null) {
          _choices[key] = v;
        } else {
          _choices.remove(key);
        }
      }),
    );
  }

  Widget _choice(String key, String label, List<String> options) {
    return DropdownButtonFormField<String>(
      initialValue: _choices[key],
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: options
          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
          .toList(),
      onChanged: (v) => setState(() {
        if (v != null) {
          _choices[key] = v;
        } else {
          _choices.remove(key);
        }
      }),
    );
  }
}

class _SuggestionBubble extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onUse;
  final VoidCallback onDismiss;
  const _SuggestionBubble({
    required this.label,
    required this.value,
    required this.onUse,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(12),
      color: scheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.lightbulb_outline),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Sugerencia',
                      style: Theme.of(context).textTheme.labelSmall),
                  Text('$label: $value',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            TextButton(onPressed: onUse, child: const Text('Usar')),
            IconButton(
              onPressed: onDismiss,
              icon: const Icon(Icons.close, size: 18),
              tooltip: 'Descartar',
            ),
          ],
        ),
      ),
    );
  }
}
