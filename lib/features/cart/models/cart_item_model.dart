class CartItemModel {
  final String id;
  final String title;
  final String author;
  final String imageUrl;
  final int originalPrice;
  final int discountedPrice;

  CartItemModel({
    required this.id,
    required this.title,
    required this.author,
    required this.imageUrl,
    required this.originalPrice,
    required this.discountedPrice,
  });

  factory CartItemModel.fromMap(String id, Map<String, dynamic> map) {
    return CartItemModel(
      id: id,
      title: map['title'] ?? '',
      author: map['author'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      originalPrice: map['originalPrice'] ?? 0,
      discountedPrice: map['discountedPrice'] ?? 0,
    );
  }
}