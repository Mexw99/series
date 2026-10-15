import 'package:flutter/material.dart';

import 'rest_series_model.dart';

/// หน้าแสดงรายละเอียดของซีรีส์จาก REST API
class RestSeriesDetailPage extends StatelessWidget {
  final RestSeriesItem series;

  const RestSeriesDetailPage({super.key, required this.series});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('รายละเอียดซีรีส์ออนไลน์')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SeriesImage(imageUrl: series.imageUrl),
          const SizedBox(height: 20),
          Text(series.title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 20),
              const SizedBox(width: 8),
              Text(series.date),
              const SizedBox(width: 20),
              const Icon(Icons.star, size: 20, color: Colors.amber),
              const SizedBox(width: 8),
              Text('${series.rating.toStringAsFixed(1)} / 10'),
            ],
          ),
          const Divider(height: 32),
          Text(series.content, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}

class _SeriesImage extends StatelessWidget {
  final String imageUrl;

  const _SeriesImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return _placeholder();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, error, stackTrace) => _placeholder(),
        ),
      ),
    );
  }

  Widget _placeholder() {
    return const AspectRatio(
      aspectRatio: 16 / 9,
      child: ColoredBox(
        color: Color(0xFFE8E8E8),
        child: Center(child: Icon(Icons.movie, size: 64)),
      ),
    );
  }
}
