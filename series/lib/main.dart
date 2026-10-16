import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import 'api_service.dart';
import 'database_helper.dart';
import 'firebase_options.dart';
import 'firestore_series.dart';
import 'login_page.dart';
import 'logout_button.dart';
import 'rest_api_series_page.dart';
import 'series_item.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Series Watchlist',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE91E63),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFFFF7FA),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFFFE0EB),
          foregroundColor: Color(0xFFAD1457),
          centerTitle: true,
        ),
        cardTheme: const CardThemeData(
          color: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFFE91E63), width: 2),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFFF8BBD0),
          foregroundColor: Color(0xFF880E4F),
        ),
      ),
      home: const AuthGate(),
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

  final List<Widget> _pages = [
    const SeriesListPage(),
    const RestApiSeriesPage(),
    const FirestoreSeriesPage(),
    const AboutPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFFFFF7FA),
        selectedItemColor: const Color.fromARGB(255, 200, 0, 73),
        unselectedItemColor: const Color(0xFF6B5B63),
        selectedFontSize: 12,
        unselectedFontSize: 12,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.movie), label: 'อยากดู'),
          BottomNavigationBarItem(
            icon: Icon(Icons.public),
            label: 'ยังไม่ออนแอร์',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.cloud), label: 'ดูแล้ว'),
          BottomNavigationBarItem(icon: Icon(Icons.info), label: 'เกี่ยวกับ'),
        ],
      ),
    );
  }
}

class SeriesListPage extends StatefulWidget {
  const SeriesListPage({super.key});

  @override
  State<SeriesListPage> createState() => _SeriesListPageState();
}

class _SeriesListPageState extends State<SeriesListPage> {
  List<SeriesItem> _seriesList = [];
  String _searchQuery = '';
  String _selectedCategory = 'ทั้งหมด';
  bool _favoriteOnly = false;
  late Future<Quote> _quoteFuture;
  late Future<SeriesRecommendation> _recommendationFuture;
  int? _lastRecommendationId;

  static const _cardColors = [
    Color(0xFFFFD6E5),
    Color(0xFFE8D7F1),
    Color(0xFFFFE7C2),
    Color(0xFFD9F2EE),
    Color(0xFFE2F0CB),
  ];

  @override
  void initState() {
    super.initState();
    _loadOnlineData();
    _loadSeries();
  }

  void _loadOnlineData() {
    _quoteFuture = ApiService.fetchQuote();
    final recommendationFuture = ApiService.fetchSeriesRecommendation(
      excludeId: _lastRecommendationId,
    );
    _recommendationFuture = recommendationFuture;
    recommendationFuture.then((recommendation) {
      if (!mounted || !identical(_recommendationFuture, recommendationFuture)) {
        return;
      }
      _lastRecommendationId = recommendation.id;
    }, onError: (_) {});
  }

  void _refreshOnlineData() {
    setState(_loadOnlineData);
  }

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

  Future<void> _addSeries(SeriesItem item) async {
    try {
      await DatabaseHelper.insert(item);
      await _loadSeries();
    } catch (error) {
      _showDatabaseError(error);
    }
  }

  Future<void> _updateSeries(SeriesItem item) async {
    try {
      await DatabaseHelper.update(item);
      await _loadSeries();
    } catch (error) {
      _showDatabaseError(error);
    }
  }

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

    return _seriesList.where((item) {
      final matchesSearch = item.title.toLowerCase().contains(query);
      final matchesCategory =
          _selectedCategory == 'ทั้งหมด' || item.category == _selectedCategory;
      final matchesFavorite = !_favoriteOnly || item.isFavorite;

      return matchesSearch && matchesCategory && matchesFavorite;
    }).toList();
  }

  void _showDatabaseError(Object error) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('จัดการข้อมูลไม่สำเร็จ: $error')));
  }

  Future<void> _saveRecommendation(SeriesRecommendation recommendation) async {
    final now = DateTime.now();
    final date =
        '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
    final genres = recommendation.genres.join(' • ');
    final content = genres.isEmpty
        ? recommendation.summary
        : '$genres\n${recommendation.summary}';

    final result = await Navigator.push<SeriesItem>(
      context,
      MaterialPageRoute(
        builder: (_) => AddSeriesPage(
          initial: SeriesItem(
            title: recommendation.title,
            content: content,
            date: date,
            rating: recommendation.rating,
            image: recommendation.imageUrl,
          ),
        ),
      ),
    );

    if (result == null || !mounted) return;

    await _addSeries(result);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('เพิ่ม ${result.title} ลงรายการแล้ว')),
    );
  }

  Future<void> _openAddSeries() async {
    final result = await Navigator.push<SeriesItem>(
      context,
      MaterialPageRoute(builder: (_) => const AddSeriesPage()),
    );

    if (result != null && mounted) {
      await _addSeries(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(scale: animation, child: child),
            );
          },
          child: Text(
            'ซีรีส์ที่อยากดู (${_seriesList.length})',
            key: ValueKey(_seriesList.length),
          ),
        ),
        actions: [
          IconButton(
            onPressed: _refreshOnlineData,
            tooltip: 'โหลดข้อมูลออนไลน์ใหม่',
            icon: const Icon(Icons.refresh),
          ),
          const LogoutButton(),
        ],
      ),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'กรองตามหมวด',
                      border: OutlineInputBorder(),
                    ),
                    items: ['ทั้งหมด', ...seriesCategories].map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedCategory = value);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  avatar: const Icon(Icons.favorite, size: 18),
                  label: const Text('โปรด'),
                  selected: _favoriteOnly,
                  onSelected: (value) {
                    setState(() => _favoriteOnly = value);
                  },
                ),
              ],
            ),
          ),
          FutureBuilder<Quote>(
            future: _quoteFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: CircularProgressIndicator(),
                );
              }

              if (snapshot.hasError || !snapshot.hasData) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'โหลดคำคมไม่ได้ ตรวจสอบอินเทอร์เน็ต',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                      TextButton(
                        onPressed: _refreshOnlineData,
                        child: const Text('ลองใหม่'),
                      ),
                    ],
                  ),
                );
              }

              final quote = snapshot.data!;
              return Card(
                margin: const EdgeInsets.fromLTRB(12, 4, 12, 4),
                color: const Color(0xFFFFF1F5),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Column(
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.format_quote,
                            color: Colors.pink,
                            size: 20,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'แรงบันดาลใจวันนี้',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '"${quote.text}"',
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontStyle: FontStyle.italic,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '— ${quote.author}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          FutureBuilder<SeriesRecommendation>(
            future: _recommendationFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: LinearProgressIndicator(),
                );
              }

              if (snapshot.hasError || !snapshot.hasData) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'โหลดซีรีส์แนะนำไม่ได้',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                      TextButton(
                        onPressed: _refreshOnlineData,
                        child: const Text('ลองใหม่'),
                      ),
                    ],
                  ),
                );
              }

              final recommendation = snapshot.data!;
              return Card(
                margin: const EdgeInsets.fromLTRB(12, 4, 12, 6),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: SizedBox(
                          width: 56,
                          height: 80,
                          child: recommendation.imageUrl.isEmpty
                              ? const ColoredBox(
                                  color: Color(0xFFEDEDED),
                                  child: Icon(Icons.movie, color: Colors.grey),
                                )
                              : Image.network(
                                  recommendation.imageUrl,
                                  fit: BoxFit.cover,
                                  loadingBuilder:
                                      (context, child, loadingProgress) {
                                        if (loadingProgress == null) {
                                          return child;
                                        }
                                        return const Center(
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        );
                                      },
                                  errorBuilder: (context, error, stackTrace) =>
                                      const ColoredBox(
                                        color: Color(0xFFEDEDED),
                                        child: Icon(
                                          Icons.broken_image,
                                          color: Colors.grey,
                                        ),
                                      ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'ซีรีส์แนะนำจากอินเทอร์เน็ต',
                              style: TextStyle(
                                color: Colors.pink,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              recommendation.title,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            if (recommendation.rating > 0)
                              Row(
                                children: [
                                  const Icon(
                                    Icons.star,
                                    size: 14,
                                    color: Colors.orange,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    '${recommendation.rating} / 10',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            const SizedBox(height: 2),
                            Text(
                              recommendation.summary.isEmpty
                                  ? 'ยังไม่มีเรื่องย่อ'
                                  : recommendation.summary,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            OutlinedButton.icon(
                              onPressed: () =>
                                  _saveRecommendation(recommendation),
                              icon: const Icon(Icons.add),
                              label: const Text(
                                'เพิ่มลงรายการ',
                                style: TextStyle(fontSize: 12),
                              ),
                              style: OutlinedButton.styleFrom(
                                minimumSize: Size.zero,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          Expanded(
            child: _seriesList.isEmpty
                ? _AnimatedEmptyState(
                    icon: Icons.movie_outlined,
                    title: 'ยังไม่มีซีรีส์',
                    subtitle: 'เริ่มสร้างรายการของคุณได้เลย',
                    actionLabel: 'เพิ่มซีรีส์เรื่องแรก',
                    onAction: _openAddSeries,
                  )
                : filteredSeries.isEmpty
                ? const _AnimatedEmptyState(
                    icon: Icons.search_off,
                    title: 'ไม่พบซีรีส์ที่ค้นหา',
                    subtitle: 'ลองเปลี่ยนคำค้นหาหรือหมวดหมู่',
                  )
                : ListView.builder(
                    itemCount: filteredSeries.length,
                    itemBuilder: (context, i) {
                      final item = filteredSeries[i];

                      return TweenAnimationBuilder<double>(
                        key: ValueKey(item.id ?? item.title),
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: Duration(milliseconds: 300 + (i * 80)),
                        curve: Curves.easeOut,
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(0, 16 * (1 - value)),
                              child: child,
                            ),
                          );
                        },
                        child: Card(
                          color: _cardColors[i % _cardColors.length],
                          margin: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          child: ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: SizedBox(
                                width: 56,
                                height: 72,
                                child: _buildSeriesImage(item.image),
                              ),
                            ),
                            title: Text(item.title),
                            subtitle: Text(
                              '${item.category} • ${item.date} • '
                              '${item.rating} / 10 ดาว\n${item.content}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (item.isFavorite)
                                  const Padding(
                                    padding: EdgeInsets.only(right: 4),
                                    child: Icon(
                                      Icons.favorite,
                                      color: Colors.pink,
                                    ),
                                  ),
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

                                    if (result != null &&
                                        result is SeriesItem) {
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
                                              style: TextStyle(
                                                color: Colors.red,
                                              ),
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
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddSeries,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _AnimatedEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _AnimatedEmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutBack,
        builder: (context, value, child) {
          final opacity = value.clamp(0.0, 1.0).toDouble();
          return Opacity(
            opacity: opacity,
            child: Transform.scale(scale: 0.9 + (value * 0.1), child: child),
          );
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 72, color: const Color(0xFFD81B60)),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: Color(0xFF880E4F),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF6D4C5B)),
            ),
            if (onAction != null && actionLabel != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.playlist_add),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class SeriesDetailPage extends StatelessWidget {
  final SeriesItem series;

  const SeriesDetailPage({super.key, required this.series});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('รายละเอียดซีรีส์'),
        actions: const [LogoutButton()],
      ),
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
                    '${series.rating} / 10 คะแนน',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.category, color: Colors.purple),
                  const SizedBox(width: 6),
                  Text(
                    'หมวดหมู่: ${series.category}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    series.isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: Colors.pink,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    series.isFavorite
                        ? 'รายการโปรด'
                        : 'ยังไม่ได้เพิ่มเป็นรายการโปรด',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
              const Divider(height: 32),
              const Text(
                'เรื่องย่อหรือความรู้สึก',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
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

  if (image.startsWith('http://') || image.startsWith('https://')) {
    return Image.network(
      image,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return const Center(child: CircularProgressIndicator(strokeWidth: 2));
      },
      errorBuilder: (context, error, stackTrace) => Container(
        color: Colors.grey.shade300,
        child: const Icon(Icons.broken_image, size: 60, color: Colors.grey),
      ),
    );
  }

  return Image.file(File(image), fit: BoxFit.cover);
}

class AddSeriesPage extends StatefulWidget {
  final SeriesItem? existing;
  final SeriesItem? initial;

  const AddSeriesPage({super.key, this.existing, this.initial});

  @override
  State<AddSeriesPage> createState() => _AddSeriesPageState();
}

class _AddSeriesPageState extends State<AddSeriesPage> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String _selectedImage = '';

  double _selectedRating = 5.0;
  String _selectedCategory = 'ทั่วไป';
  bool _isFavorite = false;

  List<double> get _ratings {
    final ratings = List<double>.generate(
      101,
      (index) => double.parse((index / 10).toStringAsFixed(1)),
    );
    if (!ratings.contains(_selectedRating)) {
      ratings.add(_selectedRating);
      ratings.sort();
    }
    return ratings;
  }

  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();

    final source = widget.existing ?? widget.initial;
    if (source != null) {
      _titleController.text = source.title;
      _contentController.text = source.content;
      _selectedImage = source.image;
      _selectedRating = source.rating;
      _selectedCategory = source.category;
      _isFavorite = source.isFavorite;

      _selectedDate = DateTime.tryParse(source.date) ?? DateTime.now();
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
        actions: const [LogoutButton()],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
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
                    setState(() {
                      _selectedRating = value;
                    });
                  }
                },
              ),

              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'หมวดหมู่',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: seriesCategories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedCategory = value);
                  }
                },
              ),

              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('รายการโปรด'),
                secondary: const Icon(Icons.favorite, color: Colors.pink),
                value: _isFavorite,
                onChanged: (value) {
                  setState(() => _isFavorite = value);
                },
              ),

              const SizedBox(height: 8),

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

                    final newSeries = SeriesItem(
                      id: widget.existing?.id,
                      title: _titleController.text.trim(),
                      content: _contentController.text.trim(),
                      date: _selectedDate.toString().substring(0, 10),
                      rating: _selectedRating,
                      image: _selectedImage,
                      category: _selectedCategory,
                      isFavorite: _isFavorite,
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

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('เกี่ยวกับ'),
        centerTitle: true,
        actions: const [LogoutButton()],
      ),
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
