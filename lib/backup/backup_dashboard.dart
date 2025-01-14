import 'package:flutter/material.dart';
import 'package:stock_rental/backup/backup_service.dart';
import 'package:stock_rental/config/app_theme.dart';

class BackupDashboard extends StatefulWidget {
  @override
  _BackupDashboardState createState() => _BackupDashboardState();
}

class _BackupDashboardState extends State<BackupDashboard> {
  // final BackupService _backupService = BackupService();
  bool _isLoading = false;
  String _lastBackupDate = 'Never';
  bool _autoBackupEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadBackupSettings();
  }

  Future<void> _loadBackupSettings() async {
    // Load last backup date and auto backup settings
    // setState(() {
    //   _isLoading = true;
    // });
    // try {
    //   final settings = await _backupService.getBackupSettings();
    //   setState(() {
    //     _lastBackupDate = settings.lastBackupDate ?? 'Never';
    //     _autoBackupEnabled = settings.autoBackupEnabled;
    //   });
    // } catch (e) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(content: Text('Failed to load backup settings: $e')),
    //   );
    // } finally {
    //   setState(() {
    //     _isLoading = false;
    //   });
    // }
  }

  Future<void> _performManualBackup() async {
    // setState(() {
    //   _isLoading = true;
    // });
    // try {
    //   await _backupService.performBackup();
    //   await _loadBackupSettings();
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(content: Text('Backup completed successfully')),
    //   );
    // } catch (e) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(content: Text('Backup failed: $e')),
    //   );
    // } finally {
    //   setState(() {
    //     _isLoading = false;
    //   });
    // }
  }

  Future<void> _toggleAutoBackup(bool value) async {
    // try {
    //   await _backupService.setAutoBackup(value);
    //   setState(() {
    //     _autoBackupEnabled = value;
    //   });
    // } catch (e) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(content: Text('Failed to update auto backup settings: $e')),
    //   );
    // }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Backup Management'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Backup Status',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text('Last Backup: $_lastBackupDate'),
                          SizedBox(height: 16),
                          ElevatedButton.icon(
                            icon: Icon(Icons.backup),
                            label: Text('Backup Now'),
                            onPressed: _performManualBackup,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Backup Settings',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SwitchListTile(
                            title: Text('Auto Backup'),
                            subtitle: Text(
                              'Automatically backup data every day',
                            ),
                            value: _autoBackupEnabled,
                            onChanged: _toggleAutoBackup,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
