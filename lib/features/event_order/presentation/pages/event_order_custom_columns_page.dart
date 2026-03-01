import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/services/event_order_settings_service.dart';

/// Settings page for managing custom columns for Events and Sub-Events
class EventOrderCustomColumnsPage extends StatefulWidget {
  const EventOrderCustomColumnsPage({super.key});

  @override
  State<EventOrderCustomColumnsPage> createState() =>
      _EventOrderCustomColumnsPageState();
}

class _EventOrderCustomColumnsPageState
    extends State<EventOrderCustomColumnsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F6),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildColumnsList(EventColumnTarget.event),
                  _buildColumnsList(EventColumnTarget.subEvent),
                ],
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
                color: const Color(0xFF1B4D3E).withOpacity(0.1),
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
                  'Custom Columns',
                  style: TextStyle(
                    fontFamily: 'Literata',
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                    color: Color(0xFF1B4D3E),
                  ),
                ),
                Text(
                  'Manage custom fields for events & sub-events',
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

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.white,
        unselectedLabelColor: const Color(0xFF1B4D3E),
        labelStyle: const TextStyle(
          fontFamily: 'Literata',
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'Literata',
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        indicator: BoxDecoration(
          color: const Color(0xFF1B4D3E),
          borderRadius: BorderRadius.circular(10),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        padding: const EdgeInsets.all(4),
        tabs: const [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event, size: 18),
                SizedBox(width: 6),
                Text('Event'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.subdirectory_arrow_right, size: 18),
                SizedBox(width: 6),
                Text('Sub-Event'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColumnsList(EventColumnTarget target) {
    return ListenableBuilder(
      listenable: EventOrderSettingsService.instance,
      builder: (context, _) {
        final columns = target == EventColumnTarget.event
            ? EventOrderSettingsService.instance.eventColumns
            : EventOrderSettingsService.instance.subEventColumns;

        if (columns.isEmpty) {
          return _buildEmptyState(target);
        }

        return ReorderableListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: columns.length,
          onReorder: (oldIndex, newIndex) {
            // Find the actual indices in the full list
            final allColumns = EventOrderSettingsService.instance.customColumns;
            final oldActual = allColumns.indexOf(columns[oldIndex]);
            var newActual = newIndex > oldIndex
                ? allColumns.indexOf(columns[newIndex - 1]) + 1
                : allColumns.indexOf(columns[newIndex]);
            if (newIndex == columns.length) {
              newActual = allColumns.indexOf(columns.last) + 1;
            }
            EventOrderSettingsService.instance.reorderColumns(
              oldActual,
              newActual,
            );
          },
          itemBuilder: (context, index) {
            final column = columns[index];
            return _buildColumnCard(column, index);
          },
        );
      },
    );
  }

  Widget _buildEmptyState(EventColumnTarget target) {
    final isEvent = target == EventColumnTarget.event;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF1B4D3E).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              isEvent ? Icons.event_note : Icons.subdirectory_arrow_right,
              size: 40,
              color: const Color(0xFF1B4D3E),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No ${isEvent ? "Event" : "Sub-Event"} Columns',
            style: const TextStyle(
              fontFamily: 'Literata',
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: Color(0xFF1B4D3E),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add custom columns to capture additional\n${isEvent ? "event" : "sub-event"} information',
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
            onPressed: () => _showAddColumnDialog(preselectedTarget: target),
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

  Widget _buildColumnCard(EventCustomColumn column, int index) {
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
              ? const Color(0xFF1B4D3E).withOpacity(0.2)
              : Colors.grey.withOpacity(0.2),
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
                  color: typeColor.withOpacity(0.15),
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
                        Flexible(
                          child: Text(
                            column.name,
                            style: const TextStyle(
                              fontFamily: 'Literata',
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: Color(0xFF1B4D3E),
                            ),
                            overflow: TextOverflow.ellipsis,
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
                              color: Colors.red.withOpacity(0.1),
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
                      EventCustomColumn.getTypeDisplayName(column.type),
                      style: TextStyle(
                        fontFamily: 'Literata',
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (column.type == EventCustomColumnType.dropdown &&
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

  IconData _getTypeIcon(EventCustomColumnType type) {
    switch (type) {
      case EventCustomColumnType.text:
        return Icons.text_fields_rounded;
      case EventCustomColumnType.number:
        return Icons.numbers_rounded;
      case EventCustomColumnType.decimal:
        return Icons.percent_rounded;
      case EventCustomColumnType.date:
        return Icons.calendar_today_rounded;
      case EventCustomColumnType.dropdown:
        return Icons.arrow_drop_down_circle_rounded;
      case EventCustomColumnType.boolean:
        return Icons.toggle_on_rounded;
    }
  }

  Color _getTypeColor(EventCustomColumnType type) {
    switch (type) {
      case EventCustomColumnType.text:
        return const Color(0xFF667eea);
      case EventCustomColumnType.number:
        return const Color(0xFFf093fb);
      case EventCustomColumnType.decimal:
        return const Color(0xFFFF6B6B);
      case EventCustomColumnType.date:
        return const Color(0xFF1B4D3E);
      case EventCustomColumnType.dropdown:
        return const Color(0xFF9C27B0);
      case EventCustomColumnType.boolean:
        return const Color(0xFFFF9800);
    }
  }

  void _handleColumnAction(String action, EventCustomColumn column) {
    switch (action) {
      case 'edit':
        _showAddColumnDialog(existingColumn: column);
        break;
      case 'toggle':
        EventOrderSettingsService.instance.toggleColumnActive(column.id);
        break;
      case 'delete':
        _showDeleteConfirmation(column);
        break;
    }
  }

  void _showDeleteConfirmation(EventCustomColumn column) {
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
              EventOrderSettingsService.instance.deleteColumn(column.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${column.name} deleted'),
                  backgroundColor: const Color(0xFF1B4D3E),
                ),
              );
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

  void _showAddColumnDialog({
    EventCustomColumn? existingColumn,
    EventColumnTarget? preselectedTarget,
  }) {
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

    EventCustomColumnType selectedType =
        existingColumn?.type ?? EventCustomColumnType.text;
    EventColumnTarget selectedTarget =
        existingColumn?.target ??
        preselectedTarget ??
        ((_tabController.index == 0)
            ? EventColumnTarget.event
            : EventColumnTarget.subEvent);
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
                      hintText: 'e.g., Venue, Decoration Theme',
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

                  // Target Type Dropdown (only for new columns)
                  if (existingColumn == null) ...[
                    const Text(
                      'Column For',
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
                        child: DropdownButton<EventColumnTarget>(
                          value: selectedTarget,
                          isExpanded: true,
                          items: EventColumnTarget.values.map((target) {
                            return DropdownMenuItem(
                              value: target,
                              child: Row(
                                children: [
                                  Icon(
                                    target == EventColumnTarget.event
                                        ? Icons.event
                                        : Icons.subdirectory_arrow_right,
                                    size: 20,
                                    color: const Color(0xFF1B4D3E),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    EventCustomColumn.getTargetDisplayName(
                                      target,
                                    ),
                                    style: const TextStyle(
                                      fontFamily: 'Literata',
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (target) {
                            if (target != null) {
                              setDialogState(() => selectedTarget = target);
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

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
                      child: DropdownButton<EventCustomColumnType>(
                        value: selectedType,
                        isExpanded: true,
                        items: EventCustomColumnType.values.map((type) {
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
                                  EventCustomColumn.getTypeDisplayName(type),
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
                  if (selectedType == EventCustomColumnType.dropdown) ...[
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
                  if (selectedType != EventCustomColumnType.boolean) ...[
                    TextField(
                      controller: defaultValueController,
                      keyboardType:
                          selectedType == EventCustomColumnType.number ||
                              selectedType == EventCustomColumnType.decimal
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
                      'User must fill this field when adding ${selectedTarget == EventColumnTarget.event ? "event" : "sub-event"}',
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a column name'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  // Parse dropdown options
                  List<String>? dropdownOptions;
                  if (selectedType == EventCustomColumnType.dropdown) {
                    final optionsText = dropdownOptionsController.text.trim();
                    if (optionsText.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter dropdown options'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    dropdownOptions = optionsText
                        .split(',')
                        .map((e) => e.trim())
                        .where((e) => e.isNotEmpty)
                        .toList();
                  }

                  final column = EventCustomColumn(
                    id:
                        existingColumn?.id ??
                        EventOrderSettingsService.instance.generateColumnId(),
                    name: name,
                    type: selectedType,
                    target: existingColumn?.target ?? selectedTarget,
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
                    EventOrderSettingsService.instance.updateColumn(
                      existingColumn.id,
                      column,
                    );
                  } else {
                    EventOrderSettingsService.instance.addColumn(column);
                  }

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        existingColumn != null
                            ? 'Column updated'
                            : 'Column added',
                      ),
                      backgroundColor: const Color(0xFF1B4D3E),
                    ),
                  );
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
