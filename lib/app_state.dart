import 'package:firebase_auth/firebase_auth.dart';
import 'models/user_profile.dart';
import 'services/storage_service.dart';

/// Estado global: usuario actual, perfil y almacenamiento local.
User? get currentFirebaseUser => FirebaseAuth.instance.currentUser;

UserProfile? _currentProfile;
UserProfile? get currentUserProfile => _currentProfile;
set currentUserProfile(UserProfile? p) => _currentProfile = p;

late StorageService appStorage;
