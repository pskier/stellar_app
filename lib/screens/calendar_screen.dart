import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stellar_pi/services/google_calendar_service.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({Key? key}) : super(key: key);

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final _calendarService = GoogleCalendarService(
    clientId: '90834030737-1158auo3l9q1l3n5oelvjlrlc3rrk96e.apps.googleusercontent.com',
  );


  bool _loading = false;
  String? _errorMessage;
  List<dynamic> _events = [];

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final events = await _calendarService.getUpcomingEvents();
      setState(() {
        _events = events;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _showAddEventDialog() async {
    final titleController = TextEditingController();
    DateTime start = DateTime.now().add(const Duration(hours: 1));
    DateTime end = start.add(const Duration(hours: 1));

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Dodaj wydarzenie'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Tytuł'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: start,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    start = DateTime(
                      picked.year,
                      picked.month,
                      picked.day,
                      start.hour,
                      start.minute,
                    );
                    end = start.add(const Duration(hours: 1));
                  }
                },
                child: Text('Wybierz datę: ${DateFormat('dd.MM.yyyy').format(start)}'),
              ),
              const SizedBox(height: 12),
              Text('Od: ${DateFormat('HH:mm').format(start)}'),
              Text('Do: ${DateFormat('HH:mm').format(end)}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Anuluj'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await _calendarService.addEvent(
                    title: titleController.text.trim().isEmpty
                        ? 'Bez tytułu'
                        : titleController.text.trim(),
                    start: start,
                    end: end,
                  );
                  Navigator.of(context).pop();
                  await _loadEvents();
                } catch (e) {
                  setState(() => _errorMessage = e.toString());
                }
              },
              child: const Text('Dodaj'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmDelete(String eventId, String title) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Usuń wydarzenie'),
        content: Text('Czy na pewno chcesz usunąć "$title"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Anuluj'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Usuń'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _calendarService.deleteEvent(eventId);
        await _loadEvents();
      } catch (e) {
        setState(() => _errorMessage = e.toString());
      }
    }
  }

  String _formatDate(String? dateTime) {
    if (dateTime == null) return '';
    final dt = DateTime.tryParse(dateTime);
    if (dt == null) return '';
    return '${dt.day}.${dt.month}.${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Google Calendar Events'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadEvents,
          ),
          IconButton(
            icon: const Icon(Icons.login),
            tooltip: 'Zaloguj z Google',
            onPressed: () async {
              try {
                await _calendarService.signIn();
                await _loadEvents();
              } catch (e) {
                setState(() => _errorMessage = e.toString());
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Dodaj wydarzenie',
            onPressed: _showAddEventDialog,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(child: Text('Błąd: $_errorMessage'))
          : _events.isEmpty
          ? const Center(child: Text('Brak wydarzeń'))
          : ListView.builder(
        itemCount: _events.length,
        itemBuilder: (context, index) {
          final event = _events[index];
          final title = event['summary'] ?? '(bez tytułu)';
          final start = event['start']?['dateTime'] ?? event['start']?['date'];
          final end = event['end']?['dateTime'] ?? event['end']?['date'];
          final id = event['id'];

          return ListTile(
            title: Text(title),
            subtitle: Text('${_formatDate(start)} - ${_formatDate(end)}'),
            onLongPress: () {
              if (id != null) {
                _confirmDelete(id, title);
              }
            },
          );
        },
      ),
    );
  }
}
