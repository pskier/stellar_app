import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'services/supabase_service.dart';
import 'services/google_calendar_service.dart'; // DODAJ TEN IMPORT

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: "assets/.env");

    // Walidacja konfiguracji
    _validateEnvVars();

    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    );

    runApp(const StellarApp());
  } catch (e) {
    runApp(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Text('Błąd inicjalizacji: ${e.toString()}',
                  style: const TextStyle(color: Colors.red, fontSize: 16)),
            ),
          ),
        ));
    }
    }

void _validateEnvVars() {
  final requiredVars = [
    'SUPABASE_URL',
    'SUPABASE_ANON_KEY',
    'GOOGLE_CLIENT_ID_ANDROID',
  ];
  for (final varName in requiredVars) {
    if (dotenv.env[varName] == null || dotenv.env[varName]!.isEmpty) {
      throw Exception('Brak wymaganej zmiennej: $varName');
    }
  }
}

class StellarApp extends StatelessWidget {
  const StellarApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SupabaseService()),
        Provider(create: (_) => GoogleCalendarService(clientId: '90834030737-1158auo3l9q1l3n5oelvjlrlc3rrk96e.apps.googleusercontent.com')),
      ],
      child: MaterialApp(
        title: 'Stellar App',
        theme: ThemeData(
          primarySwatch: Colors.deepPurple,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final supabase = context.watch<SupabaseService>();

    if (supabase.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (supabase.isAuthenticated) {
      return const HomeScreen();
    } else {
      return const LoginScreen();
    }
  }
}