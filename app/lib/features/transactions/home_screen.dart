import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_colors.dart';
import '../../core/app_state.dart';
import '../../core/connectivity.dart';
import '../../core/money_widgets.dart';
import '../../core/profile_avatar.dart';
import '../../core/storage.dart';
import '../advisor/advisor_screen.dart';
import '../babylon/babylon_screen.dart';
import '../budget/budget_model.dart';
import '../budget/budget_screen.dart';
import '../budget/budget_service.dart';
import '../dashboard/dashboard_service.dart';
import '../dashboard/home_dashboard_model.dart';
import '../debts/debt_colors.dart';
import '../debts/debt_plan_screen.dart';
import '../debts/debt_service.dart';
import '../profile/profile_screen.dart';
import '../profile/profile_service.dart';
import 'add_transaction_screen.dart';
import 'transaction_model.dart';
import 'transaction_service.dart';

const _monthNames = [
  'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
  'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
];

class HomeScreen extends StatefulWidget {
  final void Function(int tabIndex)? onSwitchTab;
  const HomeScreen({super.key, this.onSwitchTab});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _dashboardService = DashboardService();
  final _transactionService = TransactionService();
  final _debtService = DebtService();
  final _profileService = ProfileService();
  final _budgetService = BudgetService();

  HomeDashboard? _home;
  List<Transaction> _transactions = [];
  BudgetSummary? _budgetSummary;
  bool _loading = true;
  bool _hideBalance = false;
  String? _error;
  String _month = _currentMonth();
  final PageController _pageController = PageController();
  List<String> _sectionOrder = const [
    'premium', 'upcoming', 'debts', 'expenses', 'budget', 'strategy', 'babylon',
    'recent',
  ];
  Set<String> _hiddenSections = {};

  static String _currentMonth() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  String get _monthName {
    final parts = _month.split('-');
    if (parts.length != 2) return _month;
    final m = int.tryParse(parts[1]);
    if (m == null || m < 1 || m > 12) return _month;
    return _monthNames[m - 1];
  }

  @override
  void initState() {
    super.initState();
    _load();
    _loadSectionOrder();
    _loadHiddenSections();
  }

  Future<void> _loadSectionOrder() async {
    final raw = await TokenStorage.readSectionOrder();
    if (raw == null) return;
    try {
      final list = (jsonDecode(raw) as List).cast<String>();
      if (list.length == _sectionOrder.length &&
          list.toSet().containsAll(_sectionOrder)) {
        if (mounted) setState(() => _sectionOrder = list);
      }
    } catch (_) {}
  }

  Future<void> _loadHiddenSections() async {
    final raw = await TokenStorage.readSectionHidden();
    if (raw == null) return;
    try {
      final list = (jsonDecode(raw) as List).cast<String>();
      if (mounted) {
        setState(() => _hiddenSections = list.toSet());
      }
    } catch (_) {}
  }

  Future<void> _saveSectionOrder() async {
    await TokenStorage.saveSectionOrder(jsonEncode(_sectionOrder));
    await TokenStorage.saveSectionHidden(jsonEncode(_hiddenSections.toList()));
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final home = await _dashboardService.getHome(month: _month);
      if (mounted) setState(() => _home = home);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
    try {
      final list = await _transactionService.listTransactions();
      if (mounted) setState(() => _transactions = list);
    } catch (_) {}
    // Refresca el nombre/email/estado premium del usuario desde el backend.
    try {
      final profile = await _profileService.getProfile();
      if (mounted && profile.name.isNotEmpty) {
        await AppState.instance.setUserName(profile.name);
        await AppState.instance.setUserEmail(profile.email);
        AppState.instance.setPremium(profile.isPremium);
        if (mounted) setState(() {});
      }
    } catch (_) {}
    // Resumen de presupuesto (no bloquea si falla).
    try {
      final summary = await _budgetService.getSummary(month: _month);
      if (mounted) setState(() => _budgetSummary = summary);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  String _formatDate(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    return '$dd/$mm';
  }

  String _dueLabel(DateTime? d) {
    if (d == null) return 'Sin fecha';
    final today = DateTime.now();
    final diff = DateTime(d.year, d.month, d.day)
        .difference(DateTime(today.year, today.month, today.day))
        .inDays;
    if (diff < 0) return 'Vencido hace ${-diff} d';
    if (diff == 0) return 'Vence hoy';
    if (diff == 1) return 'Vence mañana';
    return 'Vence ${_formatDate(d)}';
  }

  Future<void> _markPaid(UpcomingPayment p) async {
    try {
      await _debtService.payDebt(p.id, p.minimumPayment);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Pago de "${p.name}" registrado')),
        );
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _showAddSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.arrow_upward, color: AppColors.coral),
              title: const Text('Registrar gasto'),
              onTap: () {
                Navigator.of(ctx).pop();
                _openAdd('expense');
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.arrow_downward, color: AppColors.emerald),
              title: const Text('Registrar ingreso'),
              onTap: () {
                Navigator.of(ctx).pop();
                _openAdd('income');
              },
            ),
            ListTile(
              leading: const Icon(Icons.account_balance_wallet_outlined,
                  color: AppColors.coral),
              title: const Text('Pago de deuda'),
              onTap: () {
                Navigator.of(ctx).pop();
                widget.onSwitchTab?.call(1);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openAdd(String type) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AddTransactionScreen(initialType: type)),
    );
    if (mounted) _load();
  }

  void _toggleHide() {
    setState(() => _hideBalance = !_hideBalance);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _brandBanner(),
            // Encabezado fijo
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: _header(),
            ),
            const SizedBox(height: 8),
            // Indicador de estado sin conexión
            ValueListenableBuilder<bool>(
              valueListenable: ConnectivityService.instance.online,
              builder: (context, online, _) {
                if (online) return const SizedBox.shrink();
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.amber.withValues(alpha: 0.5)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.cloud_off,
                          size: 16, color: AppColors.amber),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Sin conexión · mostrando datos guardados',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.amber),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 4),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Card(
                  color: AppColors.coral.withValues(alpha: 0.12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text('Error: $_error'),
                  ),
                ),
              ),
            // Tarjeta principal fija
            if (_home != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: _balanceCard(_home!),
              ),
            // Secciones móviles en carrusel horizontal
            Expanded(
              child: _loading && _home == null
                  ? const Center(child: CircularProgressIndicator())
                  : _sectionsPager(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddSheet,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _sectionById(String id) {
    switch (id) {
      case 'premium':
        return _premiumRow();
      case 'upcoming':
        return _home != null ? _upcomingCard(_home!) : const SizedBox.shrink();
      case 'debts':
        return _home != null ? _debtSummaryCard(_home!) : const SizedBox.shrink();
      case 'expenses':
        return _home != null ? _expensesCard(_home!) : const SizedBox.shrink();
      case 'budget':
        return _budgetCard();
      case 'strategy':
        return _strategyCard();
      case 'babylon':
        return _babylonCard();
      case 'recent':
      default:
        return _recentCard();
    }
  }

  Widget _sectionsPager() {
    final pages = _sectionOrder
        .where((id) => !_hiddenSections.contains(id))
        .map(_sectionById)
        .toList();
    if (pages.isEmpty) {
      return const Center(child: Text('No hay secciones visibles.'));
    }
    return Stack(
      children: [
        Positioned.fill(
          child: PageView.builder(
            controller: _pageController,
            itemCount: pages.length,
            itemBuilder: (context, index) => LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 16,
                  ),
                  child: pages[index],
                ),
              ),
            ),
          ),
        ),
        // Flechas flotantes semitransparentes para insinuar el deslizamiento.
        Positioned(
          left: 4,
          top: 0,
          bottom: 0,
          child: Center(child: _pagerArrow(false, pages.length)),
        ),
        Positioned(
          right: 4,
          top: 0,
          bottom: 0,
          child: Center(child: _pagerArrow(true, pages.length)),
        ),
      ],
    );
  }

  Widget _pagerArrow(bool forward, int count) {
    return IgnorePointer(
      ignoring: true,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.18),
          shape: BoxShape.circle,
        ),
        child: Icon(
          forward ? Icons.chevron_right : Icons.chevron_left,
          size: 18,
          color: Colors.white.withValues(alpha: 0.85),
        ),
      ),
    );
  }

  Future<void> _openOrderConfig() async {
    final working = [..._sectionOrder];
    final workingHidden = {..._hiddenSections};
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Secciones'),
          content: SizedBox(
            width: double.maxFinite,
            child: ReorderableListView(
              shrinkWrap: true,
              buildDefaultDragHandles: false,
              onReorderItem: (oldIndex, newIndex) {
                setDialogState(() {
                  final item = working.removeAt(oldIndex);
                  working.insert(newIndex, item);
                });
              },
              children: [
                for (var i = 0; i < working.length; i++)
                  ReorderableDragStartListener(
                    key: ValueKey(working[i]),
                    index: i,
                    child: ListTile(
                      leading: const Icon(Icons.drag_indicator),
                      title: Text(_sectionLabel(working[i])),
                      trailing: Checkbox(
                        value: !workingHidden.contains(working[i]),
                        onChanged: (visible) {
                          setDialogState(() {
                            if (visible == true) {
                              workingHidden.remove(working[i]);
                            } else {
                              workingHidden.add(working[i]);
                            }
                          });
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                setState(() {
                  _sectionOrder = working;
                  _hiddenSections = workingHidden;
                });
                _saveSectionOrder();
                Navigator.of(ctx).pop();
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  String _sectionLabel(String id) {
    switch (id) {
      case 'premium':
        return 'Premium';
      case 'upcoming':
        return 'Próximos vencimientos';
      case 'debts':
        return 'Resumen de deudas';
      case 'expenses':
        return 'Gastos del mes';
      case 'budget':
        return 'Presupuesto';
      case 'strategy':
        return 'Estrategia de pago';
      case 'babylon':
        return 'Método Babilonia';
      case 'recent':
        return 'Movimientos recientes';
      default:
        return id;
    }
  }

  Widget _brandBanner() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.midnightNavy;
    final accent = isDark ? AppColors.emerald : AppColors.emeraldDeep;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: (isDark ? Colors.white : AppColors.midnightNavy)
                .withValues(alpha: 0.08),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_balance_wallet_outlined,
              size: 18, color: accent),
          const SizedBox(width: 8),
          Text(
            'WalletGek',
            style: GoogleFonts.manrope(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: textColor,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _header() {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Buenos días'
        : hour < 19
            ? 'Buenas tardes'
            : 'Buenas noches';
    final name = AppState.instance.userName;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(name.isNotEmpty ? name : 'Usuario',
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        IconButton(
          onPressed: _openOrderConfig,
          icon: const Icon(Icons.tune, size: 20),
          tooltip: 'Configurar orden de secciones',
        ),
        IconButton(
          onPressed: _showMonthYearPicker,
          icon: const Icon(Icons.calendar_month_outlined),
          tooltip: 'Seleccionar mes',
        ),
        IconButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Sin notificaciones nuevas')),
            );
          },
          icon: const Icon(Icons.notifications_outlined),
          tooltip: 'Notificaciones',
        ),
        const SizedBox(width: 4),
        ProfileAvatar(size: 38, onOpenProfile: _openProfile),
        const SizedBox(width: 8),
      ],
    );
  }

  void _openProfile() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    );
  }

  Future<void> _showMonthYearPicker() async {
    final now = DateTime.now();
    final selected = DateTime.tryParse('$_month-01') ?? now;
    var year = selected.year;
    var month = selected.month;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Seleccionar mes'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => setDialogState(() => year--),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Text('$year',
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(
                    onPressed: () => setDialogState(() => year++),
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              GridView.count(
                shrinkWrap: true,
                crossAxisCount: 3,
                childAspectRatio: 2.2,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
                children: [
                  for (var m = 1; m <= 12; m++)
                    _monthCell(
                      ctx,
                      _monthNames[m - 1].substring(0, 3),
                      month == m,
                      () => setDialogState(() => month = m),
                    ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final ym =
                    '$year-${month.toString().padLeft(2, '0')}';
                Navigator.of(ctx).pop();
                if (ym != _month) {
                  setState(() => _month = ym);
                  _load();
                }
              },
              child: const Text('Aceptar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _monthCell(
    BuildContext ctx,
    String label,
    bool selected,
    VoidCallback onTap,
  ) {
    final scheme = Theme.of(ctx).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? scheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected
                ? scheme.primary
                : scheme.outline.withValues(alpha: 0.4),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? scheme.onPrimary : scheme.onSurface,
            fontWeight: selected ? FontWeight.bold : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _balanceCard(HomeDashboard home) {
    final up = (home.variation ?? 0) >= 0;
    final variation = home.variation;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.midnightNavy, AppColors.navy700],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Balance de $_monthName',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 14)),
              ),
              if (variation != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: (up ? AppColors.emerald : AppColors.coral)
                        .withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(up ? Icons.trending_up : Icons.trending_down,
                          size: 15,
                          color: up ? AppColors.emerald : AppColors.coral),
                      const SizedBox(width: 4),
                      Text(
                        '${up ? '+' : ''}${variation.toStringAsFixed(0)}%',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color:
                                up ? AppColors.emerald : AppColors.coral),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          _healthIndicator(home),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: AnimatedMoney(
                  home.balance,
                  hide: _hideBalance,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              IconButton(
                onPressed: _toggleHide,
                icon: Icon(
                  _hideBalance
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: Colors.white.withValues(alpha: 0.6),
                  size: 22,
                ),
                tooltip: _hideBalance
                    ? 'Mostrar montos'
                    : 'Ocultar montos',
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text('vs. mes anterior',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55),
                      fontSize: 13)),
              const SizedBox(width: 6),
              if (variation != null)
                Icon(
                  up ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 14,
                  color: up ? AppColors.emerald : AppColors.coral,
                ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _miniFlow(
                    Icons.arrow_downward, 'Ingresos', home.income,
                    AppColors.emerald,
                    hide: _hideBalance),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _miniFlow(
                    Icons.arrow_upward, 'Gastos', home.expense,
                    AppColors.coral,
                    hide: _hideBalance),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _premiumRow() {
    return ValueListenableBuilder<bool>(
      valueListenable: AppState.instance.premiumNotifier,
      builder: (context, isPremium, _) {
        return _sectionCard(
          child: GestureDetector(
            onTap: isPremium ? _openAdvisor : _showUpgradeDialog,
            child: Row(
              children: [
                Icon(
                  isPremium ? Icons.auto_awesome : Icons.workspace_premium,
                  size: 24,
                  color: AppColors.champagneGold,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isPremium ? 'Premium activo' : 'Hazte Premium',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              color: AppColors.champagneGold,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isPremium
                            ? 'Habla con tu asesor financiero IA'
                            : 'Asesor IA con tus datos reales',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right,
                    color: AppColors.champagneGold, size: 22),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openAdvisor() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AdvisorScreen()),
    );
  }

  Future<void> _showUpgradeDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.workspace_premium, color: AppColors.champagneGold),
            SizedBox(width: 8),
            Text('WalletGek Premium'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Desbloquea tu asesor financiero personal.'),
            SizedBox(height: 12),
            _Benefit(icon: Icons.auto_awesome, text: 'Asesor IA que usa tus ingresos, gastos y deudas reales'),
            SizedBox(height: 8),
            _Benefit(icon: Icons.tips_and_updates, text: 'Consejos accionables y en español'),
            SizedBox(height: 8),
            _Benefit(icon: Icons.visibility, text: 'Preguntas ilimitadas sobre tus finanzas'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Ahora no'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.champagneGold,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Activar Premium'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await _profileService.activatePremium();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Premium activado! 🎉')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  /// Nivel de salud financiera de 0 a 100, combinando tasa de ahorro
  /// (50 pts) y carga de deuda DTI (50 pts).
  double _healthScore(HomeDashboard home) {
    if (home.income <= 0) return 0;
    final savingsRate = (home.income - home.expense) / home.income;
    final dti = home.debtMonthly / home.income;

    double savingsScore;
    if (savingsRate >= 0.20) {
      savingsScore = 50;
    } else if (savingsRate >= 0) {
      savingsScore = (savingsRate / 0.20) * 50;
    } else {
      savingsScore = 0;
    }

    double dtiScore;
    if (dti <= 0.36) {
      dtiScore = 50;
    } else if (dti <= 0.50) {
      dtiScore = ((0.50 - dti) / 0.14) * 50;
    } else {
      dtiScore = 0;
    }

    return (savingsScore + dtiScore).clamp(0.0, 100.0);
  }

  Color _healthColor(double score) {
    if (score >= 70) return AppColors.emerald;
    if (score >= 40) return AppColors.amber;
    return AppColors.coral;
  }

  Widget _healthIndicator(HomeDashboard home) {
    final score = _healthScore(home);
    final color = _healthColor(score);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Salud financiera',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.65),
                fontSize: 12,
              ),
            ),
            const Spacer(),
            Text(
              '${score.round()}%',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        AnimatedProgress(
          value: score / 100.0,
          color: color,
          backgroundColor: Colors.white.withValues(alpha: 0.12),
          height: 8,
        ),
      ],
    );
  }

  Widget _miniFlow(IconData icon, String label, double value, Color color,
      {bool hide = false}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 11)),
                const SizedBox(height: 2),
                MoneyText(value,
                    hide: hide,
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _upcomingCard(HomeDashboard home) {
    final items = home.upcomingPayments;
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.event_available, color: AppColors.amber),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Próximos vencimientos',
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              if (items.isNotEmpty)
                TextButton(
                  onPressed: () => widget.onSwitchTab?.call(1),
                  child: const Text('Ver deudas'),
                ),
            ],
          ),
          const SizedBox(height: 4),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('No tienes pagos próximos.'),
            )
          else
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) const Divider(height: 1),
              _upcomingRow(items[i]),
            ],
        ],
      ),
    );
  }

  Widget _upcomingRow(UpcomingPayment p) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.amber.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.payment, color: AppColors.amber, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.name,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(_dueLabel(p.dueDate),
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          MoneyText(p.minimumPayment,
              style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => _markPaid(p),
            icon: const Icon(Icons.check_circle_outline),
            color: AppColors.emerald,
            tooltip: 'Marcar como pagado',
          ),
        ],
      ),
    );
  }

  Widget _debtSummaryCard(HomeDashboard home) {
    final progress = home.debtTotal > 0
        ? (home.debtMonthly / home.debtTotal).clamp(0.0, 1.0)
        : 0.0;
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_wallet_outlined,
                  color: AppColors.coral),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Resumen de deudas',
                    style: Theme.of(context).textTheme.titleMedium),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedMoney(
            home.debtTotal,
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          Text(
              '${home.debtCount} deuda${home.debtCount == 1 ? '' : 's'} activas',
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 14),
          AnimatedProgress(
            value: progress,
            color: AppColors.coral,
            height: 8,
          ),
          const SizedBox(height: 10),
          Text(
            'Cuota mensual: ${AppState.instance.formatAmount(home.debtMonthly)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const DebtPlanScreen()),
              ),
              icon: const Icon(Icons.timeline, size: 18),
              label: const Text('Ver estrategia de pago'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _expensesCard(HomeDashboard home) {
    final cats = home.topCategories;
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Gastos del mes',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          if (cats.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Aún no hay gastos este mes.'),
            )
          else
            Row(
              children: [
                SizedBox(width: 140, height: 140, child: _donut(cats)),
                const SizedBox(width: 16),
                Expanded(child: _categoryLegend(cats)),
              ],
            ),
        ],
      ),
    );
  }

  Widget _donut(List<TopCategory> cats) {
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
                  radius: 40,
                  showTitle: false,
                ),
            ],
            centerSpaceRadius: 30,
            sectionsSpace: 2,
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${cats.length}',
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 18)),
            const Text('cat.', style: TextStyle(fontSize: 10)),
          ],
        ),
      ],
    );
  }

  Widget _categoryLegend(List<TopCategory> cats) {
    final total = cats.fold<double>(0, (s, c) => s + c.spent);
    return Column(
      children: [
        for (var i = 0; i < cats.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: debtColors[i % debtColors.length],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(cats[i].name,
                      style: const TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: 6),
                Text(
                  total > 0
                      ? '${((cats[i].spent / total) * 100).toStringAsFixed(0)}%'
                      : '0%',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _budgetCard() {
    final s = _budgetSummary;
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.savings_outlined, color: AppColors.emerald),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Presupuesto',
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
          if (s == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Cargando presupuesto…'),
            )
          else ...[
            _budgetProgress(s),
            if (s.categories.where((c) => c.budget > 0).isNotEmpty) ...[
              const SizedBox(height: 14),
              Text('Categorías con presupuesto',
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 6),
              for (final c in s.categories.where((c) => c.budget > 0).take(4))
                _budgetCategoryRow(c),
            ],
          ],
        ],
      ),
    );
  }

  Widget _budgetProgress(BudgetSummary s) {
    final symbol = AppState.instance.symbol;
    final spent = s.totalSpent;
    final budget = s.globalBudget ?? s.totalBudget;
    final pct = budget > 0 ? (spent / budget).clamp(0.0, 1.0) : 0.0;
    final over = budget > 0 && spent > budget;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                budget > 0
                    ? '$symbol${spent.toStringAsFixed(2)} de $symbol${budget.toStringAsFixed(2)}'
                    : 'Gastado: $symbol${spent.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            if (budget > 0)
              Text('${(pct * 100).round()}%',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: over ? AppColors.coral : AppColors.emerald,
                  )),
          ],
        ),
        const SizedBox(height: 8),
        AnimatedProgress(
          value: pct,
          color: over ? AppColors.coral : AppColors.emerald,
          height: 8,
        ),
        const SizedBox(height: 6),
        Text(
          budget > 0
              ? (over
                  ? 'Sobregasto de $symbol${(spent - budget).toStringAsFixed(2)}'
                  : 'Quedan $symbol${(budget - spent).toStringAsFixed(2)}')
              : 'Sin presupuesto global definido',
          style: TextStyle(
            color: over ? AppColors.coral : null,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _budgetCategoryRow(BudgetCategory c) {
    final symbol = AppState.instance.symbol;
    final over = c.budget > 0 && c.spent > c.budget;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(c.name,
                style: const TextStyle(fontSize: 13),
                overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 8),
          Text(
            '$symbol${c.spent.toStringAsFixed(0)} / $symbol${c.budget.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 12,
              color: over ? AppColors.coral : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _strategyCard() {
    final home = _home;
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.timeline, color: AppColors.champagneGold),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Estrategia de pago',
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const DebtPlanScreen()),
                ),
                child: const Text('Calcular'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (home == null || home.debtCount == 0)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('No tienes deudas registradas.'),
            )
          else ...[
            Text(
              '${home.debtCount} deuda${home.debtCount == 1 ? '' : 's'} · '
              'pago mensual ${AppState.instance.formatAmount(home.debtMonthly)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            const _StrategyMethod(
              icon: Icons.snowing,
              color: AppColors.emerald,
              title: 'Bola de nieve',
              desc: 'Paga primero la deuda de menor saldo para ganar impulso.',
            ),
            const SizedBox(height: 8),
            const _StrategyMethod(
              icon: Icons.trending_down,
              color: AppColors.coral,
              title: 'Avalancha',
              desc: 'Paga primero la deuda con mayor interés para ahorrar más.',
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const DebtPlanScreen()),
                ),
                icon: const Icon(Icons.calculate_outlined, size: 18),
                label: const Text('Ver plan de pago'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _babylonCard() {
    final home = _home;
    final income = home?.income ?? 0;
    final expense = home?.expense ?? 0;
    final tenPercent = income * 0.10;
    final saving = income - expense;
    final meetsGoal = income > 0 && saving >= tenPercent;

    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_stories,
                  color: AppColors.champagneGold),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Método Babilonia',
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => BabylonScreen(
                      monthlyIncome: income > 0 ? income : null,
                      monthlyExpense: expense > 0 ? expense : null,
                    ),
                  ),
                ),
                child: const Text('Ver método'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            '«Una parte de todo lo que ganes es tuya para conservar.»',
            style: TextStyle(fontStyle: FontStyle.italic, fontSize: 13),
          ),
          if (income > 0) ...[
            const SizedBox(height: 12),
            Text(
              'Aparta al menos el 10% (${AppState.instance.formatAmount(tenPercent)}) '
              'de tus ${AppState.instance.formatAmount(income)} mensuales.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 10),
            AnimatedProgress(
              value: income > 0 ? (saving / tenPercent).clamp(0.0, 1.0) : 0.0,
              color: meetsGoal ? AppColors.emerald : AppColors.amber,
              height: 8,
            ),
            const SizedBox(height: 6),
            Text(
              meetsGoal
                  ? '✓ Cumples la regla del 10%'
                  : 'Te faltan ${AppState.instance.formatAmount(tenPercent - saving)} para el 10%',
              style: TextStyle(
                color: meetsGoal ? AppColors.emerald : AppColors.amber,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _recentCard() {
    final recent = _transactions.take(5).toList();
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Movimientos recientes',
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              if (recent.isNotEmpty)
                TextButton(
                  onPressed: () => widget.onSwitchTab?.call(2),
                  child: const Text('Ver todos'),
                ),
            ],
          ),
          if (recent.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Aún no hay movimientos.'),
            )
          else
            for (var i = 0; i < recent.length; i++) ...[
              if (i > 0) const Divider(height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: (recent[i].type == 'income'
                          ? AppColors.emerald
                          : AppColors.coral)
                      .withValues(alpha: 0.15),
                  child: Icon(
                    recent[i].type == 'income'
                        ? Icons.arrow_downward
                        : Icons.arrow_upward,
                    color: recent[i].type == 'income'
                        ? AppColors.emerald
                        : AppColors.coral,
                    size: 20,
                  ),
                ),
                title: Text(recent[i].category?.name ??
                    (recent[i].type == 'income' ? 'Ingreso' : 'Gasto')),
                subtitle: Text(_formatDate(recent[i].date)),
                trailing: MoneyText(
                  recent[i].amount,
                  sign: recent[i].type == 'income',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: recent[i].type == 'income'
                        ? AppColors.emerald
                        : AppColors.coral,
                  ),
                ),
              ),
            ],
        ],
      ),
    );
  }

  /// Tarjeta de sección con esquinas redondeadas y sombra sutil.
  Widget _sectionCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _Benefit extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Benefit({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.champagneGold),
        const SizedBox(width: 10),
        Expanded(child: Text(text)),
      ],
    );
  }
}

class _StrategyMethod extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String desc;
  const _StrategyMethod({
    required this.icon,
    required this.color,
    required this.title,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14)),
                Text(desc,
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
