import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/session_manager.dart';
import '../../../product/offline/entities/product_entity.dart';
import '../../../supplier/offline/entities/supplier_entity.dart';
import '../../data/repositories/report_repository.dart';
import '../../data/services/report_service.dart';
import '../../data/services/report_pdf_generator.dart';
import '../../domain/models/report_filter_model.dart';
import '../../domain/models/report_result_model.dart';
import 'package:c_billing/common_widgets/range_calendar_sheet.dart';
import 'package:c_billing/core/ui/glassy_toast.dart';
import 'package:c_billing/common_widgets/app_top_bar.dart';
import 'package:c_billing/core/theme/app_theme.dart';
import 'package:c_billing/common_widgets/file_preview_page.dart';
import 'package:c_billing/common_widgets/glass_bottom_sheet.dart';

// ────────────────────────────────────────────────────────── Premium Report Page — v2 ✅ Date presets (Today / This Week / This Month / This Year / Custom) ✅ Advanced filters: prod...

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage>
    with SingleTickerProviderStateMixin {
  final _sessionManager = SessionManager();

  // Lazy access — won't crash if the local database is still warming up
  late final ReportService _reportService;
  late final ReportRepository _repo;

  // ── Filter state ──
  ReportFilterModel _filter = ReportFilterModel.thisMonth();
  int _selectedPreset = 2; // This Month

  // ── Advanced filters ──
  bool _showAdvanced = false;
  ProductEntity? _selectedProduct;
  SupplierEntity? _selectedSupplier;
  final _minPriceCtrl = TextEditingController();
  final _maxPriceCtrl = TextEditingController();
  final _productSearchCtrl = TextEditingController();
  Timer? _searchDebounce;

  // ── Dropdowns ──
  List<ProductEntity> _products = [];
  List<SupplierEntity> _suppliers = [];
  bool _isLoadingDropdowns = true;

  // ── Report state ──
  bool _isGenerating = false;
  ReportResultModel? _reportResult;
  Uint8List? _pdfBytes;
  String? _savedFilePath;

  // ── Animation ──
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _reportService = ReportService.instance;
    _repo = ReportRepository.instance;
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _loadDropdowns();
  }

  @override
  void dispose() {
    _minPriceCtrl.dispose();
    _maxPriceCtrl.dispose();
    _productSearchCtrl.dispose();
    _searchDebounce?.cancel();
    _fadeCtrl.dispose();
    super.dispose();
  }

  // ━━━━━━━━━━━━ DATA ━━━━━━━━━━━━

  Future<void> _loadDropdowns() async {
    try {
      final results = await Future.wait([
        _repo.searchProducts(''),
        _repo.getSuppliers(),
      ]);
      if (mounted) {
        setState(() {
          _products = results[0] as List<ProductEntity>;
          _suppliers = results[1] as List<SupplierEntity>;
          _isLoadingDropdowns = false;
        });
      }
    } catch (e) {
      debugPrint('[ReportPage] Load dropdowns error: $e');
      if (mounted) setState(() => _isLoadingDropdowns = false);
    }
  }

  Future<void> _searchProducts(String query) async {
    try {
      final results = await _repo.searchProducts(query);
      if (mounted) setState(() => _products = results);
    } catch (_) {}
  }

  // ━━━━━━━━━━━━ ACTIONS ━━━━━━━━━━━━

  void _selectPreset(int index) {
    setState(() {
      _selectedPreset = index;
      _reportResult = null;
      _pdfBytes = null;
      _savedFilePath = null;
      switch (index) {
        case 0:
          _filter = _filter.copyWith(
            startDate: ReportFilterModel.today().startDate,
            endDate: ReportFilterModel.today().endDate,
            presetLabel: 'Today',
          );
          break;
        case 1:
          _filter = _filter.copyWith(
            startDate: ReportFilterModel.thisWeek().startDate,
            endDate: ReportFilterModel.thisWeek().endDate,
            presetLabel: 'This Week',
          );
          break;
        case 2:
          _filter = _filter.copyWith(
            startDate: ReportFilterModel.thisMonth().startDate,
            endDate: ReportFilterModel.thisMonth().endDate,
            presetLabel: 'This Month',
          );
          break;
        case 3:
          _filter = _filter.copyWith(
            startDate: ReportFilterModel.thisYear().startDate,
            endDate: ReportFilterModel.thisYear().endDate,
            presetLabel: 'This Year',
          );
          break;
        case 4:
          _pickCustomDateRange();
          break;
      }
    });
  }

  Future<void> _pickCustomDateRange() async {
    final picked = await showAppRangeCalendar(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: _filter.startDate,
        end: _filter.endDate,
      ),
    );
    if (picked != null) {
      setState(() {
        _filter = _filter.copyWith(
          startDate: picked.start,
          endDate: DateTime(
            picked.end.year,
            picked.end.month,
            picked.end.day,
            23,
            59,
            59,
          ),
          presetLabel:
              '${DateFormat('dd/MM').format(picked.start)} – ${DateFormat('dd/MM').format(picked.end)}',
        );
        _reportResult = null;
        _pdfBytes = null;
        _savedFilePath = null;
      });
    }
  }

  void _applyAdvancedFilters() {
    setState(() {
      _filter = _filter.copyWith(
        productId: _selectedProduct?.serverId,
        productName: _selectedProduct?.name,
        supplierId: _selectedSupplier?.serverId,
        supplierName: _selectedSupplier?.fullName,
        minPrice: _minPriceCtrl.text.isNotEmpty
            ? double.tryParse(_minPriceCtrl.text)
            : null,
        maxPrice: _maxPriceCtrl.text.isNotEmpty
            ? double.tryParse(_maxPriceCtrl.text)
            : null,
        clearProduct: _selectedProduct == null,
        clearSupplier: _selectedSupplier == null,
        clearMinPrice: _minPriceCtrl.text.isEmpty,
        clearMaxPrice: _maxPriceCtrl.text.isEmpty,
      );
      _showAdvanced = false;
      _reportResult = null;
      _pdfBytes = null;
      _savedFilePath = null;
    });
    _showSnackbar('Filters applied', false);
  }

  void _resetAdvancedFilters() {
    setState(() {
      _selectedProduct = null;
      _selectedSupplier = null;
      _minPriceCtrl.clear();
      _maxPriceCtrl.clear();
      _filter = _filter.copyWith(
        clearProduct: true,
        clearSupplier: true,
        clearMinPrice: true,
        clearMaxPrice: true,
        expiredOnly: false,
        expiringThisWeek: false,
        returnedOnly: false,
        lowStockOnly: false,
      );
      _reportResult = null;
      _pdfBytes = null;
      _savedFilePath = null;
    });
    _showSnackbar('Filters reset', false);
  }

  // ━━━━━━━━━━━━ GENERATE ━━━━━━━━━━━━

  Future<void> _generateReport() async {
    setState(() {
      _isGenerating = true;
      _reportResult = null;
      _pdfBytes = null;
      _savedFilePath = null;
    });
    _fadeCtrl.reset();

    try {
      final report = await _reportService.generateReport(_filter);
      if (!mounted) return;

      if (report.isEmpty) {
        _showSnackbar('No data found for selected filters', true);
        setState(() => _isGenerating = false);
        return;
      }

      final pdfBytes = await ReportPdfGenerator.generate(report);
      if (!mounted) return;

      setState(() {
        _reportResult = report;
        _pdfBytes = pdfBytes;
        _isGenerating = false;
      });
      _fadeCtrl.forward();
    } catch (e) {
      debugPrint('[ReportPage] Generate error: $e');
      if (mounted) {
        _showSnackbar('Error generating report: $e', true);
        setState(() => _isGenerating = false);
      }
    }
  }

  Future<void> _saveLocally() async {
    if (_pdfBytes == null) return;
    final path = await ReportPdfGenerator.saveLocally(_pdfBytes!);
    if (!mounted) return;
    if (path != null) {
      setState(() => _savedFilePath = path);
      _showSnackbar('Saved to: ${path.split('/').last}', false);
    } else {
      _showSnackbar('Failed to save report', true);
    }
  }

  Future<void> _shareReport() async {
    if (_pdfBytes == null) return;
    try {
      await ReportPdfGenerator.shareReport(_pdfBytes!);
    } catch (e) {
      if (mounted) _showSnackbar('Failed to share: $e', true);
    }
  }

  Future<void> _printReport() async {
    if (_pdfBytes == null) return;
    try {
      await FilePreviewPage.open(
        context,
        bytes: _pdfBytes,
        fileName: 'Inventory Report',
        fileType: FilePreviewType.pdf,
        subtitle: _reportResult?.filterSummary,
        centered: true,
      );
    } catch (e) {
      if (mounted) _showSnackbar('Failed to print: $e', true);
    }
  }

  void _showSnackbar(String msg, bool isError) {
    if (!mounted) return;
    GlassyToast.show(context, msg);
  }

  // ━━━━━━━━━━━━ BUILD ━━━━━━━━━━━━

  @override
  Widget build(BuildContext context) {
    _sessionManager.resetSession();
    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      body: Stack(
        children: [
          Column(
            children: [
              const AppTopBar(
                title: 'Reports',
                subtitle: 'Generate • Save • Share',
              ),
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildDateFilterChips(),
                    const SizedBox(height: 14),
                    _buildActiveFiltersBar(),
                    const SizedBox(height: 14),
                    _buildAdvancedFiltersCard(),
                    const SizedBox(height: 20),
                    _buildGenerateButton(),
                    if (_reportResult != null) ...[
                      const SizedBox(height: 20),
                      FadeTransition(
                        opacity: _fadeAnim,
                        child: _buildSummaryPreview(),
                      ),
                      const SizedBox(height: 14),
                      FadeTransition(
                        opacity: _fadeAnim,
                        child: _buildActionButtons(),
                      ),
                    ],
                  ]),
                    ),
                  ),
                  ],
                ),
              ),
            ],
          ),
          // Full-screen loading overlay
          if (_isGenerating) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  // ─── DATE FILTER CHIPS ───

  Widget _buildDateFilterChips() {
    const labels = ['Today', 'Week', 'Month', 'Year', 'Custom'];
    const icons = [
      Icons.today,
      Icons.date_range,
      Icons.calendar_month,
      Icons.calendar_today_outlined,
      Icons.tune,
    ];

    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.action(context).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.event_note_rounded,
                  color: AppColors.action(context),
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Date Range',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Literata',
                  color: AppColors.action(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(labels.length, (i) {
                final selected = _selectedPreset == i;
                return Padding(
                  padding: EdgeInsets.only(right: i < 4 ? 8 : 0),
                  child: GestureDetector(
                    onTap: () => _selectPreset(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.action(context) : AppColors.chipFill(context),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected ? AppColors.action(context) : AppTheme.grey300,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            icons[i],
                            size: 14,
                            color: selected ? AppTheme.white : AppTheme.grey600,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            labels[i],
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Literata',
                              color: selected ? AppTheme.white : AppTheme.grey700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.action(context).withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.event, size: 14, color: AppTheme.grey600),
                const SizedBox(width: 6),
                Text(
                  '${DateFormat('dd MMM yyyy').format(_filter.startDate)} — ${DateFormat('dd MMM yyyy').format(_filter.endDate)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'Literata',
                    color: AppTheme.grey700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── ACTIVE FILTERS BAR ───

  Widget _buildActiveFiltersBar() {
    final chips = <Widget>[];
    if (_filter.productName != null) {
      chips.add(
        _buildActiveChip(
          'Product: ${_filter.productName}',
          Icons.inventory_2_outlined,
        ),
      );
    }
    if (_filter.supplierName != null) {
      chips.add(
        _buildActiveChip(
          'Supplier: ${_filter.supplierName}',
          Icons.local_shipping_outlined,
        ),
      );
    }
    if (_filter.expiredOnly) {
      chips.add(
        _buildActiveChip(
          'Expired',
          Icons.warning_amber_rounded,
          color: AppTheme.red,
        ),
      );
    }
    if (_filter.expiringThisWeek) {
      chips.add(
        _buildActiveChip('Expiring Soon', Icons.schedule, color: AppTheme.orange),
      );
    }
    if (_filter.returnedOnly) {
      chips.add(_buildActiveChip('Returned', Icons.keyboard_return_rounded));
    }
    if (_filter.lowStockOnly) {
      chips.add(
        _buildActiveChip(
          'Low Stock',
          Icons.trending_down,
          color: AppTheme.orange,
        ),
      );
    }
    if (_filter.minPrice != null || _filter.maxPrice != null) {
      final range =
          '₹${_filter.minPrice?.toStringAsFixed(0) ?? '0'} – ₹${_filter.maxPrice?.toStringAsFixed(0) ?? '∞'}';
      chips.add(_buildActiveChip(range, Icons.currency_rupee));
    }

    if (chips.isEmpty) return const SizedBox.shrink();
    return Wrap(spacing: 8, runSpacing: 6, children: chips);
  }

  Widget _buildActiveChip(
    String label,
    IconData icon, {
    Color? color,
  }) {
    final chipColor = color ?? AppColors.action(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: chipColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: chipColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontFamily: 'Literata',
              fontWeight: FontWeight.w600,
              color: chipColor,
            ),
          ),
        ],
      ),
    );
  }

  // ─── ADVANCED FILTERS CARD ───

  Widget _buildAdvancedFiltersCard() {
    return _buildCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          GestureDetector(
            onTap: () => setState(() => _showAdvanced = !_showAdvanced),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.action(context).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.filter_alt_outlined,
                      color: AppColors.action(context),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Advanced Filters',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Literata',
                        color: AppColors.action(context),
                      ),
                    ),
                  ),
                  if (_filter.hasAdvancedFilters)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.action(context),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Active',
                        style: TextStyle(
                          color: AppTheme.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Literata',
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: _showAdvanced ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.expand_more, color: AppTheme.grey600),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _buildAdvancedBody(),
            crossFadeState: _showAdvanced
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedBody() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1),
          const SizedBox(height: 12),
          _buildLabel('Product'),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: _showProductPicker,
            child: _buildDropdownField(
              _selectedProduct?.name ?? 'All Products',
              Icons.inventory_2_outlined,
              _selectedProduct != null,
            ),
          ),
          const SizedBox(height: 12),
          _buildLabel('Supplier'),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: _showSupplierPicker,
            child: _buildDropdownField(
              _selectedSupplier?.fullName ?? 'All Suppliers',
              Icons.local_shipping_outlined,
              _selectedSupplier != null,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildToggleChip(
                'Expired',
                Icons.warning_amber_rounded,
                _filter.expiredOnly,
                (v) =>
                    setState(() => _filter = _filter.copyWith(expiredOnly: v)),
              ),
              _buildToggleChip(
                'Expiring Soon',
                Icons.schedule,
                _filter.expiringThisWeek,
                (v) => setState(
                  () => _filter = _filter.copyWith(expiringThisWeek: v),
                ),
              ),
              _buildToggleChip(
                'Returned',
                Icons.keyboard_return_rounded,
                _filter.returnedOnly,
                (v) =>
                    setState(() => _filter = _filter.copyWith(returnedOnly: v)),
              ),
              _buildToggleChip(
                'Low Stock',
                Icons.trending_down,
                _filter.lowStockOnly,
                (v) =>
                    setState(() => _filter = _filter.copyWith(lowStockOnly: v)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildLabel('Price Range'),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(child: _buildPriceField(_minPriceCtrl, 'Min Price')),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '—',
                  style: TextStyle(color: AppTheme.grey, fontFamily: 'Literata'),
                ),
              ),
              Expanded(child: _buildPriceField(_maxPriceCtrl, 'Max Price')),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _resetAdvancedFilters,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text(
                    'Reset',
                    style: TextStyle(
                      fontFamily: 'Literata',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.action(context),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _applyAdvancedFilters,
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text(
                    'Apply',
                    style: TextStyle(
                      fontFamily: 'Literata',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.action(context),
                    foregroundColor: AppTheme.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── GENERATE BUTTON ───

  Widget _buildGenerateButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: _isGenerating ? null : _generateReport,
        icon: const Icon(Icons.assessment_rounded, size: 20),
        label: const Text(
          'Generate Report',
          style: TextStyle(
            fontFamily: 'Literata',
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.action(context),
          foregroundColor: AppTheme.white,
          disabledBackgroundColor: AppTheme.grey300,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  // ─── SUMMARY PREVIEW ───

  Widget _buildSummaryPreview() {
    final r = _reportResult!;
    return _buildCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            decoration: BoxDecoration(
              color: AppColors.action(context).withValues(alpha: 0.06),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.action(context).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.analytics_outlined,
                    color: AppColors.action(context),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Report Summary',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Literata',
                          color: AppColors.action(context),
                        ),
                      ),
                      Text(
                        '${r.totalProducts} products • ${_filter.presetLabel}',
                        style: TextStyle(
                          fontSize: 11,
                          fontFamily: 'Literata',
                          color: AppTheme.grey600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_savedFilePath != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, size: 12, color: AppTheme.green),
                        SizedBox(width: 3),
                        Text(
                          'Saved',
                          style: TextStyle(
                            fontSize: 10,
                            fontFamily: 'Literata',
                            fontWeight: FontWeight.w600,
                            color: AppTheme.green,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          // Stats grid
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Row(
                  children: [
                    _buildStatTile(
                      icon: Icons.shopping_cart_outlined,
                      label: 'Total Purchase',
                      value: _fmtAmt(r.totalPurchaseAmount),
                      color: AppTheme.lightBlue800,
                    ),
                    const SizedBox(width: 10),
                    _buildStatTile(
                      icon: Icons.point_of_sale_rounded,
                      label: 'Total Sales',
                      value: _fmtAmt(r.totalSalesAmount),
                      color: AppColors.action(context),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildStatTile(
                      icon: Icons.trending_up_rounded,
                      label: 'Profit',
                      value: _fmtAmt(r.totalProfit),
                      color: AppTheme.green800,
                    ),
                    const SizedBox(width: 10),
                    _buildStatTile(
                      icon: Icons.trending_down_rounded,
                      label: 'Loss',
                      value: _fmtAmt(r.totalLoss),
                      color: AppTheme.red800,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildStatTile(
                      icon: Icons.warning_amber_rounded,
                      label: 'Expired',
                      value: '${r.expiredCount} items',
                      sub: _fmtAmt(r.expiredStockValue),
                      color: AppTheme.red700,
                    ),
                    const SizedBox(width: 10),
                    _buildStatTile(
                      icon: Icons.keyboard_return_rounded,
                      label: 'Returned',
                      value: '${r.returnedCount} items',
                      sub: _fmtAmt(r.returnedStockValue),
                      color: AppTheme.orange900,
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

  Widget _buildStatTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    String? sub,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontFamily: 'Literata',
                      color: AppTheme.grey600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontFamily: 'Literata',
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            if (sub != null) ...[
              const SizedBox(height: 2),
              Text(
                sub,
                style: TextStyle(
                  fontSize: 11,
                  fontFamily: 'Literata',
                  color: color.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─── ACTION BUTTONS ───

  Widget _buildActionButtons() {
    return _buildCard(
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.action(context).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.picture_as_pdf_rounded,
                  color: AppColors.action(context),
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PDF Ready',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Literata',
                        color: AppColors.action(context),
                      ),
                    ),
                    Text(
                      'Save, share, or print your report',
                      style: TextStyle(
                        fontSize: 11,
                        fontFamily: 'Literata',
                        color: AppTheme.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Primary row: Save + Share
          Row(
            children: [
              Expanded(
                child: _buildActionBtn(
                  icon: Icons.save_alt_rounded,
                  label: _savedFilePath != null ? 'Saved ✓' : 'Save',
                  color: AppTheme.lightBlue800,
                  onTap: _savedFilePath != null ? null : _saveLocally,
                  filled: _savedFilePath == null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildActionBtn(
                  icon: Icons.share_rounded,
                  label: 'Share',
                  color: AppTheme.purple700,
                  onTap: _shareReport,
                  filled: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Secondary: Print
          SizedBox(
            width: double.infinity,
            child: _buildActionBtn(
              icon: Icons.print_rounded,
              label: 'Print / Preview',
              color: AppColors.action(context),
              onTap: _printReport,
              filled: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBtn({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
    bool filled = true,
  }) {
    return SizedBox(
      height: 46,
      child: filled
          ? ElevatedButton.icon(
              onPressed: onTap,
              icon: Icon(icon, size: 18),
              label: Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Literata',
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: AppTheme.white,
                disabledBackgroundColor: color.withValues(alpha: 0.5),
                disabledForegroundColor: AppTheme.white70,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            )
          : OutlinedButton.icon(
              onPressed: onTap,
              icon: Icon(icon, size: 18),
              label: Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Literata',
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: color,
                side: BorderSide(color: color.withValues(alpha: 0.4)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
    );
  }

  // ─── LOADING OVERLAY ───

  Widget _buildLoadingOverlay() {
    return Container(
      color: AppTheme.black.withValues(alpha: 0.3),
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          decoration: BoxDecoration(
            color: AppColors.card(context),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppTheme.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation(AppColors.action(context)),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Generating Report...',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Literata',
                  color: AppColors.action(context),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Analyzing ${_filter.presetLabel.toLowerCase()} data',
                style: TextStyle(
                  fontSize: 12,
                  fontFamily: 'Literata',
                  color: AppTheme.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ━━━━━━━━━━━━ HELPERS ━━━━━━━━━━━━

  Widget _buildCard({required Widget child, EdgeInsetsGeometry? padding}) {
    return Container(
      padding: padding ?? EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        fontFamily: 'Literata',
        color: AppTheme.grey700,
      ),
    );
  }

  Widget _buildDropdownField(String text, IconData icon, bool hasValue) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.scaffold(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.grey300),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.grey600),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                fontFamily: 'Literata',
                color: hasValue ? AppColors.action(context) : AppTheme.grey,
                fontWeight: hasValue ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          Icon(Icons.keyboard_arrow_down, color: AppTheme.grey, size: 20),
        ],
      ),
    );
  }

  Widget _buildToggleChip(
    String label,
    IconData icon,
    bool active,
    ValueChanged<bool> onChanged,
  ) {
    return GestureDetector(
      onTap: () => onChanged(!active),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: active ? AppColors.action(context).withValues(alpha: 0.12) : AppColors.chipFill(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? AppColors.action(context).withValues(alpha: 0.4) : AppTheme.grey300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: active ? AppColors.action(context) : AppTheme.grey600),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                fontFamily: 'Literata',
                color: active ? AppColors.action(context) : AppTheme.grey700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceField(TextEditingController ctrl, String hint) {
    return SizedBox(
      height: 42,
      child: TextField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        style: TextStyle(fontFamily: 'Literata', fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: AppTheme.grey400, fontSize: 12),
          prefixText: '₹ ',
          prefixStyle: TextStyle(
            fontFamily: 'Literata',
            fontSize: 13,
            color: AppTheme.grey600,
          ),
          filled: true,
          fillColor: AppColors.scaffold(context),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: AppTheme.grey300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: AppTheme.grey300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: AppColors.action(context), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 0,
          ),
          isDense: true,
        ),
      ),
    );
  }

  String _fmtAmt(double val) {
    if (val == 0) return '₹0';
    if (val.abs() >= 100000) {
      return '₹${(val / 100000).toStringAsFixed(1)}L';
    }
    if (val.abs() >= 1000) {
      return '₹${(val / 1000).toStringAsFixed(1)}K';
    }
    if (val < 0) return '-₹${val.abs().toStringAsFixed(0)}';
    return '₹${val.toStringAsFixed(0)}';
  }

  // ─── PRODUCT PICKER ───

  void _showProductPicker() {
    _productSearchCtrl.clear();
    showAppBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.transparent,
      builder: (_) => _buildProductPickerSheet(),
    );
  }

  Widget _buildProductPickerSheet() {
    return StatefulBuilder(
      builder: (ctx, setSheetState) {
        final q = _productSearchCtrl.text.toLowerCase().trim();
        final filtered = q.isEmpty
            ? _products
            : _products
                  .where(
                    (p) =>
                        p.name.toLowerCase().contains(q) ||
                        p.companyName.toLowerCase().contains(q),
                  )
                  .toList();

        return Container(
          height: MediaQuery.of(context).size.height * 0.65,
          decoration: BoxDecoration(
            color: AppColors.card(context),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              _buildSheetHandle(),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Select Product',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Literata',
                              color: AppColors.action(context),
                            ),
                          ),
                        ),
                        if (_selectedProduct != null)
                          GestureDetector(
                            onTap: () {
                              setState(() => _selectedProduct = null);
                              Navigator.pop(context);
                            },
                            child: const Text(
                              'Clear',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.red,
                                fontFamily: 'Literata',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _buildSearchField(
                      _productSearchCtrl,
                      'Search product...',
                      () {
                        _searchDebounce?.cancel();
                        _searchDebounce = Timer(
                          const Duration(milliseconds: 300),
                          () {
                            _searchProducts(_productSearchCtrl.text).then((_) {
                              if (ctx.mounted) setSheetState(() {});
                            });
                          },
                        );
                        setSheetState(() {});
                      },
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 40,
                              color: AppTheme.grey300,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'No products found',
                              style: TextStyle(
                                color: AppTheme.grey,
                                fontFamily: 'Literata',
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) =>
                            Divider(height: 1, color: AppColors.chipFill(context)),
                        itemBuilder: (_, i) {
                          final p = filtered[i];
                          final selected = _selectedProduct?.id == p.id;
                          return ListTile(
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 2,
                            ),
                            leading: CircleAvatar(
                              backgroundColor: selected
                                  ? AppColors.action(context)
                                  : AppColors.border(context),
                              radius: 18,
                              child: Text(
                                p.name.isNotEmpty
                                    ? p.name[0].toUpperCase()
                                    : 'P',
                                style: TextStyle(
                                  color: selected
                                      ? AppTheme.white
                                      : AppTheme.grey700,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Literata',
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            title: Text(
                              p.name,
                              style: TextStyle(
                                fontFamily: 'Literata',
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: selected ? AppColors.action(context) : AppTheme.black87,
                              ),
                            ),
                            subtitle: p.companyName.isNotEmpty
                                ? Text(
                                    p.companyName,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontFamily: 'Literata',
                                      color: AppTheme.grey600,
                                    ),
                                  )
                                : null,
                            trailing: selected
                                ? Icon(Icons.check_circle, color: AppColors.action(context))
                                : null,
                            onTap: () {
                              setState(() => _selectedProduct = p);
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── SUPPLIER PICKER ───

  void _showSupplierPicker() {
    showAppBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.transparent,
      builder: (_) => _buildSupplierPickerSheet(),
    );
  }

  Widget _buildSupplierPickerSheet() {
    return StatefulBuilder(
      builder: (ctx, setSheetState) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.55,
          decoration: BoxDecoration(
            color: AppColors.card(context),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              _buildSheetHandle(),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Select Supplier',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Literata',
                          color: AppColors.action(context),
                        ),
                      ),
                    ),
                    if (_selectedSupplier != null)
                      GestureDetector(
                        onTap: () {
                          setState(() => _selectedSupplier = null);
                          Navigator.pop(context);
                        },
                        child: const Text(
                          'Clear',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.red,
                            fontFamily: 'Literata',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: _isLoadingDropdowns
                    ? Center(
                        child: CircularProgressIndicator(color: AppColors.action(context)),
                      )
                    : _suppliers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.local_shipping_outlined,
                              size: 40,
                              color: AppTheme.grey300,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'No suppliers found',
                              style: TextStyle(
                                color: AppTheme.grey,
                                fontFamily: 'Literata',
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: _suppliers.length,
                        separatorBuilder: (_, _) =>
                            Divider(height: 1, color: AppColors.chipFill(context)),
                        itemBuilder: (_, i) {
                          final s = _suppliers[i];
                          final selected = _selectedSupplier?.id == s.id;
                          return ListTile(
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 2,
                            ),
                            leading: CircleAvatar(
                              backgroundColor: selected
                                  ? AppColors.action(context)
                                  : AppColors.border(context),
                              radius: 18,
                              child: Text(
                                s.firstName.isNotEmpty
                                    ? s.firstName[0].toUpperCase()
                                    : 'S',
                                style: TextStyle(
                                  color: selected
                                      ? AppTheme.white
                                      : AppTheme.grey700,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Literata',
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            title: Text(
                              s.fullName,
                              style: TextStyle(
                                fontFamily: 'Literata',
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: selected ? AppColors.action(context) : AppTheme.black87,
                              ),
                            ),
                            subtitle: Text(
                              s.contact,
                              style: TextStyle(
                                fontSize: 12,
                                fontFamily: 'Literata',
                                color: AppTheme.grey600,
                              ),
                            ),
                            trailing: selected
                                ? Icon(Icons.check_circle, color: AppColors.action(context))
                                : null,
                            onTap: () {
                              setState(() => _selectedSupplier = s);
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── SHARED WIDGETS ───

  Widget _buildSheetHandle() {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: AppTheme.grey300,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildSearchField(
    TextEditingController ctrl,
    String hint,
    VoidCallback onChanged,
  ) {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: AppColors.scaffold(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.grey300),
      ),
      child: TextField(
        controller: ctrl,
        style: const TextStyle(fontFamily: 'Literata', fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: AppTheme.grey400, fontSize: 12),
          prefixIcon: Icon(Icons.search, color: AppTheme.grey600, size: 18),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
        onChanged: (_) => onChanged(),
      ),
    );
  }
}
