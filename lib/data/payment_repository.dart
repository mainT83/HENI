import 'package:supabase_flutter/supabase_flutter.dart';

class PaymentRepository {
  final SupabaseClient _client;
  PaymentRepository(this._client);

  /// Crée un paiement Konnect (Tunisie) pour passer l'éleveur connecté en
  /// premium et renvoie l'URL de la page de paiement à ouvrir dans le
  /// navigateur.
  Future<String> creerPaiementPremium() async {
    final res = await _client.functions.invoke('create-payment');
    if (res.status != 200) {
      throw Exception('Échec de création du paiement (${res.status})');
    }
    return (res.data as Map<String, dynamic>)['payUrl'] as String;
  }

  /// Crée un paiement PayPal (international) pour passer l'éleveur connecté
  /// en premium et renvoie le lien d'approbation à ouvrir dans le navigateur.
  Future<String> creerPaiementPremiumPayPal() async {
    final res = await _client.functions.invoke('create-payment-paypal');
    if (res.status != 200) {
      throw Exception('Échec de création du paiement (${res.status})');
    }
    return (res.data as Map<String, dynamic>)['payUrl'] as String;
  }
}
