/// Levée quand un trigger de limite du plan gratuit bloque une création
/// (ex: verifier_limite_oiseaux_gratuit, migration 019).
class LimitePlanGratuitException implements Exception {}
