import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;

class GoogleCalendarService {
  // Define scopes required for Google Calendar API
  static const _scopes = [calendar.CalendarApi.calendarScope];

  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: _scopes);

  /// Sign in with Google and return the authenticated user.
  Future<GoogleSignInAccount?> signIn() async {
    try {
      // Check if already signed in
      var account = _googleSignIn.currentUser;
      if (kIsWeb) {
        // En web, sovint cal forçar signInSilently primer per recuperar
        // l'estat d'autenticació complet, fins i tot si sembla que user no és null.
        account = await _googleSignIn.signInSilently();
      } else {
        account ??= await _googleSignIn.signInSilently();
      }

      // Si no hi ha user, forcem el popup
      account ??= await _googleSignIn.signIn();

      // IMPORTME: En Web, verifiquem si tenim els permisos (scopes)
      if (kIsWeb && account != null) {
        final canAccess = await _googleSignIn.requestScopes(_scopes);
        if (!canAccess) {
          debugPrint('L\'usuari ha denegat els permisos de calendari.');
          return null;
        }
      }

      return account;
    } catch (error) {
      debugPrint('Error signing in with Google: $error');
      return null;
    }
  }

  /// Create a calendar event with Google Meet link.
  /// Returns a map with 'eventId' and 'meetLink' if successful.
  Future<Map<String, String>?> createMeetEvent({
    required String title,
    required String description,
    required DateTime startTime,
    required DateTime endTime,
    List<String> attendeeEmails = const [],
  }) async {
    try {
      final googleUser = await signIn();
      if (googleUser == null) {
        debugPrint('User not signed in via Google.');
        return null; // User cancelled or error
      }

      // Get authenticated HTTP client
      final httpClient = await _googleSignIn.authenticatedClient();
      if (httpClient == null) {
        debugPrint('Failed to get authenticated client.');
        return null;
      }

      final calendarApi = calendar.CalendarApi(httpClient);

      // Create Event object
      calendar.Event event = calendar.Event(
        summary: title,
        description: description,
        start: calendar.EventDateTime(
          dateTime: startTime.toUtc(),
          timeZone: 'UTC', // Best practice to use UTC
        ),
        end: calendar.EventDateTime(
          dateTime: endTime.toUtc(),
          timeZone: 'UTC', // Best practice to use UTC
        ),
        attendees: attendeeEmails
            .map((email) => calendar.EventAttendee(email: email))
            .toList(),
        conferenceData: calendar.ConferenceData(
          createRequest: calendar.CreateConferenceRequest(
            requestId:
                "${DateTime.now().millisecondsSinceEpoch}-${title.hashCode}", // Unique request ID
            conferenceSolutionKey: calendar.ConferenceSolutionKey(
              type: "hangoutsMeet",
            ),
          ),
        ),
      );

      // Insert event into primary calendar
      // conferenceDataVersion: 1 is REQUIRED to create Meet links
      final createdEvent = await calendarApi.events.insert(
        event,
        'primary',
        conferenceDataVersion: 1,
      );

      if (createdEvent.status == 'confirmed') {
        String? meetLink = createdEvent.hangoutLink;
        String? eventId = createdEvent.id;

        // Sometimes hangoutLink might be nested in conferenceData
        if (meetLink == null && createdEvent.conferenceData != null) {
          meetLink = createdEvent.conferenceData!.entryPoints
              ?.firstWhere(
                (element) => element.entryPointType == 'video',
                orElse: () => calendar.EntryPoint(),
              )
              .uri;
        }

        debugPrint('Event created: $eventId, Meet: $meetLink');
        return {
          if (eventId != null) 'eventId': eventId,
          if (meetLink != null) 'meetLink': meetLink,
        };
      } else {
        debugPrint('Event creation status: ${createdEvent.status}');
        return null;
      }
    } catch (e) {
      debugPrint('Error creating Google Calendar event: $e');
      return null;
    }
  }

  /// Update a calendar event description.
  Future<bool> updateEventDescription({
    required String eventId,
    required String description,
  }) async {
    try {
      final googleUser = await signIn();
      if (googleUser == null) return false;

      final httpClient = await _googleSignIn.authenticatedClient();
      if (httpClient == null) return false;

      final calendarApi = calendar.CalendarApi(httpClient);

      final event = await calendarApi.events.get('primary', eventId);
      event.description = description;

      await calendarApi.events.update(event, 'primary', eventId);
      return true;
    } catch (e) {
      debugPrint('Error updating Google Calendar event: $e');
      return false;
    }
  }
}
