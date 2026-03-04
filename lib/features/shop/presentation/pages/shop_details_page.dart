import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:signature/signature.dart';
import 'dart:io';
import 'dart:convert';
import '../../../../core/services/session_manager.dart';
import '../../../../core/services/language_service.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../offline/controllers/shop_image_cache_controller.dart';
import '../../data/repositories/shop_repository.dart';

class ShopDetailsPage extends StatefulWidget {
  const ShopDetailsPage({super.key});

  @override
  State<ShopDetailsPage> createState() => _ShopDetailsPageState();
}

class _ShopDetailsPageState extends State<ShopDetailsPage> {
  final _shopNameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _gstController = TextEditingController();

  // Bank Details Controllers
  final _bankNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _ifscCodeController = TextEditingController();
  final _accountHolderNameController = TextEditingController();

  // Terms and Conditions Controller
  final _termsConditionsController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isEditing = false;

  // QR Code state - now stores base64 image data
  String? _qrCodeBase64;
  File? _pickedQrImage;
  bool _isUploadingQr = false;

  // Shop Logo state
  String? _shopLogoBase64;
  File? _pickedLogoImage;
  bool _isUploadingLogo = false;

  // Signature state
  String? _signatureBase64;
  File? _pickedSignatureImage;
  bool _isUploadingSignature = false;

  final _imagePicker = ImagePicker();

  final _auth = FirebaseAuth.instance;
  late final FirebaseFirestore _firestore;
  late SessionManager _sessionManager;
  late AppLocalizations _localizations;

  @override
  void initState() {
    super.initState();
    _firestore = FirebaseFirestore.instance;
    _sessionManager = SessionManager();
    _localizations = AppLocalizations(LanguageService.instance.currentLanguage);
    _loadShopDetails();
  }

  Future<void> _loadShopDetails() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Step 1: Load images from local cache FIRST (instant display)
      await _loadImagesFromCache(currentUser.uid);

      // Step 2: Fetch from Firebase and sync to cache (background)
      final doc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('shop_details')
          .doc('main')
          .get();

      if (doc.exists) {
        final firebaseLogo = doc['shopLogoBase64'] as String?;
        final firebaseSignature = doc['signatureBase64'] as String?;
        final firebaseQrCode = doc['qrCodeBase64'] as String?;

        setState(() {
          _shopNameController.text = doc['shopName'] ?? '';
          _ownerNameController.text = doc['ownerName'] ?? '';
          _addressController.text = doc['address'] ?? '';
          _pincodeController.text = doc['pincode'] ?? '';
          _phoneController.text = doc['phone'] ?? '';
          _emailController.text = doc['email'] ?? '';
          _gstController.text = doc['gst'] ?? '';
          // Bank Details
          _bankNameController.text = doc['bankName'] ?? '';
          _accountNumberController.text = doc['accountNumber'] ?? '';
          _ifscCodeController.text = doc['ifscCode'] ?? '';
          _accountHolderNameController.text = doc['accountHolderName'] ?? '';
          // Terms and Conditions
          _termsConditionsController.text = doc['termsAndConditions'] ?? '';
          // Only update images if Firebase has data and differs from cache
          if (firebaseLogo != null && firebaseLogo.isNotEmpty) {
            _shopLogoBase64 = firebaseLogo;
          }
          if (firebaseSignature != null && firebaseSignature.isNotEmpty) {
            _signatureBase64 = firebaseSignature;
          }
          if (firebaseQrCode != null && firebaseQrCode.isNotEmpty) {
            _qrCodeBase64 = firebaseQrCode;
          }
          _isEditing = true;
        });

        // Sync Firebase images to local cache for future fast loading
        await ShopImageCacheController.instance.syncFromFirebase(
          userId: currentUser.uid,
          shopLogoBase64: firebaseLogo,
          signatureBase64: firebaseSignature,
          qrCodeBase64: firebaseQrCode,
        );
      }
    } catch (e) {
      print('[ERROR] Failed to load shop details: $e');
    }
  }

  /// Load images from local Isar cache for instant display
  Future<void> _loadImagesFromCache(String userId) async {
    try {
      final cachedImages = await ShopImageCacheController.instance
          .getCachedImages(userId);
      if (cachedImages != null && cachedImages.hasAnyImages) {
        setState(() {
          if (cachedImages.shopLogoBase64 != null &&
              cachedImages.shopLogoBase64!.isNotEmpty) {
            _shopLogoBase64 = cachedImages.shopLogoBase64;
          }
          if (cachedImages.signatureBase64 != null &&
              cachedImages.signatureBase64!.isNotEmpty) {
            _signatureBase64 = cachedImages.signatureBase64;
          }
          if (cachedImages.qrCodeBase64 != null &&
              cachedImages.qrCodeBase64!.isNotEmpty) {
            _qrCodeBase64 = cachedImages.qrCodeBase64;
          }
        });
        print('[CACHE] Loaded shop images from local cache instantly');
      }
    } catch (e) {
      print('[CACHE] Failed to load from cache: $e');
      // Continue without cache - Firebase will be used
    }
  }

  Future<void> _saveShopDetails() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final shopDetailsRef = _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('shop_details');

      await shopDetailsRef.doc('main').set({
        'shopName': _shopNameController.text,
        'ownerName': _ownerNameController.text,
        'address': _addressController.text,
        'pincode': _pincodeController.text,
        'phone': _phoneController.text,
        'email': _emailController.text,
        'gst': _gstController.text,
        // Bank Details
        'bankName': _bankNameController.text,
        'accountNumber': _accountNumberController.text,
        'ifscCode': _ifscCodeController.text,
        'accountHolderName': _accountHolderNameController.text,
        // Terms and Conditions
        'termsAndConditions': _termsConditionsController.text,
        'qrCodeBase64': _qrCodeBase64,
        'shopLogoBase64': _shopLogoBase64,
        'signatureBase64': _signatureBase64,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_localizations.shopDetailsSaved),
            backgroundColor: const Color(0xFF4CAF50),
          ),
        );
      }
    } catch (e) {
      print('[ERROR] Failed to save shop details: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAndUploadQrCode() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 600,
        maxHeight: 600,
      );

      if (pickedFile == null) return;

      setState(() {
        _pickedQrImage = File(pickedFile.path);
        _isUploadingQr = true;
      });

      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Convert image to base64
      final bytes = await _pickedQrImage!.readAsBytes();
      final base64Image = base64Encode(bytes);

      // Save base64 to Firestore
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('shop_details')
          .doc('main')
          .set({'qrCodeBase64': base64Image}, SetOptions(merge: true));

      // Update local cache for instant loading next time
      await ShopImageCacheController.instance.updateQrCode(
        currentUser.uid,
        base64Image,
      );

      // Clear shop repository cache so next bill print gets fresh data
      ShopRepository().clearCache();

      setState(() {
        _qrCodeBase64 = base64Image;
        _isUploadingQr = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_localizations.qrCodeUploaded),
            backgroundColor: const Color(0xFF4CAF50),
          ),
        );
      }
    } catch (e) {
      print('[ERROR] Failed to save QR code: $e');
      setState(() => _isUploadingQr = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${_localizations.errorUploadingQrCode}: ${e.toString()}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _removeQrCode() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      setState(() => _isUploadingQr = true);

      // Remove base64 from Firestore
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('shop_details')
          .doc('main')
          .update({'qrCodeBase64': FieldValue.delete()});

      // Clear from local cache
      await ShopImageCacheController.instance.removeQrCode(currentUser.uid);

      // Clear shop repository cache so next bill print gets fresh data
      ShopRepository().clearCache();

      setState(() {
        _qrCodeBase64 = null;
        _pickedQrImage = null;
        _isUploadingQr = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_localizations.qrCodeRemoved),
            backgroundColor: const Color(0xFF4CAF50),
          ),
        );
      }
    } catch (e) {
      print('[ERROR] Failed to remove QR code: $e');
      setState(() => _isUploadingQr = false);
    }
  }

  // ═══════════════════════════════════════════════════
  // Shop Logo Methods
  // ═══════════════════════════════════════════════════

  Future<void> _pickAndUploadLogo() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 400,
        maxHeight: 400,
      );

      if (pickedFile == null) return;

      setState(() {
        _pickedLogoImage = File(pickedFile.path);
        _isUploadingLogo = true;
      });

      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Convert image to base64
      final bytes = await _pickedLogoImage!.readAsBytes();
      final base64Image = base64Encode(bytes);

      // Save base64 to Firestore
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('shop_details')
          .doc('main')
          .set({'shopLogoBase64': base64Image}, SetOptions(merge: true));

      // Update local cache for instant loading next time
      await ShopImageCacheController.instance.updateLogo(
        currentUser.uid,
        base64Image,
      );

      // Clear shop repository cache so next bill print gets fresh data
      ShopRepository().clearCache();

      setState(() {
        _shopLogoBase64 = base64Image;
        _isUploadingLogo = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_localizations.logoUploaded),
            backgroundColor: const Color(0xFF4CAF50),
          ),
        );
      }
    } catch (e) {
      print('[ERROR] Failed to save logo: $e');
      setState(() => _isUploadingLogo = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${_localizations.errorUploadingLogo}: ${e.toString()}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _removeLogo() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      setState(() => _isUploadingLogo = true);

      // Remove base64 from Firestore
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('shop_details')
          .doc('main')
          .update({'shopLogoBase64': FieldValue.delete()});

      // Clear from local cache
      await ShopImageCacheController.instance.removeLogo(currentUser.uid);

      // Clear shop repository cache so next bill print gets fresh data
      ShopRepository().clearCache();

      setState(() {
        _shopLogoBase64 = null;
        _pickedLogoImage = null;
        _isUploadingLogo = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_localizations.logoRemoved),
            backgroundColor: const Color(0xFF4CAF50),
          ),
        );
      }
    } catch (e) {
      print('[ERROR] Failed to remove logo: $e');
      setState(() => _isUploadingLogo = false);
    }
  }

  // ═══════════════════════════════════════════════════
  // Signature Methods
  // ═══════════════════════════════════════════════════

  Future<void> _showSignaturePad() async {
    final SignatureController signatureController = SignatureController(
      penStrokeWidth: 3,
      penColor: Colors.black,
      exportBackgroundColor: Colors.white,
    );

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.draw, color: const Color(0xFF1B4D3E)),
              const SizedBox(width: 8),
              Text(_localizations.signature),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 300,
                height: 150,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[400]!),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(7),
                  child: Signature(
                    controller: signatureController,
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () => signatureController.clear(),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Clear'),
                style: TextButton.styleFrom(foregroundColor: Colors.grey[600]),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                signatureController.dispose();
                Navigator.of(context).pop(false);
              },
              child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
            ),
            ElevatedButton(
              onPressed: () async {
                if (signatureController.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please draw your signature'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }
                Navigator.of(context).pop(true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B4D3E),
                foregroundColor: Colors.white,
              ),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (result == true && !signatureController.isEmpty) {
      await _saveSignature(signatureController);
    }
    signatureController.dispose();
  }

  Future<void> _saveSignature(SignatureController controller) async {
    try {
      setState(() => _isUploadingSignature = true);

      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Export signature to PNG bytes
      final bytes = await controller.toPngBytes();

      if (bytes == null) {
        throw Exception('Failed to export signature');
      }

      final base64Image = base64Encode(bytes);

      // Save base64 to Firestore
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('shop_details')
          .doc('main')
          .set({'signatureBase64': base64Image}, SetOptions(merge: true));

      // Update local cache for instant loading next time
      await ShopImageCacheController.instance.updateSignature(
        currentUser.uid,
        base64Image,
      );

      // Clear shop repository cache so next bill print gets fresh data
      ShopRepository().clearCache();

      setState(() {
        _signatureBase64 = base64Image;
        _isUploadingSignature = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_localizations.signatureUploaded),
            backgroundColor: const Color(0xFF4CAF50),
          ),
        );
      }
    } catch (e) {
      print('[ERROR] Failed to save signature: $e');
      setState(() => _isUploadingSignature = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${_localizations.errorUploadingSignature}: ${e.toString()}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _removeSignature() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      setState(() => _isUploadingSignature = true);

      // Remove base64 from Firestore
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('shop_details')
          .doc('main')
          .update({'signatureBase64': FieldValue.delete()});

      // Clear from local cache
      await ShopImageCacheController.instance.removeSignature(currentUser.uid);

      // Clear shop repository cache so next bill print gets fresh data
      ShopRepository().clearCache();

      setState(() {
        _signatureBase64 = null;
        _pickedSignatureImage = null;
        _isUploadingSignature = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_localizations.signatureRemoved),
            backgroundColor: const Color(0xFF4CAF50),
          ),
        );
      }
    } catch (e) {
      print('[ERROR] Failed to remove signature: $e');
      setState(() => _isUploadingSignature = false);
    }
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool isRequired = false,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1B4D3E),
                fontFamily: 'Literata',
              ),
            ),
            if (isRequired)
              const Text(' *', style: TextStyle(color: Colors.red)),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          minLines: maxLines,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.grey[600]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF1B4D3E), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          validator: (value) {
            if (isRequired && (value == null || value.isEmpty)) {
              return '$label is required';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildQrCodeSection() {
    if (_isUploadingQr) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Color(0xFF1B4D3E)),
              const SizedBox(height: 12),
              Text(
                _localizations.uploadingQrCode,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    if (_qrCodeBase64 != null && _qrCodeBase64!.isNotEmpty) {
      return Column(
        children: [
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: Image.memory(
                base64Decode(_qrCodeBase64!),
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.red[400],
                          size: 40,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Failed to load QR code',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickAndUploadQrCode,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Change'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1B4D3E),
                    side: const BorderSide(color: Color(0xFF1B4D3E)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _removeQrCode,
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: Text(_localizations.removeQrCode),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    }

    // No QR code - show upload button
    return InkWell(
      onTap: _pickAndUploadQrCode,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey[300]!,
            style: BorderStyle.solid,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.qr_code_2_outlined, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 12),
              Text(
                _localizations.uploadQrCode,
                style: TextStyle(
                  color: const Color(0xFF1B4D3E),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Tap to select image',
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoSection() {
    if (_isUploadingLogo) {
      return Container(
        height: 150,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Color(0xFF1B4D3E)),
              const SizedBox(height: 12),
              Text(
                _localizations.uploadingLogo,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    if (_shopLogoBase64 != null && _shopLogoBase64!.isNotEmpty) {
      return Column(
        children: [
          Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: Image.memory(
                base64Decode(_shopLogoBase64!),
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.red[400],
                          size: 40,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Failed to load logo',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickAndUploadLogo,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Change'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1B4D3E),
                    side: const BorderSide(color: Color(0xFF1B4D3E)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _removeLogo,
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: Text(_localizations.removeQrCode),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    }

    // No logo - show upload button
    return InkWell(
      onTap: _pickAndUploadLogo,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image_outlined, size: 40, color: Colors.grey[400]),
              const SizedBox(height: 8),
              Text(
                _localizations.uploadLogo,
                style: TextStyle(
                  color: const Color(0xFF1B4D3E),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Tap to select image',
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSignatureSection() {
    if (_isUploadingSignature) {
      return Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Color(0xFF1B4D3E)),
              const SizedBox(height: 12),
              Text(
                _localizations.uploadingSignature,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    if (_signatureBase64 != null && _signatureBase64!.isNotEmpty) {
      return Column(
        children: [
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: Image.memory(
                base64Decode(_signatureBase64!),
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.red[400],
                          size: 40,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Failed to load signature',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _showSignaturePad,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Change'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1B4D3E),
                    side: const BorderSide(color: Color(0xFF1B4D3E)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _removeSignature,
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: Text(_localizations.removeQrCode),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    }

    // No signature - show draw signature button
    return InkWell(
      onTap: _showSignaturePad,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.draw_outlined, size: 36, color: Colors.grey[400]),
              const SizedBox(height: 8),
              Text(
                _localizations.uploadSignature,
                style: TextStyle(
                  color: const Color(0xFF1B4D3E),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _shopNameController.dispose();
    _ownerNameController.dispose();
    _addressController.dispose();
    _pincodeController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _gstController.dispose();
    // Bank Details
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _ifscCodeController.dispose();
    _accountHolderNameController.dispose();
    // Terms and Conditions
    _termsConditionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1B4D3E)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _localizations.shopDetails,
          style: TextStyle(
            color: Color(0xFF1B4D3E),
            fontSize: 22,
            fontWeight: FontWeight.w700,
            fontFamily: 'Literata',
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Shop Information Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _localizations.shopInformation,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInputField(
                      label: _localizations.shopName,
                      controller: _shopNameController,
                      icon: Icons.storefront_outlined,
                      isRequired: true,
                    ),
                    const SizedBox(height: 16),
                    _buildInputField(
                      label: _localizations.ownerName,
                      controller: _ownerNameController,
                      icon: Icons.person_outline,
                      isRequired: true,
                    ),
                    const SizedBox(height: 16),
                    _buildInputField(
                      label: _localizations.email,
                      controller: _emailController,
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Contact Information Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _localizations.contactInformation,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInputField(
                      label: _localizations.phoneNumber,
                      controller: _phoneController,
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      isRequired: true,
                    ),
                    const SizedBox(height: 16),
                    _buildInputField(
                      label: _localizations.address,
                      controller: _addressController,
                      icon: Icons.location_on_outlined,
                      maxLines: 3,
                      isRequired: true,
                    ),
                    const SizedBox(height: 16),
                    _buildInputField(
                      label: _localizations.pincode,
                      controller: _pincodeController,
                      icon: Icons.pin_outlined,
                      keyboardType: TextInputType.number,
                      isRequired: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Business Information Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _localizations.businessInformation,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInputField(
                      label: _localizations.gstNumber,
                      controller: _gstController,
                      icon: Icons.receipt_outlined,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Bank Details Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _localizations.bankDetails,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInputField(
                      label: _localizations.bankName,
                      controller: _bankNameController,
                      icon: Icons.account_balance_outlined,
                    ),
                    const SizedBox(height: 16),
                    _buildInputField(
                      label: _localizations.accountNumber,
                      controller: _accountNumberController,
                      icon: Icons.credit_card_outlined,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    _buildInputField(
                      label: _localizations.ifscCode,
                      controller: _ifscCodeController,
                      icon: Icons.code_outlined,
                    ),
                    const SizedBox(height: 16),
                    _buildInputField(
                      label: _localizations.accountHolderName,
                      controller: _accountHolderNameController,
                      icon: Icons.person_outline,
                    ),
                    const SizedBox(height: 20),
                    // QR Code Section
                    Text(
                      _localizations.paymentQrCode,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1B4D3E),
                        fontFamily: 'Literata',
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildQrCodeSection(),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Shop Logo & Signature Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Shop Logo
                    Text(
                      _localizations.shopLogo,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1B4D3E),
                        fontFamily: 'Literata',
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildLogoSection(),
                    const SizedBox(height: 24),
                    // Signature
                    Text(
                      _localizations.signature,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1B4D3E),
                        fontFamily: 'Literata',
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildSignatureSection(),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Terms and Conditions Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Terms & Conditions',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1B4D3E),
                        fontFamily: 'Literata',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _termsConditionsController,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText: 'Enter terms and conditions for invoices...',
                        hintStyle: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 13,
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFF1B4D3E),
                          ),
                        ),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveShopDetails,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B4D3E),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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
                          _localizations.saveShopDetails,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
