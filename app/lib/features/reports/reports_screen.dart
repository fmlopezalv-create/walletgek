import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_state.dart';
import '../budget/budget_model.dart';
import '../budget/budget_service.dart';
import '../budget/budget_screen.dart';
import '../dashboard/dashboard_model.dart';
import '../dashboard/dashboard_service.dart';
import '../debts/debt_colors.dart';
import '../debts/debt_plan_screen.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _budgetService = BudgetService();
  final _dashboardService = DashboardService();
  BudgetSummary? _summary;
  HealthSummary? _health;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final s = await _budgetService.getSummary();
      if (mounted) setState(() => _summary = s);
    } catch (_) {}
    try {
      final h = await _dashboardService.getHealth();
      if (mounted) setState(() => _health = h);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes'),
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ValueListenableBuilder<bool>(
          valueListenable: AppState.instance.hideAmountsNotifier,
          builder: (context, hide, _) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator()),
                )
              else ...[
                if (_health != null) _healthCard(context, _health!),
                const SizedBox(height: 16),
                if (_summary != null) _budgetCard(context, _summary!),
                const SizedBox(height: 16),
                _shortcutsCard(context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _healthCard(BuildContext context, HealthSummary h) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Salud financiera',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _metric(context, 'Tasa de ahorro',
                      h.savingsRate == null ? '—' : '${h.savingsRate!.toStringAsFixed(0)}%',
                      _statusColor(h.savingsRate, (v) => v >= 20, (v) => v >= 0)),
                ),
                Expanded(
                  child: _metric(context, 'Deuda / ingreso',
                      h.dti == null ? '—' : '${h.dti!.toStringAsFixed(0)}%',
                      _statusColor(h.dti, (v) => v <= 36, (v) => v <= 43)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _miniStat(context, 'Ingresos', h.income,
                      AppColors.emerald, Icons.arrow_downward),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _miniStat(context, 'Gastos', h.expense,
                      AppColors.coral, Icons.arrow_upward),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Pagos mensuales de deuda: ${AppState.instance.formatAmount(h.monthlyDebt)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(
      double? value, bool Function(double) good, bool Function(double) warn) {
    if (value == null) return AppColors.slate;
    if (good(value)) return AppColors.emerald;
    if (warn(value)) return AppColors.amber;
    return AppColors.coral;
  }

  Widget _metric(BuildContext context, String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 6),
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(value,
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 18, color: color)),
          ],
        ),
      ],
    );
  }

  Widget _miniStat(
      BuildContext context, String label, double value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodySmall),
                Text(AppState.instance.formatAmount(value),
                    style: TextStyle(fontWeight: FontWeight.bold, color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _budgetCard(BuildContext context, BudgetSummary s) {
    final app = AppState.instance;
    final spentCats = s.categories.where((c) => c.spent > 0).toList();
    final pct = s.totalBudget > 0
        ? (s.totalSpent / s.totalBudget).clamp(0.0, 1.0)
        : 0.0;
    final over = s.totalBudget > 0 && s.totalSpent > s.totalBudget;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Presupuesto del mes',
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const BudgetScreen()),
                  ),
                  child: const Text('Ver detalle'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${app.formatAmount(s.totalSpent)} de ${app.formatAmount(s.totalBudget)}',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 10,
                color: over ? AppColors.coral : AppColors.emerald,
                backgroundColor: Colors.grey.withValues(alpha: 0.15),
              ),
            ),
            if (over) ...[
              const SizedBox(height: 6),
              Text(
                  'Sobregasto de ${app.formatAmount(s.totalSpent - s.totalBudget)}',
                  style: const TextStyle(color: AppColors.coral)),
            ],
            if (spentCats.isNotEmpty) ...[
              const SizedBox(height: 20),
              SizedBox(height: 160, child: _categoryChart(spentCats)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _categoryChart(List<BudgetCategory> cats) {
    final total = cats.fold<double>(0, (s, c) => s + c.spent);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < cats.length && i < 5; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                SizedBox(
                  width: 90,
                  child: Text(cats[i].name,
                      style: const TextStyle(fontSize: 11),
                      overflow: TextOverflow.ellipsis),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: total > 0 ? cats[i].spent / total : 0,
                      minHeight: 14,
                      color: debtColors[i % debtColors.length],
                      backgroundColor: Colors.grey.withValues(alpha: 0.15),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 64,
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

  Widget _shortcutsCard(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.account_balance_wallet_outlined),
            title: const Text('Plan de pago de deudas'),
            subtitle: const Text('Bola de nieve o avalancha'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const DebtPlanScreen()),
            ),
          ),
        ],
      ),
    );
  }
}
