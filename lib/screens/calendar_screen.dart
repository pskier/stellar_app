import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:intl/intl.dart';

import '../services/google_calendar_service.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({Key? key}) : super(key: key);

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}


class _CalendarScreenState extends State<CalendarScreen> {
  final GoogleCalendarService _calendarService = GoogleCalendarService();

  bool _loading = true;
  String? _error;
  Map<DateTime, List<calendar.Event>> _eventsMap = {};

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<calendar.Event> _selectedEvents = [];

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final allEvents = await _calendarService.getEvents();

      final tempMap = <DateTime, List<calendar.Event>>{};
      for (var event in allEvents) {
        DateTime? start = event.start?.dateTime ?? event.start?.date;
        if (start == null) continue;
        final dayKey = DateTime.utc(start.year, start.month, start.day);
        tempMap.putIfAbsent(dayKey, () => []).add(event);
      }

      setState(() {
        _eventsMap = tempMap;
        _focusedDay = DateTime.now();
        _selectedDay = DateTime.utc(
          _focusedDay.year,
          _focusedDay.month,
          _focusedDay.day,
        );
        _selectedEvents = _eventsMap[_selectedDay] ?? [];
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  List<calendar.Event> _getEventsForDay(DateTime day) {
    final dayKey = DateTime.utc(day.year, day.month, day.day);
    return _eventsMap[dayKey] ?? [];
  }

  Future<void> _showAddEventDialog() async {
    final _titleController = TextEditingController();
    DateTime now = DateTime.now();

    DateTime selectedDate = DateTime(now.year, now.month, now.day);
    TimeOfDay selectedStartTime = TimeOfDay(hour: now.hour, minute: now.minute);
    TimeOfDay selectedEndTime = TimeOfDay(hour: now.hour + 1, minute: now.minute);

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          void updateDate(DateTime date) => setModalState(() {
            selectedDate = date;
          });
          void updateStart(TimeOfDay time) => setModalState(() {
            selectedStartTime = time;
          });
          void updateEnd(TimeOfDay time) => setModalState(() {
            selectedEndTime = time;
          });

          return AlertDialog(
            title: const Text('Dodaj wydarzenie'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Tytuł'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('Data: '),
                      TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) updateDate(picked);
                        },
                        child: Text(DateFormat.yMd().format(selectedDate)),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Text('Start: '),
                      TextButton(
                        onPressed: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: selectedStartTime,
                          );
                          if (picked != null) updateStart(picked);
                        },
                        child: Text(selectedStartTime.format(context)),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Text('Koniec: '),
                      TextButton(
                        onPressed: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: selectedEndTime,
                          );
                          if (picked != null) updateEnd(picked);
                        },
                        child: Text(selectedEndTime.format(context)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Anuluj'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final title = _titleController.text.trim();
                  if (title.isEmpty) return;

                  final startDateTime = DateTime(
                    selectedDate.year,
                    selectedDate.month,
                    selectedDate.day,
                    selectedStartTime.hour,
                    selectedStartTime.minute,
                  );
                  final endDateTime = DateTime(
                    selectedDate.year,
                    selectedDate.month,
                    selectedDate.day,
                    selectedEndTime.hour,
                    selectedEndTime.minute,
                  );

                  try {
                    await _calendarService.createEvent(
                      summary: title,
                      startTime: startDateTime,
                      endTime: endDateTime,
                      timeZone: "Europe/Warsaw",
                    );
                    Navigator.pop(context);
                    await _loadEvents();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Błąd dodawania: $e')),
                    );
                  }
                },
                child: const Text('Dodaj'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _deleteEvent(calendar.Event event) async {
    if (event.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Brak ID wydarzenia – nie można usunąć')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Usuń wydarzenie'),
        content: Text('Czy na pewno chcesz usunąć „${event.summary}”?'),
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

    if (confirm != true) return;

    try {
      print("Usuwam event ID: ${event.id} z kalendarza: ${event.organizer?.email ?? 'primary'}");
      await _calendarService.deleteEvent(
        event.id!,
        calendarId: 'primary',
      );
      await _loadEvents();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wydarzenie usunięte')),
      );
    } catch (e) {
      print('Błąd usuwania: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Błąd usuwania: $e')),
      );
    }
  }


  String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    final hours = local.hour.toString().padLeft(2, '0');
    final minutes = local.minute.toString().padLeft(2, '0');
    return '$hours:$minutes';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Kalendarz')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Kalendarz')),
        body: Center(child: Text('Błąd: $_error')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Kalendarz')),
      body: Column(
        children: [
          TableCalendar<calendar.Event>(
            firstDay: DateTime.utc(2000, 1, 1),
            lastDay: DateTime.utc(2100, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            eventLoader: _getEventsForDay,
            calendarFormat: CalendarFormat.month,
            startingDayOfWeek: StartingDayOfWeek.monday,
            calendarStyle: const CalendarStyle(
              markerDecoration: BoxDecoration(
                color: Colors.deepPurple,
                shape: BoxShape.circle,
              ),
            ),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
                _selectedEvents = _getEventsForDay(selectedDay);
              });
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _selectedEvents.isEmpty
                ? const Center(child: Text('Brak wydarzeń'))
                : ListView.builder(
              itemCount: _selectedEvents.length,
              itemBuilder: (context, index) {
                final event = _selectedEvents[index];
                final start = event.start?.dateTime ?? event.start?.date;
                final end = event.end?.dateTime ?? event.end?.date;
                final timeRange = (start != null && end != null)
                    ? ' (${_formatTime(start)} – ${_formatTime(end)})'
                    : '';
                return ListTile(
                  leading: const Icon(Icons.event),
                  title: Text(event.summary ?? 'Brak tytułu'),
                  subtitle: Text(timeRange),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteEvent(event),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddEventDialog,
        child: const Icon(Icons.add),
        tooltip: 'Dodaj wydarzenie',
      ),
    );
  }
}
