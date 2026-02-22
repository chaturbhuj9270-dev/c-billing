import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/services/event_order_settings_service.dart';
import '../../domain/entities/event_order.dart';
import '../../domain/entities/sub_event.dart';
import '../../domain/entities/order_item.dart';
import '../cubit/event_order_cubit.dart';
import '../../data/services/event_order_pdf_service.dart';
import '../../../shop/data/repositories/shop_repository.dart';
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
  final _pdfService = EventOrderPdfService();
  bool _isPdfLoading = false;

  // Controllers
  final _customerNameController = TextEditingController();
  final _customerContactController = TextEditingController();
  final _customerAddressController = TextEditingController();
  final _orderNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _advanceController = TextEditingController(text: '0');
  final _eventChargesController = TextEditingController(text: '0');
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

  // Custom fields for events
  final Map<String, TextEditingController> _customTextControllers = {};
  final Map<String, dynamic> _customFieldValues = {};

  bool get _isEditing => widget.existingOrder != null;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);

    // Initialize custom field controllers
    _initializeCustomFieldControllers();

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

  void _initializeCustomFieldControllers() {
    final eventColumns = EventOrderSettingsService.instance.activeEventColumns;
    for (final column in eventColumns) {
      if (column.type == EventCustomColumnType.text ||
          column.type == EventCustomColumnType.number ||
          column.type == EventCustomColumnType.decimal) {
        _customTextControllers[column.id] = TextEditingController(
          text: column.defaultValue ?? '',
        );
      } else if (column.type == EventCustomColumnType.boolean) {
        _customFieldValues[column.id] = column.defaultValue == 'true';
      } else if (column.type == EventCustomColumnType.dropdown) {
        _customFieldValues[column.id] = column.defaultValue ??
            ((column.dropdownOptions?.isNotEmpty ?? false)
                ? column.dropdownOptions!.first
                : '');
      } else if (column.type == EventCustomColumnType.date) {
        _customFieldValues[column.id] = column.defaultValue;
      }
    }
  }

  void _loadExistingOrder() {
    final order = widget.existingOrder!;
    _orderType = order.orderType;
    _tabController.index = order.orderType.index;
    _selectedCustomerId = order.customerId;
    _customerNameController.text = order.customerName;
    _customerContactController.text = order.customerContact;
    _customerAddressController.text = order.customerAddress ?? '';
    _orderNameController.text = order.orderName;
    _descriptionController.text = order.description ?? '';
    _eventDate = order.eventDate;
    _locationController.text = order.eventLocation ?? '';
    _subEvents = List.from(order.subEvents);
    _orderItems = List.from(order.items);
    _advanceController.text = order.advanceAmount.toStringAsFixed(0);
    _eventChargesController.text = order.eventCharges.toStringAsFixed(0);
    _notesController.text = order.notes ?? '';
    
    // Load custom field values from existing order
    final customData = order.customData;
    for (final entry in customData.entries) {
      final columnId = entry.key;
      final value = entry.value;
      if (_customTextControllers.containsKey(columnId)) {
        _customTextControllers[columnId]!.text = value?.toString() ?? '';
      } else {
        _customFieldValues[columnId] = value;
      }
    }
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
          _customerAddressController.text = customer.address ?? '';
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
      _customerAddressController.text = customer.address ?? '';
      _customers = [];
    });
  }

  double get _subEventsTotal {
    return _subEvents.fold(0.0, (sum, e) => sum + e.charges);
  }

  double get _productsTotal {
    return _orderItems.fold(0.0, (sum, e) => sum + e.total);
  }

  double get _eventCharges {
    return double.tryParse(_eventChargesController.text) ?? 0.0;
  }

  double get _totalAmount {
    if (_orderType == OrderType.event) {
      // Events can have event charges, sub-events and products
      return _eventCharges + _subEventsTotal + _productsTotal;
    } else {
      return _productsTotal;
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
    _customerAddressController.dispose();
    _orderNameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _advanceController.dispose();
    _eventChargesController.dispose();
    _notesController.dispose();
    // Dispose custom field controllers
    for (final controller in _customTextControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  /// Collect custom field values into a single map
  Map<String, dynamic> _collectCustomData() {
    final customData = <String, dynamic>{};
    final eventColumns = EventOrderSettingsService.instance.activeEventColumns;
    
    for (final column in eventColumns) {
      if (_customTextControllers.containsKey(column.id)) {
        final value = _customTextControllers[column.id]!.text.trim();
        if (value.isNotEmpty) {
          if (column.type == EventCustomColumnType.number) {
            customData[column.id] = int.tryParse(value) ?? 0;
          } else if (column.type == EventCustomColumnType.decimal) {
            customData[column.id] = double.tryParse(value) ?? 0.0;
          } else {
            customData[column.id] = value;
          }
        }
      } else if (_customFieldValues.containsKey(column.id)) {
        final value = _customFieldValues[column.id];
        if (value != null && value.toString().isNotEmpty) {
          customData[column.id] = value;
        }
      }
    }
    
    return customData;
  }

  Future<void> _saveOrder() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate mode-specific data
    if (_orderType == OrderType.event && _subEvents.isEmpty && _orderItems.isEmpty) {
      _showErrorSnackBar('Please add at least one sub-event or product');
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
          customerAddress: _customerAddressController.text.trim().isEmpty
              ? null
              : _customerAddressController.text.trim(),
          orderName: _orderNameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          eventDate: _eventDate,
          eventLocation: _locationController.text.trim().isEmpty
              ? null
              : _locationController.text.trim(),
          subEvents: _subEvents,
          items: _orderItems,
          eventCharges: _eventCharges,
          advanceAmount: _advanceAmount,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
          customData: _collectCustomData(),
        );
      } else {
        await cubit.createEventOrder(
          orderType: _orderType,
          customerId: _selectedCustomerId,
          customerName: _customerNameController.text.trim(),
          customerContact: _customerContactController.text.trim(),
          customerAddress: _customerAddressController.text.trim().isEmpty
              ? null
              : _customerAddressController.text.trim(),
          orderName: _orderNameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          eventDate: _eventDate,
          eventLocation: _locationController.text.trim().isEmpty
              ? null
              : _locationController.text.trim(),
          subEvents: _subEvents,
          items: _orderItems,
          eventCharges: _eventCharges,
          advanceAmount: _advanceAmount,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
          customData: _collectCustomData(),
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
        backgroundColor: const Color(0xFFF8F9FC),
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
                      const SizedBox(height: 16),
                      _buildOrderDetailsSection(),
                      const SizedBox(height: 16),
                      // Mode-specific content
                      if (_orderType == OrderType.event) ...[
                        _buildSubEventsSection(),
                        const SizedBox(height: 16),
                        _buildEventProductsSection(),
                      ] else
                        _buildSalesOrderSection(),
                      const SizedBox(height: 16),
                      // Show grand total breakdown for events with both items
                      if (_orderType == OrderType.event && (_subEvents.isNotEmpty || _orderItems.isNotEmpty))
                        _buildGrandTotalSection(),
                      if (_orderType == OrderType.event && (_subEvents.isNotEmpty || _orderItems.isNotEmpty))
                        const SizedBox(height: 16),
                      // Event charges field for event orders only
                      if (_orderType == OrderType.event) ...[
                        _buildEventChargesSection(),
                        const SizedBox(height: 16),
                      ],
                      _buildAdvanceSection(),
                      const SizedBox(height: 16),
                      _buildNotesSection(),
                      const SizedBox(height: 16),
                      // Custom fields section for events only
                      if (_orderType == OrderType.event)
                        _buildCustomFieldsSection(),
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
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        onPressed: () => Navigator.of(context).pop(),
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF1B4D3E).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.arrow_back_ios_new, 
            color: Color(0xFF1B4D3E), 
            size: 18,
          ),
        ),
      ),
      title: Text(
        _isEditing
            ? 'Edit ${_orderType == OrderType.event ? "Event" : "Order"}'
            : 'New ${_orderType == OrderType.event ? "Event" : "Order"}',
        style: const TextStyle(
          fontFamily: 'Literata',
          color: Color(0xFF1A1A2E),
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      actions: [
        if (_isEditing && widget.existingOrder != null) ...[
          IconButton(
            onPressed: _isPdfLoading ? null : _shareOrder,
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF1B4D3E).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: _isPdfLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF1B4D3E),
                      ),
                    )
                  : const Icon(Icons.share_rounded, 
                      color: Color(0xFF1B4D3E), 
                      size: 18,
                    ),
            ),
          ),
          IconButton(
            onPressed: _isPdfLoading ? null : _printOrder,
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.print_rounded, 
                color: Colors.orange, 
                size: 18,
              ),
            ),
          ),
        ],
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.all(16),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1B4D3E)),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildModeToggle() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1B4D3E), Color(0xFF2D6B5A)],
          ),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1B4D3E).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorPadding: EdgeInsets.zero,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey[600],
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Literata'),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontFamily: 'Literata'),
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.celebration_rounded, size: 18),
                SizedBox(width: 8),
                Text('Event'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shopping_bag_rounded, size: 18),
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
      trailing: TextButton.icon(
        onPressed: _showCustomerPickerSheet,
        icon: const Icon(Icons.person_search, size: 18, color: Color(0xFF1B4D3E)),
        label: const Text(
          'Select',
          style: TextStyle(
            fontFamily: 'Literata',
            color: Color(0xFF1B4D3E),
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          backgroundColor: const Color(0xFF1B4D3E).withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
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
              constraints: const BoxConstraints(maxHeight: 180),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withOpacity(0.15)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: _isSearchingCustomers
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF1B4D3E),
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: _customers.length,
                      itemBuilder: (context, index) {
                        final customer = _customers[index];
                        return ListTile(
                          dense: true,
                          leading: CircleAvatar(
                            radius: 16,
                            backgroundColor: const Color(0xFF1B4D3E).withOpacity(0.15),
                            child: Text(
                              customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?',
                              style: const TextStyle(
                                fontFamily: 'Literata',
                                color: Color(0xFF1B4D3E),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          title: Text(
                            customer.name,
                            style: const TextStyle(
                              fontFamily: 'Literata',
                              color: Color(0xFF1A1A2E),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                customer.mobile,
                                style: TextStyle(
                                  fontFamily: 'Literata',
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                              if (customer.address?.isNotEmpty == true)
                                Text(
                                  customer.address!,
                                  style: TextStyle(
                                    fontFamily: 'Literata',
                                    color: Colors.grey[500],
                                    fontSize: 11,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
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
          const SizedBox(height: 12),
          _buildTextField(
            controller: _customerAddressController,
            label: 'Address (Optional)',
            icon: Icons.location_on,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  /// Show customer picker bottom sheet
  Future<void> _showCustomerPickerSheet() async {
    // Load all customers
    final controller = CustomerOfflineController.instance;
    final allCustomers = await controller.getAllCustomers();
    
    if (!mounted) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CustomerPickerSheet(
        customers: allCustomers,
        onCustomerSelected: (customer) {
          _selectCustomer(customer);
          Navigator.pop(ctx);
        },
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
          _buildTextField(
            controller: _locationController,
            label: 'Location/Venue (Optional)',
            icon: Icons.location_on,
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
              data: ThemeData.light().copyWith(
                colorScheme: const ColorScheme.light(
                  primary: Color(0xFF1B4D3E),
                  surface: Colors.white,
                  onSurface: Color(0xFF1A1A2E),
                ),
                dialogBackgroundColor: Colors.white,
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
          color: const Color(0xFFF8F9FC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withOpacity(0.15)),
        ),
        child: Row(
          children: [
            Icon(
              _orderType == OrderType.event
                  ? Icons.calendar_today
                  : Icons.local_shipping,
              color: Colors.grey[500],
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
                    style: TextStyle(
                      fontFamily: 'Literata',
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('EEEE, dd MMM yyyy').format(_eventDate),
                    style: const TextStyle(
                      fontFamily: 'Literata',
                      color: Color(0xFF1A1A2E),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_drop_down, color: Colors.grey[500]),
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
        icon: const Icon(Icons.add_circle, color: Color(0xFF1B4D3E)),
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
                    color: Colors.grey.withOpacity(0.3),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No sub-events added',
                    style: TextStyle(
                      fontFamily: 'Literata',
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to add events like Haldi, Sangeet, etc.',
                    style: TextStyle(
                      fontFamily: 'Literata',
                      color: Colors.grey[400],
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
        color: const Color(0xFFF8F9FC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF1B4D3E).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.celebration, color: Color(0xFF1B4D3E)),
        ),
        title: Text(
          subEvent.name,
          style: const TextStyle(
            fontFamily: 'Literata',
            color: Color(0xFF1A1A2E),
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat('dd MMM yyyy').format(subEvent.date),
              style: TextStyle(
                fontFamily: 'Literata',
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            if (subEvent.notes?.isNotEmpty == true)
              Text(
                subEvent.notes!,
                style: TextStyle(
                  fontFamily: 'Literata',
                  color: Colors.grey[500],
                  fontSize: 11,
                ),
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
                fontFamily: 'Literata',
                color: Color(0xFF4CAF50),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: Colors.grey[500]),
              color: Colors.white,
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onSelected: (value) {
                if (value == 'edit') {
                  _showEditSubEventDialog(subEvent, index);
                } else if (value == 'delete') {
                  _deleteSubEvent(index);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, color: Colors.grey[700], size: 18),
                      const SizedBox(width: 8),
                      Text('Edit', style: TextStyle(fontFamily: 'Literata', color: Colors.grey[800])),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red, size: 18),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(fontFamily: 'Literata', color: Colors.red)),
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

  /// Products section for Event type - allows adding products to events
  Widget _buildEventProductsSection() {
    return _buildSectionCard(
      title: 'Event Products',
      icon: Icons.shopping_bag,
      trailing: IconButton(
        icon: const Icon(Icons.add_circle, color: Color(0xFF1B4D3E)),
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
                    Icons.shopping_bag,
                    size: 48,
                    color: Colors.grey.withOpacity(0.3),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No products added',
                    style: TextStyle(
                      fontFamily: 'Literata',
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to add products for this event (optional)',
                    style: TextStyle(
                      fontFamily: 'Literata',
                      color: Colors.grey[400],
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
        ],
      ),
    );
  }

  /// Grand total section showing breakdown of sub-events + products
  Widget _buildGrandTotalSection() {
    final hasSubEvents = _subEvents.isNotEmpty;
    final hasProducts = _orderItems.isNotEmpty;
    
    // Only show breakdown if there are items to display
    if (!hasSubEvents && !hasProducts) return const SizedBox.shrink();
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1B4D3E).withOpacity(0.08),
            const Color(0xFF1B4D3E).withOpacity(0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF1B4D3E).withOpacity(0.15)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B4D3E).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.receipt_long, color: Color(0xFF1B4D3E), size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Total Summary',
                style: TextStyle(
                  fontFamily: 'Literata',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Sub-events total
          if (hasSubEvents) ...[
            _buildTotalRow(
              'Sub-Events (${_subEvents.length})',
              _subEventsTotal,
              Icons.celebration,
              const Color(0xFF1B4D3E),
            ),
            const SizedBox(height: 8),
          ],
          // Products total
          if (hasProducts) ...[
            _buildTotalRow(
              'Products (${_orderItems.length})',
              _productsTotal,
              Icons.shopping_bag,
              Colors.green,
            ),
            const SizedBox(height: 8),
          ],
          // Divider
          if (hasSubEvents && hasProducts) ...[
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(vertical: 8),
              color: const Color(0xFF1B4D3E).withOpacity(0.2),
            ),
          ],
          // Grand total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Grand Total',
                style: TextStyle(
                  fontFamily: 'Literata',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '₹${_totalAmount.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontFamily: 'Literata',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4CAF50),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, double amount, IconData icon, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Literata',
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
        Text(
          '₹${amount.toStringAsFixed(0)}',
          style: TextStyle(
            fontFamily: 'Literata',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }

  Widget _buildSalesOrderSection() {
    return _buildSectionCard(
      title: 'Products',
      icon: Icons.inventory_2,
      trailing: IconButton(
        icon: const Icon(Icons.add_circle, color: Color(0xFF1B4D3E)),
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
                    color: Colors.grey.withOpacity(0.3),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No products added',
                    style: TextStyle(
                      fontFamily: 'Literata',
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to add products to this order',
                    style: TextStyle(
                      fontFamily: 'Literata',
                      color: Colors.grey[400],
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
                color: Colors.blue.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue.withOpacity(0.15)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade600, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Stock will be deducted only when converted to final bill',
                      style: TextStyle(
                        fontFamily: 'Literata',
                        color: Colors.blue.shade700,
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
        color: const Color(0xFFF8F9FC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.inventory, color: Colors.green),
        ),
        title: Text(
          item.productName,
          style: const TextStyle(
            fontFamily: 'Literata',
            color: Color(0xFF1A1A2E),
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${item.quantity} × ₹${item.rate.toStringAsFixed(0)}',
              style: TextStyle(
                fontFamily: 'Literata',
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            if (item.discountPercent > 0)
              Text(
                'Discount: ${item.discountPercent}%',
                style: TextStyle(
                  fontFamily: 'Literata',
                  color: Colors.orange.shade700,
                  fontSize: 11,
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '₹${item.total.toStringAsFixed(0)}',
              style: const TextStyle(
                fontFamily: 'Literata',
                color: Color(0xFF4CAF50),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: Colors.grey[500]),
              color: Colors.white,
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onSelected: (value) {
                if (value == 'edit') {
                  _showEditProductDialog(item, index);
                } else if (value == 'delete') {
                  _deleteOrderItem(index);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, color: Colors.grey[700], size: 18),
                      const SizedBox(width: 8),
                      Text('Edit', style: TextStyle(fontFamily: 'Literata', color: Colors.grey[800])),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red, size: 18),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(fontFamily: 'Literata', color: Colors.red)),
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

  Widget _buildEventChargesSection() {
    return _buildSectionCard(
      title: 'Event Charges',
      icon: Icons.event_note,
      child: _buildTextField(
        controller: _eventChargesController,
        label: 'Additional Event Charges',
        icon: Icons.currency_rupee,
        keyboardType: TextInputType.number,
        onChanged: (_) => setState(() {}),
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

  Widget _buildCustomFieldsSection() {
    final eventColumns = EventOrderSettingsService.instance.activeEventColumns;
    if (eventColumns.isEmpty) return const SizedBox.shrink();

    return _buildSectionCard(
      title: 'Custom Fields',
      icon: Icons.edit_attributes,
      child: Column(
        children: eventColumns.map((column) => _buildCustomFieldWidget(column)).toList(),
      ),
    );
  }

  Widget _buildCustomFieldWidget(EventCustomColumn column) {
    switch (column.type) {
      case EventCustomColumnType.text:
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildTextField(
            controller: _customTextControllers[column.id]!,
            label: column.name,
            icon: Icons.text_fields,
            required: column.isRequired,
          ),
        );
      case EventCustomColumnType.number:
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildTextField(
            controller: _customTextControllers[column.id]!,
            label: column.name,
            icon: Icons.numbers,
            keyboardType: TextInputType.number,
            required: column.isRequired,
          ),
        );
      case EventCustomColumnType.decimal:
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildTextField(
            controller: _customTextControllers[column.id]!,
            label: column.name,
            icon: Icons.attach_money,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            required: column.isRequired,
          ),
        );
      case EventCustomColumnType.date:
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildCustomDateField(column),
        );
      case EventCustomColumnType.dropdown:
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildCustomDropdownField(column),
        );
      case EventCustomColumnType.boolean:
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildCustomBooleanField(column),
        );
    }
  }

  Widget _buildCustomDateField(EventCustomColumn column) {
    final dateStr = _customFieldValues[column.id] as String?;
    DateTime? selectedDate;
    if (dateStr != null && dateStr.isNotEmpty) {
      try {
        selectedDate = DateTime.parse(dateStr);
      } catch (_) {}
    }

    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: selectedDate ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
        );
        if (picked != null) {
          setState(() {
            _customFieldValues[column.id] = picked.toIso8601String().split('T')[0];
          });
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: column.name,
          prefixIcon: const Icon(Icons.calendar_today),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(
          selectedDate != null
              ? DateFormat('dd/MM/yyyy').format(selectedDate)
              : 'Select Date',
          style: TextStyle(
            color: selectedDate != null ? Colors.black : Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildCustomDropdownField(EventCustomColumn column) {
    final currentValue = _customFieldValues[column.id] as String?;
    final options = column.dropdownOptions ?? [];

    return DropdownButtonFormField<String>(
      value: options.contains(currentValue) ? currentValue : null,
      decoration: InputDecoration(
        labelText: column.name,
        prefixIcon: const Icon(Icons.list),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: options.map((option) {
        return DropdownMenuItem(value: option, child: Text(option));
      }).toList(),
      onChanged: (value) {
        setState(() {
          _customFieldValues[column.id] = value;
        });
      },
      validator: column.isRequired
          ? (value) => value == null || value.isEmpty ? 'Required' : null
          : null,
    );
  }

  Widget _buildCustomBooleanField(EventCustomColumn column) {
    final value = _customFieldValues[column.id] as bool? ?? false;

    return SwitchListTile(
      title: Text(
        column.name,
        style: const TextStyle(fontFamily: 'Literata'),
      ),
      value: value,
      onChanged: (newValue) {
        setState(() {
          _customFieldValues[column.id] = newValue;
        });
      },
      activeColor: const Color(0xFF1B4D3E),
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildSummaryBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
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
                          color: const Color(0xFF4CAF50)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Remaining: ₹${_remainingAmount.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontFamily: 'Literata',
                      color: _remainingAmount > 0
                          ? Colors.orange.shade700
                          : const Color(0xFF4CAF50),
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
              label: Text(
                _isEditing ? 'Update' : 'Save',
                style: const TextStyle(fontFamily: 'Literata', fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B4D3E),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
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
            fontFamily: 'Literata',
            color: Colors.grey[500],
            fontSize: 11,
          ),
        ),
        Text(
          '₹${amount.toStringAsFixed(0)}',
          style: TextStyle(
            fontFamily: 'Literata',
            color: color ?? const Color(0xFF1A1A2E),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B4D3E).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: const Color(0xFF1B4D3E), size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Literata',
                    color: Color(0xFF1A1A2E),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
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
    bool required = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator ?? (required
            ? (value) => value == null || value.isEmpty ? 'Required' : null
            : null),
        onChanged: onChanged,
        style: const TextStyle(
          fontFamily: 'Literata',
          color: Color(0xFF1A1A2E),
          fontSize: 14,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            fontFamily: 'Literata',
            color: Colors.grey[500],
          ),
          prefixIcon: Icon(icon, color: Colors.grey[500]),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
          errorStyle: TextStyle(color: Colors.red.shade600),
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
    
    // Initialize custom field controllers for sub-event
    final subEventColumns = EventOrderSettingsService.instance.activeSubEventColumns;
    final dialogCustomTextControllers = <String, TextEditingController>{};
    final dialogCustomFieldValues = <String, dynamic>{};
    
    for (final column in subEventColumns) {
      final existingValue = subEvent?.customData[column.id];
      if (column.type == EventCustomColumnType.text ||
          column.type == EventCustomColumnType.number ||
          column.type == EventCustomColumnType.decimal) {
        dialogCustomTextControllers[column.id] = TextEditingController(
          text: existingValue?.toString() ?? column.defaultValue ?? '',
        );
      } else if (column.type == EventCustomColumnType.boolean) {
        dialogCustomFieldValues[column.id] = existingValue ?? (column.defaultValue == 'true');
      } else if (column.type == EventCustomColumnType.dropdown) {
        dialogCustomFieldValues[column.id] = existingValue ?? column.defaultValue ??
            ((column.dropdownOptions?.isNotEmpty ?? false)
                ? column.dropdownOptions!.first
                : '');
      } else if (column.type == EventCustomColumnType.date) {
        dialogCustomFieldValues[column.id] = existingValue ?? column.defaultValue;
      }
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              editIndex != null ? 'Edit Sub-Event' : 'Add Sub-Event',
              style: const TextStyle(
                fontFamily: 'Literata',
                color: Color(0xFF1A1A2E),
                fontWeight: FontWeight.bold,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    style: const TextStyle(
                      fontFamily: 'Literata',
                      color: Color(0xFF1A1A2E),
                    ),
                    decoration: InputDecoration(
                      labelText: 'Event Name *',
                      labelStyle: TextStyle(
                        fontFamily: 'Literata',
                        color: Colors.grey[600],
                      ),
                      hintText: 'e.g., Haldi, Sangeet, Reception',
                      hintStyle: TextStyle(
                        fontFamily: 'Literata',
                        color: Colors.grey[400],
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8F9FC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: chargesController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                      fontFamily: 'Literata',
                      color: Color(0xFF1A1A2E),
                    ),
                    decoration: InputDecoration(
                      labelText: 'Charges *',
                      labelStyle: TextStyle(
                        fontFamily: 'Literata',
                        color: Colors.grey[600],
                      ),
                      prefixText: '₹ ',
                      prefixStyle: TextStyle(
                        fontFamily: 'Literata',
                        color: Colors.grey[600],
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8F9FC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
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
                          data: ThemeData.light().copyWith(
                            colorScheme: const ColorScheme.light(
                              primary: Color(0xFF1B4D3E),
                              surface: Colors.white,
                              onSurface: Color(0xFF1A1A2E),
                            ),
                            dialogBackgroundColor: Colors.white,
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
                        color: const Color(0xFFF8F9FC),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today,
                              color: Colors.grey[600], size: 18),
                          const SizedBox(width: 12),
                          Text(
                            DateFormat('dd MMM yyyy').format(selectedDate),
                            style: const TextStyle(
                              fontFamily: 'Literata',
                              color: Color(0xFF1A1A2E),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesController,
                    maxLines: 2,
                    style: const TextStyle(
                      fontFamily: 'Literata',
                      color: Color(0xFF1A1A2E),
                    ),
                    decoration: InputDecoration(
                      labelText: 'Notes (Optional)',
                      labelStyle: TextStyle(
                        fontFamily: 'Literata',
                        color: Colors.grey[600],
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8F9FC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  // Custom fields for sub-events
                  if (subEventColumns.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Custom Fields',
                        style: TextStyle(
                          fontFamily: 'Literata',
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    ...subEventColumns.map((column) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildDialogCustomField(
                        column: column,
                        textControllers: dialogCustomTextControllers,
                        fieldValues: dialogCustomFieldValues,
                        setDialogState: setDialogState,
                      ),
                    )),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  // Dispose text controllers
                  for (final controller in dialogCustomTextControllers.values) {
                    controller.dispose();
                  }
                  Navigator.pop(context);
                },
                child: Text('Cancel',
                    style: TextStyle(
                      fontFamily: 'Literata',
                      color: Colors.grey[600],
                    )),
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

                  // Collect custom data for sub-event
                  final customData = <String, dynamic>{};
                  for (final column in subEventColumns) {
                    if (dialogCustomTextControllers.containsKey(column.id)) {
                      final value = dialogCustomTextControllers[column.id]!.text.trim();
                      if (value.isNotEmpty) {
                        if (column.type == EventCustomColumnType.number) {
                          customData[column.id] = int.tryParse(value) ?? 0;
                        } else if (column.type == EventCustomColumnType.decimal) {
                          customData[column.id] = double.tryParse(value) ?? 0.0;
                        } else {
                          customData[column.id] = value;
                        }
                      }
                    } else if (dialogCustomFieldValues.containsKey(column.id)) {
                      final value = dialogCustomFieldValues[column.id];
                      if (value != null && value.toString().isNotEmpty) {
                        customData[column.id] = value;
                      }
                    }
                  }

                  final newSubEvent = SubEvent(
                    id: subEvent?.id ?? _uuid.v4(),
                    name: name,
                    date: selectedDate,
                    charges: charges,
                    notes: notesController.text.trim().isEmpty
                        ? null
                        : notesController.text.trim(),
                    customData: customData,
                  );

                  setState(() {
                    if (editIndex != null) {
                      _subEvents[editIndex] = newSubEvent;
                    } else {
                      _subEvents.add(newSubEvent);
                    }
                  });
                  
                  // Dispose text controllers
                  for (final controller in dialogCustomTextControllers.values) {
                    controller.dispose();
                  }
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B4D3E),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  editIndex != null ? 'Update' : 'Add',
                  style: const TextStyle(fontFamily: 'Literata', fontWeight: FontWeight.w600),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Build a custom field widget for dialogs (sub-event dialog)
  Widget _buildDialogCustomField({
    required EventCustomColumn column,
    required Map<String, TextEditingController> textControllers,
    required Map<String, dynamic> fieldValues,
    required void Function(void Function()) setDialogState,
  }) {
    switch (column.type) {
      case EventCustomColumnType.text:
        return TextField(
          controller: textControllers[column.id],
          style: const TextStyle(fontFamily: 'Literata', color: Color(0xFF1A1A2E)),
          decoration: InputDecoration(
            labelText: column.isRequired ? '${column.name} *' : column.name,
            labelStyle: TextStyle(fontFamily: 'Literata', color: Colors.grey[600]),
            filled: true,
            fillColor: const Color(0xFFF8F9FC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        );
      case EventCustomColumnType.number:
        return TextField(
          controller: textControllers[column.id],
          keyboardType: TextInputType.number,
          style: const TextStyle(fontFamily: 'Literata', color: Color(0xFF1A1A2E)),
          decoration: InputDecoration(
            labelText: column.isRequired ? '${column.name} *' : column.name,
            labelStyle: TextStyle(fontFamily: 'Literata', color: Colors.grey[600]),
            filled: true,
            fillColor: const Color(0xFFF8F9FC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        );
      case EventCustomColumnType.decimal:
        return TextField(
          controller: textControllers[column.id],
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(fontFamily: 'Literata', color: Color(0xFF1A1A2E)),
          decoration: InputDecoration(
            labelText: column.isRequired ? '${column.name} *' : column.name,
            labelStyle: TextStyle(fontFamily: 'Literata', color: Colors.grey[600]),
            filled: true,
            fillColor: const Color(0xFFF8F9FC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        );
      case EventCustomColumnType.date:
        final dateStr = fieldValues[column.id] as String?;
        DateTime? selectedDate;
        if (dateStr != null && dateStr.isNotEmpty) {
          try {
            selectedDate = DateTime.parse(dateStr);
          } catch (_) {}
        }
        return InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: selectedDate ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime(2100),
            );
            if (picked != null) {
              setDialogState(() {
                fieldValues[column.id] = picked.toIso8601String().split('T')[0];
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.grey[600], size: 18),
                const SizedBox(width: 12),
                Text(
                  selectedDate != null
                      ? DateFormat('dd/MM/yyyy').format(selectedDate)
                      : column.name,
                  style: TextStyle(
                    fontFamily: 'Literata',
                    color: selectedDate != null ? const Color(0xFF1A1A2E) : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        );
      case EventCustomColumnType.dropdown:
        final options = column.dropdownOptions ?? [];
        final currentValue = fieldValues[column.id] as String?;
        return DropdownButtonFormField<String>(
          value: options.contains(currentValue) ? currentValue : null,
          decoration: InputDecoration(
            labelText: column.name,
            labelStyle: TextStyle(fontFamily: 'Literata', color: Colors.grey[600]),
            filled: true,
            fillColor: const Color(0xFFF8F9FC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          items: options.map((option) => DropdownMenuItem(
            value: option,
            child: Text(option, style: const TextStyle(fontFamily: 'Literata')),
          )).toList(),
          onChanged: (value) {
            setDialogState(() {
              fieldValues[column.id] = value;
            });
          },
        );
      case EventCustomColumnType.boolean:
        final value = fieldValues[column.id] as bool? ?? false;
        return SwitchListTile(
          title: Text(column.name, style: const TextStyle(fontFamily: 'Literata')),
          value: value,
          onChanged: (newValue) {
            setDialogState(() {
              fieldValues[column.id] = newValue;
            });
          },
          activeColor: const Color(0xFF1B4D3E),
          contentPadding: EdgeInsets.zero,
        );
    }
  }

  void _deleteSubEvent(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Sub-Event?',
            style: TextStyle(
              fontFamily: 'Literata',
              color: Color(0xFF1A1A2E),
              fontWeight: FontWeight.bold,
            )),
        content: Text(
          'Are you sure you want to delete "${_subEvents[index].name}"?',
          style: TextStyle(
            fontFamily: 'Literata',
            color: Colors.grey[700],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(
              fontFamily: 'Literata',
              color: Colors.grey[600],
            )),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => _subEvents.removeAt(index));
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Delete', style: TextStyle(fontFamily: 'Literata', fontWeight: FontWeight.w600)),
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
            backgroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              editIndex != null ? 'Edit Product' : 'Add Product',
              style: const TextStyle(
                fontFamily: 'Literata',
                color: Color(0xFF1A1A2E),
                fontWeight: FontWeight.bold,
              ),
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
                        style: const TextStyle(
                          fontFamily: 'Literata',
                          color: Color(0xFF1A1A2E),
                        ),
                        decoration: InputDecoration(
                          labelText: 'Search Product',
                          labelStyle: TextStyle(
                            fontFamily: 'Literata',
                            color: Colors.grey[600],
                          ),
                          prefixIcon:
                              Icon(Icons.search, color: Colors.grey[600]),
                          filled: true,
                          fillColor: const Color(0xFFF8F9FC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Product list
                      Container(
                        height: 150,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FC),
                          borderRadius: BorderRadius.circular(12),
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
                                  const Color(0xFF1B4D3E).withOpacity(0.1),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              title: Text(
                                product.name,
                                style: TextStyle(
                                  fontFamily: 'Literata',
                                  color: isSelected
                                      ? const Color(0xFF1B4D3E)
                                      : const Color(0xFF1A1A2E),
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                              subtitle: Text(
                                '₹${product.salesPrice.toStringAsFixed(0)} | Stock: ${product.currentStock}',
                                style: TextStyle(
                                  fontFamily: 'Literata',
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
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
                          color: const Color(0xFF1B4D3E).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.inventory,
                                color: Color(0xFF1B4D3E)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                item.productName,
                                style: const TextStyle(
                                  fontFamily: 'Literata',
                                  color: Color(0xFF1A1A2E),
                                  fontWeight: FontWeight.w600,
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
                      style: const TextStyle(
                        fontFamily: 'Literata',
                        color: Color(0xFF1A1A2E),
                      ),
                      decoration: InputDecoration(
                        labelText: 'Quantity *',
                        labelStyle: TextStyle(
                          fontFamily: 'Literata',
                          color: Colors.grey[600],
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8F9FC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Rate
                    TextField(
                      controller: rateController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(
                        fontFamily: 'Literata',
                        color: Color(0xFF1A1A2E),
                      ),
                      decoration: InputDecoration(
                        labelText: 'Rate *',
                        labelStyle: TextStyle(
                          fontFamily: 'Literata',
                          color: Colors.grey[600],
                        ),
                        prefixText: '₹ ',
                        prefixStyle: TextStyle(
                          fontFamily: 'Literata',
                          color: Colors.grey[600],
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8F9FC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Discount
                    TextField(
                      controller: discountController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(
                        fontFamily: 'Literata',
                        color: Color(0xFF1A1A2E),
                      ),
                      decoration: InputDecoration(
                        labelText: 'Discount %',
                        labelStyle: TextStyle(
                          fontFamily: 'Literata',
                          color: Colors.grey[600],
                        ),
                        suffixText: '%',
                        suffixStyle: TextStyle(
                          fontFamily: 'Literata',
                          color: Colors.grey[600],
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8F9FC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
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
                child: Text('Cancel',
                    style: TextStyle(
                      fontFamily: 'Literata',
                      color: Colors.grey[600],
                    )),
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
                  backgroundColor: const Color(0xFF1B4D3E),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  editIndex != null ? 'Update' : 'Add',
                  style: const TextStyle(fontFamily: 'Literata', fontWeight: FontWeight.w600),
                ),
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
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title:
            const Text('Delete Product?', style: TextStyle(
              fontFamily: 'Literata',
              color: Color(0xFF1A1A2E),
              fontWeight: FontWeight.bold,
            )),
        content: Text(
          'Are you sure you want to remove "${_orderItems[index].productName}"?',
          style: TextStyle(
            fontFamily: 'Literata',
            color: Colors.grey[700],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                Text('Cancel', style: TextStyle(
                  fontFamily: 'Literata',
                  color: Colors.grey[600],
                )),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => _orderItems.removeAt(index));
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Delete', style: TextStyle(fontFamily: 'Literata', fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Future<void> _shareOrder() async {
    if (widget.existingOrder == null) return;
    
    setState(() => _isPdfLoading = true);
    try {
      final shop = await ShopRepository().getShopDetails();
      await _pdfService.shareOrderAsPdf(
        order: widget.existingOrder!,
        shopDetails: shop,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPdfLoading = false);
      }
    }
  }

  Future<void> _printOrder() async {
    if (widget.existingOrder == null) return;
    
    setState(() => _isPdfLoading = true);
    try {
      final shop = await ShopRepository().getShopDetails();
      await _pdfService.printOrder(
        order: widget.existingOrder!,
        shopDetails: shop,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to print: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPdfLoading = false);
      }
    }
  }
}

/// Customer picker bottom sheet widget
class _CustomerPickerSheet extends StatefulWidget {
  final List<CustomerEntity> customers;
  final Function(CustomerEntity customer) onCustomerSelected;

  const _CustomerPickerSheet({
    required this.customers,
    required this.onCustomerSelected,
  });

  @override
  State<_CustomerPickerSheet> createState() => _CustomerPickerSheetState();
}

class _CustomerPickerSheetState extends State<_CustomerPickerSheet> {
  late List<CustomerEntity> _filteredCustomers;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredCustomers = widget.customers;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterCustomers(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCustomers = widget.customers;
      } else {
        final lowerQuery = query.toLowerCase();
        _filteredCustomers = widget.customers
            .where((c) =>
                c.name.toLowerCase().contains(lowerQuery) ||
                c.mobile.toLowerCase().contains(lowerQuery) ||
                (c.address?.toLowerCase().contains(lowerQuery) ?? false))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle bar
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B4D3E).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.person_outline,
                      color: Color(0xFF1B4D3E),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Select Customer',
                          style: TextStyle(
                            fontFamily: 'Literata',
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                        Text(
                          'Choose from existing customers',
                          style: TextStyle(
                            fontFamily: 'Literata',
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchController,
                onChanged: _filterCustomers,
                style: const TextStyle(fontFamily: 'Literata', fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search by name, phone or address',
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF1B4D3E)),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            _filterCustomers('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: const Color(0xFFF5F5F5),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Customers list
            Expanded(
              child: _filteredCustomers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No customers found',
                            style: TextStyle(
                              fontFamily: 'Literata',
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: controller,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _filteredCustomers.length,
                      itemBuilder: (context, index) {
                        final customer = _filteredCustomers[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey[200]!,
                              width: 1,
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => widget.onCustomerSelected(customer),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: const Color(0xFF1B4D3E),
                                      child: Text(
                                        customer.name.isNotEmpty
                                            ? customer.name[0].toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            customer.name,
                                            style: const TextStyle(
                                              fontFamily: 'Literata',
                                              fontWeight: FontWeight.w700,
                                              fontSize: 15,
                                              color: Color(0xFF1A1A2E),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Row(
                                            children: [
                                              Icon(Icons.phone, size: 12, color: Colors.grey[500]),
                                              const SizedBox(width: 4),
                                              Text(
                                                customer.mobile.isNotEmpty ? customer.mobile : '—',
                                                style: TextStyle(
                                                  fontFamily: 'Literata',
                                                  color: Colors.grey[600],
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (customer.address?.isNotEmpty == true) ...[
                                            const SizedBox(height: 2),
                                            Row(
                                              children: [
                                                Icon(Icons.location_on, size: 12, color: Colors.grey[500]),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    customer.address!,
                                                    style: TextStyle(
                                                      fontFamily: 'Literata',
                                                      color: Colors.grey[500],
                                                      fontSize: 11,
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
                                    const SizedBox(width: 8),
                                    Icon(
                                      Icons.chevron_right,
                                      color: Colors.grey[400],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
