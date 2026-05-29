import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/wallet_model.dart';
import '../../providers/firestore_provider.dart';

class WalletsScreen extends ConsumerWidget {
  const WalletsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final walletsAsync = ref.watch(walletsProvider);
    final wallets = walletsAsync.valueOrNull ?? [];
    final total = wallets.fold<double>(0, (s, w) => s + w.saldo);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [const Color(0xFF0D1631), const Color(0xFF0A0F1E)]
              : [const Color(0xFFECF0FF), const Color(0xFFF5F7FF)],
        ),
      ),
      child: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              backgroundColor: Colors.transparent,
              title: Text('Dompet Saya',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, color: cs.onSurface)),
              floating: true,
              snap: true,
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: GestureDetector(
                    onTap: () => _showAddWalletSheet(context, ref),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_rounded, color: cs.primary, size: 18),
                          const SizedBox(width: 4),
                          Text('Tambah',
                              style: TextStyle(
                                  color: cs.primary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildTotalCard(context, total, wallets.length),
                  const SizedBox(height: 20),
                  Text(
                    'Semua Dompet',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (walletsAsync.isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (wallets.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(Icons.account_balance_wallet_outlined,
                              size: 48, color: cs.onSurface.withValues(alpha: 0.3)),
                          const SizedBox(height: 12),
                          Text('Belum ada dompet',
                              style: TextStyle(
                                  color: cs.onSurface.withValues(alpha: 0.5))),
                          const SizedBox(height: 8),
                          Text('Tap "Tambah" untuk buat dompet baru',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: cs.onSurface.withValues(alpha: 0.4))),
                        ],
                      ),
                    )
                  else
                    ...wallets.map((w) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _WalletCard(wallet: w),
                        )),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalCard(BuildContext context, double total, int count) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00C896), Color(0xFF0087FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00C896).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total $count Dompet',
                    style:
                        const TextStyle(fontSize: 13, color: Colors.white70)),
                const SizedBox(height: 6),
                Text(
                  CurrencyFormatter.format(total),
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.account_balance_wallet_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddWalletSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => const _WalletFormSheet(),
    );
  }
}

// ─────────────────────────────────────────────────
//  WALLET CARD
// ─────────────────────────────────────────────────
class _WalletCard extends ConsumerWidget {
  final WalletModel wallet;
  const _WalletCard({required this.wallet});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final isCash = wallet.jenis == 'Cash';
    final color = isCash ? const Color(0xFFFFB347) : cs.primary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? const Color(0xFF1E2538)
              : Colors.grey.withValues(alpha: 0.1),
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                )
              ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              isCash ? Icons.payments_outlined : Icons.phone_android_outlined,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(wallet.nama,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface)),
                const SizedBox(height: 3),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    wallet.jenis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                CurrencyFormatter.format(wallet.saldo),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  _actionBtn(
                    Icons.edit_outlined,
                    cs.onSurface.withValues(alpha: 0.4),
                    () => _showEditSheet(context, ref),
                  ),
                  const SizedBox(width: 4),
                  _actionBtn(
                    Icons.delete_outline_rounded,
                    const Color(0xFFFF6B6B),
                    () => _confirmDelete(context, ref),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 16),
      ),
    );
  }

  void _showEditSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _WalletFormSheet(editWallet: wallet),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Dompet?'),
        content: Text(
            'Hapus "${wallet.nama}"? Semua transaksi terkait juga akan dihapus.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final uid = FirebaseAuth.instance.currentUser!.uid;
                await ref
                    .read(firestoreServiceProvider)
                    .deleteWallet(uid, wallet.id);
                scaffoldMessenger.showSnackBar(
                  SnackBar(content: Text('Dompet "${wallet.nama}" dihapus')),
                );
              } catch (e) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(content: Text('Gagal hapus dompet: $e')),
                );
              }
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────
//  WALLET FORM SHEET (Tambah / Edit)
// ─────────────────────────────────────────────────
class _WalletFormSheet extends ConsumerStatefulWidget {
  final WalletModel? editWallet;
  const _WalletFormSheet({this.editWallet});

  @override
  ConsumerState<_WalletFormSheet> createState() => _WalletFormSheetState();
}

class _WalletFormSheetState extends ConsumerState<_WalletFormSheet> {
  late final TextEditingController _namaCtrl;
  late final TextEditingController _saldoCtrl;
  late String _jenis;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _namaCtrl = TextEditingController(text: widget.editWallet?.nama ?? '');
    _saldoCtrl = TextEditingController(
      text: widget.editWallet != null
          ? widget.editWallet!.saldo.toStringAsFixed(0)
          : '',
    );
    _jenis = widget.editWallet?.jenis ?? 'Cash';
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _saldoCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final nama = _namaCtrl.text.trim();
    // parse saldo: hapus titik dulu
    final saldo = double.tryParse(_saldoCtrl.text.replaceAll('.', '')) ?? 0;
    if (nama.isEmpty) return;

    setState(() => _isSaving = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final service = ref.read(firestoreServiceProvider);

      if (widget.editWallet != null) {
        // Mode edit — tidak ubah saldo
        await service.updateWallet(
            uid, widget.editWallet!.copyWith(nama: nama, jenis: _jenis));
      } else {
        // Mode tambah — set saldo awal
        await service.addWallet(
            uid,
            WalletModel(
                id: '', nama: nama, jenis: _jenis, saldo: saldo));
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isEdit = widget.editWallet != null;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(isEdit ? 'Edit Dompet' : 'Tambah Dompet',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface)),
          const SizedBox(height: 20),
          TextField(
            controller: _namaCtrl,
            style: TextStyle(color: cs.onSurface),
            decoration: const InputDecoration(
                labelText: 'Nama Dompet',
                prefixIcon: Icon(Icons.wallet_outlined)),
          ),
          if (!isEdit) ...[
            const SizedBox(height: 14),
            TextField(
              controller: _saldoCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [_ThousandsSeparatorFormatter()],
              style: TextStyle(color: cs.onSurface),
              decoration: const InputDecoration(
                  labelText: 'Saldo Awal (Rp)',
                  prefixIcon: Icon(Icons.attach_money_rounded)),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: ['Cash', 'E-Money'].map((j) {
              final sel = _jenis == j;
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: ChoiceChip(
                  label: Text(j),
                  selected: sel,
                  onSelected: (_) => setState(() => _jenis = j),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _handleSave,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(isEdit ? 'Update Dompet' : 'Simpan Dompet'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Auto-format ribuan: 1000000 → 1.000.000
class _ThousandsSeparatorFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll('.', '');
    if (digits.isEmpty) return newValue.copyWith(text: '');
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
      buffer.write(digits[i]);
    }
    final formatted = buffer.toString();
    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
