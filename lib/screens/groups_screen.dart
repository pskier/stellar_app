import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stellar_pi/model/group.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({Key? key}) : super(key: key);

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  final SupabaseClient _client = Supabase.instance.client;
  List<Group> _groups = [];
  bool _loading = true;
  String? _errorMessage;
  final _formKey = GlobalKey<FormState>();
  String _newGroupName = '';

  @override
  void initState() {
    super.initState();
    _fetchGroups();
  }

  Future<void> _fetchGroups() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      // Pobranie danych jako surowa lista dynamic (bez .execute())
      final List<dynamic> data = await _client
          .from('groups')
          .select()
          .order('name');

      // Mapowanie do modelu
      final fetched = data.map((e) {
        try {
          return Group.fromMap(e as Map<String, dynamic>);
        } catch (err) {
          debugPrint('Błąd mapowania wpisu: $e\n$err');
          return null;
        }
      }).whereType<Group>().toList();

      setState(() {
        _groups = fetched;
        _loading = false;
      });
    } catch (error) {
      // Jeśli coś poszło nie tak w trakcie zapytania lub mapowania
      debugPrint('Błąd podczas pobierania grup: $error');
      setState(() {
        _loading = false;
        _errorMessage = 'Nie udało się pobrać grup:\n$error';
      });
    }
  }

  Future<void> _addGroup() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    try {
      // Dodanie nowej grupy
      final response = await _client.from('groups').insert({'name': _newGroupName});
      // Jeśli włączyłeś RLS, sprawdź error w logu tutaj

      // Odśwież listę
      _fetchGroups();
      Navigator.pop(context);
    } catch (error) {
      debugPrint('Błąd podczas dodawania grupy: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Błąd dodawania grupy:\n$error')),
      );
    }
  }

  void _showAddGroupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dodaj grupę'),
        content: Form(
          key: _formKey,
          child: TextFormField(
            decoration: const InputDecoration(labelText: 'Nazwa grupy'),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Podaj nazwę';
              }
              return null;
            },
            onSaved: (value) => _newGroupName = value!.trim(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anuluj'),
          ),
          ElevatedButton(
            onPressed: _addGroup,
            child: const Text('Dodaj'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Grupy taneczne'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchGroups,
            tooltip: 'Odśwież listę',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddGroupDialog,
            tooltip: 'Dodaj grupę',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
            ? Center(
          child: Text(
            _errorMessage!,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        )
            : _groups.isEmpty
            ? const Center(child: Text('Brak grup do wyświetlenia.'))
            : ListView.builder(
          itemCount: _groups.length,
          itemBuilder: (context, index) {
            final group = _groups[index];
            return ListTile(
              leading: CircleAvatar(
                child: Text('${index + 1}'),
              ),
              title: Text(group.name),
              onTap: () {
                // tutaj można np. przejść do listy tancerek w danej grupie
              },
            );
          },
        ),
      ),
    );
  }
}
