class SliderModel {
  final int id;
  final String title;
  final String subtitle;
  final String description;
  final String url;
  final List<String> imageUrls;

  SliderModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.url,
    required this.imageUrls,
  });

  factory SliderModel.fromJson(Map<String, dynamic> json) {
    print('Parsing slider JSON: $json');

    // Extract image URLs from the images array
    List<String> imageUrls = [];
    if (json['images'] != null && json['images'] is List) {
      imageUrls =
          (json['images'] as List)
              .map((image) => image['image_url']?.toString() ?? '')
              .where((url) => url.isNotEmpty)
              .toList();
    }

    print('Extracted ${imageUrls.length} image URLs');

    return SliderModel(
      id: json['id'] ?? 0,
      title: json['title']?.toString() ?? 'No Title',
      subtitle: json['subtitle']?.toString() ?? 'No Subtitle',
      description: json['description']?.toString() ?? '',
      url: json['url'],
      imageUrls: imageUrls,
    );
  }
  String get actionButton => '';
}

//Correct with 45 line code changes
