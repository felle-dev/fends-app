import 'package:flutter/material.dart';
// ignore: unnecessary_import
import 'package:flutter/foundation.dart' hide Category;
import 'package:intl/intl.dart';
import 'package:fends/model.dart';
import 'package:fends/helper/graph.dart';
import 'package:fends/constants/app_strings.dart';

class OverviewTab extends StatelessWidget {
  final String currency;
  final String currencySymbol;
  final double totalBudget;
  final DateTime finalDate;
  final List<Transaction> transactions;
  final List<Account> accounts;
  final List<Category> categories;
  final VoidCallback onNavigateToAccounts;
  final VoidCallback onNavigateToTransactions;

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
    required this.onNavigateToTransactions,
  });

  Category _getCategoryById(String categoryId) {
    try {
      return categories.firstWhere((c) => c.id == categoryId);
    } catch (e) {
      return Category(
        id: 'unknown',
        name: AppStrings.unknownCategory,
        icon: Icons.help_outline,
        color: Colors.grey,
        isExpense: true,
      );
    }
  }

  double get _currentBalance {
    double balance = totalBudget;
    for (var t in transactions) {
      balance += t.isIncome ? t.amount : -t.amount;
    }
    return balance;
  }

  double get _totalSpent {
    final transferCategoryId = categories
        .firstWhere((c) => c.name == 'Transfer')
        .id;

    return transactions
        .where((t) => !t.isIncome && t.categoryId != transferCategoryId)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get _todaySpent {
    final today = DateTime.now();
    final transferCategoryId = categories
        .firstWhere((c) => c.name == 'Transfer')
        .id;

    return transactions
        .where(
          (t) =>
              !t.isIncome &&
              t.categoryId != transferCategoryId &&
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

  double get _todayIncome {
    final today = DateTime.now();
    return transactions
        .where(
          (t) =>
              t.isIncome &&
              t.date.year == today.year &&
              t.date.month == today.month &&
              t.date.day == today.day,
        )
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  // Calculate rollover from previous days (ONLY POSITIVE SAVINGS)
  double get _rolloverAmount {
    if (transactions.isEmpty) return 0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final earliestTransaction = transactions.isEmpty
        ? today
        : transactions.reduce((a, b) => a.date.isBefore(b.date) ? a : b).date;

    final startDate = DateTime(
      earliestTransaction.year,
      earliestTransaction.month,
      earliestTransaction.day,
    );

    if (startDate.isAtSameMomentAs(today) || startDate.isAfter(today)) {
      return 0;
    }

    double totalRollover = 0;
    DateTime checkDate = startDate;

    // Loop through each day from start to yesterday
    while (checkDate.isBefore(today)) {
      final dayTransactions = transactions.where((t) {
        final tDate = DateTime(t.date.year, t.date.month, t.date.day);
        return tDate.isAtSameMomentAs(checkDate);
      });

      final daySpent = dayTransactions
          .where((t) => !t.isIncome)
          .fold(0.0, (sum, t) => sum + t.amount);

      final dayIncome = dayTransactions
          .where((t) => t.isIncome)
          .fold(0.0, (sum, t) => sum + t.amount);

      final dayAllowance = _baseDailyAllowance;
      final daySavings = dayAllowance + dayIncome - daySpent;

      // Add savings (positive or negative)
      totalRollover += daySavings;

      // If rollover goes negative, reset to 0 (lose all rollover bonus)
      if (totalRollover < 0) {
        totalRollover = 0;
      }

      checkDate = checkDate.add(const Duration(days: 1));
    }

    return totalRollover;
  }

  // Today's allowance including rollover
  double get _dailyAllowanceWithRollover =>
      _baseDailyAllowance + _rolloverAmount;

  Widget _buildDailySpendingFocusCard(ThemeData theme) {
    final remainingBudget =
        _dailyAllowanceWithRollover + _todayIncome - _todaySpent;
    final isOverBudget = remainingBudget < 0;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: isOverBudget
            ? Colors.red.withOpacity(0.3)
            : Colors.green.withOpacity(0.3),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.todaysBudgetRemaining,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _formatCurrency(remainingBudget),
              style: theme.textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // double get _averageDailySpending {
  //   if (transactions.isEmpty) return 0;
  //   final earliestTransaction = transactions.reduce(
  //     (a, b) => a.date.isBefore(b.date) ? a : b,
  //   );
  //   final daysSinceFirstTransaction =
  //       DateTime.now().difference(earliestTransaction.date).inDays + 1;
  //   return daysSinceFirstTransaction > 0
  //       ? _totalSpent / daysSinceFirstTransaction
  //       : 0;
  // }

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
    AppStrings.init(context);
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppStrings.balanceTrend,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: onNavigateToTransactions,
              child: Text(AppStrings.viewAll),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildBalanceTrendCard(theme),
        const SizedBox(height: 24),
        _buildCategoryBreakdown(theme),
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
        borderRadius: BorderRadius.circular(0),
        color: theme.colorScheme.surface,
      ),
      child: Padding(
        padding: const EdgeInsets.all(0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppStrings.currentBalance,
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
                    AppStrings.format(AppStrings.daysLeft, [
                      _daysLeft.toString(),
                    ]),
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
              AppStrings.format(AppStrings.ofBudget, [
                _formatCurrency(totalBudget),
              ]),
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
              AppStrings.accounts,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: onNavigateToAccounts,
              child: Text(AppStrings.viewAll),
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
          AppStrings.spendingByCategory,
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
                final category = _getCategoryById(entry.key);
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
}
