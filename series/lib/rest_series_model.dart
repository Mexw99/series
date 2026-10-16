class RestSeriesItem {
  final int? id;
  final String ownerId;
  final String title;
  final String content;
  final String date;
  final double rating;
  final String imageUrl;

  const RestSeriesItem({
    this.id,
    required this.ownerId,
    required this.title,
    required this.content,
    required this.date,
    required this.rating,
    required this.imageUrl,
  });

  factory RestSeriesItem.fromJson(Map<String, dynamic> json) {
    return RestSeriesItem(
      id: (json['id'] as num?)?.toInt(),
      ownerId: json['ownerId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      date: json['date'] as String? ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      imageUrl: json['imageUrl'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ownerId': ownerId,
      'title': title,
      'content': content,
      'date': date,
      'rating': rating,
      'imageUrl': imageUrl,
    };
  }
}
