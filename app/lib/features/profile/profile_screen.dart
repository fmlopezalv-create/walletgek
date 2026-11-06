import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_colors.dart';
import '../../core/app_state.dart';
import '../../core/country.dart';
import '../../core/currency.dart';
import '../auth/auth_service.dart';
import '../auth/login_screen.dart';
import 'backup_service.dart';
import 'profile_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _service = ProfileService();
  final _auth = AuthService();
  final _backup = BackupService();
  UserProfile? _profile;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final p = await _service.getProfile();
      setState(() => _profile = p);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Seguro que quieres cerrar sesión?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.coral),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await _auth.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _backupData() async {
    try {
      final data = await _backup.exportBackup();
      final json = const JsonEncoder.withIndent('  ').convert(data);
      await Clipboard.setData(ClipboardData(text: json));
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Copia de seguridad'),
          content: const Text(
              'Se ha copiado la copia de seguridad al portapapeles. '
              'Guárdala en un lugar seguro (notas, correo, etc.).'),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Entendido'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _restoreData() async {
    final controller = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restaurar copia de seguridad'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Pega aquí el contenido del backup (JSON). '
              'Esto reemplazará todos tus datos actuales.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 6,
              minLines: 4,
              decoration: const InputDecoration(
                hintText: '{ "app": "walletgek", ... }',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar')),
          FilledButton(
            onPressed: () async {
              final text = controller.text.trim();
              if (text.isEmpty) return;
              try {
                final json = jsonDecode(text) as Map<String, dynamic>;
                await _backup.restoreBackup(json);
                if (ctx.mounted) Navigator.of(ctx).pop();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Datos restaurados correctamente')),
                  );
                  _load();
                }
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx)
                      .showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('Restaurar'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Borrar todo'),
        content: const Text(
            'Se eliminarán todas las categorías, movimientos, deudas y pagos. '
            'Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.coral),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Borrar todo'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _backup.clearAll();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Todos los datos fueron eliminados')),
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

  Future<void> _editCurrency() async {
    String currency = _profile?.currency ?? AppState.instance.currencyCode;
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Moneda'),
          content: DropdownButtonFormField<String>(
            initialValue: currency,
            decoration: const InputDecoration(labelText: 'Moneda'),
            items: currencies
                .map((c) => DropdownMenuItem(
                      value: c.code,
                      child: Text('${c.code} (${c.symbol})'),
                    ))
                .toList(),
            onChanged: (v) => setDialogState(() => currency = v ?? 'EUR'),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancelar')),
            FilledButton(
              onPressed: () async {
                try {
                  final p = await _service.updateProfile(currency: currency);
                  if (ctx.mounted) Navigator.of(ctx).pop();
                  if (mounted) setState(() => _profile = p);
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

  Future<void> _editCountry() async {
    String country = _profile?.country ?? AppState.instance.countryCode;
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('País'),
          content: DropdownButtonFormField<String>(
            initialValue: country,
            decoration: const InputDecoration(labelText: 'País'),
            items: countries
                .map((c) => DropdownMenuItem(
                      value: c.code,
                      child: Text('${c.flag} ${c.name}'),
                    ))
                .toList(),
            onChanged: (v) => setDialogState(() => country = v ?? 'ES'),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancelar')),
            FilledButton(
              onPressed: () async {
                try {
                  final p = await _service.updateProfile(country: country);
                  if (ctx.mounted) Navigator.of(ctx).pop();
                  if (mounted) setState(() => _profile = p);
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

  Future<void> _editBudget() async {
    final controller = TextEditingController(
      text: _profile?.monthlyBudget?.toStringAsFixed(2) ?? '',
    );
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Presupuesto mensual global'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Presupuesto (0 = sin límite)',
            prefixText: '${AppState.instance.symbol} ',
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar')),
          FilledButton(
            onPressed: () async {
              final v = double.tryParse(controller.text.replaceAll(',', '.'));
              try {
                final p = await _service.updateProfile(monthlyBudget: v);
                if (ctx.mounted) Navigator.of(ctx).pop();
                if (mounted) setState(() => _profile = p);
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

  Future<void> _editTheme() async {
    String themeMode = AppState.instance.themeMode;
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Tema'),
          content: DropdownButtonFormField<String>(
            initialValue: themeMode,
            decoration: const InputDecoration(labelText: 'Tema'),
            items: const [
              DropdownMenuItem(value: 'system', child: Text('Sistema')),
              DropdownMenuItem(value: 'light', child: Text('Claro')),
              DropdownMenuItem(value: 'dark', child: Text('Oscuro')),
            ],
            onChanged: (v) => setDialogState(() => themeMode = v ?? 'system'),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancelar')),
            FilledButton(
              onPressed: () async {
                await AppState.instance.setThemeMode(themeMode);
                if (ctx.mounted) Navigator.of(ctx).pop();
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.all(40),
                child: Center(child: Text('Error: $_error')),
              )
            else ...[
              _header(context),
              const SizedBox(height: 16),
              _settingsCard(context),
              const SizedBox(height: 16),
              _dataCard(context),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout, color: AppColors.coral),
                label: const Text('Cerrar sesión',
                    style: TextStyle(color: AppColors.coral)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: AppColors.coral),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Text('walletgek',
                    style: Theme.of(context).textTheme.bodySmall),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    final p = _profile!;
    final initial =
        p.name.isNotEmpty ? p.name.substring(0, 1).toUpperCase() : '?';
    return Row(
      children: [
        CircleAvatar(
          radius: 32,
          backgroundColor: AppColors.emerald,
          child: Text(initial,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(p.name.isEmpty ? 'Usuario' : p.name,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(p.email, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }

  Widget _settingsCard(BuildContext context) {
    final p = _profile!;
    final currency = currencies.firstWhere(
      (c) => c.code == p.currency,
      orElse: () => currencies.first,
    );
    final country = countryByCode(p.country);
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.payments_outlined),
            title: const Text('Moneda'),
            subtitle: Text('${currency.code} (${currency.symbol})'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _editCurrency,
          ),
          ListTile(
            leading: const Icon(Icons.public),
            title: const Text('País'),
            subtitle: Text('${country.flag} ${country.name}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _editCountry,
          ),
          ListTile(
            leading: const Icon(Icons.savings_outlined),
            title: const Text('Presupuesto mensual global'),
            subtitle: Text(p.monthlyBudget != null && p.monthlyBudget! > 0
                ? '${AppState.instance.symbol}${p.monthlyBudget!.toStringAsFixed(2)}'
                : 'Sin límite'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _editBudget,
          ),
          ListTile(
            leading: const Icon(Icons.brightness_6_outlined),
            title: const Text('Tema'),
            subtitle: Text(AppState.instance.themeMode == 'dark'
                ? 'Oscuro'
                : AppState.instance.themeMode == 'light'
                    ? 'Claro'
                    : 'Sistema'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _editTheme,
          ),
        ],
      ),
    );
  }

  Widget _dataCard(BuildContext context) {
    return Card(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                const Icon(Icons.shield_outlined,
                    size: 18, color: AppColors.champagneGold),
                const SizedBox(width: 8),
                Text('Datos y seguridad',
                    style: Theme.of(context).textTheme.titleSmall),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.cloud_upload_outlined),
            title: const Text('Copia de seguridad'),
            subtitle: const Text('Exporta tus datos como JSON'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _backupData,
          ),
          ListTile(
            leading: const Icon(Icons.cloud_download_outlined),
            title: const Text('Restablecer desde copia'),
            subtitle: const Text('Restaura tus datos desde un backup'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _restoreData,
          ),
          ListTile(
            leading: const Icon(Icons.delete_sweep_outlined,
                color: AppColors.coral),
            title: const Text('Borrar todo',
                style: TextStyle(color: AppColors.coral)),
            subtitle: const Text('Elimina movimientos, deudas y categorías'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _clearAll,
          ),
        ],
      ),
    );
  }
}
