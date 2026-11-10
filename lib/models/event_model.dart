/// Model data untuk tabel `booth_events`.
///
/// Nama kolom mengikuti pemakaian Supabase pada kode Voca-TechXpo:
/// event_name, category, event_date, booth_count, location, price,
/// description, poster_url, display_section, ukm_name, layout_config,
/// status, owner_id, dan timestamp.
class EventModel {
  final String? id;
  final String? ownerId;
  final String eventName;
  final String category;
  final String eventDate;
  final int boothCount;
  final String location;
  final String price;
  final String description;
  final String? posterUrl;
  final String? displaySection;
  final String? ukmName;
  final Map<String, dynamic> layoutConfig;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const EventModel({
    this.id,
    this.ownerId,
    required this.eventName,
    required this.category,
    required this.eventDate,
    this.boothCount = 0,
    this.location = '',
    this.price = '',
    this.description = '',
    this.posterUrl,
    this.displaySection,
    this.ukmName,
    this.layoutConfig = const {},
    this.status = 'pending',
    this.createdAt,
    this.updatedAt,
  });

  factory EventModel.fromMap(Map<String, dynamic> map) {
    return EventModel(
      id: map['id']?.toString(),
      ownerId: map['owner_id']?.toString(),
      eventName: (map['event_name'] ?? '').toString(),
      category: (map['category'] ?? '').toString(),
      eventDate: (map['event_date'] ?? '').toString(),
      boothCount: _asInt(map['booth_count']),
      location: (map['location'] ?? '').toString(),
      price: (map['price'] ?? '').toString(),
      description: (map['description'] ?? '').toString(),
      posterUrl: map['poster_url']?.toString(),
      displaySection: map['display_section']?.toString(),
      ukmName: map['ukm_name']?.toString(),
      layoutConfig: _asMap(map['layout_config']),
      status: (map['status'] ?? 'pending').toString(),
      createdAt: _asDateTime(map['created_at']),
      updatedAt: _asDateTime(map['updated_at']),
    );
  }

  /// Menghasilkan nama kolom yang sama dengan tabel `booth_events`.
  /// ID dan timestamp disertakan hanya jika nilainya tersedia.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (ownerId != null) 'owner_id': ownerId,
      'event_name': eventName,
      'category': category,
      'event_date': eventDate,
      'booth_count': boothCount,
      'location': location,
      'price': price,
      'description': description,
      'poster_url': posterUrl,
      'display_section': displaySection,
      'ukm_name': ukmName,
      'layout_config': layoutConfig,
      'status': status,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  static DateTime? _asDateTime(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}
