import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../offline/controllers/expense_offline_controller.dart';
import '../../offline/entities/expense_entity.dart';
import '../../data/services/expense_sync_service.dart';
import 'package:c_billing/core/ui/glassy_toast.dart';

/// Date filter options for expenses
enum ExpenseDateFilter { all, thisMonth, thisYear, lastYear, custom }

/// Premium Expenses Page
/// Features: Category filtering, date filtering, summary cards, beautiful UI
class ExpensesPage extends StatefulWidget {
  final bool isEmbedded;

  const ExpensesPage({super.key, this.isEmbedded = false});

  @override
  State<ExpensesPage> createState() => _ExpensesPageState();
}

class _ExpensesPageState extends State<ExpensesPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _opacityAnimation;

  List<ExpenseEntity> _expenses = [];
  bool _isLoading = true;
  ExpenseDateFilter _selectedDateFilter = ExpenseDateFilter.thisMonth;
  ExpenseCategory? _selectedCategory;
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  String _searchQuery = '';

  // Stats
  double _totalExpenses = 0;
  Map<ExpenseCategory, double> _categoryTotals = {};

  final _searchController = TextEditingController();
  StreamSubscription? _expenseSubscription;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _offsetAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
        );

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    _initSyncService();
    _loadExpenses();
    _animController.forward();
  }

  void _initSyncService() {
    // Initialize sync service
    ExpenseSyncService.instance.initialize();
  }

  @override
  void dispose() {
    _animController.dispose();
    _searchController.dispose();
    _expenseSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadExpenses() async {
    setState(() => _isLoading = true);

    try {
      final controller = ExpenseOfflineController.instance;
      List<ExpenseEntity> expenses;

      // Apply date filter
      switch (_selectedDateFilter) {
        case ExpenseDateFilter.thisMonth:
          expenses = await controller.getThisMonthExpenses();
          break;
        case ExpenseDateFilter.thisYear:
          expenses = await controller.getThisYearExpenses();
          break;
        case ExpenseDateFilter.lastYear:
          expenses = await controller.getLastYearExpenses();
          break;
        case ExpenseDateFilter.custom:
          if (_customStartDate != null && _customEndDate != null) {
            expenses = await controller.getExpensesByDateRange(
              startDate: _customStartDate!,
              endDate: _customEndDate!,
            );
          } else {
            expenses = await controller.getAllExpenses();
          }
          break;
        case ExpenseDateFilter.all:
          expenses = await controller.getAllExpenses();
      }

      // Apply category filter
      if (_selectedCategory != null) {
        expenses = expenses
            .where((e) => e.category == _selectedCategory)
            .toList();
      }

      // Apply search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        expenses = expenses.where((e) {
          return e.title.toLowerCase().contains(query) ||
              (e.description?.toLowerCase().contains(query) ?? false) ||
              (e.vendorName?.toLowerCase().contains(query) ?? false);
        }).toList();
      }

      // Calculate stats
      double total = 0;
      final Map<ExpenseCategory, double> categoryTotals = {};
      for (final category in ExpenseCategory.values) {
        categoryTotals[category] = 0;
      }

      for (final expense in expenses) {
        total += expense.amount;
        categoryTotals[expense.category] =
            (categoryTotals[expense.category] ?? 0) + expense.amount;
      }

      setState(() {
        _expenses = expenses;
        _totalExpenses = total;
        _categoryTotals = categoryTotals;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('[Expenses] Error loading expenses: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F6),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF1B4D3E)),
                  )
                : SlideTransition(
                    position: _offsetAnimation,
                    child: FadeTransition(
                      opacity: _opacityAnimation,
                      child: Column(
                        children: [
                          _buildSummarySection(),
                          _buildFilterSection(),
                          Expanded(child: _buildExpensesList()),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: _buildAddExpenseFAB(),
    );
  }

  Widget _buildHeader() {
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B4D3E), Color(0xFF0F3B2F)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B4D3E).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.only(top: topPadding),
            child: SizedBox(
              height: 56,
              child: Row(
                children: [
                  if (!widget.isEmbedded)
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  if (widget.isEmbedded) const SizedBox(width: 16),
                  const Text(
                    'Expenses',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Literata',
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () {
                      ExpenseSyncService.instance.syncNow();
                      _loadExpenses();
                    },
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.sync_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                  _loadExpenses();
                },
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontFamily: 'Literata',
                ),
                decoration: InputDecoration(
                  hintText: 'Search expenses...',
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 14,
                    fontFamily: 'Literata',
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: Colors.white.withValues(alpha: 0.6),
                    size: 20,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Total expense card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF1B4D3E),
                  const Color(0xFF1B4D3E).withValues(alpha: 0.85),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1B4D3E).withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Expenses',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.8),
                            fontFamily: 'Literata',
                          ),
                        ),
                        Text(
                          _getDateFilterLabel(),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.6),
                            fontFamily: 'Literata',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  '₹${_formatAmount(_totalExpenses)}',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontFamily: 'Literata',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_expenses.length} transactions',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.7),
                    fontFamily: 'Literata',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Category breakdown cards
          _buildCategoryBreakdown(),
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdown() {
    // Get top categories with amounts
    final sortedCategories =
        _categoryTotals.entries.where((e) => e.value > 0).toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    if (sortedCategories.isEmpty) {
      return const SizedBox.shrink();
    }

    // Responsive sizing based on screen width
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final cardHeight = isSmallScreen ? 82.0 : 88.0;
    final cardWidth = isSmallScreen ? 110.0 : 120.0;
    final cardPadding = isSmallScreen ? 10.0 : 12.0;
    final iconSize = isSmallScreen ? 16.0 : 18.0;
    final percentFontSize = isSmallScreen ? 9.0 : 10.0;
    final labelFontSize = isSmallScreen ? 10.0 : 11.0;
    final amountFontSize = isSmallScreen ? 12.0 : 13.0;

    return SizedBox(
      height: cardHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: sortedCategories.length.clamp(0, 5),
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final entry = sortedCategories[index];
          final category = entry.key;
          final amount = entry.value;
          final percentage = _totalExpenses > 0
              ? (amount / _totalExpenses * 100).toStringAsFixed(0)
              : '0';

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = _selectedCategory == category
                    ? null
                    : category;
              });
              _loadExpenses();
            },
            child: Container(
              width: cardWidth,
              padding: EdgeInsets.all(cardPadding),
              decoration: BoxDecoration(
                color: _selectedCategory == category
                    ? const Color(0xFF1B4D3E).withValues(alpha: 0.1)
                    : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _selectedCategory == category
                      ? const Color(0xFF1B4D3E)
                      : Colors.grey.shade200,
                  width: _selectedCategory == category ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(category.icon, style: TextStyle(fontSize: iconSize)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1B4D3E).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$percentage%',
                          style: TextStyle(
                            fontSize: percentFontSize,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1B4D3E),
                            fontFamily: 'Literata',
                          ),
                        ),
                      ),
                    ],
                  ),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          category.displayName,
                          style: TextStyle(
                            fontSize: labelFontSize,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                            fontFamily: 'Literata',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '₹${_formatAmount(amount)}',
                          style: TextStyle(
                            fontSize: amountFontSize,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1B4D3E),
                            fontFamily: 'Literata',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterSection() {
    return Column(
      children: [
        // Date filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _DateFilterChip(
                label: 'All',
                isSelected: _selectedDateFilter == ExpenseDateFilter.all,
                onTap: () {
                  setState(() => _selectedDateFilter = ExpenseDateFilter.all);
                  _loadExpenses();
                },
              ),
              const SizedBox(width: 8),
              _DateFilterChip(
                label: 'This Month',
                isSelected: _selectedDateFilter == ExpenseDateFilter.thisMonth,
                onTap: () {
                  setState(
                    () => _selectedDateFilter = ExpenseDateFilter.thisMonth,
                  );
                  _loadExpenses();
                },
              ),
              const SizedBox(width: 8),
              _DateFilterChip(
                label: 'This Year',
                isSelected: _selectedDateFilter == ExpenseDateFilter.thisYear,
                onTap: () {
                  setState(
                    () => _selectedDateFilter = ExpenseDateFilter.thisYear,
                  );
                  _loadExpenses();
                },
              ),
              const SizedBox(width: 8),
              _DateFilterChip(
                label: 'Last Year',
                isSelected: _selectedDateFilter == ExpenseDateFilter.lastYear,
                onTap: () {
                  setState(
                    () => _selectedDateFilter = ExpenseDateFilter.lastYear,
                  );
                  _loadExpenses();
                },
              ),
              const SizedBox(width: 8),
              _DateFilterChip(
                label: 'Custom',
                isSelected: _selectedDateFilter == ExpenseDateFilter.custom,
                onTap: _showCustomDatePicker,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Category filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _CategoryFilterChip(
                label: 'All Categories',
                icon: '📋',
                isSelected: _selectedCategory == null,
                onTap: () {
                  setState(() => _selectedCategory = null);
                  _loadExpenses();
                },
              ),
              const SizedBox(width: 8),
              ...ExpenseCategory.values.map((category) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _CategoryFilterChip(
                    label: category.displayName,
                    icon: category.icon,
                    isSelected: _selectedCategory == category,
                    onTap: () {
                      setState(() => _selectedCategory = category);
                      _loadExpenses();
                    },
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Future<void> _showCustomDatePicker() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _customStartDate != null && _customEndDate != null
          ? DateTimeRange(start: _customStartDate!, end: _customEndDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1B4D3E),
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _customStartDate = picked.start;
        _customEndDate = picked.end;
        _selectedDateFilter = ExpenseDateFilter.custom;
      });
      _loadExpenses();
    }
  }

  Widget _buildExpensesList() {
    if (_expenses.isEmpty) {
      return _buildEmptyState();
    }

    // Group expenses by date
    final Map<String, List<ExpenseEntity>> groupedExpenses = {};
    final dateFormat = DateFormat('dd MMM yyyy');

    for (final expense in _expenses) {
      final dateKey = dateFormat.format(expense.expenseDate);
      groupedExpenses.putIfAbsent(dateKey, () => []);
      groupedExpenses[dateKey]!.add(expense);
    }

    final sortedDates = groupedExpenses.keys.toList();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final dateKey = sortedDates[index];
        final expenses = groupedExpenses[dateKey]!;
        final dayTotal = expenses.fold(0.0, (sum, e) => sum + e.amount);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date header
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    dateKey,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                      fontFamily: 'Literata',
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B4D3E).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '₹${_formatAmount(dayTotal)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1B4D3E),
                        fontFamily: 'Literata',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Expense cards
            ...expenses.map(
              (expense) => _ExpenseCard(
                expense: expense,
                onTap: () => _showExpenseDetails(expense),
                onEdit: () => _showEditExpenseSheet(expense),
                onDelete: () => _deleteExpense(expense),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFF1B4D3E).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.receipt_long_rounded,
                size: 48,
                color: const Color(0xFF1B4D3E).withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Expenses Yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1B4D3E),
                fontFamily: 'Literata',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start tracking your business expenses\nby adding your first expense',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontFamily: 'Literata',
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showAddExpenseSheet,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B4D3E),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text(
                'Add Expense',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Literata',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddExpenseFAB() {
    return FloatingActionButton.extended(
      onPressed: _showAddExpenseSheet,
      backgroundColor: const Color(0xFF1B4D3E),
      elevation: 4,
      icon: const Icon(Icons.add_rounded, color: Colors.white),
      label: const Text(
        'Add Expense',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontFamily: 'Literata',
        ),
      ),
    );
  }

  String _getDateFilterLabel() {
    switch (_selectedDateFilter) {
      case ExpenseDateFilter.thisMonth:
        return DateFormat('MMMM yyyy').format(DateTime.now());
      case ExpenseDateFilter.thisYear:
        return 'Year ${DateTime.now().year}';
      case ExpenseDateFilter.lastYear:
        return 'Year ${DateTime.now().year - 1}';
      case ExpenseDateFilter.custom:
        if (_customStartDate != null && _customEndDate != null) {
          return '${DateFormat('dd MMM').format(_customStartDate!)} - ${DateFormat('dd MMM yyyy').format(_customEndDate!)}';
        }
        return 'Custom Range';
      case ExpenseDateFilter.all:
        return 'All Time';
    }
  }

  String _formatAmount(double amount) {
    if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.toStringAsFixed(0);
  }

  Future<void> _showAddExpenseSheet() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _AddExpenseSheet(),
    );

    if (result != null && mounted) {
      await ExpenseOfflineController.instance.addExpense(
        title: result['title'] as String,
        description: result['description'] as String?,
        category: result['category'] as ExpenseCategory,
        amount: result['amount'] as double,
        paymentMethod: result['paymentMethod'] as String?,
        vendorName: result['vendorName'] as String?,
        receiptNumber: result['receiptNumber'] as String?,
        isRecurring: result['isRecurring'] as bool? ?? false,
        expenseDate: result['expenseDate'] as DateTime?,
        notes: result['notes'] as String?,
      );

      // Trigger sync
      ExpenseSyncService.instance.syncNow();

      _loadExpenses();

      if (mounted) {
        GlassyToast.show(context, 'Expense added successfully');
      }
    }
  }

  Future<void> _showEditExpenseSheet(ExpenseEntity expense) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddExpenseSheet(expense: expense),
    );

    if (result != null && mounted) {
      await ExpenseOfflineController.instance.updateExpense(
        id: expense.id,
        title: result['title'] as String?,
        description: result['description'] as String?,
        category: result['category'] as ExpenseCategory?,
        amount: result['amount'] as double?,
        paymentMethod: result['paymentMethod'] as String?,
        vendorName: result['vendorName'] as String?,
        receiptNumber: result['receiptNumber'] as String?,
        isRecurring: result['isRecurring'] as bool?,
        expenseDate: result['expenseDate'] as DateTime?,
        notes: result['notes'] as String?,
      );

      // Trigger sync
      ExpenseSyncService.instance.syncNow();

      _loadExpenses();
    }
  }

  void _showExpenseDetails(ExpenseEntity expense) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _ExpenseDetailsSheet(expense: expense),
    );
  }

  Future<void> _deleteExpense(ExpenseEntity expense) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Expense?'),
        content: Text('Are you sure you want to delete "${expense.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ExpenseOfflineController.instance.deleteExpense(expense.id);
      ExpenseSyncService.instance.syncNow();
      _loadExpenses();

      if (mounted) {
        GlassyToast.show(context, 'Expense deleted', isError: true);
      }
    }
  }
}

/// Date Filter Chip Widget
class _DateFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _DateFilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1B4D3E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF1B4D3E) : Colors.grey.shade300,
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF1B4D3E).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.grey[700],
            fontFamily: 'Literata',
          ),
        ),
      ),
    );
  }
}

/// Category Filter Chip Widget
class _CategoryFilterChip extends StatelessWidget {
  final String label;
  final String icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryFilterChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF1B4D3E).withValues(alpha: 0.1)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF1B4D3E) : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isSelected ? const Color(0xFF1B4D3E) : Colors.grey[600],
                fontFamily: 'Literata',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Expense Card Widget
class _ExpenseCard extends StatelessWidget {
  final ExpenseEntity expense;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ExpenseCard({
    required this.expense,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(expense.id.toString()),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        onDelete();
        return false;
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onEdit,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Category icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B4D3E).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      expense.category.icon,
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        expense.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1B4D3E),
                          fontFamily: 'Literata',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              expense.category.displayName,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[600],
                                fontFamily: 'Literata',
                              ),
                            ),
                          ),
                          if (expense.vendorName != null) ...[
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                expense.vendorName!,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[500],
                                  fontFamily: 'Literata',
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Amount
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${expense.amount.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.red,
                        fontFamily: 'Literata',
                      ),
                    ),
                    if (expense.paymentMethod != null)
                      Text(
                        expense.paymentMethod!,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[500],
                          fontFamily: 'Literata',
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Add/Edit Expense Bottom Sheet
class _AddExpenseSheet extends StatefulWidget {
  final ExpenseEntity? expense;

  const _AddExpenseSheet({this.expense});

  @override
  State<_AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends State<_AddExpenseSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _vendorController = TextEditingController();
  final _receiptController = TextEditingController();
  final _notesController = TextEditingController();

  ExpenseCategory _selectedCategory = ExpenseCategory.other;
  String _selectedPaymentMethod = 'Cash';
  DateTime _selectedDate = DateTime.now();
  bool _isRecurring = false;

  final _paymentMethods = [
    'Cash',
    'UPI',
    'Bank Transfer',
    'Card',
    'Cheque',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.expense != null) {
      _titleController.text = widget.expense!.title;
      _descriptionController.text = widget.expense!.description ?? '';
      _amountController.text = widget.expense!.amount.toStringAsFixed(0);
      _vendorController.text = widget.expense!.vendorName ?? '';
      _receiptController.text = widget.expense!.receiptNumber ?? '';
      _notesController.text = widget.expense!.notes ?? '';
      _selectedCategory = widget.expense!.category;
      _selectedPaymentMethod = widget.expense!.paymentMethod ?? 'Cash';
      _selectedDate = widget.expense!.expenseDate;
      _isRecurring = widget.expense!.isRecurring;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    _vendorController.dispose();
    _receiptController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.expense != null;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                Text(
                  isEditing ? 'Edit Expense' : 'Add Expense',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1B4D3E),
                    fontFamily: 'Literata',
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          // Form
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    _buildLabel('Expense Title *'),
                    TextFormField(
                      controller: _titleController,
                      decoration: _inputDecoration('e.g., Electricity Bill'),
                      validator: (v) =>
                          v?.isEmpty ?? true ? 'Title is required' : null,
                    ),
                    const SizedBox(height: 16),

                    // Amount
                    _buildLabel('Amount *'),
                    TextFormField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1B4D3E),
                      ),
                      decoration: _inputDecoration('0').copyWith(
                        prefixText: '₹ ',
                        prefixStyle: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1B4D3E),
                        ),
                      ),
                      validator: (v) {
                        if (v?.isEmpty ?? true) return 'Amount is required';
                        if (double.tryParse(v!) == null) {
                          return 'Invalid amount';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Category
                    _buildLabel('Category *'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ExpenseCategory.values.map((category) {
                        final isSelected = _selectedCategory == category;
                        return GestureDetector(
                          onTap: () =>
                              setState(() => _selectedCategory = category),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF1B4D3E)
                                  : Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF1B4D3E)
                                    : Colors.grey.shade300,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  category.icon,
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  category.displayName,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.grey[700],
                                    fontFamily: 'Literata',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Date
                    _buildLabel('Date'),
                    GestureDetector(
                      onTap: _selectDate,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 18,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 10),
                            Text(
                              DateFormat('dd MMM yyyy').format(_selectedDate),
                              style: const TextStyle(
                                fontSize: 14,
                                fontFamily: 'Literata',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Payment Method
                    _buildLabel('Payment Method'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _paymentMethods.map((method) {
                        final isSelected = _selectedPaymentMethod == method;
                        return GestureDetector(
                          onTap: () =>
                              setState(() => _selectedPaymentMethod = method),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF1B4D3E)
                                  : Colors.grey[100],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              method,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.grey[700],
                                fontFamily: 'Literata',
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Vendor
                    _buildLabel('Vendor/Payee (Optional)'),
                    TextFormField(
                      controller: _vendorController,
                      decoration: _inputDecoration(
                        'e.g., State Electricity Board',
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Description
                    _buildLabel('Description (Optional)'),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 2,
                      decoration: _inputDecoration('Additional details...'),
                    ),
                    const SizedBox(height: 16),

                    // Recurring toggle
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Recurring Expense',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1B4D3E),
                                  fontFamily: 'Literata',
                                ),
                              ),
                              Text(
                                'Mark if this expense repeats monthly',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                  fontFamily: 'Literata',
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _isRecurring,
                          onChanged: (v) => setState(() => _isRecurring = v),
                          activeThumbColor: const Color(0xFF1B4D3E),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _saveExpense,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1B4D3E),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          isEditing ? 'Update Expense' : 'Add Expense',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Literata',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.grey[700],
          fontFamily: 'Literata',
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[400], fontFamily: 'Literata'),
      filled: true,
      fillColor: Colors.grey[50],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF1B4D3E), width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1B4D3E),
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _saveExpense() {
    if (_formKey.currentState!.validate()) {
      Navigator.pop(context, {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        'category': _selectedCategory,
        'amount': double.parse(_amountController.text),
        'paymentMethod': _selectedPaymentMethod,
        'vendorName': _vendorController.text.trim().isNotEmpty
            ? _vendorController.text.trim()
            : null,
        'receiptNumber': _receiptController.text.trim().isNotEmpty
            ? _receiptController.text.trim()
            : null,
        'isRecurring': _isRecurring,
        'expenseDate': _selectedDate,
        'notes': _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
      });
    }
  }
}

/// Expense Details Bottom Sheet
class _ExpenseDetailsSheet extends StatelessWidget {
  final ExpenseEntity expense;

  const _ExpenseDetailsSheet({required this.expense});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Header
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B4D3E).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      expense.category.icon,
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        expense.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1B4D3E),
                          fontFamily: 'Literata',
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        expense.category.displayName,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          fontFamily: 'Literata',
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '₹${expense.amount.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.red,
                    fontFamily: 'Literata',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),
            // Details
            _buildDetailRow('Date', dateFormat.format(expense.expenseDate)),
            if (expense.paymentMethod != null)
              _buildDetailRow('Payment Method', expense.paymentMethod!),
            if (expense.vendorName != null)
              _buildDetailRow('Vendor', expense.vendorName!),
            if (expense.description != null)
              _buildDetailRow('Description', expense.description!),
            if (expense.isRecurring) _buildDetailRow('Recurring', 'Yes'),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                fontFamily: 'Literata',
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1B4D3E),
                fontFamily: 'Literata',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
