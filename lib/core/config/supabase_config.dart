/// Identifiants du projet Supabase.
///
/// À remplacer par les vraies valeurs de votre projet (Supabase Dashboard >
/// Project Settings > API). Ne jamais commiter la clé "service_role" dans
/// l'app mobile — seule la clé "anon" (publique, protégée par les policies
/// RLS) doit apparaître ici.
class SupabaseConfig {
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://rtcfcxmektxstcdypqpz.supabase.co',
  );

  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_scV-i47Am3sqozWj1FCIMA_PkfgLwgd',
  );
}
