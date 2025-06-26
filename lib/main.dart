import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'providers/main_provider.dart';
import 'providers/auth_provider.dart' as app_auth;
import 'screens/auth/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/trip_details_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/introduction_screen.dart';
import 'models/trip_model.dart';
import 'theme/app_theme.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkMode = false;

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => app_auth.AuthProvider()),
        StreamProvider<User?>.value(
          value: FirebaseAuth.instance.authStateChanges(),
          initialData: null,
        ),
        ChangeNotifierProxyProvider<User?, MainProvider>(
          create: (context) => MainProvider(FirebaseAuth.instance.currentUser?.uid ?? ''),
          update: (context, user, previous) => MainProvider(user?.uid ?? ''),
        ),
      ],
      child: Consumer<User?>(
        builder: (context, user, _) {
          return MaterialApp(
            title: 'Wandersplit',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
            debugShowCheckedModeBanner: false,
            home: user == null
                ? SplashScreen(
                    isDarkMode: _isDarkMode,
                    onThemeToggle: _toggleTheme,
                  )
                : HomeScreen(
                    isDarkMode: _isDarkMode,
                    onThemeToggle: _toggleTheme,
                  ),
            routes: {
              '/home': (context) => HomeScreen(
                    isDarkMode: _isDarkMode,
                    onThemeToggle: _toggleTheme,
                  ),
              '/login': (context) => LoginScreen(
                    isDarkMode: _isDarkMode,
                    onThemeToggle: _toggleTheme,
                  ),
              '/introduction': (context) => IntroductionScreen(
                    isDarkMode: _isDarkMode,
                    onThemeToggle: _toggleTheme,
                  ),
              '/trip_details': (context) {
                final trip = ModalRoute.of(context)!.settings.arguments as TripModel;
                return TripDetailsScreen(
                  trip: trip,
                  isDarkMode: _isDarkMode,
                  onThemeToggle: _toggleTheme,
                );
              },
            },
          );
        },
      ),
    );
  }
}
