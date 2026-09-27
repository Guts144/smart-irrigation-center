import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Lets the network layer tell the auth feature that the session is gone
/// (refresh token expired or rejected) without importing it.
class SessionEvents {
  final _expired = StreamController<void>.broadcast();

  Stream<void> get expired => _expired.stream;

  void notifyExpired() => _expired.add(null);

  void dispose() => _expired.close();
}

final sessionEventsProvider = Provider<SessionEvents>((ref) {
  final events = SessionEvents();
  ref.onDispose(events.dispose);
  return events;
});
