import 'package:cloud_firestore/cloud_firestore.dart';

/// Visita registrada (subcolección persons/{personId}/visits/{visitId}).
class Visit {
  final String id;
  final DateTime fecha;
  final String contenido;
  final String visitadoPor;

  const Visit({
    required this.id,
    required this.fecha,
    required this.contenido,
    required this.visitadoPor,
  });

  Map<String, dynamic> toMap() => {
        'fecha': Timestamp.fromDate(fecha),
        'contenido': contenido,
        'visitadoPor': visitadoPor,
      };

  factory Visit.fromMap(String id, Map<String, dynamic> map) {
    final ts = map['fecha'];
    return Visit(
      id: id,
      fecha: ts is Timestamp ? ts.toDate() : DateTime.now(),
      contenido: map['contenido'] as String? ?? '',
      visitadoPor: map['visitadoPor'] as String? ?? '',
    );
  }
}
