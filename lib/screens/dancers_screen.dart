import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stellar_pi/model/dancer.dart';

import 'dancer_detal_screen.dart';
import 'edit_dancer_screen.dart';

class DancersScreen extends StatefulWidget {
  final int groupId;
  final String groupName;

  const DancersScreen({Key? key, required this.groupId, required this.groupName}) : super(key: key);

  @override
  State<DancersScreen> createState() => _DancersScreenState();
}

class _DancersScreenState extends State<DancersScreen> {
  final SupabaseClient _client = Supabase.instance.client;
  List<Dancer> _dancers = [];
  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchDancers();
  }

  Future<void> _fetchDancers() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final List<dynamic> data = await _client
          .from('dancers')
          .select()
          .eq('group_id', widget.groupId)
          .order('last_name');

      final fetched = data.map((e) => Dancer.fromMap(e as Map<String, dynamic>)).toList();

      setState(() {
        _dancers = fetched;
        _loading = false;
      });
    } catch (error) {
      setState(() {
        _loading = false;
        _errorMessage = 'Nie udało się pobrać tancerek:\n$error';
      });
    }
  }

  Future<void> _navigateToAddDancer() async {
    final added = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EditDancerScreen(groupId: widget.groupId),
      ),
    );

    if (added == true) {
      _fetchDancers();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tancerki: ${widget.groupName}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchDancers,
            tooltip: 'Odśwież',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _navigateToAddDancer,
            tooltip: 'Dodaj tancerkę',
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
            : _dancers.isEmpty
            ? const Center(child: Text('Brak tancerek do wyświetlenia.'))
            : ListView.builder(
          itemCount: _dancers.length,
          itemBuilder: (context, index) {
            final dancer = _dancers[index];
            return ListTile(
              title: Text('${dancer.firstName} ${dancer.lastName}'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DancerDetailsScreen(dancer: dancer),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
