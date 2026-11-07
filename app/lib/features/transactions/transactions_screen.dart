import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_state.dart';
import '../../core/money_widgets.dart';
import '../categories/category_model.dart';
import 'add_transaction_screen.dart';
import 'transaction_model.dart';
import 'transaction_service.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final _service = TransactionService();
  List<Transaction> _transactions = [];
  List<Category> _categories = [];
  bool _loading = true;
  String? _error;
  String _filter = 'all'; // all | income | expense

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
      final list = await _service.listTransactions();
      setState(() => _transactions = list);
    } catch (e) {
      setState(() => _error = e.toString());
    }
    try {
      final cats = await _service.listCategories();
      setState(() => _categories = cats);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  String _formatDate(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    return '$dd/$mm/${d.year}';
  }

  List<Transaction> get _filtered {
    if (_filter == 'all') return _transactions;
    return _transactions.where((t) => t.type == _filter).toList();
  }

  Future<void> _edit(Transaction t) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => _EditTransactionDialog(
        transaction: t,
        categories: _categories,
        onSave: (amount, type, note, categoryId) async {
          await _service.updateTransaction(
            t.id,
            amount: amount,
            type: type,
            note: note,
            categoryId: categoryId,
          );
        },
      ),
    );
    if (mounted) AppState.instance.notifyDataChanged();
  }

  Future<void> _delete(Transaction t) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar movimiento'),
        content: Text(
            '¿Seguro que quieres eliminar este movimiento de ${AppState.instance.symbol}${t.amount.toStringAsFixed(2)}?'),
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
    try {
      await _service.deleteTransaction(t.id);
      if (mounted) AppState.instance.notifyDataChanged();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showCategories() {
    final income = _categories
        .where((c) => c.type == 'income')
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    final expense = _categories
        .where((c) => c.type == 'expense')
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            Text('Categorías disponibles',
                style: Theme.of(ctx).textTheme.titleMedium),
            _categorySection(ctx, 'Ingresos', Icons.arrow_downward,
                AppColors.emerald, income),
            _categorySection(
                ctx, 'Gastos', Icons.arrow_upward, AppColors.coral, expense),
          ],
        ),
      ),
    );
  }

  Widget _categorySection(BuildContext ctx, String title, IconData icon,
      Color color, List<Category> cats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(title,
                style: TextStyle(fontWeight: FontWeight.w700, color: color)),
            const SizedBox(width: 8),
            Text('${cats.length}', style: Theme.of(ctx).textTheme.bodySmall),
          ],
        ),
        const SizedBox(height: 4),
        if (cats.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text('Sin categorías',
                style: Theme.of(ctx).textTheme.bodySmall),
          )
        else
          for (final c in cats)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Text(categoryEmoji(c.name),
                  style: const TextStyle(fontSize: 18)),
              title: Text(c.name),
              trailing: c.monthlyBudget != null && c.monthlyBudget! > 0
                  ? Text(
                      '${AppState.instance.symbol}${c.monthlyBudget!.toStringAsFixed(0)}/mes',
                      style: Theme.of(ctx).textTheme.bodySmall,
                    )
                  : null,
            ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Movimientos'),
        actions: [
          IconButton(
            onPressed: _showCategories,
            icon: const Icon(Icons.category_outlined),
            tooltip: 'Ver categorías',
          ),
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'all', label: Text('Todos')),
                ButtonSegment(value: 'income', label: Text('Ingresos')),
                ButtonSegment(value: 'expense', label: Text('Gastos')),
              ],
              selected: {_filter},
              onSelectionChanged: (s) => setState(() => _filter = s.first),
            ),
          ),
          Expanded(child: _buildList()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
          );
        },
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
    final list = _filtered;
    return RefreshIndicator(
      onRefresh: _load,
      child: list.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                Padding(
                  padding: EdgeInsets.only(top: 120),
                  child: Center(
                    child: Text(
                        'No hay movimientos.\nPulsa + para registrar uno.',
                        textAlign: TextAlign.center),
                  ),
                ),
              ],
            )
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 88),
              itemCount: list.length,
              itemBuilder: (context, index) {
                final t = list[index];
                final isIncome = t.type == 'income';
                return _transactionCard(t, isIncome);
              },
            ),
    );
  }

  Widget _transactionCard(Transaction t, bool isIncome) {
    final color = isIncome ? AppColors.emerald : AppColors.coral;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: ListTile(
        onTap: () => _edit(t),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(
            isIncome ? Icons.arrow_downward : Icons.arrow_upward,
            color: color,
            size: 20,
          ),
        ),
        title: Text(
          t.displayTitle,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          [
            _formatDate(t.date),
            if (t.category != null && t.note != null && t.note!.isNotEmpty)
              t.note!,
          ].join(' · '),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            MoneyText(
              t.amount,
              sign: isIncome,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: color,
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 20),
              onSelected: (v) {
                if (v == 'edit') {
                  _edit(t);
                } else if (v == 'delete') {
                  _delete(t);
                }
              },
              itemBuilder: (ctx) => const [
                PopupMenuItem(value: 'edit', child: Text('Editar')),
                PopupMenuItem(value: 'delete', child: Text('Eliminar')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EditTransactionDialog extends StatefulWidget {
  final Transaction transaction;
  final List<Category> categories;
  final Future<void> Function(
      double amount, String type, String? note, String? categoryId) onSave;

  const _EditTransactionDialog({
    required this.transaction,
    required this.categories,
    required this.onSave,
  });

  @override
  State<_EditTransactionDialog> createState() => _EditTransactionDialogState();
}

class _EditTransactionDialogState extends State<_EditTransactionDialog> {
  late final TextEditingController _amount;
  late final TextEditingController _note;
  late String _type;
  String? _categoryId;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _amount = TextEditingController(
        text: widget.transaction.amount.toStringAsFixed(2));
    _note = TextEditingController(text: widget.transaction.note ?? '');
    _type = widget.transaction.type;
    _categoryId = widget.transaction.category?.id;
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  List<Category> get _filteredCategories =>
      widget.categories.where((c) => c.type == _type).toList();

  Future<void> _save() async {
    final amount = double.tryParse(_amount.text.replaceAll(',', '.'));
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Introduce un monto válido');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSave(amount, _type, _note.text.trim(), _categoryId);
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
      title: const Text('Editar movimiento'),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                    value: 'expense',
                    label: Text('Gasto'),
                    icon: Icon(Icons.arrow_upward)),
                ButtonSegment(
                    value: 'income',
                    label: Text('Ingreso'),
                    icon: Icon(Icons.arrow_downward)),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() {
                _type = s.first;
                _categoryId = null;
              }),
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
            DropdownButtonFormField<String>(
              initialValue: _categoryId,
              decoration: const InputDecoration(labelText: 'Categoría'),
              items: _filteredCategories
                  .map((c) => DropdownMenuItem(
                      value: c.id,
                      child: Text('${categoryEmoji(c.name)} ${c.name}')))
                  .toList(),
              onChanged: (v) => setState(() => _categoryId = v),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _note,
              decoration: const InputDecoration(labelText: 'Nota (opcional)'),
            ),
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
}
