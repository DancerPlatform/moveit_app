class DanceStudio {
  final String id;
  final String name;
  final String imageUrl;
  final double rating;
  final int reviewCount;
  final String location;
  final String distance;
  final int pricePerMonth;
  final List<String> genres;
  final bool hasDiscount;
  final int? discountPercent;

  const DanceStudio({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.rating,
    required this.reviewCount,
    required this.location,
    required this.distance,
    required this.pricePerMonth,
    required this.genres,
    this.hasDiscount = false,
    this.discountPercent,
  });
}

class Promotion {
  final String id;
  final String title;
  final String subtitle;
  final String imageUrl;
  final String backgroundColor;
  final int? discountPercent;

  const Promotion({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.backgroundColor,
    this.discountPercent,
  });
}
