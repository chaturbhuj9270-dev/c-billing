import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:c_billing/features/customer/domain/entities/customer.dart';
import 'package:c_billing/features/customer/domain/entities/customer_transaction.dart';
import 'package:c_billing/features/customer/data/repositories/customer_repository.dart';
import 'package:c_billing/features/customer/data/repositories/customer_transaction_repository.dart';
import 'package:c_billing/core/services/customer_transaction_service.dart';
import 'package:c_billing/features/event_order/offline/controllers/event_order_offline_controller.dart';
import 'package:c_billing/features/event_order/domain/entities/event_order.dart';
import 'package:c_billing/core/ui/glassy_toast.dart';
import 'package:c_billing/features/customer/offline/controllers/customer_transaction_offline_controller.dart';

/// Page to display customer details, pending balance, and transaction history
/// Also provides functionality to receive payments
class CustomerDetailsPage extends StatefulWidget {
  final String customerId;

  const CustomerDetailsPage({super.key, required this.customerId});

  @override
  State<CustomerDetailsPage> createState() => _CustomerDetailsPageState();
}

class _CustomerDetailsPageState extends State<CustomerDetailsPage> {
  late FirebaseFirestore _firestore;
  late FirebaseCustomerRepository _customerRepository;
  late FirebaseCustomerTransactionRepository _transactionRepository;
  late CustomerTransactionService _transactionService;

  Customer? _customer;
  List<CustomerTransaction> _transactions = [];
  List<EventOrder> _eventOrders = [];
  bool _isLoading = true;
  String? _error;

  // Combined transactions data for display
  List<_CombinedTransaction> _combinedTransactions = [];
  double _totalEventsAmount = 0.0;
  double _totalAdvanceReceived = 0.0;

  @override
  void initState() {
    super.initState();
    _firestore = FirebaseFirestore.instance;
    _customerRepository = FirebaseCustomerRepository(firestore: _firestore);
    _transactionRepository = FirebaseCustomerTransactionRepository(
      firestore: _firestore,
    );
    _transactionService = CustomerTransactionService(
      firestore: _firestore,
      customerRepository: _customerRepository,
      transactionRepository: _transactionRepository,
    );
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final customerWithTransactions = await _transactionService
          .getCustomerWithTransactions(
            widget.customerId,
            transactionLimit: 100,
          );

      if (customerWithTransactions == null) {
        setState(() {
          _error = 'Customer not found';
          _isLoading = false;
        });
        return;
      }

      // Load event orders for this customer
      // Try with the passed customerId first
      debugPrint(
        '[CustomerDetails] Loading events for customerId: ${widget.customerId}',
      );
      var eventOrderEntities = await EventOrderOfflineController.instance
          .getEventOrdersByCustomerId(widget.customerId);
      debugPrint(
        '[CustomerDetails] Events found with customerId: ${eventOrderEntities.length}',
      );

      // If no results and customerId has 'local_' prefix, try with just the numeric ID
      // This handles the mismatch where customer page uses 'local_123' but event orders store '123'
      if (eventOrderEntities.isEmpty &&
          widget.customerId.startsWith('local_')) {
        final localId = widget.customerId.substring(
          6,
        ); // Remove 'local_' prefix
        debugPrint('[CustomerDetails] Trying with localId: $localId');
        eventOrderEntities = await EventOrderOfflineController.instance
            .getEventOrdersByCustomerId(localId);
        debugPrint(
          '[CustomerDetails] Events found with localId: ${eventOrderEntities.length}',
        );
      }

      // Debug: Get all event orders to see what customer IDs exist
      if (eventOrderEntities.isEmpty) {
        final allOrders = await EventOrderOfflineController.instance
            .getAllEventOrders();
        debugPrint(
          '[CustomerDetails] Total event orders in DB: ${allOrders.length}',
        );
        for (final o in allOrders) {
          debugPrint(
            '[CustomerDetails] Order customerId: "${o.customerId}" vs looking for: "${widget.customerId}"',
          );
        }
      }

      final eventOrders = eventOrderEntities.map((e) => e.toDomain()).toList();

      // Calculate event totals
      double totalEventsAmount = 0.0;
      double totalAdvanceReceived = 0.0;
      for (final order in eventOrders) {
        if (order.status != OrderStatus.cancelled) {
          totalEventsAmount += order.totalAmount;
          totalAdvanceReceived += order.advanceAmount;
        }
      }

      // Build combined transactions list
      final combined = <_CombinedTransaction>[];

      // Add bill transactions
      for (final tx in customerWithTransactions.transactions) {
        combined.add(
          _CombinedTransaction(
            type: _TransactionType.billTransaction,
            date: tx.createdAt,
            transaction: tx,
          ),
        );
      }

      // Add event orders as transactions
      for (final order in eventOrders) {
        combined.add(
          _CombinedTransaction(
            type: _TransactionType.eventOrder,
            date: order.createdAt,
            eventOrder: order,
          ),
        );
      }

      // Sort by date descending
      combined.sort((a, b) => b.date.compareTo(a.date));

      setState(() {
        _customer = customerWithTransactions.customer;
        _transactions = customerWithTransactions.transactions;
        _eventOrders = eventOrders;
        _combinedTransactions = combined;
        _totalEventsAmount = totalEventsAmount;
        _totalAdvanceReceived = totalAdvanceReceived;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _showReceivePaymentDialog() {
    if (_customer == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ReceivePaymentSheet(
        customer: _customer!,
        transactionService: _transactionService,
        onPaymentReceived: () {
          _loadData();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        title: Text(
          _customer?.fullName ?? 'Customer Details',
          style: const TextStyle(
            fontFamily: 'Literata',
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFF1B4D3E),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1B4D3E)),
            )
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(_error!, style: const TextStyle(fontFamily: 'Literata')),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadData,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              child: CustomScrollView(
                slivers: [
                  // Customer Info Card
                  SliverToBoxAdapter(child: _buildCustomerInfoCard()),
                  // Balance Card
                  SliverToBoxAdapter(child: _buildBalanceCard()),
                  // Events/Orders Summary Card
                  if (_eventOrders.isNotEmpty)
                    SliverToBoxAdapter(child: _buildEventsSummaryCard()),
                  // Transaction History Header
                  SliverToBoxAdapter(child: _buildTransactionHeader()),
                  // Transaction List
                  _combinedTransactions.isEmpty
                      ? SliverFillRemaining(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.receipt_long,
                                  size: 48,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No transactions yet',
                                  style: TextStyle(
                                    fontFamily: 'Literata',
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => _buildCombinedTransactionItem(
                              _combinedTransactions[index],
                            ),
                            childCount: _combinedTransactions.length,
                          ),
                        ),
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            ),
      floatingActionButton: _customer != null && _customer!.hasPendingBalance
          ? FloatingActionButton.extended(
              onPressed: _showReceivePaymentDialog,
              backgroundColor: const Color(0xFF1B4D3E),
              icon: const Icon(Icons.payments),
              label: const Text(
                'Receive Payment',
                style: TextStyle(fontFamily: 'Literata'),
              ),
            )
          : null,
    );
  }

  Widget _buildCustomerInfoCard() {
    if (_customer == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFF1B4D3E).withValues(alpha: 0.1),
                child: Text(
                  _customer!.firstName.isNotEmpty
                      ? _customer!.firstName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    fontFamily: 'Literata',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B4D3E),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _customer!.fullName,
                      style: const TextStyle(
                        fontFamily: 'Literata',
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.phone, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          _customer!.contact,
                          style: TextStyle(
                            fontFamily: 'Literata',
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_customer!.address != null && _customer!.address!.isNotEmpty) ...[
            const Divider(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _customer!.address!,
                    style: TextStyle(
                      fontFamily: 'Literata',
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBalanceCard() {
    if (_customer == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _customer!.hasPendingBalance
              ? [const Color(0xFFFF6B6B), const Color(0xFFEE5A5A)]
              : [const Color(0xFF1B4D3E), const Color(0xFF0F3B2F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color:
                (_customer!.hasPendingBalance
                        ? const Color(0xFFFF6B6B)
                        : const Color(0xFF1B4D3E))
                    .withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _customer!.hasPendingBalance ? 'Pending Balance' : 'Balance',
                style: TextStyle(
                  fontFamily: 'Literata',
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
              Icon(
                _customer!.hasPendingBalance
                    ? Icons.warning_amber_rounded
                    : Icons.check_circle,
                color: Colors.white,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '₹${_customer!.currentPendingAmount.toStringAsFixed(2)}',
            style: const TextStyle(
              fontFamily: 'Literata',
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Total Purchases',
                  '₹${_customer!.totalPurchaseAmount.toStringAsFixed(0)}',
                ),
              ),
              Container(
                width: 1,
                height: 30,
                color: Colors.white.withValues(alpha: 0.3),
              ),
              Expanded(
                child: _buildStatItem(
                  'Total Paid',
                  '₹${_customer!.totalPaidAmount.toStringAsFixed(0)}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Literata',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Literata',
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Transaction History',
            style: TextStyle(
              fontFamily: 'Literata',
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            '${_transactions.length} transactions',
            style: TextStyle(
              fontFamily: 'Literata',
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(CustomerTransaction transaction) {
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
    final isPayment = transaction.isPayment;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isPayment
                  ? Colors.green.withValues(alpha: 0.1)
                  : Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isPayment ? Icons.arrow_downward : Icons.receipt_long,
              color: isPayment ? Colors.green : Colors.orange,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.transactionTypeDisplay,
                  style: const TextStyle(
                    fontFamily: 'Literata',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dateFormat.format(transaction.createdAt),
                  style: TextStyle(
                    fontFamily: 'Literata',
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
                if (transaction.billNumber != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Bill: ${transaction.billNumber}',
                    style: TextStyle(
                      fontFamily: 'Literata',
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
                if (transaction.paymentMode != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B4D3E).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      transaction.paymentMode!.displayName,
                      style: const TextStyle(
                        fontFamily: 'Literata',
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1B4D3E),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Amount and Balance
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isPayment ? '-' : '+'}₹${transaction.amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontFamily: 'Literata',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isPayment ? Colors.green : Colors.orange,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Bal: ₹${transaction.balanceAfterTransaction.toStringAsFixed(2)}',
                style: TextStyle(
                  fontFamily: 'Literata',
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build Events/Orders summary card
  Widget _buildEventsSummaryCard() {
    if (_eventOrders.isEmpty) return const SizedBox.shrink();

    final activeOrders = _eventOrders
        .where((o) => o.status != OrderStatus.cancelled)
        .toList();
    final pendingOrders = activeOrders
        .where((o) => o.remainingAmount > 0)
        .length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF1B4D3E).withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B4D3E).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.event_note,
                  color: Color(0xFF1B4D3E),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Events & Orders',
                style: TextStyle(
                  fontFamily: 'Literata',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B4D3E),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${activeOrders.length}',
                  style: const TextStyle(
                    fontFamily: 'Literata',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Stats row
          Row(
            children: [
              Expanded(
                child: _buildEventStatItem(
                  'Total Amount',
                  '₹${_totalEventsAmount.toStringAsFixed(0)}',
                  Colors.blue,
                ),
              ),
              Expanded(
                child: _buildEventStatItem(
                  'Advance Paid',
                  '₹${_totalAdvanceReceived.toStringAsFixed(0)}',
                  Colors.green,
                ),
              ),
              Expanded(
                child: _buildEventStatItem(
                  'Due',
                  '₹${(_totalEventsAmount - _totalAdvanceReceived).toStringAsFixed(0)}',
                  Colors.orange,
                ),
              ),
            ],
          ),
          if (pendingOrders > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange[700], size: 16),
                  const SizedBox(width: 8),
                  Text(
                    '$pendingOrders ${pendingOrders == 1 ? 'order' : 'orders'} with pending payment',
                    style: TextStyle(
                      fontFamily: 'Literata',
                      fontSize: 12,
                      color: Colors.orange[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEventStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Literata',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Literata',
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  /// Build combined transaction item (bills + events/orders)
  Widget _buildCombinedTransactionItem(_CombinedTransaction item) {
    if (item.type == _TransactionType.billTransaction &&
        item.transaction != null) {
      return _buildTransactionItem(item.transaction!);
    } else if (item.type == _TransactionType.eventOrder &&
        item.eventOrder != null) {
      return _buildEventOrderItem(item.eventOrder!);
    }
    return const SizedBox.shrink();
  }

  /// Build event order item for transaction list
  Widget _buildEventOrderItem(EventOrder order) {
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
    final isEvent = order.orderType == OrderType.event;
    final statusColor = _getStatusColor(order.status);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF1B4D3E).withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF1B4D3E).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isEvent ? Icons.celebration : Icons.shopping_bag,
              color: const Color(0xFF1B4D3E),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        order.orderName,
                        style: const TextStyle(
                          fontFamily: 'Literata',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        order.status.displayName,
                        style: TextStyle(
                          fontFamily: 'Literata',
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  dateFormat.format(order.eventDate),
                  style: TextStyle(
                    fontFamily: 'Literata',
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isEvent
                        ? Colors.purple.withValues(alpha: 0.1)
                        : Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isEvent ? 'Event' : 'Sales Order',
                    style: TextStyle(
                      fontFamily: 'Literata',
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: isEvent ? Colors.purple : Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Amount
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${order.totalAmount.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontFamily: 'Literata',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1B4D3E),
                ),
              ),
              const SizedBox(height: 4),
              if (order.advanceAmount > 0)
                Text(
                  'Adv: ₹${order.advanceAmount.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontFamily: 'Literata',
                    fontSize: 10,
                    color: Colors.green[600],
                  ),
                ),
              if (order.remainingAmount > 0)
                Text(
                  'Due: ₹${order.remainingAmount.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontFamily: 'Literata',
                    fontSize: 10,
                    color: Colors.orange[600],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.confirmed:
        return Colors.blue;
      case OrderStatus.inProgress:
        return Colors.purple;
      case OrderStatus.delivered:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
      case OrderStatus.convertedToBill:
        return const Color(0xFF1B4D3E);
    }
  }
}

/// Bottom sheet for receiving payment from customer
class ReceivePaymentSheet extends StatefulWidget {
  final Customer customer;
  final CustomerTransactionService transactionService;
  final VoidCallback onPaymentReceived;

  const ReceivePaymentSheet({
    super.key,
    required this.customer,
    required this.transactionService,
    required this.onPaymentReceived,
  });

  @override
  State<ReceivePaymentSheet> createState() => _ReceivePaymentSheetState();
}

class _ReceivePaymentSheetState extends State<ReceivePaymentSheet> {
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  final _referenceController = TextEditingController();
  PaymentMode _selectedPaymentMode = PaymentMode.cash;
  bool _isProcessing = false;

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  double get _enteredAmount {
    return double.tryParse(_amountController.text) ?? 0.0;
  }

  double get _newBalance {
    return (widget.customer.currentPendingAmount - _enteredAmount).clamp(
      0.0,
      double.infinity,
    );
  }

  bool get _isValidAmount {
    return _enteredAmount > 0 &&
        _enteredAmount <= widget.customer.currentPendingAmount;
  }

  Future<void> _processPayment() async {
    if (!_isValidAmount) return;

    setState(() => _isProcessing = true);

    try {
      final result = await widget.transactionService.receivePayment(
        customerId: widget.customer.id,
        amount: _enteredAmount,
        paymentMode: _selectedPaymentMode,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
        referenceNumber: _referenceController.text.trim().isNotEmpty
            ? _referenceController.text.trim()
            : null,
      );

      // Also update local Isar so dashboard refreshes
      await CustomerTransactionOfflineController.instance.addPaymentTransaction(
        customerId: widget.customer.id,
        customerName: widget.customer.fullName,
        amount: _enteredAmount,
        description: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : 'Payment received',
        paymentMethod: _selectedPaymentMode.name,
      );

      if (!mounted) return;

      if (result.success) {
        Navigator.pop(context);
        GlassyToast.show(
          context,
          'Payment of ₹${_enteredAmount.toStringAsFixed(2)} recorded',
        );
        widget.onPaymentReceived();
      } else {
        GlassyToast.show(
          context,
          result.errorMessage ?? 'Failed to process payment',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
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
            const Text(
              'Receive Payment',
              style: TextStyle(
                fontFamily: 'Literata',
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'From: ${widget.customer.fullName}',
              style: TextStyle(
                fontFamily: 'Literata',
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 20),
            // Current Pending
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B6B).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFFF6B6B).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Current Pending',
                    style: TextStyle(
                      fontFamily: 'Literata',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '₹${widget.customer.currentPendingAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontFamily: 'Literata',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFFF6B6B),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Amount Input
            const Text(
              'Amount Received',
              style: TextStyle(
                fontFamily: 'Literata',
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: const TextStyle(
                fontFamily: 'Literata',
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                prefixText: '₹ ',
                prefixStyle: const TextStyle(
                  fontFamily: 'Literata',
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
                hintText: '0.00',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF1B4D3E),
                    width: 2,
                  ),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
            // Quick amount buttons
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                _buildQuickAmountButton(500),
                _buildQuickAmountButton(1000),
                _buildQuickAmountButton(2000),
                _buildQuickAmountButton(
                  widget.customer.currentPendingAmount,
                  label: 'Full',
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Payment Mode
            const Text(
              'Payment Mode',
              style: TextStyle(
                fontFamily: 'Literata',
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: PaymentMode.values.map((mode) {
                final isSelected = _selectedPaymentMode == mode;
                return ChoiceChip(
                  label: Text(
                    mode.displayName,
                    style: TextStyle(
                      fontFamily: 'Literata',
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: const Color(0xFF1B4D3E),
                  onSelected: (_) =>
                      setState(() => _selectedPaymentMode = mode),
                );
              }).toList(),
            ),
            // Reference Number (for non-cash)
            if (_selectedPaymentMode != PaymentMode.cash) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _referenceController,
                style: const TextStyle(fontFamily: 'Literata'),
                decoration: InputDecoration(
                  labelText: 'Reference Number',
                  hintText: 'Transaction ID / Cheque No.',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
            // Notes
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              style: const TextStyle(fontFamily: 'Literata'),
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Notes (Optional)',
                hintText: 'Add any notes...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // New Balance Preview
            if (_enteredAmount > 0)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.green.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'New Pending Balance',
                      style: TextStyle(
                        fontFamily: 'Literata',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '₹${_newBalance.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontFamily: 'Literata',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isValidAmount && !_isProcessing
                    ? _processPayment
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B4D3E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  disabledBackgroundColor: Colors.grey[300],
                ),
                child: _isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Text(
                        'Receive ₹${_enteredAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontFamily: 'Literata',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAmountButton(double amount, {String? label}) {
    return OutlinedButton(
      onPressed: () {
        _amountController.text = amount.toStringAsFixed(
          amount == amount.roundToDouble() ? 0 : 2,
        );
        setState(() {});
      },
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Color(0xFF1B4D3E)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(
        label ?? '₹${amount.toStringAsFixed(0)}',
        style: const TextStyle(
          fontFamily: 'Literata',
          color: Color(0xFF1B4D3E),
        ),
      ),
    );
  }
}

/// Transaction type for combined list
enum _TransactionType { billTransaction, eventOrder }

/// Combined transaction model for unified display
class _CombinedTransaction {
  final _TransactionType type;
  final DateTime date;
  final CustomerTransaction? transaction;
  final EventOrder? eventOrder;

  _CombinedTransaction({
    required this.type,
    required this.date,
    this.transaction,
    this.eventOrder,
  });
}
