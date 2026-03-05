class ReviewModel {
  final String date;        // yyyy-MM-dd
  final String location;    // 판매 장소
  final String content;     // 판매 소감
  final String author;      // 작성자
  final DateTime createdAt; // 작성 시간

  ReviewModel({
    required this.date,
    required this.location,
    required this.author,
    required this.content,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'date': date,
    'location': location,
    'author': author,
    'content': content,
    'createdAt': createdAt.toIso8601String(),
  };

  factory ReviewModel.fromJson(Map<String, dynamic> json) => ReviewModel(
    date: json['date'],
    location: json['location'],
    author: json['author'],
    content: json['content'],
    createdAt: DateTime.parse(json['createdAt']),
  );
}