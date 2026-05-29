import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/bill_model.dart';
import '../../models/wallet_model.dart';
import '../../providers/firestore_provider.dart';

class BillsScreen extends ConsumerWidget {
  const BillsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final billsAsync = ref.watch(billsProvider);
    final walletsAsync = ref.watch(walletsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    final bills = billsAsync.valueOrNull ?? [];
    final wallets = walletsAsync.valueOrNull ?? [];
    final unpaid = bills.where((b) => !b.sudahDibayar).toList();
    final paid = bills.where((b) => b.sudahDibayar).toList();

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
        child: Column(
          children: [
            // ── Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tagihan',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () => _showBillForm(context, ref, wallets),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Tambah'),
                    style: FilledButton.styleFrom(
                      backgroundColor: cs.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ],
              ),
            ),

            // ── Summary chips
            if (bills.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    _SummaryChip(
                      label: 'Belum Dibayar',
                      count: unpaid.length,
                      color: const Color(0xFFFF6B6B),
                    ),
                    const SizedBox(width: 10),
                    _SummaryChip(
                      label: 'Lunas',
                      count: paid.length,
                      color: const Color(0xFF00C896),
                    ),
                  ],
                ),
              ),

            // ── List
            Expanded(
              child: billsAsync.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : bills.isEmpty
                      ? _buildEmpty(cs)
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                          children: [
                            if (unpaid.isNotEmpty) ...[
                              const _SectionHeader(
                                  label: 'Belum Dibayar',
                                  color: Color(0xFFFF6B6B)),
                              const SizedBox(height: 8),
                              ...unpaid.map((bill) => Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: _BillCard(
                                      bill: bill,
                                      wallets: wallets,
                                      onEdit: () => _showBillForm(
                                          context, ref, wallets,
                                          existing: bill),
                                      onPay: () => _showPayDialog(
                                          context, ref, bill, wallets),
                                      onDelete: () =>
                                          _deleteBill(context, ref, bill),
                                    ),
                                  )),
                              const SizedBox(height: 16),
                            ],
                            if (paid.isNotEmpty) ...[
                              const _SectionHeader(
                                  label: 'Sudah Dibayar / Lunas',
                                  color: Color(0xFF00C896)),
                              const SizedBox(height: 8),
                              ...paid.map((bill) => Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: _BillCard(
                                      bill: bill,
                                      wallets: wallets,
                                      onEdit: null, // tidak bisa edit yang sudah lunas
                                      onPay: null,
                                      onDelete: () =>
                                          _deleteBill(context, ref, bill),
                                    ),
                                  )),
                            ],
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(ColorScheme cs) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined,
              size: 56, color: cs.onSurface.withValues(alpha: 0.25)),
          const SizedBox(height: 16),
          Text(
            'Belum ada tagihan',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: cs.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap "+ Tambah" untuk mencatat tagihan\natau hutang yang perlu dibayar.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: cs.onSurface.withValues(alpha: 0.4),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showBillForm(
    BuildContext context,
    WidgetRef ref,
    List<WalletModel> wallets, {
    BillModel? existing,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BillFormSheet(existing: existing, ref: ref),
    );
  }

  Future<void> _showPayDialog(
    BuildContext context,
    WidgetRef ref,
    BillModel bill,
    List<WalletModel> wallets,
  ) async {
    if (wallets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Anda belum memiliki dompet.')),
      );
      return;
    }

    WalletModel? selectedWallet = wallets.first;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final cs = Theme.of(ctx).colorScheme;
          final saldoCukup = selectedWallet != null &&
              selectedWallet!.saldo >= bill.nominal;

          return AlertDialog(
            backgroundColor: cs.surface,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: Text('Bayar Tagihan', style: TextStyle(color: cs.onSurface)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bill.nama,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  CurrencyFormatter.format(bill.nominal),
                  style: const TextStyle(
                    color: Color(0xFFFF6B6B),
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Bayar menggunakan dompet:',
                  style: TextStyle(
                    fontSize: 13,
                    color: cs.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<WalletModel>(
                  initialValue: selectedWallet,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: cs.onSurface.withValues(alpha: 0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                  ),
                  items: wallets
                      .map((w) => DropdownMenuItem(
                            value: w,
                            child: Text(
                              '${w.nama}  •  ${CurrencyFormatter.format(w.saldo)}',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ))
                      .toList(),
                  onChanged: (w) => setDialogState(() => selectedWallet = w),
                ),
                if (!saldoCukup && selectedWallet != null)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'Saldo tidak mencukupi!',
                      style: TextStyle(
                          color: Color(0xFFFF6B6B),
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Batal',
                    style: TextStyle(
                        color: cs.onSurface.withValues(alpha: 0.5))),
              ),
              ElevatedButton(
                onPressed: (!saldoCukup || selectedWallet == null)
                    ? null
                    : () async {
                        Navigator.pop(ctx);
                        final uid =
                            FirebaseAuth.instance.currentUser?.uid ?? '';
                        await ref
                            .read(firestoreServiceProvider)
                            .payBill(uid, bill, selectedWallet!);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  '${bill.nama} berhasil dibayar! 🎉'),
                              backgroundColor: const Color(0xFF00C896),
                            ),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C896),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Bayar Sekarang'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _deleteBill(
      BuildContext context, WidgetRef ref, BillModel bill) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return AlertDialog(
          backgroundColor: cs.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Hapus Tagihan?'),
          content: Text('Tagihan "${bill.nama}" akan dihapus permanen.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B6B),
                foregroundColor: Colors.white,
              ),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      await ref.read(firestoreServiceProvider).deleteBill(uid, bill.id);
    }
  }
}

// ─────────────────────────────────────────────────
//  BILL FORM SHEET (Add & Edit)
// ─────────────────────────────────────────────────
class _BillFormSheet extends ConsumerStatefulWidget {
  final BillModel? existing;
  final WidgetRef ref;

  const _BillFormSheet({this.existing, required this.ref});

  @override
  ConsumerState<_BillFormSheet> createState() => _BillFormSheetState();
}

class _BillFormSheetState extends ConsumerState<_BillFormSheet> {
  final _namaCtrl = TextEditingController();
  final _nominalCtrl = TextEditingController();
  final _catatanCtrl = TextEditingController();
  DateTime _jatuhTempo = DateTime.now().add(const Duration(days: 7));
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _namaCtrl.text = widget.existing!.nama;
      // Format existing nominal with dots (e.g. 1.500.000)
      final raw = widget.existing!.nominal.toStringAsFixed(0);
      _nominalCtrl.text = _ThousandsSeparatorFormatter.formatString(raw);
      _catatanCtrl.text = widget.existing!.catatan ?? '';
      _jatuhTempo = widget.existing!.jatuhTempo;
    }
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _nominalCtrl.dispose();
    _catatanCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isEdit = widget.existing != null;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isEdit ? 'Edit Tagihan' : 'Tagihan Baru',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                if (isEdit)
                  IconButton(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: cs.surface,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          title: const Text('Hapus Tagihan?'),
                          content: Text(
                              'Tagihan "${widget.existing!.nama}" akan dihapus permanen.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Batal'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF6B6B),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                              child: const Text('Hapus'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true && mounted) {
                        final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
                        await ref
                            .read(firestoreServiceProvider)
                            .deleteBill(uid, widget.existing!.id);
                        if (mounted && context.mounted) Navigator.pop(context);
                      }
                    },
                    icon: const Icon(Icons.delete_outline_rounded,
                        color: Color(0xFFFF6B6B)),
                    tooltip: 'Hapus Tagihan',
                    style: IconButton.styleFrom(
                      backgroundColor:
                          const Color(0xFFFF6B6B).withValues(alpha: 0.1),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // Nama tagihan
            _buildField(
              cs: cs,
              controller: _namaCtrl,
              hint: 'Nama Tagihan (mis: Tagihan Listrik)',
              icon: Icons.receipt_outlined,
            ),
            const SizedBox(height: 12),

            // Nominal
            _buildField(
              cs: cs,
              controller: _nominalCtrl,
              hint: 'Nominal (Rp)',
              icon: Icons.attach_money_rounded,
              keyboardType: TextInputType.number,
              inputFormatters: [_ThousandsSeparatorFormatter()],
            ),
            const SizedBox(height: 12),

            // Jatuh tempo
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _jatuhTempo,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
                );
                if (picked != null) setState(() => _jatuhTempo = picked);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: cs.onSurface.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_month_outlined,
                        color: cs.onSurface.withValues(alpha: 0.4), size: 20),
                    const SizedBox(width: 12),
                    Text(
                      'Jatuh Tempo: ${_formatDate(_jatuhTempo)}',
                      style: TextStyle(
                          color: cs.onSurface, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Catatan
            _buildField(
              cs: cs,
              controller: _catatanCtrl,
              hint: 'Catatan (opsional)',
              icon: Icons.notes_rounded,
            ),
            const SizedBox(height: 24),

            // Tombol simpan
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text(
                        isEdit ? 'Simpan Perubahan' : 'Tambah Tagihan',
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required ColorScheme cs,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: cs.onSurface.withValues(alpha: 0.4), size: 20),
        filled: true,
        fillColor: cs.onSurface.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }

  Future<void> _save() async {
    final nama = _namaCtrl.text.trim();
    // Strip titik ribuan sebelum di-parse
    final nominalStr = _nominalCtrl.text.trim().replaceAll('.', '');
    if (nama.isEmpty || nominalStr.isEmpty) return;

    final nominal = double.tryParse(nominalStr) ?? 0;
    if (nominal <= 0) return;

    setState(() => _isSaving = true);
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final svc = ref.read(firestoreServiceProvider);

    if (widget.existing != null) {
      final updated = widget.existing!.copyWith(
        nama: nama,
        nominal: nominal,
        jatuhTempo: _jatuhTempo,
        catatan: _catatanCtrl.text.trim(),
      );
      await svc.updateBill(uid, updated);
    } else {
      final newBill = BillModel(
        id: '',
        nama: nama,
        nominal: nominal,
        jatuhTempo: _jatuhTempo,
        catatan: _catatanCtrl.text.trim(),
      );
      await svc.addBill(uid, newBill);
    }

    if (mounted) Navigator.pop(context);
  }

  String _formatDate(DateTime d) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${d.day} ${months[d.month]} ${d.year}';
  }
}

// ─────────────────────────────────────────────────
//  BILL CARD
// ─────────────────────────────────────────────────
class _BillCard extends StatelessWidget {
  final BillModel bill;
  final List<WalletModel> wallets;
  final VoidCallback? onEdit;
  final VoidCallback? onPay;
  final VoidCallback onDelete;

  const _BillCard({
    required this.bill,
    required this.wallets,
    required this.onEdit,
    required this.onPay,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPaid = bill.sudahDibayar;
    final isOverdue = bill.isOverdue;

    Color statusColor;
    String statusLabel;
    if (isPaid) {
      statusColor = const Color(0xFF00C896);
      statusLabel = 'Lunas';
    } else if (isOverdue) {
      statusColor = const Color(0xFFFF6B6B);
      statusLabel = 'Lewat Jatuh Tempo';
    } else if (bill.sisaHari <= 3) {
      statusColor = const Color(0xFFFFB347);
      statusLabel = 'Jatuh tempo ${bill.sisaHari} hari lagi';
    } else {
      statusColor = cs.onSurface.withValues(alpha: 0.4);
      statusLabel = '${bill.sisaHari} hari lagi';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isPaid
              ? const Color(0xFF00C896).withValues(alpha: 0.2)
              : isOverdue
                  ? const Color(0xFFFF6B6B).withValues(alpha: 0.25)
                  : cs.onSurface.withValues(alpha: isDark ? 0.08 : 0.07),
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: statusColor.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Icon
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: (isPaid
                          ? const Color(0xFF00C896)
                          : const Color(0xFFFF6B6B))
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    isPaid ? '✅' : '🧾',
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bill.nama,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                        decoration: isPaid ? TextDecoration.lineThrough : null,
                        decorationColor:
                            cs.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      CurrencyFormatter.format(bill.nominal),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isPaid
                            ? const Color(0xFF00C896)
                            : const Color(0xFFFF6B6B),
                        decoration: isPaid ? TextDecoration.lineThrough : null,
                        decorationColor:
                            cs.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              ),
              // Status badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),

          // Jatuh tempo & catatan
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.calendar_today_rounded,
                  size: 13, color: cs.onSurface.withValues(alpha: 0.4)),
              const SizedBox(width: 6),
              Text(
                'Jatuh tempo: ${_formatDate(bill.jatuhTempo)}',
                style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
          if (bill.catatan != null && bill.catatan!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                bill.catatan!,
                style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurface.withValues(alpha: 0.45),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),

          // Action buttons (only shown for unpaid)
          if (!isPaid) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                // Edit button
                if (onEdit != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined, size: 15),
                      label: const Text('Edit'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: cs.onSurface.withValues(alpha: 0.7),
                        side: BorderSide(
                            color: cs.onSurface.withValues(alpha: 0.15)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        textStyle: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                const SizedBox(width: 10),
                // Pay button
                if (onPay != null)
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: onPay,
                      icon: const Icon(Icons.check_circle_outline_rounded,
                          size: 16),
                      label: const Text('Bayar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00C896),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        textStyle: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
              ],
            ),
          ] else ...[
            // Hapus untuk yang sudah lunas
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded, size: 14),
                label: const Text('Hapus'),
                style: TextButton.styleFrom(
                  foregroundColor:
                      const Color(0xFFFF6B6B).withValues(alpha: 0.7),
                  textStyle: const TextStyle(fontSize: 12),
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${d.day} ${months[d.month]} ${d.year}';
  }
}

// ─────────────────────────────────────────────────
//  HELPER WIDGETS
// ─────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String label;
  final Color color;
  const _SectionHeader({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _SummaryChip(
      {required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$count',
            style: TextStyle(
                fontWeight: FontWeight.w700, fontSize: 15, color: color),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: color),
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------
//  THOUSANDS SEPARATOR FORMATTER
// -------------------------------------------------
class _ThousandsSeparatorFormatter extends TextInputFormatter {
  static String formatString(String digits) {
    if (digits.isEmpty) return '';
    final buffer = StringBuffer();
    final reversed = digits.split('').reversed.toList();
    for (int i = 0; i < reversed.length; i++) {
      if (i > 0 && i % 3 == 0) buffer.write('.');
      buffer.write(reversed[i]);
    }
    return buffer.toString().split('').reversed.join();
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll('.', '');
    if (digits.isEmpty) return newValue.copyWith(text: '');
    final formatted = formatString(digits);
    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
