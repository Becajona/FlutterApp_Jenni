import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;

/// Convierte montos de una moneda a otra usando:
/// 1) exchangerate.host (con access_key si la tienes)
/// 2) fallback a Frankfurter (sin clave) si hay error/timeout
class ExchangeService {
  static const String _exHost = 'api.exchangerate.host';
  static const String _frankHost = 'api.frankfurter.app';

  static const String _API_KEY =
      String.fromEnvironment('EXCHANGE_API_KEY', defaultValue: '');

  static Uri _exUri(String path, Map<String, String> q) {
    final qp = {...q};
    if (_API_KEY.isNotEmpty) qp['access_key'] = _API_KEY; // <-- requerido por tu cuenta
    return Uri.https(_exHost, '/$path', qp);
  }

  static Future<double?> getRate(String from, String to) async {
    final base = from.trim().toUpperCase();
    final symbols = to.trim().toUpperCase();

    // 1) Intento exchangerate.host
    try {
      final uri = _exUri('latest', {'base': base, 'symbols': symbols});
      final res = await http.get(uri).timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is Map && data['success'] == false) {
          // key faltante o inválida -> probamos fallback
          // print('exchangerate error: ${data['error']}');
        } else {
          final rates = (data is Map) ? data['rates'] as Map? : null;
          final v = rates?[symbols];
          if (v != null) return (v as num).toDouble();
        }
      }
    } catch (_) {
      // socket/timeout/format -> vamos a fallback
    }

    // 2) Fallback Frankfurter (sin clave)
    try {
      final uri = Uri.https(_frankHost, '/latest', {'from': base, 'to': symbols});
      final res = await http.get(uri).timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final rates = (data is Map) ? data['rates'] as Map? : null;
        final v = rates?[symbols];
        if (v != null) return (v as num).toDouble();
      }
    } catch (_) {}

    return null;
  }

  static Future<double?> convert(double amount, String from, String to) async {
    final rate = await getRate(from, to);
    if (rate == null) return null;
    return amount * rate;
  }
}
