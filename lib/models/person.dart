import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';

/// Persona inscrita (colección persons).
/// ultimaVisita y totalVisitas son denormalizados desde la subcolección visits.
class Person {
  final String id;
  final String grupo;
  final String nombreApellidos;
  final String direccion;
  final String telefono;
  final String edad;
  final String genero;
  final String aQueSeDedica;
  final String esCristianoOAsisteIglesia;
  final String quiereRecibirVisitas;
  final List<String> vicios;
  final String enfermedadMental;
  final String enfermedadCronica;
  final int nivelComplejidad;
  final String comentarios;
  final DateTime? ultimaVisita;
  final int totalVisitas;
  // Audit trail — written by FirestoreService, never in toMap().
  final String? creadoPor;
  final DateTime? creadoEn;
  final String? modificadoPor;
  final DateTime? fechaModificacion;

  const Person({
    required this.id,
    required this.grupo,
    required this.nombreApellidos,
    required this.direccion,
    required this.telefono,
    required this.edad,
    required this.genero,
    required this.aQueSeDedica,
    required this.esCristianoOAsisteIglesia,
    required this.quiereRecibirVisitas,
    required this.vicios,
    required this.enfermedadMental,
    required this.enfermedadCronica,
    required this.nivelComplejidad,
    required this.comentarios,
    this.ultimaVisita,
    this.totalVisitas = 0,
    this.creadoPor,
    this.creadoEn,
    this.modificadoPor,
    this.fechaModificacion,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'grupo': grupo,
      'nombreApellidos': nombreApellidos,
      'direccion': direccion,
      'telefono': telefono,
      'edad': edad,
      'genero': genero,
      'aQueSeDedica': aQueSeDedica,
      'esCristianoOAsisteIglesia': esCristianoOAsisteIglesia,
      'quiereRecibirVisitas': quiereRecibirVisitas,
      'vicios': vicios,
      'enfermedadMental': enfermedadMental,
      'enfermedadCronica': enfermedadCronica,
      'nivelComplejidad': nivelComplejidad,
      'comentarios': comentarios,
    };
    if (ultimaVisita != null) {
      map['ultimaVisita'] = Timestamp.fromDate(ultimaVisita!);
    }
    return map;
    // totalVisitas is excluded from toMap — always updated via FieldValue.increment.
  }

  factory Person.fromMap(String id, Map<String, dynamic> map) {
    final viciosList = map['vicios'];
    final ts = map['ultimaVisita'];
    return Person(
      id: id,
      grupo: map['grupo'] as String? ?? 'JORGEALES',
      nombreApellidos: map['nombreApellidos'] as String? ?? '',
      direccion: map['direccion'] as String? ?? '',
      telefono: map['telefono'] as String? ?? '',
      edad: map['edad'] as String? ?? '',
      genero: map['genero'] as String? ?? '',
      aQueSeDedica: map['aQueSeDedica'] as String? ?? '',
      esCristianoOAsisteIglesia: map['esCristianoOAsisteIglesia'] as String? ?? '',
      quiereRecibirVisitas: map['quiereRecibirVisitas'] as String? ?? '',
      vicios: viciosList is List ? viciosList.map((e) => e.toString()).toList() : [],
      enfermedadMental: map['enfermedadMental'] as String? ?? '',
      enfermedadCronica: map['enfermedadCronica'] as String? ?? '',
      nivelComplejidad: (map['nivelComplejidad'] as num?)?.toInt() ?? 1,
      comentarios: map['comentarios'] as String? ?? '',
      ultimaVisita: ts is Timestamp ? ts.toDate() : null,
      totalVisitas: math.max(0, (map['totalVisitas'] as num?)?.toInt() ?? 0),
      creadoPor: map['creadoPor'] as String?,
      creadoEn: _tsToDate(map['creadoEn']),
      modificadoPor: map['modificadoPor'] as String?,
      fechaModificacion: _tsToDate(map['fechaModificacion']),
    );
  }

  static DateTime? _tsToDate(Object? v) =>
      v is Timestamp ? v.toDate() : null;

  Person copyWith({
    String? id,
    String? grupo,
    String? nombreApellidos,
    String? direccion,
    String? telefono,
    String? edad,
    String? genero,
    String? aQueSeDedica,
    String? esCristianoOAsisteIglesia,
    String? quiereRecibirVisitas,
    List<String>? vicios,
    String? enfermedadMental,
    String? enfermedadCronica,
    int? nivelComplejidad,
    String? comentarios,
    DateTime? ultimaVisita,
    int? totalVisitas,
    String? creadoPor,
    DateTime? creadoEn,
    String? modificadoPor,
    DateTime? fechaModificacion,
  }) {
    return Person(
      id: id ?? this.id,
      grupo: grupo ?? this.grupo,
      nombreApellidos: nombreApellidos ?? this.nombreApellidos,
      direccion: direccion ?? this.direccion,
      telefono: telefono ?? this.telefono,
      edad: edad ?? this.edad,
      genero: genero ?? this.genero,
      aQueSeDedica: aQueSeDedica ?? this.aQueSeDedica,
      esCristianoOAsisteIglesia:
          esCristianoOAsisteIglesia ?? this.esCristianoOAsisteIglesia,
      quiereRecibirVisitas: quiereRecibirVisitas ?? this.quiereRecibirVisitas,
      vicios: vicios ?? this.vicios,
      enfermedadMental: enfermedadMental ?? this.enfermedadMental,
      enfermedadCronica: enfermedadCronica ?? this.enfermedadCronica,
      nivelComplejidad: nivelComplejidad ?? this.nivelComplejidad,
      comentarios: comentarios ?? this.comentarios,
      ultimaVisita: ultimaVisita ?? this.ultimaVisita,
      totalVisitas: totalVisitas ?? this.totalVisitas,
      creadoPor: creadoPor ?? this.creadoPor,
      creadoEn: creadoEn ?? this.creadoEn,
      modificadoPor: modificadoPor ?? this.modificadoPor,
      fechaModificacion: fechaModificacion ?? this.fechaModificacion,
    );
  }
}
