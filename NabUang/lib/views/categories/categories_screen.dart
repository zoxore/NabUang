import 'package:flutter/material.dart';
import '../../models/category_model.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final pengeluaran =
        CategoryModel.dummyList.where((c) => c.tipe == 'Pengeluaran').toList();
    final pemasukan =
        CategoryModel.dummyList.where((c) => c.tipe == 'Pemasukan').toList();

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
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Kategori',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _showAddCategorySheet(context),
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
                                fontWeight: FontWeight.w600,
                              )),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Tab bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 46,
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: cs.onSurface.withValues(alpha: 0.06)),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: Colors.white,
                  unselectedLabelColor: cs.onSurface.withValues(alpha: 0.55),
                  labelStyle: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13),
                  unselectedLabelStyle: const TextStyle(fontSize: 13),
                  tabs: const [
                    Tab(text: '💸  Pengeluaran'),
                    Tab(text: '💰  Pemasukan'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildList(context, pengeluaran, const Color(0xFFFF6B6B)),
                  _buildList(context, pemasukan, const Color(0xFF00C896)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(
      BuildContext context, List<CategoryModel> categories, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      physics: const BouncingScrollPhysics(),
      itemCount: categories.length,
      itemBuilder: (context, i) {
        final cat = categories[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF1E2538)
                  : Colors.grey.withValues(alpha: 0.1),
            ),
            boxShadow: isDark
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Center(
                  child: Text(cat.icon,
                      style: const TextStyle(fontSize: 20)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(cat.nama,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: cs.onSurface,
                    )),
              ),
              Row(
                children: [
                  _actionBtn(context, Icons.edit_outlined,
                      cs.onSurface.withValues(alpha: 0.4), () {}),
                  const SizedBox(width: 6),
                  _actionBtn(context, Icons.delete_outline_rounded,
                      const Color(0xFFFF6B6B), () {}),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _actionBtn(BuildContext context, IconData icon, Color color,
      VoidCallback onTap) {
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

  void _showAddCategorySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => const _CategoryFormSheet(),
    );
  }
}

class _CategoryFormSheet extends StatefulWidget {
  const _CategoryFormSheet();

  @override
  State<_CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends State<_CategoryFormSheet> {
  final _namaCtrl = TextEditingController();
  String _tipe = 'Pengeluaran';
  String _selectedIcon = '📦';

  final List<String> _icons = [
    '🍔', '🚗', '🛍️', '🎮', '💊', '🧾', '🏠', '📚',
    '✈️', '💼', '💻', '📈', '💰', '🎁', '⚡', '🌊',
    '🎵', '🏋️', '🐾', '☕', '🌿', '🎨', '🏥', '🚀',
  ];

  @override
  void dispose() {
    _namaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const expColor = Color(0xFFFF6B6B);
    const incColor = Color(0xFF00C896);
    final activeColor = _tipe == 'Pengeluaran' ? expColor : incColor;

    return Padding(
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Tambah Kategori',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface)),
          const SizedBox(height: 16),
          Row(
            children: ['Pengeluaran', 'Pemasukan'].map((t) {
              final sel = _tipe == t;
              final c = t == 'Pengeluaran' ? expColor : incColor;
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: GestureDetector(
                  onTap: () => setState(() => _tipe = t),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 9),
                    decoration: BoxDecoration(
                      color: sel ? c.withValues(alpha: 0.12) : cs.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: sel ? c : cs.onSurface.withValues(alpha: 0.1)),
                    ),
                    child: Text(t,
                        style: TextStyle(
                          color: sel ? c : cs.onSurface.withValues(alpha: 0.5),
                          fontWeight:
                              sel ? FontWeight.w600 : FontWeight.w400,
                          fontSize: 13,
                        )),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _namaCtrl,
            style: TextStyle(color: cs.onSurface),
            decoration: const InputDecoration(
                labelText: 'Nama Kategori',
                prefixIcon: Icon(Icons.label_outline_rounded)),
          ),
          const SizedBox(height: 16),
          Text('Pilih Ikon',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface.withValues(alpha: 0.6))),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: _icons.map((icon) {
              final sel = _selectedIcon == icon;
              return GestureDetector(
                onTap: () => setState(() => _selectedIcon = icon),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 46, height: 46,
                  decoration: BoxDecoration(
                    color: sel
                        ? activeColor.withValues(alpha: 0.12)
                        : cs.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: sel ? activeColor : cs.onSurface.withValues(alpha: 0.1),
                      width: sel ? 1.5 : 1,
                    ),
                  ),
                  child: Center(
                    child: Text(icon,
                        style: const TextStyle(fontSize: 20)),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Simpan Kategori'),
            ),
          ),
        ],
      ),
    );
  }
}
