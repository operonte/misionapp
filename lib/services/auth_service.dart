import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_profile.dart';
import 'firestore_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestore = FirestoreService();

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Web client ID (client_type 3) de Firebase; necesario en Android para que Firebase Auth acepte el idToken.
  static const String _webClientId =
      '700679867705-821sob8r4v0k5p0vhjkojesapklu6t6f.apps.googleusercontent.com';

  Future<User?> signInWithGoogle() async {
    final googleSignIn = GoogleSignIn(
      serverClientId: _webClientId,
    );
    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) return null;

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final userCredential = await _auth.signInWithCredential(credential);
    return userCredential.user;
  }

  Future<void> signOut() async {
    await GoogleSignIn(serverClientId: _webClientId).signOut();
    await _auth.signOut();
  }

  Future<void> updateUserProfile(UserProfile profile) async {
    await _firestore.setUserProfile(profile);
  }

  /// Crea o actualiza perfil con nombre por defecto desde Google.
  Future<UserProfile> ensureUserProfile(User user) async {
    final existing = await _firestore.getUserProfile(user.uid);
    if (existing != null) return existing;

    final displayName = user.displayName ?? user.email ?? 'Usuario';
    final parts = displayName.split(' ');
    final nombre = parts.isNotEmpty ? parts.first : '';
    final apellido = parts.length > 1 ? parts.sublist(1).join(' ') : '';

    final profile = UserProfile(
      uid: user.uid,
      nombre: nombre,
      apellido: apellido,
      grupo: 'JORGEALES',
    );
    await _firestore.setUserProfile(profile);
    return profile;
  }
}
