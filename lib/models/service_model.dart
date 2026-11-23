class ServiceModel {
  final String id;
  final String nama;
  final String lokasi;
  final bool isOpen;
  final String jamBuka;
  final String jamTutup;
  final int estimasiMenit;

  // Daftar keperluan yang tersedia pada unit layanan
  final List<String> keperluan;

  const ServiceModel({
    required this.id,
    required this.nama,
    required this.lokasi,
    required this.isOpen,
    required this.jamBuka,
    required this.jamTutup,
    required this.estimasiMenit,
    this.keperluan = const [],
  });

  // Mengubah data Firestore menjadi ServiceModel
  factory ServiceModel.fromMap(String id, Map<String, dynamic> data) {
    final keperluanData = data['keperluan'];

    return ServiceModel(
      id: id,
      nama: data['nama'] ?? '',
      lokasi: data['lokasi'] ?? '',
      isOpen: data['isOpen'] ?? false,
      jamBuka: data['jamBuka'] ?? '',
      jamTutup: data['jamTutup'] ?? '',
      estimasiMenit: (data['estimasiMenit'] as num?)?.toInt() ?? 0,

      keperluan: keperluanData is List
          ? keperluanData.map((item) => item.toString()).toList()
          : const [],
    );
  }

  // Mengubah ServiceModel menjadi Map untuk Firestore
  Map<String, dynamic> toMap() {
    return {
      'nama': nama,
      'lokasi': lokasi,
      'isOpen': isOpen,
      'jamBuka': jamBuka,
      'jamTutup': jamTutup,
      'estimasiMenit': estimasiMenit,
      'keperluan': keperluan,
    };
  }
}
