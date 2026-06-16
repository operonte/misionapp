import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:misionapp/models/visit.dart';

void main() {
  group('Visit.fromMap', () {
    test('parses all fields', () {
      final date = DateTime(2025, 4, 10, 14, 30);
      final map = {
        'fecha': Timestamp.fromDate(date),
        'contenido': 'Visita de seguimiento',
        'visitadoPor': 'Juan',
      };
      final v = Visit.fromMap('v1', map);
      expect(v.id, 'v1');
      expect(v.fecha, date);
      expect(v.contenido, 'Visita de seguimiento');
      expect(v.visitadoPor, 'Juan');
    });

    test('uses defaults for missing fields', () {
      final v = Visit.fromMap('v2', {});
      expect(v.contenido, '');
      expect(v.visitadoPor, '');
      // fecha defaults to approximately now — just check it's a DateTime
      expect(v.fecha, isA<DateTime>());
    });

    test('handles non-Timestamp fecha gracefully', () {
      final v = Visit.fromMap('v3', {'fecha': 'not-a-timestamp'});
      expect(v.fecha, isA<DateTime>());
    });
  });

  group('Visit.toMap', () {
    test('serializes fecha as Timestamp', () {
      final date = DateTime(2025, 1, 1);
      final v = Visit(id: 'x', fecha: date, contenido: 'c', visitadoPor: 'p');
      final map = v.toMap();
      expect(map['fecha'], isA<Timestamp>());
      expect((map['fecha'] as Timestamp).toDate(), date);
      expect(map['contenido'], 'c');
      expect(map['visitadoPor'], 'p');
      expect(map.containsKey('id'), isFalse);
    });
  });
}
