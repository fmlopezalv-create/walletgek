import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_state.dart';
import '../../core/storage.dart';
import '../receivables/receivables_screen.dart';
import 'add_debt_screen.dart';
import 'debt_colors.dart';
import 'debt_model.dart';
import 'debt_plan_screen.dart';
import 'debt_service.dart';
import 'debt_types.dart';
import 'debt_view_settings.dart';

const _chartTypes = ['donut', 'pie', 'bar', 'hbar', 'line'];

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

class DebtsScreen extends StatefulWidget {
  const DebtsScreen({super.key});

  @override
  State<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends State<DebtsScreen> {
  final _service = DebtService();
  List<Debt> _debts = [];
  bool _loading = true;
  String? _error;
  DebtViewSettings _settings = DebtViewSettings();

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _load();
  }

  Future<void> _loadSettings() async {
    final raw = await TokenStorage.readDebtView();
    if (raw == null) return;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      if (mounted) {
        setState(() => _settings = DebtViewSettings.fromJson(json));
      }
    } catch (_) {}
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _service.listDebts();
      setState(() => _debts = list);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveSettings() async {
    await TokenStorage.saveDebtView(jsonEncode(_settings.toJson()));
  }

  Future<void> _openSettings() async {
    final s = DebtViewSettings(
      showChart: _settings.showChart,
      showInterest: _settings.showInterest,
      showInstallments: _settings.showInstallments,
      showStatus: _settings.showStatus,
      showInstitution: _settings.showInstitution,
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
              CheckboxListTile(
                value: s.showInterest,
                onChanged: (v) =>
                    setDialogState(() => s.showInterest = v ?? true),
                title: const Text('Tasa de interés'),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
              CheckboxListTile(
                value: s.showInstallments,
                onChanged: (v) =>
                    setDialogState(() => s.showInstallments = v ?? true),
                title: const Text('Cuotas (pagadas/restantes)'),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
              CheckboxListTile(
                value: s.showStatus,
                onChanged: (v) => setDialogState(() => s.showStatus = v ?? true),
                title: const Text('Estado (atrasado)'),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
              CheckboxListTile(
                value: s.showInstitution,
                onChanged: (v) =>
                    setDialogState(() => s.showInstitution = v ?? false),
                title: const Text('Institución'),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
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

  String _money(double v) => AppState.instance.formatAmount(v);

  Future<void> _payDebt(Debt debt) async {
    final amount = TextEditingController();
    final cuotas = TextEditingController(text: '1');
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Pagar a ${debt.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amount,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                  labelText: 'Monto',
                  prefixText: '${AppState.instance.symbol} '),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: cuotas,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Cuotas que cubre'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar')),
          FilledButton(
            onPressed: () async {
              final v = double.tryParse(amount.text.replaceAll(',', '.'));
              if (v == null || v <= 0) return;
              try {
                await _service.payDebt(debt.id, v,
                    cuotas: int.tryParse(cuotas.text) ?? 1);
                if (ctx.mounted) Navigator.of(ctx).pop();
                _load();
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx)
                      .showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('Pagar'),
          ),
        ],
      ),
    );
  }

  Future<void> _editDebt(Debt debt) async {
    final name = TextEditingController(text: debt.name);
    final balance =
        TextEditingController(text: debt.balance.toStringAsFixed(2));
    final rate =
        TextEditingController(text: debt.interestRate.toStringAsFixed(1));
    final payment =
        TextEditingController(text: debt.minimumPayment.toStringAsFixed(2));
    String? editColor = debt.color;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Editar ${debt.name}'),
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: name,
                    decoration: const InputDecoration(labelText: 'Nombre')),
                const SizedBox(height: 16),
                TextField(
                    controller: balance,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                        labelText: 'Valor pendiente',
                        prefixText: '${AppState.instance.symbol} ')),
                const SizedBox(height: 16),
                TextField(
                    controller: rate,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                        labelText: 'Tasa de interés anual (%)')),
                const SizedBox(height: 16),
                TextField(
                    controller: payment,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                        labelText: 'Pago mensual',
                        prefixText: '${AppState.instance.symbol} ')),
                const SizedBox(height: 16),
                Text('Color', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: debtColors.map((c) {
                    final selected = editColor == colorToHex(c);
                    return GestureDetector(
                      onTap: () =>
                          setDialogState(() => editColor = colorToHex(c)),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: selected
                              ? Border.all(color: Colors.black, width: 2)
                              : null,
                        ),
                        child: selected
                            ? const Icon(Icons.check,
                                color: Colors.white, size: 18)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancelar')),
            FilledButton(
              onPressed: () async {
                try {
                  await _service.updateDebt(
                    debt.id,
                    name: name.text.trim(),
                    color: editColor,
                    balance:
                        double.tryParse(balance.text.replaceAll(',', '.')),
                    interestRate:
                        double.tryParse(rate.text.replaceAll(',', '.')),
                    minimumPayment:
                        double.tryParse(payment.text.replaceAll(',', '.')),
                  );
                  if (ctx.mounted) Navigator.of(ctx).pop();
                  _load();
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
      ),
    );
  }

  Future<void> _changeStatus(Debt debt) async {
    final monthsLate = TextEditingController(text: debt.monthsLate.toString());
    String status = debt.status;
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Estado de ${debt.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: status,
                decoration: const InputDecoration(labelText: 'Estado'),
                items: const [
                  DropdownMenuItem(value: 'up_to_date', child: Text('Al día')),
                  DropdownMenuItem(value: 'late', child: Text('Atrasado')),
                ],
                onChanged: (v) =>
                    setDialogState(() => status = v ?? 'up_to_date'),
              ),
              if (status == 'late') ...[
                const SizedBox(height: 16),
                TextField(
                    controller: monthsLate,
                    keyboardType: TextInputType.number,
                    decoration:
                        const InputDecoration(labelText: 'Meses de atraso')),
              ],
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancelar')),
            FilledButton(
              onPressed: () async {
                try {
                  await _service.updateDebt(
                    debt.id,
                    status: status,
                    monthsLate: status == 'late'
                        ? (int.tryParse(monthsLate.text) ?? 0)
                        : 0,
                  );
                  if (ctx.mounted) Navigator.of(ctx).pop();
                  _load();
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
      ),
    );
  }

  Future<void> _deleteDebt(Debt debt) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar deuda'),
        content: Text('¿Seguro que quieres eliminar "${debt.name}"?'),
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
      await _service.deleteDebt(debt.id);
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Deudas'),
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ReceivablesScreen()),
            ),
            icon: const Icon(Icons.arrow_circle_up_outlined),
            tooltip: 'Cobros (lo que te deben)',
          ),
          IconButton(
            onPressed: _openSettings,
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Configurar vista',
          ),
          IconButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const DebtPlanScreen()),
            ),
            icon: const Icon(Icons.timeline),
            tooltip: 'Plan de pago',
          ),
        ],
      ),
      body: ValueListenableBuilder<bool>(
        valueListenable: AppState.instance.hideAmountsNotifier,
        builder: (context, hide, _) => _buildBody(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddDebtScreen()),
          );
          if (mounted) _load();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text('Error: $_error'));
    if (_debts.isEmpty) {
      return const Center(
        child: Text('No tienes deudas registradas.\nPulsa + para añadir una.',
            textAlign: TextAlign.center),
      );
    }
    final total = _debts.fold<double>(0, (s, d) => s + d.balance);
    return Column(
      children: [
        if (_settings.showChart)
          _DebtSummary(debts: _debts, chartType: _settings.chartType),
        Expanded(child: _buildList(total)),
      ],
    );
  }

  Widget _buildList(double total) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 88),
      itemCount: _debts.length,
      itemBuilder: (context, index) {
        final d = _debts[index];
        final late = d.status == 'late';
        final ratio = total > 0 ? (d.balance / total).clamp(0.0, 1.0) : 0.0;
        final parts = <String>[
          debtTypeLabel(d.type),
          _money(d.balance),
          if (_settings.showInstitution &&
              d.institution != null &&
              d.institution!.isNotEmpty)
            d.institution!,
          if (_settings.showInterest && d.interestRate > 0)
            '${d.interestRate.toStringAsFixed(1)}%',
        ];
        if (_settings.showInstallments && d.totalInstallments != null) {
          final remaining = d.totalInstallments! - d.paidInstallments;
          parts.add(
              '${d.paidInstallments}/${d.totalInstallments} cuotas · faltan $remaining');
        }
        if (_settings.showStatus && late) {
          parts.add('Atrasado (${d.monthsLate} m)');
        }
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: debtColor(d.color, index).withValues(alpha: 0.15),
              child: Icon(debtTypeIcon(d.type),
                  color: debtColor(d.color, index), size: 20),
            ),
            title: Text(d.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(parts.join(' · ')),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: ratio,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                  color: late ? AppColors.coral : debtColor(d.color, index),
                  backgroundColor: Colors.grey.withValues(alpha: 0.15),
                ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'pay') {
                  _payDebt(d);
                } else if (v == 'status') {
                  _changeStatus(d);
                } else if (v == 'edit') {
                  _editDebt(d);
                } else if (v == 'delete') {
                  _deleteDebt(d);
                }
              },
              itemBuilder: (ctx) => const [
                PopupMenuItem(value: 'pay', child: Text('Registrar pago')),
                PopupMenuItem(value: 'status', child: Text('Cambiar estado')),
                PopupMenuItem(value: 'edit', child: Text('Editar')),
                PopupMenuItem(value: 'delete', child: Text('Eliminar')),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DebtSummary extends StatelessWidget {
  final List<Debt> debts;
  final String chartType;
  const _DebtSummary({required this.debts, required this.chartType});

  @override
  Widget build(BuildContext context) {
    final total = debts.fold<double>(0, (s, d) => s + d.balance);
    final hasLegend = chartType == 'donut' || chartType == 'pie';
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text('Deuda total', style: Theme.of(context).textTheme.titleSmall),
            Text(
              AppState.instance.formatAmount(total),
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(height: 170, child: _buildChart()),
            if (hasLegend) ...[
              const SizedBox(height: 16),
              _legend(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChart() {
    switch (chartType) {
      case 'pie':
        return _pieChart(0);
      case 'bar':
        return _barChart();
      case 'hbar':
        return _hbarChart();
      case 'line':
        return _lineChart();
      default:
        return _pieChart(34); // donut
    }
  }

  Widget _pieChart(double centerSpace) {
    return Stack(
      alignment: Alignment.center,
      children: [
        PieChart(
          PieChartData(
            sections: [
              for (var i = 0; i < debts.length; i++)
                PieChartSectionData(
                  value: debts[i].balance,
                  color: debtColor(debts[i].color, i),
                  radius: 46,
                  showTitle: false,
                ),
            ],
            centerSpaceRadius: centerSpace,
            sectionsSpace: 2,
          ),
        ),
        if (centerSpace > 0)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${debts.length}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 20)),
              const Text('deudas', style: TextStyle(fontSize: 11)),
            ],
          ),
      ],
    );
  }

  Widget _barChart() {
    final maxY = debts.fold<double>(0, (m, d) => d.balance > m ? d.balance : m);
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY * 1.25,
        barGroups: [
          for (var i = 0; i < debts.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: debts[i].balance,
                  color: debtColor(debts[i].color, i),
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
                if (i < 0 || i >= debts.length) {
                  return const SizedBox.shrink();
                }
                final n = debts[i].name;
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

  Widget _hbarChart() {
    final total = debts.fold<double>(0, (s, d) => s + d.balance);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < debts.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 80,
                  child: Text(debts[i].name,
                      style: const TextStyle(fontSize: 11),
                      overflow: TextOverflow.ellipsis),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: total > 0 ? debts[i].balance / total : 0,
                      minHeight: 16,
                      color: debtColor(debts[i].color, i),
                      backgroundColor: Colors.grey.withValues(alpha: 0.15),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 70,
                  child: Text(
                    '${AppState.instance.symbol}${debts[i].balance.toStringAsFixed(0)}',
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

  Widget _lineChart() {
    final sorted = [...debts]..sort((a, b) => b.balance.compareTo(a.balance));
    return LineChart(
      LineChartData(
        minY: 0,
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (var i = 0; i < sorted.length; i++)
                FlSpot(i.toDouble(), sorted[i].balance),
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

  Widget _legend(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        for (var i = 0; i < debts.length; i++)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: debtColor(debts[i].color, i),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 200),
                child: Text(
                  debts[i].name,
                  style: Theme.of(context).textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
      ],
    );
  }
}
