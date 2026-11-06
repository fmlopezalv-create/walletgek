import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_state.dart';
import '../../core/money_widgets.dart';

/// Método de gestión financiera de "El Hombre Más Rico de Babilonia"
/// (George S. Clason, 1926), integrado como guía práctica.
class BabylonScreen extends StatefulWidget {
  final double? monthlyIncome;
  final double? monthlyExpense;

  const BabylonScreen({
    super.key,
    this.monthlyIncome,
    this.monthlyExpense,
  });

  @override
  State<BabylonScreen> createState() => _BabylonScreenState();
}

class _BabylonScreenState extends State<BabylonScreen> {
  @override
  Widget build(BuildContext context) {
    final income = widget.monthlyIncome ?? 0;
    final expense = widget.monthlyExpense ?? 0;
    final tenPercent = income * 0.10;
    final currentSaving = income - expense;

    return Scaffold(
      appBar: AppBar(title: const Text('Método Babilonia')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _intro(context),
          if (income > 0) ...[
            const SizedBox(height: 16),
            _goldenRule(context, income, tenPercent, currentSaving),
          ],
          const SizedBox(height: 16),
          _sectionTitle(context, 'Los siete remedios para la bolsa vacía',
              Icons.savings_outlined),
          const SizedBox(height: 8),
          ..._sevenCures(context),
          const SizedBox(height: 16),
          _sectionTitle(
              context, 'Las cinco leyes del oro', Icons.monetization_on_outlined),
          const SizedBox(height: 8),
          ..._fiveLaws(context),
          const SizedBox(height: 24),
          _disclaimer(context),
        ],
      ),
    );
  }

  Widget _intro(BuildContext context) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_stories, color: AppColors.champagneGold),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'El Hombre Más Rico de Babilonia',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'George S. Clason (1926) enseña, mediante parábolas ambientadas en '
            'la antigua Babilonia, las reglas para acumular riqueza. Su idea '
            'central es sencilla:',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.emerald.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.emerald.withValues(alpha: 0.3)),
            ),
            child: const Text(
              '«Una parte de todo lo que ganes es tuya para conservar.»',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _goldenRule(
      BuildContext context, double income, double tenPercent, double saving) {
    final meetsGoal = saving >= tenPercent;
    final progress = income > 0 ? (saving / tenPercent).clamp(0.0, 1.0) : 0.0;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.payments, color: AppColors.emerald),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'La regla de oro: págate a ti primero',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Aparta al menos el 10% de tus ingresos antes de gastar.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          _statRow(context, 'Ingresos del mes', AppState.instance.formatAmount(income)),
          _statRow(context, 'Debes apartar (10%)',
              AppState.instance.formatAmount(tenPercent)),
          _statRow(
            context,
            'Estás apartando',
            AppState.instance.formatAmount(saving),
            valueColor: meetsGoal ? AppColors.emerald : AppColors.amber,
          ),
          const SizedBox(height: 12),
          AnimatedProgress(
            value: progress,
            color: meetsGoal ? AppColors.emerald : AppColors.amber,
            height: 8,
          ),
          const SizedBox(height: 8),
          Text(
            meetsGoal
                ? '✓ Estás cumpliendo la regla del 10%'
                : 'Te faltan ${AppState.instance.formatAmount(tenPercent - saving)} para llegar al 10%',
            style: TextStyle(
              color: meetsGoal ? AppColors.emerald : AppColors.amber,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statRow(BuildContext context, String label, String value,
      {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.champagneGold, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  List<Widget> _sevenCures(BuildContext context) {
    const cures = [
      ('Empieza a engrosar tu bolsa', 'Ahorra al menos 1/10 (10%) de todo lo que ganes.'),
      ('Controla tus gastos', 'Distingue los gastos necesarios de los deseos. No gastes más de lo que ganas.'),
      ('Haz que tu oro se multiplique', 'Invierte tus ahorros para que generen más dinero.'),
      ('Protege tus tesoros de pérdidas', 'No inviertas en lo que no entiendes ni en promesas de ganancias imposibles.'),
      ('Haz de tu vivienda una inversión rentable', 'Tu hogar, con el tiempo, debe ser un activo y no una carga.'),
      ('Asegura ingresos para el futuro', 'Prepara tu vejez y la protección de tu familia.'),
      ('Aumenta tu capacidad de ganar', 'Invierte en ti: estudia, mejora tus habilidades, sé más valioso.'),
    ];
    return [
      for (var i = 0; i < cures.length; i++)
        _numberedItem(context, i + 1, cures[i].$1, cures[i].$2),
    ];
  }

  List<Widget> _fiveLaws(BuildContext context) {
    const laws = [
      ('El oro acude al que ahorra', 'Llega gustoso a quien aparta al menos una décima parte de sus ingresos.'),
      ('El oro trabaja para su dueño', 'Labora para quien lo emplea en negocios o inversiones rentables.'),
      ('El oro permanece con el prudente', 'Se queda con quien lo invierte siguiendo el consejo de personas sabias.'),
      ('El oro huye del que no conoce', 'Escapa de quien lo invierte en negocios que no domina.'),
      ('El oro escapa del que lo fuerza', 'Huye de quien busca ganancias imposibles o sigue consejos de embaucadores.'),
    ];
    return [
      for (var i = 0; i < laws.length; i++)
        _numberedItem(context, i + 1, laws[i].$1, laws[i].$2),
    ];
  }

  Widget _numberedItem(
      BuildContext context, int number, String title, String desc) {
    return _card(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.champagneGold.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Text(
              '$number',
              style: const TextStyle(
                color: AppColors.champagneGold,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 3),
                Text(desc, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _disclaimer(BuildContext context) {
    return Text(
      'Esta guía se basa en los principios del libro "El Hombre Más Rico de '
      'Babilonia" (George S. Clason). No constituye asesoramiento financiero '
      'profesional.',
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodySmall,
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
