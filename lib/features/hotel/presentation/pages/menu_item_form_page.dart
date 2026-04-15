import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../offline/controllers/menu_offline_controller.dart';
import '../../offline/entities/menu_item_entity.dart';

class MenuItemFormPage extends StatefulWidget {
  final MenuItemEntity? editItem;

  const MenuItemFormPage({super.key, this.editItem});

  @override
  State<MenuItemFormPage> createState() => _MenuItemFormPageState();
}

class _MenuItemFormPageState extends State<MenuItemFormPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _controller = MenuOfflineController.instance;

  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _categoryCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _prepTimeCtrl;
  late TextEditingController _tagsCtrl;

  bool _isVeg = true;
  bool _isAvailable = true;
  bool _isSaving = false;

  late AnimationController _animCtrl;
  late Animation<double> _fadeIn;

  bool get _isEditing => widget.editItem != null;

  @override
  void initState() {
    super.initState();
    final item = widget.editItem;

    _nameCtrl = TextEditingController(text: item?.name ?? '');
    _descCtrl = TextEditingController(text: item?.description ?? '');
    _categoryCtrl = TextEditingController(text: item?.category ?? '');
    _priceCtrl = TextEditingController(
      text: item != null ? item.price.toString() : '',
    );
    _prepTimeCtrl = TextEditingController(
      text: item != null ? item.preparationTimeMinutes.toString() : '15',
    );
    _tagsCtrl = TextEditingController(text: item?.tags ?? '');
    _isVeg = item?.isVeg ?? true;
    _isAvailable = item?.isAvailable ?? true;

    _animCtrl = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeIn = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _categoryCtrl.dispose();
    _priceCtrl.dispose();
    _prepTimeCtrl.dispose();
    _tagsCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      if (_isEditing) {
        await _controller.updateMenuItem(
          id: widget.editItem!.id,
          name: _nameCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          category: _categoryCtrl.text.trim().isEmpty
              ? 'Uncategorized'
              : _categoryCtrl.text.trim(),
          price: double.parse(_priceCtrl.text.trim()),
          isVeg: _isVeg,
          isAvailable: _isAvailable,
          preparationTimeMinutes: int.tryParse(_prepTimeCtrl.text.trim()) ?? 15,
          tags: _tagsCtrl.text.trim().isEmpty ? null : _tagsCtrl.text.trim(),
        );
      } else {
        await _controller.addMenuItem(
          name: _nameCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          category: _categoryCtrl.text.trim().isEmpty
              ? 'Uncategorized'
              : _categoryCtrl.text.trim(),
          price: double.parse(_priceCtrl.text.trim()),
          isVeg: _isVeg,
          isAvailable: _isAvailable,
          preparationTimeMinutes: int.tryParse(_prepTimeCtrl.text.trim()) ?? 15,
          tags: _tagsCtrl.text.trim().isEmpty ? null : _tagsCtrl.text.trim(),
        );
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: FadeTransition(
              opacity: _fadeIn,
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                  children: [
                    // ── Type toggle ───────────────────
                    _buildSectionLabel('Type'),
                    const SizedBox(height: 8),
                    _buildTypeToggle(),
                    const SizedBox(height: 24),

                    // ── Basic info ───────────────────
                    _buildSectionLabel('Basic Info'),
                    const SizedBox(height: 8),
                    _buildCard(
                      children: [
                        _buildTextField(
                          controller: _nameCtrl,
                          label: 'Item Name',
                          hint: 'e.g. Paneer Tikka',
                          icon: Icons.restaurant_rounded,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Name is required';
                            }
                            return null;
                          },
                        ),
                        const Divider(height: 1),
                        _buildTextField(
                          controller: _descCtrl,
                          label: 'Description',
                          hint: 'Brief description (optional)',
                          icon: Icons.notes_rounded,
                          maxLines: 2,
                        ),
                        const Divider(height: 1),
                        _buildTextField(
                          controller: _categoryCtrl,
                          label: 'Category',
                          hint: 'e.g. Starters, Main Course, Desserts',
                          icon: Icons.category_rounded,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ── Pricing & Time ────────────────
                    _buildSectionLabel('Pricing & Preparation'),
                    const SizedBox(height: 8),
                    _buildCard(
                      children: [
                        _buildTextField(
                          controller: _priceCtrl,
                          label: 'Price (₹)',
                          hint: '0.00',
                          icon: Icons.currency_rupee_rounded,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d+\.?\d{0,2}'),
                            ),
                          ],
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Price is required';
                            }
                            final price = double.tryParse(v);
                            if (price == null || price < 0) {
                              return 'Enter a valid price';
                            }
                            return null;
                          },
                        ),
                        const Divider(height: 1),
                        _buildTextField(
                          controller: _prepTimeCtrl,
                          label: 'Prep Time (min)',
                          hint: '15',
                          icon: Icons.schedule_rounded,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ── Tags ─────────────────────────
                    _buildSectionLabel('Tags'),
                    const SizedBox(height: 8),
                    _buildCard(
                      children: [
                        _buildTextField(
                          controller: _tagsCtrl,
                          label: 'Tags',
                          hint: 'spicy, popular, chef-special',
                          icon: Icons.label_rounded,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ── Availability ──────────────────
                    _buildSectionLabel('Availability'),
                    const SizedBox(height: 8),
                    _buildAvailabilitySwitch(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomSheet: _buildSaveButton(),
    );
  }

  // ─── HEADER ─────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B4D3E), Color(0xFF0F3B2F), Color(0xFF134E3A)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 16, 20),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              ),
              const SizedBox(width: 4),
              Icon(
                _isEditing
                    ? Icons.edit_rounded
                    : Icons.add_circle_outline_rounded,
                color: Colors.white70,
                size: 22,
              ),
              const SizedBox(width: 10),
              Text(
                _isEditing ? 'Edit Item' : 'New Item',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Literata',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── SECTION LABEL ──────────────────────────────────────────────

  Widget _buildSectionLabel(String label) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: const Color(0xFF1B4D3E),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            fontFamily: 'Literata',
            color: Color(0xFF666666),
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }

  // ─── TYPE TOGGLE ────────────────────────────────────────────────

  Widget _buildTypeToggle() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _isVeg = true),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: _isVeg
                    ? const LinearGradient(
                        colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
                      )
                    : null,
                color: _isVeg ? null : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: _isVeg
                    ? null
                    : Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                boxShadow: _isVeg
                    ? [
                        BoxShadow(
                          color: const Color(0xFF2E7D32).withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.eco_rounded,
                    color: _isVeg ? Colors.white : Colors.grey[400],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Veg',
                    style: TextStyle(
                      color: _isVeg ? Colors.white : Colors.grey[600],
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Literata',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _isVeg = false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: !_isVeg
                    ? const LinearGradient(
                        colors: [Color(0xFFD32F2F), Color(0xFFE53935)],
                      )
                    : null,
                color: !_isVeg ? null : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: !_isVeg
                    ? null
                    : Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                boxShadow: !_isVeg
                    ? [
                        BoxShadow(
                          color: const Color(0xFFD32F2F).withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lunch_dining_rounded,
                    color: !_isVeg ? Colors.white : Colors.grey[400],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Non-Veg',
                    style: TextStyle(
                      color: !_isVeg ? Colors.white : Colors.grey[600],
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Literata',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── CARD WRAPPER ───────────────────────────────────────────────

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  // ─── TEXT FIELD ─────────────────────────────────────────────────

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        validator: validator,
        style: const TextStyle(fontFamily: 'Literata', fontSize: 15),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: TextStyle(
            fontFamily: 'Literata',
            color: Colors.grey[500],
            fontSize: 13,
          ),
          hintStyle: TextStyle(
            fontFamily: 'Literata',
            color: Colors.grey[300],
            fontSize: 14,
          ),
          prefixIcon: icon != null
              ? Icon(icon, size: 20, color: const Color(0xFF1B4D3E))
              : null,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  // ─── AVAILABILITY SWITCH ────────────────────────────────────────

  Widget _buildAvailabilitySwitch() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _isAvailable
                  ? const Color(0xFF4CAF50).withValues(alpha: 0.1)
                  : Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _isAvailable
                  ? Icons.check_circle_rounded
                  : Icons.pause_circle_rounded,
              color: _isAvailable ? const Color(0xFF4CAF50) : Colors.grey,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isAvailable ? 'Available' : 'Unavailable',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Literata',
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                Text(
                  _isAvailable
                      ? 'Visible to customers'
                      : 'Hidden from customers',
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'Literata',
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: _isAvailable,
            onChanged: (v) => setState(() => _isAvailable = v),
            activeColor: const Color(0xFF4CAF50),
          ),
        ],
      ),
    );
  }

  // ─── SAVE BUTTON ────────────────────────────────────────────────

  Widget _buildSaveButton() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F0),
        border: Border(
          top: BorderSide(color: Colors.grey.withValues(alpha: 0.15)),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: _isSaving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1B4D3E),
            foregroundColor: Colors.white,
            disabledBackgroundColor: const Color(
              0xFF1B4D3E,
            ).withValues(alpha: 0.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 0,
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : Text(
                  _isEditing ? 'Update Item' : 'Add Item',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Literata',
                  ),
                ),
        ),
      ),
    );
  }
}
