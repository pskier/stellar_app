import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditDancerScreen extends StatefulWidget {
  final int groupId;

  const EditDancerScreen({Key? key, required this.groupId}) : super(key: key);

  @override
  State<EditDancerScreen> createState() => _EditDancerScreenState();
}

class _EditDancerScreenState extends State<EditDancerScreen> {
  final SupabaseClient _client = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();

  String _firstName = '';
  String _lastName = '';
  bool _saving = false;

  Future<void> _saveDancer() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();

    setState(() {
      _saving = true;
    });

    try {
      await _client.from('dancers').insert({
        'first_name': _firstName,
        'last_name': _lastName,
        'group_id': widget.groupId,
      });

      Navigator.pop(context, true);
    } catch (error) {
      setState(() {
        _saving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Błąd zapisu tancerki:\n$error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dodaj tancerkę'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _saving
            ? const Center(child: CircularProgressIndicator())
            : Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Imię'),
                validator: (value) => (value == null || value.trim().isEmpty) ? 'Podaj imię' : null,
                onSaved: (value) => _firstName = value!.trim(),
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Nazwisko'),
                validator: (value) => (value == null || value.trim().isEmpty) ? 'Podaj nazwisko' : null,
                onSaved: (value) => _lastName = value!.trim(),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveDancer,
                child: const Text('Zapisz'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
