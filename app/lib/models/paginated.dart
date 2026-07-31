class Paginated<T> {
  final List<T> items;
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  Paginated({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  factory Paginated.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    return Paginated<T>(
      items: (json['items'] as List)
          .map((e) => fromJsonT(e as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int,
      page: json['page'] as int,
      limit: json['limit'] as int,
      totalPages: json['totalPages'] as int,
    );
  }
}
