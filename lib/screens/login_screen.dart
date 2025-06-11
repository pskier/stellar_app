import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'register_screen.dart';
import 'home_screen.dart';
import '../services/supabase_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String _email = '', _password = '';
  bool _loading = false;
  String? _errorMessage;

  void _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    _formKey.currentState!.save();

    final supabase = context.read<SupabaseService>();
    final error = await supabase.signIn(_email.trim(), _password);

    setState(() {
      _loading = false;
      _errorMessage = error;
    });

    if (error == null) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Logowanie')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                    validator: (val) => val == null || !val.contains('@') ? 'Wpisz poprawny email' : null,
                    onSaved: (val) => _email = val ?? '',
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Hasło'),
                    obscureText: true,
                    validator: (val) => val == null || val.length < 6 ? 'Hasło musi mieć min. 6 znaków' : null,
                    onSaved: (val) => _password = val ?? '',
                  ),
                  const SizedBox(height: 16),
                  if (_errorMessage != null) ...[
                    Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 12),
                  ],
                  ElevatedButton(
                    onPressed: _loading ? null : _login,
                    child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text('Zaloguj się'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen()));
                    },
                    child: const Text('Nie masz konta? Zarejestruj się'),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
