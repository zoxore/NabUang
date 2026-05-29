import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/firestore_provider.dart';
import '../../models/transaction_model.dart';
import '../../core/utils/currency_formatter.dart';
import '../widgets/filter_bar.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  DateTimeRange? _selectedDateRange;
  String? _selectedWalletId;
  String _selectedType = 'Pengeluaran'; // 'Pengeluaran' atau 'Pemasukan'
  int _touchedIndex = -1;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDateRange = DateTimeRange(
      start: DateTime(now.year, now.month, 1),
      end: DateTime(now.year, now.month + 1, 0, 23, 59, 59),
    );
  }

  void _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: _selectedDateRange,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: Theme.of(context).colorScheme.primary,
                ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDateRange = DateTimeRange(
            start: picked.start,
            end: DateTime(picked.end.year, picked.end.month, picked.end.day, 23, 59, 59),
          ));
    }
  }

  List<TransactionModel> _applyFilter(List<TransactionModel> txList) {
    return txList.where((tx) {
      if (tx.tipe != _selectedType) return false;

      bool matchDate = true;
      if (_selectedDateRange != null) {
        matchDate = tx.tanggal.isAfter(_selectedDateRange!.start.subtract(const Duration(seconds: 1))) &&
            tx.tanggal.isBefore(_selectedDateRange!.end.add(const Duration(days: 1)));
      }

      final matchWallet = _selectedWalletId == null ||
          tx.idDompet == _selectedWalletId ||
          tx.idDompetTujuan == _selectedWalletId;
          
      return matchDate && matchWallet;
    }).toList();
  }

  // Define some vibrant colors for the pie chart
  final List<Color> _chartColors = [
    const Color(0xFF5D5FEF),
    const Color(0xFF00C896),
    const Color(0xFFFF6B6B),
    const Color(0xFFFFB347),
    const Color(0xFF9D4EDD),
    const Color(0xFF00B4D8),
    const Color(0xFFF15BB5),
    const Color(0xFFFEE440),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final walletsAsync = ref.watch(walletsProvider);
    final transactionsAsync = ref.watch(transactionsProvider);

    final wallets = walletsAsync.valueOrNull ?? [];
    final allTx = transactionsAsync.valueOrNull ?? [];
    final filtered = _applyFilter(allTx);

    // Grouping by category
    final Map<String, double> categoryTotals = {};
    final Map<String, String> categoryIcons = {};
    double totalAmount = 0;

    for (final tx in filtered) {
      final catName = tx.namaKategori ?? 'Lainnya';
      final catIcon = tx.iconKategori ?? '📁';
      categoryTotals[catName] = (categoryTotals[catName] ?? 0) + tx.nominal;
      categoryIcons[catName] = catIcon;
      totalAmount += tx.nominal;
    }

    // Sort categories by amount descending
    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

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
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Text(
                    'Laporan',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            
            // Type Toggle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: cs.onSurface.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _TypeToggleButton(
                        label: 'Pengeluaran',
                        isSelected: _selectedType == 'Pengeluaran',
                        activeColor: const Color(0xFFFF6B6B),
                        onTap: () => setState(() => _selectedType = 'Pengeluaran'),
                      ),
                    ),
                    Expanded(
                      child: _TypeToggleButton(
                        label: 'Pemasukan',
                        isSelected: _selectedType == 'Pemasukan',
                        activeColor: const Color(0xFF00C896),
                        onTap: () => setState(() => _selectedType = 'Pemasukan'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Filter Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: FilterBar(
                selectedDateRange: _selectedDateRange,
                selectedWalletId: _selectedWalletId,
                wallets: wallets,
                onPickDateRange: _pickDateRange,
                onClearDateRange: () => setState(() => _selectedDateRange = null),
                onWalletChanged: (id) => setState(() => _selectedWalletId = id),
              ),
            ),
            const SizedBox(height: 24),

            Expanded(
              child: transactionsAsync.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : sortedCategories.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.pie_chart_outline_rounded,
                                  size: 64, color: cs.onSurface.withValues(alpha: 0.2)),
                              const SizedBox(height: 16),
                              Text('Belum ada data',
                                  style: TextStyle(
                                      color: cs.onSurface.withValues(alpha: 0.5),
                                      fontSize: 16)),
                            ],
                          ),
                        )
                      : CustomScrollView(
                          physics: const BouncingScrollPhysics(),
                          slivers: [
                            SliverToBoxAdapter(
                              child: _buildChart(sortedCategories, totalAmount, cs),
                            ),
                            SliverPadding(
                              padding: const EdgeInsets.all(20),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    final entry = sortedCategories[index];
                                    final color = _chartColors[index % _chartColors.length];
                                    final percentage = (entry.value / totalAmount) * 100;
                                    final icon = categoryIcons[entry.key] ?? '📁';
                                    
                                    return _CategoryListItem(
                                      name: entry.key,
                                      amount: entry.value,
                                      percentage: percentage,
                                      color: color,
                                      icon: icon,
                                    );
                                  },
                                  childCount: sortedCategories.length,
                                ),
                              ),
                            ),
                            const SliverToBoxAdapter(child: SizedBox(height: 80)),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(List<MapEntry<String, double>> categories, double totalAmount, ColorScheme cs) {
    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        pieTouchResponse == null ||
                        pieTouchResponse.touchedSection == null) {
                      _touchedIndex = -1;
                      return;
                    }
                    _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                  });
                },
              ),
              borderData: FlBorderData(show: false),
              sectionsSpace: 2,
              centerSpaceRadius: 70,
              sections: List.generate(categories.length, (i) {
                final isTouched = i == _touchedIndex;
                final radius = isTouched ? 35.0 : 25.0;
                final value = categories[i].value;
                final percentage = (value / totalAmount) * 100;
                
                return PieChartSectionData(
                  color: _chartColors[i % _chartColors.length],
                  value: value,
                  title: percentage > 5 ? '${percentage.toStringAsFixed(0)}%' : '',
                  radius: radius,
                  titleStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              }),
            ),
          ),
          // Center Text
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Total $_selectedType',
                style: TextStyle(
                  fontSize: 11,
                  color: cs.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                CurrencyFormatter.format(totalAmount),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TypeToggleButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color activeColor;
  final VoidCallback onTap;

  const _TypeToggleButton({
    required this.label,
    required this.isSelected,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              color: isSelected ? activeColor : cs.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryListItem extends StatelessWidget {
  final String name;
  final double amount;
  final double percentage;
  final Color color;
  final String icon;

  const _CategoryListItem({
    required this.name,
    required this.amount,
    required this.percentage,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Row(
        children: [
          // Icon with color indicator
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Center(
              child: Text(icon, style: const TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percentage / 100,
                    backgroundColor: cs.onSurface.withValues(alpha: 0.05),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                CurrencyFormatter.format(amount),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
