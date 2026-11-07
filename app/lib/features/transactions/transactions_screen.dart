import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_state.dart';
import '../../core/micro_animations.dart';
import '../../core/money_widgets.dart';
import '../../core/skeleton.dart';
import '../../core/storage.dart';
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
  String _style = 'fintech'; // fintech | cards | dashboard

  @override
  void initState() {
    super.initState();
    AppState.instance.dataVersionNotifier.addListener(_onDataChanged);
    _load();
    _loadStyle();
  }

  Future<void> _loadStyle() async {
    final saved = await TokenStorage.readTxStyle();
    if (saved != null && mounted) {
      setState(() => _style = saved);
    }
  }

  Future<void> _saveStyle() async {
    await TokenStorage.saveTxStyle(_style);
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

  void _openStyleSettings() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text('Estilo visual de la lista',
                  style: Theme.of(ctx).textTheme.titleMedium),
            ),
            _styleOption(ctx, 'fintech', Icons.view_agenda_outlined,
                'Fintech minimalista', 'Filas limpias y compactas'),
            _styleOption(ctx, 'cards', Icons.credit_card, 'Tarjetas con color',
                'Tarjetas con acento según tipo'),
            _styleOption(ctx, 'dashboard', Icons.dashboard_outlined,
                'Dashboard', 'Resumen + tarjetas animadas'),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _styleOption(BuildContext ctx, String value, IconData icon,
      String title, String subtitle) {
    final selected = _style == value;
    return ListTile(
      leading: Icon(icon, color: selected ? AppColors.emerald : null),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: selected
          ? const Icon(Icons.check, color: AppColors.emerald)
          : null,
      onTap: () async {
        Navigator.of(ctx).pop();
        if (_style != value) {
          setState(() => _style = value);
          await _saveStyle();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Movimientos'),
        actions: [
          IconButton(
            onPressed: _openStyleSettings,
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Estilo de la lista',
          ),
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
              showSelectedIcon: false,
              onSelectionChanged: (s) => setState(() => _filter = s.first),
            ),
          ),
          if (!_loading && _error == null) _summaryHeader(),
          Expanded(child: _buildList()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
          );
        },
        child: const PressableScale(child: Icon(Icons.add)),
      ),
    );
  }

  Widget _buildList() {
    if (_loading) {
      return const SkeletonList();
    }
    if (_error != null) {
      return Center(child: Text('Error: $_error'));
    }
    final list = _filtered;
    return RippleRefresh(
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
          : _style == 'fintech'
              ? ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(0, 4, 0, 88),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => Divider(
                    height: 1,
                    thickness: 0.5,
                    color: Theme.of(context)
                        .dividerColor
                        .withValues(alpha: 0.4),
                  ),
                  itemBuilder: (context, index) {
                    final t = list[index];
                    return FadeIn(
                      delay: Duration(milliseconds: index * 30),
                      child: _fintechTile(t, t.type == 'income'),
                    );
                  },
                )
              : ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(0, 4, 0, 88),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final t = list[index];
                    final isIncome = t.type == 'income';
                    return _style == 'cards'
                        ? FadeIn(
                            delay: Duration(milliseconds: index * 30),
                            child: _cardTile(t, isIncome),
                          )
                        : _dashboardTile(t, isIncome, index);
                  },
                ),
    );
  }

  String _txEmoji(Transaction t, bool isIncome) {
    if (t.category != null) return categoryEmoji(t.category!.name);
    return isIncome ? '💰' : '🧾';
  }

  /// Fecha · nota (la nota solo si hay categoría, para no duplicar el título).
  String _subtitleOf(Transaction t) {
    return [
      _formatDate(t.date),
      if (t.category != null && t.note != null && t.note!.isNotEmpty)
        t.note!,
    ].join(' · ');
  }

  Widget _txMenu(Transaction t) {
    return PopupMenuButton<String>(
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
    );
  }

  // Opción 1 — Fintech minimalista.
  Widget _fintechTile(Transaction t, bool isIncome) {
    final color = isIncome ? AppColors.emerald : AppColors.coral;
    return InkWell(
      onTap: () => _edit(t),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Text(_txEmoji(t, isIncome),
                  style: const TextStyle(fontSize: 18)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.displayTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(_subtitleOf(t),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            const SizedBox(width: 8),
            MoneyText(
              t.amount,
              sign: isIncome,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: color,
              ),
            ),
            const SizedBox(width: 4),
            _txMenu(t),
          ],
        ),
      ),
    );
  }

  // Opción 2 — Tarjetas con jerarquía y color.
  Widget _cardTile(Transaction t, bool isIncome) {
    final color = isIncome ? AppColors.emerald : AppColors.coral;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 0,
      color: color.withValues(alpha: 0.04),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: color.withValues(alpha: 0.5), width: 1.2),
      ),
      child: ListTile(
        onTap: () => _edit(t),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Text(_txEmoji(t, isIncome),
              style: const TextStyle(fontSize: 18)),
        ),
        title: Text(t.displayTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(_subtitleOf(t),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            MoneyText(
              t.amount,
              sign: isIncome,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: color,
              ),
            ),
            const SizedBox(width: 4),
            _txMenu(t),
          ],
        ),
      ),
    );
  }

  // Opción 4 — Dashboard con resumen y tarjetas animadas.
  Widget _dashboardTile(Transaction t, bool isIncome, int index) {
    final color = isIncome ? AppColors.emerald : AppColors.coral;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 260 + (index.clamp(0, 20) * 40)),
      builder: (context, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(
          offset: Offset(0, (1 - v) * 16),
          child: child,
        ),
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        child: ListTile(
          onTap: () => _edit(t),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          leading: CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.15),
            child: Text(_txEmoji(t, isIncome),
                style: const TextStyle(fontSize: 18)),
          ),
          title: Text(t.displayTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(_subtitleOf(t),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              MoneyText(
                t.amount,
                sign: isIncome,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: color,
                ),
              ),
              const SizedBox(width: 4),
              _txMenu(t),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryHeader() {
    final income = _transactions
        .where((t) => t.type == 'income')
        .fold<double>(0, (s, t) => s + t.amount);
    final expense = _transactions
        .where((t) => t.type == 'expense')
        .fold<double>(0, (s, t) => s + t.amount);
    final balance = income - expense;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(child: _stat('Ingresos', income, AppColors.emerald)),
          _statDivider(),
          Expanded(child: _stat('Gastos', expense, AppColors.coral)),
          _statDivider(),
          Expanded(child: _stat('Balance', balance, AppColors.slate)),
        ],
      ),
    );
  }

  Widget _stat(String label, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              AppState.instance.formatAmount(value),
              maxLines: 1,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statDivider() {
    return Container(
      width: 1,
      height: 26,
      color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
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
