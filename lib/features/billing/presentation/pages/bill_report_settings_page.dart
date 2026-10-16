import 'package:flutter/material.dart';
import 'package:c_billing/core/services/bill_report_settings_service.dart';
import 'package:c_billing/core/services/language_service.dart';
import 'package:c_billing/core/localization/app_localizations.dart';
import 'package:c_billing/core/ui/glassy_toast.dart';
import 'package:c_billing/common_widgets/app_top_bar.dart';
import 'package:c_billing/core/theme/app_theme.dart';

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
          style: TextStyle(
            fontFamily: 'Literata',
            fontWeight: FontWeight.w700,
            color: AppColors.accent(context),
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
              style: TextStyle(fontFamily: 'Literata', color: AppTheme.grey600),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.action(context),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              _localizations.resetButton,
              style: TextStyle(
                fontFamily: 'Literata',
                color: AppTheme.white,
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
        GlassyToast.show(context, _localizations.settingsResetToDefaults);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: AppColors.accent(context)),
            )
          : Column(
              children: [
                AppTopBar(
                  title: 'Bill Print Settings',
                  subtitle: 'Choose columns to print on bills',
                  actions: [
                    AppTopBar.action(
                      icon: Icons.restart_alt_rounded,
                      onTap: _resetToDefaults,
                    ),
                  ],
                ),
                Expanded(
                  child: CustomScrollView(
              slivers: [
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
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.action(context).withValues(alpha: 0.1),
            AppColors.action(context).withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.accentSoft(context, 0.15),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: AppColors.headerGradient(context),
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentSoft(context, 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.view_column_rounded,
              color: AppTheme.white,
              size: 28,
            ),
          ),
          SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$visibleCount / ${_columns.length} ${_localizations.columnsVisible}',
                  style: TextStyle(
                    fontFamily: 'Literata',
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                    color: AppColors.accent(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _localizations.toggleColumnsDescription,
                  style: TextStyle(
                    fontFamily: 'Literata',
                    fontWeight: FontWeight.w400,
                    fontSize: 13,
                    color: AppTheme.grey600,
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
            color: AppColors.accentSoft(context, 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: AppColors.accent(context)),
        ),
        SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontFamily: 'Literata',
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: AppColors.accent(context),
          ),
        ),
      ],
    );
  }

  Widget _buildColumnTile(BillReportColumn column) {
    return Container(
      margin: EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: column.isVisible
              ? AppColors.action(context).withValues(alpha: 0.3)
              : AppColors.border(context),
          width: column.isVisible ? 1.5 : 1,
        ),
        boxShadow: column.isVisible
            ? [
                BoxShadow(
                  color: AppColors.accentSoft(context, 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ]
            : [
                BoxShadow(
                  color: AppTheme.black.withValues(alpha: 0.03),
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
                      AppColors.action(context).withValues(alpha: 0.15),
                      AppColors.action(context).withValues(alpha: 0.08),
                    ],
                  )
                : null,
            color: column.isVisible ? null : AppColors.chipFill(context),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _getColumnIcon(column.id),
            color: column.isVisible
                ? AppColors.action(context)
                : AppTheme.grey400,
            size: 22,
          ),
        ),
        title: Text(
          column.name,
          style: TextStyle(
            fontFamily: 'Literata',
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: column.isVisible ? AppTheme.black87 : AppTheme.grey600,
          ),
        ),
        subtitle: Text(
          _getColumnDescription(column.id),
          style: TextStyle(
            fontFamily: 'Literata',
            fontSize: 12,
            color: AppTheme.grey,
          ),
        ),
        trailing: Transform.scale(
          scale: 0.9,
          child: Switch(
            value: column.isVisible,
            onChanged: (value) => _toggleColumn(column.id, value),
            activeThumbColor: AppTheme.white,
            activeTrackColor: AppColors.action(context),
            inactiveThumbColor: AppTheme.white,
            inactiveTrackColor: AppTheme.grey300,
            trackOutlineColor: WidgetStateProperty.all(AppTheme.transparent),
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
            AppTheme.blue.withValues(alpha: 0.08),
            AppTheme.blue.withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.blue.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.lightbulb_outline_rounded,
              color: AppTheme.blue700,
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
                    color: AppTheme.blue700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _localizations.columnSelectionTip,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.grey600,
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
