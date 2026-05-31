class WishItem {
  const WishItem({
    required this.id,
    required this.ownerUserId,
    required this.title,
    required this.note,
    required this.category,
    required this.placeText,
    required this.placeUrl,
    required this.visibility,
    required this.createdAt,
  });

  final String id;
  final String ownerUserId;
  final String title;
  final String note;
  final String category;
  final String placeText;
  final String placeUrl;
  final String visibility;
  final DateTime createdAt;
}
