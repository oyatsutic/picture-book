class Book {
  final String id;
  final String name;
  final String description;
  final String animationThumbUrl;
  final String animationUrl;
  final double price;
  final String publish;
  final List<String> purchased;
  final String modifiedAt;
  final double size;
  final PdfFile pdfFile;
  final List<AudioFile> audioFiles;

  Book({
    required this.id,
    required this.name,
    required this.description,
    required this.animationThumbUrl,
    required this.animationUrl,
    required this.price,
    required this.publish,
    required this.purchased,
    required this.modifiedAt,
    required this.size,
    required this.pdfFile,
    required this.audioFiles,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      animationThumbUrl: json['animationThumbUrl'] ?? '',
      animationUrl: json['animationUrl'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      publish: json['publish'] ?? '',
      purchased: List<String>.from(json['purchased'] ?? []),
      modifiedAt: json['modifiedAt'] ?? '',
      size: (json['size'] ?? 0).toDouble(),
      pdfFile: PdfFile.fromJson(json['pdfFile'] ?? {}),
      audioFiles: (json['audioFiles'] as List<dynamic>?)
          ?.map((audio) => AudioFile.fromJson(audio))
          .toList() ?? [],
    );
  }
}

class PdfFile {
  final String name;
  final double size;
  final String url;

  PdfFile({
    required this.name,
    required this.size,
    required this.url,
  });

  factory PdfFile.fromJson(Map<String, dynamic> json) {
    return PdfFile(
      name: json['name'] ?? '',
      size: (json['size'] ?? 0).toDouble(),
      url: json['url'] ?? '',
    );
  }
}

class AudioFile {
  final String name;
  final double size;
  final String url;
  final String id;

  AudioFile({
    required this.name,
    required this.size,
    required this.url,
    required this.id,
  });

  factory AudioFile.fromJson(Map<String, dynamic> json) {
    return AudioFile(
      name: json['name'] ?? '',
      size: (json['size'] ?? 0).toDouble(),
      url: json['url'] ?? '',
      id: json['_id'] ?? '',
    );
  }
} 