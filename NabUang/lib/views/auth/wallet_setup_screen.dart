import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../models/wallet_model.dart';
import '../../providers/firestore_provider.dart';

/// Layar setup dompet pertama — muncul saat user baru login dan belum punya dompet
class WalletSetupScreen extends ConsumerStatefulWidget {
  const WalletSetupScreen({super.key});

  @override
  ConsumerState<WalletSetupScreen> createState() => _WalletSetupScreenState();
}

class _WalletSetupScreenState extends ConsumerState<WalletSetupScreen> {
  final List<_WalletEntry> _entries = [
    _WalletEntry(),
  ];
  bool _isSaving = false;

  Future<void> _handleLanjut() async {
    // Validasi minimal 1 dompet
    final valid = _entries.where((e) => e.namaCtrl.text.trim().isNotEmpty);
    if (valid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tambahkan minimal 1 dompet')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final service = ref.read(firestoreServiceProvider);

      for (final entry in _entries) {
        final nama = entry.namaCtrl.text.trim();
        if (nama.isEmpty) continue;
        final saldo =
            double.tryParse(entry.saldoCtrl.text.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;
        await service.addWallet(
          uid,
          WalletModel(id: '', nama: nama, jenis: entry.jenis, saldo: saldo),
        );
      }
      
      // Seed kategori default saat pertama kali setup
      await service.seedDefaultCategories(uid);
      
      // Setelah simpan → langsung ke dashboard
      if (mounted) context.go('/dashboard');
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal: $e')));
      }
    }
  }

  @override
  void dispose() {
    for (final e in _entries) {
      e.namaCtrl.dispose();
      e.saldoCtrl.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    // Jika sudah punya dompet → langsung ke dashboard
    final walletsAsync = ref.watch(walletsProvider);
    if (!walletsAsync.isLoading &&
        (walletsAsync.valueOrNull ?? []).isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/dashboard');
      });
    }

    return Scaffold(
      body: Container(
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
              const SizedBox(height: 32),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.35),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          )
                        ],
                      ),
                      child: const Icon(Icons.account_balance_wallet_rounded,
                          color: Colors.white, size: 36),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Buat Dompet Pertama',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tambahkan dompet kamu (rekening, e-wallet, atau cash)\nuntuk mulai mencatat keuangan.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: cs.onSurface.withValues(alpha: 0.55),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Daftar dompet
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  children: [
                    ..._entries.asMap().entries.map((entry) {
                      final i = entry.key;
                      final e = entry.value;
                      return _WalletEntryCard(
                        key: ValueKey(e),
                        entry: e,
                        index: i,
                        canDelete: _entries.length > 1,
                        onDelete: () => setState(() => _entries.removeAt(i)),
                      );
                    }),
                    const SizedBox(height: 12),
                    // Tombol tambah dompet lagi
                    GestureDetector(
                      onTap: () => setState(() => _entries.add(_WalletEntry())),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: cs.primary.withValues(alpha: 0.3),
                              style: BorderStyle.solid),
                          borderRadius: BorderRadius.circular(16),
                          color: cs.primary.withValues(alpha: 0.05),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_rounded,
                                color: cs.primary, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Tambah dompet lain',
                              style: TextStyle(
                                color: cs.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),

              // Tombol Lanjut
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _handleLanjut,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18)),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.5, color: Colors.white),
                          )
                        : const Text(
                            'Mulai Menabung 🚀',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Entry model per baris dompet ──────────────────────────────────────────────
class _WalletEntry {
  final namaCtrl = TextEditingController();
  final saldoCtrl = TextEditingController();
  String jenis = 'Cash';
}

// ── Card UI per dompet ────────────────────────────────────────────────────────
class _WalletEntryCard extends StatefulWidget {
  final _WalletEntry entry;
  final int index;
  final bool canDelete;
  final VoidCallback onDelete;

  const _WalletEntryCard({
    super.key,
    required this.entry,
    required this.index,
    required this.canDelete,
    required this.onDelete,
  });

  @override
  State<_WalletEntryCard> createState() => _WalletEntryCardState();
}

class _WalletEntryCardState extends State<_WalletEntryCard> {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.primary.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Dompet ${widget.index + 1}',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: cs.primary,
                ),
              ),
              const Spacer(),
              if (widget.canDelete)
                GestureDetector(
                  onTap: widget.onDelete,
                  child: Icon(Icons.close_rounded,
                      color: cs.onSurface.withValues(alpha: 0.4), size: 20),
                ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: widget.entry.namaCtrl,
            style: TextStyle(color: cs.onSurface),
            decoration: InputDecoration(
              labelText: 'Nama Dompet',
              hintText: 'Contoh: BCA, GoPay, Cash',
              hintStyle:
                  TextStyle(color: cs.onSurface.withValues(alpha: 0.35), fontSize: 13),
              prefixIcon: const Icon(Icons.wallet_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: widget.entry.saldoCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [_ThousandsSeparatorFormatter()],
            style: TextStyle(color: cs.onSurface),
            decoration: const InputDecoration(
              labelText: 'Saldo Awal (Rp)',
              hintText: '0',
              prefixIcon: Icon(Icons.attach_money_rounded),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: ['Cash', 'E-Money'].map((j) {
              final sel = widget.entry.jenis == j;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(j, style: const TextStyle(fontSize: 13)),
                  selected: sel,
                  onSelected: (_) => setState(() => widget.entry.jenis = j),
                ),
              );
            }).toList(),
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
