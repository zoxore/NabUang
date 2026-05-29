import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/wallet_model.dart';
import '../models/transaction_model.dart';
import '../services/firestore_service.dart';

// ─── FirestoreService instance ────────────────────────────────────────────────
final firestoreServiceProvider =
    Provider<FirestoreService>((ref) => FirestoreService());

// ─── UID user yang sedang login ───────────────────────────────────────────────
final _uidProvider = Provider<String>((ref) {
  return FirebaseAuth.instance.currentUser?.uid ?? '';
});

// ─── Stream daftar wallet ─────────────────────────────────────────────────────
final walletsProvider = StreamProvider<List<WalletModel>>((ref) {
  final uid = ref.watch(_uidProvider);
  if (uid.isEmpty) return const Stream.empty();
  return ref.watch(firestoreServiceProvider).walletsStream(uid);
});

// ─── Stream daftar transaksi ──────────────────────────────────────────────────
final transactionsProvider = StreamProvider<List<TransactionModel>>((ref) {
  final uid = ref.watch(_uidProvider);
  if (uid.isEmpty) return const Stream.empty();
  return ref.watch(firestoreServiceProvider).transactionsStream(uid);
});

// ─── Total saldo semua wallet ─────────────────────────────────────────────────
final totalSaldoProvider = Provider<double>((ref) {
  final wallets = ref.watch(walletsProvider).valueOrNull ?? [];
  return wallets.fold(0.0, (sum, w) => sum + w.saldo);
});

// ─── Total pemasukan bulan ini ────────────────────────────────────────────────
final totalPemasukanProvider = Provider<double>((ref) {
  final txList = ref.watch(transactionsProvider).valueOrNull ?? [];
  final now = DateTime.now();
  return txList
      .where((tx) =>
          tx.tipe == 'Pemasukan' &&
          tx.tanggal.month == now.month &&
          tx.tanggal.year == now.year)
      .fold(0.0, (sum, tx) => sum + tx.nominal);
});

// ─── Total pengeluaran bulan ini ──────────────────────────────────────────────
final totalPengeluaranProvider = Provider<double>((ref) {
  final txList = ref.watch(transactionsProvider).valueOrNull ?? [];
  final now = DateTime.now();
  return txList
      .where((tx) =>
          tx.tipe == 'Pengeluaran' &&
          tx.tanggal.month == now.month &&
          tx.tanggal.year == now.year)
      .fold(0.0, (sum, tx) => sum + tx.nominal);
});
