import 'package:firebase_core/firebase_core.dart';
import 'package:fleeting_monitoring_app/firebase_options.dart';
import 'package:fleeting_monitoring_app/models/car_data.dart';
import 'package:fleeting_monitoring_app/provider/auth_provider.dart';
import 'package:fleeting_monitoring_app/provider/car_location_provider.dart';
import 'package:fleeting_monitoring_app/provider/car_storage_provider.dart';
import 'package:fleeting_monitoring_app/screens/home_screen.dart';
import 'package:fleeting_monitoring_app/screens/login_screen.dart';
import 'package:fleeting_monitoring_app/screens/saved_cars_screen.dart';
import 'package:fleeting_monitoring_app/screens/splash_screen.dart';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

void main() async {
  await dotenv.load(fileName: ".env");
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    await Hive.initFlutter();
  } else {
    await Hive.initFlutter();
  }

  Hive.registerAdapter(CarDataAdapter());

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CarLocationProvider()),
        ChangeNotifierProvider(create: (_) => CarStorageProvider()..init()),
      ],
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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      initialRoute: '/',
      routes: {
        '/': (_) => const SplashScreen(),
        '/login': (_) => const LoginScreen(),
        '/home': (_) => HomeScreen(),
        '/saved_cars': (_) => const SavedCarsScreen(),
      },
    );
  }
}
