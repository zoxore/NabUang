import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/wallet_model.dart';
import '../models/transaction_model.dart';
import '../models/bill_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── Referensi koleksi ─────────────────────────────────────────────────────

  CollectionReference _wallets(String uid) =>
      _db.collection('users').doc(uid).collection('wallets');

  CollectionReference _transactions(String uid) =>
      _db.collection('users').doc(uid).collection('transactions');

  CollectionReference _bills(String uid) =>
      _db.collection('users').doc(uid).collection('bills');

  // ─── WALLET STREAMS ────────────────────────────────────────────────────────

  Stream<List<WalletModel>> walletsStream(String uid) {
    return _wallets(uid).snapshots().map((snap) => snap.docs
        .map((doc) =>
            WalletModel.fromMap(doc.id, doc.data() as Map<String, dynamic>))
        .toList());
  }

  // ─── TRANSACTION STREAMS ───────────────────────────────────────────────────

  Stream<List<TransactionModel>> transactionsStream(String uid) {
    return _transactions(uid)
        .orderBy('tanggal', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => TransactionModel.fromMap(
                doc.id, doc.data() as Map<String, dynamic>))
            .toList());
  }

  // ─── BILL STREAMS ──────────────────────────────────────────────────────────

  Stream<List<BillModel>> billsStream(String uid) {
    return _bills(uid)
        .orderBy('jatuh_tempo', descending: false)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) =>
                BillModel.fromMap(doc.id, doc.data() as Map<String, dynamic>))
            .toList());
  }

  // ─── WALLET CRUD ───────────────────────────────────────────────────────────

  Future<void> addWallet(String uid, WalletModel wallet) async {
    // 1. Tambah dompet
    final walletRef = await _wallets(uid).add(wallet.toMap());

    // 2. Jika ada saldo awal → buat transaksi Pemasukan "Saldo Awal"
    if (wallet.saldo > 0) {
      await _transactions(uid).add({
        'id_dompet': walletRef.id,
        'id_dompet_tujuan': null,
        'id_kategori': null,
        'tipe': 'Pemasukan',
        'nominal': wallet.saldo,
        'tanggal': DateTime.now(),
        'catatan': 'Saldo awal ${wallet.nama}',
        'nama_kategori': 'Saldo Awal',
        'icon_kategori': '🏦',
      });
    }
  }

  Future<void> updateWallet(String uid, WalletModel wallet) async {
    await _wallets(uid).doc(wallet.id).update({
      'nama': wallet.nama,
      'jenis': wallet.jenis,
    });
  }

  Future<void> deleteWallet(String uid, String walletId) async {
    // Hapus dompet beserta semua transaksinya
    final batch = _db.batch();
    batch.delete(_wallets(uid).doc(walletId));

    // Hapus transaksi terkait dompet ini
    final txSnap = await _transactions(uid)
        .where('id_dompet', isEqualTo: walletId)
        .get();
    for (final doc in txSnap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  // ─── TRANSACTION CRUD ──────────────────────────────────────────────────────

  /// Tambah transaksi + update saldo dompet secara atomik
  Future<void> addTransaction(
    String uid,
    TransactionModel tx,
    List<WalletModel> wallets,
  ) async {
    final batch = _db.batch();

    // 1. Simpan transaksi baru
    final txRef = _transactions(uid).doc();
    batch.set(txRef, tx.toMap());

    // 2. Update saldo dompet
    final walletRef = _wallets(uid).doc(tx.idDompet);
    switch (tx.tipe) {
      case 'Pemasukan':
        batch.update(walletRef, {'saldo': FieldValue.increment(tx.nominal)});
        break;
      case 'Pengeluaran':
        batch.update(walletRef, {'saldo': FieldValue.increment(-tx.nominal)});
        break;
      case 'Transfer':
        // Source: keluar nominal + fee
        batch.update(walletRef, {'saldo': FieldValue.increment(-(tx.nominal + tx.fee))});
        if (tx.idDompetTujuan != null) {
          final tujuanRef = _wallets(uid).doc(tx.idDompetTujuan!);
          // Tujuan: terima hanya nominal (fee tidak diteruskan)
          batch.update(tujuanRef, {'saldo': FieldValue.increment(tx.nominal)});
        }
        break;
    }

    await batch.commit();
  }

  /// Hapus transaksi + revert saldo dompet secara atomik
  Future<void> deleteTransaction(
    String uid,
    TransactionModel tx,
  ) async {
    final batch = _db.batch();

    // 1. Hapus transaksi
    batch.delete(_transactions(uid).doc(tx.id));

    // 2. Revert saldo dompet
    final walletRef = _wallets(uid).doc(tx.idDompet);
    switch (tx.tipe) {
      case 'Pemasukan':
        batch.update(walletRef, {'saldo': FieldValue.increment(-tx.nominal)});
        break;
      case 'Pengeluaran':
        batch.update(walletRef, {'saldo': FieldValue.increment(tx.nominal)});
        break;
      case 'Transfer':
        // Revert: source balik nominal + fee, tujuan kurang nominal
        batch.update(walletRef, {'saldo': FieldValue.increment(tx.nominal + tx.fee)});
        if (tx.idDompetTujuan != null) {
          final tujuanRef = _wallets(uid).doc(tx.idDompetTujuan!);
          batch.update(tujuanRef, {'saldo': FieldValue.increment(-tx.nominal)});
        }
        break;
    }

    await batch.commit();
  }

  // ─── BILL CRUD ─────────────────────────────────────────────────────────────

  Future<void> addBill(String uid, BillModel bill) async {
    await _bills(uid).add(bill.toMap());
  }

  Future<void> updateBill(String uid, BillModel bill) async {
    await _bills(uid).doc(bill.id).update(bill.toMap());
  }

  Future<void> deleteBill(String uid, String billId) async {
    await _bills(uid).doc(billId).delete();
  }

  /// Tandai tagihan sebagai lunas + buat transaksi pengeluaran sekaligus
  Future<void> payBill(
    String uid,
    BillModel bill,
    WalletModel wallet,
  ) async {
    final batch = _db.batch();

    // 1. Buat transaksi pengeluaran
    final txRef = _transactions(uid).doc();
    batch.set(txRef, {
      'id_dompet': wallet.id,
      'id_dompet_tujuan': null,
      'id_kategori': null,
      'tipe': 'Pengeluaran',
      'nominal': bill.nominal,
      'fee': 0,
      'tanggal': DateTime.now(),
      'catatan': 'Bayar: ${bill.nama}',
      'nama_dompet': wallet.nama,
      'nama_kategori': 'Tagihan',
      'icon_kategori': '🧾',
    });

    // 2. Kurangi saldo dompet
    batch.update(
      _wallets(uid).doc(wallet.id),
      {'saldo': FieldValue.increment(-bill.nominal)},
    );

    // 3. Tandai tagihan sebagai lunas
    batch.update(_bills(uid).doc(bill.id), {
      'sudah_dibayar': true,
      'id_transaksi': txRef.id,
    });

    await batch.commit();
  }
}
