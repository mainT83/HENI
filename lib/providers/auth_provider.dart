import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_provider.dart';

/// Flux des changements d'état d'authentification (login/logout/refresh),
/// utilisé par le router pour rediriger automatiquement.
final authStateProvider = StreamProvider<AuthState>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client.auth.onAuthStateChange;
});

final currentUserProvider = Provider<User?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  // On réagit aussi aux changements pour que ce provider reste à jour.
  ref.watch(authStateProvider);
  return client.auth.currentUser;
});

class AuthRepository {
  final SupabaseClient _client;
  AuthRepository(this._client);

  Future<void> signInWithEmail(String email, String password) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signUpWithEmail(String email, String password, {String? fullName}) async {
    await _client.auth.signUp(
      email: email,
      password: password,
      data: (fullName != null && fullName.trim().isNotEmpty) ? {'full_name': fullName.trim()} : null,
    );
  }

  Future<void> signInWithGoogle() async {
    // Nécessite la configuration OAuth Google côté Supabase Dashboard
    // (Authentication > Providers > Google) + les identifiants natifs
    // Android/iOS dans google-services.json / GoogleService-Info.plist.
    await _client.auth.signInWithOAuth(OAuthProvider.google);
  }

  Future<void> signInWithApple() async {
    // Nécessite la configuration OAuth Apple côté Supabase Dashboard
    // (Authentication > Providers > Apple) + "Sign in with Apple" activé
    // dans les capacités Xcode du projet iOS.
    await _client.auth.signInWithOAuth(OAuthProvider.apple);
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// Définit/change le mot de passe du compte connecté — utile notamment
  /// pour un compte créé via Google, qui n'a jamais de mot de passe Nidus
  /// et serait sinon bloqué pour se connecter sans passer par Google.
  Future<void> definirMotDePasse(String nouveauMotDePasse) async {
    await _client.auth.updateUser(UserAttributes(password: nouveauMotDePasse));
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(supabaseClientProvider));
});
