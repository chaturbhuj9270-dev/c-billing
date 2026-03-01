import 'package:flutter/material.dart';
import '../../domain/repositories/customer_repository.dart';

/// Add/Edit Customer Page for offline-first architecture
class CustomerAddEditPage extends StatefulWidget {
  final Customer? customer; // null for add, non-null for edit

  const CustomerAddEditPage({super.key, this.customer});

  @override
  State<CustomerAddEditPage> createState() => _CustomerAddEditPageState();
}

class _CustomerAddEditPageState extends State<CustomerAddEditPage> {
  final CustomerRepository _repository = CustomerRepository.instance;
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _mobileController;
  late TextEditingController _addressController;
  late TextEditingController _emailController;

  bool _isLoading = false;
  bool get _isEditing => widget.customer != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.customer?.name ?? '');
    _mobileController = TextEditingController(
      text: widget.customer?.mobile ?? '',
    );
    _addressController = TextEditingController(
      text: widget.customer?.address ?? '',
    );
    _emailController = TextEditingController(
      text: widget.customer?.email ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _saveCustomer() async {
    if (!_formKey.currentState!.validate()) {
      debugPrint('[CustomerAddEdit] Form validation failed');
      return;
    }

    debugPrint('[CustomerAddEdit] Starting save...');
    setState(() => _isLoading = true);

    try {
      final mobile = _mobileController.text.trim();
      debugPrint('[CustomerAddEdit] Checking mobile: $mobile');

      // Check for duplicate mobile
      final mobileExists = await _repository.mobileExists(
        mobile,
        excludeId: widget.customer?.localId,
      );

      if (mobileExists) {
        debugPrint('[CustomerAddEdit] Mobile already exists');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'A customer with this mobile number already exists',
              ),
              backgroundColor: Colors.red.shade600,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      if (_isEditing) {
        debugPrint(
          '[CustomerAddEdit] Updating customer ID: ${widget.customer!.localId}',
        );
        // Update existing customer
        await _repository.updateCustomer(
          id: widget.customer!.localId!,
          name: _nameController.text.trim(),
          mobile: mobile,
          address: _addressController.text.trim().isEmpty
              ? null
              : _addressController.text.trim(),
          email: _emailController.text.trim().isEmpty
              ? null
              : _emailController.text.trim(),
        );
        debugPrint('[CustomerAddEdit] Customer updated successfully');
      } else {
        debugPrint('[CustomerAddEdit] Creating new customer...');
        // Create new customer
        final newCustomer = await _repository.createCustomer(
          name: _nameController.text.trim(),
          mobile: mobile,
          address: _addressController.text.trim().isEmpty
              ? null
              : _addressController.text.trim(),
          email: _emailController.text.trim().isEmpty
              ? null
              : _emailController.text.trim(),
        );
        debugPrint(
          '[CustomerAddEdit] Customer created with ID: ${newCustomer.localId}',
        );
      }

      if (mounted) {
        debugPrint('[CustomerAddEdit] Navigating back...');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing ? 'Customer updated' : 'Customer saved offline',
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e, stackTrace) {
      debugPrint('[CustomerAddEdit] Error: $e');
      debugPrint('[CustomerAddEdit] Stack: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving customer: ${e.toString()}'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
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
        title: Text(
          _isEditing ? 'Edit Customer' : 'Add Customer',
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
            )
          else
            TextButton(
              onPressed: _saveCustomer,
              child: const Text(
                'Save',
                style: TextStyle(
                  color: Color(0xFF6C63FF),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildTextField(
              controller: _nameController,
              label: 'Name',
              icon: Icons.person_outline,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _mobileController,
              label: 'Mobile Number',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Mobile number is required';
                }
                if (value.trim().length < 10) {
                  return 'Enter a valid mobile number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _emailController,
              label: 'Email (Optional)',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _addressController,
              label: 'Address (Optional)',
              icon: Icons.location_on_outlined,
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            // Offline indicator
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.cloud_off_outlined,
                    color: Colors.blue.shade300,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Customer will be saved locally and synced when online',
                      style: TextStyle(
                        color: Colors.blue.shade300,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
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
}
