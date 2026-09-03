import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

// แม่พิมพ์ข้อมูลซีรีส์
class SeriesItem {
  final String title;
  final String content;
  final String date;
  final double rating;
  final String image;

  SeriesItem({
    required this.title,
    required this.content,
    required this.date,
    required this.rating,
    required this.image,
  });
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
class SeriesListPage extends StatelessWidget {
  const SeriesListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<SeriesItem> seriesList = [
      SeriesItem(
        title: 'Queen of Tears',
        content: 'ซีรีส์โรแมนติกดราม่าที่อยากดู เพราะกระแสดีและนักแสดงน่าสนใจ',
        date: '10 มิ.ย. 2568',
        rating: 4.8,
        image: 'assets/images/queen_of_tears.jpg',
      ),
      SeriesItem(
        title: 'Moving',
        content:
            'ซีรีส์แนวพลังพิเศษ แอ็กชัน และครอบครัว เนื้อเรื่องดูเข้มข้นมาก',
        date: '12 มิ.ย. 2568',
        rating: 4.7,
        image: 'assets/images/moving.jpg',
      ),
      SeriesItem(
        title: 'The Glory',
        content: 'ซีรีส์ดราม่าแก้แค้นที่หลายคนแนะนำ เนื้อเรื่องดูน่าติดตาม',
        date: '14 มิ.ย. 2568',
        rating: 4.9,
        image: 'assets/images/the_glory.jpg',
      ),
      SeriesItem(
        title: 'Business Proposal',
        content: 'ซีรีส์โรแมนติกคอมเมดี้ ดูเบาสบาย เหมาะกับวันพักผ่อน',
        date: '16 มิ.ย. 2568',
        rating: 4.5,
        image:
            'https://m.media-amazon.com/images/M/MV5BYWM2NTM4MTktNDFiNi00NTI3LThiZTgtZmJiZTQ2NzdhNDE3XkEyXkFqcGc@._V1_.jpg',
      ),
      SeriesItem(
        title: 'All of Us Are Dead',
        content: 'ซีรีส์ซอมบี้ในโรงเรียน น่าดูเพราะลุ้นและตื่นเต้น',
        date: '18 มิ.ย. 2568',
        rating: 4.6,
        image: 'assets/images/all_of_us_are_dead.jpg',
      ),
    ];

    final List<Color> colors = [
      Colors.pink,
      Colors.purple,
      Colors.orange,
      Colors.teal,
      Colors.green,
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('ซีรีส์ที่อยากดู')),
      body: ListView.builder(
        itemCount: seriesList.length,
        itemBuilder: (context, i) {
          return Card(
            color: colors[i % colors.length].withValues(alpha: 0.50),
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              leading: Icon(Icons.movie, color: colors[i % colors.length]),
              title: Text(seriesList[i].title),
              subtitle: Text(
                '${seriesList[i].date} • ${seriesList[i].rating} ดาว',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        SeriesDetailPage(series: seriesList[i]),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ฟีเจอร์เพิ่มซีรีส์ มาสัปดาห์หน้า!')),
          );
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
                      child: series.image.startsWith('http')
                          ? Image.network(
                              series.image,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey.shade300,
                                  child: const Icon(
                                    Icons.broken_image,
                                    size: 60,
                                  ),
                                );
                              },
                            )
                          : Image.asset(
                              series.image,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey.shade300,
                                  child: const Icon(
                                    Icons.broken_image,
                                    size: 60,
                                  ),
                                );
                              },
                            ),
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
