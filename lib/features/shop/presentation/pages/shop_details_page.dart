import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:signature/signature.dart';

import 'package:c_billing/common_widgets/app_top_bar.dart';
import 'package:c_billing/core/theme/app_theme.dart';
import 'package:c_billing/core/ui/desktop_canvas.dart';
import 'package:c_billing/core/ui/glassy_toast.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/services/language_service.dart';
import '../../data/repositories/shop_repository.dart';
import '../../data/shop_image_codec.dart';
import '../../offline/controllers/shop_image_cache_controller.dart';

class ShopDetailsPage extends StatefulWidget {
  final bool isEmbedded;

  const ShopDetailsPage({super.key, this.isEmbedded = false});

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
  final _upiIdController = TextEditingController();

  // Terms and Conditions Controller
  final _termsConditionsController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isLoadingDetails = true;
  // QR Code state - now stores base64 image data
  String? _qrCodeBase64;
  bool _isUploadingQr = false;

  // Shop Logo state
  String? _shopLogoBase64;
  bool _isUploadingLogo = false;

  // Signature state
  String? _signatureBase64;
  bool _isUploadingSignature = false;

  final _imagePicker = ImagePicker();

  final _auth = FirebaseAuth.instance;
  late final FirebaseFirestore _firestore;
  late AppLocalizations _localizations;

  @override
  void initState() {
    super.initState();
    _firestore = FirebaseFirestore.instance;
    _localizations = AppLocalizations(LanguageService.instance.currentLanguage);
    _loadShopDetails();
  }

  Future<void> _loadShopDetails() async {
    if (mounted) setState(() => _isLoadingDetails = true);
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Step 1: Load images from local cache FIRST (instant display).
      // Failures here must not block Firestore text/bank fields.
      await _loadImagesFromCache(currentUser.uid);

      // Step 2: Fetch from Firebase
      final doc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('shop_details')
          .doc('main')
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final firebaseLogo = _imageField(data, 'shopLogoBase64');
        final firebaseSignature = _imageField(data, 'signatureBase64');
        final firebaseQrCode = _imageField(data, 'qrCodeBase64');

        if (!mounted) return;
        setState(() {
          _shopNameController.text = _stringField(data, 'shopName');
          _ownerNameController.text = _stringField(data, 'ownerName');
          _addressController.text = _stringField(data, 'address');
          _pincodeController.text = _stringField(data, 'pincode');
          _phoneController.text = _stringField(data, 'phone');
          _emailController.text = _stringField(data, 'email');
          _gstController.text = _stringField(data, 'gst');
          _bankNameController.text = _stringField(data, 'bankName');
          _accountNumberController.text = _stringField(data, 'accountNumber');
          _ifscCodeController.text = _stringField(data, 'ifscCode');
          _accountHolderNameController.text =
              _stringField(data, 'accountHolderName');
          _upiIdController.text = _stringField(data, 'upiId');
          _termsConditionsController.text =
              _stringField(data, 'termsAndConditions');
          if (firebaseLogo.isNotEmpty) _shopLogoBase64 = firebaseLogo;
          if (firebaseSignature.isNotEmpty) {
            _signatureBase64 = firebaseSignature;
          }
          if (firebaseQrCode.isNotEmpty) _qrCodeBase64 = firebaseQrCode;
        });

        // Local image cache sync is best-effort (web Drift can fail).
        try {
          await ShopImageCacheController.instance.syncFromFirebase(
            userId: currentUser.uid,
            shopLogoBase64: firebaseLogo.isEmpty ? null : firebaseLogo,
            signatureBase64:
                firebaseSignature.isEmpty ? null : firebaseSignature,
            qrCodeBase64: firebaseQrCode.isEmpty ? null : firebaseQrCode,
          );
        } catch (cacheError) {
          debugPrint(
            '[CACHE] syncFromFirebase after shop load failed: $cacheError',
          );
        }
      }
    } catch (e) {
      debugPrint('[ERROR] Failed to load shop details: $e');
      if (mounted) {
        final message = e is FirebaseException
            ? (e.message ?? e.code)
            : e.toString();
        GlassyToast.show(
          context,
          'Failed to load shop details: $message',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingDetails = false);
    }
  }

  String _stringField(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value == null) return '';
    return value.toString();
  }

  /// Normalized base64 suitable for [Image.memory] / Firestore round-trips.
  String _imageField(Map<String, dynamic> data, String key) {
    final raw = _stringField(data, key);
    if (raw.isEmpty) return '';
    final normalized = ShopImageCodec.normalizeBase64(raw);
    // Drop corrupt payloads so the UI shows upload placeholder, not a crash.
    return ShopImageCodec.tryDecodeBase64(normalized) == null
        ? ''
        : normalized;
  }

  Uint8List? _decodeShopImage(String? base64) =>
      ShopImageCodec.tryDecodeBase64(base64);

  // Load images from local cache for instant display
  Future<void> _loadImagesFromCache(String userId) async {
    try {
      final cachedImages = await ShopImageCacheController.instance
          .getCachedImages(userId);
      if (cachedImages != null && cachedImages.hasAnyImages) {
        String? take(String? raw) {
          if (raw == null || raw.trim().isEmpty) return null;
          final normalized = ShopImageCodec.normalizeBase64(raw);
          return ShopImageCodec.tryDecodeBase64(normalized) == null
              ? null
              : normalized;
        }

        setState(() {
          final logo = take(cachedImages.shopLogoBase64);
          final signature = take(cachedImages.signatureBase64);
          final qr = take(cachedImages.qrCodeBase64);
          if (logo != null) _shopLogoBase64 = logo;
          if (signature != null) _signatureBase64 = signature;
          if (qr != null) _qrCodeBase64 = qr;
        });
        debugPrint('[CACHE] Loaded shop images from local cache instantly');
      }
    } catch (e) {
      debugPrint('[CACHE] Failed to load from cache: $e');
      // Continue without cache - Firebase will be used
    }
  }

  Future<void> _saveShopDetails() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    if (mounted) setState(() => _isLoading = true);

    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Text/bank fields only — logo/QR/signature are saved by their own
      // upload flows. Re-writing those huge base64 blobs here exceeds
      // Firestore's 1MB document limit and was crashing Save.
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('shop_details')
          .doc('main')
          .set({
            'shopName': _shopNameController.text.trim(),
            'ownerName': _ownerNameController.text.trim(),
            'address': _addressController.text.trim(),
            'pincode': _pincodeController.text.trim(),
            'phone': _phoneController.text.trim(),
            'email': _emailController.text.trim(),
            'gst': _gstController.text.trim(),
            'bankName': _bankNameController.text.trim(),
            'accountNumber': _accountNumberController.text.trim(),
            'ifscCode': _ifscCodeController.text.trim().toUpperCase(),
            'accountHolderName': _accountHolderNameController.text.trim(),
            'upiId': _upiIdController.text.trim(),
            'termsAndConditions': _termsConditionsController.text.trim(),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      // Keep local image cache in sync so bills can render QR/logo even when
      // Firestore omitted large image fields.
      await ShopImageCacheController.instance.syncFromFirebase(
        userId: currentUser.uid,
        shopLogoBase64: _shopLogoBase64,
        signatureBase64: _signatureBase64,
        qrCodeBase64: _qrCodeBase64,
      );

      ShopRepository.clearSharedCache();

      if (mounted) {
        GlassyToast.show(context, _localizations.shopDetailsSaved);
      }
    } catch (e, st) {
      debugPrint('[ERROR] Failed to save shop details: $e\n$st');
      if (mounted) {
        final message = e is FirebaseException
            ? (e.message ?? e.code)
            : e.toString();
        GlassyToast.show(context, 'Error: $message', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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

      setState(() => _isUploadingQr = true);

      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final bytes = await pickedFile.readAsBytes();
      // Hard-compress so logo+QR+signature fit in one Firestore doc.
      final base64Image = await ShopImageCodec.compressToBase64(
        bytes,
        maxSide: 320,
        quality: 55,
      );

      // Show on screen immediately — don't wait on cache / cloud.
      if (!mounted) return;
      setState(() {
        _qrCodeBase64 = base64Image;
      });

      try {
        await ShopImageCacheController.instance.updateQrCode(
          currentUser.uid,
          base64Image,
        );
      } catch (e) {
        debugPrint('[WARN] QR local cache failed: $e');
      }

      var cloudSaved = true;
      try {
        await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .collection('shop_details')
            .doc('main')
            .set({'qrCodeBase64': base64Image}, SetOptions(merge: true));
      } catch (e) {
        cloudSaved = false;
        debugPrint('[WARN] QR saved locally only (Firestore failed): $e');
      }

      ShopRepository.clearSharedCache();

      if (!mounted) return;
      setState(() => _isUploadingQr = false);

      GlassyToast.show(
        context,
        cloudSaved
            ? _localizations.qrCodeUploaded
            : 'QR saved for bills (cloud sync pending — document may be full)',
      );
    } catch (e) {
      debugPrint('[ERROR] Failed to save QR code: $e');
      if (mounted) {
        setState(() => _isUploadingQr = false);
        GlassyToast.show(
          context,
          '${_localizations.errorUploadingQrCode}: ${e.toString()}',
          isError: true,
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
      ShopRepository.clearSharedCache();

      setState(() {
        _qrCodeBase64 = null;
        _isUploadingQr = false;
      });

      if (mounted) {
        GlassyToast.show(context, _localizations.qrCodeRemoved);
      }
    } catch (e) {
      debugPrint('[ERROR] Failed to remove QR code: $e');
      setState(() => _isUploadingQr = false);
    }
  }

  // ═══════════════════════════════════════════════════ Shop Logo Methods ═══════════════════════════════════════════════════

  Future<void> _pickAndUploadLogo() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 600,
        maxHeight: 600,
      );

      if (pickedFile == null) return;

      setState(() => _isUploadingLogo = true);

      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final bytes = await pickedFile.readAsBytes();
      final base64Image = await ShopImageCodec.compressToBase64(
        bytes,
        maxSide: 280,
        quality: 55,
      );

      // Show on screen immediately — don't wait on cache / cloud.
      if (!mounted) return;
      setState(() {
        _shopLogoBase64 = base64Image;
      });

      try {
        await ShopImageCacheController.instance.updateLogo(
          currentUser.uid,
          base64Image,
        );
      } catch (e) {
        debugPrint('[WARN] Logo local cache failed: $e');
      }

      var cloudSaved = true;
      try {
        await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .collection('shop_details')
            .doc('main')
            .set({'shopLogoBase64': base64Image}, SetOptions(merge: true));
      } catch (e) {
        cloudSaved = false;
        debugPrint('[WARN] Logo saved locally only (Firestore failed): $e');
      }

      ShopRepository.clearSharedCache();

      if (!mounted) return;
      setState(() => _isUploadingLogo = false);

      GlassyToast.show(
        context,
        cloudSaved
            ? _localizations.logoUploaded
            : 'Logo saved for bills (cloud sync pending)',
      );
    } catch (e) {
      debugPrint('[ERROR] Failed to save logo: $e');
      if (mounted) {
        setState(() => _isUploadingLogo = false);
        GlassyToast.show(
          context,
          '${_localizations.errorUploadingLogo}: ${e.toString()}',
          isError: true,
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
      ShopRepository.clearSharedCache();

      setState(() {
        _shopLogoBase64 = null;
        _isUploadingLogo = false;
      });

      if (mounted) {
        GlassyToast.show(context, _localizations.logoRemoved);
      }
    } catch (e) {
      debugPrint('[ERROR] Failed to remove logo: $e');
      setState(() => _isUploadingLogo = false);
    }
  }

  // ═══════════════════════════════════════════════════ Signature Methods ═══════════════════════════════════════════════════

  Future<void> _showSignaturePad() async {
    final SignatureController signatureController = SignatureController(
      penStrokeWidth: 3,
      penColor: AppTheme.black,
      exportBackgroundColor: AppTheme.white,
    );

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.draw, color: AppColors.accent(context)),
              SizedBox(width: 8),
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
                  border: Border.all(color: AppTheme.grey400),
                  borderRadius: BorderRadius.circular(8),
                  color: AppColors.card(context),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(7),
                  child: Signature(
                    controller: signatureController,
                    backgroundColor: AppColors.card(context),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () => signatureController.clear(),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Clear'),
                style: TextButton.styleFrom(foregroundColor: AppTheme.grey600),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                signatureController.dispose();
                Navigator.of(context).pop(false);
              },
              child: Text('Cancel', style: TextStyle(color: AppTheme.grey600)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (signatureController.isEmpty) {
                  GlassyToast.show(context, 'Please draw your signature');
                  return;
                }
                Navigator.of(context).pop(true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.action(context),
                foregroundColor: AppTheme.white,
              ),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (result == true && signatureController.isNotEmpty) {
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

      await ShopImageCacheController.instance.updateSignature(
        currentUser.uid,
        base64Image,
      );

      try {
        await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .collection('shop_details')
            .doc('main')
            .set({'signatureBase64': base64Image}, SetOptions(merge: true));
      } catch (e) {
        debugPrint('[WARN] Signature saved locally only: $e');
      }

      ShopRepository.clearSharedCache();

      if (!mounted) return;
      setState(() {
        _signatureBase64 = base64Image;
        _isUploadingSignature = false;
      });

      GlassyToast.show(context, _localizations.signatureUploaded);
    } catch (e) {
      debugPrint('[ERROR] Failed to save signature: $e');
      if (mounted) {
        setState(() => _isUploadingSignature = false);
        GlassyToast.show(
          context,
          '${_localizations.errorUploadingSignature}: ${e.toString()}',
          isError: true,
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
      ShopRepository.clearSharedCache();

      setState(() {
        _signatureBase64 = null;
        _isUploadingSignature = false;
      });

      if (mounted) {
        GlassyToast.show(context, _localizations.signatureRemoved);
      }
    } catch (e) {
      debugPrint('[ERROR] Failed to remove signature: $e');
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
    String? hint,
  }) {
    final border = AppColors.border(context);
    final action = AppColors.action(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.secondaryText(context),
                fontFamily: 'Literata',
              ),
            ),
            if (isRequired)
              const Text(' *', style: TextStyle(color: AppTheme.red)),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          minLines: maxLines > 1 ? maxLines : 1,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.primaryText(context),
            fontFamily: 'Literata',
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontFamily: 'Literata',
              fontSize: 13,
              color: AppColors.mutedText(context),
            ),
            prefixIcon: Icon(icon, color: action.withValues(alpha: 0.75)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: action, width: 1.6),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppTheme.red),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
            filled: true,
            fillColor: AppColors.inputFill(context),
          ),
          validator: (value) {
            if (isRequired && (value == null || value.trim().isEmpty)) {
              return '$label is required';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border(context)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.black.withValues(
              alpha: AppColors.isDark(context) ? 0.28 : 0.04,
            ),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  iconColor.withValues(alpha: 0.12),
                  iconColor.withValues(alpha: 0.03),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [iconColor, iconColor.withValues(alpha: 0.82)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: AppTheme.white, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Literata',
                          color: AppColors.primaryText(context),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'Literata',
                          color: AppColors.mutedText(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQrCodeSection() {
    if (_isUploadingQr) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: AppColors.chipFill(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border(context)),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppColors.accent(context)),
              SizedBox(height: 12),
              Text(
                _localizations.uploadingQrCode,
                style: TextStyle(color: AppTheme.grey600, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    final qrBytes = _decodeShopImage(_qrCodeBase64);
    if (qrBytes != null && qrBytes.isNotEmpty) {
      return Column(
        children: [
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.chipFill(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border(context)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: Image.memory(
                qrBytes,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: AppTheme.error,
                          size: 40,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Failed to load QR code',
                          style: TextStyle(color: AppTheme.grey600),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickAndUploadQrCode,
                  icon: Icon(Icons.refresh, size: 18),
                  label: Text('Change'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.action(context),
                    side: BorderSide(color: AppColors.accent(context)),
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
                    foregroundColor: AppTheme.red,
                    side: const BorderSide(color: AppTheme.red),
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
          color: AppColors.chipFill(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.grey300,
            style: BorderStyle.solid,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.qr_code_2_outlined, size: 48, color: AppTheme.grey400),
              SizedBox(height: 12),
              Text(
                _localizations.uploadQrCode,
                style: TextStyle(
                  color: AppColors.accent(context),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Tap to select image',
                style: TextStyle(color: AppTheme.grey, fontSize: 12),
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
          color: AppColors.chipFill(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border(context)),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppColors.accent(context)),
              SizedBox(height: 12),
              Text(
                _localizations.uploadingLogo,
                style: TextStyle(color: AppTheme.grey600, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    final logoBytes = _decodeShopImage(_shopLogoBase64);
    if (logoBytes != null && logoBytes.isNotEmpty) {
      return Column(
        children: [
          Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.chipFill(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border(context)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: Image.memory(
                logoBytes,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: AppTheme.error,
                          size: 40,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Failed to load logo',
                          style: TextStyle(color: AppTheme.grey600),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickAndUploadLogo,
                  icon: Icon(Icons.refresh, size: 18),
                  label: Text('Change'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.action(context),
                    side: BorderSide(color: AppColors.accent(context)),
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
                    foregroundColor: AppTheme.red,
                    side: const BorderSide(color: AppTheme.red),
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
          color: AppColors.chipFill(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border(context)),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image_outlined, size: 40, color: AppTheme.grey400),
              SizedBox(height: 8),
              Text(
                _localizations.uploadLogo,
                style: TextStyle(
                  color: AppColors.accent(context),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Tap to select image',
                style: TextStyle(color: AppTheme.grey, fontSize: 12),
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
          color: AppColors.chipFill(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border(context)),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppColors.accent(context)),
              SizedBox(height: 12),
              Text(
                _localizations.uploadingSignature,
                style: TextStyle(color: AppTheme.grey600, fontSize: 14),
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
              color: AppColors.chipFill(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border(context)),
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
                          color: AppTheme.error,
                          size: 40,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Failed to load signature',
                          style: TextStyle(color: AppTheme.grey600),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _showSignaturePad,
                  icon: Icon(Icons.refresh, size: 18),
                  label: Text('Change'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.action(context),
                    side: BorderSide(color: AppColors.accent(context)),
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
                    foregroundColor: AppTheme.red,
                    side: const BorderSide(color: AppTheme.red),
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
          color: AppColors.chipFill(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border(context)),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.draw_outlined, size: 36, color: AppTheme.grey400),
              SizedBox(height: 8),
              Text(
                _localizations.uploadSignature,
                style: TextStyle(
                  color: AppColors.accent(context),
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
    _upiIdController.dispose();
    // Terms and Conditions
    _termsConditionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wide = DesktopCanvas.wide(context);
    final maxWidth = wide ? 920.0 : double.infinity;

    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      body: Column(
        children: [
          if (!widget.isEmbedded)
            AppTopBar(title: _localizations.shopDetails),
          Expanded(
            child: _isLoadingDetails
                ? Center(
                    child: CircularProgressIndicator(
                      color: AppColors.action(context),
                    ),
                  )
                : Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        wide ? 28 : 16,
                        12,
                        wide ? 28 : 16,
                        28,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: maxWidth),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildSectionCard(
                                icon: Icons.storefront_rounded,
                                iconColor: AppColors.action(context),
                                title: _localizations.shopInformation,
                                subtitle: 'Basic shop profile used on bills',
                                children: [
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
                              const SizedBox(height: 18),
                              _buildSectionCard(
                                icon: Icons.contact_phone_rounded,
                                iconColor: AppTheme.toneBlue,
                                title: _localizations.contactInformation,
                                subtitle: 'Shown on invoices and receipts',
                                children: [
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
                              const SizedBox(height: 18),
                              _buildSectionCard(
                                icon: Icons.business_center_rounded,
                                iconColor: AppTheme.toneViolet,
                                title: _localizations.businessInformation,
                                subtitle: 'Tax identity for GST bills',
                                children: [
                                  _buildInputField(
                                    label: _localizations.gstNumber,
                                    controller: _gstController,
                                    icon: Icons.receipt_long_outlined,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),
                              _buildSectionCard(
                                icon: Icons.account_balance_rounded,
                                iconColor: AppTheme.toneAmber,
                                title: _localizations.bankDetails,
                                subtitle:
                                    'Bank + UPI details for payment QR on bills',
                                children: [
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
                                    icon: Icons.badge_outlined,
                                  ),
                                  const SizedBox(height: 16),
                                  _buildInputField(
                                    label: _localizations.upiId,
                                    controller: _upiIdController,
                                    icon: Icons.account_balance_wallet_outlined,
                                    hint: _localizations.upiIdHint,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _localizations.upiIdHelper,
                                    style: TextStyle(
                                      fontFamily: 'Literata',
                                      fontSize: 12,
                                      height: 1.35,
                                      color: AppColors.mutedText(context),
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  Text(
                                    _localizations.paymentQrCode,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.secondaryText(context),
                                      fontFamily: 'Literata',
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  _buildQrCodeSection(),
                                ],
                              ),
                              const SizedBox(height: 18),
                              _buildSectionCard(
                                icon: Icons.image_rounded,
                                iconColor: AppTheme.toneCyan,
                                title: 'Branding',
                                subtitle: 'Logo and signature on printed bills',
                                children: [
                                  Text(
                                    _localizations.shopLogo,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.secondaryText(context),
                                      fontFamily: 'Literata',
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  _buildLogoSection(),
                                  const SizedBox(height: 22),
                                  Text(
                                    _localizations.signature,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.secondaryText(context),
                                      fontFamily: 'Literata',
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  _buildSignatureSection(),
                                ],
                              ),
                              const SizedBox(height: 18),
                              _buildSectionCard(
                                icon: Icons.gavel_rounded,
                                iconColor: AppTheme.coral,
                                title: 'Terms & Conditions',
                                subtitle: 'Printed at the bottom of invoices',
                                children: [
                                  TextFormField(
                                    controller: _termsConditionsController,
                                    maxLines: 5,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppColors.primaryText(context),
                                      fontFamily: 'Literata',
                                    ),
                                    decoration: InputDecoration(
                                      hintText:
                                          'Enter terms and conditions for invoices...',
                                      hintStyle: TextStyle(
                                        color: AppColors.mutedText(context),
                                        fontSize: 13,
                                        fontFamily: 'Literata',
                                      ),
                                      filled: true,
                                      fillColor: AppColors.inputFill(context),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: BorderSide(
                                          color: AppColors.border(context),
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: BorderSide(
                                          color: AppColors.border(context),
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: BorderSide(
                                          color: AppColors.action(context),
                                          width: 1.6,
                                        ),
                                      ),
                                      contentPadding: const EdgeInsets.all(14),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                  onPressed:
                                      _isLoading ? null : _saveShopDetails,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.action(context),
                                    foregroundColor: AppTheme.white,
                                    disabledBackgroundColor: AppColors.action(
                                      context,
                                    ).withValues(alpha: 0.45),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          height: 22,
                                          width: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.4,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                              AppTheme.white,
                                            ),
                                          ),
                                        )
                                      : Text(
                                          _localizations.saveShopDetails,
                                          style: const TextStyle(
                                            color: AppTheme.white,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            fontFamily: 'Literata',
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
