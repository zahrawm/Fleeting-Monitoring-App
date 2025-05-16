import 'package:firebase_core/firebase_core.dart';
import 'package:fleeting_monitoring_app/firebase_options.dart';
import 'package:fleeting_monitoring_app/provider/auth_provider.dart';
import 'package:fleeting_monitoring_app/screens/home_screen.dart';
import 'package:fleeting_monitoring_app/screens/login_screen.dart';
import 'package:fleeting_monitoring_app/screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => AuthProvider())],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      initialRoute: '/',
      routes: {
        '/': (_) => const SplashScreen(),
        '/login': (_) => const LoginScreen(),
         '/home': (_) => const HomeScreen(),
      },
    );
  }
}
