import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:misionapp/models/person.dart';

void main() {
  group('Person.fromMap', () {
    test('maps all fields correctly', () {
      final now = DateTime(2025, 6, 1);
      final map = {
        'grupo': 'JORGEALES',
        'nombreApellidos': 'Juan Pérez',
        'direccion': 'Calle 1',
        'telefono': '123',
        'edad': '30',
        'genero': 'Hombre',
        'aQueSeDedica': 'Carpintero',
        'esCristianoOAsisteIglesia': 'Sí',
        'quiereRecibirVisitas': 'Sí',
        'vicios': ['Alcohol'],
        'enfermedadMental': 'Sano',
        'enfermedadCronica': 'Sano',
        'nivelComplejidad': 3,
        'comentarios': 'Notas',
        'ultimaVisita': Timestamp.fromDate(now),
        'totalVisitas': 5,
      };
      final p = Person.fromMap('abc', map);

      expect(p.id, 'abc');
      expect(p.grupo, 'JORGEALES');
      expect(p.nombreApellidos, 'Juan Pérez');
      expect(p.nivelComplejidad, 3);
      expect(p.vicios, ['Alcohol']);
      expect(p.ultimaVisita, now);
      expect(p.totalVisitas, 5);
    });

    test('uses defaults for missing fields', () {
      final p = Person.fromMap('x', {});
      expect(p.grupo, 'JORGEALES');
      expect(p.nombreApellidos, '');
      expect(p.vicios, isEmpty);
      expect(p.nivelComplejidad, 1);
      expect(p.ultimaVisita, isNull);
      expect(p.totalVisitas, 0);
    });

    test('clamps negative totalVisitas to 0', () {
      final p = Person.fromMap('x', {'totalVisitas': -3});
      expect(p.totalVisitas, 0);
    });

    test('handles vicios as non-list gracefully', () {
      final p = Person.fromMap('x', {'vicios': 'Alcohol'});
      expect(p.vicios, isEmpty);
    });
  });

  group('Person.toMap', () {
    test('does not include totalVisitas (managed via FieldValue.increment)', () {
      final p = Person(
        id: '1',
        grupo: 'JORGEALES',
        nombreApellidos: 'A',
        direccion: '',
        telefono: '',
        edad: '',
        genero: 'Hombre',
        aQueSeDedica: '',
        esCristianoOAsisteIglesia: 'No',
        quiereRecibirVisitas: 'Sí',
        vicios: [],
        enfermedadMental: 'Sano',
        enfermedadCronica: 'Sano',
        nivelComplejidad: 1,
        comentarios: '',
        totalVisitas: 7,
      );
      expect(p.toMap().containsKey('totalVisitas'), isFalse);
    });

    test('includes ultimaVisita as Timestamp when set', () {
      final date = DateTime(2025, 3, 15);
      final p = Person(
        id: '1',
        grupo: 'G',
        nombreApellidos: 'B',
        direccion: '',
        telefono: '',
        edad: '',
        genero: '',
        aQueSeDedica: '',
        esCristianoOAsisteIglesia: '',
        quiereRecibirVisitas: '',
        vicios: [],
        enfermedadMental: '',
        enfermedadCronica: '',
        nivelComplejidad: 1,
        comentarios: '',
        ultimaVisita: date,
      );
      final map = p.toMap();
      expect(map['ultimaVisita'], isA<Timestamp>());
      expect((map['ultimaVisita'] as Timestamp).toDate(), date);
    });

    test('omits ultimaVisita when null', () {
      final p = Person(
        id: '1', grupo: 'G', nombreApellidos: 'C',
        direccion: '', telefono: '', edad: '', genero: '',
        aQueSeDedica: '', esCristianoOAsisteIglesia: '',
        quiereRecibirVisitas: '', vicios: [], enfermedadMental: '',
        enfermedadCronica: '', nivelComplejidad: 1, comentarios: '',
      );
      expect(p.toMap().containsKey('ultimaVisita'), isFalse);
    });
  });

  group('Person.copyWith', () {
    final base = Person(
      id: '1', grupo: 'G', nombreApellidos: 'A',
      direccion: '', telefono: '', edad: '', genero: 'Hombre',
      aQueSeDedica: '', esCristianoOAsisteIglesia: 'No',
      quiereRecibirVisitas: 'Sí', vicios: [], enfermedadMental: 'Sano',
      enfermedadCronica: 'Sano', nivelComplejidad: 1, comentarios: '',
      totalVisitas: 2,
    );

    test('changes only the specified field', () {
      final updated = base.copyWith(nombreApellidos: 'Nuevo Nombre');
      expect(updated.nombreApellidos, 'Nuevo Nombre');
      expect(updated.grupo, base.grupo);
      expect(updated.totalVisitas, base.totalVisitas);
    });
  });
}
