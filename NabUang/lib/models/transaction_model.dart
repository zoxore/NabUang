class TransactionModel {
  final String id;
  final String idDompet;
  final String? idDompetTujuan; // untuk Transfer
  final String? idKategori;
  final String tipe; // 'Pemasukan' | 'Pengeluaran' | 'Transfer'
  final double nominal;
  final double fee; // biaya/pajak transfer (default 0)
  final DateTime tanggal;
  final String catatan;
  // Denormalized fields (disimpan ke Firestore agar tidak perlu join)
  final String? namaDompet;
  final String? namaDompetTujuan;
  final String? namaKategori;
  final String? iconKategori;

  const TransactionModel({
    required this.id,
    required this.idDompet,
    this.idDompetTujuan,
    this.idKategori,
    required this.tipe,
    required this.nominal,
    this.fee = 0,
    required this.tanggal,
    this.catatan = '',
    this.namaDompet,
    this.namaDompetTujuan,
    this.namaKategori,
    this.iconKategori,
  });

  factory TransactionModel.fromMap(String id, Map<String, dynamic> map) {
    return TransactionModel(
      id: id,
      idDompet: map['id_dompet'] as String,
      idDompetTujuan: map['id_dompet_tujuan'] as String?,
      idKategori: map['id_kategori'] as String?,
      tipe: map['tipe'] as String,
      nominal: (map['nominal'] as num).toDouble(),
      fee: (map['fee'] as num? ?? 0).toDouble(),
      tanggal: (map['tanggal'] as dynamic).toDate() as DateTime,
      catatan: map['catatan'] as String? ?? '',
      namaDompet: map['nama_dompet'] as String?,
      namaDompetTujuan: map['nama_dompet_tujuan'] as String?,
      namaKategori: map['nama_kategori'] as String?,
      iconKategori: map['icon_kategori'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id_dompet': idDompet,
      'id_dompet_tujuan': idDompetTujuan,
      'id_kategori': idKategori,
      'tipe': tipe,
      'nominal': nominal,
      'fee': fee,
      'tanggal': tanggal,
      'catatan': catatan,
      // Denormalized — disimpan agar mudah ditampilkan
      'nama_dompet': namaDompet,
      'nama_dompet_tujuan': namaDompetTujuan,
      'nama_kategori': namaKategori,
      'icon_kategori': iconKategori,
    };
  }

  TransactionModel copyWith({
    String? id,
    String? idDompet,
    String? idDompetTujuan,
    String? idKategori,
    String? tipe,
    double? nominal,
    double? fee,
    DateTime? tanggal,
    String? catatan,
    String? namaDompet,
    String? namaDompetTujuan,
    String? namaKategori,
    String? iconKategori,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      idDompet: idDompet ?? this.idDompet,
      idDompetTujuan: idDompetTujuan ?? this.idDompetTujuan,
      idKategori: idKategori ?? this.idKategori,
      tipe: tipe ?? this.tipe,
      nominal: nominal ?? this.nominal,
      fee: fee ?? this.fee,
      tanggal: tanggal ?? this.tanggal,
      catatan: catatan ?? this.catatan,
      namaDompet: namaDompet ?? this.namaDompet,
      namaDompetTujuan: namaDompetTujuan ?? this.namaDompetTujuan,
      namaKategori: namaKategori ?? this.namaKategori,
      iconKategori: iconKategori ?? this.iconKategori,
    );
  }

  // Dummy data for UI development
  static List<TransactionModel> dummyList = [
    TransactionModel(
      id: '1',
      idDompet: '1',
      idKategori: '7',
      tipe: 'Pemasukan',
      nominal: 5000000,
      tanggal: DateTime.now(),
      catatan: 'Gaji bulan Mei',
      namaDompet: 'BNI',
      namaKategori: 'Gaji',
      iconKategori: '💼',
    ),
    TransactionModel(
      id: '2',
      idDompet: '2',
      idKategori: '1',
      tipe: 'Pengeluaran',
      nominal: 45000,
      tanggal: DateTime.now().subtract(const Duration(hours: 3)),
      catatan: 'Makan siang bareng teman',
      namaDompet: 'Cash',
      namaKategori: 'Makan & Minum',
      iconKategori: '🍔',
    ),
    TransactionModel(
      id: '3',
      idDompet: '1',
      idDompetTujuan: '3',
      tipe: 'Transfer',
      nominal: 200000,
      tanggal: DateTime.now().subtract(const Duration(days: 1)),
      catatan: 'Top up Dana',
      namaDompet: 'BNI',
      namaDompetTujuan: 'Dana',
    ),
    TransactionModel(
      id: '4',
      idDompet: '3',
      idKategori: '2',
      tipe: 'Pengeluaran',
      nominal: 25000,
      tanggal: DateTime.now().subtract(const Duration(days: 1)),
      catatan: 'Grab ke kantor',
      namaDompet: 'Dana',
      namaKategori: 'Transport',
      iconKategori: '🚗',
    ),
    TransactionModel(
      id: '5',
      idDompet: '1',
      idKategori: '8',
      tipe: 'Pemasukan',
      nominal: 1200000,
      tanggal: DateTime.now().subtract(const Duration(days: 2)),
      catatan: 'Project freelance website',
      namaDompet: 'BNI',
      namaKategori: 'Freelance',
      iconKategori: '💻',
    ),
    TransactionModel(
      id: '6',
      idDompet: '4',
      idKategori: '6',
      tipe: 'Pengeluaran',
      nominal: 150000,
      tanggal: DateTime.now().subtract(const Duration(days: 3)),
      catatan: 'Bayar Indihome',
      namaDompet: 'GoPay',
      namaKategori: 'Tagihan',
      iconKategori: '🧾',
    ),
  ];
}
