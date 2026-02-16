/// Perfil del misionero en Firestore (users/{uid}).
class UserProfile {
  final String uid;
  final String nombre;
  final String apellido;
  final String grupo;

  const UserProfile({
    required this.uid,
    required this.nombre,
    required this.apellido,
    required this.grupo,
  });

  String get displayName => '$nombre $apellido'.trim();
  bool get isAdmin => grupo == 'ADMINISTRADOR';

  Map<String, dynamic> toMap() => {
        'nombre': nombre,
        'apellido': apellido,
        'grupo': grupo,
      };

  factory UserProfile.fromMap(String uid, Map<String, dynamic> map) {
    return UserProfile(
      uid: uid,
      nombre: map['nombre'] as String? ?? '',
      apellido: map['apellido'] as String? ?? '',
      grupo: map['grupo'] as String? ?? 'JORGEALES',
    );
  }

  UserProfile copyWith({
    String? nombre,
    String? apellido,
    String? grupo,
  }) {
    return UserProfile(
      uid: uid,
      nombre: nombre ?? this.nombre,
      apellido: apellido ?? this.apellido,
      grupo: grupo ?? this.grupo,
    );
  }
}
