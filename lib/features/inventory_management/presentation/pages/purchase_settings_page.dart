import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:c_billing/core/services/purchase_settings_service.dart';

class PurchaseSettingsPage extends StatefulWidget {
  const PurchaseSettingsPage({super.key});

  @override
  State<PurchaseSettingsPage> createState() => _PurchaseSettingsPageState();
}

class _PurchaseSettingsPageState extends State<PurchaseSettingsPage>
    with SingleTickerProviderStateMixin {
  late bool _showManufacturingDate;
  late bool _showExpiryDate;
  late bool _showWarranty;
  late List<String> _availableUnits;
  late String _defaultUnit;
  late List<int> _warrantyOptions;
  late int _defaultWarranty;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _showManufacturingDate =
        PurchaseSettingsService.instance.showManufacturingDate;
    _showExpiryDate = PurchaseSettingsService.instance.showExpiryDate;
    _showWarranty = PurchaseSettingsService.instance.showWarranty;
    _availableUnits = List.from(
      PurchaseSettingsService.instance.availableUnits,
    );
    _defaultUnit = PurchaseSettingsService.instance.defaultUnit;
    _warrantyOptions = List.from(
      PurchaseSettingsService.instance.warrantyOptions,
    );
    _defaultWarranty = PurchaseSettingsService.instance.defaultWarranty;

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F6),
      body: CustomScrollView(
        slivers: [
          // Sticky Header with Glass Effect
          SliverPersistentHeader(
            pinned: true,
            delegate: _SettingsHeaderDelegate(
              minHeight: 100,
              maxHeight: 140,
              onBack: () => Navigator.pop(context),
            ),
          ),

          // Main Content
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date Fields Section
                    _buildSectionCard(
                      icon: Icons.calendar_month_rounded,
                      iconColor: const Color(0xFF1B4D3E),
                      title: 'Date Fields',
                      subtitle:
                          'Control date field visibility on purchase form',
                      children: [
                        _buildModernToggle(
                          icon: Icons.factory_rounded,
                          iconColor: const Color(0xFF4CAF50),
                          title: 'Manufacturing Date',
                          subtitle: 'Show production date field',
                          value: _showManufacturingDate,
                          onChanged: (value) async {
                            setState(() => _showManufacturingDate = value);
                            await PurchaseSettingsService.instance
                                .setShowManufacturingDate(value);
                          },
                        ),
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          height: 1,
                          color: Colors.grey.withOpacity(0.1),
                        ),
                        _buildModernToggle(
                          icon: Icons.event_busy_rounded,
                          iconColor: const Color(0xFFFF6B6B),
                          title: 'Expiry Date',
                          subtitle: 'Show expiration date field',
                          value: _showExpiryDate,
                          onChanged: (value) async {
                            setState(() => _showExpiryDate = value);
                            await PurchaseSettingsService.instance
                                .setShowExpiryDate(value);
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Measurement Units Section
                    _buildSectionCard(
                      icon: Icons.straighten_rounded,
                      iconColor: const Color(0xFF7B68EE),
                      title: 'Measurement Units',
                      subtitle: 'Configure available units for purchases',
                      children: [
                        // Available Units
                        _buildSubSectionHeader(
                          icon: Icons.check_circle_outline,
                          title: 'Available Units',
                          color: const Color(0xFF1B4D3E),
                        ),
                        const SizedBox(height: 12),
                        _buildUnitsChipSelector(),
                        const SizedBox(height: 16),
                        _buildAddCustomButton(
                          label: 'Add Custom Unit',
                          color: const Color(0xFF1B4D3E),
                          onPressed: _showAddCustomUnitDialog,
                        ),
                        const SizedBox(height: 20),
                        Container(
                          height: 1,
                          color: Colors.grey.withOpacity(0.1),
                        ),
                        const SizedBox(height: 20),
                        // Default Unit
                        _buildSubSectionHeader(
                          icon: Icons.star_rounded,
                          title: 'Default Unit',
                          color: const Color(0xFFFF6F00),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Pre-selected unit on new purchases',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                            fontFamily: 'Literata',
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildDefaultUnitSelector(),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Warranty Section
                    _buildSectionCard(
                      icon: Icons.verified_user_rounded,
                      iconColor: const Color(0xFF9C27B0),
                      title: 'Warranty Settings',
                      subtitle: 'Configure product warranty options',
                      children: [
                        _buildModernToggle(
                          icon: Icons.shield_rounded,
                          iconColor: const Color(0xFF9C27B0),
                          title: 'Enable Warranty Field',
                          subtitle: 'Show warranty selection on purchase form',
                          value: _showWarranty,
                          onChanged: (value) async {
                            setState(() => _showWarranty = value);
                            await PurchaseSettingsService.instance
                                .setShowWarranty(value);
                          },
                        ),
                        if (_showWarranty) ...[
                          const SizedBox(height: 20),
                          Container(
                            height: 1,
                            color: Colors.grey.withOpacity(0.1),
                          ),
                          const SizedBox(height: 20),
                          // Warranty Options
                          _buildSubSectionHeader(
                            icon: Icons.schedule_rounded,
                            title: 'Warranty Periods',
                            color: const Color(0xFF9C27B0),
                          ),
                          const SizedBox(height: 12),
                          _buildWarrantyChipSelector(),
                          const SizedBox(height: 16),
                          _buildAddCustomButton(
                            label: 'Add Custom Warranty',
                            color: const Color(0xFF9C27B0),
                            onPressed: _showAddCustomWarrantyDialog,
                          ),
                          const SizedBox(height: 20),
                          Container(
                            height: 1,
                            color: Colors.grey.withOpacity(0.1),
                          ),
                          const SizedBox(height: 20),
                          // Default Warranty
                          _buildSubSectionHeader(
                            icon: Icons.star_rounded,
                            title: 'Default Warranty',
                            color: const Color(0xFFE91E63),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Pre-selected warranty on new purchases',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                              fontFamily: 'Literata',
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildDefaultWarrantySelector(),
                        ],
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Info Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF1B4D3E).withOpacity(0.05),
                            const Color(0xFF1B4D3E).withOpacity(0.02),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF1B4D3E).withOpacity(0.1),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1B4D3E).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.lightbulb_outline_rounded,
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
                                  'Pro Tip',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'Literata',
                                    color: Color(0xFF1B4D3E),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Settings are saved automatically. Changes will apply to new purchases immediately.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                    fontFamily: 'Literata',
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Build a section card with header and children
  Widget _buildSectionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Section Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  iconColor.withOpacity(0.08),
                  iconColor.withOpacity(0.02),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [iconColor, iconColor.withOpacity(0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: iconColor.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Literata',
                          color: Color(0xFF1B4D3E),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[500],
                          fontFamily: 'Literata',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Section Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  // Modern toggle with better visual
  Widget _buildModernToggle({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Literata',
                  color: Color(0xFF1B4D3E),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                  fontFamily: 'Literata',
                ),
              ),
            ],
          ),
        ),
        Transform.scale(
          scale: 0.9,
          child: Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.white,
            activeTrackColor: const Color(0xFF1B4D3E),
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: Colors.grey[300],
            trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
          ),
        ),
      ],
    );
  }

  // Sub-section header
  Widget _buildSubSectionHeader({
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            fontFamily: 'Literata',
            color: color,
          ),
        ),
      ],
    );
  }

  // Units chip selector
  Widget _buildUnitsChipSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 10,
      children: PurchaseSettingsService.instance.allUnits.map((unit) {
        final isSelected = _availableUnits.contains(unit);
        final isDefault = _defaultUnit == unit;
        final isCustom = PurchaseSettingsService.instance.isCustomUnit(unit);

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          child: FilterChip(
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  unit,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey[700],
                    fontFamily: 'Literata',
                    fontWeight: isDefault ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
                if (isDefault) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.star_rounded,
                    size: 14,
                    color: isSelected ? Colors.amber[300] : Colors.amber,
                  ),
                ],
                if (isCustom && !isDefault) ...[
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => _showRemoveCustomUnitDialog(unit),
                    child: Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: isSelected ? Colors.white70 : Colors.grey[400],
                    ),
                  ),
                ],
              ],
            ),
            selected: isSelected,
            onSelected: (selected) =>
                _handleUnitSelection(unit, selected, isDefault),
            selectedColor: const Color(0xFF1B4D3E),
            checkmarkColor: Colors.white,
            backgroundColor: Colors.grey[100],
            side: BorderSide(
              color: isSelected ? const Color(0xFF1B4D3E) : Colors.grey[300]!,
              width: isSelected ? 0 : 1,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          ),
        );
      }).toList(),
    );
  }

  // Handle unit selection
  void _handleUnitSelection(String unit, bool selected, bool isDefault) async {
    if (!selected && (_availableUnits.length <= 1 || isDefault)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isDefault
                ? 'Cannot remove the default unit. Change the default first.'
                : 'At least one unit must be selected.',
            style: const TextStyle(fontFamily: 'Literata'),
          ),
          backgroundColor: const Color(0xFFFF6B6B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    setState(() {
      if (selected) {
        _availableUnits.add(unit);
      } else {
        _availableUnits.remove(unit);
      }
    });
    await PurchaseSettingsService.instance.setAvailableUnits(_availableUnits);
  }

  // Show remove custom unit dialog
  void _showRemoveCustomUnitDialog(String unit) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B6B).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                color: Color(0xFFFF6B6B),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Remove Unit',
              style: TextStyle(
                fontFamily: 'Literata',
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to remove "$unit"?',
          style: const TextStyle(fontFamily: 'Literata', fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey[600], fontFamily: 'Literata'),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B6B),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Remove',
              style: TextStyle(fontFamily: 'Literata'),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await PurchaseSettingsService.instance.removeCustomUnit(unit);
      setState(() {
        _availableUnits = List.from(
          PurchaseSettingsService.instance.availableUnits,
        );
      });
    }
  }

  // Default unit selector
  Widget _buildDefaultUnitSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 10,
      children: _availableUnits.map((unit) {
        final isSelected = _defaultUnit == unit;
        return ChoiceChip(
          label: Text(
            unit,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey[700],
              fontFamily: 'Literata',
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              fontSize: 13,
            ),
          ),
          selected: isSelected,
          onSelected: (selected) async {
            if (selected) {
              setState(() => _defaultUnit = unit);
              await PurchaseSettingsService.instance.setDefaultUnit(unit);
            }
          },
          selectedColor: const Color(0xFFFF6F00),
          backgroundColor: Colors.grey[100],
          side: BorderSide(
            color: isSelected ? const Color(0xFFFF6F00) : Colors.grey[300]!,
            width: isSelected ? 0 : 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        );
      }).toList(),
    );
  }

  // Warranty chip selector
  Widget _buildWarrantyChipSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 10,
      children: PurchaseSettingsService.instance.allWarrantyOptions.map((
        months,
      ) {
        final isSelected = _warrantyOptions.contains(months);
        final isDefault = _defaultWarranty == months;

        return FilterChip(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                PurchaseSettingsService.instance.getWarrantyLabel(months),
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[700],
                  fontFamily: 'Literata',
                  fontWeight: isDefault ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
              if (isDefault) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.star_rounded,
                  size: 14,
                  color: isSelected ? Colors.amber[300] : Colors.amber,
                ),
              ],
            ],
          ),
          selected: isSelected,
          onSelected: (selected) =>
              _handleWarrantySelection(months, selected, isDefault),
          selectedColor: const Color(0xFF9C27B0),
          checkmarkColor: Colors.white,
          backgroundColor: Colors.grey[100],
          side: BorderSide(
            color: isSelected ? const Color(0xFF9C27B0) : Colors.grey[300]!,
            width: isSelected ? 0 : 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        );
      }).toList(),
    );
  }

  // Handle warranty selection
  void _handleWarrantySelection(
    int months,
    bool selected,
    bool isDefault,
  ) async {
    if (!selected && (_warrantyOptions.length <= 1 || isDefault)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isDefault
                ? 'Cannot remove the default warranty. Change the default first.'
                : 'At least one warranty option must be selected.',
            style: const TextStyle(fontFamily: 'Literata'),
          ),
          backgroundColor: const Color(0xFFFF6B6B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    setState(() {
      if (selected) {
        _warrantyOptions.add(months);
        _warrantyOptions.sort();
      } else {
        _warrantyOptions.remove(months);
      }
    });
    await PurchaseSettingsService.instance.setWarrantyOptions(_warrantyOptions);
  }

  // Default warranty selector
  Widget _buildDefaultWarrantySelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 10,
      children: _warrantyOptions.map((months) {
        final isSelected = _defaultWarranty == months;
        return ChoiceChip(
          label: Text(
            PurchaseSettingsService.instance.getWarrantyLabel(months),
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey[700],
              fontFamily: 'Literata',
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              fontSize: 13,
            ),
          ),
          selected: isSelected,
          onSelected: (selected) async {
            if (selected) {
              setState(() => _defaultWarranty = months);
              await PurchaseSettingsService.instance.setDefaultWarranty(months);
            }
          },
          selectedColor: const Color(0xFFE91E63),
          backgroundColor: Colors.grey[100],
          side: BorderSide(
            color: isSelected ? const Color(0xFFE91E63) : Colors.grey[300]!,
            width: isSelected ? 0 : 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        );
      }).toList(),
    );
  }

  // Add custom button
  Widget _buildAddCustomButton({
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(Icons.add_rounded, size: 18, color: color),
      label: Text(
        label,
        style: TextStyle(
          fontFamily: 'Literata',
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color.withOpacity(0.5), width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
    );
  }

  // Show add custom unit dialog
  void _showAddCustomUnitDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF1B4D3E),
                    const Color(0xFF1B4D3E).withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Add Custom Unit',
              style: TextStyle(
                fontFamily: 'Literata',
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          style: const TextStyle(fontFamily: 'Literata'),
          decoration: InputDecoration(
            hintText: 'Enter unit name (e.g., Yard)',
            hintStyle: TextStyle(
              color: Colors.grey[400],
              fontFamily: 'Literata',
            ),
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF1B4D3E), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey[600], fontFamily: 'Literata'),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final unitName = controller.text.trim();
              if (unitName.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text(
                      'Please enter a unit name',
                      style: TextStyle(fontFamily: 'Literata'),
                    ),
                    backgroundColor: const Color(0xFFFF6B6B),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
                return;
              }

              if (PurchaseSettingsService.instance.allUnits.contains(
                unitName,
              )) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text(
                      'This unit already exists',
                      style: TextStyle(fontFamily: 'Literata'),
                    ),
                    backgroundColor: const Color(0xFFFF6B6B),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
                return;
              }

              await PurchaseSettingsService.instance.addCustomUnit(unitName);
              setState(() {
                _availableUnits = List.from(
                  PurchaseSettingsService.instance.availableUnits,
                );
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '"$unitName" added successfully',
                    style: const TextStyle(fontFamily: 'Literata'),
                  ),
                  backgroundColor: const Color(0xFF4CAF50),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B4D3E),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text(
              'Add',
              style: TextStyle(
                fontFamily: 'Literata',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Show add custom warranty dialog
  void _showAddCustomWarrantyDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF9C27B0),
                    const Color(0xFF9C27B0).withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Add Custom Warranty',
              style: TextStyle(
                fontFamily: 'Literata',
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          style: const TextStyle(fontFamily: 'Literata'),
          decoration: InputDecoration(
            hintText: 'Enter warranty in months',
            hintStyle: TextStyle(
              color: Colors.grey[400],
              fontFamily: 'Literata',
            ),
            suffixText: 'months',
            suffixStyle: TextStyle(
              color: Colors.grey[600],
              fontFamily: 'Literata',
            ),
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF9C27B0), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey[600], fontFamily: 'Literata'),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final months = int.tryParse(controller.text.trim());
              if (months == null || months <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text(
                      'Please enter a valid number',
                      style: TextStyle(fontFamily: 'Literata'),
                    ),
                    backgroundColor: const Color(0xFFFF6B6B),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
                return;
              }

              if (_warrantyOptions.contains(months)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text(
                      'This warranty period already exists',
                      style: TextStyle(fontFamily: 'Literata'),
                    ),
                    backgroundColor: const Color(0xFFFF6B6B),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
                return;
              }

              setState(() {
                _warrantyOptions.add(months);
                _warrantyOptions.sort();
              });
              await PurchaseSettingsService.instance.setWarrantyOptions(
                _warrantyOptions,
              );
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${PurchaseSettingsService.instance.getWarrantyLabel(months)} added successfully',
                    style: const TextStyle(fontFamily: 'Literata'),
                  ),
                  backgroundColor: const Color(0xFF4CAF50),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9C27B0),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text(
              'Add',
              style: TextStyle(
                fontFamily: 'Literata',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Sticky Header Delegate for Settings Page
class _SettingsHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final VoidCallback onBack;

  _SettingsHeaderDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.onBack,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final progress = (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);
    final isCollapsed = progress > 0.5;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1B4D3E),
            const Color(0xFF2D6A4F),
            const Color(0xFF1B4D3E).withOpacity(0.9),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B4D3E).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      // Back Button
                      GestureDetector(
                        onTap: onBack,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                            ),
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Title
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Purchase Settings',
                              style: TextStyle(
                                fontSize: isCollapsed ? 20 : 24,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'Literata',
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            if (!isCollapsed) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Customize your purchase form',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontFamily: 'Literata',
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      // Done Button
                      GestureDetector(
                        onTap: onBack,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Text(
                            'Done',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Literata',
                              color: Color(0xFF1B4D3E),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_SettingsHeaderDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight;
  }
}
