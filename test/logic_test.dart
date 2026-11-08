import 'package:flutter_test/flutter_test.dart';
import 'package:student_task_tracker/logic.dart';

void main() {
  group('monthlyBudget', () {
    test('includes only transactions from the selected month', () {
      final txs = [
        {'type': 'income', 'amount': 300.0, 'date': '2026-11-01T10:00:00'},
        {'type': 'expense', 'amount': 120.5, 'date': '2026-11-03T12:00:00'},
        {'type': 'expense', 'amount': 30.0, 'date': '2026-11-08T09:00:00'},
        {'type': 'expense', 'amount': 900.0, 'date': '2026-10-31T23:59:00'},
        {'type': 'income', 'amount': 500.0, 'date': '2025-11-01T10:00:00'},
      ];

      final result = monthlyBudget(txs, month: DateTime(2026, 11));
      expect(result['income'], 300.0);
      expect(result['expense'], 150.5);
      expect(result['balance'], 149.5);
    });

    test('empty list gives zeros', () {
      final result = monthlyBudget([], month: DateTime(2026, 11));
      expect(result['income'], 0.0);
      expect(result['expense'], 0.0);
      expect(result['balance'], 0.0);
    });

    test('ignores transactions with invalid dates or amounts', () {
      final txs = [
        {'type': 'expense', 'amount': 10, 'date': 'not-a-date'},
        {'type': 'expense', 'amount': '20', 'date': '2026-11-02'},
        {'type': 'other', 'amount': 30, 'date': '2026-11-03'},
      ];
      final result = monthlyBudget(txs, month: DateTime(2026, 11));
      expect(result['income'], 0.0);
      expect(result['expense'], 0.0);
      expect(result['balance'], 0.0);
    });
  });

  group('transactionsForMonth', () {
    test('matches both month and year', () {
      final txs = [
        {'date': '2026-11-01'},
        {'date': '2026-10-31'},
        {'date': '2025-11-01'},
      ];
      expect(
        transactionsForMonth(txs, month: DateTime(2026, 11)).length,
        1,
      );
    });
  });

  group('sortTasks', () {
    test('undone tasks first, sorted by due date', () {
      final tasks = [
        {'id': 1, 'title': 'A', 'due_date': '2026-11-10', 'is_done': 1},
        {'id': 2, 'title': 'B', 'due_date': '2026-11-05', 'is_done': 0},
        {'id': 3, 'title': 'C', 'due_date': '2026-11-01', 'is_done': 0},
        {'id': 4, 'title': 'D', 'due_date': null, 'is_done': 0},
      ];
      final sorted = sortTasks(tasks);
      expect(sorted.map((e) => e['id']).toList(), [3, 2, 4, 1]);
    });
  });
}
