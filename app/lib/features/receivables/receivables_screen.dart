import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_state.dart';
import '../../core/money_widgets.dart';
import '../transactions/transaction_service.dart';
import 'receivable_model.dart';
import 'receivable_service.dart';

class ReceivablesScreen extends StatefulWidget {
  const ReceivablesScreen({super.key});

  @override
  State<ReceivablesScreen> createState() => _ReceivablesScreenState();
}

class _ReceivablesScreenState extends State<ReceivablesScreen> {
  final _service = ReceivableService();
  final _txService = TransactionService();
  List<Receivable> _receivables = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    AppState.instance.dataVersionNotifier.addListener(_onDataChanged);
    _load();
  }

  @override
  void dispose() {
    AppState.instance.dataVersionNotifier.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _service.listReceivables();
      setState(() => _receivables = list);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  double get _totalPending {
    return _receivables
        .where((r) => r.status == 'pending')
        .fold(0, (s, r) => s + r.amount);
  }

  String _formatDate(DateTime? d) {
    if (d == null) return 'Sin fecha';
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    return '$dd/$mm/${d.year}';
  }

  Future<void> _create() async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => _ReceivableForm(
          onSave: (person, amount, note, dueDate, details) async {
        await _service.createReceivable(
          person: person,
          amount: amount,
          note: note,
          dueDate: dueDate,
          details: details,
        );
      }),
    );
    if (mounted) AppState.instance.notifyDataChanged();
  }

  Future<void> _collect(Receivable r) async {
    final controller = TextEditingController(
        text: r.amount.toStringAsFixed(2));
    final amount = await showDialog<double>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Registrar cobro'),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Monto cobrado',
              prefixText: '${AppState.instance.symbol} ',
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancelar')),
            FilledButton(
              onPressed: () {
                final v = double.tryParse(
                    controller.text.replaceAll(',', '.'));
                Navigator.of(ctx).pop(v);
              },
              child: const Text('Cobrar'),
            ),
          ],
        ),
      ),
    );
    if (amount == null || amount <= 0) return;
    try {
      await _service.collectReceivable(r.id, amount);
      if (mounted) AppState.instance.notifyDataChanged();
      _askRegisterIncome(r.person, amount);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  /// Tras registrar un cobro, ofrece registrarlo como ingreso.
  Future<void> _askRegisterIncome(String person, double amount) async {
    final nameController = TextEditingController(text: 'Cobro $person');
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Registrar como ingreso?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
                '${AppState.instance.formatAmount(amount)} de "$person"'),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              autofocus: true,
              decoration:
                  const InputDecoration(labelText: 'Nombre del ingreso'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Ahora no'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(ctx).pop(nameController.text.trim()),
            child: const Text('Registrar ingreso'),
          ),
        ],
      ),
    );
    if (result == null || !mounted) return;
    try {
      await _txService.createTransaction(
        amount: amount,
        type: 'income',
        note: result.isEmpty ? 'Cobro $person' : result,
      );
      AppState.instance.notifyDataChanged();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ingreso registrado')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _edit(Receivable r) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => _ReceivableForm(
        initial: r,
        onSave: (person, amount, note, dueDate, details) async {
          await _service.updateReceivable(
            r.id,
            person: person,
            amount: amount,
            note: note,
            dueDate: dueDate,
            details: details,
          );
        },
      ),
    );
    if (mounted) AppState.instance.notifyDataChanged();
  }

  Future<void> _delete(Receivable r) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar cobro'),
        content: Text('¿Eliminar el cobro de "${r.person}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.coral),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await _service.deleteReceivable(r.id);
    if (mounted) AppState.instance.notifyDataChanged();
  }

  Future<void> _toggleStatus(Receivable r) async {
    final newStatus = r.status == 'collected' ? 'pending' : 'collected';
    await _service.updateReceivable(r.id, status: newStatus);
    if (mounted) AppState.instance.notifyDataChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cobros'),
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: Column(
        children: [
          if (!_loading && _error == null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.emerald.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Pendiente por cobrar',
                      style: TextStyle(fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(
                    AppState.instance.formatAmount(_totalPending),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.emerald,
                    ),
                  ),
                ],
              ),
            ),
          Expanded(child: _buildList()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _create,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildList() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text('Error: $_error'));
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: _receivables.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                Padding(
                  padding: EdgeInsets.only(top: 120),
                  child: Center(
                    child: Text(
                        'No tienes cobros pendientes.\nPulsa + para registrar uno.',
                        textAlign: TextAlign.center),
                  ),
                ),
              ],
            )
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 88),
              itemCount: _receivables.length,
              itemBuilder: (context, index) {
        final r = _receivables[index];
        final collected = r.status == 'collected';
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: ListTile(
            onTap: () => _edit(r),
            leading: CircleAvatar(
              backgroundColor: (collected ? AppColors.emerald : AppColors.amber)
                  .withValues(alpha: 0.15),
              child: Icon(
                collected ? Icons.check_circle : Icons.person_outline,
                color: collected ? AppColors.emerald : AppColors.amber,
              ),
            ),
            title: Text(
              r.person,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                decoration: collected ? TextDecoration.lineThrough : null,
              ),
            ),
            subtitle: Text([
              _formatDate(r.dueDate),
              if (r.note != null && r.note!.isNotEmpty) r.note!,
            ].join(' · ')),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                MoneyText(r.amount,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: collected ? AppColors.emerald : AppColors.amber,
                    )),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 20),
                  onSelected: (v) {
                    if (v == 'collect') {
                      _collect(r);
                    } else if (v == 'toggle') {
                      _toggleStatus(r);
                    } else if (v == 'edit') {
                      _edit(r);
                    } else if (v == 'delete') {
                      _delete(r);
                    }
                  },
                  itemBuilder: (ctx) => [
                    if (!collected)
                      const PopupMenuItem(
                          value: 'collect', child: Text('Registrar cobro')),
                    PopupMenuItem(
                      value: 'toggle',
                      child: Text(collected ? 'Marcar pendiente' : 'Marcar cobrado'),
                    ),
                    const PopupMenuItem(value: 'edit', child: Text('Editar')),
                    const PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                  ],
                ),
              ],
            ),
          ),
        );
      },
      ),
    );
  }
}

class _ReceivableForm extends StatefulWidget {
  final Receivable? initial;
  final Future<void> Function(String person, double amount, String? note,
      DateTime? dueDate, Map<String, dynamic>? details) onSave;

  const _ReceivableForm({this.initial, required this.onSave});

  @override
  State<_ReceivableForm> createState() => _ReceivableFormState();
}

class _ReceivableFormState extends State<_ReceivableForm> {
  late final TextEditingController _person;
  late final TextEditingController _amount;
  late final TextEditingController _note;
  late final TextEditingController _interest;
  late final TextEditingController _quota;
  late final TextEditingController _months;
  DateTime? _dueDate;

  // Tipo de cobro: 'simple' | 'custom'
  String _type = 'simple';
  final Set<String> _customFields = {};

  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _person = TextEditingController(text: widget.initial?.person ?? '');
    _amount = TextEditingController(
        text: widget.initial?.amount.toStringAsFixed(2) ?? '');
    _note = TextEditingController(text: widget.initial?.note ?? '');
    _dueDate = widget.initial?.dueDate;

    final details = widget.initial?.details;
    _interest = TextEditingController(
        text: details?['interest_monthly']?.toString() ?? '');
    _quota = TextEditingController(text: details?['quota']?.toString() ?? '');
    _months = TextEditingController(text: details?['months']?.toString() ?? '');

    if (details != null) {
      _type = 'custom';
      if (details['interest_monthly'] != null) {
        _customFields.add('interest_monthly');
      }
      if (details['quota'] != null) _customFields.add('quota');
      if (details['months'] != null) _customFields.add('months');
    }
  }

  @override
  void dispose() {
    _person.dispose();
    _amount.dispose();
    _note.dispose();
    _interest.dispose();
    _quota.dispose();
    _months.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  double? _num(TextEditingController c) =>
      double.tryParse(c.text.replaceAll(',', '.'));

  Map<String, dynamic>? _buildDetails() {
    if (_type != 'custom') return null;
    final details = <String, dynamic>{};
    if (_customFields.contains('interest_monthly')) {
      details['interest_monthly'] = _num(_interest);
    }
    if (_customFields.contains('quota')) {
      details['quota'] = _num(_quota);
    }
    if (_customFields.contains('months')) {
      details['months'] = int.tryParse(_months.text);
    }
    return details.isEmpty ? null : details;
  }

  Future<void> _save() async {
    final person = _person.text.trim();
    final amount = double.tryParse(_amount.text.replaceAll(',', '.'));
    if (person.isEmpty) {
      setState(() => _error = 'Introduce el nombre de la persona');
      return;
    }
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Introduce un monto válido');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSave(
          person, amount, _note.text.trim(), _dueDate, _buildDetails());
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initial == null ? 'Nuevo cobro' : 'Editar cobro'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Viñeta de tipo de cobro
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                    value: 'simple',
                    label: Text('Simple'),
                    icon: Icon(Icons.person_outline)),
                ButtonSegment(
                    value: 'custom',
                    label: Text('Personalizado'),
                    icon: Icon(Icons.tune)),
              ],
              selected: {_type},
              onSelectionChanged: (s) =>
                  setState(() => _type = s.first),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _person,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Persona'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amount,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Monto',
                prefixText: '${AppState.instance.symbol} ',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _note,
              decoration: const InputDecoration(labelText: 'Nota (opcional)'),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event),
              title: Text(
                _dueDate == null
                    ? 'Fecha de cobro (opcional)'
                    : 'Fecha: ${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}',
              ),
              trailing: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: _dueDate == null
                    ? null
                    : () => setState(() => _dueDate = null),
              ),
              onTap: _pickDate,
            ),
            if (_type == 'custom') ...[
              const SizedBox(height: 16),
              const Divider(),
              Text('Campos personalizados',
                  style: Theme.of(context).textTheme.titleSmall),
              _check('interest_monthly', 'Interés mensual (%)'),
              _check('quota', 'Cuota'),
              _check('months', 'Meses'),
              if (_customFields.contains('interest_monthly')) ...[
                const SizedBox(height: 8),
                TextField(
                  controller: _interest,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Interés mensual',
                    suffixText: '%',
                  ),
                ),
              ],
              if (_customFields.contains('quota')) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _quota,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Cuota',
                    prefixText: '${AppState.instance.symbol} ',
                  ),
                ),
              ],
              if (_customFields.contains('months')) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _months,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Meses'),
                ),
              ],
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar')),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Guardar'),
        ),
      ],
    );
  }

  Widget _check(String key, String label) {
    final on = _customFields.contains(key);
    return CheckboxListTile(
      value: on,
      onChanged: (v) => setState(() {
        if (v == true) {
          _customFields.add(key);
        } else {
          _customFields.remove(key);
        }
      }),
      title: Text(label),
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
      dense: true,
    );
  }
}
