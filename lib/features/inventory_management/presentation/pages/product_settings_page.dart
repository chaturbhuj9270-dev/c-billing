import 'package:flutter/material.dart';
import 'dart:ui';
import '../../../../core/services/product_settings_service.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/services/language_service.dart';
import 'package:c_billing/core/ui/glassy_toast.dart';

class ProductSettingsPage extends StatefulWidget {
  const ProductSettingsPage({super.key});

  @override
  State<ProductSettingsPage> createState() => _ProductSettingsPageState();
}

class _ProductSettingsPageState extends State<ProductSettingsPage> {
  late AppLocalizations _localizations;

  @override
  void initState() {
    super.initState();
    _localizations = AppLocalizations.of(
      LanguageService.instance.currentLanguage,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F6),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: ListenableBuilder(
                listenable: ProductSettingsService.instance,
                builder: (context, _) {
                  final columns = ProductSettingsService.instance.customColumns;

                  if (columns.isEmpty) {
                    return _buildEmptyState();
                  }

                  return ReorderableListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: columns.length,
                    onReorder: (oldIndex, newIndex) {
                      ProductSettingsService.instance.reorderColumns(
                        oldIndex,
                        newIndex,
                      );
                    },
                    itemBuilder: (context, index) {
                      final column = columns[index];
                      return _buildColumnCard(column, index);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddColumnDialog(),
        backgroundColor: const Color(0xFF1B4D3E),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Add Column',
          style: TextStyle(
            fontFamily: 'Literata',
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF1B4D3E).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.arrow_back_ios_rounded,
                size: 20,
                color: Color(0xFF1B4D3E),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Product Settings',
                  style: TextStyle(
                    fontFamily: 'Literata',
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                    color: Color(0xFF1B4D3E),
                  ),
                ),
                Text(
                  'Manage custom columns for products',
                  style: TextStyle(
                    fontFamily: 'Literata',
                    fontWeight: FontWeight.w400,
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF1B4D3E).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.view_column_rounded,
              size: 40,
              color: Color(0xFF1B4D3E),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Custom Columns',
            style: TextStyle(
              fontFamily: 'Literata',
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: Color(0xFF1B4D3E),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add custom columns to capture additional\nproduct information',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Literata',
              fontWeight: FontWeight.w400,
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddColumnDialog(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B4D3E),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            label: const Text(
              'Add First Column',
              style: TextStyle(
                fontFamily: 'Literata',
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColumnCard(CustomColumn column, int index) {
    final typeIcon = _getTypeIcon(column.type);
    final typeColor = _getTypeColor(column.type);

    return Card(
      key: ValueKey(column.id),
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: column.isActive
              ? const Color(0xFF1B4D3E).withValues(alpha: 0.2)
              : Colors.grey.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Opacity(
        opacity: column.isActive ? 1.0 : 0.6,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
          ),
          child: Row(
            children: [
              // Drag handle
              ReorderableDragStartListener(
                index: index,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    Icons.drag_indicator_rounded,
                    color: Colors.grey[400],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Type icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(typeIcon, color: typeColor, size: 22),
              ),
              const SizedBox(width: 12),
              // Column info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          column.name,
                          style: const TextStyle(
                            fontFamily: 'Literata',
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: Color(0xFF1B4D3E),
                          ),
                        ),
                        if (column.isRequired) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Required',
                              style: TextStyle(
                                fontFamily: 'Literata',
                                fontWeight: FontWeight.w600,
                                fontSize: 10,
                                color: Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      CustomColumn.getTypeDisplayName(column.type),
                      style: TextStyle(
                        fontFamily: 'Literata',
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (column.type == CustomColumnType.dropdown &&
                        column.dropdownOptions != null &&
                        column.dropdownOptions!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Options: ${column.dropdownOptions!.join(", ")}',
                        style: TextStyle(
                          fontFamily: 'Literata',
                          fontWeight: FontWeight.w400,
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              // Actions
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert_rounded, color: Colors.grey[600]),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onSelected: (value) => _handleColumnAction(value, column),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(
                          Icons.edit_rounded,
                          size: 20,
                          color: Colors.grey[700],
                        ),
                        const SizedBox(width: 12),
                        const Text('Edit'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'toggle',
                    child: Row(
                      children: [
                        Icon(
                          column.isActive
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                          size: 20,
                          color: Colors.grey[700],
                        ),
                        const SizedBox(width: 12),
                        Text(column.isActive ? 'Disable' : 'Enable'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(
                          Icons.delete_rounded,
                          size: 20,
                          color: Colors.red,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Delete',
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getTypeIcon(CustomColumnType type) {
    switch (type) {
      case CustomColumnType.text:
        return Icons.text_fields_rounded;
      case CustomColumnType.number:
        return Icons.numbers_rounded;
      case CustomColumnType.decimal:
        return Icons.percent_rounded;
      case CustomColumnType.date:
        return Icons.calendar_today_rounded;
      case CustomColumnType.dropdown:
        return Icons.arrow_drop_down_circle_rounded;
      case CustomColumnType.boolean:
        return Icons.toggle_on_rounded;
    }
  }

  Color _getTypeColor(CustomColumnType type) {
    switch (type) {
      case CustomColumnType.text:
        return const Color(0xFF667eea);
      case CustomColumnType.number:
        return const Color(0xFFf093fb);
      case CustomColumnType.decimal:
        return const Color(0xFFFF6B6B);
      case CustomColumnType.date:
        return const Color(0xFF1B4D3E);
      case CustomColumnType.dropdown:
        return const Color(0xFF9C27B0);
      case CustomColumnType.boolean:
        return const Color(0xFFFF9800);
    }
  }

  void _handleColumnAction(String action, CustomColumn column) {
    switch (action) {
      case 'edit':
        _showAddColumnDialog(existingColumn: column);
        break;
      case 'toggle':
        ProductSettingsService.instance.toggleColumnActive(column.id);
        break;
      case 'delete':
        _showDeleteConfirmation(column);
        break;
    }
  }

  void _showDeleteConfirmation(CustomColumn column) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Column?',
          style: TextStyle(
            fontFamily: 'Literata',
            fontWeight: FontWeight.w700,
            color: Color(0xFF1B4D3E),
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${column.name}"? This action cannot be undone.',
          style: const TextStyle(fontFamily: 'Literata'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(fontFamily: 'Literata', color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              ProductSettingsService.instance.deleteColumn(column.id);
              Navigator.pop(context);
              GlassyToast.show(context, '${column.name} deleted');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Delete',
              style: TextStyle(fontFamily: 'Literata', color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddColumnDialog({CustomColumn? existingColumn}) {
    final nameController = TextEditingController(
      text: existingColumn?.name ?? '',
    );
    final placeholderController = TextEditingController(
      text: existingColumn?.placeholder ?? '',
    );
    final defaultValueController = TextEditingController(
      text: existingColumn?.defaultValue ?? '',
    );
    final dropdownOptionsController = TextEditingController(
      text: existingColumn?.dropdownOptions?.join(', ') ?? '',
    );

    CustomColumnType selectedType =
        existingColumn?.type ?? CustomColumnType.text;
    bool isRequired = existingColumn?.isRequired ?? false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              existingColumn != null ? 'Edit Column' : 'Add Custom Column',
              style: const TextStyle(
                fontFamily: 'Literata',
                fontWeight: FontWeight.w700,
                color: Color(0xFF1B4D3E),
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Column Name
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Column Name *',
                      hintText: 'e.g., Warranty, Color, Size',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF1B4D3E),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Data Type Dropdown
                  const Text(
                    'Data Type',
                    style: TextStyle(
                      fontFamily: 'Literata',
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Color(0xFF1B4D3E),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[400]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<CustomColumnType>(
                        value: selectedType,
                        isExpanded: true,
                        items: CustomColumnType.values.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Row(
                              children: [
                                Icon(
                                  _getTypeIcon(type),
                                  size: 20,
                                  color: _getTypeColor(type),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  CustomColumn.getTypeDisplayName(type),
                                  style: const TextStyle(
                                    fontFamily: 'Literata',
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (type) {
                          if (type != null) {
                            setDialogState(() => selectedType = type);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Dropdown Options (only for dropdown type)
                  if (selectedType == CustomColumnType.dropdown) ...[
                    TextField(
                      controller: dropdownOptionsController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Dropdown Options *',
                        hintText: 'Comma separated: Option1, Option2, Option3',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF1B4D3E),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Placeholder
                  TextField(
                    controller: placeholderController,
                    decoration: InputDecoration(
                      labelText: 'Placeholder (optional)',
                      hintText: 'Hint text for the field',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF1B4D3E),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Default Value (not for boolean)
                  if (selectedType != CustomColumnType.boolean) ...[
                    TextField(
                      controller: defaultValueController,
                      keyboardType:
                          selectedType == CustomColumnType.number ||
                              selectedType == CustomColumnType.decimal
                          ? TextInputType.number
                          : TextInputType.text,
                      decoration: InputDecoration(
                        labelText: 'Default Value (optional)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF1B4D3E),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Required toggle
                  SwitchListTile(
                    value: isRequired,
                    onChanged: (value) =>
                        setDialogState(() => isRequired = value),
                    title: const Text(
                      'Required Field',
                      style: TextStyle(
                        fontFamily: 'Literata',
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      'User must fill this field when adding product',
                      style: TextStyle(
                        fontFamily: 'Literata',
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    activeThumbColor: const Color(0xFF1B4D3E),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    fontFamily: 'Literata',
                    color: Colors.grey[600],
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  final name = nameController.text.trim();
                  if (name.isEmpty) {
                    GlassyToast.show(context, 'Please enter a column name', isError: true);
                    return;
                  }

                  // Parse dropdown options
                  List<String>? dropdownOptions;
                  if (selectedType == CustomColumnType.dropdown) {
                    final optionsText = dropdownOptionsController.text.trim();
                    if (optionsText.isEmpty) {
                      GlassyToast.show(context, 'Please enter dropdown options', isError: true);
                      return;
                    }
                    dropdownOptions = optionsText
                        .split(',')
                        .map((e) => e.trim())
                        .where((e) => e.isNotEmpty)
                        .toList();
                  }

                  final column = CustomColumn(
                    id:
                        existingColumn?.id ??
                        ProductSettingsService.instance.generateColumnId(),
                    name: name,
                    type: selectedType,
                    isRequired: isRequired,
                    defaultValue: defaultValueController.text.trim().isNotEmpty
                        ? defaultValueController.text.trim()
                        : null,
                    dropdownOptions: dropdownOptions,
                    placeholder: placeholderController.text.trim().isNotEmpty
                        ? placeholderController.text.trim()
                        : null,
                    isActive: existingColumn?.isActive ?? true,
                  );

                  if (existingColumn != null) {
                    ProductSettingsService.instance.updateColumn(
                      existingColumn.id,
                      column,
                    );
                  } else {
                    ProductSettingsService.instance.addColumn(column);
                  }

                  Navigator.pop(context);
                  GlassyToast.show(context, existingColumn != null
                            ? 'Column updated'
                            : 'Column added');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B4D3E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  existingColumn != null ? 'Update' : 'Add',
                  style: const TextStyle(
                    fontFamily: 'Literata',
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
