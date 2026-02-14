import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/session_manager.dart';
import '../../../product/offline/entities/product_entity.dart';
import '../../../supplier/offline/entities/supplier_entity.dart';
import '../../data/repositories/report_repository.dart';
import '../../data/services/report_service.dart';
import '../../data/services/report_pdf_generator.dart';
import '../../domain/models/report_filter_model.dart';

// ──────────────────────────────────────────────────────────
// Premium Report Page
//   - Date filter chips (Today / This Week / This Month / This Year / Custom)
//   - Advanced filters: product, supplier, expired, returned, price range,
//     low stock
//   - No table preview — PDF generated directly on tap
//   - Professional PDF with landscape table, colour-coded rows, summary
// ──────────────────────────────────────────────────────────

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  final _sessionManager = SessionManager();
  final _reportService = ReportService.instance;
  final _repo = ReportRepository.instance;

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

  // ── Generation state ──
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _loadDropdowns();
  }

  @override
  void dispose() {
    _minPriceCtrl.dispose();
    _maxPriceCtrl.dispose();
    _productSearchCtrl.dispose();
    _searchDebounce?.cancel();
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
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange:
          DateTimeRange(start: _filter.startDate, end: _filter.endDate),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme:
              const ColorScheme.light(primary: Color(0xFF1B4D3E)),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _filter = _filter.copyWith(
          startDate: picked.start,
          endDate: DateTime(
              picked.end.year, picked.end.month, picked.end.day, 23, 59, 59),
          presetLabel:
              '${DateFormat('dd/MM').format(picked.start)} – ${DateFormat('dd/MM').format(picked.end)}',
        );
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
    });
    _showSnackbar('Filters reset', false);
  }

  // ━━━━━━━━━━━━ GENERATE PDF ━━━━━━━━━━━━

  Future<void> _generatePdf() async {
    setState(() => _isGenerating = true);
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

      await ReportPdfGenerator.shareOrPrint(context, pdfBytes);
    } catch (e) {
      debugPrint('[ReportPage] PDF error: $e');
      if (mounted) _showSnackbar('Error generating report: $e', true);
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  void _showSnackbar(String msg, bool isError) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontFamily: 'Literata')),
      backgroundColor: isError ? Colors.red : const Color(0xFF1B4D3E),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
    ));
  }

  // ━━━━━━━━━━━━ BUILD ━━━━━━━━━━━━

  @override
  Widget build(BuildContext context) {
    _sessionManager.resetSession();
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDateFilterChips(),
            const SizedBox(height: 16),
            _buildActiveFiltersBar(),
            const SizedBox(height: 12),
            _buildAdvancedFiltersCard(),
            const SizedBox(height: 20),
            _buildGenerateCard(),
          ],
        ),
      ),
    );
  }

  // ─── APP BAR ───

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(60),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1B4D3E), Color(0xFF0F3B2F)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1B4D3E).withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back_rounded,
                      color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Reports',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Literata',
                        ),
                      ),
                      Text(
                        'Generate & download PDF reports',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontFamily: 'Literata',
                        ),
                      ),
                    ],
                  ),
                ),
                // Generate PDF button
                GestureDetector(
                  onTap: _isGenerating ? null : _generatePdf,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: _isGenerating
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.picture_as_pdf_rounded,
                                  color: Colors.white, size: 18),
                              SizedBox(width: 6),
                              Text(
                                'PDF',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Literata',
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── DATE FILTER CHIPS ───

  Widget _buildDateFilterChips() {
    const labels = ['Today', 'This Week', 'This Month', 'This Year', 'Custom'];
    const icons = [
      Icons.today,
      Icons.date_range,
      Icons.calendar_month,
      Icons.calendar_today_outlined,
      Icons.tune,
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Date Range',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              fontFamily: 'Literata',
              color: Color(0xFF1B4D3E),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(labels.length, (i) {
              final selected = _selectedPreset == i;
              return GestureDetector(
                onTap: () => _selectPreset(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xFF1B4D3E)
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected
                          ? const Color(0xFF1B4D3E)
                          : Colors.grey[300]!,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        icons[i],
                        size: 14,
                        color: selected ? Colors.white : Colors.grey[600],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        labels[i],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Literata',
                          color:
                              selected ? Colors.white : Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          // Show selected range
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF1B4D3E).withOpacity(0.06),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.event, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Text(
                  '${DateFormat('dd MMM yyyy').format(_filter.startDate)} — ${DateFormat('dd MMM yyyy').format(_filter.endDate)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'Literata',
                    color: Colors.grey[700],
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
      chips.add(_buildActiveChip(
          'Product: ${_filter.productName}', Icons.inventory_2_outlined));
    }
    if (_filter.supplierName != null) {
      chips.add(_buildActiveChip(
          'Supplier: ${_filter.supplierName}', Icons.local_shipping_outlined));
    }
    if (_filter.expiredOnly) {
      chips.add(_buildActiveChip('Expired', Icons.warning_amber_rounded,
          color: Colors.red));
    }
    if (_filter.expiringThisWeek) {
      chips.add(_buildActiveChip(
          'Expiring This Week', Icons.schedule, color: Colors.orange));
    }
    if (_filter.returnedOnly) {
      chips.add(
          _buildActiveChip('Returned', Icons.keyboard_return_rounded));
    }
    if (_filter.lowStockOnly) {
      chips.add(_buildActiveChip('Low Stock', Icons.trending_down,
          color: Colors.orange));
    }
    if (_filter.minPrice != null || _filter.maxPrice != null) {
      final range =
          '₹${_filter.minPrice?.toStringAsFixed(0) ?? '0'} – ₹${_filter.maxPrice?.toStringAsFixed(0) ?? '∞'}';
      chips.add(_buildActiveChip(range, Icons.currency_rupee));
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Wrap(spacing: 8, runSpacing: 6, children: chips);
  }

  Widget _buildActiveChip(String label, IconData icon,
      {Color color = const Color(0xFF1B4D3E)}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontFamily: 'Literata',
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ─── ADVANCED FILTERS CARD ───

  Widget _buildAdvancedFiltersCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header toggle
          GestureDetector(
            onTap: () => setState(() => _showAdvanced = !_showAdvanced),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const Icon(Icons.filter_alt_outlined,
                      color: Color(0xFF1B4D3E), size: 20),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Advanced Filters',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Literata',
                        color: Color(0xFF1B4D3E),
                      ),
                    ),
                  ),
                  if (_filter.hasAdvancedFilters)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B4D3E),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Active',
                        style: TextStyle(
                          color: Colors.white,
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
                    child: Icon(Icons.expand_more,
                        color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
          // Expandable body
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

          // ── Product dropdown ──
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

          // ── Supplier dropdown ──
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

          // ── Toggle filters ──
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildToggleChip(
                'Expired Products',
                Icons.warning_amber_rounded,
                _filter.expiredOnly,
                (v) => setState(
                    () => _filter = _filter.copyWith(expiredOnly: v)),
              ),
              _buildToggleChip(
                'Expiring This Week',
                Icons.schedule,
                _filter.expiringThisWeek,
                (v) => setState(
                    () => _filter = _filter.copyWith(expiringThisWeek: v)),
              ),
              _buildToggleChip(
                'Returned Products',
                Icons.keyboard_return_rounded,
                _filter.returnedOnly,
                (v) => setState(
                    () => _filter = _filter.copyWith(returnedOnly: v)),
              ),
              _buildToggleChip(
                'Low Stock',
                Icons.trending_down,
                _filter.lowStockOnly,
                (v) => setState(
                    () => _filter = _filter.copyWith(lowStockOnly: v)),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── Price range ──
          _buildLabel('Price Range'),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _buildPriceField(_minPriceCtrl, 'Min Price'),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('—',
                    style: TextStyle(
                        color: Colors.grey, fontFamily: 'Literata')),
              ),
              Expanded(
                child: _buildPriceField(_maxPriceCtrl, 'Max Price'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Action buttons ──
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
                    foregroundColor: const Color(0xFF1B4D3E),
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
                    backgroundColor: const Color(0xFF1B4D3E),
                    foregroundColor: Colors.white,
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

  // ─── GENERATE CARD ───

  Widget _buildGenerateCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1B4D3E).withOpacity(0.08),
            const Color(0xFF1B4D3E).withOpacity(0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: const Color(0xFF1B4D3E).withOpacity(0.15)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1B4D3E).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.picture_as_pdf_rounded,
                size: 40,
                color: const Color(0xFF1B4D3E).withOpacity(0.6)),
          ),
          const SizedBox(height: 14),
          const Text(
            'Generate PDF Report',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              fontFamily: 'Literata',
              color: Color(0xFF1B4D3E),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Professional report with detailed product breakdown, \npurchase & sales data, profit/loss, and expiry info.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontFamily: 'Literata',
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _isGenerating ? null : _generatePdf,
              icon: _isGenerating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : const Icon(Icons.download_rounded, size: 20),
              label: Text(
                _isGenerating ? 'Generating...' : 'Download / Print PDF',
                style: const TextStyle(
                  fontFamily: 'Literata',
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B4D3E),
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey[300],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── HELPERS ───

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        fontFamily: 'Literata',
        color: Colors.grey[700],
      ),
    );
  }

  Widget _buildDropdownField(String text, IconData icon, bool hasValue) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                fontFamily: 'Literata',
                color: hasValue
                    ? const Color(0xFF1B4D3E)
                    : Colors.grey[500],
                fontWeight:
                    hasValue ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          Icon(Icons.keyboard_arrow_down, color: Colors.grey[500], size: 20),
        ],
      ),
    );
  }

  Widget _buildToggleChip(
      String label, IconData icon, bool active, ValueChanged<bool> onChanged) {
    return GestureDetector(
      onTap: () => onChanged(!active),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: active
              ? const Color(0xFF1B4D3E).withOpacity(0.12)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active
                ? const Color(0xFF1B4D3E).withOpacity(0.4)
                : Colors.grey[300]!,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 14,
                color: active
                    ? const Color(0xFF1B4D3E)
                    : Colors.grey[600]),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                fontFamily: 'Literata',
                color: active
                    ? const Color(0xFF1B4D3E)
                    : Colors.grey[700],
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
        style: const TextStyle(fontFamily: 'Literata', fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 12),
          prefixText: '₹ ',
          prefixStyle: TextStyle(
              fontFamily: 'Literata',
              fontSize: 13,
              color: Colors.grey[600]),
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                const BorderSide(color: Color(0xFF1B4D3E), width: 2),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
          isDense: true,
        ),
      ),
    );
  }

  // ─── PRODUCT PICKER ───

  void _showProductPicker() {
    _productSearchCtrl.clear();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _buildProductPickerSheet(),
    );
  }

  Widget _buildProductPickerSheet() {
    return StatefulBuilder(builder: (ctx, setSheetState) {
      final q = _productSearchCtrl.text.toLowerCase().trim();
      final filtered = q.isEmpty
          ? _products
          : _products
              .where((p) =>
                  p.name.toLowerCase().contains(q) ||
                  p.companyName.toLowerCase().contains(q))
              .toList();

      return Container(
        height: MediaQuery.of(context).size.height * 0.65,
        decoration: const BoxDecoration(
          color: Colors.white,
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
                      const Expanded(
                        child: Text('Select Product',
                            style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Literata',
                                color: Color(0xFF1B4D3E))),
                      ),
                      if (_selectedProduct != null)
                        GestureDetector(
                          onTap: () {
                            setState(() => _selectedProduct = null);
                            Navigator.pop(context);
                          },
                          child: const Text('Clear',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.red,
                                  fontFamily: 'Literata',
                                  fontWeight: FontWeight.w600)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildSearchField(_productSearchCtrl, 'Search product...',
                      () {
                    _searchDebounce?.cancel();
                    _searchDebounce =
                        Timer(const Duration(milliseconds: 300), () {
                      _searchProducts(_productSearchCtrl.text).then((_) {
                        if (ctx.mounted) setSheetState(() {});
                      });
                    });
                    setSheetState(() {});
                  }),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text('No products found',
                          style: TextStyle(
                              color: Colors.grey[500],
                              fontFamily: 'Literata')))
                  : ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) =>
                          Divider(height: 1, color: Colors.grey[100]),
                      itemBuilder: (_, i) {
                        final p = filtered[i];
                        final selected =
                            _selectedProduct?.id == p.id;
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 2),
                          title: Text(p.name,
                              style: TextStyle(
                                  fontFamily: 'Literata',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: selected
                                      ? const Color(0xFF1B4D3E)
                                      : Colors.black87)),
                          subtitle: p.companyName.isNotEmpty
                              ? Text(p.companyName,
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontFamily: 'Literata',
                                      color: Colors.grey[600]))
                              : null,
                          trailing: selected
                              ? const Icon(Icons.check_circle,
                                  color: Color(0xFF1B4D3E))
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
    });
  }

  // ─── SUPPLIER PICKER ───

  void _showSupplierPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _buildSupplierPickerSheet(),
    );
  }

  Widget _buildSupplierPickerSheet() {
    return StatefulBuilder(builder: (ctx, setSheetState) {
      return Container(
        height: MediaQuery.of(context).size.height * 0.55,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            _buildSheetHandle(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  const Expanded(
                    child: Text('Select Supplier',
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Literata',
                            color: Color(0xFF1B4D3E))),
                  ),
                  if (_selectedSupplier != null)
                    GestureDetector(
                      onTap: () {
                        setState(() => _selectedSupplier = null);
                        Navigator.pop(context);
                      },
                      child: const Text('Clear',
                          style: TextStyle(
                              fontSize: 13,
                              color: Colors.red,
                              fontFamily: 'Literata',
                              fontWeight: FontWeight.w600)),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _isLoadingDropdowns
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: Color(0xFF1B4D3E)))
                  : _suppliers.isEmpty
                      ? Center(
                          child: Text('No suppliers found',
                              style: TextStyle(
                                  color: Colors.grey[500],
                                  fontFamily: 'Literata')))
                      : ListView.separated(
                          itemCount: _suppliers.length,
                          separatorBuilder: (_, __) =>
                              Divider(height: 1, color: Colors.grey[100]),
                          itemBuilder: (_, i) {
                            final s = _suppliers[i];
                            final selected =
                                _selectedSupplier?.id == s.id;
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 2),
                              leading: CircleAvatar(
                                backgroundColor: selected
                                    ? const Color(0xFF1B4D3E)
                                    : Colors.grey[200],
                                radius: 18,
                                child: Text(
                                  s.firstName.isNotEmpty
                                      ? s.firstName[0].toUpperCase()
                                      : 'S',
                                  style: TextStyle(
                                    color: selected
                                        ? Colors.white
                                        : Colors.grey[700],
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'Literata',
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              title: Text(s.fullName,
                                  style: TextStyle(
                                      fontFamily: 'Literata',
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: selected
                                          ? const Color(0xFF1B4D3E)
                                          : Colors.black87)),
                              subtitle: Text(s.contact,
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontFamily: 'Literata',
                                      color: Colors.grey[600])),
                              trailing: selected
                                  ? const Icon(Icons.check_circle,
                                      color: Color(0xFF1B4D3E))
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
    });
  }

  // ─── SHARED WIDGETS ───

  Widget _buildSheetHandle() {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildSearchField(
      TextEditingController ctrl, String hint, VoidCallback onChanged) {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: TextField(
        controller: ctrl,
        style: const TextStyle(fontFamily: 'Literata', fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 12),
          prefixIcon:
              Icon(Icons.search, color: Colors.grey[600], size: 18),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
        onChanged: (_) => onChanged(),
      ),
    );
  }
}
