import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/event_order.dart';
import '../../domain/entities/sub_event.dart';
import '../../domain/entities/order_item.dart';
import '../cubit/event_order_cubit.dart';
import '../../../customer/offline/controllers/customer_offline_controller.dart';
import '../../../customer/offline/entities/customer_entity.dart';
import '../../../product/offline/controllers/product_offline_controller.dart';
import '../../../product/offline/entities/product_entity.dart';

/// Event Management + Sales Order Screen
/// Supports two modes: Event Mode (with sub-events) and Sales Order Mode (with products)
class EventOrderScreen extends StatefulWidget {
  final EventOrder? existingOrder; // null for create, non-null for edit
  final OrderType? initialMode;
  final String? preSelectedCustomerId;
  final String? preSelectedCustomerName;

  const EventOrderScreen({
    super.key,
    this.existingOrder,
    this.initialMode,
    this.preSelectedCustomerId,
    this.preSelectedCustomerName,
  });

  @override
  State<EventOrderScreen> createState() => _EventOrderScreenState();
}

class _EventOrderScreenState extends State<EventOrderScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TabController _tabController;
  final _uuid = const Uuid();

  // Controllers
  final _customerNameController = TextEditingController();
  final _customerContactController = TextEditingController();
  final _orderNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _advanceController = TextEditingController(text: '0');
  final _notesController = TextEditingController();

  // State
  OrderType _orderType = OrderType.event;
  DateTime _eventDate = DateTime.now().add(const Duration(days: 7));
  List<SubEvent> _subEvents = [];
  List<OrderItem> _orderItems = [];
  String? _selectedCustomerId;
  bool _isLoading = false;

  // Customer search
  List<CustomerEntity> _customers = [];
  bool _isSearchingCustomers = false;
  // ignore: unused_field
  CustomerEntity? _selectedCustomer;

  // Product search for Sales Order
  List<ProductEntity> _products = [];
  // ignore: unused_field
  bool _isLoadingProducts = false;

  bool get _isEditing => widget.existingOrder != null;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);

    // Initialize with existing data or defaults
    if (_isEditing) {
      _loadExistingOrder();
    } else {
      _orderType = widget.initialMode ?? OrderType.event;
      _tabController.index = _orderType.index;
      
      // Pre-select customer if provided
      if (widget.preSelectedCustomerId != null) {
        _selectedCustomerId = widget.preSelectedCustomerId;
        _customerNameController.text = widget.preSelectedCustomerName ?? '';
        _loadCustomerDetails(widget.preSelectedCustomerId!);
      }
    }

    _loadProducts();
  }

  void _loadExistingOrder() {
    final order = widget.existingOrder!;
    _orderType = order.orderType;
    _tabController.index = order.orderType.index;
    _selectedCustomerId = order.customerId;
    _customerNameController.text = order.customerName;
    _customerContactController.text = order.customerContact;
    _orderNameController.text = order.orderName;
    _descriptionController.text = order.description ?? '';
    _eventDate = order.eventDate;
    _subEvents = List.from(order.subEvents);
    _orderItems = List.from(order.items);
    _advanceController.text = order.advanceAmount.toStringAsFixed(0);
    _notesController.text = order.notes ?? '';
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      setState(() {
        _orderType = OrderType.values[_tabController.index];
      });
    }
  }

  Future<void> _loadCustomerDetails(String customerId) async {
    try {
      final controller = CustomerOfflineController.instance;
      final customer = await controller.getCustomerById(int.parse(customerId));
      if (customer != null && mounted) {
        setState(() {
          _selectedCustomer = customer;
          _customerContactController.text = customer.mobile;
        });
      }
    } catch (e) {
      debugPrint('[EventOrderScreen] Error loading customer: $e');
    }
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoadingProducts = true);
    try {
      final controller = ProductOfflineController.instance;
      final products = await controller.getAllProducts();
      if (mounted) {
        setState(() {
          _products = products;
          _isLoadingProducts = false;
        });
      }
    } catch (e) {
      debugPrint('[EventOrderScreen] Error loading products: $e');
      if (mounted) {
        setState(() => _isLoadingProducts = false);
      }
    }
  }

  Future<void> _searchCustomers(String query) async {
    if (query.isEmpty) {
      setState(() => _customers = []);
      return;
    }

    setState(() => _isSearchingCustomers = true);
    try {
      final controller = CustomerOfflineController.instance;
      final customers = await controller.searchCustomers(query);
      if (mounted) {
        setState(() {
          _customers = customers;
          _isSearchingCustomers = false;
        });
      }
    } catch (e) {
      debugPrint('[EventOrderScreen] Error searching customers: $e');
      if (mounted) {
        setState(() => _isSearchingCustomers = false);
      }
    }
  }

  void _selectCustomer(CustomerEntity customer) {
    setState(() {
      _selectedCustomer = customer;
      _selectedCustomerId = customer.id.toString();
      _customerNameController.text = customer.name;
      _customerContactController.text = customer.mobile;
      _customers = [];
    });
  }

  double get _totalAmount {
    if (_orderType == OrderType.event) {
      return _subEvents.fold(0.0, (sum, e) => sum + e.charges);
    } else {
      return _orderItems.fold(0.0, (sum, e) => sum + e.total);
    }
  }

  double get _advanceAmount {
    return double.tryParse(_advanceController.text) ?? 0.0;
  }

  double get _remainingAmount => _totalAmount - _advanceAmount;

  @override
  void dispose() {
    _tabController.dispose();
    _customerNameController.dispose();
    _customerContactController.dispose();
    _orderNameController.dispose();
    _descriptionController.dispose();
    _advanceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveOrder() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate mode-specific data
    if (_orderType == OrderType.event && _subEvents.isEmpty) {
      _showErrorSnackBar('Please add at least one sub-event');
      return;
    }
    if (_orderType == OrderType.salesOrder && _orderItems.isEmpty) {
      _showErrorSnackBar('Please add at least one product');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final cubit = context.read<EventOrderCubit>();

      if (_isEditing) {
        // Extract local ID from order ID
        final orderId = widget.existingOrder!.id;
        final localId = orderId.startsWith('local_')
            ? int.parse(orderId.substring(6))
            : int.tryParse(orderId) ?? 0;

        await cubit.updateEventOrder(
          id: localId,
          orderType: _orderType,
          customerId: _selectedCustomerId,
          customerName: _customerNameController.text.trim(),
          customerContact: _customerContactController.text.trim(),
          orderName: _orderNameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          eventDate: _eventDate,
          subEvents: _subEvents,
          items: _orderItems,
          advanceAmount: _advanceAmount,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
        );
      } else {
        await cubit.createEventOrder(
          orderType: _orderType,
          customerId: _selectedCustomerId,
          customerName: _customerNameController.text.trim(),
          customerContact: _customerContactController.text.trim(),
          orderName: _orderNameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          eventDate: _eventDate,
          subEvents: _subEvents,
          items: _orderItems,
          advanceAmount: _advanceAmount,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
        );
      }

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Order updated' : 'Order saved'),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('[EventOrderScreen] Error saving order: $e');
      if (mounted) {
        _showErrorSnackBar('Error saving order: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => EventOrderCubit(),
      child: Scaffold(
        backgroundColor: const Color(0xFF1A1A2E),
        appBar: _buildAppBar(),
        body: Form(
          key: _formKey,
          child: Column(
            children: [
              // Mode toggle tabs
              _buildModeToggle(),
              // Form content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCustomerSection(),
                      const SizedBox(height: 20),
                      _buildOrderDetailsSection(),
                      const SizedBox(height: 20),
                      // Mode-specific content
                      if (_orderType == OrderType.event)
                        _buildSubEventsSection()
                      else
                        _buildSalesOrderSection(),
                      const SizedBox(height: 20),
                      _buildAdvanceSection(),
                      const SizedBox(height: 20),
                      _buildNotesSection(),
                      const SizedBox(height: 100), // Space for bottom bar
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: _buildSummaryBar(),
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
      title: Text(
        _isEditing
            ? 'Edit ${_orderType == OrderType.event ? "Event" : "Order"}'
            : 'New ${_orderType == OrderType.event ? "Event" : "Order"}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.all(16),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildModeToggle() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: const Color(0xFF6C63FF),
          borderRadius: BorderRadius.circular(10),
        ),
        indicatorPadding: const EdgeInsets.all(4),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white60,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
        tabs: const [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.celebration, size: 18),
                SizedBox(width: 8),
                Text('Event'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shopping_cart, size: 18),
                SizedBox(width: 8),
                Text('Sales Order'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerSection() {
    return _buildSectionCard(
      title: 'Customer Details',
      icon: Icons.person_outline,
      child: Column(
        children: [
          // Customer name with autocomplete
          _buildTextField(
            controller: _customerNameController,
            label: 'Customer Name *',
            icon: Icons.person,
            onChanged: (value) => _searchCustomers(value),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Customer name is required';
              }
              return null;
            },
          ),
          // Customer suggestions
          if (_customers.isNotEmpty || _isSearchingCustomers)
            Container(
              margin: const EdgeInsets.only(top: 4),
              constraints: const BoxConstraints(maxHeight: 150),
              decoration: BoxDecoration(
                color: const Color(0xFF252542),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white12),
              ),
              child: _isSearchingCustomers
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: _customers.length,
                      itemBuilder: (context, index) {
                        final customer = _customers[index];
                        return ListTile(
                          dense: true,
                          title: Text(
                            customer.name,
                            style: const TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            customer.mobile,
                            style: const TextStyle(color: Colors.white54),
                          ),
                          onTap: () => _selectCustomer(customer),
                        );
                      },
                    ),
            ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _customerContactController,
            label: 'Contact Number',
            icon: Icons.phone,
            keyboardType: TextInputType.phone,
          ),
        ],
      ),
    );
  }

  Widget _buildOrderDetailsSection() {
    return _buildSectionCard(
      title: _orderType == OrderType.event ? 'Event Details' : 'Order Details',
      icon: _orderType == OrderType.event ? Icons.event : Icons.assignment,
      child: Column(
        children: [
          _buildTextField(
            controller: _orderNameController,
            label: _orderType == OrderType.event
                ? 'Event Name *'
                : 'Order Name *',
            icon: Icons.title,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Name is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _descriptionController,
            label: 'Description (Optional)',
            icon: Icons.description,
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          // Date picker
          _buildDatePicker(),
        ],
      ),
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _eventDate,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
          builder: (context, child) {
            return Theme(
              data: ThemeData.dark().copyWith(
                colorScheme: const ColorScheme.dark(
                  primary: Color(0xFF6C63FF),
                  surface: Color(0xFF252542),
                ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          setState(() => _eventDate = picked);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          children: [
            Icon(
              _orderType == OrderType.event
                  ? Icons.calendar_today
                  : Icons.local_shipping,
              color: Colors.white54,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _orderType == OrderType.event
                        ? 'Event Date *'
                        : 'Delivery Date *',
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('EEEE, dd MMM yyyy').format(_eventDate),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: Colors.white54),
          ],
        ),
      ),
    );
  }

  Widget _buildSubEventsSection() {
    return _buildSectionCard(
      title: 'Sub Events',
      icon: Icons.event_note,
      trailing: IconButton(
        icon: const Icon(Icons.add_circle, color: Color(0xFF6C63FF)),
        onPressed: _showAddSubEventDialog,
      ),
      child: Column(
        children: [
          if (_subEvents.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.event_note,
                    size: 48,
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No sub-events added',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to add events like Haldi, Sangeet, etc.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            )
          else
            ...List.generate(_subEvents.length, (index) {
              final subEvent = _subEvents[index];
              return _buildSubEventCard(subEvent, index);
            }),
        ],
      ),
    );
  }

  Widget _buildSubEventCard(SubEvent subEvent, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF6C63FF).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.celebration, color: Color(0xFF6C63FF)),
        ),
        title: Text(
          subEvent.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat('dd MMM yyyy').format(subEvent.date),
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
            if (subEvent.notes?.isNotEmpty == true)
              Text(
                subEvent.notes!,
                style: const TextStyle(color: Colors.white38, fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '₹${subEvent.charges.toStringAsFixed(0)}',
              style: const TextStyle(
                color: Color(0xFF4CAF50),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white54),
              color: const Color(0xFF252542),
              onSelected: (value) {
                if (value == 'edit') {
                  _showEditSubEventDialog(subEvent, index);
                } else if (value == 'delete') {
                  _deleteSubEvent(index);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, color: Colors.white70, size: 18),
                      SizedBox(width: 8),
                      Text('Edit', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red, size: 18),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesOrderSection() {
    return _buildSectionCard(
      title: 'Products',
      icon: Icons.inventory_2,
      trailing: IconButton(
        icon: const Icon(Icons.add_circle, color: Color(0xFF6C63FF)),
        onPressed: _showAddProductDialog,
      ),
      child: Column(
        children: [
          if (_orderItems.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.inventory_2,
                    size: 48,
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No products added',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to add products to this order',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            )
          else
            ...List.generate(_orderItems.length, (index) {
              final item = _orderItems[index];
              return _buildOrderItemCard(item, index);
            }),
          // Stock not deducted info
          if (_orderItems.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade300, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Stock will be deducted only when converted to final bill',
                      style: TextStyle(
                        color: Colors.blue.shade300,
                        fontSize: 12,
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

  Widget _buildOrderItemCard(OrderItem item, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.inventory, color: Colors.green),
        ),
        title: Text(
          item.productName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${item.quantity} × ₹${item.rate.toStringAsFixed(0)}',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
            if (item.discountPercent > 0)
              Text(
                'Discount: ${item.discountPercent}%',
                style: TextStyle(color: Colors.orange.shade300, fontSize: 11),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '₹${item.total.toStringAsFixed(0)}',
              style: const TextStyle(
                color: Color(0xFF4CAF50),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white54),
              color: const Color(0xFF252542),
              onSelected: (value) {
                if (value == 'edit') {
                  _showEditProductDialog(item, index);
                } else if (value == 'delete') {
                  _deleteOrderItem(index);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, color: Colors.white70, size: 18),
                      SizedBox(width: 8),
                      Text('Edit', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red, size: 18),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvanceSection() {
    return _buildSectionCard(
      title: 'Advance Payment',
      icon: Icons.account_balance_wallet,
      child: _buildTextField(
        controller: _advanceController,
        label: 'Advance Amount Received',
        icon: Icons.currency_rupee,
        keyboardType: TextInputType.number,
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _buildNotesSection() {
    return _buildSectionCard(
      title: 'Notes',
      icon: Icons.note,
      child: _buildTextField(
        controller: _notesController,
        label: 'Additional Notes (Optional)',
        icon: Icons.note_add,
        maxLines: 3,
      ),
    );
  }

  Widget _buildSummaryBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF252542),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Summary info
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildSummaryItem('Total', _totalAmount),
                      const SizedBox(width: 16),
                      _buildSummaryItem('Advance', _advanceAmount,
                          color: Colors.green),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Remaining: ₹${_remainingAmount.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: _remainingAmount > 0
                          ? Colors.orange.shade300
                          : Colors.green.shade300,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            // Save button
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _saveOrder,
              icon: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.save),
              label: Text(_isEditing ? 'Update' : 'Save'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, double amount, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 11,
          ),
        ),
        Text(
          '₹${amount.toStringAsFixed(0)}',
          style: TextStyle(
            color: color ?? Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFF6C63FF), size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (trailing != null) ...[
                  const Spacer(),
                  trailing,
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        onChanged: onChanged,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
          prefixIcon: Icon(icon, color: Colors.white.withValues(alpha: 0.5)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
          errorStyle: TextStyle(color: Colors.red.shade300),
        ),
      ),
    );
  }

  // ==================== DIALOGS ====================

  void _showAddSubEventDialog() {
    _showSubEventDialog();
  }

  void _showEditSubEventDialog(SubEvent subEvent, int index) {
    _showSubEventDialog(subEvent: subEvent, editIndex: index);
  }

  void _showSubEventDialog({SubEvent? subEvent, int? editIndex}) {
    final nameController = TextEditingController(text: subEvent?.name ?? '');
    final chargesController =
        TextEditingController(text: subEvent?.charges.toStringAsFixed(0) ?? '');
    final notesController = TextEditingController(text: subEvent?.notes ?? '');
    DateTime selectedDate = subEvent?.date ?? _eventDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF252542),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              editIndex != null ? 'Edit Sub-Event' : 'Add Sub-Event',
              style: const TextStyle(color: Colors.white),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Event Name *',
                      labelStyle: const TextStyle(color: Colors.white54),
                      hintText: 'e.g., Haldi, Sangeet, Reception',
                      hintStyle: const TextStyle(color: Colors.white30),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: chargesController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Charges *',
                      labelStyle: const TextStyle(color: Colors.white54),
                      prefixText: '₹ ',
                      prefixStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 730)),
                        builder: (context, child) => Theme(
                          data: ThemeData.dark().copyWith(
                            colorScheme: const ColorScheme.dark(
                              primary: Color(0xFF6C63FF),
                              surface: Color(0xFF252542),
                            ),
                          ),
                          child: child!,
                        ),
                      );
                      if (picked != null) {
                        setDialogState(() => selectedDate = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today,
                              color: Colors.white54, size: 18),
                          const SizedBox(width: 12),
                          Text(
                            DateFormat('dd MMM yyyy').format(selectedDate),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesController,
                    maxLines: 2,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Notes (Optional)',
                      labelStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel',
                    style: TextStyle(color: Colors.white54)),
              ),
              ElevatedButton(
                onPressed: () {
                  final name = nameController.text.trim();
                  final charges =
                      double.tryParse(chargesController.text) ?? 0.0;

                  if (name.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter event name')),
                    );
                    return;
                  }

                  final newSubEvent = SubEvent(
                    id: subEvent?.id ?? _uuid.v4(),
                    name: name,
                    date: selectedDate,
                    charges: charges,
                    notes: notesController.text.trim().isEmpty
                        ? null
                        : notesController.text.trim(),
                  );

                  setState(() {
                    if (editIndex != null) {
                      _subEvents[editIndex] = newSubEvent;
                    } else {
                      _subEvents.add(newSubEvent);
                    }
                  });
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                ),
                child: Text(editIndex != null ? 'Update' : 'Add'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _deleteSubEvent(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF252542),
        title: const Text('Delete Sub-Event?',
            style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to delete "${_subEvents[index].name}"?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => _subEvents.removeAt(index));
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAddProductDialog() {
    _showProductDialog();
  }

  void _showEditProductDialog(OrderItem item, int index) {
    _showProductDialog(item: item, editIndex: index);
  }

  void _showProductDialog({OrderItem? item, int? editIndex}) {
    ProductEntity? selectedProduct;
    final quantityController =
        TextEditingController(text: item?.quantity.toString() ?? '1');
    final rateController =
        TextEditingController(text: item?.rate.toStringAsFixed(0) ?? '');
    final discountController =
        TextEditingController(text: item?.discountPercent.toString() ?? '0');
    String searchQuery = '';

    // If editing, find the product
    if (item != null) {
      for (final p in _products) {
        if (p.serverId == item.productId ||
            p.id.toString() == item.productId) {
          selectedProduct = p;
          break;
        }
      }
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final filteredProducts = searchQuery.isEmpty
              ? _products
              : _products
                  .where((p) =>
                      p.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
                      p.indexNo.toString().contains(searchQuery))
                  .toList();

          return AlertDialog(
            backgroundColor: const Color(0xFF252542),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              editIndex != null ? 'Edit Product' : 'Add Product',
              style: const TextStyle(color: Colors.white),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Product search
                    if (editIndex == null) ...[
                      TextField(
                        onChanged: (value) {
                          setDialogState(() => searchQuery = value);
                        },
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Search Product',
                          labelStyle: const TextStyle(color: Colors.white54),
                          prefixIcon:
                              const Icon(Icons.search, color: Colors.white54),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.05),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Product list
                      Container(
                        height: 150,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: filteredProducts.length,
                          itemBuilder: (context, index) {
                            final product = filteredProducts[index];
                            final isSelected =
                                selectedProduct?.id == product.id;
                            return ListTile(
                              dense: true,
                              selected: isSelected,
                              selectedTileColor:
                                  const Color(0xFF6C63FF).withValues(alpha: 0.2),
                              title: Text(
                                product.name,
                                style: TextStyle(
                                  color: isSelected
                                      ? const Color(0xFF6C63FF)
                                      : Colors.white,
                                ),
                              ),
                              subtitle: Text(
                                '₹${product.salesPrice.toStringAsFixed(0)} | Stock: ${product.currentStock}',
                                style: const TextStyle(
                                    color: Colors.white54, fontSize: 12),
                              ),
                              onTap: () {
                                setDialogState(() {
                                  selectedProduct = product;
                                  rateController.text =
                                      product.salesPrice.toStringAsFixed(0);
                                });
                              },
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    // Selected product info (for editing)
                    if (editIndex != null && item != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.inventory,
                                color: Color(0xFF6C63FF)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                item.productName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 12),
                    // Quantity
                    TextField(
                      controller: quantityController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Quantity *',
                        labelStyle: const TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Rate
                    TextField(
                      controller: rateController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Rate *',
                        labelStyle: const TextStyle(color: Colors.white54),
                        prefixText: '₹ ',
                        prefixStyle: const TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Discount
                    TextField(
                      controller: discountController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Discount %',
                        labelStyle: const TextStyle(color: Colors.white54),
                        suffixText: '%',
                        suffixStyle: const TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel',
                    style: TextStyle(color: Colors.white54)),
              ),
              ElevatedButton(
                onPressed: () {
                  if (editIndex == null && selectedProduct == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please select a product')),
                    );
                    return;
                  }

                  final quantity =
                      int.tryParse(quantityController.text) ?? 1;
                  final rate =
                      double.tryParse(rateController.text) ?? 0.0;
                  final discount =
                      double.tryParse(discountController.text) ?? 0.0;

                  if (rate <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter valid rate')),
                    );
                    return;
                  }

                  OrderItem newItem;
                  if (editIndex != null && item != null) {
                    // Update existing item - copyWith handles recalculations
                    newItem = item.copyWith(
                      quantity: quantity,
                      rate: rate,
                      discountPercent: discount,
                    );
                  } else {
                    // Create new item from product
                    newItem = OrderItem.fromProductEntity(
                      entity: selectedProduct!,
                      quantity: quantity,
                      rate: rate,
                      discountPercent: discount,
                    );
                  }

                  setState(() {
                    if (editIndex != null) {
                      _orderItems[editIndex] = newItem;
                    } else {
                      _orderItems.add(newItem);
                    }
                  });
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                ),
                child: Text(editIndex != null ? 'Update' : 'Add'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _deleteOrderItem(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF252542),
        title:
            const Text('Delete Product?', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to remove "${_orderItems[index].productName}"?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => _orderItems.removeAt(index));
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
