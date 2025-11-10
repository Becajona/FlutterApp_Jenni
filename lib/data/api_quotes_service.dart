import 'dart:convert';
import 'package:http/http.dart' as http;

class QuotesService {
  static const _zenUrl = 'https://zenquotes.io/api/random';
  static const _libreUrl = 'https://libretranslate.de/translate'; // instancia pública
  static const _myMemoryUrl = 'https://api.mymemory.translated.net/get';

  static Future<String> getRandomQuote() async {
    try {
      // 1) Obtener frase en inglés
      final res = await http.get(Uri.parse(_zenUrl)).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) {
        print('❌ ZenQuotes status: ${res.statusCode} body: ${res.body}');
        return 'No se pudo obtener la frase hoy.';
      }

      final data = jsonDecode(res.body);
      final String quoteEn = (data[0]['q'] ?? '').toString().trim();
      final String author = (data[0]['a'] ?? 'Unknown').toString().trim();

      // Sanea comillas raras para mejorar la traducción
      final clean = quoteEn
          .replaceAll('“', '"')
          .replaceAll('”', '"')
          .replaceAll('’', "'")
          .replaceAll('—', '-');

      // 2) Traducir: primero LibreTranslate, luego MyMemory (fallback)
      final esLT = await _translateLibre(clean, from: 'en', to: 'es');
      final quoteEs = esLT ?? await _translateMyMemory(clean, from: 'en', to: 'es') ?? quoteEn;

      return '“$quoteEs” — $author';
    } catch (e) {
      print('⚠️ Error en QuotesService.getRandomQuote: $e');
      return 'Error al conectar con el servicio de frases.';
    }
  }

  // ------- Traductor 1: LibreTranslate (POST JSON) -------
  static Future<String?> _translateLibre(String text, {String from = 'en', String to = 'es'}) async {
    try {
      final res = await http
          .post(
            Uri.parse(_libreUrl),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'User-Agent': 'Ahorraton/1.0 (Flutter)',
            },
            body: jsonEncode({
              'q': text,
              'source': from,
              'target': to,
              'format': 'text',
            }),
          )
          .timeout(const Duration(seconds: 12));

      if (res.statusCode == 200) {
        final m = jsonDecode(res.body) as Map<String, dynamic>;
        final t = (m['translatedText'] ?? '').toString().trim();
        if (t.isNotEmpty) return t;
        print('ℹ️ LibreTranslate sin texto traducido. body: ${res.body}');
        return null;
      } else {
        print('⚠️ LibreTranslate status: ${res.statusCode} body: ${res.body}');
        return null;
      }
    } catch (e) {
      print('⚠️ LibreTranslate error: $e');
      return null;
    }
  }

  // ------- Traductor 2: MyMemory (GET) -------
  static Future<String?> _translateMyMemory(String text, {String from = 'en', String to = 'es'}) async {
    try {
      final uri = Uri.parse(_myMemoryUrl).replace(queryParameters: {
        'q': text,
        'langpair': '$from|$to',
        // Opcional: agregar email= para más cuota gratuita
      });

      final res = await http
          .get(uri, headers: {'User-Agent': 'Ahorraton/1.0 (Flutter)'})
          .timeout(const Duration(seconds: 12));

      if (res.statusCode == 200) {
        final m = jsonDecode(res.body) as Map<String, dynamic>;
        final resp = m['responseData'] as Map<String, dynamic>?;
        final t = (resp?['translatedText'] ?? '').toString().trim();
        if (t.isNotEmpty) return t;
        print('ℹ️ MyMemory sin texto traducido. body: ${res.body}');
        return null;
      } else {
        print('⚠️ MyMemory status: ${res.statusCode} body: ${res.body}');
        return null;
      }
    } catch (e) {
      print('⚠️ MyMemory error: $e');
      return null;
    }
  }
}
