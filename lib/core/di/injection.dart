import 'package:get_it/get_it.dart';
import '../../features/dashboard/data/datasources/dashboard_cache_datasource.dart';
import '../../features/dashboard/data/datasources/dashboard_firebase_datasource.dart';
import '../../features/dashboard/data/repositories/dashboard_repository_impl.dart';
import '../../features/dashboard/presentation/cubit/optimized_dashboard_cubit.dart';

final GetIt sl = GetIt.instance;

Future<void> init() async {
  // Dashboard Feature
  await _initDashboard();
}

Future<void> _initDashboard() async {
  // Data Sources
  sl.registerLazySingleton<DashboardCacheDataSource>(
    () => DashboardCacheDataSource(),
  );
  
  sl.registerLazySingleton<DashboardFirebaseDataSource>(
    () => DashboardFirebaseDataSource(),
  );

  // Repository
  sl.registerLazySingleton<DashboardRepositoryImpl>(
    () => DashboardRepositoryImpl(
      cacheDataSource: sl<DashboardCacheDataSource>(),
      firebaseDataSource: sl<DashboardFirebaseDataSource>(),
    ),
  );

  // Initialize cache early for instant dashboard loading
  final cacheDataSource = sl<DashboardCacheDataSource>();
  await cacheDataSource.init();
  
  // Cubit - factory so each screen gets fresh instance
  sl.registerFactory<OptimizedDashboardCubit>(
    () => OptimizedDashboardCubit(
      repository: sl<DashboardRepositoryImpl>(),
    ),
  );
}
