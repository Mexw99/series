class SeriesItem {
  final int? id;
  final String title;
  final String content;
  final String date;
  final double rating;
  final String image;
  final String category;
  final bool isFavorite;

  const SeriesItem({
    this.id,
    required this.title,
    required this.content,
    required this.date,
    required this.rating,
    required this.image,
    this.category = 'ทั่วไป',
    this.isFavorite = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'date': date,
      'rating': rating,
      'image': image,
      'category': category,
      'isFavorite': isFavorite ? 1 : 0,
    };
  }

  factory SeriesItem.fromMap(Map<String, dynamic> map) {
    return SeriesItem(
      id: map['id'],
      title: map['title'],
      content: map['content'],
      date: map['date'],
      rating: (map['rating'] as num).toDouble(),
      image: map['image'] ?? '',
      category: map['category'] as String? ?? 'ทั่วไป',
      isFavorite: map['isFavorite'] == 1,
    );
  }
}

const seriesCategories = [
  'ทั่วไป',
  'โรแมนติก',
  'ดราม่า',
  'แอ็กชัน',
  'คอมเมดี้',
];
