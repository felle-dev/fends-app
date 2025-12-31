import 'dart:ui';
import 'package:fends/tab/accounts.dart';
import 'package:fends/tab/overview.dart';
import 'package:fends/tab/settings.dart';
import 'package:fends/tab/transactions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fends/model.dart';

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
          OverviewTab(
            currency: widget.currency,
            currencySymbol: widget.currencySymbol,
            totalBudget: widget.totalBudget,
            finalDate: widget.finalDate,
            transactions: widget.transactions,
            accounts: widget.accounts,
            categories: widget.categories,
            onNavigateToAccounts: () => setState(() => _navIndex = 1),
          ),
          AccountsTab(
            currency: widget.currency,
            currencySymbol: widget.currencySymbol,
            transactions: widget.transactions,
            accounts: widget.accounts,
            onAddAccount: widget.onAddAccount,
          ),
          TransactionsTab(
            currency: widget.currency,
            currencySymbol: widget.currencySymbol,
            transactions: widget.transactions,
            accounts: widget.accounts,
            categories: widget.categories,
            onDeleteTransaction: widget.onDeleteTransaction,
            onUpdateTransaction: widget.onUpdateTransaction,
          ),
          SettingsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTransactionDialog(context),
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withOpacity(0.5),
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
                labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
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
