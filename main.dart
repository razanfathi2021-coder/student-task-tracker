import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'logic.dart';
import 'task_db.dart';

final notifications = FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tzdata.initializeTimeZones();
  await notifications.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    ),
  );
  runApp(const TrackerApp());
}

Future<void> scheduleTaskReminder(int id, String title, DateTime due) async {
  final when = due.subtract(const Duration(hours: 12));
  if (when.isBefore(DateTime.now())) return;
  await notifications.zonedSchedule(
    id,
    'Task due soon',
    title,
    tz.TZDateTime.from(when, tz.local),
    const NotificationDetails(
      android: AndroidNotificationDetails('tasks', 'Task reminders',
          importance: Importance.high),
      iOS: DarwinNotificationDetails(),
    ),
    androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
  );
}

class TrackerApp extends StatelessWidget {
  const TrackerApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int tab = 0;

  @override
  Widget build(BuildContext context) {
    final pages = const [TasksTab(), BudgetTab(), SettingsTab()];
    return Scaffold(
      body: pages[tab],
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (i) => setState(() => tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.checklist), label: 'Tasks'),
          NavigationDestination(icon: Icon(Icons.account_balance_wallet), label: 'Budget'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}

class TasksTab extends StatefulWidget {
  const TasksTab({super.key});
  @override
  State<TasksTab> createState() => _TasksTabState();
}

class _TasksTabState extends State<TasksTab> {
  List<Map<String, dynamic>> tasks = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    tasks = sortTasks(await TaskDB.getTasks());
    setState(() {});
  }

  Future<void> _addTask() async {
    final title = TextEditingController();
    DateTime? due;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: const Text('New task'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: title, decoration: const InputDecoration(labelText: 'Title')),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.calendar_today),
              label: Text(due == null ? 'Pick deadline (optional)' : DateFormat('yyyy-MM-dd').format(due!)),
              onPressed: () async {
                final picked = await showDatePicker(
                  context: ctx,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2024),
                  lastDate: DateTime(2030),
                );
                if (picked != null) setD(() => due = picked);
              },
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
          ],
        ),
      ),
    );
    if (ok == true && title.text.isNotEmpty) {
      final id = await TaskDB.addTask(title.text, due?.toIso8601String());
      if (due != null) scheduleTaskReminder(id, title.text, due!);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Tasks')),
      floatingActionButton: FloatingActionButton(onPressed: _addTask, child: const Icon(Icons.add)),
      body: tasks.isEmpty
          ? const Center(child: Text('No tasks yet - tap + to add'))
          : ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (ctx, i) {
                final t = tasks[i];
                final done = t['is_done'] == 1;
                final due = t['due_date'] == null ? null : DateTime.tryParse(t['due_date']);
                final overdue = !done && due != null && due.isBefore(DateTime.now());
                return ListTile(
                  leading: Checkbox(
                    value: done,
                    onChanged: (v) async {
                      await TaskDB.toggleTask(t['id'], v! ? 1 : 0);
                      _load();
                    },
                  ),
                  title: Text(t['title'],
                      style: TextStyle(decoration: done ? TextDecoration.lineThrough : null)),
                  subtitle: due == null
                      ? null
                      : Text(DateFormat('yyyy-MM-dd').format(due),
                          style: TextStyle(color: overdue ? Colors.red : null)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      await TaskDB.deleteTask(t['id']);
                      _load();
                    },
                  ),
                );
              },
            ),
    );
  }
}

class BudgetTab extends StatefulWidget {
  const BudgetTab({super.key});
  @override
  State<BudgetTab> createState() => _BudgetTabState();
}

class _BudgetTabState extends State<BudgetTab> {
  List<Map<String, dynamic>> txs = [];
  double monthlyAllowance = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    txs = await TaskDB.getTransactions();
    final prefs = await SharedPreferences.getInstance();
    monthlyAllowance = prefs.getDouble('monthly_allowance') ?? 0;
    setState(() {});
  }

  Future<void> _setAllowance() async {
    final ctrl = TextEditingController(text: monthlyAllowance.toString());
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Monthly allowance'),
        content: TextField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Amount')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      ),
    );
    if (ok == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('monthly_allowance', double.tryParse(ctrl.text) ?? 0);
      _load();
    }
  }

  Future<void> _addTx(String type) async {
    final amount = TextEditingController();
    final note = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(type == 'income' ? 'Add income' : 'Add expense'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
              controller: amount,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Amount')),
          TextField(controller: note, decoration: const InputDecoration(labelText: 'Note (optional)')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      ),
    );
    if (ok == true && (double.tryParse(amount.text) ?? 0) > 0) {
      await TaskDB.addTransaction(type, double.parse(amount.text), note.text);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentMonthTxs = transactionsForMonth(txs);
    final summary = monthlyBudget(txs);
    final spent = summary['expense']!;
    final left = monthlyAllowance - spent;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Monthly Budget'),
        actions: [
          IconButton(icon: const Icon(Icons.edit), onPressed: _setAllowance),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'out',
            onPressed: () => _addTx('expense'),
            child: const Icon(Icons.remove),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'in',
            onPressed: () => _addTx('income'),
            child: const Icon(Icons.add),
          ),
        ],
      ),
      body: Column(children: [
        Card(
          margin: const EdgeInsets.all(12),
          child: ListTile(
            title: Text('${left.toStringAsFixed(2)} left',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: left < 0 ? Colors.red : Colors.green)),
            subtitle: Text(
                'Allowance: ${monthlyAllowance.toStringAsFixed(2)}  •  Spent: ${spent.toStringAsFixed(2)}'),
          ),
        ),
        Expanded(
          child: currentMonthTxs.isEmpty
              ? const Center(child: Text('No transactions this month'))
              : ListView.builder(
                  itemCount: currentMonthTxs.length,
                  itemBuilder: (ctx, i) {
                    final t = currentMonthTxs[i];
                    final isIncome = t['type'] == 'income';
                    final d = DateTime.tryParse(t['date']);
                    return ListTile(
                      leading: Icon(isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                          color: isIncome ? Colors.green : Colors.red),
                      title: Text(t['note']?.isNotEmpty == true ? t['note'] : (isIncome ? 'Income' : 'Expense')),
                      subtitle: Text(d == null ? '' : DateFormat('yyyy-MM-dd').format(d)),
                      trailing: Text(
                        '${isIncome ? '+' : '-'}${(t['amount'] as num).toStringAsFixed(2)}',
                        style: TextStyle(
                            color: isIncome ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold),
                      ),
                    );
                  },
                ),
        ),
      ]),
    );
  }
}

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(children: const [
        ListTile(leading: Icon(Icons.notifications), title: Text('Task reminders'), subtitle: Text('A notification is scheduled 12 hours before each deadline.')),
        ListTile(leading: Icon(Icons.storage), title: Text('Storage'), subtitle: Text('Tasks and transactions: SQLite on device. Monthly allowance: SharedPreferences.')),
      ]),
    );
  }
}
