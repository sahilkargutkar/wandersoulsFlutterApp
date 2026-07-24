import 'package:wonder_souls/src/features/auth/domain/enitiy/budget_category.dart';

class Budget {
  final double totalEstimated;
  final double totalSpent;
  final String currency;
  final BudgetCategory byCategory;

  const Budget({
    required this.totalEstimated,
    required this.totalSpent,
    required this.currency,
    required this.byCategory,
  });

  Budget copyWith({
    double? totalEstimated,
    double? totalSpent,
    String? currency,
    BudgetCategory? byCategory,
  }) {
    return Budget(
      totalEstimated: totalEstimated ?? this.totalEstimated,
      totalSpent: totalSpent ?? this.totalSpent,
      currency: currency ?? this.currency,
      byCategory: byCategory ?? this.byCategory,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Budget &&
          other.totalEstimated == totalEstimated &&
          other.totalSpent == totalSpent &&
          other.currency == currency &&
          other.byCategory == byCategory;

  @override
  int get hashCode =>
      totalEstimated.hashCode ^
      totalSpent.hashCode ^
      currency.hashCode ^
      byCategory.hashCode;
}
