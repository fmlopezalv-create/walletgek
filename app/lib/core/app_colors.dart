import 'package:flutter/material.dart';

/// Identidad visual premium "Midnight Emerald".
/// Semántica de color (nada más, para que el color comunique):
///  - Esmeralda: ingresos y avances.
///  - Coral suave: deudas y gastos (nunca rojo puro).
///  - Ámbar: vencimientos próximos / avisos.
class AppColors {
  AppColors._();

  // Fondo casi negro con tinte azul profundo (base oscura)
  static const Color midnightBlack = Color(0xFF050B14);
  // Azul profundo — degradados, appbar
  static const Color midnightNavy = Color(0xFF0B1B2E);
  // Tarjeta en tono ligeramente más claro que el fondo
  static const Color navy700 = Color(0xFF14233A);
  // Acento principal — ingresos, avances, positivo
  static const Color emerald = Color(0xFF12B886);
  // Verde apagado sobre fondo claro
  static const Color emeraldDeep = Color(0xFF087F5B);
  // Acento neutro premium — sólo detalles, sin significado
  static const Color champagneGold = Color(0xFFD4B26A);
  // Fondo claro
  static const Color iceWhite = Color(0xFFF4F6F9);
  // Texto secundario
  static const Color slate = Color(0xFF8A97A8);
  // Deudas / gastos — coral suave (no rojo puro)
  static const Color coral = Color(0xFFE5737A);
  // Vencimientos próximos / avisos
  static const Color amber = Color(0xFFF2B54B);
}
