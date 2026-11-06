import 'package:flutter/material.dart';

import '../../core/app_colors.dart';

// Paleta de visualización armonizada con la identidad "Midnight Emerald".
// Tonos apagados y premium, sin azules/púrpuras estridentes.
const List<Color> debtColors = [
  AppColors.emerald, // #12B886
  AppColors.emeraldDeep, // #087F5B
  AppColors.coral, // #E5737A
  AppColors.amber, // #F2B54B
  AppColors.champagneGold, // #D4B26A
  AppColors.navy700, // #14233A
  AppColors.slate, // #8A97A8
  Color(0xFF4FB3A0), // verde azulado apagado
  Color(0xFFC77E8E), // rosa apagado
  Color(0xFF7E93B8), // azul grisáceo suave
];

String colorToHex(Color c) {
  final hex = c.toARGB32().toRadixString(16).substring(2).toUpperCase();
  return '#$hex';
}

Color hexToColor(String hex) {
  final s = hex.replaceFirst('#', '');
  return Color(int.parse('FF$s', radix: 16));
}

Color debtColor(String? hex, int index) {
  if (hex != null && hex.startsWith('#')) return hexToColor(hex);
  return debtColors[index % debtColors.length];
}
