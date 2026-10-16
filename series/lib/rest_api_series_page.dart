import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'logout_button.dart';
import 'rest_api_service.dart';
import 'rest_series_detail_page.dart';
import 'rest_series_form_page.dart';
import 'rest_series_model.dart';

class RestApiSeriesPage extends StatefulWidget {
  const RestApiSeriesPage({super.key});

  @override
  State<RestApiSeriesPage> createState() => _RestApiSeriesPageState();
}

class _RestApiSeriesPageState extends State<RestApiSeriesPage> {
  late Future<List<RestSeriesItem>> _seriesFuture;

  String get _ownerId => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _reloadSeries();
  }

  void _reloadSeries() {
    _seriesFuture = RestApiService.getSeries();
  }

  Future<void> _refreshSeries() async {
    setState(_reloadSeries);
    await _seriesFuture;
  }

  Future<void> _addSeries() async {
    final result = await Navigator.push<RestSeriesItem>(
      context,
      MaterialPageRoute(builder: (_) => RestSeriesFormPage(ownerId: _ownerId)),
    );
    if (result == null || !mounted) return;

    try {
      await RestApiService.createSeries(result);
      if (!mounted) return;
      setState(_reloadSeries);
      _showMessage('เพิ่มซีรีส์ใหม่ที่ยังไม่ออนแอร์แล้ว');
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _editSeries(RestSeriesItem series) async {
    final result = await Navigator.push<RestSeriesItem>(
      context,
      MaterialPageRoute(
        builder: (_) => RestSeriesFormPage(ownerId: _ownerId, existing: series),
      ),
    );
    if (result == null || !mounted) return;

    try {
      await RestApiService.updateSeries(result);
      if (!mounted) return;
      setState(_reloadSeries);
      _showMessage('แก้ไขซีรีส์ใหม่ที่ยังไม่ออนแอร์แล้ว');
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _deleteSeries(RestSeriesItem series) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('ลบซีรีส์ใหม่ที่ยังไม่ออนแอร์?'),
        content: Text('ต้องการลบ “${series.title}” ใช่ไหม'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('ลบ', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted || series.id == null) return;

    try {
      await RestApiService.deleteSeries(id: series.id!);
      if (!mounted) return;
      setState(_reloadSeries);
      _showMessage('ลบซีรีส์ใหม่ที่ยังไม่ออนแอร์แล้ว');
    } catch (error) {
      _showError(error);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showError(Object error) {
    final message = error is RestApiException
        ? error.message
        : 'ขออภัย เกิดข้อผิดพลาด กรุณาลองใหม่อีกครั้ง';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ซีรีส์ใหม่ที่ยังไม่ออนแอร์'),
        actions: [
          IconButton(
            onPressed: _refreshSeries,
            tooltip: 'โหลดข้อมูลใหม่',
            icon: const Icon(Icons.refresh),
          ),
          const LogoutButton(),
        ],
      ),
      body: FutureBuilder<List<RestSeriesItem>>(
        future: _seriesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _ErrorState(
              message: snapshot.error is RestApiException
                  ? (snapshot.error! as RestApiException).message
                  : 'ขออภัย เกิดข้อผิดพลาดในการโหลดข้อมูล\nกรุณาลองใหม่อีกครั้ง',
              onRetry: _refreshSeries,
            );
          }

          final seriesList = snapshot.data ?? [];
          if (seriesList.isEmpty) {
            return const _EmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
            itemCount: seriesList.length,
            itemBuilder: (context, index) {
              final series = seriesList[index];
              return _SeriesCard(
                series: series,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RestSeriesDetailPage(series: series),
                  ),
                ),
                onEdit: () => _editSeries(series),
                onDelete: () => _deleteSeries(series),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addSeries,
        icon: const Icon(Icons.add),
        label: const Text('เพิ่มซีรีส์'),
      ),
    );
  }
}

class _SeriesCard extends StatelessWidget {
  final RestSeriesItem series;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _SeriesCard({
    required this.series,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
        leading: _Thumbnail(imageUrl: series.imageUrl),
        title: Text(series.title),
        subtitle: Text(
          '${series.date.split('T').first} • '
          '${series.rating.toStringAsFixed(1)} / 10\n'
          '${series.content}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'แก้ไข',
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: onEdit,
            ),
            IconButton(
              tooltip: 'ลบ',
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  final String imageUrl;

  const _Thumbnail({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return const CircleAvatar(child: Icon(Icons.movie));
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        width: 52,
        height: 64,
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            );
          },
          errorBuilder: (_, error, stackTrace) => const ColoredBox(
            color: Colors.grey,
            child: Icon(Icons.broken_image, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_queue, size: 72, color: Colors.grey),
          SizedBox(height: 12),
          Text('ยังไม่มีซีรีส์ใหม่ที่ยังไม่ออนแอร์'),
          Text('กด “เพิ่มซีรีส์” เพื่อเพิ่มรายการใหม่'),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 64, color: Colors.grey),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('ลองใหม่'),
            ),
          ],
        ),
      ),
    );
  }
}
