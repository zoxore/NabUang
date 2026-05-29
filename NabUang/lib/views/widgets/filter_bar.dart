import 'package:flutter/material.dart';
import '../../models/wallet_model.dart';

class FilterBar extends StatelessWidget {
  final DateTimeRange? selectedDateRange;
  final String? selectedWalletId;
  final List<WalletModel> wallets;
  final VoidCallback onPickDateRange;
  final VoidCallback onClearDateRange;
  final ValueChanged<String?> onWalletChanged;

  const FilterBar({
    super.key,
    required this.selectedDateRange,
    required this.selectedWalletId,
    required this.wallets,
    required this.onPickDateRange,
    required this.onClearDateRange,
    required this.onWalletChanged,
  });

  static const _months = [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    String dateText;
    if (selectedDateRange == null) {
      dateText = 'Semua Waktu';
    } else {
      final start = selectedDateRange!.start;
      final end = selectedDateRange!.end;
      if (start.year == end.year && start.month == end.month && start.day == 1 && end.day == DateTime(end.year, end.month + 1, 0).day) {
        // Full month selected
        dateText = '${_months[start.month]} ${start.year}';
      } else {
        dateText = '${start.day} ${_months[start.month]} - ${end.day} ${_months[end.month]} ${end.year}';
      }
    }

    return Column(
      children: [
        // Date navigator
        Row(
          children: [
            Expanded(
              child: Material(
                color: cs.surface,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  onTap: onPickDateRange,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: cs.onSurface.withValues(alpha: 0.08)),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.calendar_month_outlined, size: 18, color: cs.primary),
                        const SizedBox(width: 8),
                        Text(
                          dateText,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (selectedDateRange != null) ...[
              const SizedBox(width: 8),
              IconButton(
                onPressed: onClearDateRange,
                icon: const Icon(Icons.close_rounded),
                tooltip: 'Tampilkan Semua Waktu',
                style: IconButton.styleFrom(
                  backgroundColor: cs.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: cs.onSurface.withValues(alpha: 0.08)),
                  ),
                ),
              ),
            ]
          ],
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
