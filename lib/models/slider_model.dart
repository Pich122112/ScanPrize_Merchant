// models/slider_model.dart
class SliderModel {
  final int sliderId;
  final String title;
  final String subtitle;
  final String actionButton;
  final String description;
  final List<String> imageUrls;

  SliderModel({
    required this.sliderId,
    required this.title,
    required this.subtitle,
    required this.actionButton,
    required this.description,
    required this.imageUrls,
  });

  factory SliderModel.fromJson(Map<String, dynamic> json) {
    return SliderModel(
      sliderId: json['SliderID'],
      title: json['Title'] ?? '',
      subtitle: json['Subtitle'] ?? '',
      actionButton: json['ActionButton'] ?? 'Read More',
      description: json['Description'] ?? '',
      imageUrls: List<String>.from(json['ImageUrls'] ?? []),
    );
  }
}

//Correct with 31 line code changes
