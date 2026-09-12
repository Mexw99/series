import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import 'database_helper.dart';

void main() => runApp(const MyApp());

// แม่พิมพ์ข้อมูลซีรีส์
class SeriesItem {
  final int? id;
  final String title;
  final String content;
  final String date;
  final double rating;
  final String image;

  const SeriesItem({
    this.id,
    required this.title,
    required this.content,
    required this.date,
    required this.rating,
    required this.image,
  });

  // แปลง object → Map สำหรับ SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'date': date,
      'rating': rating,
      'image': image,
    };
  }

  // แปลง Map จาก SQLite → object
  factory SeriesItem.fromMap(Map<String, dynamic> map) {
    return SeriesItem(
      id: map['id'],
      title: map['title'],
      content: map['content'],
      date: map['date'],
      rating: (map['rating'] as num).toDouble(),
      image: map['image'] ?? '',
    );
  }
}

// // ข้อมูลซีรีส์เริ่มต้นจากสัปดาห์ที่ 1
// final List<SeriesItem> seriesList = [
//   SeriesItem(
//     title: 'Queen of Tears',
//     content: 'ซีรีส์โรแมนติกดราม่าที่อยากดู เพราะกระแสดีและนักแสดงน่าสนใจ',
//     date: '2025-06-10',
//     rating: 4.8,
//     image:
//         'https://raw.githubusercontent.com/Mexw99/series/main/series/assets/images/queen_of_tears.jpg',
//   ),
//   SeriesItem(
//     title: 'Moving',
//     content: 'ซีรีส์แนวพลังพิเศษ แอ็กชัน และครอบครัว เนื้อเรื่องดูเข้มข้นมาก',
//     date: '2025-06-12',
//     rating: 4.7,
//     image:
//         'https://raw.githubusercontent.com/Mexw99/series/main/series/assets/images/moving.jpg',
//   ),
//   SeriesItem(
//     title: 'The Glory',
//     content: 'ซีรีส์ดราม่าแก้แค้นที่หลายคนแนะนำ เนื้อเรื่องดูน่าติดตาม',
//     date: '2025-06-14',
//     rating: 4.9,
//     image:
//         'https://raw.githubusercontent.com/Mexw99/series/main/series/assets/images/the_glory.jpg',
//   ),
//   SeriesItem(
//     title: 'Business Proposal',
//     content: 'ซีรีส์โรแมนติกคอมเมดี้ ดูเบาสบาย เหมาะกับวันพักผ่อน',
//     date: '2025-06-16',
//     rating: 4.5,
//     image:
//         'https://raw.githubusercontent.com/Mexw99/series/main/series/assets/images/business_proposal.jpg',
//   ),
//   SeriesItem(
//     title: 'All of Us Are Dead',
//     content: 'ซีรีส์ซอมบี้ในโรงเรียน น่าดูเพราะลุ้นและตื่นเต้น',
//     date: '2025-06-18',
//     rating: 4.6,
//     image:
//         'https://raw.githubusercontent.com/Mexw99/series/main/series/assets/images/all_of_us_are_dead.jpg',
//   ),
// ];

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Series Watchlist',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 200, 118, 147),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color.fromARGB(255, 243, 243, 243),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color.fromARGB(255, 246, 211, 221),
          foregroundColor: Color.fromARGB(255, 200, 0, 73),
          centerTitle: true,
        ),
        cardTheme: const CardThemeData(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
      ),
      home: const MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [const SeriesListPage(), const AboutPage()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.movie), label: 'ซีรีส์'),
          BottomNavigationBarItem(icon: Icon(Icons.info), label: 'เกี่ยวกับ'),
        ],
      ),
    );
  }
}

// หน้ารายการซีรีส์
class SeriesListPage extends StatefulWidget {
  const SeriesListPage({super.key});

  @override
  State<SeriesListPage> createState() => _SeriesListPageState();
}

class _SeriesListPageState extends State<SeriesListPage> {
  List<SeriesItem> _seriesList = [];
  String _searchQuery = '';

  final List<Color> colors = [
    Colors.pink,
    Colors.purple,
    Colors.orange,
    Colors.teal,
    Colors.green,
  ];

  @override
  void initState() {
    super.initState();
    _loadSeries();
  }

  // โหลดข้อมูลจาก SQLite
  Future<void> _loadSeries() async {
    try {
      final data = await DatabaseHelper.getAll();

      if (!mounted) return;

      setState(() {
        _seriesList = data;
      });
    } catch (error) {
      _showDatabaseError(error);
    }
  }

  // เพิ่มซีรีส์ลง SQLite
  Future<void> _addSeries(SeriesItem item) async {
    try {
      await DatabaseHelper.insert(item);
      await _loadSeries();
    } catch (error) {
      _showDatabaseError(error);
    }
  }

  // แก้ไขซีรีส์ใน SQLite
  Future<void> _updateSeries(SeriesItem item) async {
    try {
      await DatabaseHelper.update(item);
      await _loadSeries();
    } catch (error) {
      _showDatabaseError(error);
    }
  }

  // ลบซีรีส์จาก SQLite
  Future<void> _deleteSeries(int id) async {
    try {
      await DatabaseHelper.delete(id);
      await _loadSeries();
    } catch (error) {
      _showDatabaseError(error);
    }
  }

  List<SeriesItem> get filteredSeries {
    final query = _searchQuery.trim().toLowerCase();

    if (query.isEmpty) return _seriesList;

    return _seriesList.where((item) {
      return item.title.toLowerCase().contains(query);
    }).toList();
  }

  void _showDatabaseError(Object error) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('จัดการข้อมูลไม่สำเร็จ: $error')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('ซีรีส์ที่อยากดู (${_seriesList.length})')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'ค้นหาชื่อซีรีส์...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      ),
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: _seriesList.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.movie_outlined,
                          size: 80,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'ยังไม่มีซีรีส์',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'กดปุ่ม + เพื่อเพิ่มซีรีส์เรื่องแรก',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : filteredSeries.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 80, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'ไม่พบซีรีส์ที่ค้นหา',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredSeries.length,
                    itemBuilder: (context, i) {
                      final item = filteredSeries[i];

                      return Card(
                        color: colors[i % colors.length].withValues(
                          alpha: 0.50,
                        ),
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: ListTile(
                          leading: Icon(
                            Icons.movie,
                            color: colors[i % colors.length],
                          ),
                          title: Text(item.title),
                          subtitle: Text(
                            '${item.date} • ${item.rating} ดาว\n${item.content}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.blue,
                                ),
                                onPressed: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          AddSeriesPage(existing: item),
                                    ),
                                  );

                                  if (result != null && result is SeriesItem) {
                                    await _updateSeries(result);
                                  }
                                },
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('ลบซีรีส์?'),
                                      content: Text(
                                        'ต้องการลบ "${item.title}" ใช่ไหม',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, false),
                                          child: const Text('ยกเลิก'),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, true),
                                          child: const Text(
                                            'ลบ',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirm == true && item.id != null) {
                                    await _deleteSeries(item.id!);
                                  }
                                },
                              ),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    SeriesDetailPage(series: item),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddSeriesPage()),
          );

          if (result != null && result is SeriesItem) {
            await _addSeries(result);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

// หน้ารายละเอียดซีรีส์
class SeriesDetailPage extends StatelessWidget {
  final SeriesItem series;

  const SeriesDetailPage({super.key, required this.series});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('รายละเอียดซีรีส์')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    width: 220,
                    child: AspectRatio(
                      aspectRatio: 2 / 3,
                      child: _buildSeriesImage(series.image),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                series.title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                series.date,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.orange),
                  const SizedBox(width: 6),
                  Text(
                    '${series.rating} / 5.0',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
              const Divider(height: 32),
              Text(
                series.content,
                style: const TextStyle(fontSize: 16, height: 1.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _buildSeriesImage(String image) {
  if (image.isEmpty) {
    return Container(
      color: Colors.grey.shade300,
      child: const Icon(Icons.movie, size: 60, color: Colors.grey),
    );
  }

  return Image.file(File(image), fit: BoxFit.cover);
}

// หน้าฟอร์มเพิ่มและแก้ไขซีรีส์
class AddSeriesPage extends StatefulWidget {
  final SeriesItem? existing;

  const AddSeriesPage({super.key, this.existing});

  @override
  State<AddSeriesPage> createState() => _AddSeriesPageState();
}

class _AddSeriesPageState extends State<AddSeriesPage> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String _selectedImage = '';

  // Dropdown คะแนน
  double _selectedRating = 5.0;

  final List<double> _ratings = [1.0, 2.0, 3.0, 4.0, 4.5, 5.0];

  // DatePicker
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();

    // ถ้าเป็นโหมดแก้ไข ให้แสดงข้อมูลเดิม
    if (widget.existing != null) {
      _titleController.text = widget.existing!.title;
      _contentController.text = widget.existing!.content;
      _selectedImage = widget.existing!.image;
      _selectedRating = widget.existing!.rating;

      _selectedDate =
          DateTime.tryParse(widget.existing!.date) ?? DateTime.now();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existing == null ? 'เพิ่มซีรีส์ใหม่' : 'แก้ไขข้อมูลซีรีส์',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // ช่องกรอกชื่อซีรีส์
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

              // ช่องกรอกเรื่องย่อ
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

              // Dropdown เลือกคะแนน
              DropdownButtonFormField<double>(
                initialValue: _selectedRating,
                decoration: const InputDecoration(
                  labelText: 'คะแนนซีรีส์',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.star),
                ),
                items: _ratings.map((rating) {
                  return DropdownMenuItem<double>(
                    value: rating,
                    child: Text('$rating ดาว'),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedRating = value;
                    });
                  }
                },
              ),

              const SizedBox(height: 16),

              // DatePicker
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today),
                title: Text(
                  'วันที่: ${_selectedDate.toString().substring(0, 10)}',
                ),
                trailing: const Icon(Icons.edit),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );

                  if (picked != null) {
                    setState(() {
                      _selectedDate = picked;
                    });
                  }
                },
              ),

              const SizedBox(height: 16),

              // รูปภาพจากไฟล์เครื่อง
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
                    // ตรวจทุกช่องในฟอร์มก่อน เพื่อให้ช่องที่เว้นว่างแสดง
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

                    final newSeries = SeriesItem(
                      id: widget.existing?.id,
                      title: _titleController.text.trim(),
                      content: _contentController.text.trim(),
                      date: _selectedDate.toString().substring(0, 10),
                      rating: _selectedRating,
                      image: _selectedImage,
                    );

                    Navigator.pop(context, newSeries);
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

// class AboutPage extends StatelessWidget {
//   const AboutPage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('เกี่ยวกับ')),
//       body: Center(
//         child: Padding(
//           padding: const EdgeInsets.all(24),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               const CircleAvatar(
//                 // << รูปวงกลม (ใช้ไอคอนแทนรูปก่อน)
//                 radius: 50,
//                 backgroundColor: Color.fromARGB(255, 226, 17, 115),
//                 child: Icon(Icons.movie, size: 50, color: Colors.white),
//               ),
//               const SizedBox(height: 20),
//               const Text(
//                 'My Series Watchlist',
//                 style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
//               ),
//               const SizedBox(height: 8),
//               const Text('รายการซีรีส์ที่อยากดู'),
//               const SizedBox(height: 4),
//               const Text('สร้างโดย [Bootsabong Nakpan]'), // << ใส่ชื่อตัวเอง
//               const Text('รหัสนักศึกษา [67011212042]'), // << ใส่รหัส
//               const SizedBox(height: 16),
//               const Text('เวอร์ชัน 1.0', style: TextStyle(color: Colors.grey)),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('เกี่ยวกับ'), centerTitle: true),
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        color: const Color.fromARGB(255, 255, 247, 250),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 55,
              backgroundColor: Color.fromARGB(255, 226, 17, 115),
              child: Icon(Icons.movie_creation, size: 55, color: Colors.white),
            ),

            const SizedBox(height: 20),

            const Text(
              'My Series Watchlist',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 120, 30, 65),
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'รายการซีรีส์ที่อยากดู',
              style: TextStyle(
                fontSize: 16,
                color: Color.fromARGB(255, 110, 90, 98),
              ),
            ),

            const SizedBox(height: 24),

            Card(
              color: const Color.fromARGB(255, 255, 230, 239),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.person,
                          color: Color.fromARGB(255, 226, 17, 115),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Bootsabong Nakpan',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color.fromARGB(255, 70, 50, 58),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const Divider(height: 28),

                    const Row(
                      children: [
                        Icon(
                          Icons.badge,
                          color: Color.fromARGB(255, 226, 17, 115),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'รหัสนักศึกษา 67011212042',
                            style: TextStyle(
                              fontSize: 16,
                              color: Color.fromARGB(255, 70, 50, 58),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline, size: 18, color: Colors.grey),
                SizedBox(width: 6),
                Text('เวอร์ชัน 1.0', style: TextStyle(color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/*
คำถามท้ายงาน

1. ListView.builder กับการเขียน Column ใส่ Card ทีละอันเอง ต่างกันยังไง?
ตอบ: ListView.builder เหมาะกับข้อมูลจำนวนมาก เพราะสร้างรายการตามจำนวนข้อมูลและเลื่อนได้ ส่วน Column ต้องเขียน Card เองทีละอัน ถ้าข้อมูลเยอะจะไม่สะดวกและอาจล้นหน้าจอ

2. ตอนแตะรายการเพื่อเปิดหน้ารายละเอียด ข้อมูลถูกส่งไปหน้าใหม่ได้อย่างไร?
ตอบ: ส่งข้อมูลผ่าน constructor ของหน้า SeriesDetailPage โดยใช้ Navigator.push และ MaterialPageRoute แล้วส่ง series: seriesList[i] ไปยังหน้ารายละเอียด

3. ตอนนี้ถ้าอยากเพิ่มรายการใหม่ ต้องทำยังไง? สะดวกไหม?
ตอบ: ตอนนี้ต้องเพิ่มข้อมูลเองในโค้ดตรง List seriesList ซึ่งยังไม่สะดวก สัปดาห์หน้าน่าจะทำหน้าฟอร์มเพิ่มข้อมูล และใช้ StatefulWidget เพื่อเพิ่ม ลบ หรือแก้ไขรายการได้จริง
*/
