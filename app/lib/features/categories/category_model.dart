class Category {
  final String id;
  final String name;
  final String type; // income | expense
  final String? color;
  final double? monthlyBudget;

  Category({
    required this.id,
    required this.name,
    required this.type,
    this.color,
    this.monthlyBudget,
  });

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: json['id'] as String,
        name: json['name'] as String,
        type: json['type'] as String,
        color: json['color'] as String?,
        monthlyBudget: json['monthlyBudget'] != null
            ? double.parse(json['monthlyBudget'].toString())
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type,
        'color': color,
        'monthlyBudget': monthlyBudget,
      };
}

/// Devuelve un emoji representativo para una categoría según su nombre.
/// El primer acierto gana; si no coincide ninguno, usa un emoji genérico.
String categoryEmoji(String name) {
  final n = name.toLowerCase();
  const rules = <List<String>>[
    ['comida', '🛒'],
    ['supermercado', '🛒'],
    ['restaurante', '🍽️'],
    ['transporte', '🚗'],
    ['vivienda', '🏠'],
    ['servicio', '💡'],
    ['salud', '💊'],
    ['ocio', '🎬'],
    ['entretenimiento', '🎬'],
    ['compras', '👕'],
    ['ropa', '👕'],
    ['suscripcion', '📱'],
    ['educacion', '🎓'],
    ['deuda', '💳'],
    ['prestamo', '💳'],
    ['sueldo', '💰'],
    ['nomina', '💰'],
    ['freelance', '💼'],
    ['independiente', '💼'],
    ['venta', '💵'],
    ['ingreso', '💵'],
  ];
  for (final r in rules) {
    if (n.contains(r[0])) return r[1];
  }
  return '🏷️';
}
