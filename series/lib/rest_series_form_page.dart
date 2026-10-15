import 'package:flutter/material.dart';

import 'rest_series_model.dart';

/// ฟอร์มเพิ่มและแก้ไขข้อมูลซีรีส์บน REST API
class RestSeriesFormPage extends StatefulWidget {
  final String ownerId;
  final RestSeriesItem? existing;

  const RestSeriesFormPage({super.key, required this.ownerId, this.existing});

  @override
  State<RestSeriesFormPage> createState() => _RestSeriesFormPageState();
}

class _RestSeriesFormPageState extends State<RestSeriesFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _imageUrlController = TextEditingController();

  double _rating = 5.0;
  DateTime _date = DateTime.now();

  bool get _isEditing => widget.existing != null;

  List<double> get _ratings => List<double>.generate(
    101,
    (index) => double.parse((index / 10).toStringAsFixed(1)),
  );

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing == null) return;

    _titleController.text = existing.title;
    _contentController.text = existing.content;
    _imageUrlController.text = existing.imageUrl;
    _rating = existing.rating;
    _date = DateTime.tryParse(existing.date) ?? DateTime.now();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime value) {
    return '${value.year.toString().padLeft(4, '0')}-'
        '${value.month.toString().padLeft(2, '0')}-'
        '${value.day.toString().padLeft(2, '0')}';
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null && mounted) setState(() => _date = picked);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.pop(
      context,
      RestSeriesItem(
        id: widget.existing?.id,
        ownerId: widget.ownerId,
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        date: _formatDate(_date),
        rating: _rating,
        imageUrl: _imageUrlController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'แก้ไขซีรีส์ออนไลน์' : 'เพิ่มซีรีส์ออนไลน์'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'ชื่อซีรีส์',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.movie),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'กรุณากรอกชื่อซีรีส์'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _contentController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'เรื่องย่อหรือความรู้สึก',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'กรุณากรอกเรื่องย่อหรือความรู้สึก'
                  : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<double>(
              initialValue: _rating,
              decoration: const InputDecoration(
                labelText: 'คะแนนซีรีส์ (เต็ม 10)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.star),
              ),
              items: _ratings
                  .map(
                    (rating) => DropdownMenuItem(
                      value: rating,
                      child: Text('$rating คะแนน'),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _rating = value);
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: Text('วันที่: ${_formatDate(_date)}'),
              trailing: const Icon(Icons.edit),
              onTap: _selectDate,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _imageUrlController,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'URL รูปภาพ (ไม่บังคับ)',
                hintText: 'https://example.com/series.jpg',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.link),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.save),
                label: const Text('บันทึกข้อมูล'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
