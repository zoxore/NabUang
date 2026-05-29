import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/transaction_model.dart';
import '../../models/wallet_model.dart';
import '../../core/utils/currency_formatter.dart';
import '../../providers/theme_provider.dart';
import '../../providers/firestore_provider.dart';
import '../../providers/auth_provider.dart';
import '../wallets/wallets_screen.dart';
import '../categories/categories_screen.dart';
import '../transactions/transaction_form_screen.dart';
import 'widgets/balance_card.dart';
import 'widgets/transaction_list_item.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    _HomeTab(),
    WalletsScreen(),
    CategoriesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          border: Border(
            top: BorderSide(
              color: cs.onSurface.withValues(alpha: 0.08),
              width: 1,
            ),
          ),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, -4),
                  )
                ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          backgroundColor: Colors.transparent,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Beranda',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet_outlined),
              activeIcon: Icon(Icons.account_balance_wallet_rounded),
              label: 'Dompet',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.grid_view_outlined),
              activeIcon: Icon(Icons.grid_view_rounded),
              label: 'Kategori',
            ),
          ],
        ),
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const TransactionFormScreen()),
              ),
              icon: const Icon(Icons.add_rounded, size: 22),
              label: const Text(
                'Transaksi',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

// ─────────────────────────────────────────────────
//  HOME TAB
// ─────────────────────────────────────────────────
class _HomeTab extends ConsumerStatefulWidget {
  const _HomeTab();

  @override
  ConsumerState<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends ConsumerState<_HomeTab> {
  // ─── Filter state ────────────────────────────────
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  String? _selectedWalletId; // null = semua dompet
  final Set<String> _pendingDeleteIds = {}; // item yg sudah di-swipe, tunggu Firestore

  List<TransactionModel> _applyFilter(List<TransactionModel> txList) {
    return txList.where((tx) {
      if (_pendingDeleteIds.contains(tx.id)) return false; // hide immediately
      final matchMonth = tx.tanggal.year == _selectedMonth.year &&
          tx.tanggal.month == _selectedMonth.month;
      final matchWallet = _selectedWalletId == null ||
          tx.idDompet == _selectedWalletId ||
          tx.idDompetTujuan == _selectedWalletId;
      return matchMonth && matchWallet;
    }).toList();
  }

  void _prevMonth() =>
      setState(() => _selectedMonth =
          DateTime(_selectedMonth.year, _selectedMonth.month - 1));

  void _nextMonth() {
    final now = DateTime.now();
    final next = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    if (!next.isAfter(DateTime(now.year, now.month))) {
      setState(() => _selectedMonth = next);
    }
  }

  Future<void> _deleteTransaction(TransactionModel tx) async {
    // Sembunyikan item langsung (fix Dismissible error)
    setState(() => _pendingDeleteIds.add(tx.id));
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      await ref.read(firestoreServiceProvider).deleteTransaction(uid, tx);
    } catch (e) {
      // Kalau gagal, tampilkan kembali
      setState(() => _pendingDeleteIds.remove(tx.id));
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal hapus: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final walletsAsync = ref.watch(walletsProvider);
    final transactionsAsync = ref.watch(transactionsProvider);
    final totalSaldo = ref.watch(totalSaldoProvider);
    final wallets = walletsAsync.valueOrNull ?? [];
    final allTx = transactionsAsync.valueOrNull ?? [];
    final filtered = _applyFilter(allTx);
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName?.split(' ').first ?? 'Pengguna';

    // Hitung income/expense dengan logika transfer yang akurat
    double income = 0, expense = 0;
    for (final t in filtered) {
      if (t.tipe == 'Pemasukan') {
        income += t.nominal;
      } else if (t.tipe == 'Pengeluaran') {
        expense += t.nominal;
      } else if (t.tipe == 'Transfer') {
        if (_selectedWalletId != null) {
          // Filter per dompet: transfer keluar = pengeluaran, masuk = pemasukan
          if (t.idDompet == _selectedWalletId) {
            expense += t.nominal + t.fee; // total keluar dari dompet ini
          } else if (t.idDompetTujuan == _selectedWalletId) {
            income += t.nominal; // diterima di dompet ini
          }
        } else {
          // Filter "Semua": transfer antar dompet = netral, hanya fee = pengeluaran
          expense += t.fee;
        }
      }
    }

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
        child: walletsAsync.isLoading
            ? const Center(child: CircularProgressIndicator())
            : CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // ── App Bar
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _getGreeting(DateTime.now().hour),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: cs.onSurface.withValues(alpha: 0.55),
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  'Halo, $displayName! 👋',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: cs.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _ThemeToggleButton(),
                          const SizedBox(width: 8),
                          // Avatar + Logout menu
                          PopupMenuButton<String>(
                            onSelected: (val) async {
                              if (val == 'logout') {
                                await ref
                                    .read(authServiceProvider)
                                    .signOut();
                              }
                            },
                            itemBuilder: (ctx) => [
                              const PopupMenuItem(
                                value: 'logout',
                                child: Row(
                                  children: [
                                    Icon(Icons.logout_rounded,
                                        color: Color(0xFFFF6B6B), size: 18),
                                    SizedBox(width: 10),
                                    Text('Keluar',
                                        style: TextStyle(
                                            color: Color(0xFFFF6B6B))),
                                  ],
                                ),
                              ),
                            ],
                            child: CircleAvatar(
                              radius: 20,
                              backgroundImage: user?.photoURL != null
                                  ? NetworkImage(user!.photoURL!)
                                  : null,
                              backgroundColor: cs.primary.withValues(alpha: 0.15),
                              child: user?.photoURL == null
                                  ? Icon(Icons.person_rounded,
                                      color: cs.primary, size: 22)
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        BalanceCard(totalSaldo: totalSaldo, wallets: wallets),
                        const SizedBox(height: 20),
                        // ── Summary cards
                        Row(
                          children: [
                            Expanded(
                              child: _SummaryCard(
                                label: 'Pemasukan',
                                amount: income,
                                icon: Icons.south_west_rounded,
                                color: const Color(0xFF00C896),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _SummaryCard(
                                label: 'Pengeluaran',
                                amount: expense,
                                icon: Icons.north_east_rounded,
                                color: const Color(0xFFFF6B6B),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // ── Filter bar
                        _FilterBar(
                          selectedMonth: _selectedMonth,
                          selectedWalletId: _selectedWalletId,
                          wallets: wallets,
                          onPrevMonth: _prevMonth,
                          onNextMonth: _nextMonth,
                          onWalletChanged: (id) =>
                              setState(() => _selectedWalletId = id),
                        ),
                        const SizedBox(height: 12),

                        // ── Transaksi list header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Transaksi',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: cs.onSurface,
                              ),
                            ),
                            Text(
                              '${filtered.length} transaksi',
                              style: TextStyle(
                                fontSize: 12,
                                color: cs.onSurface.withValues(alpha: 0.45),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // ── List
                        if (filtered.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                children: [
                                  Icon(Icons.receipt_long_outlined,
                                      size: 48,
                                      color: cs.onSurface.withValues(alpha: 0.3)),
                                  const SizedBox(height: 12),
                                  Text('Belum ada transaksi',
                                      style: TextStyle(
                                          color:
                                              cs.onSurface.withValues(alpha: 0.5))),
                                ],
                              ),
                            ),
                          )
                        else
                          ...filtered.map(
                            (t) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: TransactionListItem(
                                transaction: t,
                                onDelete: () => _deleteTransaction(t),
                              ),
                            ),
                          ),
                        const SizedBox(height: 100),
                      ]),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  String _getGreeting(int hour) {
    if (hour < 12) return 'Selamat pagi ☀️';
    if (hour < 15) return 'Selamat siang 🌤️';
    if (hour < 19) return 'Selamat sore 🌅';
    return 'Selamat malam 🌙';
  }
}

// ─────────────────────────────────────────────────
//  FILTER BAR
// ─────────────────────────────────────────────────
class _FilterBar extends StatelessWidget {
  final DateTime selectedMonth;
  final String? selectedWalletId;
  final List<WalletModel> wallets;
  final VoidCallback onPrevMonth;
  final VoidCallback onNextMonth;
  final ValueChanged<String?> onWalletChanged;

  const _FilterBar({
    required this.selectedMonth,
    required this.selectedWalletId,
    required this.wallets,
    required this.onPrevMonth,
    required this.onNextMonth,
    required this.onWalletChanged,
  });

  static const _months = [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final isCurrentMonth = selectedMonth.year == now.year &&
        selectedMonth.month == now.month;

    return Column(
      children: [
        // Month navigator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cs.onSurface.withValues(alpha: 0.08)),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: onPrevMonth,
                icon: Icon(Icons.chevron_left_rounded,
                    color: cs.onSurface.withValues(alpha: 0.6)),
                iconSize: 22,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
              Expanded(
                child: Text(
                  '${_months[selectedMonth.month]} ${selectedMonth.year}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
              ),
              IconButton(
                onPressed: isCurrentMonth ? null : onNextMonth,
                icon: Icon(
                  Icons.chevron_right_rounded,
                  color: isCurrentMonth
                      ? cs.onSurface.withValues(alpha: 0.2)
                      : cs.onSurface.withValues(alpha: 0.6),
                ),
                iconSize: 22,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
            ],
          ),
        ),

        // Wallet filter chips
        if (wallets.isNotEmpty) ...[
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _WalletChip(
                  label: 'Semua',
                  isSelected: selectedWalletId == null,
                  onTap: () => onWalletChanged(null),
                ),
                ...wallets.map((w) => _WalletChip(
                      label: w.nama,
                      isSelected: selectedWalletId == w.id,
                      onTap: () => onWalletChanged(w.id),
                    )),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _WalletChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _WalletChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? cs.primary : cs.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? cs.primary : cs.onSurface.withValues(alpha: 0.12),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : cs.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────
//  THEME TOGGLE BUTTON
// ─────────────────────────────────────────────────
class _ThemeToggleButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () {
        ref.read(themeModeProvider.notifier).state =
            isDark ? ThemeMode.light : ThemeMode.dark;
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: 64,
        height: 34,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: isDark
              ? const Color(0xFF252C3F)
              : const Color(0xFFE3E8F7),
          border: Border.all(
            color: cs.primary.withValues(alpha: 0.25),
            width: 1.5,
          ),
        ),
        child: Stack(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 2),
                  child: Icon(Icons.wb_sunny_rounded,
                      size: 14,
                      color: isDark
                          ? Colors.grey.withValues(alpha: 0.4)
                          : const Color(0xFFFFB347)),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 2),
                  child: Icon(Icons.nightlight_round,
                      size: 14,
                      color: isDark
                          ? cs.primary
                          : Colors.grey.withValues(alpha: 0.4)),
                ),
              ],
            ),
            AnimatedAlign(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              alignment:
                  isDark ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? cs.primary : const Color(0xFFFFB347),
                  boxShadow: [
                    BoxShadow(
                      color: (isDark ? cs.primary : const Color(0xFFFFB347))
                          .withValues(alpha: 0.4),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  isDark ? Icons.nightlight_round : Icons.wb_sunny_rounded,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────
//  SUMMARY CARD
// ─────────────────────────────────────────────────
class _SummaryCard extends StatelessWidget {
  final String label;
  final double amount;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.2 : 0.15),
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: color.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                )
              ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: cs.onSurface.withValues(alpha: 0.55),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                SizedBox(
                  width: double.infinity,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _fmt(amount),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(double v) => CurrencyFormatter.format(v);
}
