import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class InfoScreen extends StatefulWidget {
  const InfoScreen({Key? key}) : super(key: key);

  @override
  State<InfoScreen> createState() => _InfoScreenState();
}

class _InfoScreenState extends State<InfoScreen> {
  final SupabaseClient _client = Supabase.instance.client;
  final TextEditingController _controller = TextEditingController();
  List<Map<String, dynamic>> _infoList = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchInfo();
  }

  Future<void> _fetchInfo() async {
    setState(() => _loading = true);
    try {
      final data = await _client
          .from('info')
          .select()
          .order('created_at', ascending: false);
      setState(() {
        _infoList = List<Map<String, dynamic>>.from(data);
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Błąd pobierania ogłoszeń: $e')),
      );
    }
  }

  Future<void> _addInfo() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    try {
      await _client.from('info').insert({'message': text});
      _controller.clear();
      _fetchInfo();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Błąd dodawania ogłoszenia: $e')),
      );
    }
  }

  Future<void> _deleteInfo(int id) async {
    try {
      await _client.from('info').delete().eq('id', id);
      _fetchInfo();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Błąd usuwania ogłoszenia: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ogłoszenia')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      labelText: 'Dodaj ogłoszenie',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _addInfo,
                  child: const Text('Dodaj'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _loading
                ? const Center(child: CircularProgressIndicator())
                : Expanded(
              child: _infoList.isEmpty
                  ? const Center(child: Text('Brak ogłoszeń.'))
                  : ListView.builder(
                itemCount: _infoList.length,
                itemBuilder: (context, index) {
                  final item = _infoList[index];
                  return Card(
                    child: ListTile(
                      title: Text(item['message']),
                      subtitle: Text(item['created_at'] ?? ''),
                      onLongPress: () => _deleteInfo(item['id']),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
