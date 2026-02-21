import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/event_order.dart';
import '../cubit/event_order_cubit.dart';
import '../cubit/event_order_state.dart';
import 'event_order_screen.dart';

/// Event Orders List Page - displays all events and sales orders
class EventOrderListPage extends StatefulWidget {
  final OrderType? filterType;

  const EventOrderListPage({super.key, this.filterType});

  @override
  State<EventOrderListPage> createState() => _EventOrderListPageState();
}

class _EventOrderListPageState extends State<EventOrderListPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  OrderStatus? _selectedStatus;
  OrderType? _selectedType;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _selectedType = widget.filterType;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => EventOrderCubit()..loadEventOrders(filterType: _selectedType),
      child: Scaffold(
        backgroundColor: const Color(0xFF1A1A2E),
        appBar: _buildAppBar(),
        body: Column(
          children: [
            _buildFilterSection(),
            Expanded(child: _buildOrdersList()),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _navigateToCreate(context),
          backgroundColor: const Color(0xFF6C63FF),
          icon: const Icon(Icons.add),
          label: const Text('New Order'),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF1A1A2E),
      elevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
      ),
      title: const Text(
        'Event & Orders',
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.filter_list, color: Colors.white70),
          onPressed: _showFilterDialog,
        ),
      ],
      bottom: TabBar(
        controller: _tabController,
        indicatorColor: const Color(0xFF6C63FF),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white54,
        onTap: (index) {
          setState(() {
            _selectedType = index == 0
                ? null
                : index == 1
                    ? OrderType.event
                    : OrderType.salesOrder;
          });
          context
              .read<EventOrderCubit>()
              .loadEventOrders(filterType: _selectedType);
        },
        tabs: const [
          Tab(text: 'All'),
          Tab(text: 'Events'),
          Tab(text: 'Sales Orders'),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search bar
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search by name or customer...',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                prefixIcon: Icon(Icons.search,
                    color: Colors.white.withValues(alpha: 0.5)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
              ),
              onChanged: (value) {
                context.read<EventOrderCubit>().loadEventOrders(
                      filterType: _selectedType,
                      searchQuery: value,
                    );
              },
            ),
          ),
          // Status filter chips
          if (_selectedStatus != null)
            Container(
              margin: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  Chip(
                    label: Text(
                      'Status: ${_selectedStatus!.displayName}',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    backgroundColor: const Color(0xFF6C63FF).withValues(alpha: 0.3),
                    deleteIcon:
                        const Icon(Icons.close, color: Colors.white70, size: 16),
                    onDeleted: () {
                      setState(() => _selectedStatus = null);
                      context
                          .read<EventOrderCubit>()
                          .loadEventOrders(filterType: _selectedType);
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOrdersList() {
    return BlocBuilder<EventOrderCubit, EventOrderState>(
      builder: (context, state) {
        if (state is EventOrderLoading) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6C63FF)),
            ),
          );
        }

        if (state is EventOrderError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                const SizedBox(height: 16),
                Text(
                  'Error loading orders',
                  style: TextStyle(color: Colors.red.shade300, fontSize: 16),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => context
                      .read<EventOrderCubit>()
                      .loadEventOrders(filterType: _selectedType),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (state is EventOrderLoaded) {
          final orders = state.orders;

          if (orders.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () => context
                .read<EventOrderCubit>()
                .loadEventOrders(filterType: _selectedType),
            color: const Color(0xFF6C63FF),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                return _buildOrderCard(context, orders[index]);
              },
            ),
          );
        }

        return const SizedBox();
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _selectedType == OrderType.event
                ? Icons.celebration
                : _selectedType == OrderType.salesOrder
                    ? Icons.shopping_cart
                    : Icons.event_note,
            size: 80,
            color: Colors.white.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 16),
          Text(
            _selectedType == OrderType.event
                ? 'No events found'
                : _selectedType == OrderType.salesOrder
                    ? 'No sales orders found'
                    : 'No orders found',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to create a new order',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, EventOrder order) {
    final isEvent = order.orderType == OrderType.event;
    final statusColor = _getStatusColor(order.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: InkWell(
        onTap: () => _navigateToEdit(context, order),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: (isEvent ? Colors.purple : Colors.green)
                          .withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isEvent ? Icons.celebration : Icons.shopping_cart,
                      color: isEvent ? Colors.purple : Colors.green,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.orderName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          order.customerName,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      order.status.displayName,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Date and items info
              Row(
                children: [
                  Icon(
                    isEvent ? Icons.event : Icons.local_shipping,
                    size: 14,
                    color: Colors.white38,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    DateFormat('dd MMM yyyy').format(order.eventDate),
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    isEvent ? Icons.event_note : Icons.inventory_2,
                    size: 14,
                    color: Colors.white38,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isEvent
                        ? '${order.subEvents.length} sub-events'
                        : '${order.items.length} items',
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Amount row
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildAmountColumn('Total', order.totalAmount, Colors.white),
                    Container(
                      width: 1,
                      height: 30,
                      color: Colors.white12,
                    ),
                    _buildAmountColumn(
                        'Advance', order.advanceAmount, Colors.green),
                    Container(
                      width: 1,
                      height: 30,
                      color: Colors.white12,
                    ),
                    _buildAmountColumn(
                      'Due',
                      order.remainingAmount,
                      order.remainingAmount > 0
                          ? Colors.orange
                          : Colors.green,
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

  Widget _buildAmountColumn(String label, double amount, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '₹${amount.toStringAsFixed(0)}',
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
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
        return Colors.teal;
    }
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF252542),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Filter by Status',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: OrderStatus.values.map((status) {
                    final isSelected = _selectedStatus == status;
                    return FilterChip(
                      label: Text(status.displayName),
                      selected: isSelected,
                      onSelected: (selected) {
                        setSheetState(() {
                          _selectedStatus = selected ? status : null;
                        });
                        setState(() {});
                        Navigator.pop(context);
                        this.context.read<EventOrderCubit>().loadEventOrders(
                              filterType: _selectedType,
                              filterStatus: _selectedStatus,
                            );
                      },
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                      selectedColor:
                          const Color(0xFF6C63FF).withValues(alpha: 0.3),
                      checkmarkColor: const Color(0xFF6C63FF),
                      labelStyle: TextStyle(
                        color: isSelected ? const Color(0xFF6C63FF) : Colors.white70,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                if (_selectedStatus != null)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        setSheetState(() => _selectedStatus = null);
                        setState(() {});
                        Navigator.pop(context);
                        this.context.read<EventOrderCubit>().loadEventOrders(
                              filterType: _selectedType,
                            );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: const BorderSide(color: Colors.white24),
                      ),
                      child: const Text('Clear Filter'),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _navigateToCreate(BuildContext context) async {
    final cubit = context.read<EventOrderCubit>();
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: cubit,
          child: EventOrderScreen(
            initialMode: _selectedType ?? OrderType.event,
          ),
        ),
      ),
    );
    if (result == true) {
      cubit.loadEventOrders(filterType: _selectedType);
    }
  }

  void _navigateToEdit(BuildContext context, EventOrder order) async {
    final cubit = context.read<EventOrderCubit>();
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: cubit,
          child: EventOrderScreen(existingOrder: order),
        ),
      ),
    );
    if (result == true) {
      cubit.loadEventOrders(filterType: _selectedType);
    }
  }
}
