import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService extends ChangeNotifier {
  final SupabaseClient _client = Supabase.instance.client;
  User? _user;
  bool _loading = true;

  SupabaseService() {
    _init();
  }

  User? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _loading;

  Future<void> _init() async {
    final session = _client.auth.currentSession;
    _user = session?.user;
    _loading = false;
    notifyListeners();

    _client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      _user = session?.user;
      notifyListeners();
    });
  }

  Future<String?> signUp(String email, String password, String firstName, String lastName) async {
    try {
      final AuthResponse res = await _client.auth.signUp(
        email: email,
        password: password,
      );

      if (res.user != null) {
        final userId = res.user!.id;

        await _client.from('profiles').insert({
          'id': userId,
          'email': email,
          'first_name': firstName,
          'last_name': lastName,
        });

        return null;
      } else {
        return 'Błąd: Nie udało się zarejestrować użytkownika';
      }
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> signIn(String email, String password) async {
    try {
      final AuthResponse res = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      _user = res.user;
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
    _user = null;
    notifyListeners();
  }
}
