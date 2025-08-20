import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:moodmind_new/screens/tasks/mm_points_screen.dart';
import 'package:moodmind_new/screens/tasks/task_scheduler_screen.dart';
import 'package:provider/provider.dart';
import 'package:moodmind_new/services/firebase_service.dart';
import 'package:moodmind_new/providers/auth_provider.dart';
import 'utils/app_theme.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await FirebaseService.initializeFirebase();

  runApp(const MoodMindApp());
}

class MoodMindApp extends StatelessWidget {
  const MoodMindApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => AuthProvider())],
      child: MaterialApp(
        title: 'Mood Mind',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const SplashScreen(),
        routes: {
        '/tasks': (context) => const TaskSchedulerScreen(),
        '/points': (context) => const MMPointsScreen(),
      },
        builder: (context, child) {
          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: const SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.dark,
              systemNavigationBarColor: Colors.white,
              systemNavigationBarIconBrightness: Brightness.dark,
            ),
            child: child!,
          );
        },
      ),
    );
  }
}
