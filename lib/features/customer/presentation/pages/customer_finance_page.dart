import 'package:flutter/material.dart';
import '../../../billing/offline/controllers/bill_offline_controller.dart';
import '../../../billing/offline/entities/bill_entity.dart';
import '../../../event_order/offline/controllers/event_order_offline_controller.dart';
import '../../../event_order/offline/entities/event_order_entity.dart';
import '../../../event_order/domain/entities/event_order.dart';
import 'package:intl/intl.dart';

/// Premium Customer Finance/History Page
/// Shows all bills and events/orders for a specific customer
class CustomerFinancePage extends StatefulWidget {
  final String customerId; // Server ID (Firebase document ID)
  final String? customerLocalId; // Local Isar ID
  final String customerName;
  final String customerContact;
  final double currentPendingAmount;

  const CustomerFinancePage({
    super.key,
    required this.customerId,
    this.customerLocalId,
    required this.customerName,
    required this.customerContact,
    required this.currentPendingAmount,
  });

  @override
  State<CustomerFinancePage> createState() => _CustomerFinancePageState();
}

class _CustomerFinancePageState extends State<CustomerFinancePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<BillEntity> _bills = [];
  List<EventOrderEntity> _eventOrders = [];
  bool _isLoading = true;

  // Stats
  double _totalBillAmount = 0;
  double _totalPaidAmount = 0;
  double _totalPendingAmount = 0;
  double _totalEventAmount = 0;
  double _totalAdvanceAmount = 0;
  double _totalEventPending = 0;
  int _totalBillCount = 0;
  int _totalEventCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      debugPrint(
        '[CustomerFinance] Loading data for customerId: ${widget.customerId}, localId: ${widget.customerLocalId}',
      );

      // Load bills for this customer (try serverId first, then local id)
      List<BillEntity> bills = await BillOfflineController.instance
          .getBillsByCustomerId(widget.customerId);
      debugPrint(
        '[CustomerFinance] Bills found with serverId: ${bills.length}',
      );

      // If no bills found with serverId, try local ID
      if (bills.isEmpty &&
          widget.customerLocalId != null &&
          widget.customerLocalId!.isNotEmpty &&
          widget.customerLocalId != widget.customerId) {
        bills = await BillOfflineController.instance.getBillsByCustomerId(
          widget.customerLocalId!,
        );
        debugPrint(
          '[CustomerFinance] Bills found with localId: ${bills.length}',
        );
      }

      // Load event orders for this customer (try serverId first)
      List<EventOrderEntity> eventOrders = await EventOrderOfflineController
          .instance
          .getEventOrdersByCustomerId(widget.customerId);
      debugPrint(
        '[CustomerFinance] Events found with serverId: ${eventOrders.length}',
      );

      // If no event orders found with serverId, try local ID
      if (eventOrders.isEmpty &&
          widget.customerLocalId != null &&
          widget.customerLocalId!.isNotEmpty &&
          widget.customerLocalId != widget.customerId) {
        eventOrders = await EventOrderOfflineController.instance
            .getEventOrdersByCustomerId(widget.customerLocalId!);
        debugPrint(
          '[CustomerFinance] Events found with localId: ${eventOrders.length}',
        );
      }

      // Debug: Get all event orders to see what customer IDs exist
      if (eventOrders.isEmpty) {
        final allOrders = await EventOrderOfflineController.instance
            .getAllEventOrders();
        debugPrint(
          '[CustomerFinance] Total event orders in DB: ${allOrders.length}',
        );
        for (final o in allOrders) {
          debugPrint(
            '[CustomerFinance] Order customerId: "${o.customerId}" vs looking for: "${widget.customerId}" or "${widget.customerLocalId}"',
          );
        }
      }

      // Sort events: upcoming first (latest on top), then passed events (latest on top)
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Separate upcoming and passed events
      final upcomingEvents = eventOrders
          .where((e) => !e.eventDate.isBefore(today))
          .toList();
      final passedEvents = eventOrders
          .where((e) => e.eventDate.isBefore(today))
          .toList();

      // Sort upcoming events by date descending (latest scheduled first)
      upcomingEvents.sort((a, b) => b.eventDate.compareTo(a.eventDate));
      // Sort passed events by date descending (most recently passed first)
      passedEvents.sort((a, b) => b.eventDate.compareTo(a.eventDate));

      // Combine: upcoming first, then passed
      final sortedEventOrders = [...upcomingEvents, ...passedEvents];

      // Calculate bill stats
      double totalBill = 0;
      double totalPaid = 0;
      double totalPending = 0;

      for (final bill in bills) {
        totalBill += bill.finalAmount;
        totalPaid += bill.paidAmount;
        totalPending += bill.pendingAmount;
      }

      // Calculate event stats
      double totalEvent = 0;
      double totalAdvance = 0;
      double totalEventPending = 0;

      for (final order in sortedEventOrders) {
        totalEvent += order.totalAmount;
        totalAdvance += order.advanceAmount;
        totalEventPending += order.remainingAmount;
      }

      setState(() {
        _bills = bills;
        _eventOrders = sortedEventOrders;
        _totalBillAmount = totalBill;
        _totalPaidAmount = totalPaid;
        _totalPendingAmount = totalPending;
        _totalEventAmount = totalEvent;
        _totalAdvanceAmount = totalAdvance;
        _totalEventPending = totalEventPending;
        _totalBillCount = bills.length;
        _totalEventCount = eventOrders.length;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading customer finance data: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F6),
      body: Column(
        children: [
          // Premium Header
          _buildHeader(),

          // Content Area
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF1B4D3E)),
                  )
                : Column(
                    children: [
                      // Stats Cards
                      _buildStatsSection(),

                      // Tab Bar
                      _buildTabBar(),

                      // Tab Content
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildBillsList(),
                            _buildEventOrdersList(),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
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
            color: const Color(0xFF1B4D3E).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Status bar space + Navigation
          Padding(
            padding: EdgeInsets.only(top: topPadding),
            child: SizedBox(
              height: 56,
              child: Row(
                children: [
                  // Back Button
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
                  const SizedBox(width: 4),
                  // Page Title
                  const Text(
                    'Finance History',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Literata',
                    ),
                  ),
                  const Spacer(),
                  // Refresh Button
                  IconButton(
                    onPressed: _loadData,
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
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

          // Customer Info Card
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  // Avatar
                  Hero(
                    tag: 'customer_avatar_${widget.customerId}',
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withValues(alpha: 0.25),
                            Colors.white.withValues(alpha: 0.1),
                          ],
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Literata',
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Name and Contact
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.customerName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Literata',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.phone_rounded,
                              size: 13,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              widget.customerContact,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 13,
                                fontFamily: 'Literata',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Pending Amount Badge
                  if (widget.currentPendingAmount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.red.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '₹${widget.currentPendingAmount.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Literata',
                            ),
                          ),
                          Text(
                            'pending',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Literata',
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.green.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            color: Colors.green[300],
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Clear',
                            style: TextStyle(
                              color: Colors.green[200],
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Literata',
                            ),
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

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.white,
        unselectedLabelColor: const Color(0xFF1B4D3E),
        indicator: BoxDecoration(
          color: const Color(0xFF1B4D3E),
          borderRadius: BorderRadius.circular(10),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          fontFamily: 'Literata',
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          fontFamily: 'Literata',
        ),
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.receipt_long_rounded, size: 16),
                const SizedBox(width: 6),
                Text('Bills ($_totalBillCount)'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.event_rounded, size: 16),
                const SizedBox(width: 6),
                Text('Events ($_totalEventCount)'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    final isEventTab = _tabController.index == 1;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              icon: isEventTab
                  ? Icons.event_rounded
                  : Icons.receipt_long_rounded,
              label: isEventTab ? 'Total Orders' : 'Total Billed',
              value:
                  '₹${_formatAmount(isEventTab ? _totalEventAmount : _totalBillAmount)}',
              color: const Color(0xFF1B4D3E),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              icon: Icons.check_circle_rounded,
              label: isEventTab ? 'Advance' : 'Received',
              value:
                  '₹${_formatAmount(isEventTab ? _totalAdvanceAmount : _totalPaidAmount)}',
              color: Colors.green,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              icon: Icons.schedule_rounded,
              label: isEventTab ? 'Remaining' : 'Pending',
              value:
                  '₹${_formatAmount(isEventTab ? _totalEventPending : _totalPendingAmount)}',
              color: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  String _formatAmount(double amount) {
    return amount.toStringAsFixed(0);
  }

  Widget _buildBillsList() {
    if (_bills.isEmpty) {
      return _buildEmptyState(
        icon: Icons.receipt_long_rounded,
        title: 'No Bills Yet',
        subtitle: 'Bills created for this customer will appear here',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _bills.length,
      itemBuilder: (context, index) {
        final bill = _bills[index];
        return _BillCard(bill: bill);
      },
    );
  }

  Widget _buildEventOrdersList() {
    if (_eventOrders.isEmpty) {
      return _buildEmptyState(
        icon: Icons.event_rounded,
        title: 'No Events/Orders Yet',
        subtitle: 'Events and orders for this customer will appear here',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _eventOrders.length,
      itemBuilder: (context, index) {
        final order = _eventOrders[index];
        return _EventOrderCard(order: order);
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
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
                color: const Color(0xFF1B4D3E).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 40,
                color: const Color(0xFF1B4D3E).withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1B4D3E),
                fontFamily: 'Literata',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
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
}

/// Statistics Card Widget
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
              fontFamily: 'Literata',
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
              fontFamily: 'Literata',
            ),
          ),
        ],
      ),
    );
  }
}

/// Bill Card Widget
class _BillCard extends StatelessWidget {
  final BillEntity bill;

  const _BillCard({required this.bill});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');
    final isPaid = bill.paymentStatus == BillPaymentStatus.paid;
    final isPartial = bill.paymentStatus == BillPaymentStatus.partiallyPaid;

    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (isPaid) {
      statusColor = Colors.green;
      statusText = 'Paid';
      statusIcon = Icons.check_circle_rounded;
    } else if (isPartial) {
      statusColor = Colors.orange;
      statusText = 'Partial';
      statusIcon = Icons.hourglass_bottom_rounded;
    } else {
      statusColor = Colors.red;
      statusText = 'Pending';
      statusIcon = Icons.schedule_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B4D3E).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.receipt_rounded,
                    color: Color(0xFF1B4D3E),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bill #${bill.id}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1B4D3E),
                          fontFamily: 'Literata',
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dateFormat.format(bill.billDate),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontFamily: 'Literata',
                        ),
                      ),
                    ],
                  ),
                ),
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                          fontFamily: 'Literata',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Divider
            Container(height: 1, color: Colors.grey[100]),
            const SizedBox(height: 14),
            // Amount Details
            Row(
              children: [
                _AmountDetail(
                  label: 'Total',
                  amount: bill.finalAmount,
                  color: const Color(0xFF1B4D3E),
                ),
                const SizedBox(width: 24),
                _AmountDetail(
                  label: 'Paid',
                  amount: bill.paidAmount,
                  color: Colors.green,
                ),
                const SizedBox(width: 24),
                _AmountDetail(
                  label: 'Due',
                  amount: bill.pendingAmount,
                  color: Colors.red,
                ),
                const Spacer(),
                // Items count
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${bill.items.length} items',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[700],
                      fontFamily: 'Literata',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Amount Detail Widget
class _AmountDetail extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;

  const _AmountDetail({
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[500],
            fontFamily: 'Literata',
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '₹${amount.toStringAsFixed(0)}',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color,
            fontFamily: 'Literata',
          ),
        ),
      ],
    );
  }
}

/// Event/Order Card Widget
class _EventOrderCard extends StatelessWidget {
  final EventOrderEntity order;

  const _EventOrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');
    final isEvent = order.orderType == OrderType.event.index;
    final status = OrderStatus.values[order.status];

    Color statusColor;
    IconData typeIcon;

    switch (status) {
      case OrderStatus.pending:
        statusColor = Colors.orange;
        break;
      case OrderStatus.confirmed:
        statusColor = Colors.blue;
        break;
      case OrderStatus.inProgress:
        statusColor = Colors.purple;
        break;
      case OrderStatus.delivered:
        statusColor = Colors.green;
        break;
      case OrderStatus.cancelled:
        statusColor = Colors.red;
        break;
      case OrderStatus.convertedToBill:
        statusColor = Colors.teal;
        break;
    }

    typeIcon = isEvent ? Icons.celebration_rounded : Icons.shopping_bag_rounded;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (isEvent ? Colors.purple : Colors.blue).withValues(
                      alpha: 0.1,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    typeIcon,
                    color: isEvent ? Colors.purple : Colors.blue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.orderName.isNotEmpty
                            ? order.orderName
                            : (isEvent ? 'Event' : 'Sales Order'),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1B4D3E),
                          fontFamily: 'Literata',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 12,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            dateFormat.format(order.eventDate),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontFamily: 'Literata',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Type Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: (isEvent ? Colors.purple : Colors.blue).withValues(
                      alpha: 0.1,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isEvent ? 'Event' : 'Order',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isEvent ? Colors.purple : Colors.blue,
                      fontFamily: 'Literata',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Divider
            Container(height: 1, color: Colors.grey[100]),
            const SizedBox(height: 14),
            // Bottom Row
            Row(
              children: [
                // Status
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status.displayName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                      fontFamily: 'Literata',
                    ),
                  ),
                ),
                const Spacer(),
                // Amount Info
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${order.totalAmount.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1B4D3E),
                        fontFamily: 'Literata',
                      ),
                    ),
                    if (order.advanceAmount > 0)
                      Text(
                        'Adv: ₹${order.advanceAmount.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.green[600],
                          fontFamily: 'Literata',
                        ),
                      ),
                  ],
                ),
              ],
            ),
            // Location if available
            if (order.eventLocation != null &&
                order.eventLocation!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    Icons.location_on_rounded,
                    size: 14,
                    color: Colors.grey[500],
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      order.eventLocation!,
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
            ],
          ],
        ),
      ),
    );
  }
}
