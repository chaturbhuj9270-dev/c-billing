# High-Performance Dashboard Architecture

## Overview

This document describes the optimized dashboard architecture designed for instant loading and smooth user experience, even on slow network connections.

## Architecture Goals

1. **Instant UI Rendering** - Dashboard renders immediately on app start
2. **Cache-First Strategy** - Load cached data first, refresh in background
3. **Minimal Rebuilds** - Only update UI components that have changed
4. **Parallel Data Fetching** - All Firebase queries run concurrently
5. **Graceful Degradation** - Works offline with cached data

## Folder Structure

```
lib/features/dashboard/
├── domain/                          # Business logic layer
│   ├── entities/
│   │   └── dashboard_summary.dart   # Core data model
│   └── repositories/
│       └── dashboard_repository_interface.dart  # Repository contract
│
├── data/                            # Data access layer
│   ├── datasources/
│   │   ├── dashboard_cache_datasource.dart     # Local cache (SharedPreferences + memory)
│   │   └── dashboard_firebase_datasource.dart  # Firebase Firestore datasource
│   └── repositories/
│       └── dashboard_repository_impl.dart      # Cache-first repository implementation
│
├── presentation/                    # UI layer
│   ├── cubit/
│   │   ├── optimized_dashboard_cubit.dart     # State management
│   │   └── optimized_dashboard_state.dart     # State definitions
│   ├── pages/
│   │   └── optimized_dashboard_page.dart      # Main dashboard UI
│   └── widgets/
│       └── shimmer_widgets.dart               # Loading placeholders
│
└── dashboard.dart                   # Feature exports
```

## Data Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                        APP STARTUP                               │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  1. Cubit Created - Sync load cached data from memory           │
│     └── _loadCachedDataSync() → Immediate UI render             │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  2. Initialize() - Async load from disk cache if needed         │
│     └── Repository.init() → Load SharedPreferences              │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  3. Background Refresh - Fetch fresh data from Firebase         │
│     └── _refreshData() → Parallel Firestore queries             │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  4. Update UI - Smooth transition to fresh data                 │
│     └── AnimatedSwitcher for value updates                      │
└─────────────────────────────────────────────────────────────────┘
```

## Key Components

### DashboardSummary (Domain Entity)

```dart
class DashboardSummary extends Equatable {
  final int invoicesCount;
  final int clientsCount;
  // ... other metrics
  final DateTime lastUpdated;
  final bool isFromCache;
  
  bool isStale({Duration threshold = const Duration(minutes: 5)});
}
```

### DashboardCacheDataSource

- **In-memory cache** for instant synchronous access
- **SharedPreferences** for persistent storage across app restarts
- Automatically loads all cached data to memory on init

```dart
// Synchronous read from memory (instant)
DashboardSummary? getCachedSync(DashboardParams params);

// Async read with disk fallback
Future<DashboardSummary?> getCached(DashboardParams params);
```

### DashboardRepositoryImpl

Implements cache-first strategy:

```dart
Future<DashboardSummary> getDashboardSummary({
  required DashboardParams params,
  bool forceRefresh = false,
}) async {
  // 1. Try cache first (unless force refresh)
  if (!forceRefresh) {
    final cached = await _cacheDataSource.getCached(params);
    if (cached != null) {
      // Trigger background refresh if stale
      if (cached.isStale()) {
        _refreshInBackground(params);
      }
      return cached;
    }
  }
  
  // 2. Fetch from Firebase
  final freshData = await _firebaseDataSource.fetchDashboardData(params: params);
  
  // 3. Save to cache
  await _cacheDataSource.saveToCache(params, freshData);
  
  return freshData;
}
```

### OptimizedDashboardCubit

State management with cache-first loading:

```dart
class OptimizedDashboardCubit extends Cubit<OptimizedDashboardState> {
  OptimizedDashboardCubit(...) : super(const DashboardInitialState()) {
    // INSTANT: Load cached data synchronously in constructor
    _loadCachedDataSync();
  }

  Future<void> initialize() async {
    // BACKGROUND: Fetch fresh data while UI is already rendered
    await _refreshData(showRefreshIndicator: state.hasData);
  }
}
```

### State Classes

```dart
sealed class OptimizedDashboardState {
  final DashboardParams params;
  final DashboardSummary? data;
  final bool isRefreshing;
  bool get hasData => data != null;
  bool get isFromCache => data?.isFromCache ?? false;
}

class DashboardInitialState extends OptimizedDashboardState  // No data, show shimmer
class DashboardReadyState extends OptimizedDashboardState    // Has data, render UI
class DashboardErrorState extends OptimizedDashboardState    // Error but may have cache
```

## Performance Optimizations

### 1. Parallel Firebase Queries

All Firestore queries execute concurrently:

```dart
final results = await Future.wait([
  // Count aggregations (very fast)
  userRef.collection('bills').count().get(),
  userRef.collection('customers').count().get(),
  userRef.collection('products').count().get(),
  userRef.collection('suppliers').count().get(),
  userRef.collection('purchases').count().get(),
  userRef.collection('companies').count().get(),
  // Data queries with filtering
  _getBillsForPeriod(userRef, startDate, endDate, source),
  _getPurchasesForPeriod(userRef, startDate, endDate, source),
  _getProductsSnapshot(userRef, source),
]);
```

### 2. Firestore Cache Utilization

```dart
// Use serverAndCache source to leverage Firestore's built-in cache
final source = forceNetwork ? Source.server : Source.serverAndCache;
query.get(GetOptions(source: source));
```

### 3. Shimmer Loading

Beautiful loading placeholders that match the final UI layout:

```dart
// Shows immediately while data loads
if (!state.hasData && state is DashboardInitialState) {
  return const DashboardShimmerLoading();
}
```

### 4. AnimatedSwitcher for Smooth Updates

Values animate when updated:

```dart
AnimatedSwitcher(
  duration: const Duration(milliseconds: 200),
  child: Text(
    value,
    key: ValueKey(value),  // Triggers animation on change
  ),
)
```

### 5. Incremental State Updates

UI shows cached data while refreshing indicator shows background fetch:

```dart
if (state.hasData) {
  final currentState = state as DashboardReadyState;
  emit(currentState.withRefreshing(true));  // Keep data, show refreshing
}
```

## Usage

### In BlocProvider

```dart
BlocProvider(
  create: (context) {
    final cubit = OptimizedDashboardCubit();
    cubit.initialize();  // Async, doesn't block
    return cubit;
  },
  child: const _DashboardView(),
)
```

### Filter Changes

```dart
context.read<OptimizedDashboardCubit>().changeFilter(DashboardFilter.thisMonth);
```

### Manual Refresh

```dart
context.read<OptimizedDashboardCubit>().refresh();
```

## Migration from Old Dashboard

The new optimized dashboard is a drop-in replacement:

```dart
// Old
import '.../dashboard_page.dart';
const DashboardPage()

// New
import '.../optimized_dashboard_page.dart';
const OptimizedDashboardPage()
```

## Future Improvements

1. **Firestore Dashboard Summary Document** - Store pre-aggregated metrics in a single document updated by Cloud Functions
2. **Real-time Subscriptions** - Use Firestore snapshots for live updates
3. **Background Sync** - Periodic cache refresh using WorkManager
4. **Offline-First** - Full offline support with conflict resolution
