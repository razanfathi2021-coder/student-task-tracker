/// Pure logic helpers - kept plugin-free so they can be unit tested.

/// Returns transactions belonging to [month] (same year and month).
/// Transactions with missing or invalid dates are ignored.
List<Map<String, dynamic>> transactionsForMonth(
  List<Map<String, dynamic>> transactions, {
  DateTime? month,
}) {
  final selectedMonth = month ?? DateTime.now();
  return transactions.where((transaction) {
    final rawDate = transaction['date'];
    if (rawDate is! String) return false;
    final date = DateTime.tryParse(rawDate);
    return date != null &&
        date.year == selectedMonth.year &&
        date.month == selectedMonth.month;
  }).toList();
}

/// Monthly budget summary from dated transactions.
/// Each transaction: {'type': 'income'|'expense', 'amount': num, 'date': ISO-8601 string}.
/// Only transactions in [month] are included; defaults to the current month.
Map<String, double> monthlyBudget(
  List<Map<String, dynamic>> transactions, {
  DateTime? month,
}) {
  double income = 0;
  double expense = 0;

  for (final transaction in transactionsForMonth(transactions, month: month)) {
    final rawAmount = transaction['amount'];
    if (rawAmount is! num || !rawAmount.isFinite || rawAmount < 0) continue;

    if (transaction['type'] == 'income') {
      income += rawAmount.toDouble();
    } else if (transaction['type'] == 'expense') {
      expense += rawAmount.toDouble();
    }
  }

  return {'income': income, 'expense': expense, 'balance': income - expense};
}

/// Sort tasks by due date; tasks without a due date go last.
/// Undone tasks come before done ones within the same date group.
List<Map<String, dynamic>> sortTasks(List<Map<String, dynamic>> tasks) {
  final list = List<Map<String, dynamic>>.from(tasks);
  list.sort((a, b) {
    if (a['is_done'] != b['is_done']) return a['is_done'] == 1 ? 1 : -1;
    final ad = a['due_date'] as String?;
    final bd = b['due_date'] as String?;
    if (ad == null && bd == null) return 0;
    if (ad == null) return 1;
    if (bd == null) return -1;
    return ad.compareTo(bd);
  });
  return list;
}
