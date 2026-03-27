import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class GroupValidationService {
  static const String _configCol = 'config';
  static const String _groupsDoc = 'allowed_groups';
  
  late final FirebaseFirestore _firestore = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'misionapp',
  );

  /// Obtiene la lista de grupos permitidos desde Firestore
  Future<List<String>> getAllAllowedGroups() async {
    try {
      final doc = await _firestore.collection(_configCol).doc(_groupsDoc).get();
      if (!doc.exists) {
        // Si no existe, crear con grupos por defecto
        await _createDefaultGroups();
        return ['JORGEALES', 'NELSONPEREIRA', 'IASDBUERAS', 'ADMINISTRADOR'];
      }
      
      final data = doc.data();
      if (data == null || data['groups'] == null) {
        return ['JORGEALES', 'NELSONPEREIRA', 'IASDBUERAS', 'ADMINISTRADOR'];
      }
      
      final groups = data['groups'] as List;
      return groups.map((e) => e.toString()).toList();
    } catch (e) {
      // En caso de error, retornar grupos por defecto
      return ['JORGEALES', 'NELSONPEREIRA', 'IASDBUERAS', 'ADMINISTRADOR'];
    }
  }

  /// Valida si un nombre de grupo es permitido
  Future<bool> validateGroupName(String name) async {
    if (name.trim().isEmpty) return false;
    
    final allowedGroups = await getAllAllowedGroups();
    return allowedGroups.contains(name.trim().toUpperCase());
  }

  /// Crea el documento de configuración con grupos por defecto
  Future<void> _createDefaultGroups() async {
    await _firestore.collection(_configCol).doc(_groupsDoc).set({
      'groups': ['JORGEALES', 'NELSONPEREIRA', 'IASDBUERAS', 'ADMINISTRADOR'],
      'updated_at': Timestamp.now(),
    });
  }

  /// Agrega un nuevo grupo a la lista (solo para administradores)
  Future<void> addGroup(String groupName) async {
    final allowedGroups = await getAllAllowedGroups();
    final normalizedName = groupName.trim().toUpperCase();
    
    if (!allowedGroups.contains(normalizedName)) {
      allowedGroups.add(normalizedName);
      await _firestore.collection(_configCol).doc(_groupsDoc).set({
        'groups': allowedGroups,
        'updated_at': Timestamp.now(),
      });
    }
  }
}
