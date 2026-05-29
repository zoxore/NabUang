class BillModel {
  final String id;
  final String nama;
  final double nominal;
  final DateTime jatuhTempo;
  final bool sudahDibayar;
  final String? catatan;
  final String? idTransaksi; // ID transaksi yang dibuat saat dibayar

  const BillModel({
    required this.id,
    required this.nama,
    required this.nominal,
    required this.jatuhTempo,
    this.sudahDibayar = false,
    this.catatan,
    this.idTransaksi,
  });

  factory BillModel.fromMap(String id, Map<String, dynamic> map) {
    return BillModel(
      id: id,
      nama: map['nama'] as String,
      nominal: (map['nominal'] as num).toDouble(),
      jatuhTempo: (map['jatuh_tempo'] as dynamic).toDate() as DateTime,
      sudahDibayar: map['sudah_dibayar'] as bool? ?? false,
      catatan: map['catatan'] as String?,
      idTransaksi: map['id_transaksi'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nama': nama,
      'nominal': nominal,
      'jatuh_tempo': jatuhTempo,
      'sudah_dibayar': sudahDibayar,
      'catatan': catatan,
      'id_transaksi': idTransaksi,
    };
  }

  BillModel copyWith({
    String? id,
    String? nama,
    double? nominal,
    DateTime? jatuhTempo,
    bool? sudahDibayar,
    String? catatan,
    String? idTransaksi,
  }) {
    return BillModel(
      id: id ?? this.id,
      nama: nama ?? this.nama,
      nominal: nominal ?? this.nominal,
      jatuhTempo: jatuhTempo ?? this.jatuhTempo,
      sudahDibayar: sudahDibayar ?? this.sudahDibayar,
      catatan: catatan ?? this.catatan,
      idTransaksi: idTransaksi ?? this.idTransaksi,
    );
  }

  /// Apakah sudah lewat jatuh tempo (dan belum dibayar)?
  bool get isOverdue =>
      !sudahDibayar && jatuhTempo.isBefore(DateTime.now());

  /// Sisa hari sampai jatuh tempo (negatif = sudah lewat)
  int get sisaHari => jatuhTempo.difference(DateTime.now()).inDays;
}
