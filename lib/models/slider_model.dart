class SliderModel {
  final int sliderID;
  final String title;
  final String subtitle;
  final String actionButton;
  final String description;
  final String createdAt;
  final String updatedAt;
  final String imagePath;
  final List<String> images;

  SliderModel({
    required this.sliderID,
    required this.title,
    required this.subtitle,
    required this.actionButton,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
    required this.imagePath,
    required this.images,
  });

  // Get full image URLs
  List<String> get imageUrls {
    return images.map((image) => '$imagePath/$image').toList();
  }

  factory SliderModel.fromJson(Map<String, dynamic> json) {
    return SliderModel(
      sliderID: json['SliderID'] ?? 0,
      title: json['Title'] ?? '',
      subtitle: json['Subtitle'] ?? '',
      actionButton: json['ActionButton'] ?? '',
      description: json['Description'] ?? '',
      createdAt: json['Create_At'] ?? '',
      updatedAt: json['Update_At'] ?? '',
      imagePath: json['image_path'] ?? '',
      images: List<String>.from(json['images'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'SliderID': sliderID,
      'Title': title,
      'Subtitle': subtitle,
      'ActionButton': actionButton,
      'Description': description,
      'Create_At': createdAt,
      'Update_At': updatedAt,
      'image_path': imagePath,
      'images': images,
    };
  }

  // Add equality comparison
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SliderModel &&
          runtimeType == other.runtimeType &&
          sliderID == other.sliderID;

  @override
  int get hashCode => sliderID.hashCode;
}

//Correct with 69 line code changes
