import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../offline/controllers/table_offline_controller.dart';

class TableFormSheet extends StatefulWidget {
  const TableFormSheet({super.key});

  @override
  State<TableFormSheet> createState() => _TableFormSheetState();
}

class _TableFormSheetState extends State<TableFormSheet> {
  final _ctrl = TableOfflineController.instance;
  final _formKey = GlobalKey<FormState>();

  final _numberCtrl = TextEditingController();
  final _sectionCtrl = TextEditingController(text: 'Main');
  int _capacity = 4;
  bool _saving = false;

  // Quick capacity selector values
  final _capacityOptions = [2, 4, 6, 8, 10, 12];

  @override
  void dispose() {
    _numberCtrl.dispose();
    _sectionCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.mediumImpact();
    setState(() => _saving = true);
    try {
      await _ctrl.addTable(
        tableNumber: _numberCtrl.text.trim(),
        section: _sectionCtrl.text.trim().isEmpty
            ? 'Main'
            : _sectionCtrl.text.trim(),
        capacity: _capacity,
      );
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
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0E1C17),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: Color(0xFF22C55E), width: 1.5)),
      ),
      padding: EdgeInsets.fromLTRB(24, 16, 24, bottom + 24),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Title
              const Text(
                'New Table',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Literata',
                ),
              ),
              const SizedBox(height: 20),

              // Table number
              _buildLabel('TABLE NUMBER'),
              const SizedBox(height: 8),
              _buildField(
                controller: _numberCtrl,
                hint: 'e.g. T-01 or 12',
                icon: Icons.table_restaurant_rounded,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Table number is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Section
              _buildLabel('SECTION / ZONE'),
              const SizedBox(height: 8),
              _buildField(
                controller: _sectionCtrl,
                hint: 'e.g. Indoor, Rooftop, Bar',
                icon: Icons.map_rounded,
              ),
              const SizedBox(height: 20),

              // Capacity
              _buildLabel('SEATING CAPACITY'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _capacityOptions.map((cap) {
                  final selected = _capacity == cap;
                  return GestureDetector(
                    onTap: () => setState(() => _capacity = cap),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFF22C55E).withValues(alpha: 0.2)
                            : Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selected
                              ? const Color(0xFF22C55E)
                              : Colors.white.withValues(alpha: 0.12),
                          width: selected ? 1.8 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$cap',
                            style: TextStyle(
                              color: selected
                                  ? const Color(0xFF22C55E)
                                  : Colors.white54,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Literata',
                            ),
                          ),
                          Icon(
                            Icons.people_rounded,
                            size: 12,
                            color: selected
                                ? const Color(0xFF22C55E)
                                : Colors.white30,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 28),

              // Save button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF22C55E),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(
                      0xFF22C55E,
                    ).withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Add Table',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Literata',
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white38,
        fontSize: 10,
        fontWeight: FontWeight.w700,
        fontFamily: 'Literata',
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: TextFormField(
        controller: controller,
        validator: validator,
        style: const TextStyle(
          color: Colors.white,
          fontFamily: 'Literata',
          fontSize: 15,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.25),
            fontFamily: 'Literata',
            fontSize: 14,
          ),
          prefixIcon: Icon(icon, color: Colors.white38, size: 18),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
          errorStyle: const TextStyle(
            color: Color(0xFFF87171),
            fontFamily: 'Literata',
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}
