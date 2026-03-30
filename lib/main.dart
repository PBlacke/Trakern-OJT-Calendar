import 'package:flutter/material.dart';
import 'package:ojt_app/screens/about_screen.dart';
import 'package:provider/provider.dart';
import 'providers/record_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/main_screen.dart';
import 'screens/dtr_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/export_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settingsProvider = SettingsProvider();
  await settingsProvider.loadSettings();
  final recordProvider = RecordProvider();
  await recordProvider.loadRecords();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settingsProvider),
        ChangeNotifierProvider.value(value: recordProvider),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trackern OJT Calendar',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/',
      routes: {
        '/': (context) => const MainScreen(),
        '/dtr': (context) => const DTRScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/export': (context) => const ExportScreen(),
        '/about': (context) => const AboutScreen(),
      },
    );
  }
}

