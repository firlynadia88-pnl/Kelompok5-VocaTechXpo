/// Model data untuk tabel `booths` (pengajuan booth Organizer).
class BoothModel {
  final String? id;
  final String? ownerId;
  final String name;
  final String businessType;
  final String organizerType;
  final String adminWhatsapp;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const BoothModel({
    this.id,
    this.ownerId,
    required this.name,
    this.businessType = '',
    this.organizerType = '',
    this.adminWhatsapp = '',
    this.status = 'pending',
    this.createdAt,
    this.updatedAt,
  });

  factory BoothModel.fromMap(Map<String, dynamic> map) {
    return BoothModel(
      id: map['id']?.toString(),
      ownerId: map['owner_id']?.toString(),
      name: (map['name'] ?? '').toString(),
      businessType: (map['business_type'] ?? '').toString(),
      organizerType: (map['organizer_type'] ?? '').toString(),
      adminWhatsapp: (map['admin_whatsapp'] ?? '').toString(),
      status: (map['status'] ?? 'pending').toString(),
      createdAt: _asDateTime(map['created_at']),
      updatedAt: _asDateTime(map['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (ownerId != null) 'owner_id': ownerId,
      'name': name,
      'business_type': businessType,
      'organizer_type': organizerType,
      'admin_whatsapp': adminWhatsapp,
      'status': status,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  static DateTime? _asDateTime(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}
