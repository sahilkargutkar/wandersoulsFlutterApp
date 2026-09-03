class TripExpenseModel {
  final String id;
  final String tripId;
  final String title;
  final double amount;
  final String category; // Transportation, Accommodation, Food, Activities, Others
  final String currency;
  final String? notes;
  final DateTime? date;
  final String? payer;

  TripExpenseModel({
    required this.id,
    required this.tripId,
    required this.title,
    required this.amount,
    required this.category,
    this.currency = "USD",
    this.notes,
    this.date,
    this.payer,
  });

  factory TripExpenseModel.fromJson(Map<String, dynamic> json) {
    final rawAmount = json['amount'] ??
        json['cost'] ??
        json['price'] ??
        json['total'] ??
        json['expenseAmount'] ??
        0;
    final double amountVal = (rawAmount is num)
        ? rawAmount.toDouble()
        : (double.tryParse(rawAmount.toString()) ?? 0.0);

    final rawDate = json['date'] ??
        json['expenseDate'] ??
        json['createdAt'] ??
        json['dateTime'];
    final DateTime? parsedDate =
        rawDate != null ? DateTime.tryParse(rawDate.toString()) : null;

    final idVal = (json['id'] ??
            json['expenseId'] ??
            json['_id'] ??
            '')
        .toString();
    final tripIdVal =
        (json['tripId'] ?? json['TripId'] ?? '').toString();
    final titleVal = (json['title'] ??
            json['name'] ??
            json['description'] ??
            'Expense')
        .toString();
    final categoryVal =
        (json['category'] ?? json['categoryName'] ?? 'Others').toString();
    final currencyVal = (json['currency'] ?? 'USD').toString();
    final notesVal = (json['notes'] ?? json['comment'] ?? '').toString();
    final payerVal = (json['payer'] ?? json['paidBy'] ?? '').toString();

    return TripExpenseModel(
      id: idVal,
      tripId: tripIdVal,
      title: titleVal,
      amount: amountVal,
      category: categoryVal,
      currency: currencyVal,
      notes: notesVal.isNotEmpty ? notesVal : null,
      date: parsedDate,
      payer: payerVal.isNotEmpty ? payerVal : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) "id": id,
      if (id.isNotEmpty) "expenseId": id,
      "tripId": tripId,
      "TripId": tripId,
      "title": title,
      "name": title,
      "amount": amount,
      "cost": amount,
      "category": category,
      "currency": currency,
      "notes": notes ?? "",
      "date": (date ?? DateTime.now()).toUtc().toIso8601String(),
      "payer": payer ?? "",
    };
  }

  TripExpenseModel copyWith({
    String? id,
    String? tripId,
    String? title,
    double? amount,
    String? category,
    String? currency,
    String? notes,
    DateTime? date,
    String? payer,
  }) {
    return TripExpenseModel(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      currency: currency ?? this.currency,
      notes: notes ?? this.notes,
      date: date ?? this.date,
      payer: payer ?? this.payer,
    );
  }
}
