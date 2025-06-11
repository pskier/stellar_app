import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:http/http.dart' as http;

class AuthenticatedClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _inner;

  AuthenticatedClient(this._headers, [http.Client? inner]) : _inner = inner ?? http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _inner.send(request);
  }

  @override
  void close() {
    _inner.close();
  }
}

class GoogleCalendarService {
  static const _scopes = [calendar.CalendarApi.calendarScope];

  final GoogleSignIn _googleSignIn;

  GoogleSignInAccount? _currentUser;
  calendar.CalendarApi? _calendarApi;
  http.Client? _authClient;

  GoogleCalendarService({required String clientId})
      : _googleSignIn = GoogleSignIn(
    scopes: _scopes,
    clientId: clientId,
  );

  Future<void> signIn() async {
    _currentUser = await _googleSignIn.signIn();
    if (_currentUser == null) {
      throw Exception('Użytkownik anulował logowanie.');
    }

    await _initCalendarApi();
  }

  Future<void> _initCalendarApi() async {
    if (_currentUser == null) {
      throw Exception('Brak zalogowanego użytkownika.');
    }

    final authHeaders = await _currentUser!.authHeaders;
    if (authHeaders == null || !authHeaders.containsKey('Authorization')) {
      throw Exception('Brak nagłówków autoryzacji.');
    }

    _authClient?.close();

    _authClient = AuthenticatedClient(authHeaders);

    _calendarApi = calendar.CalendarApi(_authClient!);
  }

  Future<List<Map<String, dynamic>>> getUpcomingEvents() async {
    await _ensureSignedIn();

    final now = DateTime.now().toUtc();
    final events = await _calendarApi!.events.list(
      'primary',
      timeMin: now,
      singleEvents: true,
      orderBy: 'startTime',
    );

    return events.items?.map((e) => {
      'id': e.id,
      'summary': e.summary,
      'start': e.start?.dateTime?.toIso8601String() ?? e.start?.date,
      'end': e.end?.dateTime?.toIso8601String() ?? e.end?.date,
    }).toList() ??
        [];
  }

  Future<void> addEvent({
    required String title,
    required DateTime start,
    required DateTime end,
  }) async {
    await _ensureSignedIn();

    final event = calendar.Event()
      ..summary = title
      ..start = calendar.EventDateTime(dateTime: start.toUtc())
      ..end = calendar.EventDateTime(dateTime: end.toUtc());

    await _calendarApi!.events.insert(event, 'primary');
  }

  Future<void> deleteEvent(String eventId) async {
    await _ensureSignedIn();

    await _calendarApi!.events.delete('primary', eventId);
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();

    _currentUser = null;
    _calendarApi = null;
    _authClient?.close();
    _authClient = null;
  }

  bool get isSignedIn => _currentUser != null;

  Future<void> _ensureSignedIn() async {
    if (!isSignedIn) {
      _currentUser = await _googleSignIn.signInSilently();
      if (_currentUser == null) {
        throw Exception('Nie jesteś zalogowany.');
      }
      await _initCalendarApi();
    }
  }
}
