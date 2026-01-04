import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:fends/model.dart';

class TransactionsTab extends StatelessWidget {
  final String currency;
  final String currencySymbol;
  final List<Transaction> transactions;
  final List<Account> accounts;
  final List<Category> categories;
  final Function(String) onDeleteTransaction;
  final Function(Transaction) onUpdateTransaction;

  const TransactionsTab({
    super.key,
    required this.currency,
    required this.currencySymbol,
    required this.transactions,
    required this.accounts,
    required this.categories,
    required this.onDeleteTransaction,
    required this.onUpdateTransaction,
  });

  Category _getCategoryById(String categoryId) {
    try {
      return categories.firstWhere((c) => c.id == categoryId);
    } catch (e) {
      return Category(
        id: 'unknown',
        name: 'Unknown Category',
        icon: Icons.help_outline,
        color: Colors.grey,
        isExpense: true,
      );
    }
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      symbol: currencySymbol,
      decimalDigits: 0,
      locale: currency == 'IDR' ? 'id_ID' : 'en_US',
    );
    return formatter.format(amount);
  }

  bool _isTransferTransaction(Transaction transaction) {
    final category = _getCategoryById(transaction.categoryId);
    return category.name == 'Transfer';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sortedTransactions = transactions.toList()
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
            final category = _getCategoryById(transaction.categoryId);
            final account = accounts.firstWhere(
              (a) => a.id == transaction.accountId,
            );
            final isTransfer = _isTransferTransaction(transaction);

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
                            border: Border.all(
                              color: isTransfer
                                  ? theme.colorScheme.primary
                                  : category.color,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isTransfer ? Icons.swap_horiz : category.icon,
                            color: isTransfer
                                ? theme.colorScheme.primary
                                : category.color,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isTransfer ? 'Transfer' : category.name,
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
                        Text(
                          '${transaction.isIncome ? '+' : '-'}${_formatCurrency(transaction.amount)}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isTransfer
                                ? theme.colorScheme.primary
                                : (transaction.isIncome
                                      ? Colors.green
                                      : Colors.red),
                          ),
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

  void _showTransactionOptionsDialog(
    BuildContext context,
    Transaction transaction,
  ) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 32,
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
      ),
    );
  }

  void _showDeleteConfirmationDialog(
    BuildContext context,
    Transaction transaction,
  ) {
    final theme = Theme.of(context);
    final category = _getCategoryById(transaction.categoryId);

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
              onDeleteTransaction(transaction.id);
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

    bool isTransfer = _isTransferTransaction(transaction);
    String transactionType = isTransfer
        ? 'transfer'
        : (transaction.isIncome ? 'income' : 'expense');
    Account selectedAccount = accounts.firstWhere(
      (a) => a.id == transaction.accountId,
    );
    Account? selectedToAccount;
    Category selectedCategory = _getCategoryById(transaction.categoryId);
    DateTime selectedDate = transaction.date;

    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 32,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurfaceVariant.withOpacity(
                          0.4,
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(
                    'Edit Transaction',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Type selector
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'expense',
                        label: Text('Expense'),
                        icon: Icon(Icons.remove_circle_outline),
                      ),
                      ButtonSegment(
                        value: 'income',
                        label: Text('Income'),
                        icon: Icon(Icons.add_circle_outline),
                      ),
                      ButtonSegment(
                        value: 'transfer',
                        label: Text('Transfer'),
                        icon: Icon(Icons.swap_horiz),
                      ),
                    ],
                    selected: {transactionType},
                    onSelectionChanged: (v) {
                      setDialogState(() {
                        transactionType = v.first;
                        if (transactionType != 'transfer') {
                          selectedCategory = categories.firstWhere(
                            (c) => c.isExpense != (transactionType == 'income'),
                          );
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 32),

                  // Amount input - Primary focus
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withOpacity(
                        0.3,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: theme.colorScheme.primary.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Amount',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: amountController,
                          autofocus: false,
                          keyboardType: TextInputType.number,
                          style: theme.textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: '0',
                            hintStyle: theme.textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurfaceVariant
                                  .withOpacity(0.3),
                            ),
                            prefixText: '$currencySymbol ',
                            prefixStyle: theme.textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                            contentPadding: EdgeInsets.zero,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            _ThousandsSeparatorInputFormatter(),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Account selector with chips
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transactionType == 'transfer'
                            ? 'From Account'
                            : 'Account',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: accounts.map((account) {
                          final isSelected = selectedAccount.id == account.id;
                          return FilterChip(
                            selected: isSelected,
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  account.icon,
                                  size: 16,
                                  color: isSelected
                                      ? theme.colorScheme.onSecondaryContainer
                                      : account.color,
                                ),
                                const SizedBox(width: 6),
                                Text(account.name),
                              ],
                            ),
                            onSelected: (selected) {
                              if (selected) {
                                setDialogState(() => selectedAccount = account);
                              }
                            },
                            backgroundColor: theme.colorScheme.surface,
                            selectedColor: theme.colorScheme.secondaryContainer,
                            checkmarkColor:
                                theme.colorScheme.onSecondaryContainer,
                            side: BorderSide(
                              color: isSelected
                                  ? theme.colorScheme.secondary
                                  : account.color.withOpacity(0.5),
                              width: isSelected ? 2 : 1,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),

                  // To Account selector (only for transfer)
                  if (transactionType == 'transfer') ...[
                    const SizedBox(height: 24),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'To Account',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: accounts
                              .where((a) => a.id != selectedAccount.id)
                              .map((account) {
                                final isSelected =
                                    selectedToAccount?.id == account.id;
                                return FilterChip(
                                  selected: isSelected,
                                  label: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        account.icon,
                                        size: 16,
                                        color: isSelected
                                            ? theme
                                                  .colorScheme
                                                  .onSecondaryContainer
                                            : account.color,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(account.name),
                                    ],
                                  ),
                                  onSelected: (selected) {
                                    setDialogState(() {
                                      selectedToAccount = selected
                                          ? account
                                          : null;
                                    });
                                  },
                                  backgroundColor: theme.colorScheme.surface,
                                  selectedColor:
                                      theme.colorScheme.secondaryContainer,
                                  checkmarkColor:
                                      theme.colorScheme.onSecondaryContainer,
                                  side: BorderSide(
                                    color: isSelected
                                        ? theme.colorScheme.secondary
                                        : account.color.withOpacity(0.5),
                                    width: isSelected ? 2 : 1,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                );
                              })
                              .toList(),
                        ),
                      ],
                    ),
                  ],

                  // Category selector with chips (not shown for transfer)
                  if (transactionType != 'transfer') ...[
                    const SizedBox(height: 24),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Category',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: categories
                              .where(
                                (c) =>
                                    c.isExpense !=
                                    (transactionType == 'income'),
                              )
                              .map((category) {
                                final isSelected =
                                    selectedCategory.id == category.id;
                                return FilterChip(
                                  selected: isSelected,
                                  label: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        category.icon,
                                        size: 16,
                                        color: isSelected
                                            ? theme
                                                  .colorScheme
                                                  .onSecondaryContainer
                                            : category.color,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(category.name),
                                    ],
                                  ),
                                  onSelected: (selected) {
                                    if (selected) {
                                      setDialogState(
                                        () => selectedCategory = category,
                                      );
                                    }
                                  },
                                  backgroundColor: theme.colorScheme.surface,
                                  selectedColor:
                                      theme.colorScheme.secondaryContainer,
                                  checkmarkColor:
                                      theme.colorScheme.onSecondaryContainer,
                                  side: BorderSide(
                                    color: isSelected
                                        ? theme.colorScheme.secondary
                                        : category.color.withOpacity(0.5),
                                    width: isSelected ? 2 : 1,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                );
                              })
                              .toList(),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Date picker
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
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            color: theme.colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Date',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  DateFormat(
                                    'EEEE, MMM d, y',
                                  ).format(selectedDate),
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Note input
                  TextField(
                    controller: noteController,
                    decoration: InputDecoration(
                      labelText: 'Note (optional)',
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: Icon(
                        Icons.note_outlined,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    maxLines: 2,
                  ),

                  const SizedBox(height: 32),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: FilledButton(
                          onPressed: () {
                            final clean = amountController.text.replaceAll(
                              ',',
                              '',
                            );
                            if (clean.isEmpty) return;

                            onUpdateTransaction(
                              Transaction(
                                id: transaction.id,
                                amount: double.parse(clean),
                                isIncome: transactionType == 'income',
                                date: selectedDate,
                                accountId: selectedAccount.id,
                                categoryId: selectedCategory.id,
                                note: noteController.text,
                              ),
                            );

                            Navigator.pop(context);

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Transaction updated'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Save Changes'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

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
