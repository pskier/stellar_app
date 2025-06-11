import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:http/http.dart' as http;

class GoogleCalendarService {
  static const _calendarScope = calendar.CalendarApi.calendarScope;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: <String>[
      'https://www.googleapis.com/auth/calendar',
      'https://www.googleapis.com/auth/calendar.events',
      'email',
    ],
  );

  AuthClient? _authClient;

  Future<void> _ensureLoggedIn() async {
    if (_authClient != null) return;

    await _googleSignIn.disconnect();

    final account = await _googleSignIn.signIn();
    if (account == null) throw Exception('Użytkownik nie zalogował się.');

    final auth = await account.authentication;
    final accessToken = auth.accessToken;
    if (accessToken == null) throw Exception('Brak accessToken z GoogleSignIn.');

    final allScopes = _googleSignIn.scopes;

    final expiryUtc = DateTime.now().toUtc().add(const Duration(hours: 1));
    final credentials = AccessCredentials(
      AccessToken('Bearer', accessToken, expiryUtc),
      null,
      allScopes,
    );

    _authClient = authenticatedClient(
      http.Client(),
      credentials,
    );
  }

  Future<List<calendar.Event>> getEvents() async {
    await _ensureLoggedIn();
    final calendarApi = calendar.CalendarApi(_authClient!);
    final events = await calendarApi.events.list(
      'primary',
      maxResults: 100,
      singleEvents: true,
      orderBy: 'startTime',
      timeMin: DateTime.now().toUtc(),
    );
    return events.items ?? [];
  }

  Future<void> createEvent({
    required String summary,
    required DateTime startTime,
    required DateTime endTime,
    String timeZone = "Europe/Warsaw",
  }) async {
    await _ensureLoggedIn();
    final calendarApi = calendar.CalendarApi(_authClient!);
    final event = calendar.Event()
      ..summary = summary
      ..start = (calendar.EventDateTime()
        ..dateTime = startTime
        ..timeZone = timeZone)
      ..end = (calendar.EventDateTime()
        ..dateTime = endTime
        ..timeZone = timeZone);
    await calendarApi.events.insert(event, 'primary');
  }

  Future<void> deleteEvent(
      String eventId, {
        required String calendarId,
      }) async {
    await _ensureLoggedIn();
    final calendarApi = calendar.CalendarApi(_authClient!);
    try {
      print('→ deleteEvent: eventId="$eventId", calendarId="$calendarId"');
      await calendarApi.events.delete(eventId, calendarId);
      print('Usunięto event o ID="$eventId" z calendarId="$calendarId"');
    } on calendar.DetailedApiRequestError catch (e) {
      print('DetailedApiRequestError przy usuwaniu:');
      print('   status: ${e.status}');
      print('   message: ${e.message}');
      print('   errors: ${e.errors}');
      rethrow;
    } catch (e) {
      print('Inny wyjątek przy usuwaniu: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _authClient?.close();
    _authClient = null;
  }

  Future<void> printAllCalendars() async {
    await _ensureLoggedIn();
    final calendarApi = calendar.CalendarApi(_authClient!);
    final calendarList = await calendarApi.calendarList.list();
    print('Lista kalendarzy:');
    for (var cal in calendarList.items ?? []) {
      print(' - id: ${cal.id}, nazwa: ${cal.summary}');
    }
  }
}
