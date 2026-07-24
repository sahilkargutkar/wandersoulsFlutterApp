import 'package:equatable/equatable.dart';

class BudgetCategory extends Equatable {
  final double accommodation;
  final double food;
  final double transportation;
  final double activities;
  final double others;

  const BudgetCategory({
    required this.accommodation,
    required this.food,
    required this.transportation,
    required this.activities,
    required this.others,
  });

  @override
  List<Object?> get props => [
    accommodation,
    food,
    transportation,
    activities,
    others,
  ];
}
