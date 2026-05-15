import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'providers/explore_provider.dart';
import 'views/auth_wrapper.dart';

void main() async { 
  // These two lines boot Firebase BEFORE the app runs
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ExploreProvider()),
      ],
      child: const DPSChefApp(),
    ),
  );
}

class DPSChefApp extends StatelessWidget {
  const DPSChefApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DPS Chef',
      debugShowCheckedModeBanner: false, 
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepOrange,
          brightness: Brightness.light, 
        ),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
    );
  }
}
