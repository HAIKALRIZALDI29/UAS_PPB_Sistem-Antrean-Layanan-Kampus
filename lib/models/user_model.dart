class UserModel {
  final String uid;
  final String nama;
  final String nim;
  final String role;
  final String? layananId;

  const UserModel({
    required this.uid,
    required this.nama,
    required this.nim,
    required this.role,
    this.layananId,
  });

  factory UserModel.fromMap(String uid, Map<String, dynamic> data) {
    return UserModel(
      uid: uid,
      nama: data['nama'] ?? '',
      nim: data['nim'] ?? '',
      role: data['role'] ?? '',
      layananId: data['layananId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nama': nama,
      'nim': nim,
      'role': role,
      if (layananId != null) 'layananId': layananId,
    };
  }
}
