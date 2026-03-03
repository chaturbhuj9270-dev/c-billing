import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:c_billing/core/services/bill_report_settings_service.dart';
import 'package:c_billing/core/services/language_service.dart';
import 'package:c_billing/core/localization/app_localizations.dart';

/// Page for managing which columns appear in bill prints/reports
class BillReportSettingsPage extends StatefulWidget {
  const BillReportSettingsPage({super.key});

  @override
  State<BillReportSettingsPage> createState() => _BillReportSettingsPageState();
}

class _BillReportSettingsPageState extends State<BillReportSettingsPage>
    with SingleTickerProviderStateMixin {
  late List<BillReportColumn> _columns;
  bool _isLoading = true;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late AppLocalizations _localizations;

  @override
  void initState() {
    super.initState();
    _localizations = AppLocalizations(LanguageService.instance.currentLanguage);
    LanguageService.instance.addListener(_onLanguageChanged);
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    _loadColumns();
  }

  void _onLanguageChanged() {
    if (mounted) {
      setState(() {
        _localizations = AppLocalizations(
          LanguageService.instance.currentLanguage,
        );
      });
    }
  }

  @override
  void dispose() {
    LanguageService.instance.removeListener(_onLanguageChanged);
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadColumns() async {
    await BillReportSettingsService.instance.init();
    setState(() {
      _columns = List.from(BillReportSettingsService.instance.columns);
      _isLoading = false;
    });
    _animController.forward();
  }

  Future<void> _toggleColumn(String columnId, bool isVisible) async {
    await BillReportSettingsService.instance.setColumnVisibility(
      columnId,
      isVisible,
    );
    setState(() {
      final index = _columns.indexWhere((c) => c.id == columnId);
      if (index != -1) {
        _columns[index] = _columns[index].copyWith(isVisible: isVisible);
      }
    });
  }

  Future<void> _resetToDefaults() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          _localizations.resetToDefaults,
          style: const TextStyle(
            fontFamily: 'Literata',
            fontWeight: FontWeight.w700,
            color: Color(0xFF1B4D3E),
          ),
        ),
        content: Text(
          _localizations.resetColumnVisibilityConfirm,
          style: const TextStyle(fontFamily: 'Literata'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              _localizations.cancel,
              style: TextStyle(fontFamily: 'Literata', color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B4D3E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              _localizations.resetButton,
              style: const TextStyle(
                fontFamily: 'Literata',
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await BillReportSettingsService.instance.resetToDefaults();
      await _loadColumns();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _localizations.settingsResetToDefaults,
              style: const TextStyle(fontFamily: 'Literata'),
            ),
            backgroundColor: const Color(0xFF1B4D3E),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F6),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1B4D3E)),
            )
          : CustomScrollView(
              slivers: [
                // Sticky Header with Glass Effect
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _BillReportHeaderDelegate(
                    minHeight: 100,
                    maxHeight: 140,
                    onBack: () => Navigator.pop(context),
                    onReset: _resetToDefaults,
                  ),
                ),

                // Main Content
                SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Summary card
                          _buildSummaryCard(),
                          const SizedBox(height: 24),

                          // Product Info Columns
                          _buildSectionTitle(
                            _localizations.productInformation,
                            Icons.inventory_2_rounded,
                          ),
                          const SizedBox(height: 12),
                          ..._columns
                              .where((c) => _isProductInfoColumn(c.id))
                              .map((column) => _buildColumnTile(column)),

                          const SizedBox(height: 24),

                          // Pricing Columns
                          _buildSectionTitle(
                            _localizations.pricingAndAmount,
                            Icons.currency_rupee_rounded,
                          ),
                          const SizedBox(height: 12),
                          ..._columns
                              .where((c) => _isPricingColumn(c.id))
                              .map((column) => _buildColumnTile(column)),

                          const SizedBox(height: 24),

                          // Info Card
                          _buildInfoCard(),

                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  bool _isProductInfoColumn(String id) {
    return [
      'sr_no',
      'product_name',
      'hsn_code',
      'company',
      'quantity',
      'unit',
    ].contains(id);
  }

  bool _isPricingColumn(String id) {
    return ['rate', 'discount', 'tax', 'amount'].contains(id);
  }

  Widget _buildSummaryCard() {
    final visibleCount = _columns.where((c) => c.isVisible).length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1B4D3E).withOpacity(0.1),
            const Color(0xFF1B4D3E).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1B4D3E).withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1B4D3E), Color(0xFF2D6A4F)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1B4D3E).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.view_column_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$visibleCount / ${_columns.length} ${_localizations.columnsVisible}',
                  style: const TextStyle(
                    fontFamily: 'Literata',
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                    color: Color(0xFF1B4D3E),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _localizations.toggleColumnsDescription,
                  style: TextStyle(
                    fontFamily: 'Literata',
                    fontWeight: FontWeight.w400,
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFF1B4D3E).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: const Color(0xFF1B4D3E)),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Literata',
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: Color(0xFF1B4D3E),
          ),
        ),
      ],
    );
  }

  Widget _buildColumnTile(BillReportColumn column) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: column.isVisible
              ? const Color(0xFF1B4D3E).withOpacity(0.3)
              : Colors.grey[200]!,
          width: column.isVisible ? 1.5 : 1,
        ),
        boxShadow: column.isVisible
            ? [
                BoxShadow(
                  color: const Color(0xFF1B4D3E).withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: column.isVisible
                ? LinearGradient(
                    colors: [
                      const Color(0xFF1B4D3E).withOpacity(0.15),
                      const Color(0xFF1B4D3E).withOpacity(0.08),
                    ],
                  )
                : null,
            color: column.isVisible ? null : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _getColumnIcon(column.id),
            color: column.isVisible
                ? const Color(0xFF1B4D3E)
                : Colors.grey[400],
            size: 22,
          ),
        ),
        title: Text(
          column.name,
          style: TextStyle(
            fontFamily: 'Literata',
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: column.isVisible ? Colors.black87 : Colors.grey[600],
          ),
        ),
        subtitle: Text(
          _getColumnDescription(column.id),
          style: TextStyle(
            fontFamily: 'Literata',
            fontSize: 12,
            color: Colors.grey[500],
          ),
        ),
        trailing: Transform.scale(
          scale: 0.9,
          child: Switch(
            value: column.isVisible,
            onChanged: (value) => _toggleColumn(column.id, value),
            activeThumbColor: Colors.white,
            activeTrackColor: const Color(0xFF1B4D3E),
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: Colors.grey[300],
            trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.withOpacity(0.08),
            Colors.blue.withOpacity(0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.lightbulb_outline_rounded,
              color: Colors.blue[700],
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _localizations.proTip,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Literata',
                    color: Colors.blue[700],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _localizations.columnSelectionTip,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontFamily: 'Literata',
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getColumnIcon(String columnId) {
    switch (columnId) {
      case 'sr_no':
        return Icons.format_list_numbered_rounded;
      case 'product_name':
        return Icons.inventory_2_rounded;
      case 'hsn_code':
        return Icons.tag_rounded;
      case 'company':
        return Icons.business_rounded;
      case 'quantity':
        return Icons.numbers_rounded;
      case 'unit':
        return Icons.straighten_rounded;
      case 'rate':
        return Icons.currency_rupee_rounded;
      case 'discount':
        return Icons.discount_rounded;
      case 'tax':
        return Icons.receipt_long_rounded;
      case 'amount':
        return Icons.calculate_rounded;
      default:
        return Icons.view_column_rounded;
    }
  }

  String _getColumnDescription(String columnId) {
    switch (columnId) {
      case 'sr_no':
        return 'Serial number for each item';
      case 'product_name':
        return 'Name of the product';
      case 'hsn_code':
        return 'HSN/SAC code for GST';
      case 'company':
        return 'Product manufacturer/company';
      case 'quantity':
        return 'Quantity of items sold';
      case 'unit':
        return 'Unit of measurement';
      case 'rate':
        return 'Price per unit';
      case 'discount':
        return 'Discount amount per item';
      case 'tax':
        return 'Tax amount per item';
      case 'amount':
        return 'Total amount per item';
      default:
        return 'Custom column';
    }
  }
}

/// Header delegate for bill report settings page
class _BillReportHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final VoidCallback onBack;
  final VoidCallback onReset;

  _BillReportHeaderDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.onBack,
    required this.onReset,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final progress = shrinkOffset / (maxHeight - minHeight);
    final isCollapsed = progress > 0.5;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B4D3E), Color(0xFF2D6A4F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B4D3E).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      // Back Button
                      GestureDetector(
                        onTap: onBack,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                            ),
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Title
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Bill Print Settings',
                              style: TextStyle(
                                fontSize: isCollapsed ? 18 : 22,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'Literata',
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            if (!isCollapsed) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Choose columns to print on bills',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontFamily: 'Literata',
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      // Reset Button
                      GestureDetector(
                        onTap: onReset,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.restart_alt_rounded,
                                color: Colors.white.withOpacity(0.9),
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Reset',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Literata',
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_BillReportHeaderDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight;
  }
}
