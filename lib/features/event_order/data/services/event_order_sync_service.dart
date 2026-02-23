import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import '../../offline/controllers/event_order_offline_controller.dart';
import '../../offline/entities/event_order_entity.dart';
import 'event_order_api_service.dart';

/// Sync status for tracking sync state
enum EventOrderSyncStatusIndicator {
  idle,
  syncing,
  success,
  failed,
}

/// Result of a sync operation
class EventOrderSyncResult {
  final bool success;
  final int uploadedCount;
  final int downloadedCount;
  final int failedCount;
  final String? errorMessage;
  final Duration duration;

  EventOrderSyncResult({
    required this.success,
    this.uploadedCount = 0,
    this.downloadedCount = 0,
    this.failedCount = 0,
    this.errorMessage,
    required this.duration,
  });

  @override
  String toString() {
    if (success) {
      return 'Sync completed: ↑$uploadedCount ↓$downloadedCount';
    }
    return 'Sync failed: $errorMessage';
  }
}

/// Service for background synchronization of Event Order data
/// Handles bidirectional sync between local Isar and remote Firebase
class EventOrderSyncService extends ChangeNotifier {
  static EventOrderSyncService? _instance;

  final EventOrderOfflineController _offlineController;
  final EventOrderApiService _apiService;
  final Connectivity _connectivity;

  EventOrderSyncStatusIndicator _status = EventOrderSyncStatusIndicator.idle;
  DateTime? _lastSyncTime;
  String? _lastError;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _periodicSyncTimer;
  
  /// Mutex to prevent concurrent sync operations
  bool _isSyncing = false;

  EventOrderSyncService._({
    EventOrderOfflineController? offlineController,
    EventOrderApiService? apiService,
    Connectivity? connectivity,
  })  : _offlineController = offlineController ?? EventOrderOfflineController.instance,
        _apiService = apiService ?? EventOrderApiService.instance,
        _connectivity = connectivity ?? Connectivity();

  /// Get the singleton instance
  static EventOrderSyncService get instance {
    _instance ??= EventOrderSyncService._();
    return _instance!;
  }

  /// Current sync status
  EventOrderSyncStatusIndicator get status => _status;

  /// Last successful sync time
  DateTime? get lastSyncTime => _lastSyncTime;

  /// Last error message
  String? get lastError => _lastError;

  /// Check if currently syncing
  bool get isSyncing => _status == EventOrderSyncStatusIndicator.syncing;

  /// Initialize the sync service
  /// Call this after Isar is initialized
  void initialize() {
    debugPrint('[EventOrderSync] Initializing...');
    
    // Listen for connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((result) {
      if (_isConnected(result)) {
        // Back online - trigger sync with delay
        Future.delayed(const Duration(seconds: 2), () {
          if (!_isSyncing) {
            debugPrint('[EventOrderSync] Network available - triggering sync');
            syncNow();
          }
        });
      }
    });

    // Set up periodic sync (every 3 minutes when online)
    _periodicSyncTimer = Timer.periodic(const Duration(minutes: 3), (_) {
      _checkAndSync();
    });
    
    // Initial sync
    _checkAndSync();
    
    debugPrint('[EventOrderSync] Initialized');
  }

  /// Dispose resources
  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _periodicSyncTimer?.cancel();
    super.dispose();
  }

  bool _isConnected(List<ConnectivityResult> results) {
    return results.any((r) => r != ConnectivityResult.none);
  }

  Future<void> _checkAndSync() async {
    final results = await _connectivity.checkConnectivity();
    if (_isConnected(results)) {
      await syncNow();
    }
  }

  /// Check if device is online
  Future<bool> isOnline() async {
    final results = await _connectivity.checkConnectivity();
    return _isConnected(results);
  }

  /// Perform sync now
  /// Returns SyncResult with details of the sync operation
  Future<EventOrderSyncResult> syncNow() async {
    // Prevent concurrent syncs
    if (_isSyncing) {
      return EventOrderSyncResult(
        success: false,
        errorMessage: 'Sync already in progress',
        duration: Duration.zero,
      );
    }

    // Check if user is authenticated
    if (!_apiService.isAuthenticated) {
      debugPrint('[EventOrderSync] User not authenticated, skipping sync');
      return EventOrderSyncResult(
        success: false,
        errorMessage: 'User not authenticated',
        duration: Duration.zero,
      );
    }

    _isSyncing = true;
    final startTime = DateTime.now();
    _status = EventOrderSyncStatusIndicator.syncing;
    _lastError = null;
    notifyListeners();

    int uploadedCount = 0;
    int downloadedCount = 0;
    int failedCount = 0;

    try {
      // Check connectivity
      if (!await isOnline()) {
        throw Exception('No internet connection');
      }

      // Step 1: Push local changes to server
      final pushResult = await _pushLocalChanges();
      uploadedCount = pushResult['uploaded'] ?? 0;
      failedCount = pushResult['failed'] ?? 0;

      // Step 2: Pull changes from server
      downloadedCount = await _pullServerChanges();

      // Step 3: Clean up deleted records
      await _offlineController.purgeDeletedRecords();

      _status = EventOrderSyncStatusIndicator.success;
      _lastSyncTime = DateTime.now();
      _lastError = null;
      notifyListeners();

      return EventOrderSyncResult(
        success: true,
        uploadedCount: uploadedCount,
        downloadedCount: downloadedCount,
        failedCount: failedCount,
        duration: DateTime.now().difference(startTime),
      );
    } catch (e) {
      _status = EventOrderSyncStatusIndicator.failed;
      _lastError = e.toString();
      notifyListeners();

      return EventOrderSyncResult(
        success: false,
        uploadedCount: uploadedCount,
        downloadedCount: downloadedCount,
        failedCount: failedCount,
        errorMessage: e.toString(),
        duration: DateTime.now().difference(startTime),
      );
    } finally {
      _isSyncing = false;
    }
  }

  /// Push local changes to server
  Future<Map<String, int>> _pushLocalChanges() async {
    int uploaded = 0;
    int failed = 0;

    final ordersNeedingPush = await _offlineController.getRecordsToSync();

    for (final order in ordersNeedingPush) {
      try {
        if (order.syncStatus == EventOrderSyncStatus.deleted) {
          // Delete on server
          if (order.serverId != null) {
            await _apiService.deleteEventOrder(order.serverId!);
          }
          // Will be purged in cleanup step
        } else if (order.serverId == null) {
          // Create on server
          final response = await _apiService.createEventOrder(_toSyncPayload(order));
          await _offlineController.markAsSynced(order.id, response['id'] as String);
        } else {
          // Update on server
          await _apiService.updateEventOrder(order.serverId!, _toSyncPayload(order));
          await _offlineController.markAsSynced(order.id, order.serverId!);
        }
        uploaded++;
      } catch (e) {
        debugPrint('[EventOrderSync] Failed to sync order ${order.id}: $e');
        failed++;
      }
    }

    return {'uploaded': uploaded, 'failed': failed};
  }

  /// Convert EventOrderEntity to sync payload
  Map<String, dynamic> _toSyncPayload(EventOrderEntity order) {
    return {
      'orderType': order.orderType,
      'customerId': order.customerId,
      'customerName': order.customerName,
      'customerContact': order.customerContact,
      'customerAddress': order.customerAddress,
      'orderName': order.orderName,
      'description': order.description,
      'eventDate': order.eventDate.toIso8601String(),
      'eventLocation': order.eventLocation,
      'subEvents': order.subEvents.map((e) => {
        'id': e.id,
        'name': e.name,
        'date': e.date?.toIso8601String(),
        'charges': e.charges,
        'notes': e.notes,
        'customDataJson': e.customDataJson,
      }).toList(),
      'items': order.items.map((e) => {
        'id': e.id,
        'productId': e.productId,
        'productName': e.productName,
        'hsnCode': e.hsnCode,
        'quantity': e.quantity,
        'rate': e.rate,
        'discountPercent': e.discountPercent,
        'discountAmount': e.discountAmount,
        'cgstPercent': e.cgstPercent,
        'sgstPercent': e.sgstPercent,
        'cgstAmount': e.cgstAmount,
        'sgstAmount': e.sgstAmount,
        'taxAmount': e.taxAmount,
        'subtotal': e.subtotal,
        'total': e.total,
      }).toList(),
      'eventCharges': order.eventCharges,
      'totalAmount': order.totalAmount,
      'advanceAmount': order.advanceAmount,
      'remainingAmount': order.remainingAmount,
      'notes': order.notes,
      'status': order.status,
      'convertedBillId': order.convertedBillId,
      'customDataJson': order.customDataJson,
      'createdAt': order.createdAt.toIso8601String(),
      'updatedAt': order.updatedAt.toIso8601String(),
    };
  }

  /// Pull changes from server
  Future<int> _pullServerChanges() async {
    try {
      // Get last sync time for incremental sync
      final lastSync = _lastSyncTime;
      
      // Fetch orders from server (with optional since parameter)
      final serverOrders = await _apiService.getEventOrders(
        updatedSince: lastSync,
      );

      if (serverOrders.isNotEmpty) {
        await _importFromServer(serverOrders);
      }

      return serverOrders.length;
    } catch (e) {
      debugPrint('[EventOrderSync] Failed to pull server changes: $e');
      rethrow;
    }
  }

  /// Import orders from server
  Future<void> _importFromServer(List<Map<String, dynamic>> serverOrders) async {
    for (final orderData in serverOrders) {
      try {
        final serverId = orderData['id'] as String?;
        if (serverId == null) continue;

        // Check if exists locally by serverId
        final existing = await _offlineController.getEventOrderByServerId(serverId);

        if (existing != null) {
          // Update existing if server version is newer and local is synced
          if (existing.syncStatus == EventOrderSyncStatus.synced) {
            final serverUpdatedAt = DateTime.tryParse(orderData['updatedAt']?.toString() ?? '');
            if (serverUpdatedAt != null && serverUpdatedAt.isAfter(existing.updatedAt)) {
              await _updateFromServer(existing.id, orderData);
            }
          }
          // If not synced, local changes take precedence
        } else {
          // Create new from server
          await _createFromServer(orderData);
        }
      } catch (e) {
        debugPrint('[EventOrderSync] Failed to import order: $e');
      }
    }
  }

  /// Create order from server data
  Future<void> _createFromServer(Map<String, dynamic> data) async {
    final subEvents = (data['subEvents'] as List<dynamic>?)
        ?.map((e) => SubEventEmbedded(
              id: e['id'] as String?,
              name: e['name'] as String?,
              date: DateTime.tryParse(e['date']?.toString() ?? ''),
              charges: (e['charges'] as num?)?.toDouble() ?? 0.0,
              notes: e['notes'] as String?,
              customDataJson: e['customDataJson'] as String?,
            ))
        .toList() ?? [];

    final items = (data['items'] as List<dynamic>?)
        ?.map((e) => OrderItemEmbedded(
              id: e['id'] as String?,
              productId: e['productId'] as String?,
              productName: e['productName'] as String?,
              hsnCode: e['hsnCode'] as String?,
              quantity: (e['quantity'] as num?)?.toInt() ?? 0,
              rate: (e['rate'] as num?)?.toDouble() ?? 0.0,
              discountPercent: (e['discountPercent'] as num?)?.toDouble() ?? 0.0,
              discountAmount: (e['discountAmount'] as num?)?.toDouble() ?? 0.0,
              cgstPercent: (e['cgstPercent'] as num?)?.toDouble() ?? 0.0,
              sgstPercent: (e['sgstPercent'] as num?)?.toDouble() ?? 0.0,
              cgstAmount: (e['cgstAmount'] as num?)?.toDouble() ?? 0.0,
              sgstAmount: (e['sgstAmount'] as num?)?.toDouble() ?? 0.0,
              taxAmount: (e['taxAmount'] as num?)?.toDouble() ?? 0.0,
              subtotal: (e['subtotal'] as num?)?.toDouble() ?? 0.0,
              total: (e['total'] as num?)?.toDouble() ?? 0.0,
            ))
        .toList() ?? [];

    final entity = EventOrderEntity(
      serverId: data['id'] as String?,
      orderType: (data['orderType'] as num?)?.toInt() ?? 0,
      customerId: data['customerId'] as String?,
      customerName: data['customerName'] as String? ?? '',
      customerContact: data['customerContact'] as String? ?? '',
      customerAddress: data['customerAddress'] as String?,
      orderName: data['orderName'] as String? ?? '',
      description: data['description'] as String?,
      eventDate: DateTime.tryParse(data['eventDate']?.toString() ?? '') ?? DateTime.now(),
      eventLocation: data['eventLocation'] as String?,
      subEvents: subEvents,
      items: items,
      eventCharges: (data['eventCharges'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (data['totalAmount'] as num?)?.toDouble() ?? 0.0,
      advanceAmount: (data['advanceAmount'] as num?)?.toDouble() ?? 0.0,
      remainingAmount: (data['remainingAmount'] as num?)?.toDouble() ?? 0.0,
      notes: data['notes'] as String?,
      status: (data['status'] as num?)?.toInt() ?? 0,
      convertedBillId: data['convertedBillId'] as String?,
      customDataJson: data['customDataJson'] as String?,
      createdAt: DateTime.tryParse(data['createdAt']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(data['updatedAt']?.toString() ?? '') ?? DateTime.now(),
      syncStatus: EventOrderSyncStatus.synced,
    );

    await _offlineController.importEventOrder(entity);
  }

  /// Update order from server data
  Future<void> _updateFromServer(int localId, Map<String, dynamic> data) async {
    await _offlineController.updateFromServer(localId, data);
  }

  /// Force full refresh from server
  Future<EventOrderSyncResult> forceFullRefresh() async {
    if (_status == EventOrderSyncStatusIndicator.syncing) {
      return EventOrderSyncResult(
        success: false,
        errorMessage: 'Sync already in progress',
        duration: Duration.zero,
      );
    }

    final startTime = DateTime.now();
    _status = EventOrderSyncStatusIndicator.syncing;
    _lastError = null;
    notifyListeners();

    try {
      // Get all orders from server
      final serverOrders = await _apiService.getEventOrders();
      
      // Import all
      await _importFromServer(serverOrders);

      _status = EventOrderSyncStatusIndicator.success;
      _lastSyncTime = DateTime.now();
      notifyListeners();

      return EventOrderSyncResult(
        success: true,
        downloadedCount: serverOrders.length,
        duration: DateTime.now().difference(startTime),
      );
    } catch (e) {
      _status = EventOrderSyncStatusIndicator.failed;
      _lastError = e.toString();
      notifyListeners();

      return EventOrderSyncResult(
        success: false,
        errorMessage: e.toString(),
        duration: DateTime.now().difference(startTime),
      );
    }
  }

  /// Get number of pending sync items
  Future<int> getPendingSyncCount() async {
    final records = await _offlineController.getRecordsToSync();
    return records.length;
  }
}
