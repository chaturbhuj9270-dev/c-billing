import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/services/language_service.dart';
import '../../domain/entities/event_order.dart';
import 'event_order_custom_columns_page.dart';

/// Settings page for Event/Order list configuration
class EventOrderSettingsPage extends StatefulWidget {
  final OrderType? currentType;
  final Function(OrderType?) onTypeChanged;

  const EventOrderSettingsPage({
    super.key,
    required this.currentType,
    required this.onTypeChanged,
  });

  @override
  State<EventOrderSettingsPage> createState() => _EventOrderSettingsPageState();
}

class _EventOrderSettingsPageState extends State<EventOrderSettingsPage> {
  static const _prefsKey = 'event_order_show_event_mode';
  static const _primaryColor = Color(0xFF1B4D3E);
  static const _eventColor = Color(0xFF9C27B0);
  static const _salesColor = Color(0xFF2196F3);

  bool _showEventMode = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedMode = prefs.getBool(_prefsKey);

      setState(() {
        // If we have a saved preference, use it
        // Otherwise, infer from current type
        if (savedMode != null) {
          _showEventMode = savedMode;
        } else if (widget.currentType != null) {
          _showEventMode = widget.currentType == OrderType.event;
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _showEventMode = widget.currentType == OrderType.event;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefsKey, value);
    } catch (e) {
      debugPrint('[EventOrderSettings] Error saving settings: $e');
    }
  }

  void _onModeChanged(bool value) {
    setState(() => _showEventMode = value);
    _saveSettings(value);

    // Notify parent of type change
    final newType = value ? OrderType.event : OrderType.salesOrder;
    widget.onTypeChanged(newType);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new,
              color: _primaryColor,
              size: 18,
            ),
          ),
        ),
        title: Text(
          AppLocalizations.of(
            LanguageService.instance.currentLanguage,
          ).settings,
          style: const TextStyle(
            fontFamily: 'Literata',
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: Color(0xFF1A1A2E),
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _primaryColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section header
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 12),
                    child: Text(
                      AppLocalizations.of(
                        LanguageService.instance.currentLanguage,
                      ).displayMode,
                      style: TextStyle(
                        fontFamily: 'Literata',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  // Mode toggle card
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Toggle row
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: _showEventMode
                                        ? [
                                            _eventColor,
                                            _eventColor.withValues(alpha: 0.7),
                                          ]
                                        : [
                                            _salesColor,
                                            _salesColor.withValues(alpha: 0.7),
                                          ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  _showEventMode
                                      ? Icons.celebration_rounded
                                      : Icons.shopping_bag_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      AppLocalizations.of(
                                        LanguageService
                                            .instance
                                            .currentLanguage,
                                      ).showEvents,
                                      style: const TextStyle(
                                        fontFamily: 'Literata',
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1A1A2E),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _showEventMode
                                          ? AppLocalizations.of(
                                              LanguageService
                                                  .instance
                                                  .currentLanguage,
                                            ).eventModeActive
                                          : AppLocalizations.of(
                                              LanguageService
                                                  .instance
                                                  .currentLanguage,
                                            ).orderModeActive,
                                      style: TextStyle(
                                        fontFamily: 'Literata',
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch.adaptive(
                                value: _showEventMode,
                                onChanged: _onModeChanged,
                                activeColor: _eventColor,
                                inactiveThumbColor: _salesColor,
                                inactiveTrackColor: _salesColor.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Divider
                        Divider(height: 1, color: Colors.grey[100]),
                        // Mode description
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildModeInfoRow(
                                icon: Icons.celebration_rounded,
                                color: _eventColor,
                                title: AppLocalizations.of(
                                  LanguageService.instance.currentLanguage,
                                ).eventModeTitle,
                                description: AppLocalizations.of(
                                  LanguageService.instance.currentLanguage,
                                ).eventModeDescription,
                                isActive: _showEventMode,
                              ),
                              const SizedBox(height: 12),
                              _buildModeInfoRow(
                                icon: Icons.shopping_bag_rounded,
                                color: _salesColor,
                                title: AppLocalizations.of(
                                  LanguageService.instance.currentLanguage,
                                ).orderModeTitle,
                                description: AppLocalizations.of(
                                  LanguageService.instance.currentLanguage,
                                ).orderModeDescription,
                                isActive: !_showEventMode,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Additional info card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _primaryColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _primaryColor.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: _primaryColor,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocalizations.of(
                                  LanguageService.instance.currentLanguage,
                                ).howItWorks,
                                style: const TextStyle(
                                  fontFamily: 'Literata',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1A1A2E),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                AppLocalizations.of(
                                  LanguageService.instance.currentLanguage,
                                ).settingsDescription,
                                style: TextStyle(
                                  fontFamily: 'Literata',
                                  fontSize: 12,
                                  color: Colors.grey[700],
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Custom Columns Section
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 12),
                    child: Text(
                      AppLocalizations.of(
                        LanguageService.instance.currentLanguage,
                      ).customFields,
                      style: TextStyle(
                        fontFamily: 'Literata',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  // Custom columns navigation card
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const EventOrderCustomColumnsPage(),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: _primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.view_column_rounded,
                              color: _primaryColor,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppLocalizations.of(
                                    LanguageService.instance.currentLanguage,
                                  ).customFields,
                                  style: const TextStyle(
                                    fontFamily: 'Literata',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1A1A2E),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  AppLocalizations.of(
                                    LanguageService.instance.currentLanguage,
                                  ).addCustomFieldsDesc,
                                  style: TextStyle(
                                    fontFamily: 'Literata',
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: Colors.grey[400],
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildModeInfoRow({
    required IconData icon,
    required Color color,
    required String title,
    required String description,
    required bool isActive,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isActive ? color.withValues(alpha: 0.1) : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? color.withValues(alpha: 0.3) : Colors.grey[200]!,
          width: isActive ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: isActive ? color : Colors.grey[400], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Literata',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isActive ? color : Colors.grey[600],
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontFamily: 'Literata',
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          if (isActive)
            Icon(Icons.check_circle_rounded, color: color, size: 20),
        ],
      ),
    );
  }
}
