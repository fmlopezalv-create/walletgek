import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import 'debt_plan_model.dart';
import 'debt_service.dart';

class DebtPlanScreen extends StatefulWidget {
  const DebtPlanScreen({super.key});

  @override
  State<DebtPlanScreen> createState() => _DebtPlanScreenState();
}

class _DebtPlanScreenState extends State<DebtPlanScreen> {
  final _service = DebtService();
  final _budget = TextEditingController();
  String _strategy = 'snowball';
  DebtPlan? _plan;
  bool _loading = false;
  String? _error;

  Future<void> _calculate() async {
    final budget = double.tryParse(_budget.text.replaceAll(',', '.'));
    if (budget == null || budget <= 0) {
      setState(() => _error = 'Introduce un presupuesto mensual válido');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final plan =
          await _service.getPlan(strategy: _strategy, monthlyBudget: budget);
      setState(() => _plan = plan);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Plan de pago de deudas')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                    value: 'snowball',
                    label: Text('Bola de nieve'),
                    icon: Icon(Icons.snowing)),
                ButtonSegment(
                    value: 'avalanche',
                    label: Text('Avalancha'),
                    icon: Icon(Icons.trending_down)),
              ],
              selected: {_strategy},
              onSelectionChanged: (s) => setState(() => _strategy = s.first),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _budget,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Presupuesto mensual para deudas',
                prefixText: '${AppState.instance.symbol} ',
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _loading ? null : _calculate,
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Calcular plan'),
            ),
            if (_plan != null) ...[
              const SizedBox(height: 24),
              _PlanResult(plan: _plan!),
            ],
          ],
        ),
      ),
    );
  }
}

class _PlanResult extends StatelessWidget {
  final DebtPlan plan;
  const _PlanResult({required this.plan});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tiempo estimado: ${plan.monthsToPayoff} meses',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
                'Interés total a pagar: ${AppState.instance.symbol}${plan.totalInterest.toStringAsFixed(2)}'),
            const SizedBox(height: 12),
            Text(
                'Orden de pago (${plan.strategy == 'avalanche' ? 'avalancha' : 'bola de nieve'}):'),
            const SizedBox(height: 4),
            ...plan.schedule.map((s) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.check_circle_outline),
                  title: Text(s.name),
                  trailing:
                      Text(s.paidOffMonth != null ? 'mes ${s.paidOffMonth}' : '—'),
                )),
          ],
        ),
      ),
    );
  }
}
