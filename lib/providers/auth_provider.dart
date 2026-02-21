import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Simple model representing authentication information.
class AuthState {
  final bool isLoggedIn;
  final String? email;
  final String? name;
  final String? role;

  const AuthState({this.isLoggedIn = false, this.email, this.name, this.role});

  AuthState copyWith({
    bool? isLoggedIn,
    String? email,
    String? name,
    String? role,
  }) {
    return AuthState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState());

  void login(String email, String password) {
    // In a real app you would call a repository / service here.
    // For this sample we accept any non-empty credentials.
    if (email.isNotEmpty && password.isNotEmpty) {
      state = state.copyWith(isLoggedIn: true, email: email);
    }
  }

  void logout() {
    state = const AuthState();
  }

  void signUp(String name, String email, String password, String role) {
    // again simple stub logic
    if (name.isNotEmpty && email.isNotEmpty && password.isNotEmpty) {
      state = AuthState(isLoggedIn: true, name: name, email: email, role: role);
    }
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
