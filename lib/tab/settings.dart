import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' hide Category;
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:local_auth/local_auth.dart';
import 'dart:io';
import 'package:fends/model.dart';

class SettingsTab extends StatefulWidget {
  final Future<void> Function(String)? onImportData;
  final Future<String> Function()? onExportData;
  final VoidCallback? onReset;
  final bool? biometricEnabled;
  final Function(bool)? onBiometricChanged;
  final List<Category>? categories;
  final Function(Category)? onAddCategory;
  final Function(Category)? onUpdateCategory;
  final Function(String)? onDeleteCategory;

  const SettingsTab({
    super.key,
    this.onImportData,
    this.onExportData,
    this.onReset,
    this.biometricEnabled,
    this.onBiometricChanged,
    this.categories,
    this.onAddCategory,
    this.onUpdateCategory,
    this.onDeleteCategory,
  });

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _biometricAvailable = false;
  String _biometricType = '';

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
  }

  Future<void> _checkBiometricAvailability() async {
    try {
      if (kIsWeb) {
        setState(() {
          _biometricAvailable = false;
        });
        return;
      }

      final canAuth = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();

      if (canAuth && isDeviceSupported) {
        final availableBiometrics = await _localAuth.getAvailableBiometrics();
        String type = 'Biometric';

        if (availableBiometrics.contains(BiometricType.face)) {
          type = 'Face ID';
        } else if (availableBiometrics.contains(BiometricType.fingerprint)) {
          type = 'Fingerprint';
        } else if (availableBiometrics.contains(BiometricType.iris)) {
          type = 'Iris';
        }

        setState(() {
          _biometricAvailable = true;
          _biometricType = type;
        });
      } else {
        setState(() {
          _biometricAvailable = false;
        });
      }
    } catch (e) {
      setState(() {
        _biometricAvailable = false;
      });
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    if (value) {
      try {
        final authenticated = await _localAuth.authenticate(
          localizedReason: 'Authenticate to enable biometric lock',
          options: const AuthenticationOptions(
            stickyAuth: true,
            biometricOnly: false,
          ),
        );

        if (authenticated && mounted) {
          widget.onBiometricChanged?.call(true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$_biometricType authentication enabled'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Authentication failed: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } else {
      widget.onBiometricChanged?.call(false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$_biometricType authentication disabled'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Security Section
        if (_biometricAvailable) ...[
          Container(
            clipBehavior: Clip.antiAlias,
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
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.security_outlined,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Security',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: theme.colorScheme.outlineVariant),
                SwitchListTile(
                  secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.fingerprint,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  title: Text('$_biometricType Lock'),
                  subtitle: Text(
                    (widget.biometricEnabled ?? false)
                        ? 'App is locked with $_biometricType'
                        : 'Require $_biometricType to open app',
                  ),
                  value: widget.biometricEnabled ?? false,
                  onChanged: widget.onBiometricChanged != null
                      ? _toggleBiometric
                      : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Categories Management Section
        if (widget.categories != null) ...[
          Container(
            clipBehavior: Clip.antiAlias,
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
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.category_outlined,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Categories',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: theme.colorScheme.outlineVariant),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.edit_outlined,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  title: const Text('Manage Categories'),
                  subtitle: Text('${widget.categories!.length} categories'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showCategoriesManagement(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Data Management Section
        Container(
          clipBehavior: Clip.antiAlias,
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
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.cloud_outlined,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Data Management',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: theme.colorScheme.outlineVariant),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.upload_file, color: Colors.green),
                ),
                title: const Text('Export Data'),
                subtitle: const Text('Save your data as a backup file'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _handleExport(context),
              ),
              Divider(
                height: 1,
                indent: 72,
                color: theme.colorScheme.outlineVariant,
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.download, color: Colors.blue),
                ),
                title: const Text('Import Data'),
                subtitle: const Text('Restore from a backup file'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _handleImport(context),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // App Information Section
        Container(
          clipBehavior: Clip.antiAlias,
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
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.settings_outlined,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'App Information',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: theme.colorScheme.outlineVariant),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.info_outline,
                    color: theme.colorScheme.primary,
                  ),
                ),
                title: const Text('About'),
                subtitle: const Text('App version and information'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  showAboutDialog(
                    context: context,
                    applicationName: 'Fends',
                    applicationVersion: '1.0.0',
                    applicationIcon: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.account_balance_wallet,
                        size: 32,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    children: [
                      const SizedBox(height: 16),
                      const Text(
                        'A simple and beautiful budget tracking app to help you manage your finances.',
                      ),
                    ],
                  );
                },
              ),
              Divider(
                height: 1,
                indent: 72,
                color: theme.colorScheme.outlineVariant,
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.privacy_tip_outlined,
                    color: Colors.orange,
                  ),
                ),
                title: const Text('Privacy Policy'),
                subtitle: const Text('How we handle your data'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Privacy Policy'),
                      content: const SingleChildScrollView(
                        child: Text(
                          'All your financial data is stored locally on your device. '
                          'We do not collect, transmit, or store any of your personal '
                          'information on external servers. Your privacy is our priority.',
                        ),
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
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Danger Zone Section
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.red.withOpacity(0.3), width: 1),
            borderRadius: BorderRadius.circular(16),
            color: theme.colorScheme.surface,
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_outlined,
                      color: Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Danger Zone',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: theme.colorScheme.outlineVariant),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.delete_outline, color: Colors.red),
                ),
                title: const Text('Reset All Data'),
                subtitle: const Text('Delete all transactions and accounts'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      icon: const Icon(
                        Icons.warning_rounded,
                        color: Colors.red,
                        size: 48,
                      ),
                      title: const Text('Reset All Data?'),
                      content: const Text(
                        'Are you sure you want to delete all transactions and accounts? '
                        'This action cannot be undone.\n\n'
                        'Consider exporting your data first as a backup.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () {
                            Navigator.pop(context);
                            if (widget.onReset != null) {
                              widget.onReset!();
                            }
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.red,
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
        ),
        const SizedBox(height: 100),
      ],
    );
  }

  void _showCategoriesManagement(BuildContext context) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              // Drag handle and header
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Manage Categories',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        FilledButton.icon(
                          onPressed: () => _showAddEditCategory(
                            context,
                            null,
                            onSuccess: () => setModalState(() {}),
                          ),
                          icon: const Icon(Icons.add, size: 20),
                          label: const Text('Add'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Categories list
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Expense categories
                    Text(
                      'EXPENSE CATEGORIES',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...widget.categories!
                        .where((c) => c.isExpense && c.name != 'Transfer')
                        .map(
                          (category) => _buildCategoryTile(
                            context,
                            category,
                            onUpdate: () => setModalState(() {}),
                          ),
                        ),
                    const SizedBox(height: 24),
                    // Income categories
                    Text(
                      'INCOME CATEGORIES',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...widget.categories!
                        .where((c) => !c.isExpense && c.name != 'Transfer')
                        .map(
                          (category) => _buildCategoryTile(
                            context,
                            category,
                            onUpdate: () => setModalState(() {}),
                          ),
                        ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryTile(
    BuildContext context,
    Category category, {
    VoidCallback? onUpdate,
  }) {
    final theme = Theme.of(context);
    final isDefaultCategory = _isDefaultCategory(category.name);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        border: Border.all(color: category.color.withOpacity(0.3), width: 1),
        borderRadius: BorderRadius.circular(12),
        color: theme.colorScheme.surface,
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: category.color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(category.icon, color: category.color, size: 20),
        ),
        title: Text(
          category.name,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          isDefaultCategory ? 'Default category' : 'Custom category',
          style: TextStyle(
            fontSize: 12,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              onPressed: () =>
                  _showAddEditCategory(context, category, onSuccess: onUpdate),
              tooltip: 'Edit',
            ),
            if (category.isDeletable)
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                color: Colors.red,
                onPressed: () => _confirmDeleteCategory(
                  context,
                  category,
                  onSuccess: onUpdate,
                ),
                tooltip: 'Delete',
              ),
          ],
        ),
      ),
    );
  }

  void _showAddEditCategory(
    BuildContext context,
    Category? category, {
    VoidCallback? onSuccess,
  }) {
    final theme = Theme.of(context);
    final nameController = TextEditingController(text: category?.name ?? '');
    final isEditing = category != null;
    bool isExpense = category?.isExpense ?? true;
    IconData selectedIcon = category?.icon ?? Icons.category;
    Color selectedColor = category?.color ?? Colors.blue;

    final availableIcons = [
      Icons.restaurant,
      Icons.local_cafe,
      Icons.fastfood,
      Icons.shopping_bag,
      Icons.shopping_cart,
      Icons.card_giftcard,
      Icons.directions_car,
      Icons.local_gas_station,
      Icons.flight,
      Icons.home,
      Icons.bolt,
      Icons.water_drop,
      Icons.wifi,
      Icons.phone_android,
      Icons.movie,
      Icons.sports_esports,
      Icons.sports_soccer,
      Icons.fitness_center,
      Icons.medical_services,
      Icons.medication,
      Icons.school,
      Icons.work,
      Icons.account_balance,
      Icons.savings,
      Icons.trending_up,
      Icons.pets,
      Icons.child_care,
      Icons.checkroom,
      Icons.dry_cleaning,
      Icons.build,
      Icons.computer,
      Icons.headphones,
      Icons.book,
      Icons.brush,
    ];

    final availableColors = [
      Colors.red,
      Colors.pink,
      Colors.purple,
      Colors.deepPurple,
      Colors.indigo,
      Colors.blue,
      Colors.lightBlue,
      Colors.cyan,
      Colors.teal,
      Colors.green,
      Colors.lightGreen,
      Colors.lime,
      Colors.amber,
      Colors.orange,
      Colors.deepOrange,
      Colors.brown,
    ];

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
                    isEditing ? 'Edit Category' : 'Add Category',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Category type
                  Text(
                    'Type',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(
                        value: true,
                        label: Text('Expense'),
                        icon: Icon(Icons.remove_circle_outline),
                      ),
                      ButtonSegment(
                        value: false,
                        label: Text('Income'),
                        icon: Icon(Icons.add_circle_outline),
                      ),
                    ],
                    selected: {isExpense},
                    onSelectionChanged: (v) {
                      setDialogState(() => isExpense = v.first);
                    },
                  ),
                  const SizedBox(height: 24),

                  // Category name
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Category Name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.label_outline),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Icon selector
                  Text(
                    'Icon',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 200,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 6,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                      itemCount: availableIcons.length,
                      itemBuilder: (context, index) {
                        final icon = availableIcons[index];
                        final isSelected = icon == selectedIcon;
                        return InkWell(
                          onTap: () {
                            setDialogState(() => selectedIcon = icon);
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? selectedColor.withOpacity(0.2)
                                  : Colors.transparent,
                              border: Border.all(
                                color: isSelected
                                    ? selectedColor
                                    : theme.colorScheme.outlineVariant,
                                width: isSelected ? 2 : 1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              icon,
                              color: isSelected
                                  ? selectedColor
                                  : theme.colorScheme.onSurfaceVariant,
                              size: 24,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Color selector
                  Text(
                    'Color',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: availableColors.map((color) {
                      final isSelected = color == selectedColor;
                      return InkWell(
                        onTap: () {
                          setDialogState(() => selectedColor = color);
                        },
                        borderRadius: BorderRadius.circular(24),
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? theme.colorScheme.onSurface
                                  : Colors.transparent,
                              width: 3,
                            ),
                          ),
                          child: isSelected
                              ? const Icon(Icons.check, color: Colors.white)
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),

                  // Preview
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: selectedColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            selectedIcon,
                            color: selectedColor,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Preview',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                nameController.text.isEmpty
                                    ? 'Category Name'
                                    : nameController.text,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                isExpense ? 'Expense' : 'Income',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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
                            if (nameController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please enter a category name'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            final newCategory = Category(
                              id:
                                  category?.id ??
                                  DateTime.now().millisecondsSinceEpoch
                                      .toString(),
                              name: nameController.text.trim(),
                              icon: selectedIcon,
                              color: selectedColor,
                              isExpense: isExpense,
                            );

                            if (isEditing) {
                              widget.onUpdateCategory?.call(newCategory);
                            } else {
                              widget.onAddCategory?.call(newCategory);
                            }

                            Navigator.pop(context);
                            onSuccess?.call();

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isEditing
                                      ? 'Category updated successfully'
                                      : 'Category added successfully',
                                ),
                                backgroundColor: Colors.green,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(isEditing ? 'Update' : 'Add Category'),
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

  bool _isDefaultCategory(String name) {
    const defaultCategories = [
      'Food & Dining',
      'Transportation',
      'Shopping',
      'Entertainment',
      'Bills & Utilities',
      'Healthcare',
      'Education',
      'Other',
      'Salary',
      'Investment',
      'Gift',
    ];
    return defaultCategories.contains(name);
  }

  void _confirmDeleteCategory(
    BuildContext context,
    Category category, {
    VoidCallback? onSuccess,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.warning_rounded, color: Colors.orange, size: 48),
        title: const Text('Delete Category?'),
        content: Text(
          'Are you sure you want to delete "${category.name}"?\n\n'
          'Transactions with this category will not be deleted, '
          'but will need to be recategorized.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              widget.onDeleteCategory?.call(category.id);
              Navigator.pop(context);
              onSuccess?.call(); // Call the callback to refresh the list

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Category deleted'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleExport(BuildContext context) async {
    try {
      if (widget.onExportData == null) {
        _showErrorSnackBar(context, 'Export function not available');
        return;
      }

      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Get the data from parent
      final jsonData = await widget.onExportData!();

      // Close loading dialog
      if (context.mounted) Navigator.pop(context);

      // Create a temporary file
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now()
          .toIso8601String()
          .split('.')[0]
          .replaceAll(':', '-');
      final file = File('${directory.path}/fends_backup_$timestamp.json');
      await file.writeAsString(jsonData);

      // Share the file
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Fends Backup',
        text: 'My Fends financial data backup',
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data exported successfully'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading if still open
        _showErrorSnackBar(context, 'Failed to export data: $e');
      }
    }
  }

  Future<void> _handleImport(BuildContext context) async {
    try {
      // Show file picker
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.single.path == null) {
        return;
      }

      // Read the file
      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString();

      // Validate JSON
      try {
        json.decode(jsonString);
      } catch (e) {
        if (context.mounted) {
          _showErrorSnackBar(context, 'Invalid backup file format');
        }
        return;
      }

      // Show confirmation dialog
      if (context.mounted) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            icon: const Icon(
              Icons.warning_rounded,
              color: Colors.orange,
              size: 48,
            ),
            title: const Text('Import Data?'),
            content: const Text(
              'This will replace all your current data with the data from the backup file. '
              'This action cannot be undone.\n\n'
              'Consider exporting your current data first.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Import'),
              ),
            ],
          ),
        );

        if (confirmed == true && context.mounted) {
          // Show loading
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) =>
                const Center(child: CircularProgressIndicator()),
          );

          // Import the data
          if (widget.onImportData != null) {
            await widget.onImportData!(jsonString);
          }

          // Close loading
          if (context.mounted) Navigator.pop(context);

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Data imported successfully'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorSnackBar(context, 'Failed to import data: $e');
      }
    }
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}