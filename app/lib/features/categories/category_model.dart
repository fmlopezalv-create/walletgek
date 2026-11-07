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
