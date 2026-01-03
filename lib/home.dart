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
  final Function(String) onDeleteAccount;
  final Function(Transaction) onUpdateTransaction;
  final VoidCallback onReset;
  final Future<String> Function() onExportData;
  final Future<void> Function(String) onImportData;
  final bool? biometricEnabled;
  final Function(bool)? onBiometricChanged;

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
    required this.onDeleteAccount,
    required this.onUpdateTransaction,
    required this.onReset,
    required this.onExportData,
    required this.onImportData,
    this.biometricEnabled,
    this.onBiometricChanged,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _navIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _navIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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

  void _onPageChanged(int index) {
    setState(() => _navIndex = index);
  }

  void _onNavTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(title: Text(_currentTitle), centerTitle: false),
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: [
          OverviewTab(
            currency: widget.currency,
            currencySymbol: widget.currencySymbol,
            totalBudget: widget.totalBudget,
            finalDate: widget.finalDate,
            transactions: widget.transactions,
            accounts: widget.accounts,
            categories: widget.categories,
            onNavigateToAccounts: () => _onNavTapped(1),
          ),
          AccountsTab(
            currency: widget.currency,
            currencySymbol: widget.currencySymbol,
            transactions: widget.transactions,
            accounts: widget.accounts,
            onAddAccount: widget.onAddAccount,
            onDeleteAccount: widget.onDeleteAccount,
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
          SettingsTab(
            onExportData: widget.onExportData,
            onImportData: (jsonData) async =>
                await widget.onImportData(jsonData),
            onReset: widget.onReset,
            biometricEnabled: widget.biometricEnabled,
            onBiometricChanged: widget.onBiometricChanged,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTransactionDialog(context),
        child: const Icon(Icons.add),
      ),
      extendBody: true,
      bottomNavigationBar: Container(
        margin: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withOpacity(0.7),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: theme.colorScheme.outline.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: NavigationBar(
                selectedIndex: _navIndex,
                onDestinationSelected: _onNavTapped,
                elevation: 0,
                height: 70,
                backgroundColor: Colors.transparent,
                indicatorColor: theme.colorScheme.primaryContainer.withOpacity(
                  0.8,
                ),
                labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
                destinations: const [
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

    String transactionType = 'expense'; // 'expense', 'income', 'transfer'
    Account selectedAccount = widget.accounts.first;
    Account? selectedToAccount = widget.accounts.length > 1
        ? widget.accounts[1]
        : null;
    Category selectedCategory = widget.categories.firstWhere(
      (c) => c.isExpense,
    );

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
                    'Add Transaction',
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
                          selectedCategory = widget.categories.firstWhere(
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
                          autofocus: true,
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
                            prefixText: '${widget.currencySymbol} ',
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

                  // Account selector (From account for transfer)
                  DropdownButtonFormField<Account>(
                    value: selectedAccount,
                    items: widget.accounts
                        .map(
                          (a) => DropdownMenuItem(
                            value: a,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.account_balance_wallet,
                                  size: 20,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 12),
                                Text(a.name),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) =>
                        setDialogState(() => selectedAccount = v!),
                    decoration: InputDecoration(
                      labelText: transactionType == 'transfer'
                          ? 'From Account'
                          : 'Account',
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  // To Account selector (only for transfer)
                  if (transactionType == 'transfer') ...[
                    const SizedBox(height: 16),
                    DropdownButtonFormField<Account>(
                      value: selectedToAccount,
                      items: widget.accounts
                          .where((a) => a.id != selectedAccount.id)
                          .map(
                            (a) => DropdownMenuItem(
                              value: a,
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.account_balance_wallet,
                                    size: 20,
                                    color: theme.colorScheme.primary,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(a.name),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) =>
                          setDialogState(() => selectedToAccount = v),
                      decoration: InputDecoration(
                        labelText: 'To Account',
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],

                  // Category selector (not shown for transfer)
                  if (transactionType != 'transfer') ...[
                    const SizedBox(height: 16),
                    DropdownButtonFormField<Category>(
                      value: selectedCategory,
                      items: widget.categories
                          .where(
                            (c) => c.isExpense != (transactionType == 'income'),
                          )
                          .map(
                            (c) => DropdownMenuItem(
                              value: c,
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.category,
                                    size: 20,
                                    color: theme.colorScheme.primary,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(c.name),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) =>
                          setDialogState(() => selectedCategory = v!),
                      decoration: InputDecoration(
                        labelText: 'Category',
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
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

                            if (transactionType == 'transfer') {
                              if (selectedToAccount == null) return;

                              // Create two transactions for transfer
                              final now = DateTime.now();
                              final transferId = now.millisecondsSinceEpoch
                                  .toString();

                              // Outgoing transaction
                              widget.onAddTransaction(
                                Transaction(
                                  id: '${transferId}_out',
                                  amount: double.parse(clean),
                                  isIncome: false,
                                  date: now,
                                  accountId: selectedAccount.id,
                                  categoryId: widget.categories
                                      .firstWhere((c) => c.name == 'Transfer')
                                      .id,
                                  note:
                                      'Transfer to ${selectedToAccount!.name}',
                                ),
                              );

                              // Incoming transaction
                              widget.onAddTransaction(
                                Transaction(
                                  id: '${transferId}_in',
                                  amount: double.parse(clean),
                                  isIncome: true,
                                  date: now,
                                  accountId: selectedToAccount!.id,
                                  categoryId: widget.categories
                                      .firstWhere((c) => c.name == 'Transfer')
                                      .id,
                                  note: 'Transfer from ${selectedAccount.name}',
                                ),
                              );
                            } else {
                              widget.onAddTransaction(
                                Transaction(
                                  id: DateTime.now().millisecondsSinceEpoch
                                      .toString(),
                                  amount: double.parse(clean),
                                  isIncome: transactionType == 'income',
                                  date: DateTime.now(),
                                  accountId: selectedAccount.id,
                                  categoryId: selectedCategory.id,
                                  note: '',
                                ),
                              );
                            }

                            Navigator.pop(context);
                          },
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Add Transaction'),
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
