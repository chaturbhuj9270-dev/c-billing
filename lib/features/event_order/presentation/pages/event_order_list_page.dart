import 'dart:io';

import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/services/language_service.dart';
import '../../domain/entities/event_order.dart';
import '../cubit/event_order_cubit.dart';
import '../cubit/event_order_state.dart';
import '../../data/services/event_order_pdf_service.dart';
import '../../data/services/event_order_report_pdf_generator.dart';
import '../../data/services/event_order_sync_service.dart';
import '../../offline/controllers/event_order_offline_controller.dart';
import '../../../shop/data/repositories/shop_repository.dart';
import '../../../shop/domain/entities/shop.dart';
import '../../../../common_widgets/file_preview_page.dart';
import 'event_order_screen.dart';
import 'event_order_settings_page.dart';
import 'package:c_billing/core/ui/glassy_toast.dart';
import 'package:c_billing/core/ui/sync_status_icon.dart';
import 'package:c_billing/common_widgets/range_calendar_sheet.dart';
import 'package:c_billing/core/theme/app_theme.dart';
import 'package:c_billing/common_widgets/app_top_bar.dart';
import 'package:c_billing/common_widgets/glass_bottom_sheet.dart';
import 'package:c_billing/common_widgets/desktop_stat_bar.dart';
import 'package:c_billing/core/ui/desktop_canvas.dart';

// Lets the desktop shell header open a new event order.
class EventOrderScreenActions {
  static VoidCallback? add;
}

// Date filter options for event/order list
enum DateFilter {
  all,
  thisWeek,
  nextWeek,
  today,
  thisMonth,
  nextMonth,
  thisYear,
  passed,
  custom,
}

// Event Orders List Page - Premium UI Design
class EventOrderListPage extends StatefulWidget {
  final OrderType? filterType;
  final bool isEmbedded;

  const EventOrderListPage({
    super.key,
    this.filterType,
    this.isEmbedded = false,
  });

  @override
  State<EventOrderListPage> createState() => _EventOrderListPageState();
}

class _EventOrderListPageState extends State<EventOrderListPage>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  final _pdfService = EventOrderPdfService();
  String _searchQuery = '';
  OrderStatus? _selectedStatus;
  OrderType? _selectedType;
  String? _processingOrderId;

  // Date filter
  DateFilter _selectedDateFilter = DateFilter.thisWeek;
  DateTime? _customStartDate;
  DateTime? _customEndDate;

  // Sync state
  int _unsyncedCount = 0;
  VoidCallback? _offlineControllerListener;

  // Primary colors - aligned with app theme (availability screen style)
  Color get _primaryColor => AppColors.action(context);
  static const _primaryDark = AppTheme.paletteFF2D6B5A;
  static const _eventColor = AppTheme.purple;
  static const _salesColor = AppTheme.blue;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.filterType;
    EventOrderScreenActions.add = () => _navigateToCreate(context);
    _initSyncService();
  }

  void _initSyncService() {
    // Initialize sync service
    EventOrderSyncService.instance.initialize();

    // Load initial unsynced count
    _loadUnsyncedCount();

    // Listen for offline controller changes
    _offlineControllerListener = () => _loadUnsyncedCount();
    EventOrderOfflineController.instance.addListener(
      _offlineControllerListener!,
    );

    // Also listen for sync service changes
    EventOrderSyncService.instance.addListener(_loadUnsyncedCount);
  }

  Future<void> _loadUnsyncedCount() async {
    final count = await EventOrderOfflineController.instance.getUnsyncedCount();
    if (mounted) {
      setState(() => _unsyncedCount = count);
    }
  }

  @override
  void dispose() {
    EventOrderScreenActions.add = null;
    _searchController.dispose();
    if (_offlineControllerListener != null) {
      EventOrderOfflineController.instance.removeListener(
        _offlineControllerListener!,
      );
    }
    EventOrderSyncService.instance.removeListener(_loadUnsyncedCount);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          EventOrderCubit()..loadEventOrders(filterType: _selectedType),
      child: Builder(
        builder: (context) => Scaffold(
          backgroundColor: AppColors.scaffold(context),
          body: Column(
            children: [
              if (!widget.isEmbedded)
                _buildPremiumAppBar(context)
              else
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 16, 4),
                  child: _eventActionRow(context),
                ),
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(child: _buildStatsSection()),
                    SliverToBoxAdapter(child: _buildSearchAndFilters()),
                    _buildOrdersSliver(),
                  ],
                ),
              ),
            ],
          ),
          floatingActionButton:
              widget.isEmbedded && DesktopCanvas.isDesktopPlatform
              ? null
              : _buildFAB(),
        ),
      ),
    );
  }

  Widget _buildPremiumAppBar(BuildContext context) {
    final l10n = AppLocalizations.of(LanguageService.instance.currentLanguage);
    final title = _selectedType == OrderType.event
        ? l10n.events
        : _selectedType == OrderType.salesOrder
        ? l10n.salesOrders
        : l10n.eventsAndOrders;
    final subtitle = _selectedType == OrderType.event
        ? l10n.manageYourEvents
        : _selectedType == OrderType.salesOrder
        ? l10n.manageYourOrders
        : l10n.manageYourEventsAndOrders;

    return AppTopBar(
      title: title,
      subtitle: subtitle,
      actions: _eventBarActions(context),
    );
  }

  Widget _eventActionRow(BuildContext context) {
    final actions = _eventBarActions(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        for (var i = 0; i < actions.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          actions[i],
        ],
      ],
    );
  }

  List<Widget> _eventBarActions(BuildContext context) {
    final l10n = AppLocalizations.of(LanguageService.instance.currentLanguage);
    return [
        if (_unsyncedCount > 0)
          GestureDetector(
            onTap: () {
              EventOrderSyncService.instance.syncNow();
              GlassyToast.show(context, l10n.syncing);
            },
            child: Chip(
              backgroundColor: AppTheme.toneAmber.withValues(alpha: 0.16),
              avatar: Icon(
                Icons.cloud_upload_rounded,
                size: 16,
                color: AppTheme.toneAmber,
              ),
              label: Text(
                '$_unsyncedCount',
                style: TextStyle(
                  fontFamily: 'Literata',
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: AppTheme.toneAmber,
                ),
              ),
            ),
          ),
        BlocBuilder<EventOrderCubit, EventOrderState>(
          builder: (context, state) {
            final orders = state is EventOrderLoaded ? state.orders : null;
            return AppTopBar.action(
              icon: Icons.summarize_rounded,
              onTap: orders != null && orders.isNotEmpty
                  ? () => _showReportBottomSheet(context, orders)
                  : null,
            );
          },
        ),
        BlocBuilder<EventOrderCubit, EventOrderState>(
          builder: (context, state) {
            return AppTopBar.action(
              icon: Icons.refresh_rounded,
              onTap: () => context.read<EventOrderCubit>().loadEventOrders(
                filterType: _selectedType,
                searchQuery: _searchQuery,
              ),
            );
          },
        ),
        AppTopBar.action(
          icon: Icons.settings_rounded,
          onTap: () => _openSettings(context),
        ),
    ];
  }

  Widget _buildStatsSection() {
    return BlocBuilder<EventOrderCubit, EventOrderState>(
      builder: (context, state) {
        int totalOrders = 0;
        int eventCount = 0;
        int salesCount = 0;
        int pendingCount = 0;
        int confirmedCount = 0;

        if (state is EventOrderLoaded) {
          final orders = state.orders;
          totalOrders = orders.length;
          eventCount = orders
              .where((o) => o.orderType == OrderType.event)
              .length;
          salesCount = orders
              .where((o) => o.orderType == OrderType.salesOrder)
              .length;
          pendingCount = orders
              .where((o) => o.status == OrderStatus.pending)
              .length;
          confirmedCount = orders
              .where((o) => o.status == OrderStatus.confirmed)
              .length;
        }

        final l10n = AppLocalizations.of(
          LanguageService.instance.currentLanguage,
        );
        final expand = widget.isEmbedded;
        final cards = [
          _buildStatCard(
            expand: expand,
            title: l10n.all,
            value: totalOrders,
            icon: Icons.all_inbox_rounded,
            gradient: [_primaryColor, _primaryDark],
            isActive: _selectedType == null,
            onTap: () => _onTypeFilterChanged(context, null),
          ),
          _buildStatCard(
            expand: expand,
            title: l10n.events,
            value: eventCount,
            icon: Icons.celebration_rounded,
            gradient: [_eventColor, AppTheme.purple300],
            isActive: _selectedType == OrderType.event,
            onTap: () => _onTypeFilterChanged(context, OrderType.event),
          ),
          _buildStatCard(
            expand: expand,
            title: l10n.sales,
            value: salesCount,
            icon: Icons.shopping_bag_rounded,
            gradient: [_salesColor, AppTheme.blue300],
            isActive: _selectedType == OrderType.salesOrder,
            onTap: () => _onTypeFilterChanged(context, OrderType.salesOrder),
          ),
          _buildStatCard(
            expand: expand,
            title: l10n.pending,
            value: pendingCount,
            icon: Icons.schedule_rounded,
            gradient: [AppTheme.orange, AppTheme.orangeAccent],
            isActive: _selectedStatus == OrderStatus.pending,
            onTap: () => _onStatusFilterChanged(context, OrderStatus.pending),
          ),
          _buildStatCard(
            expand: expand,
            title: l10n.confirmed,
            value: confirmedCount,
            icon: Icons.check_circle_rounded,
            gradient: [AppTheme.green, AppTheme.lightGreen],
            isActive: _selectedStatus == OrderStatus.confirmed,
            onTap: () =>
                _onStatusFilterChanged(context, OrderStatus.confirmed),
          ),
        ];

        if (widget.isEmbedded && DesktopCanvas.isDesktopPlatform) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 4),
            child: DesktopStatBar(
              stats: [
                DesktopStat(
                  value: '$totalOrders',
                  label: l10n.all,
                  selected: _selectedType == null,
                  onTap: () => _onTypeFilterChanged(context, null),
                ),
                DesktopStat(
                  value: '$eventCount',
                  label: l10n.events,
                  selected: _selectedType == OrderType.event,
                  onTap: () => _onTypeFilterChanged(context, OrderType.event),
                ),
                DesktopStat(
                  value: '$salesCount',
                  label: l10n.sales,
                  selected: _selectedType == OrderType.salesOrder,
                  onTap: () =>
                      _onTypeFilterChanged(context, OrderType.salesOrder),
                ),
                DesktopStat(
                  value: '$pendingCount',
                  label: l10n.pending,
                  selected: _selectedStatus == OrderStatus.pending,
                  onTap: () =>
                      _onStatusFilterChanged(context, OrderStatus.pending),
                ),
                DesktopStat(
                  value: '$confirmedCount',
                  label: l10n.confirmed,
                  selected: _selectedStatus == OrderStatus.confirmed,
                  onTap: () =>
                      _onStatusFilterChanged(context, OrderStatus.confirmed),
                ),
              ],
            ),
          );
        }

        if (widget.isEmbedded) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 4),
            child: Row(
              children: [
                for (var i = 0; i < cards.length; i++) ...[
                  if (i > 0) const SizedBox(width: 12),
                  Expanded(child: cards[i]),
                ],
              ],
            ),
          );
        }

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border(context)),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var i = 0; i < cards.length; i++) ...[
                  if (i > 0) const SizedBox(width: 10),
                  cards[i],
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required int value,
    required IconData icon,
    required List<Color> gradient,
    required bool isActive,
    required VoidCallback onTap,
    bool expand = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: expand ? double.infinity : 76,
        padding: EdgeInsets.symmetric(
          vertical: expand ? 16 : 14,
          horizontal: 8,
        ),
        decoration: BoxDecoration(
          gradient: isActive
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradient,
                )
              : null,
          color: isActive ? null : AppColors.chipFill(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isActive ? AppTheme.transparent : AppColors.border(context),
            width: 1,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: gradient[0].withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Icon(icon, color: isActive ? AppTheme.white : gradient[0], size: 20),
            const SizedBox(height: 8),
            Text(
              value.toString(),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                fontFamily: 'Literata',
                color: isActive ? AppTheme.white : AppColors.primaryText(context),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 9,
                color: isActive
                    ? AppTheme.white.withValues(alpha: 0.85)
                    : AppColors.secondaryText(context),
                fontFamily: 'Literata',
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        widget.isEmbedded ? 24 : 16,
        8,
        widget.isEmbedded ? 24 : 16,
        12,
      ),
      child: Column(
        children: [
          // Search bar
          BlocBuilder<EventOrderCubit, EventOrderState>(
              builder: (context, state) {
                return TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                    context.read<EventOrderCubit>().loadEventOrders(
                      filterType: _selectedType,
                      filterStatus: _selectedStatus,
                      searchQuery: value,
                    );
                  },
                  style: TextStyle(
                    fontFamily: 'Literata',
                    fontSize: 14,
                    color: AppColors.primaryText(context),
                  ),
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(
                      LanguageService.instance.currentLanguage,
                    ).searchEventsOrOrders,
                    hintStyle: TextStyle(
                      color: AppColors.mutedText(context),
                      fontFamily: 'Literata',
                    ),
                    prefixIcon: Container(
                      padding: const EdgeInsets.all(12),
                      child: Icon(
                        Icons.search_rounded,
                        color: _searchQuery.isNotEmpty
                            ? _primaryColor
                            : AppColors.mutedText(context),
                      ),
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Container(
                              padding: EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppColors.border(context),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.close,
                                size: 16,
                                color: AppColors.mutedText(context),
                              ),
                            ),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                              context.read<EventOrderCubit>().loadEventOrders(
                                filterType: _selectedType,
                                filterStatus: _selectedStatus,
                              );
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.inputFill(context),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: AppColors.border(context)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: _primaryColor,
                        width: 1.5,
                      ),
                    ),
                  ),
                );
              },
            ),
          const SizedBox(height: 12),
          // Date filter chips
          _buildDateFilterChips(),
          const SizedBox(height: 12),
          // Active filters row
          BlocBuilder<EventOrderCubit, EventOrderState>(
            builder: (context, state) {
              final allOrders = state is EventOrderLoaded
                  ? state.orders
                  : <EventOrder>[];
              final filteredOrders = _filterOrdersByDate(allOrders);
              final itemCount = filteredOrders.length;
              return Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _primaryColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.list_alt_rounded,
                          size: 14,
                          color: _primaryColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$itemCount orders',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Literata',
                            color: _primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (_selectedStatus != null)
                    GestureDetector(
                      onTap: () => _onStatusFilterChanged(context, null),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.chipFill(context),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.filter_alt_off_rounded,
                              size: 14,
                              color: AppTheme.grey600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Clear status',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Literata',
                                color: AppTheme.grey600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersSliver() {
    return BlocBuilder<EventOrderCubit, EventOrderState>(
      builder: (context, state) {
        if (state is EventOrderLoading) {
          return SliverFillRemaining(
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
              ),
            ),
          );
        }

        if (state is EventOrderError) {
          return SliverFillRemaining(child: _buildErrorState(context));
        }

        if (state is EventOrderLoaded) {
          final allOrders = state.orders;
          final orders = _filterOrdersByDate(allOrders);

          if (orders.isEmpty) {
            return SliverFillRemaining(child: _buildEmptyState());
          }

          return SliverPadding(
            padding: EdgeInsets.fromLTRB(
              widget.isEmbedded ? 24 : 16,
              0,
              widget.isEmbedded ? 24 : 16,
              100,
            ),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildOrderCard(context, orders[index]),
                childCount: orders.length,
              ),
            ),
          );
        }

        return const SliverToBoxAdapter(child: SizedBox());
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: _primaryColor.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _selectedType == OrderType.event
                  ? Icons.celebration_rounded
                  : _selectedType == OrderType.salesOrder
                  ? Icons.shopping_bag_rounded
                  : Icons.event_note_rounded,
              size: 64,
              color: _primaryColor.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _selectedType == OrderType.event
                ? AppLocalizations.of(
                    LanguageService.instance.currentLanguage,
                  ).noEventsFound
                : _selectedType == OrderType.salesOrder
                ? AppLocalizations.of(
                    LanguageService.instance.currentLanguage,
                  ).noSalesOrdersFound
                : AppLocalizations.of(
                    LanguageService.instance.currentLanguage,
                  ).noOrdersFound,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              fontFamily: 'Literata',
              color: AppColors.primaryText(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(
              LanguageService.instance.currentLanguage,
            ).tapToCreateFirstOrder,
            style: TextStyle(
              fontSize: 13,
              fontFamily: 'Literata',
              color: AppColors.mutedText(context),
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.red.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              size: 56,
              color: AppTheme.red,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            AppLocalizations.of(
              LanguageService.instance.currentLanguage,
            ).errorLoadingOrders,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              fontFamily: 'Literata',
              color: AppTheme.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(
              LanguageService.instance.currentLanguage,
            ).pleaseTryAgain,
            style: TextStyle(
              fontSize: 13,
              fontFamily: 'Literata',
              color: AppTheme.grey,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => context.read<EventOrderCubit>().loadEventOrders(
              filterType: _selectedType,
            ),
            icon: const Icon(Icons.refresh_rounded),
            label: Text(
              AppLocalizations.of(
                LanguageService.instance.currentLanguage,
              ).retry,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: AppTheme.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, EventOrder order) {
    final isEvent = order.orderType == OrderType.event;
    final typeColor = isEvent ? _eventColor : _salesColor;
    final statusInfo = _getStatusInfo(order.status);

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: order.status == OrderStatus.pending
              ? AppTheme.orange.withValues(alpha: 0.35)
              : AppColors.border(context),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: AppTheme.transparent,
        child: InkWell(
          onTap: () => _navigateToEdit(context, order),
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    // Type icon
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [typeColor, typeColor.withValues(alpha: 0.7)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: typeColor.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(
                        isEvent
                            ? Icons.celebration_rounded
                            : Icons.shopping_bag_rounded,
                        color: AppTheme.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Title and customer
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.orderName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Literata',
                              color: AppTheme.ink,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.person_outline_rounded,
                                size: 14,
                                color: AppTheme.grey,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  order.customerName,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontFamily: 'Literata',
                                    color: AppTheme.grey600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusInfo['color'].withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            statusInfo['icon'],
                            size: 14,
                            color: statusInfo['color'],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            order.status.displayName,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Literata',
                              color: statusInfo['color'],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Info badges row
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    SyncStatusIcon(
                      isSynced: order.isSynced,
                      size: 16,
                      padded: false,
                    ),
                    _buildInfoBadge(
                      Icons.calendar_today_rounded,
                      DateFormat('dd MMM yyyy').format(order.eventDate),
                      AppTheme.grey600,
                    ),
                    if (isEvent && order.subEvents.isNotEmpty)
                      _buildInfoBadge(
                        Icons.event_note_rounded,
                        '${order.subEvents.length} sub-events',
                        typeColor,
                      ),
                    if (order.items.isNotEmpty)
                      _buildInfoBadge(
                        Icons.shopping_bag_rounded,
                        '${order.items.length} products',
                        isEvent ? AppTheme.green : typeColor,
                      ),
                    if (order.customerContact.isNotEmpty)
                      _buildInfoBadge(
                        Icons.phone_rounded,
                        order.customerContact,
                        AppTheme.grey600,
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                // Amount summary row
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _primaryColor.withValues(alpha: 0.06),
                        _primaryColor.withValues(alpha: 0.02),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildAmountColumn(
                          'Total',
                          order.totalAmount,
                          AppTheme.ink,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 36,
                        color: AppTheme.grey.withValues(alpha: 0.15),
                      ),
                      Expanded(
                        child: _buildAmountColumn(
                          'Advance',
                          order.advanceAmount,
                          AppTheme.green,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 36,
                        color: AppTheme.grey.withValues(alpha: 0.15),
                      ),
                      Expanded(
                        child: _buildAmountColumn(
                          'Due',
                          order.remainingAmount,
                          order.remainingAmount > 0
                              ? AppTheme.orange
                              : AppTheme.green,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                // Action buttons row
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _buildActionButton(
                      context,
                      icon: Icons.receipt_long_rounded,
                      label: 'Invoice',
                      color: AppTheme.teal,
                      isLoading: _processingOrderId == order.id,
                      onTap: () => _showInvoicePreview(context, order),
                    ),
                    const SizedBox(width: 8),
                    _buildActionButton(
                      context,
                      icon: Icons.share_rounded,
                      label: 'Share',
                      color: _primaryColor,
                      isLoading: _processingOrderId == order.id,
                      onTap: () => _shareOrder(context, order),
                    ),
                    const SizedBox(width: 8),
                    _buildActionButton(
                      context,
                      icon: Icons.print_rounded,
                      label: 'Print',
                      color: AppTheme.orange,
                      isLoading: _processingOrderId == order.id,
                      onTap: () => _printOrder(context, order),
                    ),
                    const SizedBox(width: 8),
                    _buildActionButton(
                      context,
                      icon: Icons.delete_outline_rounded,
                      label: 'Delete',
                      color: AppTheme.red,
                      onTap: () => _confirmDelete(context, order),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLoading)
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: color,
                  ),
                )
              else
                Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Literata',
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBadge(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              fontFamily: 'Literata',
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountColumn(String label, double amount, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            fontFamily: 'Literata',
            color: AppColors.mutedText(context),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '₹${_formatAmount(amount)}',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            fontFamily: 'Literata',
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildFAB() {
    return Builder(
      builder: (context) {
        return FloatingActionButton.extended(
          onPressed: () => _navigateToCreate(context),
          backgroundColor: _primaryColor,
          elevation: 4,
          highlightElevation: 8,
          icon: const Icon(Icons.add_rounded, color: AppTheme.white),
          label: const Text(
            'New Order',
            style: TextStyle(
              fontFamily: 'Literata',
              fontWeight: FontWeight.w600,
              color: AppTheme.white,
            ),
          ),
        );
      },
    );
  }

  Map<String, dynamic> _getStatusInfo(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return {'color': AppTheme.orange, 'icon': Icons.schedule_rounded};
      case OrderStatus.confirmed:
        return {'color': AppTheme.blue, 'icon': Icons.check_circle_rounded};
      case OrderStatus.inProgress:
        return {'color': _primaryColor, 'icon': Icons.sync_rounded};
      case OrderStatus.delivered:
        return {'color': AppTheme.green, 'icon': Icons.task_alt_rounded};
      case OrderStatus.cancelled:
        return {'color': AppTheme.red, 'icon': Icons.cancel_rounded};
      case OrderStatus.convertedToBill:
        return {'color': AppTheme.teal, 'icon': Icons.receipt_long_rounded};
    }
  }

  String _formatAmount(double amount) {
    if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.toStringAsFixed(0);
  }

  // Build date filter chips row
  Widget _buildDateFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildDateFilterChip(
            label: 'All',
            filter: DateFilter.all,
            icon: Icons.all_inclusive_rounded,
          ),
          const SizedBox(width: 8),
          _buildDateFilterChip(
            label: 'This Week',
            filter: DateFilter.thisWeek,
            icon: Icons.view_week_rounded,
          ),
          const SizedBox(width: 8),
          _buildDateFilterChip(
            label: 'Next Week',
            filter: DateFilter.nextWeek,
            icon: Icons.next_week_rounded,
          ),
          const SizedBox(width: 8),
          _buildDateFilterChip(
            label: 'Today',
            filter: DateFilter.today,
            icon: Icons.today_rounded,
          ),
          const SizedBox(width: 8),
          _buildDateFilterChip(
            label: 'This Month',
            filter: DateFilter.thisMonth,
            icon: Icons.calendar_month_rounded,
          ),
          const SizedBox(width: 8),
          _buildDateFilterChip(
            label: 'Next Month',
            filter: DateFilter.nextMonth,
            icon: Icons.event_rounded,
          ),
          const SizedBox(width: 8),
          _buildDateFilterChip(
            label: 'This Year',
            filter: DateFilter.thisYear,
            icon: Icons.calendar_today_rounded,
          ),
          const SizedBox(width: 8),
          _buildDateFilterChip(
            label: 'Passed',
            filter: DateFilter.passed,
            icon: Icons.history_rounded,
          ),
          const SizedBox(width: 8),
          _buildDateFilterChip(
            label:
                _selectedDateFilter == DateFilter.custom &&
                    _customStartDate != null
                ? '${DateFormat('dd/MM').format(_customStartDate!)} - ${DateFormat('dd/MM').format(_customEndDate ?? _customStartDate!)}'
                : 'Custom',
            filter: DateFilter.custom,
            icon: Icons.date_range_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildDateFilterChip({
    required String label,
    required DateFilter filter,
    required IconData icon,
  }) {
    final isSelected = _selectedDateFilter == filter;
    return GestureDetector(
      onTap: () => _onDateFilterChanged(filter),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? _primaryColor : AppColors.card(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? _primaryColor
                : AppColors.border(context),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _primaryColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected
                  ? AppTheme.white
                  : AppColors.secondaryText(context),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontFamily: 'Literata',
                color: isSelected
                    ? AppTheme.white
                    : AppColors.primaryText(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onDateFilterChanged(DateFilter filter) async {
    if (filter == DateFilter.custom) {
      await _showCustomDateRangePicker();
    } else {
      setState(() {
        _selectedDateFilter = filter;
        _customStartDate = null;
        _customEndDate = null;
      });
    }
  }

  Future<void> _showCustomDateRangePicker() async {
    final now = DateTime.now();
    final initialRange = DateTimeRange(
      start: _customStartDate ?? now.subtract(const Duration(days: 7)),
      end: _customEndDate ?? now,
    );

    final picked = await showAppRangeCalendar(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 2),
      initialDateRange: initialRange,
    );

    if (picked != null) {
      setState(() {
        _selectedDateFilter = DateFilter.custom;
        _customStartDate = picked.start;
        _customEndDate = picked.end;
      });
    }
  }

  // Get date range based on selected filter Returns null for 'all' and 'passed' filters which need special handling
  (DateTime start, DateTime end)? _getDateRange() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (_selectedDateFilter) {
      case DateFilter.all:
        // Return null to indicate no date filtering
        return null;
      case DateFilter.passed:
        // Return null - will be handled specially in _filterOrdersByDate
        return null;
      case DateFilter.today:
        return (today, today.add(const Duration(days: 1)));
      case DateFilter.thisWeek:
        // Get start of week (Monday)
        final weekStart = today.subtract(Duration(days: today.weekday - 1));
        final weekEnd = weekStart.add(const Duration(days: 7));
        return (weekStart, weekEnd);
      case DateFilter.nextWeek:
        // Get start of next week (Monday)
        final thisWeekStart = today.subtract(Duration(days: today.weekday - 1));
        final nextWeekStart = thisWeekStart.add(const Duration(days: 7));
        final nextWeekEnd = nextWeekStart.add(const Duration(days: 7));
        return (nextWeekStart, nextWeekEnd);
      case DateFilter.thisMonth:
        final monthStart = DateTime(now.year, now.month, 1);
        final monthEnd = DateTime(now.year, now.month + 1, 1);
        return (monthStart, monthEnd);
      case DateFilter.nextMonth:
        final nextMonthStart = DateTime(now.year, now.month + 1, 1);
        final nextMonthEnd = DateTime(now.year, now.month + 2, 1);
        return (nextMonthStart, nextMonthEnd);
      case DateFilter.thisYear:
        final yearStart = DateTime(now.year, 1, 1);
        final yearEnd = DateTime(now.year + 1, 1, 1);
        return (yearStart, yearEnd);
      case DateFilter.custom:
        if (_customStartDate != null) {
          final start = DateTime(
            _customStartDate!.year,
            _customStartDate!.month,
            _customStartDate!.day,
          );
          final end = _customEndDate != null
              ? DateTime(
                  _customEndDate!.year,
                  _customEndDate!.month,
                  _customEndDate!.day,
                ).add(const Duration(days: 1))
              : start.add(const Duration(days: 1));
          return (start, end);
        }
        // Default to this week if no custom dates
        final weekStart = today.subtract(Duration(days: today.weekday - 1));
        final weekEnd = weekStart.add(const Duration(days: 7));
        return (weekStart, weekEnd);
    }
  }

  // Filter orders by date range
  List<EventOrder> _filterOrdersByDate(List<EventOrder> orders) {
    // Handle 'all' filter - return all orders
    if (_selectedDateFilter == DateFilter.all) {
      return orders;
    }

    // Handle 'passed' filter - return orders with event date before today
    if (_selectedDateFilter == DateFilter.passed) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      return orders.where((order) {
        final orderDate = DateTime(
          order.eventDate.year,
          order.eventDate.month,
          order.eventDate.day,
        );
        return orderDate.isBefore(today);
      }).toList();
    }

    final dateRange = _getDateRange();
    if (dateRange == null) return orders;

    final (start, end) = dateRange;
    return orders.where((order) {
      final orderDate = DateTime(
        order.eventDate.year,
        order.eventDate.month,
        order.eventDate.day,
      );
      return orderDate.isAfter(start.subtract(const Duration(days: 1))) &&
          orderDate.isBefore(end);
    }).toList();
  }

  void _onTypeFilterChanged(BuildContext ctx, OrderType? type) {
    setState(() {
      _selectedType = type;
      _selectedStatus = null;
    });
    ctx.read<EventOrderCubit>().loadEventOrders(
      filterType: type,
      searchQuery: _searchQuery,
    );
  }

  void _onStatusFilterChanged(BuildContext ctx, OrderStatus? status) {
    setState(() {
      if (_selectedStatus == status) {
        _selectedStatus = null;
      } else {
        _selectedStatus = status;
      }
    });
    ctx.read<EventOrderCubit>().loadEventOrders(
      filterType: _selectedType,
      filterStatus: _selectedStatus,
      searchQuery: _searchQuery,
    );
  }

  void _navigateToCreate(BuildContext context) async {
    final cubit = context.read<EventOrderCubit>();
    final result = await showAppPage(
      context,
      BlocProvider.value(
        value: cubit,
        child: EventOrderScreen(
          initialMode: _selectedType ?? OrderType.event,
        ),
      ),
    );
    if (result == true) {
      cubit.loadEventOrders(filterType: _selectedType);
    }
  }

  void _navigateToEdit(BuildContext context, EventOrder order) async {
    final cubit = context.read<EventOrderCubit>();
    final result = await showAppPage(
      context,
      BlocProvider.value(
        value: cubit,
        child: EventOrderScreen(existingOrder: order),
      ),
    );
    if (result == true) {
      cubit.loadEventOrders(filterType: _selectedType);
    }
  }

  // Open settings page
  void _openSettings(BuildContext context) async {
    // Capture cubit reference before navigation
    final cubit = context.read<EventOrderCubit>();
    await showAppPage(
      context,
      EventOrderSettingsPage(
          currentType: _selectedType,
          onTypeChanged: (newType) {
            setState(() {
              _selectedType = newType;
            });
            cubit.loadEventOrders(
              filterType: newType,
              searchQuery: _searchQuery,
            );
          },
      ),
    );
  }

  // Show invoice preview with share/print options
  Future<void> _showInvoicePreview(
    BuildContext context,
    EventOrder order,
  ) async {
    if (_processingOrderId != null) {
      debugPrint(
        '[EventOrderList] Already processing order: $_processingOrderId, resetting...',
      );
      // Reset stale state and allow retry
      setState(() => _processingOrderId = null);
      _pdfService.resetGeneratingState();
    }

    setState(() => _processingOrderId = order.id);

    // Clear any existing snackbars first
    GlassyToast.dismiss();

    debugPrint(
      '[EventOrderList] Starting invoice preview for: ${order.orderName}',
    );

    // Track if dialog is shown to ensure proper cleanup
    bool dialogShown = false;

    // Helper to safely close dialog
    void closeDialog() {
      if (dialogShown && mounted) {
        try {
          Navigator.of(context, rootNavigator: true).pop();
          dialogShown = false;
        } catch (e) {
          debugPrint('[EventOrderList] Error closing dialog: $e');
        }
      }
    }

    // Show loading dialog instead of snackbar for better UX
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(color: _primaryColor),
              const SizedBox(width: 20),
              const Expanded(
                child: Text(
                  'Generating invoice...',
                  style: TextStyle(fontFamily: 'Literata'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    dialogShown = true;

    // Allow dialog to render
    await Future.delayed(const Duration(milliseconds: 50));

    try {
      if (!mounted) {
        closeDialog();
        return;
      }

      debugPrint('[EventOrderList] Fetching shop details...');
      Shop shop;
      try {
        shop = await ShopRepository().getShopDetails().timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            debugPrint(
              '[EventOrderList] Shop details timeout, using empty shop',
            );
            return Shop.empty;
          },
        );
        debugPrint('[EventOrderList] Got shop: ${shop.shopName}');
      } catch (shopError) {
        debugPrint(
          '[EventOrderList] Shop fetch error: $shopError, using empty shop',
        );
        shop = Shop.empty;
      }

      if (!mounted) {
        closeDialog();
        return;
      }

      debugPrint('[EventOrderList] Generating PDF...');
      debugPrint(
        '[EventOrderList] Order details - name: ${order.orderName}, type: ${order.orderType}, items: ${order.items.length}, subEvents: ${order.subEvents.length}',
      );

      // Generate PDF document with timeout to prevent hanging
      final pdf = await _pdfService
          .generateEventOrderPdf(order: order, shopDetails: shop)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception('PDF generation timed out. Please try again.');
            },
          );

      debugPrint('[EventOrderList] PDF document generated, saving bytes...');
      final pdfBytes = await pdf.save().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('PDF save timed out. Please try again.');
        },
      );
      debugPrint('[EventOrderList] PDF bytes: ${pdfBytes.length}');

      if (pdfBytes.isEmpty) {
        throw Exception('PDF generation failed - empty result');
      }

      if (kIsWeb) {
        closeDialog();
        if (!mounted || !context.mounted) return;
        setState(() => _processingOrderId = null);
        final title = order.orderType == OrderType.event
            ? 'Event Invoice'
            : 'Order Invoice';
        await FilePreviewPage.open(
        context,
              bytes: pdfBytes,
              fileName: '$title - ${order.orderName}',
              fileType: FilePreviewType.pdf,
              subtitle: DateFormat('dd MMM yyyy').format(order.eventDate),
              customerPhone: order.customerContact,
        );
        return;
      }

      // Save PDF to temp file for preview
      debugPrint('[EventOrderList] Saving PDF to temp file...');
      final tempDir = await Directory.systemTemp.createTemp('invoice_');
      final isEvent = order.orderType == OrderType.event;
      final prefix = isEvent ? 'event_invoice' : 'order_invoice';
      final safeOrderName = order.orderName
          .replaceAll(RegExp(r'[^\w\s]'), '')
          .replaceAll(' ', '_');
      final fileName = '${prefix}_$safeOrderName.pdf';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(pdfBytes);
      debugPrint('[EventOrderList] PDF saved to: ${file.path}');

      // Close loading dialog
      closeDialog();

      if (!mounted || !context.mounted) {
        debugPrint('[EventOrderList] Widget not mounted, returning');
        return;
      }

      // Reset processing state before preview
      setState(() => _processingOrderId = null);

      final title = isEvent ? 'Event Invoice' : 'Order Invoice';

      // Navigate to FilePreviewPage for preview with share/print options
      debugPrint('[EventOrderList] Opening PDF preview...');
      await FilePreviewPage.open(
      context,
            file: file,
            fileName: '$title - ${order.orderName}',
            fileType: FilePreviewType.pdf,
            subtitle: DateFormat('dd MMM yyyy').format(order.eventDate),
            customerPhone: order.customerContact,
      );
      debugPrint('[EventOrderList] PDF preview closed');
    } catch (e, stack) {
      debugPrint('[EventOrderList] ERROR generating invoice: $e');
      debugPrint('[EventOrderList] Stack trace: $stack');

      // Close loading dialog
      closeDialog();

      // Reset PDF service state on error
      _pdfService.resetGeneratingState();

      if (mounted && context.mounted) {
        GlassyToast.show(
          context,
          'Failed to generate invoice: ${e.toString()}',
        );
      }
    } finally {
      debugPrint('[EventOrderList] Finally block - resetting state');
      // Ensure dialog is closed in all cases
      closeDialog();
      if (mounted) {
        setState(() => _processingOrderId = null);
      }
    }
  }

  Future<void> _shareOrder(BuildContext context, EventOrder order) async {
    if (_processingOrderId != null) {
      debugPrint('[EventOrderList] Already processing, resetting state...');
      setState(() => _processingOrderId = null);
      _pdfService.resetGeneratingState();
    }

    setState(() => _processingOrderId = order.id);

    // Show loading indicator
    GlassyToast.show(context, 'Preparing to share...');

    try {
      final shop = await ShopRepository().getShopDetails().timeout(
        const Duration(seconds: 5),
        onTimeout: () => Shop.empty,
      );
      await _pdfService
          .shareOrderAsPdf(order: order, shopDetails: shop)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw Exception('Share timed out'),
          );

      // Clear loading snackbar on success
      if (mounted) {
        GlassyToast.dismiss();
      }
    } catch (e) {
      debugPrint('[EventOrderList] Share error: $e');
      _pdfService.resetGeneratingState();
      if (mounted && context.mounted) {
        GlassyToast.dismiss();
        GlassyToast.show(
          context,
          'Failed to share: ${e.toString()}',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _processingOrderId = null);
      }
    }
  }

  Future<void> _printOrder(BuildContext context, EventOrder order) async {
    if (_processingOrderId != null) {
      debugPrint('[EventOrderList] Already processing, resetting state...');
      setState(() => _processingOrderId = null);
      _pdfService.resetGeneratingState();
    }

    setState(() => _processingOrderId = order.id);

    // Show loading indicator
    GlassyToast.show(context, 'Preparing to print...');

    try {
      final shop = await ShopRepository().getShopDetails().timeout(
        const Duration(seconds: 5),
        onTimeout: () => Shop.empty,
      );
      await _pdfService
          .printOrder(order: order, shopDetails: shop)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw Exception('Print timed out'),
          );

      // Clear loading snackbar on success
      if (mounted) {
        GlassyToast.dismiss();
      }
    } catch (e) {
      debugPrint('[EventOrderList] Print error: $e');
      _pdfService.resetGeneratingState();
      if (mounted && context.mounted) {
        GlassyToast.dismiss();
        GlassyToast.show(
          context,
          'Failed to print: ${e.toString()}',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _processingOrderId = null);
      }
    }
  }

  void _confirmDelete(BuildContext context, EventOrder order) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Delete Order?',
          style: TextStyle(
            fontFamily: 'Literata',
            fontWeight: FontWeight.bold,
            color: AppTheme.ink,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${order.orderName}"? This action cannot be undone.',
          style: TextStyle(fontFamily: 'Literata', color: AppTheme.grey700),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(fontFamily: 'Literata', color: AppTheme.grey600),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              // Extract local ID from order ID
              final orderId = order.id;
              final localId = orderId.startsWith('local_')
                  ? int.parse(orderId.substring(6))
                  : int.tryParse(orderId) ?? 0;
              context.read<EventOrderCubit>().deleteEventOrder(localId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.red,
              foregroundColor: AppTheme.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Delete',
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

  // Show report generation bottom sheet
  void _showReportBottomSheet(
    BuildContext context,
    List<EventOrder> allOrders,
  ) {
    final filteredOrders = _filterOrdersByDate(allOrders);

    showAppBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: BoxDecoration(
          color: AppColors.card(context),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.grey300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.summarize_rounded,
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
                          _selectedType == OrderType.event
                              ? 'Generate Event Report'
                              : _selectedType == OrderType.salesOrder
                              ? 'Generate Order Report'
                              : 'Generate Report',
                          style: const TextStyle(
                            fontFamily: 'Literata',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.ink,
                          ),
                        ),
                        Text(
                          'Export as PDF',
                          style: TextStyle(
                            fontFamily: 'Literata',
                            fontSize: 12,
                            color: AppTheme.grey600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Filter info banner
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _primaryColor.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(_getDateFilterIcon(), color: _primaryColor, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Filter: ${_getDateFilterLabel()}',
                          style: const TextStyle(
                            fontFamily: 'Literata',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.ink,
                          ),
                        ),
                        Text(
                          '${filteredOrders.length} ${_selectedType == OrderType.event
                              ? 'events'
                              : _selectedType == OrderType.salesOrder
                              ? 'orders'
                              : 'items'} will be included',
                          style: TextStyle(
                            fontFamily: 'Literata',
                            fontSize: 12,
                            color: AppTheme.grey600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Summary info
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.scaffold(context),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildReportSummaryItem(
                    'Total Amount',
                    'Rs. ${_formatAmount(filteredOrders.fold(0.0, (total, o) => total + o.totalAmount))}',
                    AppTheme.green,
                  ),
                  Container(height: 30, width: 1, color: AppTheme.grey300),
                  _buildReportSummaryItem(
                    'Advance',
                    'Rs. ${_formatAmount(filteredOrders.fold(0.0, (total, o) => total + o.advanceAmount))}',
                    AppTheme.blue,
                  ),
                  Container(height: 30, width: 1, color: AppTheme.grey300),
                  _buildReportSummaryItem(
                    'Due',
                    'Rs. ${_formatAmount(filteredOrders.fold(0.0, (total, o) => total + o.remainingAmount))}',
                    AppTheme.orange,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Generate Button
            Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: MediaQuery.of(context).padding.bottom + 16,
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: filteredOrders.isEmpty
                      ? null
                      : () {
                          Navigator.pop(ctx);
                          _generateReport(filteredOrders);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.picture_as_pdf, size: 20, color: AppTheme.white),
                      SizedBox(width: 8),
                      Text(
                        'Preview & Generate PDF',
                        style: TextStyle(
                          fontFamily: 'Literata',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Literata',
            fontSize: 10,
            color: AppTheme.grey600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Literata',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  IconData _getDateFilterIcon() {
    switch (_selectedDateFilter) {
      case DateFilter.all:
        return Icons.all_inclusive_rounded;
      case DateFilter.today:
        return Icons.today_rounded;
      case DateFilter.thisWeek:
        return Icons.view_week_rounded;
      case DateFilter.nextWeek:
        return Icons.next_week_rounded;
      case DateFilter.thisMonth:
        return Icons.calendar_month_rounded;
      case DateFilter.nextMonth:
        return Icons.event_rounded;
      case DateFilter.thisYear:
        return Icons.calendar_today_rounded;
      case DateFilter.passed:
        return Icons.history_rounded;
      case DateFilter.custom:
        return Icons.date_range_rounded;
    }
  }

  String _getDateFilterLabel() {
    switch (_selectedDateFilter) {
      case DateFilter.all:
        return 'All Events';
      case DateFilter.today:
        return 'Today';
      case DateFilter.thisWeek:
        return 'This Week';
      case DateFilter.nextWeek:
        return 'Next Week';
      case DateFilter.thisMonth:
        return 'This Month';
      case DateFilter.nextMonth:
        return 'Next Month';
      case DateFilter.thisYear:
        return 'This Year';
      case DateFilter.passed:
        return 'Passed Events';
      case DateFilter.custom:
        if (_customStartDate != null) {
          final start = DateFormat('dd/MM').format(_customStartDate!);
          final end = DateFormat(
            'dd/MM',
          ).format(_customEndDate ?? _customStartDate!);
          return '$start - $end';
        }
        return 'Custom';
    }
  }

  Future<void> _generateReport(List<EventOrder> orders) async {
    try {
      // Show loading
      GlassyToast.show(context, 'Generating report...');

      final isEvent = _selectedType == OrderType.event;
      final filterDesc = _getDateFilterLabel();

      // Fetch shop details for the report header
      Shop? shopDetails;
      try {
        shopDetails = await ShopRepository().getShopDetails().timeout(
          const Duration(seconds: 5),
          onTimeout: () => Shop.empty,
        );
      } catch (e) {
        debugPrint('[EventOrderList] Failed to get shop details: $e');
        shopDetails = Shop.empty;
      }

      // Generate PDF bytes with timeout
      final pdfBytes =
          await EventOrderReportPdfGenerator.generate(
            orders: orders,
            shopDetails: shopDetails,
            filterDescription: filterDesc,
            isEventReport: isEvent,
          ).timeout(
            const Duration(seconds: 45),
            onTimeout: () {
              throw Exception(
                'Report generation timed out. Please try again with fewer orders.',
              );
            },
          );

      if (pdfBytes.isEmpty) {
        throw Exception('Report generation failed - empty result');
      }

      if (kIsWeb) {
        if (mounted) GlassyToast.dismiss();
        if (!mounted) return;
        await FilePreviewPage.open(
          context,
          bytes: pdfBytes,
          fileName: isEvent ? 'Event Report' : 'Order Report',
          fileType: FilePreviewType.pdf,
          subtitle: _getDateFilterLabel(),
          details: FilePreviewDetails(
            title: 'Report preview',
            documentNo: isEvent ? 'Event Report' : 'Order Report',
            dateLabel: _getDateFilterLabel(),
            itemsQty: '${orders.length} ${isEvent ? 'events' : 'orders'}',
          ),
        );
        return;
      }

      // Save to file with timeout
      final file =
          await EventOrderReportPdfGenerator.saveToFile(
            pdfBytes,
            isEvent: isEvent,
          ).timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw Exception('Failed to save report file');
            },
          );

      // Clear snackbar
      if (mounted) {
        GlassyToast.dismiss();
      }

      if (!mounted) return;

      // Navigate to preview
      await FilePreviewPage.open(
        context,
        file: file,
        fileName: isEvent ? 'Event Report' : 'Order Report',
        fileType: FilePreviewType.pdf,
        subtitle: _getDateFilterLabel(),
        details: FilePreviewDetails(
          title: 'Report preview',
          documentNo: isEvent ? 'Event Report' : 'Order Report',
          dateLabel: _getDateFilterLabel(),
          itemsQty: '${orders.length} ${isEvent ? 'events' : 'orders'}',
        ),
      );
    } catch (e) {
      debugPrint('[EventOrderList] Report generation error: $e');
      if (mounted) {
        GlassyToast.dismiss();
        GlassyToast.show(context, 'Failed to generate report: ${e.toString()}');
      }
    }
  }
}
