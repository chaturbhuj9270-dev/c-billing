import 'package:flutter/material.dart';
import 'package:c_billing/core/services/purchase_settings_service.dart';

class PurchaseSettingsPage extends StatefulWidget {
  const PurchaseSettingsPage({super.key});

  @override
  State<PurchaseSettingsPage> createState() => _PurchaseSettingsPageState();
}

class _PurchaseSettingsPageState extends State<PurchaseSettingsPage> {
  late bool _showManufacturingDate;
  late bool _showExpiryDate;
  late bool _showWarranty;
  late List<String> _availableUnits;
  late String _defaultUnit;
  late List<int> _warrantyOptions;
  late int _defaultWarranty;

  @override
  void initState() {
    super.initState();
    _showManufacturingDate = PurchaseSettingsService.instance.showManufacturingDate;
    _showExpiryDate = PurchaseSettingsService.instance.showExpiryDate;
    _showWarranty = PurchaseSettingsService.instance.showWarranty;
    _availableUnits = List.from(PurchaseSettingsService.instance.availableUnits);
    _defaultUnit = PurchaseSettingsService.instance.defaultUnit;
    _warrantyOptions = List.from(PurchaseSettingsService.instance.warrantyOptions);
    _defaultWarranty = PurchaseSettingsService.instance.defaultWarranty;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE6EDE7),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.arrow_back_ios_rounded,
                      size: 22,
                      color: Color(0xFF1B4D3E),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Purchase Settings',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1B4D3E),
                        letterSpacing: 0.5,
                        fontSize: 24,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B4D3E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Done',
                      style: TextStyle(
                        fontFamily: 'Literata',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Settings content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    // Section title - Date Fields
                    const Text(
                      'Date Fields Visibility',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Literata',
                        color: Color(0xFF1B4D3E),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Choose which date fields to display on the purchase form',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontFamily: 'Literata',
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Manufacturing Date Toggle
                    _buildSettingsTile(
                      icon: Icons.factory_rounded,
                      title: 'Manufacturing Date',
                      subtitle: 'Show manufacturing/production date field',
                      value: _showManufacturingDate,
                      onChanged: (value) async {
                        setState(() {
                          _showManufacturingDate = value;
                        });
                        await PurchaseSettingsService.instance.setShowManufacturingDate(value);
                      },
                    ),
                    const SizedBox(height: 16),
                    // Expiry Date Toggle
                    _buildSettingsTile(
                      icon: Icons.event_busy_rounded,
                      title: 'Expiry Date',
                      subtitle: 'Show expiry/expiration date field',
                      value: _showExpiryDate,
                      onChanged: (value) async {
                        setState(() {
                          _showExpiryDate = value;
                        });
                        await PurchaseSettingsService.instance.setShowExpiryDate(value);
                      },
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Section title - Measurement Units
                    const Text(
                      'Measurement Units',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Literata',
                        color: Color(0xFF1B4D3E),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Select which units are available for purchase and set the default',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontFamily: 'Literata',
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Available Units Selection
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1B4D3E).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.straighten_rounded,
                                  color: Color(0xFF1B4D3E),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Available Units',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        fontFamily: 'Literata',
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Select units to show in purchase form',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey,
                                        fontFamily: 'Literata',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: PurchaseSettingsService.instance.allUnits.map((unit) {
                              final isSelected = _availableUnits.contains(unit);
                              final isDefault = _defaultUnit == unit;
                              final isCustom = PurchaseSettingsService.instance.isCustomUnit(unit);
                              return FilterChip(
                                label: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      unit + (isDefault ? ' ★' : ''),
                                      style: TextStyle(
                                        color: isSelected ? Colors.white : Colors.black87,
                                        fontFamily: 'Literata',
                                        fontWeight: isDefault ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                    if (isCustom && !isDefault) ...[
                                      const SizedBox(width: 4),
                                      GestureDetector(
                                        onTap: () async {
                                          // Show confirmation dialog
                                          final confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: const Text('Remove Custom Unit'),
                                              content: Text('Are you sure you want to remove "$unit"?'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(context, false),
                                                  child: const Text('Cancel'),
                                                ),
                                                TextButton(
                                                  onPressed: () => Navigator.pop(context, true),
                                                  child: const Text('Remove', style: TextStyle(color: Colors.red)),
                                                ),
                                              ],
                                            ),
                                          );
                                          if (confirm == true) {
                                            await PurchaseSettingsService.instance.removeCustomUnit(unit);
                                            setState(() {
                                              _availableUnits = List.from(PurchaseSettingsService.instance.availableUnits);
                                            });
                                          }
                                        },
                                        child: Icon(
                                          Icons.close,
                                          size: 16,
                                          color: isSelected ? Colors.white70 : Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                selected: isSelected,
                                onSelected: (selected) async {
                                  // Don't allow deselecting if it's the only one or the default
                                  if (!selected && (_availableUnits.length <= 1 || isDefault)) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          isDefault 
                                              ? 'Cannot remove the default unit. Change the default first.'
                                              : 'At least one unit must be selected.',
                                        ),
                                        backgroundColor: Colors.orange,
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
                                },
                                selectedColor: const Color(0xFF1B4D3E),
                                checkmarkColor: Colors.white,
                                backgroundColor: Colors.grey[200],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),
                          // Add Custom Unit Button
                          OutlinedButton.icon(
                            onPressed: _showAddCustomUnitDialog,
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Add Custom Unit'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF1B4D3E),
                              side: const BorderSide(color: Color(0xFF1B4D3E)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Default Unit Selection
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF6F00).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.star_rounded,
                                  color: Color(0xFFFF6F00),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Default Unit',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        fontFamily: 'Literata',
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Pre-selected unit on purchase form',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey,
                                        fontFamily: 'Literata',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _availableUnits.map((unit) {
                              final isSelected = _defaultUnit == unit;
                              return ChoiceChip(
                                label: Text(
                                  unit,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : Colors.black87,
                                    fontFamily: 'Literata',
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                  ),
                                ),
                                selected: isSelected,
                                onSelected: (selected) async {
                                  if (selected) {
                                    setState(() {
                                      _defaultUnit = unit;
                                    });
                                    await PurchaseSettingsService.instance.setDefaultUnit(unit);
                                  }
                                },
                                selectedColor: const Color(0xFFFF6F00),
                                backgroundColor: Colors.grey[200],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Section title - Warranty
                    const Text(
                      'Warranty',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Literata',
                        color: Color(0xFF1B4D3E),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Configure warranty options for products',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontFamily: 'Literata',
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Warranty Toggle
                    _buildSettingsTile(
                      icon: Icons.verified_user_rounded,
                      title: 'Show Warranty Field',
                      subtitle: 'Display warranty selection on purchase form',
                      value: _showWarranty,
                      onChanged: (value) async {
                        setState(() {
                          _showWarranty = value;
                        });
                        await PurchaseSettingsService.instance.setShowWarranty(value);
                      },
                    ),
                    
                    if (_showWarranty) ...[
                      const SizedBox(height: 16),
                      
                      // Available Warranty Options
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF9C27B0).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.schedule_rounded,
                                    color: Color(0xFF9C27B0),
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Warranty Options',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: 'Literata',
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Select available warranty periods',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey,
                                          fontFamily: 'Literata',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: PurchaseSettingsService.instance.allWarrantyOptions.map((months) {
                                final isSelected = _warrantyOptions.contains(months);
                                final isDefault = _defaultWarranty == months;
                                return FilterChip(
                                  label: Text(
                                    PurchaseSettingsService.instance.getWarrantyLabel(months) + (isDefault ? ' ★' : ''),
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : Colors.black87,
                                      fontFamily: 'Literata',
                                      fontWeight: isDefault ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                  selected: isSelected,
                                  onSelected: (selected) async {
                                    // Don't allow deselecting if it's the only one or the default
                                    if (!selected && (_warrantyOptions.length <= 1 || isDefault)) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            isDefault 
                                                ? 'Cannot remove the default warranty. Change the default first.'
                                                : 'At least one warranty option must be selected.',
                                          ),
                                          backgroundColor: Colors.orange,
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
                                  },
                                  selectedColor: const Color(0xFF9C27B0),
                                  checkmarkColor: Colors.white,
                                  backgroundColor: Colors.grey[200],
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 16),
                            // Add Custom Warranty Button
                            OutlinedButton.icon(
                              onPressed: _showAddCustomWarrantyDialog,
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Add Custom Warranty'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF9C27B0),
                                side: const BorderSide(color: Color(0xFF9C27B0)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Default Warranty Selection
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE91E63).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.star_rounded,
                                    color: Color(0xFFE91E63),
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Default Warranty',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: 'Literata',
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Pre-selected warranty on purchase form',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey,
                                          fontFamily: 'Literata',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _warrantyOptions.map((months) {
                                final isSelected = _defaultWarranty == months;
                                return ChoiceChip(
                                  label: Text(
                                    PurchaseSettingsService.instance.getWarrantyLabel(months),
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : Colors.black87,
                                      fontFamily: 'Literata',
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                    ),
                                  ),
                                  selected: isSelected,
                                  onSelected: (selected) async {
                                    if (selected) {
                                      setState(() {
                                        _defaultWarranty = months;
                                      });
                                      await PurchaseSettingsService.instance.setDefaultWarranty(months);
                                    }
                                  },
                                  selectedColor: const Color(0xFFE91E63),
                                  backgroundColor: Colors.grey[200],
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showAddCustomWarrantyDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF9C27B0).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.add,
                color: Color(0xFF9C27B0),
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
          decoration: InputDecoration(
            hintText: 'Enter warranty period in months',
            suffixText: 'months',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF9C27B0), width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final months = int.tryParse(controller.text.trim());
              if (months == null || months <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid number of months'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }
              
              // Check if already exists
              if (_warrantyOptions.contains(months)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('This warranty period already exists'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }
              
              setState(() {
                _warrantyOptions.add(months);
                _warrantyOptions.sort();
              });
              await PurchaseSettingsService.instance.setWarrantyOptions(_warrantyOptions);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${PurchaseSettingsService.instance.getWarrantyLabel(months)} added successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9C27B0),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
  
  void _showAddCustomUnitDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF1B4D3E).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.add,
                color: Color(0xFF1B4D3E),
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
          decoration: InputDecoration(
            hintText: 'Enter unit name (e.g., Yard, Pair)',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF1B4D3E), width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final unitName = controller.text.trim();
              if (unitName.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a unit name'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }
              
              // Check if already exists
              if (PurchaseSettingsService.instance.allUnits.contains(unitName)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('This unit already exists'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }
              
              await PurchaseSettingsService.instance.addCustomUnit(unitName);
              setState(() {
                _availableUnits = List.from(PurchaseSettingsService.instance.availableUnits);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('"$unitName" added successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B4D3E),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF1B4D3E).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF1B4D3E),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Literata',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontFamily: 'Literata',
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF1B4D3E),
            activeTrackColor: const Color(0xFF1B4D3E).withOpacity(0.3),
          ),
        ],
      ),
    );
  }
}
