import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/firestore_service.dart';
import '../../models/settings_model.dart';
import '../../core/providers/theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  final String userId;

  const SettingsScreen({super.key, required this.userId});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  late String _currentTheme;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await _firestoreService.getSettings(widget.userId);
      setState(() {
        _currentTheme = settings.theme;
        _isLoading = false;
      });
    } catch (e) {
      // If settings don't exist yet, use default
      setState(() {
        _currentTheme = 'dark';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveTheme(String theme) async {
    try {
      final settings = Settings(
        userId: widget.userId,
        theme: theme,
      );

      await _firestoreService.updateSettings(settings);

      // Update the theme provider
      if (mounted) {
        final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
        themeProvider.setTheme(theme == 'light' ? ThemeMode.light : ThemeMode.dark);
      }

      setState(() {
        _currentTheme = theme;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Theme updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update theme: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Theme',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          RadioGroup<String>(
                            groupValue: _currentTheme,
                            onChanged: (value) => _saveTheme(value!),
                            child: Column(
                              children: [
                                RadioListTile<String>(
                                  title: const Text('Dark'),
                                  value: 'dark',
                                ),
                                RadioListTile<String>(
                                  title: const Text('Light'),
                                  value: 'light',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'About',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Sleep Optimizer\nVersion 1.0.0\n\n'
                            'An educational tool to help high school students improve their sleep habits.',
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'Back to Home',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
