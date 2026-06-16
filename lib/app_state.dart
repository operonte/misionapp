import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'models/user_profile.dart';
import 'services/storage_service.dart';

// ── Firebase Auth ──────────────────────────────────────────────────────────

User? get currentFirebaseUser => FirebaseAuth.instance.currentUser;

// ── User profile (reactive) ────────────────────────────────────────────────

final _profileNotifier = ValueNotifier<UserProfile?>(null);

UserProfile? get currentUserProfile => _profileNotifier.value;
set currentUserProfile(UserProfile? p) => _profileNotifier.value = p;

ValueListenable<UserProfile?> get userProfileListenable => _profileNotifier;

// ── Theme (reactive) ───────────────────────────────────────────────────────
// Index into appPalettes. Default 0 = Celeste. Loaded from storage in main().

final ValueNotifier<int> themeIndexNotifier = ValueNotifier<int>(0);

// ── Local storage ──────────────────────────────────────────────────────────

late StorageService appStorage;
