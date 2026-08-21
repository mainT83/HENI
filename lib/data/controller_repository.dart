import 'dart:convert';
import 'package:http/http.dart' as http;

/// État renvoyé par /api/status du contrôleur Breeding Control.
class ControllerStatus {
  final String mode;
  final String heure;
  final String date;
  final double? temp;
  final double? hum;
  final List<int> dutiesPct;
  final String? saison;
  final bool relaisTemp;
  final bool relaisHum;
  final String wifiMode;
  final String wifiIp;
  final String wifiSsid;

  ControllerStatus.fromJson(Map<String, dynamic> json)
      : mode = json['mode'] as String,
        heure = json['heure'] as String,
        date = json['date'] as String,
        temp = (json['temp'] as num?)?.toDouble(),
        hum = (json['hum'] as num?)?.toDouble(),
        dutiesPct = (json['duties_pct'] as List).map((d) => (d as num).toInt()).toList(),
        saison = json['saison'] as String?,
        relaisTemp = (json['relais'] as Map<String, dynamic>)['temp'] as bool,
        relaisHum = (json['relais'] as Map<String, dynamic>)['hum'] as bool,
        wifiMode = (json['wifi'] as Map<String, dynamic>)['mode'] as String,
        wifiIp = (json['wifi'] as Map<String, dynamic>)['ip'] as String,
        wifiSsid = (json['wifi'] as Map<String, dynamic>)['ssid'] as String;
}

/// Erreur levée quand le contrôleur n'est pas joignable à l'IP donnée
/// (mauvaise IP, téléphone pas sur le même réseau WiFi, etc.)
class ControllerUnreachableException implements Exception {
  final String message;
  ControllerUnreachableException(this.message);
}

class ControllerRepository {
  static const _timeout = Duration(seconds: 5);

  Future<ControllerStatus> fetchStatus(String ip) async {
    try {
      final res = await http.get(Uri.parse('http://$ip/api/status')).timeout(_timeout);
      if (res.statusCode != 200) {
        throw ControllerUnreachableException('Réponse inattendue (${res.statusCode})');
      }
      return ControllerStatus.fromJson(json.decode(res.body) as Map<String, dynamic>);
    } on ControllerUnreachableException {
      rethrow;
    } catch (e) {
      throw ControllerUnreachableException(
          'Contrôleur injoignable à $ip — vérifiez que votre téléphone est sur le même réseau WiFi.');
    }
  }

  Future<void> setMode(String ip, String mode) async {
    final res = await http
        .post(Uri.parse('http://$ip/api/mode'),
            headers: {'Content-Type': 'application/json'}, body: json.encode({'mode': mode}))
        .timeout(_timeout);
    if (res.statusCode != 200) {
      throw ControllerUnreachableException('Échec du changement de mode (${res.statusCode})');
    }
  }

  Future<void> setSortieManuelle(String ip, int sortie, int dutyPct) async {
    final res = await http
        .post(Uri.parse('http://$ip/api/manuel'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'sortie': sortie, 'duty_pct': dutyPct}))
        .timeout(_timeout);
    if (res.statusCode != 200) {
      throw ControllerUnreachableException('Échec du réglage de la sortie (${res.statusCode})');
    }
  }
}
