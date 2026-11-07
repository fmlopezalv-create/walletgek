import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/app_colors.dart';
import '../../core/app_state.dart';
import 'advisor_service.dart';

class AdvisorScreen extends StatefulWidget {
  const AdvisorScreen({super.key});

  @override
  State<AdvisorScreen> createState() => _AdvisorScreenState();
}

class _AdvisorScreenState extends State<AdvisorScreen> {
  final _service = AdvisorService();
  final _controller = TextEditingController();
  final _scroll = ScrollController();

  final List<_ChatMessage> _messages = [];
  bool _sending = false;

  String get _historyKey =>
      'advisor_history_${AppState.instance.userEmail}';

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    const greeting = _ChatMessage(
      text: 'Hola 👋 Soy tu asesor financiero. Cuéntame qué quieres revisar: '
          'tus deudas, tu presupuesto, cómo ahorrar más…',
      isUser: false,
    );
    try {
      final sp = await SharedPreferences.getInstance();
      final raw = sp.getString(_historyKey);
      if (raw != null && raw.isNotEmpty) {
        final list = (jsonDecode(raw) as List)
            .map((e) =>
                _ChatMessage.fromJson((e as Map).cast<String, dynamic>()))
            .toList();
        if (mounted) setState(() => _messages.addAll(list));
        return;
      }
    } catch (_) {}
    if (mounted) setState(() => _messages.add(greeting));
  }

  Future<void> _saveHistory() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final json = jsonEncode(_messages.map((m) => m.toJson()).toList());
      await sp.setString(_historyKey, json);
    } catch (_) {}
  }

  String _friendlyError(String raw) {
    final r = raw.toLowerCase();
    if (r.contains('deepseek_api_key') || r.contains('falta configurar')) {
      return 'El asesor aún no está configurado en el servidor. '
          'Inténtalo más tarde.';
    }
    if (r.contains('premium')) {
      return 'El asesor financiero es una función Premium. '
          'Activa Premium para usarlo.';
    }
    if (r.contains('demasiados') || r.contains('429')) {
      return 'Has hecho muchas preguntas. Espera unos minutos e inténtalo de nuevo.';
    }
    return 'No pude obtener una respuesta ahora. Inténtalo de nuevo.';
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _sending = true;
    });
    _controller.clear();
    _saveHistory();
    _scrollToBottom();

    try {
      final reply = await _service.ask(text);
      if (mounted) {
        setState(() {
          _messages.add(_ChatMessage(text: reply, isUser: false));
        });
        _saveHistory();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(_ChatMessage(
            text: _friendlyError(e.toString()),
            isUser: false,
            isError: true,
          ));
        });
        _saveHistory();
      }
    } finally {
      if (mounted) setState(() => _sending = false);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Asesor financiero'),
        actions: [
          Icon(Icons.auto_awesome, color: AppColors.champagneGold, size: 20),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: AppColors.champagneGold.withValues(alpha: 0.1),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                const Icon(Icons.verified, color: AppColors.champagneGold, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Premium activo · consejos con tus datos reales',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              'Los consejos son orientativos y no sustituyen la asesoría de un '
              'profesional financiero certificado.',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_sending ? 1 : 0),
              itemBuilder: (context, index) {
                if (_sending && index == _messages.length) {
                  return _typingBubble();
                }
                return _bubble(_messages[index]);
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      onSubmitted: (_) => _send(),
                      textInputAction: TextInputAction.send,
                      decoration: InputDecoration(
                        hintText: 'Pregúntame sobre tus finanzas…',
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.send),
                          color: AppColors.emerald,
                          onPressed: _sending ? null : _send,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _typingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Text(
          'Escribiendo…',
          style: TextStyle(fontStyle: FontStyle.italic),
        ),
      ),
    );
  }

  Widget _bubble(_ChatMessage m) {
    final isUser = m.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? AppColors.emerald
              : m.isError
                  ? AppColors.coral.withValues(alpha: 0.15)
                  : Theme.of(context).cardColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
        ),
        child: Text(
          m.text,
          style: TextStyle(
            color: isUser ? Colors.white : null,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;
  final bool isError;
  const _ChatMessage({
    required this.text,
    required this.isUser,
    this.isError = false,
  });

  Map<String, dynamic> toJson() => {
        'text': text,
        'isUser': isUser,
        'isError': isError,
      };

  factory _ChatMessage.fromJson(Map<String, dynamic> json) => _ChatMessage(
        text: json['text'] as String? ?? '',
        isUser: json['isUser'] == true,
        isError: json['isError'] == true,
      );
}
