import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ProductPage extends StatefulWidget {
  const ProductPage({super.key});

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  final _productNameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _companyController = TextEditingController();
  final _manufacturingDateController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _purchaseRateController = TextEditingController();
  final _saleRateController = TextEditingController();
  final _filterController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isEditing = false;
  String? _editingProductId;
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _filteredProducts = [];
  File? _selectedImage;
  final _imagePicker = ImagePicker();

  final _auth = FirebaseAuth.instance;
  late final FirebaseFirestore _firestore;

  @override
  void initState() {
    super.initState();
    _firestore = FirebaseFirestore.instance;
    _checkUserAuthentication();
    _loadProducts();
    _filterController.addListener(_filterProducts);
  }

  void _filterProducts() {
    final query = _filterController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredProducts = _products;
      } else {
        _filteredProducts = _products.where((product) {
          final name = (product['productName'] ?? '').toString().toLowerCase();
          return name.contains(query);
        }).toList();
      }
    });
  }

  void _checkUserAuthentication() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  Future<void> _loadProducts() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      final snapshot = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('products')
          .orderBy('createdAt', descending: true)
          .get();

      setState(() {
        _products = snapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  ...doc.data(),
                })
            .toList();
        _filterProducts();
      });
    } catch (e) {
      print('[ERROR] Failed to load products: $e');
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      final productData = {
        'productName': _productNameController.text.trim(),
        'quantity': int.tryParse(_quantityController.text) ?? 0,
        'company': _companyController.text.trim(),
        'manufacturingDate': _manufacturingDateController.text,
        'expiryDate': _expiryDateController.text,
        'purchaseRate': double.tryParse(_purchaseRateController.text) ?? 0.0,
        'saleRate': double.tryParse(_saleRateController.text) ?? 0.0,
        'imagePath': _selectedImage?.path ?? '',
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (_isEditing && _editingProductId != null) {
        await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .collection('products')
            .doc(_editingProductId)
            .update(productData);
        print('[DEBUG] Product updated: $_editingProductId');
      } else {
        productData['createdAt'] = FieldValue.serverTimestamp();
        await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .collection('products')
            .add(productData);
        print('[DEBUG] Product added');
      }

      if (mounted) {
        _clearForm();
        Navigator.pop(context);
        await _loadProducts();
      }
    } catch (e) {
      print('[ERROR] Failed to save product: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteProduct(String productId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('products')
          .doc(productId)
          .delete();

      print('[DEBUG] Product deleted: $productId');
      await _loadProducts();
    } catch (e) {
      print('[ERROR] Failed to delete product: $e');
    }
  }

  void _editProduct(Map<String, dynamic> product) {
    _isEditing = true;
    _editingProductId = product['id'];
    _productNameController.text = product['productName'] ?? '';
    _quantityController.text = (product['quantity'] ?? 0).toString();
    _companyController.text = product['company'] ?? '';
    _manufacturingDateController.text = product['manufacturingDate'] ?? '';
    _expiryDateController.text = product['expiryDate'] ?? '';
    _purchaseRateController.text = (product['purchaseRate'] ?? 0).toString();
    _saleRateController.text = (product['saleRate'] ?? 0).toString();
    
    // Load existing image if available
    if (product['imagePath'] != null && product['imagePath'].isNotEmpty) {
      _selectedImage = File(product['imagePath']);
    } else {
      _selectedImage = null;
    }

    _showProductDialog();
  }

  void _clearForm() {
    _productNameController.clear();
    _quantityController.clear();
    _companyController.clear();
    _manufacturingDateController.clear();
    _expiryDateController.clear();
    _purchaseRateController.clear();
    _saleRateController.clear();
    _selectedImage = null;
    _isEditing = false;
    _editingProductId = null;
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
        Navigator.pop(context);
      }
    } catch (e) {
      print('[ERROR] Failed to pick image from gallery: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
        Navigator.pop(context);
      }
    } catch (e) {
      print('[ERROR] Failed to pick image from camera: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error taking photo: ${e.toString()}')),
        );
      }
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFF1B4D3E)),
              title: const Text('Gallery'),
              onTap: _pickImageFromGallery,
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFF1B4D3E)),
              title: const Text('Camera'),
              onTap: _pickImageFromCamera,
            ),
          ],
        ),
      ),
    );
  }

  void _showProductDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _isEditing ? 'Edit Product' : 'Add New Product',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1B4D3E),
                        fontFamily: 'Literata',
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _clearForm();
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Product Image Picker
                _buildImagePickerWidget(),
                const SizedBox(height: 16),
                _buildInputField(
                  label: 'Product Name',
                  controller: _productNameController,
                  icon: Icons.shopping_bag_outlined,
                  isRequired: true,
                ),
                const SizedBox(height: 16),
                _buildInputField(
                  label: 'Quantity',
                  controller: _quantityController,
                  icon: Icons.inventory_2,
                  keyboardType: TextInputType.number,
                  isRequired: false,
                ),
                const SizedBox(height: 16),
                _buildInputField(
                  label: 'Company',
                  controller: _companyController,
                  icon: Icons.business,
                  isRequired: false,
                ),
                const SizedBox(height: 16),
                _buildDatePickerField(
                  label: 'Manufacturing Date',
                  controller: _manufacturingDateController,
                  icon: Icons.calendar_today,
                  isRequired: false,
                ),
                const SizedBox(height: 16),
                _buildDatePickerField(
                  label: 'Expiry Date',
                  controller: _expiryDateController,
                  icon: Icons.calendar_today,
                  isRequired: false,
                ),
                const SizedBox(height: 16),
                _buildInputField(
                  label: 'Purchase Rate',
                  controller: _purchaseRateController,
                  icon: Icons.trending_down,
                  keyboardType: TextInputType.number,
                  isRequired: false,
                ),
                const SizedBox(height: 16),
                _buildInputField(
                  label: 'Sale Rate',
                  controller: _saleRateController,
                  icon: Icons.trending_up,
                  keyboardType: TextInputType.number,
                  isRequired: false,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveProduct,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1B4D3E),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Text(
                                _isEditing ? 'Update' : 'Add Product',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        title: const Text(
          'Products',
          style: TextStyle(
            color: Color(0xFF1B4D3E),
            fontSize: 22,
            fontWeight: FontWeight.w700,
            fontFamily: 'Literata',
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1B4D3E)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildSearchBar(),
              const SizedBox(height: 16),
              Expanded(
                child: _filteredProducts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.shopping_bag_outlined,
                              size: 64,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No products found',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                                fontFamily: 'Literata',
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product = _filteredProducts[index];
                          return _buildProductCard(product);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _clearForm();
          _showProductDialog();
        },
        backgroundColor: const Color(0xFF1B4D3E),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: TextField(
        controller: _filterController,
        decoration: InputDecoration(
          hintText: 'Search products...',
          prefixIcon: const Icon(Icons.search, color: Color(0xFF1B4D3E)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[200]!, width: 1),
            ),
            child: (product['imagePath'] != null && product['imagePath'].isNotEmpty && File(product['imagePath']).existsSync())
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(product['imagePath']),
                      fit: BoxFit.cover,
                    ),
                  )
                : Icon(
                    Icons.shopping_bag_outlined,
                    size: 40,
                    color: Colors.grey[400],
                  ),
          ),
          const SizedBox(width: 12),
          // Product Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Name (Green)
                Text(
                  product['productName'] ?? 'N/A',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1B5E20),
                    fontFamily: 'Literata',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // Company (Grey)
                if (product['company'] != null && product['company'].isNotEmpty)
                  Text(
                    'Company: ${product['company']}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontFamily: 'Literata',
                    ),
                  ),
                const SizedBox(height: 8),
                // Price Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Quantity
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quantity',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                            fontFamily: 'Literata',
                          ),
                        ),
                        Text(
                          '${product['quantity'] ?? 0}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                            fontFamily: 'Literata',
                          ),
                        ),
                      ],
                    ),
                    // Sale Rate (Price)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sale Rate',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                            fontFamily: 'Literata',
                          ),
                        ),
                        Text(
                          '₹${product['saleRate'] ?? 0}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                            fontFamily: 'Literata',
                          ),
                        ),
                      ],
                    ),
                    // Purchase Rate
                    if (product['purchaseRate'] != null && product['purchaseRate'] > 0)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Purchase Rate',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                              fontFamily: 'Literata',
                            ),
                          ),
                          Text(
                            '₹${product['purchaseRate']}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                              fontFamily: 'Literata',
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
          // Menu Button
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                child: const Text('Edit'),
                onTap: () => Future.delayed(
                  const Duration(milliseconds: 100),
                  () => _editProduct(product),
                ),
              ),
              PopupMenuItem(
                child: const Text('Delete'),
                onTap: () => _deleteProduct(product['id']),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool isRequired = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFF1B4D3E)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        validator: isRequired
            ? (value) => (value == null || value.isEmpty) ? 'This field is required' : null
            : null,
      ),
    );
  }

  Widget _buildImagePickerWidget() {
    return GestureDetector(
      onTap: _showImagePickerOptions,
      child: Container(
        width: double.infinity,
        height: 160,
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey[300]!, width: 2, style: BorderStyle.solid),
        ),
        child: _selectedImage != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  _selectedImage!,
                  fit: BoxFit.cover,
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.camera_alt,
                    size: 40,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap to add product photo',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontFamily: 'Literata',
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildDatePickerField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool isRequired = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: TextFormField(
        controller: controller,
        readOnly: true,
        onTap: () => _selectDate(controller),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFF1B4D3E)),
          suffixIcon: const Icon(Icons.date_range, color: Color(0xFF1B4D3E)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        validator: isRequired
            ? (value) => (value == null || value.isEmpty) ? 'This field is required' : null
            : null,
      ),
    );
  }

  Future<void> _selectDate(TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      controller.text = '${picked.day.toString().padLeft(2, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.year}';
    }
  }

  @override
  void dispose() {
    _productNameController.dispose();
    _quantityController.dispose();
    _companyController.dispose();
    _manufacturingDateController.dispose();
    _expiryDateController.dispose();
    _purchaseRateController.dispose();
    _saleRateController.dispose();
    _filterController.dispose();
    super.dispose();
  }
}
