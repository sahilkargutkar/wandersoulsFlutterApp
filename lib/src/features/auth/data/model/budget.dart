import 'package:wonder_souls/src/features/auth/data/model/budget_category_model.dart';
import 'package:wonder_souls/src/features/auth/domain/enitiy/budget.dart';
class BudgetModel extends Budget {
  const BudgetModel({
    required super.totalEstimated,
    required super.totalSpent,
    required super.currency,
    required super.byCategory,
  });

  factory BudgetModel.fromJson(Map<String, dynamic> json) {
    return BudgetModel(
      totalEstimated: (json['totalEstimated'] ?? 0).toDouble(),
      totalSpent: (json['totalSpent'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'USD',
      byCategory: BudgetCategoryModel.fromJson(json['byCategory']),
    );
  }
}
