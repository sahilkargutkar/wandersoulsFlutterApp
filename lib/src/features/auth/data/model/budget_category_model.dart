import 'package:wonder_souls/src/features/auth/domain/enitiy/budget_category.dart';

class BudgetCategoryModel extends BudgetCategory {
  const BudgetCategoryModel({
    required super.transportation,
    required super.accommodation,
    required super.food,
    required super.activities,
    required super.others,
  });

  /// FROM JSON
  factory BudgetCategoryModel.fromJson(Map<String, dynamic> json) {
    return BudgetCategoryModel(
      transportation: (json['transportation'] ?? 0).toDouble(),
      accommodation: (json['accommodation'] ?? 0).toDouble(),
      food: (json['food'] ?? 0).toDouble(),
      activities: (json['activities'] ?? 0).toDouble(),
      others: (json['others'] ?? 0).toDouble(),
    );
  }

  /// TO JSON
  Map<String, dynamic> toJson() {
    return {
      'transportation': transportation,
      'accommodation': accommodation,
      'food': food,
      'activities': activities,
      'others': others, // 👈 you forgot this
    };
  }
}
