import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      // Transactions
      'transactions': 'Transactions',
      'totalTransactions': '{} total',
      'noTransactionsInPeriod': 'No transactions in this period',
      'unknownCategory': 'Unknown Category',
      'week': 'Week',
      'month': 'Month',
      'allTime': 'All Time',
      'spent': 'Spent',
      'expenses': 'Expenses',
      'weeklyTrend': 'Weekly Trend',
      'topCategories': 'Top Categories',
      'editTransaction': 'Edit Transaction',
      'deleteTransaction': 'Delete Transaction',
      'deleteTransactionConfirm':
          'Are you sure you want to delete this transaction?',
      'transactionDeleted': 'Transaction deleted',
      'transactionUpdated': 'Transaction updated',
      'amount': 'Amount',
      'account': 'Account',
      'fromAccount': 'From Account',
      'toAccount': 'To Account',
      'category': 'Category',
      'date': 'Date',
      'noteOptional': 'Note (optional)',
      'saveChanges': 'Save Changes',
      'transfer': 'Transfer',
      'totalCount': '{} total',
      'transactionCount': '{} Transaction{}',

      // Accounts
      'accounts': 'Accounts',
      'noAccountsYet': 'No accounts yet',
      'addFirstAccount': 'Add your first account to start tracking',
      'totalNetWorth': 'Total Net Worth',
      'acrossAccounts': 'across {} account{}',
      'addAccount': 'Add Account',
      'deleteAccount': 'Delete Account',
      'deleteAccountQuestion': 'Delete Account?',
      'deleteAccountConfirm': 'Are you sure you want to delete this account?',
      'deleteAccountWithTransactionsWarning':
          'This account has {} transaction{}. Deleting this account will also delete all associated transactions.',
      'mustHaveOneAccount': 'You must have at least one account',
      'cannotDeleteLastAccount': 'Cannot delete last account',
      'accountDeleted': 'Account deleted',
      'accountAndTransactionsDeleted': 'Account and {} transaction{} deleted',
      'accountName': 'Account Name',
      'initialBalance': 'Initial Balance',
      'accountType': 'Account Type',
      'currentBalance': 'Current Balance',
      'initial': 'Initial',
      'netChange': 'Net Change',
      'actionCannotBeUndone': 'This action cannot be undone.',

      // Overview
      'overview': 'Overview',
      'balanceTrend': 'Balance Trend',
      'viewAll': 'View All',
      'daysLeft': '{} days left',
      'ofBudget': 'of {} budget',
      'todaysBudgetRemaining': 'Today\'s Budget Remaining',
      'spendingByCategory': 'Spending by Category',

      // Home & Navigation
      'settings': 'Settings',
      'addTransaction': 'Add Transaction',
      'transferToAccount': 'Transfer to {}',
      'transferFromAccount': 'Transfer from {}',

      // Security
      'security': 'Security',
      'biometricLock': 'Lock',
      'appIsLockedWith': 'App is locked with',
      'requireToOpenApp': 'Require {} to open app',
      'authenticateToEnable': 'Authenticate to enable biometric lock',
      'authenticationEnabled': '{} authentication enabled',
      'authenticationDisabled': '{} authentication disabled',
      'authenticationFailed': 'Authentication failed: {}',

      // Appearance
      'appearance': 'Appearance',
      'theme': 'Theme',
      'materialYou': 'Material You',
      'usingSystemColors': 'Using system colors',
      'usingDefaultColors': 'Using default colors',
      'dynamicColorsEnabled': 'Dynamic colors enabled',
      'dynamicColorsDisabled': 'Dynamic colors disabled',
      'chooseTheme': 'Choose Theme',
      'light': 'Light',
      'dark': 'Dark',
      'system': 'System',
      'alwaysUseLightTheme': 'Always use light theme',
      'alwaysUseDarkTheme': 'Always use dark theme',
      'followSystemSettings': 'Follow system settings',
      'themeChangedTo': 'Theme changed to {}',

      // Language
      'language': 'Language',
      'changeLanguage': 'Change Language',
      'currentLanguage': 'Current language',
      'english': 'English',
      'indonesian': 'Indonesian',
      'languageChangedTo': 'Language changed to {}',

      // Categories
      'categories': 'Categories',
      'manageCategories': 'Manage Categories',
      'categoriesCount': '{} categories',
      'addCategory': 'Add Category',
      'editCategory': 'Edit Category',
      'categoryName': 'Category Name',
      'type': 'Type',
      'expense': 'Expense',
      'income': 'Income',
      'icon': 'Icon',
      'color': 'Color',
      'preview': 'Preview',
      'defaultCategory': 'Default category',
      'customCategory': 'Custom category',
      'deleteCategory': 'Delete Category?',
      'deleteCategoryConfirm':
          'Are you sure you want to delete "{}"?\n\nTransactions with this category will not be deleted, but will need to be recategorized.',
      'categoryDeleted': 'Category deleted',
      'categoryAddedSuccess': 'Category added successfully',
      'categoryUpdatedSuccess': 'Category updated successfully',
      'pleaseEnterCategoryName': 'Please enter a category name',
      'expenseCategories': 'EXPENSE CATEGORIES',
      'incomeCategories': 'INCOME CATEGORIES',
      'add': 'Add',
      'update': 'Update',
      'edit': 'Edit',
      'delete': 'Delete',

      // Data Management
      'dataManagement': 'Data Management',
      'exportData': 'Export Data',
      'importData': 'Import Data',
      'saveDataBackup': 'Save your data as a backup file',
      'restoreFromBackup': 'Restore from a backup file',
      'dataExportedSuccess': 'Data exported successfully',
      'dataImportedSuccess': 'Data imported successfully',
      'exportFailed': 'Failed to export data: {}',
      'importFailed': 'Failed to import data: {}',
      'invalidBackupFile': 'Invalid backup file format',
      'importDataQuestion': 'Import Data?',
      'importWarning':
          'This will replace all your current data with the data from the backup file. This action cannot be undone.\n\nConsider exporting your current data first.',
      'exportFunctionNotAvailable': 'Export function not available',
      'import': 'Import',

      // App Information
      'appInformation': 'App Information',
      'about': 'About',
      'appVersionInfo': 'App version and information',
      'appName': 'Fends',
      'appVersion': '1.0.0',
      'appDescription':
          'A simple and beautiful budget tracking app to help you manage your finances.',
      'privacyPolicy': 'Privacy Policy',
      'howWeHandleData': 'How we handle your data',
      'privacyMessage':
          'All your financial data is stored locally on your device. We do not collect, transmit, or store any of your personal information on external servers. Your privacy is our priority.',
      'close': 'Close',

      // Danger Zone
      'dangerZone': 'Danger Zone',
      'resetAllData': 'Reset All Data',
      'deleteAllTransactions': 'Delete all transactions and accounts',
      'resetDataQuestion': 'Reset All Data?',
      'resetWarning':
          'Are you sure you want to delete all transactions and accounts? This action cannot be undone.\n\nConsider exporting your data first as a backup.',
      'reset': 'Reset',
      'cancel': 'Cancel',
    },
    'id': {
      // Transactions
      'transactions': 'Transaksi',
      'totalTransactions': '{} total',
      'noTransactionsInPeriod': 'Tidak ada transaksi di periode ini',
      'unknownCategory': 'Kategori Tidak Dikenal',
      'week': 'Minggu',
      'month': 'Bulan',
      'allTime': 'Semua',
      'spent': 'Pengeluaran',
      'expenses': 'Pengeluaran',
      'weeklyTrend': 'Tren Mingguan',
      'topCategories': 'Kategori Teratas',
      'editTransaction': 'Edit Transaksi',
      'deleteTransaction': 'Hapus Transaksi',
      'deleteTransactionConfirm':
          'Apakah Anda yakin ingin menghapus transaksi ini?',
      'transactionDeleted': 'Transaksi dihapus',
      'transactionUpdated': 'Transaksi diperbarui',
      'amount': 'Jumlah',
      'account': 'Akun',
      'fromAccount': 'Dari Akun',
      'toAccount': 'Ke Akun',
      'category': 'Kategori',
      'date': 'Tanggal',
      'noteOptional': 'Catatan (opsional)',
      'saveChanges': 'Simpan Perubahan',
      'transfer': 'Transfer',
      'totalCount': '{} total',
      'transactionCount': '{} Transaksi',

      // Accounts
      'accounts': 'Akun',
      'noAccountsYet': 'Belum ada akun',
      'addFirstAccount': 'Tambahkan akun pertama Anda untuk mulai melacak',
      'totalNetWorth': 'Total Kekayaan Bersih',
      'acrossAccounts': 'dari {} akun',
      'addAccount': 'Tambah Akun',
      'deleteAccount': 'Hapus Akun',
      'deleteAccountQuestion': 'Hapus Akun?',
      'deleteAccountConfirm': 'Apakah Anda yakin ingin menghapus akun ini?',
      'deleteAccountWithTransactionsWarning':
          'Akun ini memiliki {} transaksi. Menghapus akun ini juga akan menghapus semua transaksi terkait.',
      'mustHaveOneAccount': 'Anda harus memiliki setidaknya satu akun',
      'cannotDeleteLastAccount': 'Tidak dapat menghapus akun terakhir',
      'accountDeleted': 'Akun dihapus',
      'accountAndTransactionsDeleted': 'Akun dan {} transaksi dihapus',
      'accountName': 'Nama Akun',
      'initialBalance': 'Saldo Awal',
      'accountType': 'Tipe Akun',
      'currentBalance': 'Saldo Saat Ini',
      'initial': 'Awal',
      'netChange': 'Perubahan Bersih',
      'actionCannotBeUndone': 'Tindakan ini tidak dapat dibatalkan.',

      // Overview
      'overview': 'Ringkasan',
      'balanceTrend': 'Tren Saldo',
      'viewAll': 'Lihat Semua',
      'daysLeft': '{} hari tersisa',
      'ofBudget': 'dari {} anggaran',
      'todaysBudgetRemaining': 'Sisa Anggaran Hari Ini',
      'spendingByCategory': 'Pengeluaran per Kategori',

      // Home & Navigation
      'settings': 'Pengaturan',
      'addTransaction': 'Tambah Transaksi',
      'transferToAccount': 'Transfer ke {}',
      'transferFromAccount': 'Transfer dari {}',

      // Security
      'security': 'Keamanan',
      'biometricLock': 'Kunci',
      'appIsLockedWith': 'Aplikasi dikunci dengan',
      'requireToOpenApp': 'Memerlukan {} untuk membuka aplikasi',
      'authenticateToEnable': 'Autentikasi untuk mengaktifkan kunci biometrik',
      'authenticationEnabled': 'Autentikasi {} diaktifkan',
      'authenticationDisabled': 'Autentikasi {} dinonaktifkan',
      'authenticationFailed': 'Autentikasi gagal: {}',

      // Appearance
      'appearance': 'Tampilan',
      'theme': 'Tema',
      'materialYou': 'Material You',
      'usingSystemColors': 'Menggunakan warna sistem',
      'usingDefaultColors': 'Menggunakan warna default',
      'dynamicColorsEnabled': 'Warna dinamis diaktifkan',
      'dynamicColorsDisabled': 'Warna dinamis dinonaktifkan',
      'chooseTheme': 'Pilih Tema',
      'light': 'Terang',
      'dark': 'Gelap',
      'system': 'Sistem',
      'alwaysUseLightTheme': 'Selalu gunakan tema terang',
      'alwaysUseDarkTheme': 'Selalu gunakan tema gelap',
      'followSystemSettings': 'Ikuti pengaturan sistem',
      'themeChangedTo': 'Tema diubah ke {}',

      // Language
      'language': 'Bahasa',
      'changeLanguage': 'Ubah Bahasa',
      'currentLanguage': 'Bahasa saat ini',
      'english': 'Inggris',
      'indonesian': 'Indonesia',
      'languageChangedTo': 'Bahasa diubah ke {}',

      // Categories
      'categories': 'Kategori',
      'manageCategories': 'Kelola Kategori',
      'categoriesCount': '{} kategori',
      'addCategory': 'Tambah Kategori',
      'editCategory': 'Edit Kategori',
      'categoryName': 'Nama Kategori',
      'type': 'Tipe',
      'expense': 'Pengeluaran',
      'income': 'Pemasukan',
      'icon': 'Ikon',
      'color': 'Warna',
      'preview': 'Pratinjau',
      'defaultCategory': 'Kategori default',
      'customCategory': 'Kategori kustom',
      'deleteCategory': 'Hapus Kategori?',
      'deleteCategoryConfirm':
          'Apakah Anda yakin ingin menghapus "{}"?\n\nTransaksi dengan kategori ini tidak akan dihapus, tetapi perlu dikategorikan ulang.',
      'categoryDeleted': 'Kategori dihapus',
      'categoryAddedSuccess': 'Kategori berhasil ditambahkan',
      'categoryUpdatedSuccess': 'Kategori berhasil diperbarui',
      'pleaseEnterCategoryName': 'Silakan masukkan nama kategori',
      'expenseCategories': 'KATEGORI PENGELUARAN',
      'incomeCategories': 'KATEGORI PEMASUKAN',
      'add': 'Tambah',
      'update': 'Perbarui',
      'edit': 'Edit',
      'delete': 'Hapus',

      // Data Management
      'dataManagement': 'Manajemen Data',
      'exportData': 'Ekspor Data',
      'importData': 'Impor Data',
      'saveDataBackup': 'Simpan data Anda sebagai file cadangan',
      'restoreFromBackup': 'Pulihkan dari file cadangan',
      'dataExportedSuccess': 'Data berhasil diekspor',
      'dataImportedSuccess': 'Data berhasil diimpor',
      'exportFailed': 'Gagal mengekspor data: {}',
      'importFailed': 'Gagal mengimpor data: {}',
      'invalidBackupFile': 'Format file cadangan tidak valid',
      'importDataQuestion': 'Impor Data?',
      'importWarning':
          'Ini akan mengganti semua data Anda saat ini dengan data dari file cadangan. Tindakan ini tidak dapat dibatalkan.\n\nPertimbangkan untuk mengekspor data Anda saat ini terlebih dahulu.',
      'exportFunctionNotAvailable': 'Fungsi ekspor tidak tersedia',
      'import': 'Impor',

      // App Information
      'appInformation': 'Informasi Aplikasi',
      'about': 'Tentang',
      'appVersionInfo': 'Versi dan informasi aplikasi',
      'appName': 'Fends',
      'appVersion': '1.0.0',
      'appDescription':
          'Aplikasi pelacakan anggaran yang sederhana dan indah untuk membantu Anda mengelola keuangan.',
      'privacyPolicy': 'Kebijakan Privasi',
      'howWeHandleData': 'Bagaimana kami menangani data Anda',
      'privacyMessage':
          'Semua data keuangan Anda disimpan secara lokal di perangkat Anda. Kami tidak mengumpulkan, mentransmisikan, atau menyimpan informasi pribadi Anda di server eksternal. Privasi Anda adalah prioritas kami.',
      'close': 'Tutup',

      // Danger Zone
      'dangerZone': 'Zona Berbahaya',
      'resetAllData': 'Reset Semua Data',
      'deleteAllTransactions': 'Hapus semua transaksi dan akun',
      'resetDataQuestion': 'Reset Semua Data?',
      'resetWarning':
          'Apakah Anda yakin ingin menghapus semua transaksi dan akun? Tindakan ini tidak dapat dibatalkan.\n\nPertimbangkan untuk mengekspor data Anda terlebih dahulu sebagai cadangan.',
      'reset': 'Reset',
      'cancel': 'Batal',
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }

  String format(String key, List<String> args) {
    String result = translate(key);
    for (var arg in args) {
      result = result.replaceFirst('{}', arg);
    }
    return result;
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'id'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
