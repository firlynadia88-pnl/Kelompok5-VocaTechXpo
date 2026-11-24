/// Model data untuk tabel `profiles`.
///
/// Kolom diselaraskan dengan struktur profil Voca-TechXpo:
/// id, username, nim, email, phone, jurusan, prodi, angkatan, role,
/// ukm, avatar_url, bio, created_at, dan updated_at.
class ProfileModel {
  final String id;
  final String username;
  final String nim;
  final String email;
  final String phone;
  final String jurusan;
  final String prodi;
  final String angkatan;
  final String role;
  final String ukm;
  final String? avatarUrl;
  final String? bio;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ProfileModel({
    required this.id,
    this.username = '',
    this.nim = '',
    this.email = '',
    this.phone = '',
    this.jurusan = '',
    this.prodi = '',
    this.angkatan = '',
    this.role = 'mahasiswa',
    this.ukm = '',
    this.avatarUrl,
    this.bio,
    this.createdAt,
    this.updatedAt,
  });

  factory ProfileModel.fromMap(Map<String, dynamic> map) {
    return ProfileModel(
      id: (map['id'] ?? '').toString(),
      username: (map['username'] ?? '').toString(),
      nim: (map['nim'] ?? '').toString(),
      email: (map['email'] ?? '').toString(),
      phone: (map['phone'] ?? '').toString(),
      jurusan: (map['jurusan'] ?? '').toString(),
      prodi: (map['prodi'] ?? '').toString(),
      angkatan: (map['angkatan'] ?? '').toString(),
      role: (map['role'] ?? 'mahasiswa').toString(),
      ukm: (map['ukm'] ?? '').toString(),
      avatarUrl: map['avatar_url']?.toString(),
      bio: map['bio']?.toString(),
      createdAt: _asDateTime(map['created_at']),
      updatedAt: _asDateTime(map['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'nim': nim,
      'email': email,
      'phone': phone,
      'jurusan': jurusan,
      'prodi': prodi,
      'angkatan': angkatan,
      'role': role,
      'ukm': ukm,
      'avatar_url': avatarUrl,
      'bio': bio,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  static DateTime? _asDateTime(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}
