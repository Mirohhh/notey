import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'providers/task_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/home_screen.dart';
import 'services/database_service.dart';
import 'services/notification_service.dart';
// HomeWidget is only available on mobile platforms
import 'package:home_widget/home_widget.dart' if (dart.library.html) 'package:home_widget/home_widget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive with local storage path for web compatibility
  await Hive.initFlutter();

  // For web, we need to ensure the box is opened correctly
  try {
    await DatabaseService().init();
  } catch (e) {
    debugPrint('Failed to initialize database: $e');
    // Continue anyway - app will work with empty database
  }

  if (!kIsWeb) {
    try {
      await NotificationService().initialize();
    } catch (e) {
      debugPrint('Failed to initialize notifications: $e');
      // Notifications are optional, continue anyway
    }

    // Set group ID so the iOS app and widget share data (even though we focus on Android now, it's good practice)
    // This might fail on web, which is okay
    try {
      await HomeWidget.setAppGroupId('group.com.example.flutter_application_2');
    } catch (e) {
      debugPrint('HomeWidget not supported on this platform: $e');
    }
  }

  runApp(const TaskOrganizerApp());
}

class TaskOrganizerApp extends StatelessWidget {
  const TaskOrganizerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()..loadTheme()),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'notey',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: themeProvider.themeMode,
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}
