import 'dart:io';

import 'package:flutter/material.dart';

import 'logout_button.dart';

class FirestoreSeriesDetailPage extends StatelessWidget {
  final Map<String, dynamic> series;

  const FirestoreSeriesDetailPage({super.key, required this.series});

  @override
  Widget build(BuildContext context) {
    final rating = (series['rating'] as num?)?.toDouble() ?? 0;
    final image = series['image'] as String? ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('รายละเอียดซีรีส์ที่ดูแล้ว'),
        actions: const [LogoutButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _detailImage(image),
          const SizedBox(height: 20),
          Text(
            series['title'] as String? ?? '',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 20),
              const SizedBox(width: 8),
              Text(series['date'] as String? ?? ''),
              const SizedBox(width: 20),
              const Icon(Icons.star, color: Colors.amber, size: 20),
              const SizedBox(width: 8),
              Text('${rating.toStringAsFixed(1)} / 10'),
            ],
          ),
          const Divider(height: 32),
          Text(
            series['content'] as String? ?? '',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}

Widget _detailImage(String image) {
  if (image.isEmpty) {
    return const AspectRatio(
      aspectRatio: 16 / 9,
      child: ColoredBox(
        color: Color(0xFFE8E8E8),
        child: Center(child: Icon(Icons.movie, size: 64)),
      ),
    );
  }

  final imageWidget =
      image.startsWith('http://') || image.startsWith('https://')
      ? Image.network(
          image,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            );
          },
          errorBuilder: (_, error, stackTrace) => _brokenImage(),
        )
      : Image.file(
          File(image),
          fit: BoxFit.cover,
          errorBuilder: (_, error, stackTrace) => _brokenImage(),
        );

  return ClipRRect(
    borderRadius: BorderRadius.circular(16),
    child: AspectRatio(aspectRatio: 16 / 9, child: imageWidget),
  );
}

Widget _brokenImage() {
  return const ColoredBox(
    color: Color(0xFFE8E8E8),
    child: Center(child: Icon(Icons.broken_image, size: 64)),
  );
}
