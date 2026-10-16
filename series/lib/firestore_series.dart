import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import 'firestore_series_detail_page.dart';
import 'firestore_service.dart';
import 'logout_button.dart';

class FirestoreSeriesPage extends StatelessWidget {
  const FirestoreSeriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ซีรีส์ที่ดูแล้ว'),
        actions: const [LogoutButton()],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirestoreService.getMySeries(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('ผิดพลาด: ${snapshot.error}'));
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('ยังไม่มีซีรีส์ กดปุ่ม +'));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final data = docs[i].data();
              final docId = docs[i].id;
              final rating = (data['rating'] as num?)?.toDouble() ?? 0;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FirestoreSeriesDetailPage(series: data),
                      ),
                    );
                  },
                  leading: _seriesThumbnail(data['image'] ?? ''),
                  title: Text(data['title'] ?? ''),
                  subtitle: Text(
                    '${data['date'] ?? ''} • ${rating.toStringAsFixed(1)} / 10 ดาว\n${data['content'] ?? ''}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'แก้ไข',
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FirestoreSeriesFormPage(
                                existing: {'docId': docId, ...data},
                              ),
                            ),
                          );
                          if (result is Map) {
                            await FirestoreService.update(
                              result['docId'],
                              result['title'],
                              result['content'],
                              result['date'],
                              result['rating'],
                              result['image'],
                            );
                          }
                        },
                      ),
                      IconButton(
                        tooltip: 'ลบ',
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('ลบซีรีส์?'),
                              content: Text(
                                'ต้องการลบ "${data['title'] ?? ''}" ใช่ไหม',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('ยกเลิก'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text(
                                    'ลบ',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            await FirestoreService.delete(docId);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const FirestoreSeriesFormPage()),
          );
          if (result is Map) {
            await FirestoreService.add(
              result['title'],
              result['content'],
              result['date'],
              result['rating'],
              result['image'],
            );
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

Widget _seriesThumbnail(String image) {
  if (image.isEmpty) {
    return const CircleAvatar(child: Icon(Icons.movie));
  }

  return ClipRRect(
    borderRadius: BorderRadius.circular(6),
    child: SizedBox(
      width: 48,
      height: 64,
      child: image.startsWith('http://') || image.startsWith('https://')
          ? Image.network(
              image,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                );
              },
              errorBuilder: (context, error, stackTrace) =>
                  const _BrokenImage(),
            )
          : Image.file(
              File(image),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  const _BrokenImage(),
            ),
    ),
  );
}

class _BrokenImage extends StatelessWidget {
  const _BrokenImage();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Colors.grey,
      child: Icon(Icons.broken_image, color: Colors.white),
    );
  }
}

class FirestoreSeriesFormPage extends StatefulWidget {
  final Map<String, dynamic>? existing;

  const FirestoreSeriesFormPage({super.key, this.existing});

  @override
  State<FirestoreSeriesFormPage> createState() =>
      _FirestoreSeriesFormPageState();
}

class _FirestoreSeriesFormPageState extends State<FirestoreSeriesFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String _selectedImage = '';
  double _selectedRating = 5.0;
  DateTime _selectedDate = DateTime.now();

  List<double> get _ratings {
    return List<double>.generate(
      101,
      (index) => double.parse((index / 10).toStringAsFixed(1)),
    );
  }

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _titleController.text = existing['title'] ?? '';
      _contentController.text = existing['content'] ?? '';
      _selectedImage = existing['image'] ?? '';
      _selectedRating = (existing['rating'] as num?)?.toDouble() ?? 5.0;

      final date = DateTime.tryParse(existing['date'] ?? '');
      if (date != null) _selectedDate = date;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.pickFile(type: FileType.image);

      if (result == null || result.path == null) return;

      final appDirectory = await getApplicationDocumentsDirectory();
      final imageDirectory = Directory(
        path.join(appDirectory.path, 'series_images'),
      );
      await imageDirectory.create(recursive: true);

      final extension = path.extension(result.name);
      final fileName =
          'series_${DateTime.now().microsecondsSinceEpoch}$extension';
      final savedFile = await File(
        result.path!,
      ).copy(path.join(imageDirectory.path, fileName));

      if (!mounted) return;

      setState(() {
        _selectedImage = savedFile.path;
      });
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('เลือกรูปภาพไม่สำเร็จ: $error')));
    }
  }

  String _dateText(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? 'แก้ไขซีรีส์ที่ดูแล้ว' : 'เพิ่มซีรีส์ที่ดูแล้ว',
        ),
        actions: const [LogoutButton()],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'ชื่อซีรีส์',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.movie),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'กรุณากรอกชื่อซีรีส์';
                  }
                  return null;
                },
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
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'กรุณากรอกเรื่องย่อหรือความรู้สึก';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<double>(
                initialValue: _selectedRating,
                decoration: const InputDecoration(
                  labelText: 'คะแนนซีรีส์ (เต็ม 10)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.star),
                ),
                items: _ratings.map((rating) {
                  return DropdownMenuItem<double>(
                    value: rating,
                    child: Text('$rating คะแนน'),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedRating = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today),
                title: Text('วันที่: ${_dateText(_selectedDate)}'),
                trailing: const Icon(Icons.edit),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) setState(() => _selectedDate = picked);
                },
              ),
              const SizedBox(height: 16),
              Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _selectedImage.isEmpty
                    ? const Center(
                        child: Icon(
                          Icons.image_outlined,
                          size: 60,
                          color: Colors.grey,
                        ),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _buildSeriesImage(_selectedImage),
                      ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.photo_library),
                label: Text(
                  _selectedImage.isEmpty
                      ? 'เลือกรูปภาพจากเครื่อง'
                      : 'เปลี่ยนรูปภาพ',
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final isFormValid = _formKey.currentState!.validate();
                    if (!isFormValid) return;

                    if (_selectedImage.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('กรุณาเลือกรูปภาพจากเครื่อง'),
                        ),
                      );
                      return;
                    }

                    final result = <String, dynamic>{
                      'title': _titleController.text.trim(),
                      'content': _contentController.text.trim(),
                      'date': _dateText(_selectedDate),
                      'rating': _selectedRating,
                      'image': _selectedImage,
                    };
                    if (widget.existing?['docId'] != null) {
                      result['docId'] = widget.existing!['docId'];
                    }
                    Navigator.pop(context, result);
                  },
                  child: const Text('บันทึก'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _buildSeriesImage(String image) {
  if (image.startsWith('http://') || image.startsWith('https://')) {
    return Image.network(
      image,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return const Center(child: CircularProgressIndicator(strokeWidth: 2));
      },
      errorBuilder: (context, error, stackTrace) => const Center(
        child: Icon(Icons.broken_image, size: 60, color: Colors.grey),
      ),
    );
  }

  return Image.file(
    File(image),
    fit: BoxFit.cover,
    errorBuilder: (context, error, stackTrace) => const Center(
      child: Icon(Icons.broken_image, size: 60, color: Colors.grey),
    ),
  );
}
