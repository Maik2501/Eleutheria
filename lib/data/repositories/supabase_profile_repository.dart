import 'dart:math' as math;

import 'package:supabase_flutter/supabase_flutter.dart';

/// Talks to the Supabase `profiles` table — the global, unique display-name
/// registry for anonymous users.
class SupabaseProfileRepository {
  SupabaseProfileRepository(this._client);

  final SupabaseClient _client;

  String? get _uid => _client.auth.currentUser?.id;

  /// Fetches the own profile row. Returns `null` when no row exists yet
  /// (first-time user) or when not authenticated.
  Future<RemoteProfile?> fetchMine() async {
    final uid = _uid;
    if (uid == null) return null;
    final row = await _client
        .from('profiles')
        .select()
        .eq('id', uid)
        .maybeSingle();
    if (row == null) return null;
    return RemoteProfile.fromRow(row);
  }

  /// Reserves or updates the display name for the current user.
  ///
  /// Idempotent: inserts on first call, updates on later calls. Server-side
  /// uniqueness is enforced through the `profiles.display_name` unique index.
  Future<ReservationResult> reserve(String displayName) async {
    final uid = _uid;
    if (uid == null) return const ReservationOffline();

    final trimmed = displayName.trim();
    final clientValidation = _validate(trimmed);
    if (clientValidation != null) return ReservationInvalid(clientValidation);

    try {
      final exists = await fetchMine();
      if (exists == null) {
        await _client.from('profiles').insert({
          'id': uid,
          'display_name': trimmed,
        });
      } else {
        await _client
            .from('profiles')
            .update({'display_name': trimmed})
            .eq('id', uid);
      }
      return ReservationOk(displayName: trimmed);
    } on PostgrestException catch (e) {
      // 23505 = unique_violation — display_name already taken.
      // 23514 = check_violation — fell through client validation somehow.
      if (e.code == '23505') {
        return ReservationTaken(suggestions: _suggest(trimmed));
      }
      if (e.code == '23514') {
        return const ReservationInvalid('Name enthält unerlaubte Zeichen.');
      }
      return ReservationError(e.message);
    } catch (e) {
      return ReservationError(e.toString());
    }
  }

  /// Löscht das Konto des Callers vollständig (RPC `delete_account`,
  /// Migration 0011): auth.users-Row weg, profiles/scores/duel_ratings
  /// cascaden, Duelle werden serverseitig aufgeräumt, Feedback bleibt
  /// anonymisiert. Gibt `false` zurück, wenn der Call fehlschlägt — der
  /// lokale Zustand darf dann NICHT zurückgesetzt werden.
  Future<bool> deleteAccount() async {
    if (_uid == null) return false;
    try {
      await _client.rpc<void>('delete_account');
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Client-side validation mirroring the SQL check-constraints from
  /// migration 0002.  Returns an error message or `null` when valid.
  static String? _validate(String name) {
    if (name.length < 2) return 'Mindestens 2 Zeichen.';
    if (name.length > 24) return 'Höchstens 24 Zeichen.';
    final regex = RegExp(r'^[a-zA-Z0-9 _.\-]+$');
    if (!regex.hasMatch(name)) {
      return 'Erlaubt: Buchstaben, Zahlen, Leerzeichen, _ . -';
    }
    return null;
  }

  static List<String> _suggest(String base) {
    final rnd = math.Random();
    return List.generate(3, (_) => '$base${rnd.nextInt(900) + 100}');
  }
}

class RemoteProfile {
  const RemoteProfile({
    required this.id,
    required this.displayName,
    required this.createdAt,
  });

  final String id;
  final String displayName;
  final DateTime createdAt;

  factory RemoteProfile.fromRow(Map<String, dynamic> r) => RemoteProfile(
        id: r['id'] as String,
        displayName: r['display_name'] as String,
        createdAt: DateTime.parse(r['created_at'] as String),
      );
}

sealed class ReservationResult {
  const ReservationResult();
}

class ReservationOk extends ReservationResult {
  const ReservationOk({required this.displayName});
  final String displayName;
}

class ReservationTaken extends ReservationResult {
  const ReservationTaken({required this.suggestions});
  final List<String> suggestions;
}

class ReservationInvalid extends ReservationResult {
  const ReservationInvalid(this.reason);
  final String reason;
}

class ReservationOffline extends ReservationResult {
  const ReservationOffline();
}

class ReservationError extends ReservationResult {
  const ReservationError(this.message);
  final String message;
}
