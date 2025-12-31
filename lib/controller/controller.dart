import 'package:fends/onboarding.dart';
import 'package:fends/widgets/home_widget_helper.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:fends/model.dart';
import 'package:fends/home.dart';

class AppController extends StatefulWidget {
  const AppController({super.key});

  @override
  State<AppController> createState() => _AppControllerState();
}

class _AppControllerState extends State<AppController> {
  bool _isOnboarded = false;
  String _currency = 'IDR';
  String _currencySymbol = 'Rp';
  double _totalBudget = 0;
  DateTime? _finalDate;
  List<Transaction> _transactions = [];
  List<Account> _accounts = [];
  List<Category> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _isOnboarded = prefs.getBool('isOnboarded') ?? false;
      _currency = prefs.getString('currency') ?? 'IDR';
      _currencySymbol = prefs.getString('currencySymbol') ?? 'Rp';
      _totalBudget = prefs.getDouble('totalBudget') ?? 0;

      final dateString = prefs.getString('finalDate');
      if (dateString != null) {
        _finalDate = DateTime.parse(dateString);
      }

      final transactionsJson = prefs.getString('transactions');
      if (transactionsJson != null) {
        final List<dynamic> decoded = json.decode(transactionsJson);
        _transactions = decoded.map((e) => Transaction.fromJson(e)).toList();
      }

      final accountsJson = prefs.getString('accounts');
      if (accountsJson != null) {
        final List<dynamic> decoded = json.decode(accountsJson);
        _accounts = decoded.map((e) => Account.fromJson(e)).toList();
      }

      final categoriesJson = prefs.getString('categories');
      if (categoriesJson != null) {
        final List<dynamic> decoded = json.decode(categoriesJson);
        _categories = decoded.map((e) => Category.fromJson(e)).toList();
      } else {
        _categories = _getDefaultCategories();
      }

      _isLoading = false;
    });
  }

  List<Category> _getDefaultCategories() {
    return [
      Category(
        id: '1',
        name: 'Food',
        icon: Icons.restaurant,
        color: Colors.orange,
        isExpense: true,
      ),
      Category(
        id: '2',
        name: 'Transport',
        icon: Icons.directions_car,
        color: Colors.blue,
        isExpense: true,
      ),
      Category(
        id: '3',
        name: 'Shopping',
        icon: Icons.shopping_bag,
        color: Colors.purple,
        isExpense: true,
      ),
      Category(
        id: '4',
        name: 'Entertainment',
        icon: Icons.movie,
        color: Colors.pink,
        isExpense: true,
      ),
      Category(
        id: '5',
        name: 'Bills',
        icon: Icons.receipt_long,
        color: Colors.red,
        isExpense: true,
      ),
      Category(
        id: '6',
        name: 'Health',
        icon: Icons.medical_services,
        color: Colors.green,
        isExpense: true,
      ),
      Category(
        id: '7',
        name: 'Salary',
        icon: Icons.payments,
        color: Colors.teal,
        isExpense: false,
      ),
      Category(
        id: '8',
        name: 'Business',
        icon: Icons.business,
        color: Colors.indigo,
        isExpense: false,
      ),
      Category(
        id: '9',
        name: 'Gifts',
        icon: Icons.card_giftcard,
        color: Colors.amber,
        isExpense: false,
      ),
      Category(
        id: '10',
        name: 'Other',
        icon: Icons.more_horiz,
        color: Colors.grey,
        isExpense: false,
      ),
    ];
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('isOnboarded', _isOnboarded);
    await prefs.setString('currency', _currency);
    await prefs.setString('currencySymbol', _currencySymbol);
    await prefs.setDouble('totalBudget', _totalBudget);

    if (_finalDate != null) {
      await prefs.setString('finalDate', _finalDate!.toIso8601String());
    }

    if (_isOnboarded && _accounts.isNotEmpty) {
      final currentBalance =
          _totalBudget +
          _transactions.fold<double>(
            0.0,
            (sum, t) => sum + (t.isIncome ? t.amount : -t.amount),
          );

      await HomeWidgetHelper.updateBalance(
        balance: currentBalance,
        currencySymbol: _currencySymbol,
      );
    }

    await prefs.setString(
      'transactions',
      json.encode(_transactions.map((e) => e.toJson()).toList()),
    );
    await prefs.setString(
      'accounts',
      json.encode(_accounts.map((e) => e.toJson()).toList()),
    );
    await prefs.setString(
      'categories',
      json.encode(_categories.map((e) => e.toJson()).toList()),
    );
  }

  void _completeOnboarding(
    String currency,
    String symbol,
    double budget,
    DateTime finalDate,
    List<Account> accounts,
  ) {
    setState(() {
      _isOnboarded = true;
      _currency = currency;
      _currencySymbol = symbol;
      _totalBudget = budget;
      _finalDate = finalDate;
      _accounts = accounts;
    });
    _saveData();
  }

  void _addTransaction(Transaction transaction) {
    setState(() {
      _transactions.add(transaction);
    });
    _saveData();
  }

  void _addAccount(Account account) {
    setState(() {
      _accounts.add(account);
    });
    _saveData();
  }

  void _resetApp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    setState(() {
      _isOnboarded = false;
      _currency = 'IDR';
      _currencySymbol = 'Rp';
      _totalBudget = 0;
      _finalDate = null;
      _transactions = [];
      _accounts = [];
      _categories = _getDefaultCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!_isOnboarded) {
      return OnboardingFlow(onComplete: _completeOnboarding);
    }

    return HomeScreen(
      currency: _currency,
      currencySymbol: _currencySymbol,
      totalBudget: _totalBudget,
      finalDate: _finalDate!,
      transactions: _transactions,
      accounts: _accounts,
      categories: _categories,
      onAddTransaction: _addTransaction,
      onAddAccount: _addAccount,
      onDeleteTransaction: _deleteTransaction,
      onUpdateTransaction: _updateTransaction,
      onReset: _resetApp,
    );
  }

  void _deleteTransaction(String transactionId) {
    setState(() {
      _transactions.removeWhere((t) => t.id == transactionId);
    });
    _saveData();
  }

  void _updateTransaction(Transaction updatedTransaction) {
    setState(() {
      final index = _transactions.indexWhere(
        (t) => t.id == updatedTransaction.id,
      );
      if (index != -1) {
        _transactions[index] = updatedTransaction;
      }
    });
    _saveData();
  }
}
