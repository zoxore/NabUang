import 'package:flutter/material.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../models/transaction_model.dart';

class TransactionListItem extends StatelessWidget {
  final TransactionModel transaction;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const TransactionListItem({
    super.key,
    required this.transaction,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final isIncome = transaction.tipe == 'Pemasukan';
    final isTransfer = transaction.tipe == 'Transfer';
    final color = isTransfer
        ? const Color(0xFF5B8DEF)
        : isIncome
            ? const Color(0xFF00C896)
            : const Color(0xFFFF6B6B);

    return GestureDetector(
      onTap: onTap,
      onLongPress: onDelete != null ? () => _confirmDelete(context) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark
                ? const Color(0xFF1E2538)
                : Colors.grey.withValues(alpha: 0.12),
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
            _buildIcon(color, isTransfer, cs),
            const SizedBox(width: 12),
            Expanded(child: _buildContent(context, cs)),
            const SizedBox(width: 10),
            _buildAmount(color, isTransfer, isIncome),
            if (onDelete != null) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _confirmDelete(context),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B6B).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.delete_outline_rounded,
                      color: Color(0xFFFF6B6B), size: 16),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<bool> _confirmDeleteAsync(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Hapus Transaksi?'),
            content: const Text(
                'Transaksi ini akan dihapus dan saldo dompet akan dikembalikan.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Batal')),
              TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Hapus',
                      style: TextStyle(color: Color(0xFFFF6B6B)))),
            ],
          ),
        ) ??
        false;
  }

  void _confirmDelete(BuildContext context) async {
    final ok = await _confirmDeleteAsync(context);
    if (ok && onDelete != null) onDelete!();
  }

  Widget _buildIcon(Color color, bool isTransfer, ColorScheme cs) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: transaction.iconKategori != null && !isTransfer
            ? Text(transaction.iconKategori!,
                style: const TextStyle(fontSize: 20))
            : Icon(
                isTransfer ? Icons.swap_horiz_rounded : Icons.receipt_outlined,
                color: color,
                size: 20,
              ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _getTitle(),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 3),
        _buildSubtitleWidget(cs),
        if (transaction.catatan.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            transaction.catatan,
            style: TextStyle(
              fontSize: 11,
              color: cs.onSurface.withValues(alpha: 0.35),
              fontStyle: FontStyle.italic,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  Widget _buildAmount(Color color, bool isTransfer, bool isIncome) {
    final prefix = isTransfer ? '' : isIncome ? '+' : '-';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '$prefix${_fmtCompact(transaction.nominal)}',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          _fmtTime(transaction.tanggal),
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }

  String _getTitle() {
    if (transaction.tipe == 'Transfer') {
      return '${transaction.namaDompet ?? '?'} → ${transaction.namaDompetTujuan ?? '?'}';
    }
    return transaction.namaKategori ?? transaction.tipe;
  }

  Widget _buildSubtitleWidget(ColorScheme cs) {
    final date = _fmtRelDate(transaction.tanggal);
    
    if (transaction.tipe == 'Transfer' && transaction.fee > 0) {
      return RichText(
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        text: TextSpan(
          style: TextStyle(
            fontSize: 12,
            color: cs.onSurface.withValues(alpha: 0.5),
          ),
          children: [
            TextSpan(text: '$date • '),
            TextSpan(
              text: 'Fee: ${CurrencyFormatter.format(transaction.fee)}',
              style: const TextStyle(
                color: Color(0xFFFFB347),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }
    
    final wallet = transaction.namaDompet ?? '';
    return Text(
      '$date • $wallet',
      style: TextStyle(
        fontSize: 12,
        color: cs.onSurface.withValues(alpha: 0.5),
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  String _fmtCompact(double v) => CurrencyFormatter.format(v);

  String _fmtRelDate(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(d.year, d.month, d.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'Hari ini';
    if (diff == 1) return 'Kemarin';
    return '${d.day}/${d.month}/${d.year}';
  }

  String _fmtTime(DateTime d) {
    return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }
}
