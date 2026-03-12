import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Simple model representing authentication information.
class AuthState {
  final bool isLoggedIn;
  final String? email;
  final String? name;
  final String? role;
  final String? error;

  const AuthState({
    this.isLoggedIn = false,
    this.email,
    this.name,
    this.role,
    this.error,
  });

  AuthState copyWith({
    bool? isLoggedIn,
    String? email,
    String? name,
    String? role,
    String? error,
  }) {
    return AuthState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      error: error,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthState &&
          runtimeType == other.runtimeType &&
          isLoggedIn == other.isLoggedIn &&
          email == other.email &&
          name == other.name &&
          role == other.role &&
          error == other.error;

  @override
  int get hashCode =>
      isLoggedIn.hashCode ^
      email.hashCode ^
      name.hashCode ^
      role.hashCode ^
      error.hashCode;
}

class AuthNotifier extends StateNotifier<AuthState> {
  final FirebaseAuth? _auth;
  StreamSubscription<User?>? _authSubscription;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Timer? _debounceTimer;

  // track prefs instance to avoid repeated creation
  SharedPreferences? _prefs;

  AuthNotifier([FirebaseAuth? firebaseAuth])
    : _auth =
          firebaseAuth ??
          (Firebase.apps.isNotEmpty ? FirebaseAuth.instance : null),
      super(const AuthState()) {
    _loadPrefs();
    if (_auth == null) {
      return;
    }

    // Add debouncing and distinct to prevent rapid-fire updates during initialization
    _authSubscription = _auth
        .authStateChanges()
        .distinct(
          (prev, next) => prev?.uid == next?.uid,
        ) // Only emit when user changes
        .listen((user) {
          // Cancel any pending updates
          _debounceTimer?.cancel();

          // Debounce state updates to prevent rebuild storms
          _debounceTimer = Timer(const Duration(milliseconds: 100), () async {
            final newState = user != null
                ? await _buildStateFromUser(user)
                : const AuthState();

            // Only update if state actually changed to prevent rebuild loops
            if (newState.isLoggedIn != state.isLoggedIn ||
                newState.email != state.email ||
                newState.name != state.name ||
                newState.role != state.role) {
              state = newState;
              _savePrefs(state);
            }
          });
        });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> login(String email, String password) async {
    final auth = _auth;
    if (auth == null) return;
    try {
      await auth.signInWithEmailAndPassword(email: email, password: password);
      // state will update via listener
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(error: e.message);
      rethrow;
    }
  }

  Future<void> logout() async {
    final auth = _auth;
    if (auth == null) return;
    await auth.signOut();
    await GoogleSignIn().signOut();
    await _clearPrefs();
    state = const AuthState();
  }

  Future<void> signInWithGoogle() async {
    final auth = _auth;
    if (auth == null) return;
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        // Prepare state from Google User
        state = state.copyWith(
          isLoggedIn: true,
          email: user.email,
          name: user.displayName,
          role: 'seller', // Default role for Google Sign-In
        );
        _savePrefs(state);

        // Sync to Firestore if needed
        const docId = 'reworth_4_users';
        await _firestore.collection('user').doc(docId).set({
          'uid': user.uid,
          'name': user.displayName,
          'email': user.email,
          'role': 'seller',
          'lastLogin': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> signUp(
    String name,
    String email,
    String password,
    String role,
  ) async {
    final auth = _auth;
    if (auth == null) return;
    try {
      UserCredential cred = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = cred.user;
      await user?.updateDisplayName(name);

      // store additional metadata in Firestore
      if (user != null) {
        try {
          // use the fixed document ID that already exists in your console
          const docId = 'reworth_4_users';
          final docRef = _firestore.collection('user').doc(docId);
          await docRef.set(
            {
              'uid': user.uid,
              'name': name,
              'email': email,
              'role': role,
              'createdAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          ); // merge to avoid overwriting other fields
          debugPrint('User document written to $docId');
        } on FirebaseException catch (fe) {
          debugPrint('Firestore write failed: ${fe.code} ${fe.message}');
          rethrow;
        }
      }

      // update local state right away so UI can react
      state = state.copyWith(
        isLoggedIn: true,
        email: email,
        name: name,
        role: role,
      );
      _savePrefs(state);
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(error: e.message);
      rethrow;
    }
  }

  /// Look up the role/email for an authenticated user from Firestore.
  /// Since documents are stored with an auto‑ID, we query by email.
  Future<AuthState> _buildStateFromUser(User user) async {
    String? role;
    try {
      const docId = 'reworth_4_users';
      final doc = await _firestore.collection('user').doc(docId).get();
      if (doc.exists) {
        final data = doc.data()!;
        if (data['email'] == user.email) {
          role = data['role'] as String?;
        }
      }
    } catch (_) {}
    return AuthState(
      isLoggedIn: true,
      email: user.email,
      name: user.displayName,
      role: role,
    );
  }

  // shared preferences helpers ------------------------------------------------
  Future<void> _loadPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    final logged = _prefs?.getBool('loggedIn') ?? false;
    if (logged) {
      state = AuthState(
        isLoggedIn: true,
        email: _prefs?.getString('email'),
        name: _prefs?.getString('name'),
        role: _prefs?.getString('role'),
      );
    }
  }

  Future<void> _savePrefs(AuthState s) async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setBool('loggedIn', s.isLoggedIn);
    if (s.email != null) await _prefs!.setString('email', s.email!);
    if (s.name != null) await _prefs!.setString('name', s.name!);
    if (s.role != null) await _prefs!.setString('role', s.role!);
  }

  Future<void> _clearPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.clear();
  }
}

/// Global auth provider.
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(),
);

/// Convenience selectors.
final isLoggedInProvider = Provider<bool>(
  (ref) => ref.watch(authProvider).isLoggedIn,
);
final userEmailProvider = Provider<String?>(
  (ref) => ref.watch(authProvider).email,
);
final userNameProvider = Provider<String?>(
  (ref) => ref.watch(authProvider).name,
);
final userRoleProvider = Provider<String?>(
  (ref) => ref.watch(authProvider).role,
);

// simple field providers that hold local form state
final loginEmailProvider = StateProvider<String>((ref) => '');
final loginPasswordProvider = StateProvider<String>((ref) => '');

final signupNameProvider = StateProvider<String>((ref) => '');
final signupEmailProvider = StateProvider<String>((ref) => '');
final signupPasswordProvider = StateProvider<String>((ref) => '');
final signupRoleProvider = StateProvider<String>((ref) => 'seller');

// indicates whether the onboarding has been shown already
final hasSeenOnboardingProvider = StateProvider<bool>((ref) => false);
