import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'providers/main_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/trip_details_screen.dart';
import 'screens/splash_screen.dart';
import 'models/trip_model.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        StreamProvider<User?>.value(
          value: FirebaseAuth.instance.authStateChanges(),
          initialData: null,
        ),
        ChangeNotifierProxyProvider<User?, MainProvider>(
          create: (context) => MainProvider(FirebaseAuth.instance.currentUser?.uid ?? ''),
          update: (context, user, previous) => MainProvider(user?.uid ?? ''),
        ),
      ],
      child: MaterialApp(
        title: 'Wandersplit',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        home: const SplashScreen(),
        routes: {
          '/home': (context) => const HomeScreen(),
          '/login': (context) => const LoginScreen(),
          '/trip_details': (context) {
            final trip = ModalRoute.of(context)!.settings.arguments as TripModel;
            return TripDetailsScreen(trip: trip);
          },
        },
      ),
    );
  }
}
