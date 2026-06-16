import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/user_profile.dart';
import '../models/person.dart';
import '../models/visit.dart';

const String _databaseId = 'misionapp';

class FirestoreService {
  static FirestoreService? _instance;

  factory FirestoreService() {
    _instance ??= FirestoreService._internal();
    return _instance!;
  }

  FirestoreService._internal() {
    _firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  late final FirebaseFirestore _firestore = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: _databaseId,
  );

  // ── User profile ───────────────────────────────────────────────────────────

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

  // ── Persons ────────────────────────────────────────────────────────────────

  static const String _personsCol = 'persons';

  /// Forces a server-side fetch, updating the local cache so the live
  /// [personsStream] emits fresh data after a pull-to-refresh.
  Future<void> refreshPersons(String userGrupo) async {
    try {
      if (userGrupo == 'ADMINISTRADOR') {
        await _firestore
            .collection(_personsCol)
            .get(const GetOptions(source: Source.server));
      } else {
        await _firestore
            .collection(_personsCol)
            .where('grupo', isEqualTo: userGrupo)
            .get(const GetOptions(source: Source.server));
      }
    } catch (_) {} // fail silently when offline
  }

  Stream<List<Person>> personsStream(String userGrupo) {
    if (userGrupo == 'ADMINISTRADOR') {
      return _firestore
          .collection(_personsCol)
          .orderBy('nombreApellidos')
          .snapshots()
          .map((snap) =>
              snap.docs.map((d) => Person.fromMap(d.id, d.data())).toList());
    }
    return _firestore
        .collection(_personsCol)
        .where('grupo', isEqualTo: userGrupo)
        .orderBy('nombreApellidos')
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Person.fromMap(d.id, d.data())).toList());
  }

  /// Real-time stream for a single person document. Used in PersonDetailScreen
  /// to avoid stale data after edits made from another session.
  Stream<Person?> personStream(String personId) {
    return _firestore
        .collection(_personsCol)
        .doc(personId)
        .snapshots()
        .map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return Person.fromMap(doc.id, doc.data()!);
    });
  }

  Future<Person?> getPerson(String personId) async {
    final doc = await _firestore.collection(_personsCol).doc(personId).get();
    if (doc.data() == null) return null;
    return Person.fromMap(doc.id, doc.data()!);
  }

  Future<String> addPerson(Person person, {String? createdBy}) async {
    final map = person.toMap();
    if (createdBy != null && createdBy.isNotEmpty) {
      final now = FieldValue.serverTimestamp();
      map['creadoPor'] = createdBy;
      map['creadoEn'] = now;
      map['modificadoPor'] = createdBy;
      map['fechaModificacion'] = now;
    }
    final ref = await _firestore.collection(_personsCol).add(map);
    return ref.id;
  }

  Future<void> updatePerson(Person person, {String? modifiedBy}) async {
    final map = person.toMap();
    if (modifiedBy != null && modifiedBy.isNotEmpty) {
      map['modificadoPor'] = modifiedBy;
      map['fechaModificacion'] = FieldValue.serverTimestamp();
    }
    await _firestore
        .collection(_personsCol)
        .doc(person.id)
        .update(map);
  }

  Future<void> deletePerson(String personId) async {
    final batch = _firestore.batch();
    final visitsRef =
        _firestore.collection(_personsCol).doc(personId).collection('visits');
    final visitsSnap = await visitsRef.get();
    for (final d in visitsSnap.docs) {
      batch.delete(d.reference);
    }
    batch.delete(_firestore.collection(_personsCol).doc(personId));
    await batch.commit();
  }

  // ── Visits (sub-collection) ────────────────────────────────────────────────

  Stream<List<Visit>> visitsStream(String personId) {
    return _firestore
        .collection(_personsCol)
        .doc(personId)
        .collection('visits')
        .orderBy('fecha', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Visit.fromMap(d.id, d.data())).toList());
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
    // Denormalize: update last-visit date and increment visit counter atomically.
    await _firestore.collection(_personsCol).doc(personId).update({
      'ultimaVisita': Timestamp.fromDate(visit.fecha),
      'totalVisitas': FieldValue.increment(1),
    });
  }

  /// Deletes a visit and keeps ultimaVisita + totalVisitas consistent.
  Future<void> deleteVisit(String personId, String visitId) async {
    await _firestore
        .collection(_personsCol)
        .doc(personId)
        .collection('visits')
        .doc(visitId)
        .delete();

    // Recalculate ultimaVisita in case we just removed the most recent visit.
    final newLast = await getLastVisitDate(personId);
    await _firestore.collection(_personsCol).doc(personId).update({
      'ultimaVisita':
          newLast != null ? Timestamp.fromDate(newLast) : FieldValue.delete(),
      'totalVisitas': FieldValue.increment(-1),
    });
  }

  // ── Export (admin) ─────────────────────────────────────────────────────────

  Future<List<Person>> getAllPersonsForExport() async {
    final snap = await _firestore
        .collection(_personsCol)
        .orderBy('nombreApellidos')
        .get();
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
