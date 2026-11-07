import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_state.dart';
import '../../core/storage.dart';
import '../auth/auth_service.dart';
import '../debts/debt_colors.dart';
import '../transactions/transaction_service.dart';
import 'budget_model.dart';
import 'budget_service.dart';
import 'budget_view_settings.dart';

const _chartTypes = ['donut', 'pie', 'bar', 'hbar', 'line'];
const _monthNames = [
  'Enero',
  'Febrero',
  'Marzo',
  'Abril',
  'Mayo',
  'Junio',
  'Julio',
  'Agosto',
  'Septiembre',
  'Octubre',
  'Noviembre',
  'Diciembre',
];

String _chartTypeLabel(String t) {
  switch (t) {
    case 'pie':
      return 'Pastel';
    case 'bar':
      return 'Barras verticales';
    case 'hbar':
      return 'Barras horizontales';
    case 'line':
      return 'Línea';
    default:
      return 'Dona';
  }
}

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final _service = BudgetService();
  final _categoryService = TransactionService();
  final _auth = AuthService();
  BudgetSummary? _summary;
  bool _loading = true;
  String? _error;
  BudgetViewSettings _settings = BudgetViewSettings();
  DateTime _selectedMonth =
      DateTime(DateTime.now().year, DateTime.now().month);
  int _categoryPickerKey = 0;

  String get _monthKey =>
      '${_selectedMonth.year}-${_selectedMonth.month.toString().padLeft(2, '0')}';

  String get _monthLabel => '${_monthNames[_selectedMonth.month - 1]} ${_selectedMonth.year}';

  @override
  void initState() {
    super.initState();
    AppState.instance.dataVersionNotifier.addListener(_onDataChanged);
    _loadSettings();
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

  Future<void> _loadSettings() async {
    final raw = await TokenStorage.readBudgetView();
    if (raw == null) return;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      if (mounted) {
        setState(() => _settings = BudgetViewSettings.fromJson(json));
      }
    } catch (_) {}
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final s = await _service.getSummary(month: _monthKey);
      setState(() => _summary = s);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _changeMonth(int delta) {
    setState(() {
      _selectedMonth =
          DateTime(_selectedMonth.year, _selectedMonth.month + delta);
    });
    _load();
  }

  Future<void> _saveSettings() async {
    await TokenStorage.saveBudgetView(jsonEncode(_settings.toJson()));
  }

  Future<void> _openSettings() async {
    final s = BudgetViewSettings(
      showChart: _settings.showChart,
      chartType: _settings.chartType,
    );
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Configurar vista'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CheckboxListTile(
                value: s.showChart,
                onChanged: (v) => setDialogState(() => s.showChart = v ?? true),
                title: const Text('Mostrar gráfico'),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
              DropdownButtonFormField<String>(
                initialValue: s.chartType,
                decoration: const InputDecoration(labelText: 'Tipo de gráfico'),
                items: _chartTypes
                    .map((t) => DropdownMenuItem(
                        value: t, child: Text(_chartTypeLabel(t))))
                    .toList(),
                onChanged: (v) =>
                    setDialogState(() => s.chartType = v ?? 'donut'),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancelar')),
            FilledButton(
              onPressed: () async {
                setState(() => _settings = s);
                await _saveSettings();
                if (ctx.mounted) Navigator.of(ctx).pop();
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editCategoryBudget(BudgetCategory c) async {
    final controller = TextEditingController(
        text: c.budget > 0 ? c.budget.toStringAsFixed(2) : '');
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Presupuesto de ${c.name}'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
              prefixText: '${AppState.instance.symbol} ',
              labelText: 'Presupuesto mensual'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar')),
          FilledButton(
            onPressed: () async {
              final v = double.tryParse(controller.text.replaceAll(',', '.'));
              try {
                await _categoryService.updateCategory(c.id, monthlyBudget: v);
                if (ctx.mounted) Navigator.of(ctx).pop();
                AppState.instance.notifyDataChanged();
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx)
                      .showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _editGlobalBudget() async {
    final current = _summary?.globalBudget;
    final controller = TextEditingController(
        text: current != null ? current.toStringAsFixed(2) : '');
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Presupuesto total del mes'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
              prefixText: '${AppState.instance.symbol} ',
              labelText: 'Límite de gasto mensual'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar')),
          FilledButton(
            onPressed: () async {
              final v = double.tryParse(controller.text.replaceAll(',', '.'));
              try {
                await _auth.updateMonthlyBudget(v);
                if (ctx.mounted) Navigator.of(ctx).pop();
                AppState.instance.notifyDataChanged();
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx)
                      .showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Presupuesto'),
        actions: [
          IconButton(
            onPressed: _openSettings,
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Configurar vista',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildCategoryPicker(List<BudgetCategory> categories) {
    return DropdownButtonFormField<String>(
      key: ValueKey(_categoryPickerKey),
      initialValue: null,
      hint: const Text('Selecciona una categoría…'),
      decoration: const InputDecoration(
        labelText: 'Fijar presupuesto por categoría',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.tune),
      ),
      items: categories
          .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
          .toList(),
      onChanged: (v) {
        if (v == null) return;
        final cat = categories.firstWhere((c) => c.id == v);
        setState(() => _categoryPickerKey++); // resetea la selección
        _editCategoryBudget(cat);
      },
    );
  }

  Widget _buildMonthSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          tooltip: 'Mes anterior',
          onPressed: () => _changeMonth(-1),
        ),
        Expanded(
          child: Text(
            _monthLabel,
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          tooltip: 'Mes siguiente',
          onPressed: () => _changeMonth(1),
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text('Error: $_error'));
    final s = _summary!;
    final relevant =
        s.categories.where((c) => c.budget > 0 || c.spent > 0).toList();
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildMonthSelector(),
          const SizedBox(height: 12),
          _buildCategoryPicker(s.categories),
          const SizedBox(height: 12),
          if (_settings.showChart)
            _BudgetSummaryCard(
              summary: s,
              chartType: _settings.chartType,
              onEditGlobal: _editGlobalBudget,
            ),
          const SizedBox(height: 8),
          if (relevant.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'Aún no hay gastos ni presupuestos este mes.\nToca ✏️ en una categoría para fijar su presupuesto.',
                textAlign: TextAlign.center,
              ),
            ),
          ...relevant.map((c) => _CategoryCard(
                category: c,
                index: relevant.indexOf(c),
                onEdit: () => _editCategoryBudget(c),
              )),
        ],
      ),
    );
  }
}

class _BudgetSummaryCard extends StatelessWidget {
  final BudgetSummary summary;
  final String chartType;
  final VoidCallback onEditGlobal;
  const _BudgetSummaryCard({
    required this.summary,
    required this.chartType,
    required this.onEditGlobal,
  });

  @override
  Widget build(BuildContext context) {
    final symbol = AppState.instance.symbol;
    final gb = summary.globalBudget;
    final overGlobal = gb != null && summary.totalSpent > gb;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text('Gasto del mes', style: Theme.of(context).textTheme.titleSmall),
            Text(
              '$symbol${summary.totalSpent.toStringAsFixed(2)}',
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            // Presupuesto global
            InkWell(
              onTap: onEditGlobal,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.flag_outlined, size: 18),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        gb != null
                            ? 'Presupuesto: $symbol${gb.toStringAsFixed(2)}'
                            : 'Fijar presupuesto global',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.edit_outlined, size: 16),
                  ],
                ),
              ),
            ),
            if (gb != null)
              Text(
                overGlobal
                    ? 'Excedido en $symbol${(summary.totalSpent - gb).toStringAsFixed(2)}'
                    : 'Te quedan $symbol${(gb - summary.totalSpent).toStringAsFixed(2)}',
                style: TextStyle(
                  color: overGlobal ? AppColors.coral : AppColors.emerald,
                  fontWeight: FontWeight.w600,
                ),
              ),
            const SizedBox(height: 12),
            SizedBox(height: 160, child: _buildChart()),
          ],
        ),
      ),
    );
  }

  Widget _buildChart() {
    final spent = summary.categories.where((c) => c.spent > 0).toList();
    if (spent.isEmpty) {
      return const Center(child: Text('Sin gastos este mes'));
    }
    switch (chartType) {
      case 'pie':
        return _pieChart(spent, 0);
      case 'bar':
        return _barChart(spent);
      case 'hbar':
        return _hbarChart(spent);
      case 'line':
        return _lineChart(spent);
      default:
        return _pieChart(spent, 34);
    }
  }

  Widget _pieChart(List<BudgetCategory> cats, double centerSpace) {
    return Stack(
      alignment: Alignment.center,
      children: [
        PieChart(
          PieChartData(
            sections: [
              for (var i = 0; i < cats.length; i++)
                PieChartSectionData(
                  value: cats[i].spent,
                  color: debtColors[i % debtColors.length],
                  radius: 46,
                  showTitle: false,
                ),
            ],
            centerSpaceRadius: centerSpace,
            sectionsSpace: 2,
          ),
        ),
        if (centerSpace > 0)
          Text('${cats.length}',
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
      ],
    );
  }

  Widget _barChart(List<BudgetCategory> cats) {
    final maxY = cats.fold<double>(0, (m, c) => c.spent > m ? c.spent : m);
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY * 1.25,
        barGroups: [
          for (var i = 0; i < cats.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: cats[i].spent,
                  color: debtColors[i % debtColors.length],
                  width: 18,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
        ],
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 42),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= cats.length) return const SizedBox.shrink();
                final n = cats[i].name;
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(n.length > 7 ? '${n.substring(0, 7)}…' : n,
                      style: const TextStyle(fontSize: 9)),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
      ),
    );
  }

  Widget _hbarChart(List<BudgetCategory> cats) {
    final total = cats.fold<double>(0, (s, c) => s + c.spent);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < cats.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 80,
                  child: Text(cats[i].name,
                      style: const TextStyle(fontSize: 11),
                      overflow: TextOverflow.ellipsis),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: total > 0 ? cats[i].spent / total : 0,
                      minHeight: 16,
                      color: debtColors[i % debtColors.length],
                      backgroundColor: Colors.grey.withValues(alpha: 0.15),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 70,
                  child: Text(
                    '${AppState.instance.symbol}${cats[i].spent.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 11),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _lineChart(List<BudgetCategory> cats) {
    final sorted = [...cats]..sort((a, b) => b.spent.compareTo(a.spent));
    return LineChart(
      LineChartData(
        minY: 0,
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (var i = 0; i < sorted.length; i++)
                FlSpot(i.toDouble(), sorted[i].spent),
            ],
            isCurved: true,
            color: AppColors.emerald,
            barWidth: 3,
            dotData: FlDotData(show: true),
          ),
        ],
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 42),
          ),
          bottomTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: true),
        borderData: FlBorderData(show: false),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final BudgetCategory category;
  final int index;
  final VoidCallback onEdit;
  const _CategoryCard({
    required this.category,
    required this.index,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final symbol = AppState.instance.symbol;
    final ratio = category.budget > 0
        ? (category.spent / category.budget).clamp(0.0, 1.0)
        : 0.0;
    final over = category.budget > 0 && category.spent > category.budget;
    final noBudget = category.budget <= 0 && category.spent > 0;
    final color = debtColors[index % debtColors.length];
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(Icons.circle, color: color, size: 20),
        ),
        title: Row(
          children: [
            Expanded(child: Text(category.name)),
            if (noBudget)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.amber.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Sin presupuesto',
                    style: TextStyle(fontSize: 11, color: AppColors.amber)),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
              color: over || noBudget ? AppColors.coral : color,
              backgroundColor: Colors.grey.withValues(alpha: 0.15),
            ),
            const SizedBox(height: 6),
            Text(
              noBudget
                  ? '$symbol${category.spent.toStringAsFixed(2)} gastados'
                  : '$symbol${category.spent.toStringAsFixed(2)} / $symbol${category.budget.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 12,
                color: over || noBudget ? AppColors.coral : null,
                fontWeight: over || noBudget ? FontWeight.w600 : null,
              ),
            ),
          ],
        ),
        trailing: IconButton(
          onPressed: onEdit,
          icon: const Icon(Icons.edit_outlined),
          tooltip: 'Editar presupuesto',
        ),
      ),
    );
  }
}
