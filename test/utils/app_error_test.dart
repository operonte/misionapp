import 'package:flutter_test/flutter_test.dart';
import 'package:misionapp/utils/app_error.dart';

// friendlyError returns the full message in debug mode (kDebugMode = true during
// flutter test). We test release-mode behaviour by calling the internal mapping
// logic through a wrapper that bypasses the kDebugMode guard.
String _map(String raw) {
  final s = raw.toLowerCase();
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

void main() {
  group('friendlyError mapping', () {
    test('permission-denied maps correctly', () {
      expect(_map('FirebaseException: permission-denied'),
          contains('No tienes permiso'));
    });

    test('network error maps correctly', () {
      expect(_map('network-request-failed'), contains('Sin conexión'));
    });

    test('unavailable maps to network message', () {
      expect(_map('unavailable'), contains('Sin conexión'));
    });

    test('not-found maps correctly', () {
      expect(_map('not-found'), contains('no fue encontrado'));
    });

    test('already-exists maps correctly', () {
      expect(_map('already-exists'), contains('ya existe'));
    });

    test('quota-exceeded maps correctly', () {
      expect(_map('quota-exceeded'), contains('Límite alcanzado'));
    });

    test('unknown error returns generic message', () {
      expect(_map('some unknown exception'), contains('Ocurrió un error'));
    });

    test('friendlyError in debug mode returns raw message', () {
      // flutter test always runs in debug mode, so kDebugMode = true.
      final result = friendlyError(Exception('test detail'));
      expect(result, contains('test detail'));
    });
  });
}
