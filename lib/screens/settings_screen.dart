import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../providers/record_provider.dart';   // add this import
import '../models/settings.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _totalHoursController;
  late TextEditingController _allowanceController;
  late TextEditingController _employeeNameController;   // new
  late TextEditingController _supervisorNameController; // new

  @override
  void initState() {
    super.initState();
    final settings = Provider.of<SettingsProvider>(context, listen: false).settings;
    _totalHoursController = TextEditingController(text: settings.totalRequiredHours?.toString() ?? '500');
    _allowanceController = TextEditingController(text: settings.allowancePerDay?.toString() ?? '0');
    _employeeNameController = TextEditingController(text: settings.employeeName ?? '');
    _supervisorNameController = TextEditingController(text: settings.supervisorName ?? '');
  }

  @override
  void dispose() {
    _totalHoursController.dispose();
    _allowanceController.dispose();
    _employeeNameController.dispose();
    _supervisorNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _totalHoursController,
                decoration: const InputDecoration(
                  labelText: 'Total Required OJT Hours',
                  hintText: 'e.g., 500',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter total hours';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _allowanceController,
                decoration: const InputDecoration(
                  labelText: 'Daily Allowance (₱)',
                  hintText: 'Optional, 0 if none',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return null;
                  if (double.tryParse(value) == null) {
                    return 'Enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _employeeNameController,
                decoration: const InputDecoration(
                  labelText: 'Employee Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _supervisorNameController,
                decoration: const InputDecoration(
                  labelText: 'Supervisor Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final totalHours = double.parse(_totalHoursController.text);
                    final allowance = _allowanceController.text.isEmpty
                        ? 0.0
                        : double.parse(_allowanceController.text);
                    final employeeName = _employeeNameController.text.trim();
                    final supervisorName = _supervisorNameController.text.trim();

                    await settingsProvider.updateSettings(
                      AppSettings(
                        totalRequiredHours: totalHours,
                        allowancePerDay: allowance,
                        employeeName: employeeName,
                        supervisorName: supervisorName,
                      ),
                    );

                    // Recalculate allowance for all records
                    final recordProvider = Provider.of<RecordProvider>(context, listen: false);
                    await recordProvider.recalculateAllowance(allowance);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Settings saved and allowance updated for all records')),
                    );
                    Navigator.pop(context);
                  }
                },
                child: const Text('Save Settings'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}