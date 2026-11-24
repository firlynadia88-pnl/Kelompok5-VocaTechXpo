/// Model data untuk tabel `promotions` (Banner Promosi Spesial).
class PromotionModel {
  final String? id;
  final String? ownerId;
  final String title;
  final String? ukm;
  final String? bannerUrl;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const PromotionModel({
    this.id,
    this.ownerId,
    required this.title,
    this.ukm,
    this.bannerUrl,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory PromotionModel.fromMap(Map<String, dynamic> map) {
    return PromotionModel(
      id: map['id']?.toString(),
      ownerId: map['owner_id']?.toString(),
      title: (map['title'] ?? '').toString(),
      ukm: map['ukm']?.toString(),
      bannerUrl: map['banner_url']?.toString(),
      isActive: _asBool(map['is_active']),
      createdAt: _asDateTime(map['created_at']),
      updatedAt: _asDateTime(map['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (ownerId != null) 'owner_id': ownerId,
      'title': title,
      'ukm': ukm,
      'banner_url': bannerUrl,
      'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  static bool _asBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final text = value?.toString().toLowerCase();
    return text == 'true' || text == '1';
  }

  static DateTime? _asDateTime(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}
