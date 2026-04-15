import 'package:flutter/material.dart';

import '../data/auth/hotel_auth_service.dart';
import '../data/auth/hotel_roles.dart';

/// Access-control wrapper. Shows the child if access is granted,
/// otherwise shows an "Access Denied" message.
class HotelModuleGuard extends StatelessWidget {
  final HotelModule module;
  final Widget child;

  const HotelModuleGuard({
    super.key,
    required this.module,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final auth = HotelAuthService.instance;
    if (auth.hasAccess(module)) return child;

    return Scaffold(
      appBar: AppBar(title: Text(module.label)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Access Denied',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'You do not have permission to access ${module.label}.\nContact your administrator.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
