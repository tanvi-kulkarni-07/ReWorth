import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart'; // for PlatformException
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Simple model representing authentication information.
class AuthState {
  final bool isLoggedIn;
  final String? email;
  final String? name;
  final String? role;
  final String? phone;
  final String? location;
  final String? error;

  const AuthState({
    this.isLoggedIn = false,
    this.email,
    this.name,
    this.role,
    this.phone,
    this.location,
    this.error,
  });

  AuthState copyWith({
    bool? isLoggedIn,
    String? email,
    String? name,
    String? role,
    String? phone,
    String? location,
    String? error,
  }) {
    return AuthState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      location: location ?? this.location,
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
  final FirebaseFirestore? _firestore =
      Firebase.apps.isNotEmpty ? FirebaseFirestore.instance : null;
  Timer? _debounceTimer;

  // shared GoogleSignIn object with email scope; avoids recreating and allows
  // configuration if you need to supply a clientId for web platforms.
  //
  // **Important setup notes**
  // 1. Add your `google-services.json` (Android) and `GoogleService-Info.plist`
  //    (iOS) files to the project. Ensure the OAuth client is configured with
  //    the proper package name / bundle ID and SHA‑1 fingerprint (debug or
  //    release as appropriate) in the Firebase console. Missing fingerprints
  //    are the most common cause of ``PlatformException(sign_in_failed)``.
  // 2. For web, provide a `clientId` to GoogleSignIn constructor or use the
  //    `google_sign_in_web` plugin, and configure the OAuth consent screen.
  // 3. Ensure the Firebase project has Google sign-in enabled under Auth > Sign-in
  //    method.
  //
  // The widget layer catches exceptions and displays them; if you still see a
  // platform exception you likely need to fix configuration rather than code.
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);

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

  /// Local login - compares credentials stored in SharedPreferences.
  Future<void> login(String email, String password) async {
    _prefs ??= await SharedPreferences.getInstance();
    final storedEmail = _prefs!.getString('email');
    final storedPassword = _prefs!.getString('password');
    if (storedEmail == email && storedPassword == password) {
      // build state from prefs values
      state = AuthState(
        isLoggedIn: true,
        email: storedEmail,
        name: _prefs!.getString('name'),
        role: _prefs!.getString('role'),
        phone: _prefs!.getString('phone'),
        location: _prefs!.getString('location'),
      );
      _savePrefs(state);
    } else {
      state = state.copyWith(error: 'Invalid credentials');
      throw Exception('Invalid credentials');
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
      // use the shared instance so we can configure options in one place
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // user cancelled the flow; not an error
        return;
      }

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
        if (_firestore != null) {
          const docId = 'reworth_4_users';
          await _firestore!.collection('user').doc(docId).set({
            'uid': user.uid,
            'name': user.displayName,
            'email': user.email,
            'role': 'seller',
            'lastLogin': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
      }
    } on PlatformException catch (e) {
      // ApiException 10 is a common Android misconfiguration (SHA-1 mismatch).
      final raw = e.message ?? '';
      final message = raw.contains('ApiException: 10')
          ? 'Google Sign-In is not configured correctly.\nPlease add the debug/release SHA-1 fingerprint to your Firebase project and enable Google Sign-In under Authentication -> Sign-in method.'
          : 'Google Sign-In failed (platform): $raw';
      state = state.copyWith(error: message);
      rethrow;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(error: e.message);
      rethrow;
    } catch (e) {
      final msg = e.toString();
      state = state.copyWith(error: msg);
      rethrow;
    }
  }

  /// Sign up by saving details locally to SharedPreferences.  The
  /// [phone] and [location] parameters are optional but persisted.
  Future<void> signUp(
    String name,
    String email,
    String password,
    String role,
    String phone,
    String location,
  ) async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setString('email', email);
    await _prefs!.setString('password', password);
    await _prefs!.setString('name', name);
    await _prefs!.setString('role', role);
    await _prefs!.setString('phone', phone);
    await _prefs!.setString('location', location);

    state = AuthState(
      isLoggedIn: true,
      email: email,
      name: name,
      role: role,
      phone: phone,
      location: location,
    );
    _savePrefs(state);
  }

  /// Look up the role/email for an authenticated user from Firestore.
  /// Since documents are stored with an auto‑ID, we query by email.
  Future<AuthState> _buildStateFromUser(User user) async {
    String? role;

    if (_firestore != null) {
      try {
        const docId = 'reworth_4_users';
        final doc = await _firestore!.collection('user').doc(docId).get();
        if (doc.exists) {
          final data = doc.data()!;
          if (data['email'] == user.email) {
            role = data['role'] as String?;
          }
        }
      } catch (_) {}
    }

    return AuthState(
      isLoggedIn: true,
      email: user.email,
      name: user.displayName,
      role: role,
    );
  }

  Future<void> _loadUserRole(User user) async {
    try {
      final updatedState = await _buildStateFromUser(user);
      state = state.copyWith(role: updatedState.role);
      _savePrefs(state);
    } catch (_) {
      // ignore; role is non-critical for login flow
    }
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
    if (s.phone != null) await _prefs!.setString('phone', s.phone!);
    if (s.location != null) await _prefs!.setString('location', s.location!);
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
final userRoleProvider = Provider<String>(
  (ref) => ref.watch(authProvider).role ?? 'seller',
);
final userPhoneProvider = Provider<String?>(
  (ref) => ref.watch(authProvider).phone,
);
final userLocationProvider = Provider<String?>(
  (ref) => ref.watch(authProvider).location,
);

// simple field providers that hold local form state
final loginEmailProvider = StateProvider<String>((ref) => '');
final loginPasswordProvider = StateProvider<String>((ref) => '');

final signupNameProvider = StateProvider<String>((ref) => '');
final signupEmailProvider = StateProvider<String>((ref) => '');
final signupPasswordProvider = StateProvider<String>((ref) => '');
final signupRoleProvider = StateProvider<String>((ref) => 'seller');
final signupPhoneProvider = StateProvider<String>((ref) => '');
final signupLocationProvider = StateProvider<String>((ref) => '');

// indicates whether the onboarding has been shown already
final hasSeenOnboardingProvider = StateProvider<bool>((ref) => false);
