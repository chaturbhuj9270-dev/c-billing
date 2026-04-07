import 'package:c_billing/core/flavor/app_flavor.dart';
import 'package:c_billing/main.dart' as app;

Future<void> main() async {
  FlavorConfig.initialize(flavor: AppFlavor.hotel);
  await app.main();
}
