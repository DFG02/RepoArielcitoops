import 'package:flutter/material.dart';
import 'package:psicalendar_movil/views/home_screen.dart';
import 'package:psicalendar_movil/views/calendar_screen.dart';
import 'package:psicalendar_movil/views/day_screen.dart';
import 'package:psicalendar_movil/views/about_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PsiCalendar',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomeScreen(),
      initialRoute: '/home',
      routes: {
        '/home': (context) => HomeScreen(),
        '/calendar': (context) => CalendarScreen(),
        '/day': (context) => DayScreen(),
        '/about': (context) => AboutScreen(),
      },
    );
  }
}
