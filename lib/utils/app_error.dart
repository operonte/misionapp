import 'package:flutter/foundation.dart';

/// Returns a user-friendly error message. In debug mode returns the full error
/// so developers see the real cause. In release mode, maps Firebase/network
/// codes to safe generic messages (no internal details exposed — OWASP A09).
String friendlyError(Object e) {
  if (kDebugMode) return e.toString();
  final s = e.toString().toLowerCase();
  if (s.contains('permission-denied') || s.contains('permission_denied')) {
    return 'No tienes permiso para realizar esta acción.';
  }
  if (s.contains('unavailable') || s.contains('network-request-failed') ||
      s.contains('network')) {
    return 'Sin conexión. Verifica tu red e inténtalo de nuevo.';
  }
  if (s.contains('not-found') || s.contains('not_found')) {
    return 'El registro no fue encontrado.';
  }
  if (s.contains('already-exists')) {
    return 'El registro ya existe.';
  }
  if (s.contains('quota-exceeded') || s.contains('resource-exhausted')) {
    return 'Límite alcanzado. Inténtalo más tarde.';
  }
  return 'Ocurrió un error. Inténtalo de nuevo.';
}

/// Logs to console only in debug builds. Never call with PII in production
/// (OWASP A09 — avoid leaking sensitive data to logs).
void debugLog(String message, [Object? error, StackTrace? stackTrace]) {
  if (!kDebugMode) return;
  debugPrint(error != null ? '$message: $error' : message);
  if (stackTrace != null) debugPrint('$stackTrace');
}
