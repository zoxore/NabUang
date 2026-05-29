import 'package:flutter/material.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../models/wallet_model.dart';

class BalanceCard extends StatefulWidget {
  final double totalSaldo;
  final List<WalletModel> wallets;

  const BalanceCard({
    super.key,
    required this.totalSaldo,
    required this.wallets,
  });

  @override
  State<BalanceCard> createState() => _BalanceCardState();
}

class _BalanceCardState extends State<BalanceCard>
    with SingleTickerProviderStateMixin {
  bool _isHidden = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (context, child) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: isDark
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0E2A4A), Color(0xFF0A1A2E)],
                  )
                : const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF00C896), Color(0xFF0087FF)],
                  ),
            border: isDark
                ? Border.all(
                    color: const Color(0xFF00C896).withValues(alpha: 0.25),
                    width: 1.5,
                  )
                : null,
            boxShadow: [
              BoxShadow(
                color: (isDark
                        ? const Color(0xFF00C896)
                        : const Color(0xFF0087FF))
                    .withValues(alpha: isDark ? 0.12 * _pulseAnim.value : 0.3),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 18),
          _buildAmount(context),
          const SizedBox(height: 20),
          _buildDivider(context),
          const SizedBox(height: 16),
          _buildWalletChips(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white70 : Colors.white.withValues(alpha: 0.85);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF00C896) : Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (isDark ? const Color(0xFF00C896) : Colors.white)
                        .withValues(alpha: 0.5),
                    blurRadius: 6,
                  )
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Total Saldo',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: textColor,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: () => setState(() => _isHidden = !_isHidden),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              _isHidden
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              key: ValueKey(_isHidden),
              color: Colors.white.withValues(alpha: 0.7),
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAmount(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.15),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
          child: child,
        ),
      ),
      child: _isHidden
          ? const Text(
              'Rp ••••••••',
              key: ValueKey('hidden'),
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 3,
              ),
            )
          : Text(
              _formatRupiah(widget.totalSaldo),
              key: const ValueKey('visible'),
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Container(
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            Colors.white.withValues(alpha: 0.25),
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  Widget _buildWalletChips(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${widget.wallets.length} Dompet Aktif',
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.55),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: widget.wallets.map((wallet) {
              return Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: isDark ? 0.08 : 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      wallet.jenis == 'Cash'
                          ? Icons.payments_outlined
                          : Icons.phone_android_outlined,
                      size: 13,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      wallet.nama,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    if (!_isHidden) ...[
                      const SizedBox(width: 5),
                      Text(
                        _formatCompact(wallet.saldo),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  String _formatRupiah(double amount) => CurrencyFormatter.format(amount);

  String _formatCompact(double v) => CurrencyFormatter.format(v);
}
