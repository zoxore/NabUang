class CategoryModel {
  final String id;
  final String nama;
  final String tipe; // 'Pemasukan' | 'Pengeluaran'
  final String icon;

  const CategoryModel({
    required this.id,
    required this.nama,
    required this.tipe,
    this.icon = '📦',
  });

  factory CategoryModel.fromMap(String id, Map<String, dynamic> map) {
    return CategoryModel(
      id: id,
      nama: map['nama'] as String,
      tipe: map['tipe'] as String,
      icon: map['icon'] as String? ?? '📦',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nama': nama,
      'tipe': tipe,
      'icon': icon,
    };
  }

  CategoryModel copyWith({
    String? id,
    String? nama,
    String? tipe,
    String? icon,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      nama: nama ?? this.nama,
      tipe: tipe ?? this.tipe,
      icon: icon ?? this.icon,
    );
  }

  // Dummy data for UI development
  static List<CategoryModel> dummyList = [
    // Pengeluaran
    const CategoryModel(id: '1', nama: 'Makan & Minum', tipe: 'Pengeluaran', icon: '🍔'),
    const CategoryModel(id: '2', nama: 'Transport', tipe: 'Pengeluaran', icon: '🚗'),
    const CategoryModel(id: '3', nama: 'Belanja', tipe: 'Pengeluaran', icon: '🛍️'),
    const CategoryModel(id: '4', nama: 'Hiburan', tipe: 'Pengeluaran', icon: '🎮'),
    const CategoryModel(id: '5', nama: 'Kesehatan', tipe: 'Pengeluaran', icon: '💊'),
    const CategoryModel(id: '6', nama: 'Tagihan', tipe: 'Pengeluaran', icon: '🧾'),
    // Pemasukan
    const CategoryModel(id: '7', nama: 'Gaji', tipe: 'Pemasukan', icon: '💼'),
    const CategoryModel(id: '8', nama: 'Freelance', tipe: 'Pemasukan', icon: '💻'),
    const CategoryModel(id: '9', nama: 'Investasi', tipe: 'Pemasukan', icon: '📈'),
    const CategoryModel(id: '10', nama: 'Lainnya', tipe: 'Pemasukan', icon: '💰'),
  ];
}
