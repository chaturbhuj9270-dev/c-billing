/// Dashboard Feature Exports
/// 
/// This file provides a clean public API for the dashboard feature
/// following clean architecture principles.

// Domain Layer
export 'domain/entities/dashboard_summary.dart';
export 'domain/repositories/dashboard_repository_interface.dart' hide DashboardFilter;

// Data Layer
export 'data/datasources/dashboard_cache_datasource.dart';
export 'data/datasources/dashboard_firebase_datasource.dart';
export 'data/repositories/dashboard_repository_impl.dart';

// Presentation Layer - Cubit
export 'presentation/cubit/optimized_dashboard_cubit.dart';
export 'presentation/cubit/optimized_dashboard_state.dart';

// Presentation Layer - Pages
export 'presentation/pages/optimized_dashboard_page.dart';

// Presentation Layer - Widgets
export 'presentation/widgets/shimmer_widgets.dart';

// Legacy exports (for backward compatibility)
export 'data/models/dashboard_data.dart';
export 'presentation/cubit/dashboard_cubit.dart';
export 'presentation/cubit/dashboard_state.dart';
