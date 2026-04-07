/// Defines the available app flavors.
enum AppFlavor { retail, hotel }

/// Singleton that holds the current flavor context for the running app.
class FlavorConfig {
  static FlavorConfig? _instance;

  final AppFlavor flavor;
  final String appName;

  FlavorConfig._internal({required this.flavor, required this.appName});

  /// Initialize the flavor config. Must be called before runApp().
  static void initialize({required AppFlavor flavor}) {
    _instance = FlavorConfig._internal(
      flavor: flavor,
      appName: flavor == AppFlavor.retail ? 'C-Billing' : 'C-Hotel',
    );
  }

  static FlavorConfig get instance {
    assert(_instance != null, 'FlavorConfig.initialize() must be called first');
    return _instance!;
  }

  bool get isRetail => flavor == AppFlavor.retail;
  bool get isHotel => flavor == AppFlavor.hotel;
}
