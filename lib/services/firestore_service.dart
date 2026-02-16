import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/user_profile.dart';
import '../models/person.dart';
import '../models/visit.dart';

/// ID de la base Firestore que creaste (plan Blaze). No usar "(default)".
const String _databaseId = 'misionapp';

class FirestoreService {
  late final FirebaseFirestore _firestore = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: _databaseId,
  );

  FirestoreService() {
    _firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  // ---------- User profile ----------
  static const String _usersCol = 'users';

  Future<UserProfile?> getUserProfile(String uid) async {
    final doc = await _firestore.collection(_usersCol).doc(uid).get();
    if (doc.data() == null) return null;
    return UserProfile.fromMap(uid, doc.data()!);
  }

  Future<void> setUserProfile(UserProfile profile) async {
    await _firestore.collection(_usersCol).doc(profile.uid).set(profile.toMap());
  }

  Stream<UserProfile?> userProfileStream(String uid) {
    return _firestore.collection(_usersCol).doc(uid).snapshots().map((doc) {
      if (doc.data() == null) return null;
      return UserProfile.fromMap(uid, doc.data()!);
    });
  }

  // ---------- Persons ----------
  static const String _personsCol = 'persons';

  /// Lista personas visibles para el usuario: su grupo o todas si es ADMINISTRADOR.
  Stream<List<Person>> personsStream(String userGrupo) {
    if (userGrupo == 'ADMINISTRADOR') {
      return _firestore
          .collection(_personsCol)
          .orderBy('nombreApellidos')
          .snapshots()
          .map((snap) => snap.docs
              .map((d) => Person.fromMap(d.id, d.data()))
              .toList());
    }
    return _firestore
        .collection(_personsCol)
        .where('grupo', isEqualTo: userGrupo)
        .orderBy('nombreApellidos')
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Person.fromMap(d.id, d.data())).toList());
  }

  Future<Person?> getPerson(String personId) async {
    final doc = await _firestore.collection(_personsCol).doc(personId).get();
    if (doc.data() == null) return null;
    return Person.fromMap(doc.id, doc.data()!);
  }

  Future<String> addPerson(Person person) async {
    final ref = await _firestore.collection(_personsCol).add(person.toMap());
    return ref.id;
  }

  Future<void> updatePerson(Person person) async {
    await _firestore
        .collection(_personsCol)
        .doc(person.id)
        .update(person.toMap());
  }

  Future<void> deletePerson(String personId) async {
    final batch = _firestore.batch();
    final visitsRef =
        _firestore.collection(_personsCol).doc(personId).collection('visits');
    final visitsSnap = await visitsRef.get();
    for (final d in visitsSnap.docs) batch.delete(d.reference);
    batch.delete(_firestore.collection(_personsCol).doc(personId));
    await batch.commit();
  }

  // ---------- Visits (subcollection) ----------
  Stream<List<Visit>> visitsStream(String personId) {
    return _firestore
        .collection(_personsCol)
        .doc(personId)
        .collection('visits')
        .orderBy('fecha', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => Visit.fromMap(d.id, d.data()))
            .toList());
  }

  Future<DateTime?> getLastVisitDate(String personId) async {
    final snap = await _firestore
        .collection(_personsCol)
        .doc(personId)
        .collection('visits')
        .orderBy('fecha', descending: true)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    final ts = snap.docs.first.data()['fecha'];
    return ts is Timestamp ? ts.toDate() : null;
  }

  Future<void> addVisit(String personId, Visit visit) async {
    await _firestore
        .collection(_personsCol)
        .doc(personId)
        .collection('visits')
        .add(visit.toMap());
  }

  // ---------- Export (admin): all persons with visits ----------
  Future<List<Person>> getAllPersonsForExport() async {
    final snap =
        await _firestore.collection(_personsCol).orderBy('nombreApellidos').get();
    return snap.docs.map((d) => Person.fromMap(d.id, d.data())).toList();
  }

  Future<List<Visit>> getVisitsForPerson(String personId) async {
    final snap = await _firestore
        .collection(_personsCol)
        .doc(personId)
        .collection('visits')
        .orderBy('fecha', descending: false)
        .get();
    return snap.docs.map((d) => Visit.fromMap(d.id, d.data())).toList();
  }
}
