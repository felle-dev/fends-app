import 'package:flutter/material.dart';
import 'package:fends/l10n/app_localizations.dart';

class AppStrings {
  static AppLocalizations? _localizations;

  static void init(BuildContext context) {
    _localizations = AppLocalizations.of(context);
  }

  static String get security =>
      _localizations?.translate('security') ?? 'Security';
  static String get biometricLock =>
      _localizations?.translate('biometricLock') ?? 'Lock';
  static String get appIsLockedWith =>
      _localizations?.translate('appIsLockedWith') ?? 'App is locked with';
  static String get requireToOpenApp =>
      _localizations?.translate('requireToOpenApp') ?? 'Require {} to open app';
  static String get authenticateToEnable =>
      _localizations?.translate('authenticateToEnable') ??
      'Authenticate to enable biometric lock';
  static String get authenticationEnabled =>
      _localizations?.translate('authenticationEnabled') ??
      '{} authentication enabled';
  static String get authenticationDisabled =>
      _localizations?.translate('authenticationDisabled') ??
      '{} authentication disabled';
  static String get authenticationFailed =>
      _localizations?.translate('authenticationFailed') ??
      'Authentication failed: {}';

  static String get appearance =>
      _localizations?.translate('appearance') ?? 'Appearance';
  static String get theme => _localizations?.translate('theme') ?? 'Theme';
  static String get materialYou =>
      _localizations?.translate('materialYou') ?? 'Material You';
  static String get usingSystemColors =>
      _localizations?.translate('usingSystemColors') ?? 'Using system colors';
  static String get usingDefaultColors =>
      _localizations?.translate('usingDefaultColors') ?? 'Using default colors';
  static String get dynamicColorsEnabled =>
      _localizations?.translate('dynamicColorsEnabled') ??
      'Dynamic colors enabled';
  static String get dynamicColorsDisabled =>
      _localizations?.translate('dynamicColorsDisabled') ??
      'Dynamic colors disabled';
  static String get chooseTheme =>
      _localizations?.translate('chooseTheme') ?? 'Choose Theme';
  static String get light => _localizations?.translate('light') ?? 'Light';
  static String get dark => _localizations?.translate('dark') ?? 'Dark';
  static String get system => _localizations?.translate('system') ?? 'System';
  static String get alwaysUseLightTheme =>
      _localizations?.translate('alwaysUseLightTheme') ??
      'Always use light theme';
  static String get alwaysUseDarkTheme =>
      _localizations?.translate('alwaysUseDarkTheme') ??
      'Always use dark theme';
  static String get followSystemSettings =>
      _localizations?.translate('followSystemSettings') ??
      'Follow system settings';
  static String get themeChangedTo =>
      _localizations?.translate('themeChangedTo') ?? 'Theme changed to {}';

  static String get language =>
      _localizations?.translate('language') ?? 'Language';
  static String get changeLanguage =>
      _localizations?.translate('changeLanguage') ?? 'Change Language';
  static String get currentLanguage =>
      _localizations?.translate('currentLanguage') ?? 'Current language';
  static String get english =>
      _localizations?.translate('english') ?? 'English';
  static String get indonesian =>
      _localizations?.translate('indonesian') ?? 'Indonesian';
  static String get languageChangedTo =>
      _localizations?.translate('languageChangedTo') ??
      'Language changed to {}';

  // Add all other strings similarly...
  static String get categories =>
      _localizations?.translate('categories') ?? 'Categories';
  static String get manageCategories =>
      _localizations?.translate('manageCategories') ?? 'Manage Categories';
  static String get categoriesCount =>
      _localizations?.translate('categoriesCount') ?? '{} categories';
  static String get addCategory =>
      _localizations?.translate('addCategory') ?? 'Add Category';
  static String get editCategory =>
      _localizations?.translate('editCategory') ?? 'Edit Category';
  static String get categoryName =>
      _localizations?.translate('categoryName') ?? 'Category Name';
  static String get type => _localizations?.translate('type') ?? 'Type';
  static String get expense =>
      _localizations?.translate('expense') ?? 'Expense';
  static String get income => _localizations?.translate('income') ?? 'Income';
  static String get icon => _localizations?.translate('icon') ?? 'Icon';
  static String get color => _localizations?.translate('color') ?? 'Color';
  static String get preview =>
      _localizations?.translate('preview') ?? 'Preview';
  static String get defaultCategory =>
      _localizations?.translate('defaultCategory') ?? 'Default category';
  static String get customCategory =>
      _localizations?.translate('customCategory') ?? 'Custom category';
  static String get deleteCategory =>
      _localizations?.translate('deleteCategory') ?? 'Delete Category?';
  static String get deleteCategoryConfirm =>
      _localizations?.translate('deleteCategoryConfirm') ??
      'Are you sure you want to delete "{}"?';
  static String get categoryDeleted =>
      _localizations?.translate('categoryDeleted') ?? 'Category deleted';
  static String get categoryAddedSuccess =>
      _localizations?.translate('categoryAddedSuccess') ??
      'Category added successfully';
  static String get categoryUpdatedSuccess =>
      _localizations?.translate('categoryUpdatedSuccess') ??
      'Category updated successfully';
  static String get pleaseEnterCategoryName =>
      _localizations?.translate('pleaseEnterCategoryName') ??
      'Please enter a category name';
  static String get expenseCategories =>
      _localizations?.translate('expenseCategories') ?? 'EXPENSE CATEGORIES';
  static String get incomeCategories =>
      _localizations?.translate('incomeCategories') ?? 'INCOME CATEGORIES';
  static String get add => _localizations?.translate('add') ?? 'Add';
  static String get update => _localizations?.translate('update') ?? 'Update';
  static String get edit => _localizations?.translate('edit') ?? 'Edit';
  static String get delete => _localizations?.translate('delete') ?? 'Delete';

  static String get dataManagement =>
      _localizations?.translate('dataManagement') ?? 'Data Management';
  static String get exportData =>
      _localizations?.translate('exportData') ?? 'Export Data';
  static String get importData =>
      _localizations?.translate('importData') ?? 'Import Data';
  static String get saveDataBackup =>
      _localizations?.translate('saveDataBackup') ??
      'Save your data as a backup file';
  static String get restoreFromBackup =>
      _localizations?.translate('restoreFromBackup') ??
      'Restore from a backup file';
  static String get dataExportedSuccess =>
      _localizations?.translate('dataExportedSuccess') ??
      'Data exported successfully';
  static String get dataImportedSuccess =>
      _localizations?.translate('dataImportedSuccess') ??
      'Data imported successfully';
  static String get exportFailed =>
      _localizations?.translate('exportFailed') ?? 'Failed to export data: {}';
  static String get importFailed =>
      _localizations?.translate('importFailed') ?? 'Failed to import data: {}';
  static String get invalidBackupFile =>
      _localizations?.translate('invalidBackupFile') ??
      'Invalid backup file format';
  static String get importDataQuestion =>
      _localizations?.translate('importDataQuestion') ?? 'Import Data?';
  static String get importWarning =>
      _localizations?.translate('importWarning') ??
      'This will replace all your current data';
  static String get exportFunctionNotAvailable =>
      _localizations?.translate('exportFunctionNotAvailable') ??
      'Export function not available';
  static String get import => _localizations?.translate('import') ?? 'Import';

  static String get appInformation =>
      _localizations?.translate('appInformation') ?? 'App Information';
  static String get about => _localizations?.translate('about') ?? 'About';
  static String get appVersionInfo =>
      _localizations?.translate('appVersionInfo') ??
      'App version and information';
  static String get appName => _localizations?.translate('appName') ?? 'Fends';
  static String get appVersion =>
      _localizations?.translate('appVersion') ?? '1.0.0';
  static String get appDescription =>
      _localizations?.translate('appDescription') ??
      'A simple and beautiful budget tracking app';
  static String get privacyPolicy =>
      _localizations?.translate('privacyPolicy') ?? 'Privacy Policy';
  static String get howWeHandleData =>
      _localizations?.translate('howWeHandleData') ?? 'How we handle your data';
  static String get privacyMessage =>
      _localizations?.translate('privacyMessage') ??
      'All your financial data is stored locally';
  static String get close => _localizations?.translate('close') ?? 'Close';

  static String get dangerZone =>
      _localizations?.translate('dangerZone') ?? 'Danger Zone';
  static String get resetAllData =>
      _localizations?.translate('resetAllData') ?? 'Reset All Data';
  static String get deleteAllTransactions =>
      _localizations?.translate('deleteAllTransactions') ??
      'Delete all transactions and accounts';
  static String get resetDataQuestion =>
      _localizations?.translate('resetDataQuestion') ?? 'Reset All Data?';
  static String get resetWarning =>
      _localizations?.translate('resetWarning') ??
      'Are you sure you want to delete all data?';
  static String get reset => _localizations?.translate('reset') ?? 'Reset';
  static String get cancel => _localizations?.translate('cancel') ?? 'Cancel';

  static String get transactions =>
      _localizations?.translate('transactions') ?? 'Transactions';
  static String get totalTransactions =>
      _localizations?.translate('totalTransactions') ?? '{} total';
  static String get noTransactionsInPeriod =>
      _localizations?.translate('noTransactionsInPeriod') ??
      'No transactions in this period';
  static String get unknownCategory =>
      _localizations?.translate('unknownCategory') ?? 'Unknown Category';
  static String get week => _localizations?.translate('week') ?? 'Week';
  static String get month => _localizations?.translate('month') ?? 'Month';
  static String get allTime =>
      _localizations?.translate('allTime') ?? 'All Time';
  static String get spent => _localizations?.translate('spent') ?? 'Spent';
  static String get expenses =>
      _localizations?.translate('expenses') ?? 'Expenses';
  static String get weeklyTrend =>
      _localizations?.translate('weeklyTrend') ?? 'Weekly Trend';
  static String get topCategories =>
      _localizations?.translate('topCategories') ?? 'Top Categories';
  static String get editTransaction =>
      _localizations?.translate('editTransaction') ?? 'Edit Transaction';
  static String get deleteTransaction =>
      _localizations?.translate('deleteTransaction') ?? 'Delete Transaction';
  static String get deleteTransactionConfirm =>
      _localizations?.translate('deleteTransactionConfirm') ??
      'Are you sure you want to delete this transaction?';
  static String get transactionDeleted =>
      _localizations?.translate('transactionDeleted') ?? 'Transaction deleted';
  static String get transactionUpdated =>
      _localizations?.translate('transactionUpdated') ?? 'Transaction updated';
  static String get amount => _localizations?.translate('amount') ?? 'Amount';
  static String get account =>
      _localizations?.translate('account') ?? 'Account';
  static String get fromAccount =>
      _localizations?.translate('fromAccount') ?? 'From Account';
  static String get toAccount =>
      _localizations?.translate('toAccount') ?? 'To Account';
  static String get noteOptional =>
      _localizations?.translate('noteOptional') ?? 'Note (optional)';
  static String get saveChanges =>
      _localizations?.translate('saveChanges') ?? 'Save Changes';
  static String get transfer =>
      _localizations?.translate('transfer') ?? 'Transfer';

  static String get date => _localizations?.translate('date') ?? 'Date';

  static String get totalCount =>
      _localizations?.translate('totalCount') ?? '{} total';

  static String get category =>
      _localizations?.translate('category') ?? 'Category';

  static String format(String template, List<String> args) {
    String result = template;
    for (var arg in args) {
      result = result.replaceFirst('{}', arg);
    }
    return result;
  }
}
