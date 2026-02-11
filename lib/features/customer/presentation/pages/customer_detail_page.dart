import 'package:flutter/material.dart';
import '../../domain/repositories/customer_repository.dart';
import '../../data/services/customer_sync_service.dart';
import 'customer_add_edit_page.dart';

/// Customer detail page for offline-first architecture
class CustomerDetailPage extends StatefulWidget {
  final Customer customer;

  const CustomerDetailPage({super.key, required this.customer});

  @override
  State<CustomerDetailPage> createState() => _CustomerDetailPageState();
}

class _CustomerDetailPageState extends State<CustomerDetailPage> {
  final CustomerRepository _repository = CustomerRepository.instance;
  final CustomerSyncService _syncService = CustomerSyncService.instance;
  
  late Customer _customer;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _customer = widget.customer;
  }

  Future<void> _editCustomer() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => CustomerAddEditPage(customer: _customer),
      ),
    );

    if (result == true && mounted) {
      // Refresh customer data
      final updated = await _repository.getCustomerById(_customer.localId!);
      if (updated != null && mounted) {
        setState(() => _customer = updated);
      }
      // Trigger sync
      _syncService.syncNow();
    }
  }

  Future<void> _deleteCustomer() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Customer?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to delete "${_customer.name}"? This action cannot be undone.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Delete',
              style: TextStyle(color: Colors.red.shade400),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isDeleting = true);

    try {
      await _repository.deleteCustomer(_customer.localId!);
      
      if (mounted) {
        Navigator.of(context).pop(true); // Return true to indicate deletion
        
        // Trigger sync
        _syncService.syncNow();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Customer deleted'),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting customer: ${e.toString()}'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        ),
        title: const Text(
          'Customer Details',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _editCustomer,
            icon: const Icon(Icons.edit_outlined, color: Colors.white70),
          ),
          if (_isDeleting)
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
            )
          else
            IconButton(
              onPressed: _deleteCustomer,
              icon: Icon(Icons.delete_outline, color: Colors.red.shade400),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile header
            _buildProfileHeader(),
            const SizedBox(height: 24),
            
            // Sync status
            if (!_customer.isSynced) _buildSyncStatus(),
            
            // Details cards
            _buildInfoCard(
              title: 'Contact Information',
              items: [
                _InfoItem(
                  icon: Icons.phone_outlined,
                  label: 'Mobile',
                  value: _customer.mobile,
                ),
                if (_customer.email != null && _customer.email!.isNotEmpty)
                  _InfoItem(
                    icon: Icons.email_outlined,
                    label: 'Email',
                    value: _customer.email!,
                  ),
                if (_customer.address != null && _customer.address!.isNotEmpty)
                  _InfoItem(
                    icon: Icons.location_on_outlined,
                    label: 'Address',
                    value: _customer.address!,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Financial info
            _buildInfoCard(
              title: 'Financial Summary',
              items: [
                _InfoItem(
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'Pending Amount',
                  value: '₹${_customer.currentPendingAmount.toStringAsFixed(2)}',
                  valueColor: _customer.currentPendingAmount > 0 
                      ? Colors.red.shade400 
                      : Colors.green.shade400,
                ),
                _InfoItem(
                  icon: Icons.shopping_cart_outlined,
                  label: 'Total Purchases',
                  value: '₹${_customer.totalPurchases.toStringAsFixed(2)}',
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Metadata
            _buildInfoCard(
              title: 'Record Information',
              items: [
                _InfoItem(
                  icon: Icons.calendar_today_outlined,
                  label: 'Created',
                  value: _formatDate(_customer.createdAt),
                ),
                _InfoItem(
                  icon: Icons.update_outlined,
                  label: 'Last Updated',
                  value: _formatDate(_customer.updatedAt),
                ),
                _InfoItem(
                  icon: Icons.tag_outlined,
                  label: 'ID',
                  value: _customer.displayId,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF6C63FF),
            const Color(0xFF8B7CFF),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C63FF).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                _customer.name.isNotEmpty 
                    ? _customer.name[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Name
          Text(
            _customer.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          // Mobile
          Text(
            _customer.mobile,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncStatus() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.amber.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.cloud_upload_outlined,
            color: Colors.amber.shade400,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'This customer has not been synced to the server yet',
              style: TextStyle(
                color: Colors.amber.shade400,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required List<_InfoItem> items,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ...items.map((item) => _buildInfoRow(item)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(_InfoItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            item.icon,
            color: Colors.white.withValues(alpha: 0.5),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.value,
                  style: TextStyle(
                    color: item.valueColor ?? Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}, '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }
}

class _InfoItem {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });
}
