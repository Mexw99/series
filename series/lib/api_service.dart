import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

class Quote {
  final String text;
  final String author;

  const Quote({required this.text, required this.author});

  factory Quote.fromJson(Map<String, dynamic> json) {
    return Quote(
      text: json['quote'] as String? ?? '',
      author: json['author'] as String? ?? 'ไม่ทราบชื่อ',
    );
  }
}

class SeriesRecommendation {
  final int id;
  final String title;
  final String summary;
  final List<String> genres;
  final double rating;
  final String imageUrl;

  const SeriesRecommendation({
    required this.id,
    required this.title,
    required this.summary,
    required this.genres,
    required this.rating,
    required this.imageUrl,
  });

  factory SeriesRecommendation.fromJson(Map<String, dynamic> json) {
    final ratingValue = json['rating'];
    final image = json['image'];

    return SeriesRecommendation(
      id: json['id'] as int? ?? 0,
      title: json['name'] as String? ?? 'ซีรีส์แนะนำ',
      summary: _removeHtml(json['summary'] as String? ?? ''),
      genres: (json['genres'] as List<dynamic>? ?? [])
          .whereType<String>()
          .toList(),
      rating: ratingValue is Map && ratingValue['average'] is num
          ? (ratingValue['average'] as num).toDouble()
          : 0,
      imageUrl: image is Map ? image['original'] as String? ?? '' : '',
    );
  }
}

String _removeHtml(String value) {
  return value
      .replaceAll(RegExp(r'<[^>]*>'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

class ApiService {
  static Future<Quote> fetchQuote() async {
    try {
      final response = await http
          .get(Uri.parse('https://dummyjson.com/quotes/random'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception('เซิร์ฟเวอร์ตอบกลับ ${response.statusCode}');
      }

      return Quote.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } catch (_) {
      throw Exception('โหลดคำคมไม่ได้ ตรวจสอบอินเทอร์เน็ต');
    }
  }

  static Future<SeriesRecommendation> fetchSeriesRecommendation({
    int? excludeId,
  }) async {
    try {
      final page = Random().nextInt(4);
      final response = await http
          .get(Uri.parse('https://api.tvmaze.com/shows?page=$page'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception('เซิร์ฟเวอร์ตอบกลับ ${response.statusCode}');
      }

      final shows = (jsonDecode(response.body) as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .where((show) => show['id'] != excludeId)
          .toList();

      if (shows.isEmpty) {
        throw Exception('ไม่พบซีรีส์แนะนำ');
      }

      final show = shows[Random().nextInt(shows.length)];
      return SeriesRecommendation.fromJson(show);
    } catch (_) {
      throw Exception('โหลดซีรีส์แนะนำไม่ได้ ตรวจสอบอินเทอร์เน็ต');
    }
  }
}
