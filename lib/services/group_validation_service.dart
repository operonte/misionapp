import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../app_config.dart';

class GroupValidationService {
  static const String _configCol = 'config';
  static const String _groupsDoc = 'allowed_groups';

  late final FirebaseFirestore _firestore = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'misionapp',
  );

  /// Returns allowed groups from Firestore config. Falls back to the local
  /// [missionGroups] constant so non-admin users (who can't write config)
  /// always get a valid list without creating a document.
  Future<List<String>> getAllAllowedGroups() async {
    try {
      final doc =
          await _firestore.collection(_configCol).doc(_groupsDoc).get();
      if (!doc.exists || doc.data() == null) return missionGroups;

      final groups = doc.data()!['groups'];
      if (groups is! List || groups.isEmpty) return missionGroups;
      return groups.map((e) => e.toString()).toList();
    } catch (_) {
      return missionGroups;
    }
  }

  Future<bool> validateGroupName(String name) async {
    if (name.trim().isEmpty) return false;
    final allowed = await getAllAllowedGroups();
    return allowed.contains(name.trim().toUpperCase());
  }

  /// Admin-only: adds a new group to Firestore config.
  /// Firestore rules enforce that only ADMINISTRADOR can write config.
  Future<void> addGroup(String groupName) async {
    final current = await getAllAllowedGroups();
    final normalized = groupName.trim().toUpperCase();
    if (current.contains(normalized)) return;
    await _firestore.collection(_configCol).doc(_groupsDoc).set({
      'groups': [...current, normalized],
      'updated_at': Timestamp.now(),
    });
  }
}
