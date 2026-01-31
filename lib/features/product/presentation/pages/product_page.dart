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
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(125),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1B4D3E), Color(0xFF0F3B2F)],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 0),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'My Products',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Literata',
                                  height: 1.2,
                                ),
                              ),
                              Text(
                                'Manage your inventory',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 11,
                                  fontFamily: 'Literata',
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 16, right: 16, top: 8),
                    child: SizedBox(
                      height: 44,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
                        ),
                        child: Center(
                          child: TextField(
                            controller: _filterController,
                            textAlignVertical: TextAlignVertical.center,
                            style: const TextStyle(color: Colors.white, fontFamily: 'Literata', fontSize: 14, height: 1),
                            decoration: InputDecoration(
                              hintText: 'Search products...',
                              hintStyle: TextStyle(color: Colors.white.withOpacity(0.5), fontFamily: 'Literata', fontSize: 14),
                              prefixIcon: Icon(Icons.search_rounded, color: Colors.white.withOpacity(0.7), size: 20),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: const EdgeInsets.fromLTRB(0, 0, 12, 0),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: _filteredProducts.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B4D3E).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(Icons.shopping_bag_outlined, size: 50, color: const Color(0xFF1B4D3E).withOpacity(0.3)),
                  ),
                  const SizedBox(height: 20),
                  Text('No products yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey[700], fontFamily: 'Literata')),
                  const SizedBox(height: 8),
                  Text('Create your first product to get started', style: TextStyle(fontSize: 14, color: Colors.grey[500], fontFamily: 'Literata')),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredProducts.length,
              itemBuilder: (context, index) {
                final product = _filteredProducts[index];
                return _buildProductCard(product, index);
              },
            ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF1B4D3E), Color(0xFF0F3B2F)]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: const Color(0xFF1B4D3E).withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8))],
        ),
        child: FloatingActionButton(
          onPressed: () {
            _clearForm();
            _showProductDialog();
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product, int index) {
    final colors = [const Color(0xFF1B4D3E), const Color(0xFF0F3B2F), const Color(0xFF2C6F5E), const Color(0xFF1A5E52)];
    final accentColor = colors[index % colors.length];
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: accentColor.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 8), spreadRadius: 2), BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            Container(
              height: 140,
              decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [accentColor, accentColor.withOpacity(0.7)])),
              child: Stack(
                children: [
                  Positioned(right: -30, top: -30, child: Container(width: 120, height: 120, decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle))),
                  Positioned(
                    left: 16,
                    top: 10,
                    bottom: 10,
                    child: Container(
                      width: 110,
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.3), width: 2)),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: (product['imageUrl'] != null && product['imageUrl'].isNotEmpty)
                            ? Image.network(product['imageUrl'], fit: BoxFit.cover, loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withOpacity(0.7)), strokeWidth: 2));
                              }, errorBuilder: (context, error, stackTrace) => Container(color: Colors.white.withOpacity(0.2), child: Icon(Icons.image_not_supported_outlined, color: Colors.white.withOpacity(0.6), size: 40)))
                            : Container(color: Colors.white.withOpacity(0.2), child: Icon(Icons.shopping_bag_outlined, color: Colors.white.withOpacity(0.6), size: 48)),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))]),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.inventory_2, size: 14, color: accentColor), const SizedBox(width: 4), Text('${product['quantity'] ?? 0}', style: TextStyle(color: accentColor, fontSize: 13, fontWeight: FontWeight.w700, fontFamily: 'Literata'))]),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Transform.translate(
                      offset: const Offset(50, 0),
                      child: PopupMenuButton(color: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 8, itemBuilder: (context) => [
                        PopupMenuItem(child: Row(children: [Icon(Icons.edit_outlined, color: accentColor, size: 18), const SizedBox(width: 8), const Text('Edit')]), onTap: () => Future.delayed(const Duration(milliseconds: 100), () => _editProduct(product))),
                        PopupMenuItem(child: Row(children: [const Icon(Icons.delete_outline, color: Colors.red, size: 18), const SizedBox(width: 8), const Text('Delete', style: TextStyle(color: Colors.red))]), onTap: () => _deleteProduct(product['id'])),
                      ], icon: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.more_vert, color: Colors.white, size: 18))),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product['productName'] ?? 'Unknown Product', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1B4D3E), fontFamily: 'Literata'), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  if (product['company'] != null && product['company'].isNotEmpty) Row(children: [Icon(Icons.business, size: 14, color: Colors.grey[500]), const SizedBox(width: 6), Expanded(child: Text(product['company'], style: TextStyle(fontSize: 13, color: Colors.grey[600], fontFamily: 'Literata'), maxLines: 1, overflow: TextOverflow.ellipsis))]),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Sale Rate', style: TextStyle(fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.w500, fontFamily: 'Literata')), const SizedBox(height: 4), Text('₹${product['saleRate'] ?? 0}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: accentColor, fontFamily: 'Literata'))]),
                      if (product['expiryDate'] != null && product['expiryDate'].isNotEmpty) Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(8)), child: Column(children: [Text('Exp', style: TextStyle(fontSize: 10, color: Colors.orange[700], fontWeight: FontWeight.w600, fontFamily: 'Literata')), Text(product['expiryDate'], style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.orange[900], fontFamily: 'Literata'))])),
                      if (product['manufacturingDate'] != null && product['manufacturingDate'].isNotEmpty) Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(8)), child: Column(children: [Text('MFG', style: TextStyle(fontSize: 10, color: Colors.green[700], fontWeight: FontWeight.w600, fontFamily: 'Literata')), Text(product['manufacturingDate'], style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.green[900], fontFamily: 'Literata'))]))
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
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
