import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../categories/category_model.dart';
import 'transaction_service.dart';

class AddTransactionScreen extends StatefulWidget {
  final String initialType;
  const AddTransactionScreen({super.key, this.initialType = 'expense'});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _service = TransactionService();
  final _amount = TextEditingController();
  final _note = TextEditingController();

  late String _type = widget.initialType;
  List<Category> _categories = [];
  String? _categoryId;
  bool _loadingCategories = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final list = await _service.listCategories();
      setState(() => _categories = list);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loadingCategories = false);
    }
  }

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
      await _service.createTransaction(
        amount: amount,
        type: _type,
        note: _note.text.trim(),
        categoryId: _categoryId,
      );
      AppState.instance.notifyDataChanged();
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _showNewCategoryDialog() async {
    final nameController = TextEditingController();
    final budgetController = TextEditingController();
    final created = await showDialog<Category>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(_type == 'income'
            ? 'Nueva categoría de ingreso'
            : 'Nueva categoría de gasto'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: budgetController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Presupuesto mensual (opcional)',
                prefixText: '${AppState.instance.symbol} ',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              try {
                final category = await _service.createCategory(
                  name: name,
                  type: _type,
                  monthlyBudget: double.tryParse(
                    budgetController.text.replaceAll(',', '.'),
                  ),
                );
                AppState.instance.notifyDataChanged();
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop(category);
                }
              } catch (e) {
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (created != null && mounted) {
      setState(() {
        _categories.add(created);
        _categoryId = created.id;
      });
    }
  }

  List<Category> get _filteredCategories =>
      _categories.where((c) => c.type == _type).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo movimiento')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
              onSelectionChanged: (s) => setState(() => _type = s.first),
            ),
            const SizedBox(height: 24),
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
            _loadingCategories
                ? const Center(child: CircularProgressIndicator())
                : DropdownButtonFormField<String>(
                    initialValue: _categoryId,
                    decoration: const InputDecoration(labelText: 'Categoría'),
                    items: _filteredCategories
                        .map((c) => DropdownMenuItem(
                              value: c.id,
                              child: Text('${categoryEmoji(c.name)} ${c.name}'),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _categoryId = v),
                  ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _showNewCategoryDialog,
                icon: const Icon(Icons.add),
                label: const Text('Nueva categoría'),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _note,
              decoration: const InputDecoration(labelText: 'Nota (opcional)'),
            ),
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
                  : const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}
