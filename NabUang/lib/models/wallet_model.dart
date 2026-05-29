class WalletModel {
  final String id;
  final String nama;
  final String jenis; // 'Cash' | 'E-Money'
  final double saldo;

  const WalletModel({
    required this.id,
    required this.nama,
    required this.jenis,
    required this.saldo,
  });

  factory WalletModel.fromMap(String id, Map<String, dynamic> map) {
    return WalletModel(
      id: id,
      nama: map['nama'] as String,
      jenis: map['jenis'] as String,
      saldo: (map['saldo'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nama': nama,
      'jenis': jenis,
      'saldo': saldo,
    };
  }

  WalletModel copyWith({
    String? id,
    String? nama,
    String? jenis,
    double? saldo,
  }) {
    return WalletModel(
      id: id ?? this.id,
      nama: nama ?? this.nama,
      jenis: jenis ?? this.jenis,
      saldo: saldo ?? this.saldo,
    );
  }

  // Dummy data for UI development
  static List<WalletModel> dummyList = [
    const WalletModel(id: '1', nama: 'BNI', jenis: 'E-Money', saldo: 2500000),
    const WalletModel(id: '2', nama: 'Cash', jenis: 'Cash', saldo: 850000),
    const WalletModel(id: '3', nama: 'Dana', jenis: 'E-Money', saldo: 320000),
    const WalletModel(id: '4', nama: 'GoPay', jenis: 'E-Money', saldo: 175000),
  ];
}
