import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:fends/model.dart';
import 'package:fends/helper/graph.dart';

class _ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    final numericValue = newValue.text.replaceAll(',', '');

    if (numericValue.isEmpty) {
      return newValue;
    }

    final formattedValue = _formatWithCommas(numericValue);

    return TextEditingValue(
      text: formattedValue,
      selection: TextSelection.collapsed(offset: formattedValue.length),
    );
  }

  String _formatWithCommas(String value) {
    final regex = RegExp(r'\B(?=(\d{3})+(?!\d))');
    return value.replaceAllMapped(regex, (match) => ',');
  }
}

class HomeScreen extends StatefulWidget {
  final String currency;
  final String currencySymbol;
  final double totalBudget;
  final DateTime finalDate;
  final List<Transaction> transactions;
  final List<Account> accounts;
  final List<Category> categories;
  final Function(Transaction) onAddTransaction;
  final Function(Account) onAddAccount;
  final Function(String) onDeleteTransaction;
  final Function(Transaction) onUpdateTransaction;
  final VoidCallback onReset;

  const HomeScreen({
    super.key,
    required this.currency,
    required this.currencySymbol,
    required this.totalBudget,
    required this.finalDate,
    required this.transactions,
    required this.accounts,
    required this.categories,
    required this.onAddTransaction,
    required this.onAddAccount,
    required this.onDeleteTransaction,
    required this.onUpdateTransaction,
    required this.onReset,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _navIndex = 0;

  double get _currentBalance {
    double balance = widget.totalBudget;
    for (var t in widget.transactions) {
      balance += t.isIncome ? t.amount : -t.amount;
    }
    return balance;
  }

  double get _totalSpent {
    return widget.transactions
        .where((t) => !t.isIncome)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get _totalIncome {
    return widget.transactions
        .where((t) => t.isIncome)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get _todaySpent {
    final today = DateTime.now();
    return widget.transactions
        .where(
          (t) =>
              !t.isIncome &&
              t.date.year == today.year &&
              t.date.month == today.month &&
              t.date.day == today.day,
        )
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  int get _daysLeft =>
      widget.finalDate.difference(DateTime.now()).inDays.clamp(1, 999999);
  int get _weeksLeft => (_daysLeft / 7).ceil();
  int get _monthsLeft => (_daysLeft / 30).ceil();

  double get _dailyAllowance => _daysLeft > 0 ? _currentBalance / _daysLeft : 0;
  double get _weeklyAllowance =>
      _weeksLeft > 0 ? _currentBalance / _weeksLeft : 0;
  double get _monthlyAllowance =>
      _monthsLeft > 0 ? _currentBalance / _monthsLeft : 0;

  // Calculate average daily spending
  double get _averageDailySpending {
    if (widget.transactions.isEmpty) return 0;

    final earliestTransaction = widget.transactions.reduce(
      (a, b) => a.date.isBefore(b.date) ? a : b,
    );
    final daysSinceFirstTransaction =
        DateTime.now().difference(earliestTransaction.date).inDays + 1;

    return daysSinceFirstTransaction > 0
        ? _totalSpent / daysSinceFirstTransaction
        : 0;
  }

  // Estimate when budget runs out
  DateTime? get _estimatedRunoutDate {
    if (_averageDailySpending <= 0) return null;
    final daysRemaining = _currentBalance / _averageDailySpending;
    return DateTime.now().add(Duration(days: daysRemaining.floor()));
  }

  double _getAccountBalance(String accountId) {
    final account = widget.accounts.firstWhere((a) => a.id == accountId);
    double balance = account.initialBalance;
    for (var t in widget.transactions.where((t) => t.accountId == accountId)) {
      balance += t.isIncome ? t.amount : -t.amount;
    }
    return balance;
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      symbol: widget.currencySymbol,
      decimalDigits: 0,
      locale: widget.currency == 'IDR' ? 'id_ID' : 'en_US',
    );
    return formatter.format(amount);
  }

  String get _currentTitle {
    switch (_navIndex) {
      case 0:
        return 'Overview';
      case 1:
        return 'Accounts';
      case 2:
        return 'Transactions';
      case 3:
        return 'Settings';
      default:
        return 'Fends';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(title: Text(_currentTitle), centerTitle: false),
      body: IndexedStack(
        index: _navIndex,
        children: [
          _buildOverviewTab(theme),
          _buildAccountsTab(theme),
          _buildTransactionsTab(theme),
          _buildSettingsTab(theme),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTransactionDialog(context),
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.only(left: 20, right: 20, bottom: 30),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withOpacity(0.7),
                borderRadius: BorderRadius.circular(30),
              ),
              child: NavigationBar(
                selectedIndex: _navIndex,
                onDestinationSelected: (index) {
                  setState(() => _navIndex = index);
                },
                elevation: 0,
                height: 56,
                backgroundColor: Colors.transparent,
                indicatorColor: theme.colorScheme.primaryContainer,
                labelBehavior:
                    NavigationDestinationLabelBehavior.onlyShowSelected,
                destinations: [
                  NavigationDestination(
                    icon: Icon(Icons.home_outlined),
                    selectedIcon: Icon(Icons.home),
                    label: 'Overview',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.account_balance_wallet_outlined),
                    selectedIcon: Icon(Icons.account_balance_wallet),
                    label: 'Accounts',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.receipt_long_outlined),
                    selectedIcon: Icon(Icons.receipt_long),
                    label: 'Transactions',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.settings_outlined),
                    selectedIcon: Icon(Icons.settings),
                    label: 'Settings',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewTab(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildDailySpendingFocusCard(theme),
        const SizedBox(height: 16),
        _buildBalanceGraphCard(theme),
        const SizedBox(height: 24),
        _buildAccountsOverviewCard(theme),
        const SizedBox(height: 24),
        Text(
          'Balance Trend',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _buildBalanceTrendCard(theme),
        const SizedBox(height: 24),
        _buildCategoryBreakdown(theme),
        const SizedBox(height: 100),
        _buildBudgetRunwayCard(theme),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildDailySpendingFocusCard(ThemeData theme) {
    final isOverBudget = _todaySpent > _dailyAllowance;
    final difference = _todaySpent - _dailyAllowance;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: isOverBudget
              ? Colors.red.withOpacity(0.5)
              : theme.colorScheme.outlineVariant,
          width: isOverBudget ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(16),
        color: isOverBudget
            ? Colors.red.withOpacity(0.05)
            : theme.colorScheme.surface,
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isOverBudget
                        ? Colors.red.withOpacity(0.1)
                        : theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isOverBudget
                          ? Colors.red.withOpacity(0.3)
                          : theme.colorScheme.outline.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    isOverBudget ? Icons.warning_rounded : Icons.today_rounded,
                    color: isOverBudget
                        ? Colors.red
                        : theme.colorScheme.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Today\'s Spending',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        DateFormat('EEEE, MMM d').format(DateTime.now()),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatCurrency(_todaySpent),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isOverBudget ? Colors.red : null,
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    'of ${_formatCurrency(_dailyAllowance)}',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _dailyAllowance > 0
                    ? (_todaySpent / _dailyAllowance).clamp(0.0, 1.0)
                    : 0.0,
                minHeight: 8,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                color: isOverBudget ? Colors.red : theme.colorScheme.primary,
              ),
            ),
            if (isOverBudget) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.red.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.priority_high_rounded,
                      color: Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'You\'ve exceeded today\'s budget by ${_formatCurrency(difference.abs())}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (_todaySpent > _dailyAllowance * 0.8) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.orange.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'You have ${_formatCurrency(_dailyAllowance - _todaySpent)} left for today',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetRunwayCard(ThemeData theme) {
    final runoutDate = _estimatedRunoutDate;
    final daysUntilRunout = runoutDate != null
        ? runoutDate.difference(DateTime.now()).inDays
        : null;

    final willRunOutBeforeFinalDate =
        runoutDate != null && runoutDate.isBefore(widget.finalDate);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: willRunOutBeforeFinalDate
              ? Colors.orange.withOpacity(0.5)
              : theme.colorScheme.outlineVariant,
          width: willRunOutBeforeFinalDate ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(16),
        color: willRunOutBeforeFinalDate
            ? Colors.orange.withOpacity(0.05)
            : theme.colorScheme.surface,
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: willRunOutBeforeFinalDate
                        ? Colors.orange.withOpacity(0.1)
                        : theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: willRunOutBeforeFinalDate
                          ? Colors.orange.withOpacity(0.3)
                          : theme.colorScheme.outline.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    willRunOutBeforeFinalDate
                        ? Icons.warning_amber_rounded
                        : Icons.trending_up_rounded,
                    color: willRunOutBeforeFinalDate
                        ? Colors.orange
                        : theme.colorScheme.secondary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Budget Runway',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (_averageDailySpending > 0 && runoutDate != null) ...[
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Estimated Runout',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('MMM d, yyyy').format(runoutDate),
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: willRunOutBeforeFinalDate
                                ? Colors.orange
                                : theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'in $daysUntilRunout days',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 60,
                    color: theme.colorScheme.outlineVariant,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Avg. Daily Spend',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatCurrency(_averageDailySpending),
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (willRunOutBeforeFinalDate) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.orange.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.priority_high_rounded,
                        color: Colors.orange,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Budget may run out ${widget.finalDate.difference(runoutDate).inDays} days before your target date',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.orange.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ] else ...[
              Text(
                'Not enough data to estimate',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Add more transactions to see budget runway',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAccountsOverviewCard(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Accounts',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => setState(() => _navIndex = 1),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...widget.accounts.take(3).map((account) {
          final balance = _getAccountBalance(account.id);
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: theme.colorScheme.outlineVariant,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(12),
                color: theme.colorScheme.surface,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        border: Border.all(color: account.color, width: 2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(account.icon, color: account.color, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            account.name,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            account.type
                                .toString()
                                .split('.')
                                .last
                                .toUpperCase(),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _formatCurrency(balance),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: balance >= 0 ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildBalanceTrendCard(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant, width: 1),
        borderRadius: BorderRadius.circular(16),
        color: theme.colorScheme.surface,
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SizedBox(
          height: 200,
          child: BudgetGraph(
            totalBudget: widget.totalBudget,
            transactions: widget.transactions,
            finalDate: widget.finalDate,
            colorScheme: theme.colorScheme,
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceGraphCard(ThemeData theme) {
    final progress = widget.totalBudget > 0
        ? (_currentBalance / widget.totalBudget).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant, width: 1),
        borderRadius: BorderRadius.circular(16),
        color: theme.colorScheme.surface,
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Current Balance',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    border: Border.all(
                      color: theme.colorScheme.outline.withOpacity(0.3),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$_daysLeft days left',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _formatCurrency(_currentBalance),
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'of ${_formatCurrency(widget.totalBudget)} budget',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    theme,
                    'Spent',
                    _formatCurrency(_totalSpent),
                    Colors.red,
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: theme.colorScheme.outlineVariant,
                ),
                Expanded(
                  child: _buildStatItem(
                    theme,
                    'Income',
                    _formatCurrency(_totalIncome),
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Container(height: 1, color: theme.colorScheme.outlineVariant),
            const SizedBox(height: 24),
            Text(
              'Spending Allowance',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            _buildAllowanceItem(theme, 'Daily', _dailyAllowance, Icons.today),
            const SizedBox(height: 16),
            Container(height: 1, color: theme.colorScheme.outlineVariant),
            const SizedBox(height: 16),
            _buildAllowanceItem(
              theme,
              'Weekly',
              _weeklyAllowance,
              Icons.calendar_view_week,
            ),
            const SizedBox(height: 16),
            Container(height: 1, color: theme.colorScheme.outlineVariant),
            const SizedBox(height: 16),
            _buildAllowanceItem(
              theme,
              'Monthly',
              _monthlyAllowance,
              Icons.calendar_month,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    ThemeData theme,
    String label,
    String value,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildAllowanceItem(
    ThemeData theme,
    String period,
    double amount,
    IconData icon,
  ) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.primary, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: theme.colorScheme.primary, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                period,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _formatCurrency(amount),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryBreakdown(ThemeData theme) {
    final expensesByCategory = <String, double>{};

    for (var t in widget.transactions.where((t) => !t.isIncome)) {
      expensesByCategory[t.categoryId] =
          (expensesByCategory[t.categoryId] ?? 0) + t.amount;
    }

    if (expensesByCategory.isEmpty) {
      return const SizedBox.shrink();
    }

    final sortedEntries = expensesByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Spending by Category',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: theme.colorScheme.outlineVariant,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(16),
            color: theme.colorScheme.surface,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: sortedEntries.take(5).map((entry) {
                final category = widget.categories.firstWhere(
                  (c) => c.id == entry.key,
                );
                final percentage = _totalSpent > 0
                    ? (entry.value / _totalSpent) * 100
                    : 0.0;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: category.color,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              category.icon,
                              color: category.color,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  category.name,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '${percentage.toStringAsFixed(1)}%',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            _formatCurrency(entry.value),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: percentage / 100,
                          minHeight: 6,
                          backgroundColor:
                              theme.colorScheme.surfaceContainerHighest,
                          color: category.color,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  // ACCOUNTS TAB
  Widget _buildAccountsTab(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            FilledButton.icon(
              onPressed: () => _showAddAccountDialog(context),
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Add'),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        ...widget.accounts.map((account) {
          final balance = _getAccountBalance(account.id);
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: theme.colorScheme.outlineVariant,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(16),
                color: theme.colorScheme.surface,
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        border: Border.all(color: account.color, width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(account.icon, color: account.color),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            account.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            account.type
                                .toString()
                                .split('.')
                                .last
                                .toUpperCase(),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _formatCurrency(balance),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: balance >= 0 ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  // TRANSACTIONS TAB
  Widget _buildTransactionsTab(ThemeData theme) {
    final sortedTransactions = widget.transactions.toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (sortedTransactions.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 64,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No transactions yet',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...sortedTransactions.map((transaction) {
            final category = widget.categories.firstWhere(
              (c) => c.id == transaction.categoryId,
            );
            final account = widget.accounts.firstWhere(
              (a) => a.id == transaction.accountId,
            );

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  color: theme.colorScheme.surface,
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () =>
                      _showTransactionOptionsDialog(context, transaction),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            border: Border.all(color: category.color, width: 2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            category.icon,
                            color: category.color,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                category.name,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(
                                    account.icon,
                                    size: 14,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    account.name,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  if (transaction.note.isNotEmpty) ...[
                                    const Text(' • '),
                                    Flexible(
                                      child: Text(
                                        transaction.note,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: theme
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              Text(
                                DateFormat('MMM d, y').format(transaction.date),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${transaction.isIncome ? '+' : '-'}${_formatCurrency(transaction.amount)}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: transaction.isIncome
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Icon(
                              Icons.more_vert,
                              size: 16,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        const SizedBox(height: 100),
      ],
    );
  }

  // SETTINGS TAB
  Widget _buildSettingsTab(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: theme.colorScheme.outlineVariant,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(16),
            color: theme.colorScheme.surface,
          ),
          child: Column(
            children: [
              ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('About'),
                trailing: Icon(Icons.chevron_right),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('About'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Fends',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Version 1.0.0',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'A simple budgeting app for tracking expenses and income',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  );
                },
              ),
              Container(
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                color: theme.colorScheme.outlineVariant,
              ),
              ListTile(
                leading: Icon(Icons.article_outlined),
                title: Text('License'),
                trailing: Icon(Icons.chevron_right),
                onTap: () {
                  showLicensePage(
                    context: context,
                    applicationName: 'Fends',
                    applicationVersion: '1.0.0',
                    applicationIcon: Icon(
                      Icons.account_balance_wallet,
                      size: 48,
                      color: theme.colorScheme.primary,
                    ),
                    applicationLegalese: '© 2025 Fends',
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showAddAccountDialog(BuildContext context) {
    final nameController = TextEditingController();
    final balanceController = TextEditingController();

    AccountType selectedType = AccountType.wallet;
    IconData selectedIcon = Icons.account_balance_wallet;
    Color selectedColor = Colors.teal;

    final typeIcons = {
      AccountType.wallet: Icons.account_balance_wallet,
      AccountType.bank: Icons.account_balance,
      AccountType.card: Icons.credit_card,
      AccountType.savings: Icons.savings,
      AccountType.investment: Icons.trending_up,
    };

    final colors = [
      Colors.teal,
      Colors.blue,
      Colors.purple,
      Colors.orange,
      Colors.green,
      Colors.pink,
      Colors.red,
      Colors.indigo,
    ];

    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add Account',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),

                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Account Name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  TextField(
                    controller: balanceController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Initial Balance',
                      prefixText: '${widget.currencySymbol} ',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      _ThousandsSeparatorInputFormatter(),
                    ],
                  ),

                  const SizedBox(height: 16),

                  Text(
                    'Account Type',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Wrap(
                    spacing: 8,
                    children: AccountType.values.map((type) {
                      final isSelected = selectedType == type;
                      return ChoiceChip(
                        label: Text(
                          type.toString().split('.').last.toUpperCase(),
                        ),
                        selected: isSelected,
                        onSelected: (_) {
                          setDialogState(() {
                            selectedType = type;
                            selectedIcon = typeIcons[type]!;
                          });
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 16),

                  Text(
                    'Color',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Wrap(
                    spacing: 8,
                    children: colors.map((color) {
                      final isSelected = selectedColor == color;
                      return InkWell(
                        onTap: () {
                          setDialogState(() => selectedColor = color);
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: isSelected
                                ? Border.all(
                                    color: theme.colorScheme.primary,
                                    width: 3,
                                  )
                                : null,
                          ),
                          child: isSelected
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 20,
                                )
                              : null,
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            final cleanBalance = balanceController.text
                                .replaceAll(',', '');
                            if (nameController.text.isEmpty ||
                                cleanBalance.isEmpty)
                              return;

                            widget.onAddAccount(
                              Account(
                                id: DateTime.now().millisecondsSinceEpoch
                                    .toString(),
                                name: nameController.text,
                                type: selectedType,
                                initialBalance: double.parse(cleanBalance),
                                icon: selectedIcon,
                                color: selectedColor,
                              ),
                            );

                            Navigator.pop(context);
                          },
                          child: const Text('Add'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showAddTransactionDialog(BuildContext context) {
    final amountController = TextEditingController();

    bool isIncome = false;
    Account selectedAccount = widget.accounts.first;
    Category selectedCategory = widget.categories.firstWhere(
      (c) => c.isExpense,
    );

    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add Transaction',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: false, label: Text('Expense')),
                      ButtonSegment(value: true, label: Text('Income')),
                    ],
                    selected: {isIncome},
                    onSelectionChanged: (v) {
                      setDialogState(() {
                        isIncome = v.first;
                        selectedCategory = widget.categories.firstWhere(
                          (c) => c.isExpense != isIncome,
                        );
                      });
                    },
                  ),

                  const SizedBox(height: 16),

                  TextField(
                    controller: amountController,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Amount',
                      prefixText: '${widget.currencySymbol} ',
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      _ThousandsSeparatorInputFormatter(),
                    ],
                  ),

                  const SizedBox(height: 12),

                  DropdownButtonFormField<Account>(
                    value: selectedAccount,
                    items: widget.accounts
                        .map(
                          (a) =>
                              DropdownMenuItem(value: a, child: Text(a.name)),
                        )
                        .toList(),
                    onChanged: (v) =>
                        setDialogState(() => selectedAccount = v!),
                    decoration: const InputDecoration(labelText: 'Account'),
                  ),

                  const SizedBox(height: 12),

                  DropdownButtonFormField<Category>(
                    value: selectedCategory,
                    items: widget.categories
                        .where((c) => c.isExpense != isIncome)
                        .map(
                          (c) =>
                              DropdownMenuItem(value: c, child: Text(c.name)),
                        )
                        .toList(),
                    onChanged: (v) =>
                        setDialogState(() => selectedCategory = v!),
                    decoration: const InputDecoration(labelText: 'Category'),
                  ),

                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            final clean = amountController.text.replaceAll(
                              ',',
                              '',
                            );
                            if (clean.isEmpty) return;

                            widget.onAddTransaction(
                              Transaction(
                                id: DateTime.now().millisecondsSinceEpoch
                                    .toString(),
                                amount: double.parse(clean),
                                isIncome: isIncome,
                                date: DateTime.now(),
                                accountId: selectedAccount.id,
                                categoryId: selectedCategory.id,
                                note: '',
                              ),
                            );

                            Navigator.pop(context);
                          },
                          child: const Text('Add'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showTransactionOptionsDialog(
    BuildContext context,
    Transaction transaction,
  ) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Icon(Icons.edit, color: theme.colorScheme.primary),
                title: const Text('Edit Transaction'),
                onTap: () {
                  Navigator.pop(context);
                  _showEditTransactionDialog(context, transaction);
                },
              ),
              ListTile(
                leading: Icon(Icons.delete, color: theme.colorScheme.error),
                title: const Text('Delete Transaction'),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmationDialog(context, transaction);
                },
              ),
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('Cancel'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmationDialog(
    BuildContext context,
    Transaction transaction,
  ) {
    final theme = Theme.of(context);
    final category = widget.categories.firstWhere(
      (c) => c.id == transaction.categoryId,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete this transaction?'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(category.icon, color: category.color, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.name,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          DateFormat('MMM d, y').format(transaction.date),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _formatCurrency(transaction.amount),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: transaction.isIncome ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              widget.onDeleteTransaction(transaction.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Transaction deleted'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showEditTransactionDialog(
    BuildContext context,
    Transaction transaction,
  ) {
    final amountController = TextEditingController(
      text: transaction.amount
          .toStringAsFixed(0)
          .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ','),
    );
    final noteController = TextEditingController(text: transaction.note);

    bool isIncome = transaction.isIncome;
    Account selectedAccount = widget.accounts.firstWhere(
      (a) => a.id == transaction.accountId,
    );
    Category selectedCategory = widget.categories.firstWhere(
      (c) => c.id == transaction.categoryId,
    );
    DateTime selectedDate = transaction.date;

    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Edit Transaction',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: false, label: Text('Expense')),
                      ButtonSegment(value: true, label: Text('Income')),
                    ],
                    selected: {isIncome},
                    onSelectionChanged: (v) {
                      setDialogState(() {
                        isIncome = v.first;
                        // Find a category matching the new type
                        final matchingCategories = widget.categories.where(
                          (c) => c.isExpense != isIncome,
                        );
                        if (matchingCategories.isNotEmpty) {
                          selectedCategory = matchingCategories.first;
                        }
                      });
                    },
                  ),

                  const SizedBox(height: 16),

                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Amount',
                      prefixText: '${widget.currencySymbol} ',
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      _ThousandsSeparatorInputFormatter(),
                    ],
                  ),

                  const SizedBox(height: 12),

                  DropdownButtonFormField<Account>(
                    value: selectedAccount,
                    items: widget.accounts
                        .map(
                          (a) =>
                              DropdownMenuItem(value: a, child: Text(a.name)),
                        )
                        .toList(),
                    onChanged: (v) =>
                        setDialogState(() => selectedAccount = v!),
                    decoration: const InputDecoration(labelText: 'Account'),
                  ),

                  const SizedBox(height: 12),

                  DropdownButtonFormField<Category>(
                    value: selectedCategory,
                    items: widget.categories
                        .where((c) => c.isExpense != isIncome)
                        .map(
                          (c) =>
                              DropdownMenuItem(value: c, child: Text(c.name)),
                        )
                        .toList(),
                    onChanged: (v) =>
                        setDialogState(() => selectedCategory = v!),
                    decoration: const InputDecoration(labelText: 'Category'),
                  ),

                  const SizedBox(height: 12),

                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setDialogState(() => selectedDate = picked);
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date',
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(DateFormat('MMM d, y').format(selectedDate)),
                    ),
                  ),

                  const SizedBox(height: 12),

                  TextField(
                    controller: noteController,
                    decoration: const InputDecoration(
                      labelText: 'Note (Optional)',
                    ),
                    maxLines: 2,
                  ),

                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            final clean = amountController.text.replaceAll(
                              ',',
                              '',
                            );
                            if (clean.isEmpty) return;

                            final updatedTransaction = Transaction(
                              id: transaction.id,
                              amount: double.parse(clean),
                              isIncome: isIncome,
                              date: selectedDate,
                              accountId: selectedAccount.id,
                              categoryId: selectedCategory.id,
                              note: noteController.text.trim(),
                            );

                            widget.onUpdateTransaction(updatedTransaction);
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Transaction updated'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          child: const Text('Save'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
