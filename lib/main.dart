import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math' as math;

void main() {
  runApp(const FendsApp());
}

class FendsApp extends StatelessWidget {
  const FendsApp({super.key});

  ThemeData _buildThemeData(ColorScheme colorScheme, Brightness brightness) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: 'Outfit',
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontFamily: 'NoyhR'),
        displayMedium: TextStyle(fontFamily: 'NoyhR'),
        displaySmall: TextStyle(fontFamily: 'NoyhR'),
        headlineLarge: TextStyle(fontFamily: 'NoyhR'),
        headlineMedium: TextStyle(fontFamily: 'NoyhR'),
        headlineSmall: TextStyle(fontFamily: 'NoyhR'),
        titleLarge: TextStyle(fontFamily: 'NoyhR'),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: brightness == Brightness.light
              ? Brightness.dark
              : Brightness.light,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        ColorScheme lightColorScheme;
        ColorScheme darkColorScheme;

        if (lightDynamic != null && darkDynamic != null) {
          lightColorScheme = lightDynamic.harmonized();
          darkColorScheme = darkDynamic.harmonized();
        } else {
          lightColorScheme = ColorScheme.fromSeed(seedColor: Colors.teal);
          darkColorScheme = ColorScheme.fromSeed(
            seedColor: Colors.teal,
            brightness: Brightness.dark,
          );
        }

        return MaterialApp(
          title: 'Fends',
          theme: _buildThemeData(lightColorScheme, Brightness.light),
          darkTheme: _buildThemeData(darkColorScheme, Brightness.dark),
          themeMode: ThemeMode.system,
          home: const AppController(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

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

      _isLoading = false;
    });
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

    final transactionsJson = json.encode(
      _transactions.map((e) => e.toJson()).toList(),
    );
    await prefs.setString('transactions', transactionsJson);
  }

  void _completeOnboarding(
    String currency,
    String symbol,
    double budget,
    DateTime finalDate,
  ) {
    setState(() {
      _isOnboarded = true;
      _currency = currency;
      _currencySymbol = symbol;
      _totalBudget = budget;
      _finalDate = finalDate;
    });
    _saveData();
  }

  void _addTransaction(Transaction transaction) {
    setState(() {
      _transactions.add(transaction);
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
      onAddTransaction: _addTransaction,
      onReset: _resetApp,
    );
  }
}

class Transaction {
  final double amount;
  final bool isIncome;
  final DateTime date;

  Transaction({
    required this.amount,
    required this.isIncome,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
    'amount': amount,
    'isIncome': isIncome,
    'date': date.toIso8601String(),
  };

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
    amount: json['amount'],
    isIncome: json['isIncome'],
    date: DateTime.parse(json['date']),
  );
}

class OnboardingFlow extends StatefulWidget {
  final Function(String, String, double, DateTime) onComplete;

  const OnboardingFlow({super.key, required this.onComplete});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  String _selectedCurrency = 'IDR';
  String _selectedSymbol = 'Rp';
  final _budgetController = TextEditingController();
  DateTime? _selectedDate;

  final List<Map<String, String>> _currencies = [
    {'symbol': 'Rp', 'name': 'Indonesian Rupiah', 'code': 'IDR'},
    {'symbol': '\$', 'name': 'US Dollar', 'code': 'USD'},
    {'symbol': '€', 'name': 'Euro', 'code': 'EUR'},
    {'symbol': '£', 'name': 'British Pound', 'code': 'GBP'},
    {'symbol': '¥', 'name': 'Japanese Yen', 'code': 'JPY'},
    {'symbol': '₹', 'name': 'Indian Rupee', 'code': 'INR'},
  ];

  void _nextPage() {
    if (_currentPage < 3) {
      _pageController.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      if (_selectedDate != null && _budgetController.text.isNotEmpty) {
        final cleanText = _budgetController.text.replaceAll(',', '');
        widget.onComplete(
          _selectedCurrency,
          _selectedSymbol,
          double.parse(cleanText),
          _selectedDate!,
        );
      }
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.animateToPage(
        _currentPage - 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  bool get _canProceed {
    switch (_currentPage) {
      case 0:
      case 1:
        return true;
      case 2:
        final cleanText = _budgetController.text.replaceAll(',', '');
        return cleanText.isNotEmpty &&
            double.tryParse(cleanText) != null &&
            double.parse(cleanText) > 0;
      case 3:
        return _selectedDate != null;
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == index ? 32 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? theme.colorScheme.primary
                          : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) => setState(() => _currentPage = page),
                children: [
                  _buildWelcomePage(theme),
                  _buildCurrencyPage(theme),
                  _buildBudgetPage(theme),
                  _buildDatePage(theme),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  if (_currentPage > 0) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _previousPage,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text('Back'),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: FilledButton(
                      onPressed: _canProceed ? _nextPage : null,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(_currentPage == 3 ? 'Get Started' : 'Next'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomePage(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_wallet_rounded,
            size: 100,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 40),
          Text(
            'Welcome to Fends',
            style: theme.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Manage your budget wisely',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencyPage(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Currency',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose your currency',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              itemCount: _currencies.length,
              itemBuilder: (context, index) {
                final currency = _currencies[index];
                final isSelected = _selectedCurrency == currency['code'];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Material(
                    color: isSelected
                        ? theme.colorScheme.primaryContainer
                        : theme.colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedCurrency = currency['code']!;
                          _selectedSymbol = currency['symbol']!;
                        });
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  currency['symbol']!,
                                  style: TextStyle(
                                    color: isSelected
                                        ? theme.colorScheme.onPrimary
                                        : theme.colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                currency['name']!,
                                style: theme.textTheme.bodyLarge,
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                Icons.check_circle,
                                color: theme.colorScheme.primary,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetPage(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Set Budget',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter your total budget',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 40),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _selectedSymbol,
                    style: theme.textTheme.displaySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  IntrinsicWidth(
                    child: TextField(
                      controller: _budgetController,
                      keyboardType: TextInputType.number,
                      style: theme.textTheme.displayLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 56,
                      ),
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        hintText: '0',
                        border: InputBorder.none,
                        hintStyle: theme.textTheme.displayLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 56,
                          color: theme.colorScheme.onSurfaceVariant.withOpacity(
                            0.3,
                          ),
                        ),
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        _ThousandsSeparatorInputFormatter(),
                      ],
                      onChanged: (value) => setState(() {}),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 2,
                    width: 200,
                    color: theme.colorScheme.primary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePage(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Budget Period',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'When should this budget end?',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 60),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().add(
                            const Duration(days: 30),
                          ),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                        );
                        if (date != null) {
                          setState(() => _selectedDate = date);
                        }
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: theme.colorScheme.outline.withOpacity(0.3),
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.calendar_today,
                              color: theme.colorScheme.primary,
                              size: 28,
                            ),
                            const SizedBox(width: 16),
                            Text(
                              _selectedDate == null
                                  ? 'Select Date'
                                  : DateFormat(
                                      'MMM d, y',
                                    ).format(_selectedDate!),
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (_selectedDate != null) ...[
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '${_selectedDate!.difference(DateTime.now()).inDays} days from now',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final String currency;
  final String currencySymbol;
  final double totalBudget;
  final DateTime finalDate;
  final List<Transaction> transactions;
  final Function(Transaction) onAddTransaction;
  final VoidCallback onReset;

  const HomeScreen({
    super.key,
    required this.currency,
    required this.currencySymbol,
    required this.totalBudget,
    required this.finalDate,
    required this.transactions,
    required this.onAddTransaction,
    required this.onReset,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedTab = 0;

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

  int get _daysLeft =>
      widget.finalDate.difference(DateTime.now()).inDays.clamp(1, 999999);
  int get _weeksLeft => (_daysLeft / 7).ceil();
  int get _monthsLeft => (_daysLeft / 30).ceil();

  double get _dailyAllowance => _daysLeft > 0 ? _currentBalance / _daysLeft : 0;
  double get _weeklyAllowance =>
      _weeksLeft > 0 ? _currentBalance / _weeksLeft : 0;
  double get _monthlyAllowance =>
      _monthsLeft > 0 ? _currentBalance / _monthsLeft : 0;

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      symbol: widget.currencySymbol,
      decimalDigits: 0,
      locale: widget.currency == 'IDR' ? 'id_ID' : 'en_US',
    );
    return formatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Fends'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset App',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Reset App?'),
                  content: const Text(
                    'This will delete all your data. Are you sure?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onReset();
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.colorScheme.error,
                      ),
                      child: const Text('Reset'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildBalanceCard(theme),
          const SizedBox(height: 24),
          Text(
            'Spending Allowance',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildAllowanceSelector(theme),
          const SizedBox(height: 12),
          _buildAllowanceCard(theme),
          const SizedBox(height: 24),
          _buildGraphCard(theme),
          const SizedBox(height: 24),
          _buildTransactionsList(theme),
          const SizedBox(height: 100),
        ],
      ),
      floatingActionButton: _buildFABs(theme),
    );
  }

  Widget _buildBalanceCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Balance',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatCurrency(_currentBalance),
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$_daysLeft days',
                  style: TextStyle(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  theme,
                  'Spent',
                  _totalSpent,
                  theme.colorScheme.errorContainer,
                  theme.colorScheme.onErrorContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  theme,
                  'Income',
                  _totalIncome,
                  theme.colorScheme.tertiaryContainer,
                  theme.colorScheme.onTertiaryContainer,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    ThemeData theme,
    String label,
    double value,
    Color bgColor,
    Color textColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(color: textColor),
          ),
          const SizedBox(height: 4),
          Text(
            _formatCurrency(value),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllowanceSelector(ThemeData theme) {
    return SegmentedButton<int>(
      segments: const [
        ButtonSegment(value: 0, label: Text('Day')),
        ButtonSegment(value: 1, label: Text('Week')),
        ButtonSegment(value: 2, label: Text('Month')),
      ],
      selected: {_selectedTab},
      onSelectionChanged: (Set<int> selected) {
        setState(() => _selectedTab = selected.first);
      },
    );
  }

  Widget _buildAllowanceCard(ThemeData theme) {
    final allowance = _selectedTab == 0
        ? _dailyAllowance
        : _selectedTab == 1
        ? _weeklyAllowance
        : _monthlyAllowance;

    final period = _selectedTab == 0
        ? 'per day'
        : _selectedTab == 1
        ? 'per week'
        : 'per month';

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Container(
        key: ValueKey(_selectedTab),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'You can spend',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatCurrency(allowance),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  period,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSecondaryContainer.withOpacity(
                      0.7,
                    ),
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _selectedTab == 0
                    ? Icons.today
                    : _selectedTab == 1
                    ? Icons.view_week
                    : Icons.calendar_month,
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGraphCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Overview',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: BudgetGraph(
              totalBudget: widget.totalBudget,
              transactions: widget.transactions,
              finalDate: widget.finalDate,
              colorScheme: theme.colorScheme,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsList(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Transactions',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (widget.transactions.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${widget.transactions.length}',
                  style: theme.textTheme.labelLarge,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (widget.transactions.isEmpty)
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 48,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No transactions yet',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...widget.transactions.reversed.take(10).map((t) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: t.isIncome
                            ? theme.colorScheme.tertiaryContainer
                            : theme.colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        t.isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                        size: 20,
                        color: t.isIncome
                            ? theme.colorScheme.onTertiaryContainer
                            : theme.colorScheme.onErrorContainer,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatCurrency(t.amount),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            DateFormat('MMM d, y').format(t.date),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: t.isIncome
                            ? theme.colorScheme.tertiaryContainer
                            : theme.colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        t.isIncome ? 'In' : 'Out',
                        style: TextStyle(
                          color: t.isIncome
                              ? theme.colorScheme.onTertiaryContainer
                              : theme.colorScheme.onErrorContainer,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildFABs(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        FloatingActionButton.extended(
          heroTag: 'expense',
          onPressed: () => _showAddTransactionDialog(false),
          backgroundColor: theme.colorScheme.errorContainer,
          foregroundColor: theme.colorScheme.onErrorContainer,
          icon: const Icon(Icons.remove),
          label: const Text('Expense'),
        ),
        const SizedBox(width: 12),
        FloatingActionButton.extended(
          heroTag: 'income',
          onPressed: () => _showAddTransactionDialog(true),
          icon: const Icon(Icons.add),
          label: const Text('Income'),
        ),
      ],
    );
  }

  void _showAddTransactionDialog(bool isIncome) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isIncome ? 'Add Income' : 'Add Expense',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.currencySymbol,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 12),
                    IntrinsicWidth(
                      child: TextField(
                        controller: controller,
                        keyboardType: TextInputType.number,
                        autofocus: true,
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          hintText: '0',
                          border: InputBorder.none,
                          hintStyle: theme.textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurfaceVariant
                                .withOpacity(0.3),
                          ),
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          _ThousandsSeparatorInputFormatter(),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          final cleanText = controller.text.replaceAll(',', '');
                          final amount = double.tryParse(cleanText);
                          if (amount != null && amount > 0) {
                            widget.onAddTransaction(
                              Transaction(
                                amount: amount,
                                isIncome: isIncome,
                                date: DateTime.now(),
                              ),
                            );
                            Navigator.pop(context);
                          }
                        },
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text('Add'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class BudgetGraph extends StatelessWidget {
  final double totalBudget;
  final List<Transaction> transactions;
  final DateTime finalDate;
  final ColorScheme colorScheme;

  const BudgetGraph({
    super.key,
    required this.totalBudget,
    required this.transactions,
    required this.finalDate,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: GraphPainter(
        totalBudget: totalBudget,
        transactions: transactions,
        finalDate: finalDate,
        colorScheme: colorScheme,
      ),
    );
  }
}

class GraphPainter extends CustomPainter {
  final double totalBudget;
  final List<Transaction> transactions;
  final DateTime finalDate;
  final ColorScheme colorScheme;

  GraphPainter({
    required this.totalBudget,
    required this.transactions,
    required this.finalDate,
    required this.colorScheme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = colorScheme.primary
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = colorScheme.primary.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final gridPaint = Paint()
      ..color = colorScheme.outlineVariant.withOpacity(0.15)
      ..strokeWidth = 1;

    final points = _getDataPoints(size);

    // Draw grid
    for (int i = 0; i <= 3; i++) {
      final y = size.height * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if (points.isEmpty) return;

    // Fill area
    final path = Path()..moveTo(0, size.height);
    for (var point in points) {
      path.lineTo(point.dx, point.dy);
    }
    path.lineTo(size.width, size.height);
    path.close();
    canvas.drawPath(path, fillPaint);

    // Draw line
    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      linePath.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(linePath, linePaint);

    // Draw points
    for (var point in points) {
      canvas.drawCircle(
        point,
        4,
        Paint()
          ..color = colorScheme.primary
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        point,
        4,
        Paint()
          ..color = colorScheme.surface
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  List<Offset> _getDataPoints(Size size) {
    final now = DateTime.now();
    final daysTotal = finalDate.difference(now).inDays.clamp(1, 365);
    final numPoints = math.min(daysTotal, 15);

    if (numPoints <= 0) return [];

    final points = <Offset>[];
    double maxValue = totalBudget * 1.1;

    for (int i = 0; i <= numPoints; i++) {
      final daysAgo = (numPoints - i) * (daysTotal / numPoints);
      final pointDate = now.subtract(Duration(days: daysAgo.round()));

      double balance = totalBudget;
      for (var t in transactions) {
        if (t.date.isBefore(pointDate) || t.date.isAtSameMomentAs(pointDate)) {
          balance += t.isIncome ? t.amount : -t.amount;
        }
      }

      maxValue = math.max(maxValue, balance);

      final x = size.width * i / numPoints;
      final normalizedBalance = (balance / maxValue).clamp(0.0, 1.0);
      final y = size.height * (1 - normalizedBalance);
      points.add(Offset(x, y));
    }

    return points;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Custom formatter for thousands separator
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
