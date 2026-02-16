/// Persona inscrita (colección persons). 12 datos + grupo.
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
  });

  Map<String, dynamic> toMap() => {
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

  factory Person.fromMap(String id, Map<String, dynamic> map) {
    final viciosList = map['vicios'];
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
      vicios: viciosList is List ? (viciosList).map((e) => e.toString()).toList() : [],
      enfermedadMental: map['enfermedadMental'] as String? ?? '',
      enfermedadCronica: map['enfermedadCronica'] as String? ?? '',
      nivelComplejidad: (map['nivelComplejidad'] as num?)?.toInt() ?? 1,
      comentarios: map['comentarios'] as String? ?? '',
    );
  }

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
    );
  }
}
