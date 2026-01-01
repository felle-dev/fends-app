import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class SettingsTab extends StatelessWidget {
  final Future<void> Function(String)? onImportData;
  final Future<String> Function()? onExportData;
  final VoidCallback? onReset;

  const SettingsTab({
    super.key,
    this.onImportData,
    this.onExportData,
    this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Data Management Section
        Container(
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
                            if (onReset != null) {
                              onReset!();
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

  Future<void> _handleExport(BuildContext context) async {
    try {
      if (onExportData == null) {
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
      final jsonData = await onExportData!();

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
          if (onImportData != null) {
            await onImportData!(jsonString);
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
