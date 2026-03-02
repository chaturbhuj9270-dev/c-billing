import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/services/customer_transaction_service.dart';
import '../../data/repositories/customer_repository.dart';
import '../../data/repositories/customer_transaction_repository.dart';
import '../../domain/entities/customer_transaction.dart' show PaymentMode;
import '../../offline/controllers/customer_transaction_offline_controller.dart';
import '../../offline/entities/customer_transaction_entity.dart';
import '../../data/services/customer_transaction_sync_service.dart';

/// Date filter options for transactions
enum TransactionDateFilter { thisMonth, thisYear, lastYear, custom, all }

/// Premium Customer Transactions Page
/// Allows viewing and settling customer payments
class CustomerTransactionsPage extends StatefulWidget {
  final String customerId;
  final String customerLocalId;
  final String customerName;
  final String customerContact;
  final double currentPendingAmount;

  const CustomerTransactionsPage({
    super.key,
    required this.customerId,
    required this.customerLocalId,
    required this.customerName,
    required this.customerContact,
    required this.currentPendingAmount,
  });

  @override
  State<CustomerTransactionsPage> createState() =>
      _CustomerTransactionsPageState();
}

class _CustomerTransactionsPageState extends State<CustomerTransactionsPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late CustomerTransactionService _transactionService;

  List<CustomerTransactionEntity> _transactions = [];
  bool _isLoading = true;
  TransactionDateFilter _selectedFilter = TransactionDateFilter.all;
  DateTime? _customStartDate;
  DateTime? _customEndDate;

  // Stats
  double _totalReceived = 0;
  double _currentPending = 0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _currentPending = widget.currentPendingAmount;
    _initTransactionService();
    _syncAndLoadTransactions();
  }

  /// Sync transactions from server, then load from local storage
  Future<void> _syncAndLoadTransactions() async {
    // First, trigger a sync to pull any missing transactions from server
    try {
      await CustomerTransactionSyncService.instance.syncNow();
    } catch (e) {
      debugPrint('[Transactions] Sync failed (will load local data): $e');
    }
    // Then load from local storage
    _loadTransactions();
  }

  void _initTransactionService() {
    final firestore = FirebaseFirestore.instance;
    _transactionService = CustomerTransactionService(
      firestore: firestore,
      customerRepository: FirebaseCustomerRepository(firestore: firestore),
      transactionRepository: FirebaseCustomerTransactionRepository(
        firestore: firestore,
      ),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);

    try {
      final controller = CustomerTransactionOfflineController.instance;
      List<CustomerTransactionEntity> transactions;

      // Try both IDs
      final customerId = widget.customerId.isNotEmpty
          ? widget.customerId
          : widget.customerLocalId;

      switch (_selectedFilter) {
        case TransactionDateFilter.thisMonth:
          transactions = await controller.getThisMonthTransactions(customerId);
          // Also try with local ID
          if (transactions.isEmpty &&
              widget.customerLocalId != widget.customerId) {
            transactions = await controller.getThisMonthTransactions(
              widget.customerLocalId,
            );
          }
          break;
        case TransactionDateFilter.thisYear:
          transactions = await controller.getThisYearTransactions(customerId);
          if (transactions.isEmpty &&
              widget.customerLocalId != widget.customerId) {
            transactions = await controller.getThisYearTransactions(
              widget.customerLocalId,
            );
          }
          break;
        case TransactionDateFilter.lastYear:
          transactions = await controller.getLastYearTransactions(customerId);
          if (transactions.isEmpty &&
              widget.customerLocalId != widget.customerId) {
            transactions = await controller.getLastYearTransactions(
              widget.customerLocalId,
            );
          }
          break;
        case TransactionDateFilter.custom:
          if (_customStartDate != null && _customEndDate != null) {
            transactions = await controller.getTransactionsByDateRange(
              customerId: customerId,
              startDate: _customStartDate!,
              endDate: _customEndDate!,
            );
            if (transactions.isEmpty &&
                widget.customerLocalId != widget.customerId) {
              transactions = await controller.getTransactionsByDateRange(
                customerId: widget.customerLocalId,
                startDate: _customStartDate!,
                endDate: _customEndDate!,
              );
            }
          } else {
            transactions = [];
          }
          break;
        case TransactionDateFilter.all:
          transactions = await controller.getTransactionsByCustomerId(
            customerId,
          );
          if (transactions.isEmpty &&
              widget.customerLocalId != widget.customerId) {
            transactions = await controller.getTransactionsByCustomerId(
              widget.customerLocalId,
            );
          }
      }

      // Calculate stats
      double totalReceived = 0;
      for (final t in transactions) {
        if (t.transactionType == TransactionType.payment) {
          totalReceived += t.amount;
        }
      }

      // Get latest pending amount from last transaction
      if (transactions.isNotEmpty) {
        _currentPending = transactions.first.balanceAfter;
      }

      setState(() {
        _transactions = transactions;
        _totalReceived = totalReceived;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading transactions: $e');
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
                : Column(
                    children: [
                      _buildSummaryCards(),
                      _buildFilterChips(),
                      Expanded(child: _buildTransactionsList()),
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButton: _buildReceivePaymentFAB(),
    );
  }

  Widget _buildHeader() {
    final initials = widget.customerName.isNotEmpty
        ? widget.customerName[0].toUpperCase()
        : 'C';
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
            color: const Color(0xFF1B4D3E).withOpacity(0.3),
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
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Transactions',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Literata',
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: _loadTransactions,
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.refresh_rounded,
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
          // Customer Info
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white.withOpacity(0.15),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity(0.25),
                          Colors.white.withOpacity(0.1),
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Literata',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.customerName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Literata',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.phone_rounded,
                              size: 12,
                              color: Colors.white.withOpacity(0.7),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.customerContact,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 12,
                                fontFamily: 'Literata',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _SummaryCard(
              icon: Icons.arrow_downward_rounded,
              label: 'Received',
              value: '₹${_formatAmount(_totalReceived)}',
              color: Colors.green,
              iconBackground: Colors.green.withOpacity(0.1),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _SummaryCard(
              icon: Icons.schedule_rounded,
              label: 'Pending',
              value: '₹${_formatAmount(_currentPending)}',
              color: _currentPending > 0 ? Colors.red : Colors.green,
              iconBackground: (_currentPending > 0 ? Colors.red : Colors.green)
                  .withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount.abs() >= 100000) {
      return '${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount.abs() >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.toStringAsFixed(0);
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _FilterChip(
            label: 'All',
            isSelected: _selectedFilter == TransactionDateFilter.all,
            onTap: () {
              setState(() => _selectedFilter = TransactionDateFilter.all);
              _loadTransactions();
            },
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'This Month',
            isSelected: _selectedFilter == TransactionDateFilter.thisMonth,
            onTap: () {
              setState(() => _selectedFilter = TransactionDateFilter.thisMonth);
              _loadTransactions();
            },
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'This Year',
            isSelected: _selectedFilter == TransactionDateFilter.thisYear,
            onTap: () {
              setState(() => _selectedFilter = TransactionDateFilter.thisYear);
              _loadTransactions();
            },
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Last Year',
            isSelected: _selectedFilter == TransactionDateFilter.lastYear,
            onTap: () {
              setState(() => _selectedFilter = TransactionDateFilter.lastYear);
              _loadTransactions();
            },
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Custom',
            isSelected: _selectedFilter == TransactionDateFilter.custom,
            onTap: _showCustomDatePicker,
          ),
        ],
      ),
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
        _selectedFilter = TransactionDateFilter.custom;
      });
      _loadTransactions();
    }
  }

  Widget _buildTransactionsList() {
    if (_transactions.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: _transactions.length,
      itemBuilder: (context, index) {
        final transaction = _transactions[index];
        return _TransactionCard(
          transaction: transaction,
          onDelete: () => _deleteTransaction(transaction),
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
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF1B4D3E).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.receipt_long_rounded,
                size: 40,
                color: const Color(0xFF1B4D3E).withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No Transactions Yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1B4D3E),
                fontFamily: 'Literata',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Record payments received from this customer',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontFamily: 'Literata',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceivePaymentFAB() {
    return FloatingActionButton.extended(
      onPressed: _showReceivePaymentSheet,
      backgroundColor: const Color(0xFF1B4D3E),
      elevation: 4,
      icon: const Icon(Icons.add_rounded, color: Colors.white),
      label: const Text(
        'Receive Payment',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontFamily: 'Literata',
        ),
      ),
    );
  }

  Future<void> _showReceivePaymentSheet() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ReceivePaymentSheet(
        customerName: widget.customerName,
        pendingAmount: _currentPending,
      ),
    );

    if (result != null && mounted) {
      final amount = result['amount'] as double;
      final description = result['description'] as String?;
      final paymentMethod = result['paymentMethod'] as String?;

      final customerId = widget.customerId.isNotEmpty
          ? widget.customerId
          : widget.customerLocalId;

      // Save offline first
      await CustomerTransactionOfflineController.instance.addPaymentTransaction(
        customerId: customerId,
        customerName: widget.customerName,
        amount: amount,
        description: description,
        paymentMethod: paymentMethod,
      );

      // Sync to Firebase (online)
      try {
        final paymentMode = _mapPaymentMethod(paymentMethod);
        final firebaseResult = await _transactionService.receivePayment(
          customerId: customerId,
          amount: amount,
          paymentMode: paymentMode,
          notes: description ?? 'Payment received',
        );

        if (firebaseResult.success) {
          debugPrint('[Transactions] Payment synced to Firebase: $amount');
        } else {
          debugPrint(
            '[Transactions] Firebase sync failed: ${firebaseResult.errorMessage}',
          );
        }
      } catch (e) {
        debugPrint('[Transactions] Firebase sync error (non-blocking): $e');
      }

      _loadTransactions();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment of ₹${amount.toStringAsFixed(0)} recorded'),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Map payment method string to PaymentMode enum
  PaymentMode _mapPaymentMethod(String? method) {
    switch (method?.toLowerCase()) {
      case 'upi':
        return PaymentMode.upi;
      case 'bank transfer':
        return PaymentMode.online;
      case 'card':
        return PaymentMode.card;
      case 'cheque':
        return PaymentMode.cheque;
      case 'other':
        return PaymentMode.other;
      case 'cash':
      default:
        return PaymentMode.cash;
    }
  }

  Future<void> _deleteTransaction(CustomerTransactionEntity transaction) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction?'),
        content: const Text('This will reverse the effect on pending amount.'),
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
      await CustomerTransactionOfflineController.instance.deleteTransaction(
        transaction.id,
      );
      _loadTransactions();
    }
  }
}

/// Summary Card Widget
class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final Color iconBackground;

  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.iconBackground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: color,
                    fontFamily: 'Literata',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontFamily: 'Literata',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Filter Chip Widget
class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                    color: const Color(0xFF1B4D3E).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.grey[700],
            fontFamily: 'Literata',
          ),
        ),
      ),
    );
  }
}

/// Transaction Card Widget
class _TransactionCard extends StatelessWidget {
  final CustomerTransactionEntity transaction;
  final VoidCallback onDelete;

  const _TransactionCard({required this.transaction, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
    final isPayment = transaction.transactionType == TransactionType.payment;

    IconData icon;
    Color color;
    String typeLabel;

    switch (transaction.transactionType) {
      case TransactionType.payment:
        icon = Icons.arrow_downward_rounded;
        color = Colors.green;
        typeLabel = 'Payment Received';
        break;
      case TransactionType.billCreated:
        icon = Icons.receipt_rounded;
        color = Colors.orange;
        typeLabel = 'Bill Created';
        break;
      case TransactionType.billReturn:
        icon = Icons.undo_rounded;
        color = Colors.blue;
        typeLabel = 'Bill Return';
        break;
      case TransactionType.adjustment:
        icon = Icons.tune_rounded;
        color = Colors.purple;
        typeLabel = 'Adjustment';
        break;
    }

    return Dismissible(
      key: Key(transaction.id.toString()),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        onDelete();
        return false;
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            typeLabel,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1B4D3E),
                              fontFamily: 'Literata',
                            ),
                          ),
                        ),
                        Text(
                          '${isPayment ? '+' : ''}₹${transaction.amount.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isPayment ? Colors.green : Colors.orange,
                            fontFamily: 'Literata',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Payment method or description
                    if (transaction.paymentMethod != null ||
                        transaction.description != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            if (transaction.paymentMethod != null) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  transaction.paymentMethod!,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: color,
                                    fontFamily: 'Literata',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            if (transaction.description != null)
                              Expanded(
                                child: Text(
                                  transaction.description!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                    fontFamily: 'Literata',
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                        ),
                      ),
                    // Date and balance
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 12,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          dateFormat.format(transaction.transactionDate),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                            fontFamily: 'Literata',
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Balance: ₹${transaction.balanceAfter.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: transaction.balanceAfter > 0
                                ? Colors.red[400]
                                : Colors.green[400],
                            fontFamily: 'Literata',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Receive Payment Bottom Sheet
class _ReceivePaymentSheet extends StatefulWidget {
  final String customerName;
  final double pendingAmount;

  const _ReceivePaymentSheet({
    required this.customerName,
    required this.pendingAmount,
  });

  @override
  State<_ReceivePaymentSheet> createState() => _ReceivePaymentSheetState();
}

class _ReceivePaymentSheetState extends State<_ReceivePaymentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedPaymentMethod = 'Cash';

  final _paymentMethods = [
    'Cash',
    'UPI',
    'Bank Transfer',
    'Card',
    'Cheque',
    'Other',
  ];

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Form(
          key: _formKey,
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
              // Title
              const Text(
                'Receive Payment',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1B4D3E),
                  fontFamily: 'Literata',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'From ${widget.customerName}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontFamily: 'Literata',
                ),
              ),
              const SizedBox(height: 8),
              // Pending amount info
              if (widget.pendingAmount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 16,
                        color: Colors.red[400],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Pending: ₹${widget.pendingAmount.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.red[700],
                          fontFamily: 'Literata',
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 20),
              // Amount field
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1B4D3E),
                  fontFamily: 'Literata',
                ),
                decoration: InputDecoration(
                  labelText: 'Amount',
                  prefixText: '₹ ',
                  prefixStyle: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1B4D3E),
                    fontFamily: 'Literata',
                  ),
                  labelStyle: TextStyle(
                    color: Colors.grey[600],
                    fontFamily: 'Literata',
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: Color(0xFF1B4D3E),
                      width: 2,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter amount';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Please enter a valid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Payment method selection
              Text(
                'Payment Method',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                  fontFamily: 'Literata',
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _paymentMethods.map((method) {
                  final isSelected = _selectedPaymentMethod == method;
                  return GestureDetector(
                    onTap: () =>
                        setState(() => _selectedPaymentMethod = method),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF1B4D3E)
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF1B4D3E)
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Text(
                        method,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : Colors.grey[700],
                          fontFamily: 'Literata',
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              // Description field
              TextFormField(
                controller: _descriptionController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Notes (Optional)',
                  labelStyle: TextStyle(
                    color: Colors.grey[600],
                    fontFamily: 'Literata',
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Save button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _savePayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B4D3E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Record Payment',
                    style: TextStyle(
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
    );
  }

  void _savePayment() {
    if (_formKey.currentState!.validate()) {
      final amount = double.parse(_amountController.text);
      Navigator.pop(context, {
        'amount': amount,
        'description': _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        'paymentMethod': _selectedPaymentMethod,
      });
    }
  }
}
