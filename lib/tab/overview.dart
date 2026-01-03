import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' hide Category;
import 'package:intl/intl.dart';
import 'package:fends/model.dart';
import 'package:fends/helper/graph.dart';

class OverviewTab extends StatelessWidget {
  final String currency;
  final String currencySymbol;
  final double totalBudget;
  final DateTime finalDate;
  final List<Transaction> transactions;
  final List<Account> accounts;
  final List<Category> categories;
  final VoidCallback onNavigateToAccounts;

  const OverviewTab({
    super.key,
    required this.currency,
    required this.currencySymbol,
    required this.totalBudget,
    required this.finalDate,
    required this.transactions,
    required this.accounts,
    required this.categories,
    required this.onNavigateToAccounts,
  });

  double get _currentBalance {
    double balance = totalBudget;
    for (var t in transactions) {
      balance += t.isIncome ? t.amount : -t.amount;
    }
    return balance;
  }

  double get _totalSpent {
    return transactions
        .where((t) => !t.isIncome)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get _totalIncome {
    return transactions
        .where((t) => t.isIncome)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get _todaySpent {
    final today = DateTime.now();
    return transactions
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
      finalDate.difference(DateTime.now()).inDays.clamp(1, 999999);

  double get _baseDailyAllowance =>
      _daysLeft > 0 ? _currentBalance / _daysLeft : 0;

  // Calculate rollover from previous days
  double get _rolloverAmount {
    if (transactions.isEmpty) return 0;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Get the earliest transaction or budget start date (whichever is more recent)
    final earliestTransaction = transactions.isEmpty
        ? today
        : transactions.reduce((a, b) => a.date.isBefore(b.date) ? a : b).date;

    final startDate = DateTime(
      earliestTransaction.year,
      earliestTransaction.month,
      earliestTransaction.day,
    );

    // Don't calculate rollover if we just started
    if (startDate.isAtSameMomentAs(today) || startDate.isAfter(today)) {
      return 0;
    }

    double totalRollover = 0;
    DateTime checkDate = startDate;

    // Loop through each day from start to yesterday
    while (checkDate.isBefore(today)) {
      final dayTransactions = transactions.where((t) {
        final tDate = DateTime(t.date.year, t.date.month, t.date.day);
        return !t.isIncome && tDate.isAtSameMomentAs(checkDate);
      });

      final daySpent = dayTransactions.fold(0.0, (sum, t) => sum + t.amount);
      final dayAllowance = _baseDailyAllowance;
      final daySavings = dayAllowance - daySpent;

      // Only add positive savings (didn't overspend)
      if (daySavings > 0) {
        totalRollover += daySavings;
      }

      checkDate = checkDate.add(const Duration(days: 1));
    }

    return totalRollover;
  }

  // Today's allowance including rollover
  double get _dailyAllowanceWithRollover =>
      _baseDailyAllowance + _rolloverAmount;

  double get _averageDailySpending {
    if (transactions.isEmpty) return 0;
    final earliestTransaction = transactions.reduce(
      (a, b) => a.date.isBefore(b.date) ? a : b,
    );
    final daysSinceFirstTransaction =
        DateTime.now().difference(earliestTransaction.date).inDays + 1;
    return daysSinceFirstTransaction > 0
        ? _totalSpent / daysSinceFirstTransaction
        : 0;
  }

  DateTime? get _estimatedRunoutDate {
    if (_averageDailySpending <= 0) return null;
    final daysRemaining = _currentBalance / _averageDailySpending;
    return DateTime.now().add(Duration(days: daysRemaining.floor()));
  }

  double _getAccountBalance(String accountId) {
    final account = accounts.firstWhere((a) => a.id == accountId);
    double balance = account.initialBalance;
    for (var t in transactions.where((t) => t.accountId == accountId)) {
      balance += t.isIncome ? t.amount : -t.amount;
    }
    return balance;
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      symbol: currencySymbol,
      decimalDigits: 0,
      locale: currency == 'IDR' ? 'id_ID' : 'en_US',
    );
    return formatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildBalanceGraphCard(theme),
        const SizedBox(height: 16),
        _buildDailySpendingFocusCard(theme),
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
        const SizedBox(height: 12),
        _buildBudgetRunwayCard(theme),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildBalanceGraphCard(ThemeData theme) {
    final progress = totalBudget > 0
        ? (_currentBalance / totalBudget).clamp(0.0, 1.0)
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
              'of ${_formatCurrency(totalBudget)} budget',
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

  Widget _buildDailySpendingFocusCard(ThemeData theme) {
    final isOverBudget = _todaySpent > _dailyAllowanceWithRollover;
    final difference = _todaySpent - _dailyAllowanceWithRollover;
    final hasRollover = _rolloverAmount > 0;

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
                    'of ${_formatCurrency(_dailyAllowanceWithRollover)}',
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
                value: _dailyAllowanceWithRollover > 0
                    ? (_todaySpent / _dailyAllowanceWithRollover).clamp(
                        0.0,
                        1.0,
                      )
                    : 0.0,
                minHeight: 8,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                color: isOverBudget ? Colors.red : theme.colorScheme.primary,
              ),
            ),

            // Show rollover bonus if exists
            if (hasRollover && !isOverBudget) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.green.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.savings_outlined, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Rollover Bonus',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'You saved ${_formatCurrency(_rolloverAmount)} from previous days!',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

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
            ] else if (_todaySpent > _dailyAllowanceWithRollover * 0.8) ...[
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
                        'You have ${_formatCurrency(_dailyAllowanceWithRollover - _todaySpent)} left for today',
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

            // Show breakdown of base vs rollover
            if (hasRollover) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Base Daily',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          _formatCurrency(_baseDailyAllowance),
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.add,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rollover',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.green,
                          ),
                        ),
                        Text(
                          _formatCurrency(_rolloverAmount),
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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
              onPressed: onNavigateToAccounts,
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...accounts.take(3).map((account) {
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
            totalBudget: totalBudget,
            transactions: transactions,
            finalDate: finalDate,
            colorScheme: theme.colorScheme,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryBreakdown(ThemeData theme) {
    final expensesByCategory = <String, double>{};

    for (var t in transactions.where((t) => !t.isIncome)) {
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
                final category = categories.firstWhere(
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

  Widget _buildBudgetRunwayCard(ThemeData theme) {
    final runoutDate = _estimatedRunoutDate;
    final daysUntilRunout = runoutDate != null
        ? runoutDate.difference(DateTime.now()).inDays
        : null;

    final willRunOutBeforeFinalDate =
        runoutDate != null && runoutDate.isBefore(finalDate);

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
                          'Budget may run out ${finalDate.difference(runoutDate).inDays} days before your target date',
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
}