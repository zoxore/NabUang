import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/transaction_model.dart';
import '../../models/wallet_model.dart';
import '../../models/category_model.dart';
import '../../providers/firestore_provider.dart';

class TransactionFormScreen extends ConsumerStatefulWidget {
  const TransactionFormScreen({super.key});

  @override
  ConsumerState<TransactionFormScreen> createState() =>
      _TransactionFormScreenState();
}

class _TransactionFormScreenState extends ConsumerState<TransactionFormScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _tipe = 'Pengeluaran';
  WalletModel? _selectedWallet;
  WalletModel? _selectedWalletTujuan;
  CategoryModel? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  final _nominalController = TextEditingController();
  final _catatanController = TextEditingController();
  final _feeController = TextEditingController();

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          switch (_tabController.index) {
            case 0:
              _tipe = 'Pengeluaran';
              break;
            case 1:
              _tipe = 'Pemasukan';
              break;
            case 2:
              _tipe = 'Transfer';
              break;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nominalController.dispose();
    _catatanController.dispose();
    _feeController.dispose();
    super.dispose();
  }

  Color get _tipeColor {
    switch (_tipe) {
      case 'Pemasukan':
        return AppColors.income;
      case 'Transfer':
        return AppColors.transfer;
      default:
        return AppColors.expense;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
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
              _buildHeader(context),
              _buildTypeTabBar(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildNominalField(),
                      const SizedBox(height: 20),
                      _buildWalletPicker(),
                      if (_tipe == 'Transfer') ...[
                        const SizedBox(height: 12),
                        _buildWalletTujuanPicker(),
                        const SizedBox(height: 12),
                        _buildFeeField(),
                      ],
                      if (_tipe != 'Transfer') ...[
                        const SizedBox(height: 12),
                        _buildCategoryPicker(),
                      ],
                      const SizedBox(height: 12),
                      _buildDatePicker(),
                      const SizedBox(height: 12),
                      _buildCatatanField(),
                      const SizedBox(height: 28),
                      _buildSaveButton(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: cs.onSurface),
          ),
          Expanded(
            child: Text(
              'Tambah Transaksi',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeTabBar() {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            color: _tipeColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _tipeColor.withValues(alpha: 0.5)),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelColor: _tipeColor,
          unselectedLabelColor: cs.onSurface.withValues(alpha: 0.5),
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          unselectedLabelStyle: const TextStyle(fontSize: 13),
          tabs: const [
            Tab(text: 'Pengeluaran'),
            Tab(text: 'Pemasukan'),
            Tab(text: 'Transfer'),
          ],
        ),
      ),
    );
  }

  Widget _buildNominalField() {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _tipeColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Nominal',
              style: TextStyle(
                  fontSize: 13,
                  color: cs.onSurface.withValues(alpha: 0.6))),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('Rp',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: _tipeColor)),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _nominalController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    _ThousandsSeparatorFormatter(),
                  ],
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: _tipeColor),
                  decoration: InputDecoration(
                    hintText: '0',
                    hintStyle: TextStyle(
                        color: _tipeColor.withValues(alpha: 0.3),
                        fontSize: 28,
                        fontWeight: FontWeight.w700),
                    border: InputBorder.none,
                    fillColor: Colors.transparent,
                    filled: false,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWalletPicker() {
    final label = _tipe == 'Transfer' ? 'Dompet Asal' : 'Dompet';
    return _PickerField(
      label: label,
      value: _selectedWallet?.nama,
      icon: Icons.account_balance_wallet_outlined,
      onTap: () => _showWalletPicker(isAsal: true),
    );
  }

  Widget _buildWalletTujuanPicker() {
    return _PickerField(
      label: 'Dompet Tujuan',
      value: _selectedWalletTujuan?.nama,
      icon: Icons.account_balance_wallet_rounded,
      iconColor: AppColors.transfer,
      onTap: () => _showWalletPicker(isAsal: false),
    );
  }

  Widget _buildCategoryPicker() {
    return _PickerField(
      label: 'Kategori',
      value: _selectedCategory != null
          ? '${_selectedCategory!.icon} ${_selectedCategory!.nama}'
          : null,
      icon: Icons.category_outlined,
      onTap: _showCategoryPicker,
    );
  }

  Widget _buildFeeField() {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFFFB347).withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFB347).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.receipt_long_outlined,
                color: Color(0xFFFFB347), size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Biaya / Pajak Transfer (opsional)',
                    style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurface.withValues(alpha: 0.5))),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Text('Rp ',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFFFB347))),
                    Expanded(
                      child: TextField(
                        controller: _feeController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [_ThousandsSeparatorFormatter()],
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: cs.onSurface),
                        decoration: InputDecoration(
                          hintText: '0',
                          hintStyle: TextStyle(
                              color: cs.onSurface.withValues(alpha: 0.3)),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          fillColor: Colors.transparent,
                          filled: false,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: _pickDate,
      child: _PickerField(
        label: 'Tanggal',
        value: _formatDate(_selectedDate),
        icon: Icons.calendar_today_outlined,
        onTap: _pickDate,
      ),
    );
  }

  Widget _buildCatatanField() {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.1)),
      ),
      child: TextField(
        controller: _catatanController,
        maxLines: 3,
        style: TextStyle(color: cs.onSurface),
        decoration: InputDecoration(
          hintText: 'Catatan (opsional)...',
          hintStyle: TextStyle(color: cs.onSurface.withValues(alpha: 0.4)),
          border: InputBorder.none,
          fillColor: Colors.transparent,
          filled: false,
          contentPadding: const EdgeInsets.all(18),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 16, right: 8, top: 14),
            child: Icon(Icons.notes_rounded,
                color: cs.onSurface.withValues(alpha: 0.4), size: 20),
          ),
          prefixIconConstraints: const BoxConstraints(),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _handleSave,
        style: ElevatedButton.styleFrom(
          backgroundColor: _tipeColor,
          disabledBackgroundColor: _tipeColor.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: _isSaving
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: Colors.white),
              )
            : const Text(
                'Simpan Transaksi',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Future<void> _handleSave() async {
    // Validasi nominal
    final nominalStr = _nominalController.text.replaceAll('.', '');
    final nominal = double.tryParse(nominalStr) ?? 0;
    if (nominal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan nominal yang valid')),
      );
      return;
    }
    if (_selectedWallet == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih dompet terlebih dahulu')),
      );
      return;
    }
    if (_tipe == 'Transfer' && _selectedWalletTujuan == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih dompet tujuan')),
      );
      return;
    }

    final fee = _tipe == 'Transfer'
        ? (double.tryParse(_feeController.text.replaceAll('.', '')) ?? 0)
        : 0.0;

    // ── Validasi saldo tidak minus ──────────────────────────
    if (_tipe == 'Pengeluaran' || _tipe == 'Transfer') {
      final totalKeluar = nominal + fee;
      if (_selectedWallet!.saldo < totalKeluar) {
        final kekurangan = totalKeluar - _selectedWallet!.saldo;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Saldo ${_selectedWallet!.nama} tidak mencukupi. '
              'Kurang ${CurrencyFormatter.format(kekurangan)}',
            ),
            backgroundColor: const Color(0xFFFF6B6B),
          ),
        );
        return;
      }
    }

    setState(() => _isSaving = true);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final wallets = ref.read(walletsProvider).valueOrNull ?? [];
      final service = ref.read(firestoreServiceProvider);

      final tx = TransactionModel(
        id: '',
        idDompet: _selectedWallet!.id,
        idDompetTujuan: _tipe == 'Transfer' ? _selectedWalletTujuan?.id : null,
        idKategori: _selectedCategory?.id,
        tipe: _tipe,
        nominal: nominal,
        fee: fee,
        tanggal: _selectedDate,
        catatan: _catatanController.text.trim(),
        namaDompet: _selectedWallet!.nama,
        namaDompetTujuan: _selectedWalletTujuan?.nama,
        namaKategori: _selectedCategory?.nama,
        iconKategori: _selectedCategory?.icon,
      );

      await service.addTransaction(uid, tx, wallets);

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan: $e')),
        );
      }
    }
  }

  void _showWalletPicker({required bool isAsal}) {
    final wallets = ref.read(walletsProvider).valueOrNull ?? [];
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _ListPickerSheet(
        title: isAsal ? 'Pilih Dompet' : 'Pilih Dompet Tujuan',
        items: wallets
            .map((w) => _PickerItem(
                  label: w.nama,
                  subtitle: '${w.jenis}  •  ${CurrencyFormatter.format(w.saldo)}',
                ))
            .toList(),
        onSelect: (index) {
          setState(() {
            if (isAsal) {
              _selectedWallet = wallets[index];
            } else {
              _selectedWalletTujuan = wallets[index];
            }
          });
        },
      ),
    );
  }

  void _showCategoryPicker() {
    final categories = ref.read(categoriesProvider).valueOrNull ?? [];
    final filtered = categories.where((c) => c.tipe == _tipe).toList();
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _ListPickerSheet(
        title: 'Pilih Kategori',
        items: filtered
            .map((c) => _PickerItem(label: c.nama, icon: c.icon))
            .toList(),
        onSelect: (index) {
          setState(() => _selectedCategory = filtered[index]);
        },
      ),
    );
  }

  Future<void> _pickDate() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: isDark
              ? ColorScheme.dark(primary: cs.primary, surface: cs.surface)
              : ColorScheme.light(primary: cs.primary, surface: cs.surface),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  String _formatDate(DateTime date) {
    final months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    final now = DateTime.now();
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return 'Hari ini';
    }
    return '${date.day} ${months[date.month]} ${date.year}';
  }
}

class _PickerField extends StatelessWidget {
  final String label;
  final String? value;
  final IconData icon;
  final Color? iconColor;
  final VoidCallback onTap;

  const _PickerField({
    required this.label,
    required this.value,
    required this.icon,
    this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = iconColor ?? cs.primary;
    final hasValue = value != null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: hasValue
                ? color.withValues(alpha: 0.3)
                : cs.onSurface.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: hasValue ? color : cs.onSurface.withValues(alpha: 0.4),
                size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurface.withValues(alpha: 0.5))),
                  const SizedBox(height: 2),
                  Text(
                    value ?? 'Pilih $label',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight:
                          hasValue ? FontWeight.w500 : FontWeight.w400,
                      color: hasValue
                          ? cs.onSurface
                          : cs.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: cs.onSurface.withValues(alpha: 0.3), size: 20),
          ],
        ),
      ),
    );
  }
}

class _PickerItem {
  final String label;
  final String? subtitle;
  final String? icon;

  const _PickerItem({required this.label, this.subtitle, this.icon});
}

class _ListPickerSheet extends StatelessWidget {
  final String title;
  final List<_PickerItem> items;
  final ValueChanged<int> onSelect;

  const _ListPickerSheet({
    required this.title,
    required this.items,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 12),
        Center(
          child: Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: cs.onSurface.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: Text(title,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface)),
        ),
        Flexible(
          child: ListView.builder(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                onTap: () {
                  onSelect(index);
                  Navigator.pop(context);
                },
                leading: item.icon != null
                    ? Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: cs.onSurface.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(item.icon!,
                              style: const TextStyle(fontSize: 18)),
                        ),
                      )
                    : Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.account_balance_wallet_outlined,
                            color: cs.primary, size: 18),
                      ),
                title: Text(item.label,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: cs.onSurface)),
                subtitle: item.subtitle != null
                    ? Text(item.subtitle!,
                        style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurface.withValues(alpha: 0.5)))
                    : null,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Auto-format nominal input dengan titik ribuan
/// Contoh: ketik 10000 → tampil 10.000
class _ThousandsSeparatorFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;
    final formatted = CurrencyFormatter.addSeparator(newValue.text);
    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
