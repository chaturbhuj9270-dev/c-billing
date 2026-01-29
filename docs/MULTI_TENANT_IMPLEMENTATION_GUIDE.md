# Multi-Tenant Shop User System - Implementation Guide

## Overview

This guide explains how to integrate the multi-tenant shop user system with role-based access control (RBAC) into your C-Billing Flutter application.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Flutter UI Layer                         │
│  (ShopAdminPanel, UserManagement, RoleAssignment screens)  │
└──────────────────┬──────────────────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────────────────┐
│                   BLoC/Services Layer                        │
│  ├─ ShopManagementBloc                                      │
│  ├─ MultiTenantApiService                                  │
│  ├─ UserManagementService                                  │
│  ├─ RolePermissionService                                  │
│  └─ ShopAccessService                                      │
└──────────────────┬──────────────────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────────────────┐
│              Firestore Database Layer                        │
│  ├─ shops/                                                  │
│  ├─ users/ (with shopId foreign key)                       │
│  ├─ roles/ (with shopId foreign key)                       │
│  ├─ permissions/ (with shopId foreign key)                 │
│  └─ [Other collections: invoices, customers, etc]          │
└──────────────────┬──────────────────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────────────────┐
│         Firestore Security Rules Layer                      │
│  (Enforces shop-scoped access, prevents cross-shop data)   │
└─────────────────────────────────────────────────────────────┘
```

## Key Files Created

### Models
- **`lib/core/models/shop.dart`** - Shop entity model
- **`lib/core/models/shop_user.dart`** - ShopUser entity model (Main/Sub user)
- **`lib/core/models/role.dart`** - Role and Permission entity models

### Services
- **`lib/core/services/shop_access_service.dart`** - Multi-tenancy enforcement service
- **`lib/core/services/user_management_service.dart`** - Sub user CRUD operations
- **`lib/core/services/role_permission_service.dart`** - Role and permission management
- **`lib/core/services/multi_tenant_api_service.dart`** - Example API endpoints

### UI
- **`lib/features/shop/presentation/pages/shop_admin_panel.dart`** - Admin panel for managing users/roles
  - ShopManagementBloc - Business logic layer
  - ShopAdminPanelPage - Main admin interface
  - Dialog widgets for CRUD operations

### Documentation
- **`docs/FIRESTORE_SCHEMA.md`** - Database schema design
- **`docs/FIRESTORE_SECURITY_RULES.md`** - Security rules for Firestore

## Integration Steps

### 1. Update Firebase Project Structure

Navigate to Firebase Console and create the Firestore collections:

```
shops/
  {shopId1}/
    name: "ABC Retail"
    mainUserId: "user_123"
    ownerName: "John Doe"
    ...
    
users/
  {userId1}/
    shopId: "shop_1"
    firstName: "John"
    userType: "mainUser"
    roleIds: []
    ...
  
  {userId2}/
    shopId: "shop_1"
    firstName: "Jane"
    userType: "subUser"
    roleIds: ["role_1", "role_2"]
    ...

roles/
  {roleId1}/
    shopId: "shop_1"
    name: "Sales Manager"
    permissionIds: ["perm_1", "perm_2"]
    ...

permissions/
  {permId1}/
    shopId: "shop_1"
    code: "create_invoice"
    name: "Create Invoice"
    ...
```

### 2. Deploy Firestore Security Rules

1. Copy content from `docs/FIRESTORE_SECURITY_RULES.md`
2. Go to Firebase Console → Firestore Database → Rules
3. Replace existing rules with the new rules
4. Test rules using Firestore Rules Simulator before publishing
5. Click "Publish"

### 3. Integrate Services into App

#### Update `main.dart` or your service locator:

```dart
// Using GetIt or your DI solution
final getIt = GetIt.instance;

void setupServiceLocator() {
  // Firestore
  final firestore = FirebaseFirestore.instance;
  
  // Register core services
  getIt.registerSingleton<ShopAccessService>(
    ShopAccessService(firestore: firestore),
  );
  
  getIt.registerSingleton<UserManagementService>(
    UserManagementService(
      firestore: firestore,
      shopAccessService: getIt<ShopAccessService>(),
    ),
  );
  
  getIt.registerSingleton<RolePermissionService>(
    RolePermissionService(
      firestore: firestore,
      shopAccessService: getIt<ShopAccessService>(),
    ),
  );
  
  getIt.registerSingleton<MultiTenantApiService>(
    MultiTenantApiService(
      firestore: firestore,
      shopAccessService: getIt<ShopAccessService>(),
      userManagementService: getIt<UserManagementService>(),
      rolePermissionService: getIt<RolePermissionService>(),
    ),
  );
  
  // Register BLoC
  getIt.registerFactory(() => ShopManagementBloc(
    userManagementService: getIt<UserManagementService>(),
    rolePermissionService: getIt<RolePermissionService>(),
    shopAccessService: getIt<ShopAccessService>(),
    currentUserId: FirebaseAuth.instance.currentUser?.uid ?? '',
  ));
}
```

### 4. Add ShopId to User Session

Update your `SessionManager` or authentication service:

```dart
class SessionManager {
  String? _currentUserId;
  String? _currentShopId;
  UserType? _userType;

  Future<void> initializeSession(String userId) async {
    _currentUserId = userId;
    
    // Fetch user from Firestore to get shop context
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();
    
    if (userDoc.exists) {
      final data = userDoc.data() as Map<String, dynamic>;
      _currentShopId = data['shopId'];
      _userType = data['userType'] == 'mainUser' 
          ? UserType.mainUser 
          : UserType.subUser;
    }
  }

  String get currentShopId => _currentShopId ?? '';
  String get currentUserId => _currentUserId ?? '';
  UserType get userType => _userType ?? UserType.subUser;
  bool get isMainUser => _userType == UserType.mainUser;
}
```

### 5. Protect Data Collections

For all your existing collections (invoices, customers, suppliers, etc.), add `shopId` field:

```dart
// When creating an invoice
final invoice = {
  'id': invoiceId,
  'shopId': currentShopId, // ⭐ CRITICAL: Add shop context
  'customerName': 'John Doe',
  'amount': 1000,
  'createdAt': DateTime.now(),
  // ... other fields
};

// When querying invoices - ALWAYS filter by shopId
final invoices = await FirebaseFirestore.instance
    .collection('invoices')
    .where('shopId', '==', currentShopId) // ⭐ Security-critical filter
    .get();
```

### 6. Add Navigation to Admin Panel

Update your flyout menu to include Shop Admin option for main users:

```dart
// In FlyoutMenu or MainMenu
if (isMainUser) {
  ListTile(
    leading: const Icon(Icons.admin_panel_settings),
    title: const Text('Shop Admin'),
    onTap: () {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => BlocProvider(
            create: (context) => ShopManagementBloc(
              userManagementService: getIt<UserManagementService>(),
              rolePermissionService: getIt<RolePermissionService>(),
              shopAccessService: getIt<ShopAccessService>(),
              currentUserId: currentUserId,
            ),
            child: ShopAdminPanelPage(
              shopId: currentShopId,
              currentUserId: currentUserId,
            ),
          ),
        ),
      );
    },
  );
}
```

## Usage Examples

### Creating a Sub User

```dart
final apiService = getIt<MultiTenantApiService>();

final result = await apiService.createSubUser(
  mainUserId: 'current_user_uid',
  shopId: 'shop_123',
  subUserId: 'new_user_uid',
  firstName: 'Jane',
  middleName: 'M',
  lastName: 'Smith',
  email: 'jane@example.com',
  phone: '9876543210',
  address: '456 Oak St',
  roleIds: ['role_sales', 'role_reports'],
);

if (result['success']) {
  print('Sub user created: ${result['data']}');
} else {
  print('Error: ${result['error']}');
}
```

### Assigning a Role to a User

```dart
final rolePermissionService = getIt<RolePermissionService>();

await rolePermissionService.assignRoleToUser(
  userId: 'user_456',
  roleId: 'role_sales',
  shopId: 'shop_123',
);
```

### Checking User Permissions

```dart
final hasPermission = await rolePermissionService.userHasPermission(
  userId: 'user_456',
  permissionCode: 'create_invoice',
  shopId: 'shop_123',
);

if (hasPermission) {
  // Show create invoice button
}
```

### Getting Shop-Scoped Data

```dart
// WRONG: No shop context - violates security
final allCustomers = await FirebaseFirestore.instance
    .collection('customers')
    .get(); // ❌ INSECURE

// CORRECT: With shop context
final currentShopId = sessionManager.currentShopId;
final customers = await FirebaseFirestore.instance
    .collection('customers')
    .where('shopId', '==', currentShopId) // ✅ SECURE
    .get();
```

## Security Best Practices

### ✅ DO:

1. **Always validate shop access** before any data operation
   ```dart
   await shopAccessService.validateUserShopAccess(
     userId: userId,
     shopId: shopId,
   );
   ```

2. **Include shopId in every query**
   ```dart
   .where('shopId', '==', currentShopId)
   ```

3. **Check main user status before management operations**
   ```dart
   final isMainUser = await shopAccessService.isMainUser(
     userId: userId,
     shopId: shopId,
   );
   ```

4. **Use Firestore security rules** as a second layer of defense

5. **Soft delete users** instead of hard deletes (set `isActive: false`)

### ❌ DON'T:

1. **Never skip shopId validation**
   ```dart
   // ❌ BAD
   await FirebaseFirestore.instance.collection('invoices').get();
   
   // ✅ GOOD
   await FirebaseFirestore.instance
       .collection('invoices')
       .where('shopId', '==', currentShopId)
       .get();
   ```

2. **Never trust client-side role checks alone**
   - Always validate on backend/Firestore rules

3. **Never allow users to change their shop affiliation**

4. **Never expose sub users to main user operations**
   - Validate that the target user is a sub user before operations

## Testing Multi-Tenancy

### Using Firestore Rules Simulator

1. Go to Firestore Database → Rules tab
2. Click "Rules Playground" at the top
3. Test scenarios:

```
// Test 1: User A (shop_1) reading shop_1 data ✅ ALLOW
Request: read from shops/shop_1
Auth UID: user_shop1_main
User shopId: shop_1
→ Should ALLOW

// Test 2: User A (shop_1) reading shop_2 data ❌ DENY
Request: read from users/user_shop2_sub
Auth UID: user_shop1_main
User shopId: shop_1 (different from target user's shop)
→ Should DENY with 403

// Test 3: Sub User creating role ❌ DENY
Request: create role in shop_1
Auth UID: user_shop1_sub
User userType: subUser
→ Should DENY (only main users can create roles)
```

## Data Migration

If migrating from existing system:

```dart
Future<void> migrateExistingData() async {
  // 1. Add shopId to existing users
  final usersSnapshot = await FirebaseFirestore.instance
      .collection('users')
      .where('shopId', isNotEqualTo: null)
      .get();
  
  // If no shopId, assign to default shop
  for (final doc in usersSnapshot.docs) {
    final data = doc.data();
    if (data['shopId'] == null) {
      await doc.reference.update({
        'shopId': 'default_shop_id',
      });
    }
  }
  
  // 2. Similarly for other collections
}
```

## Troubleshooting

### "ShopAccessDeniedException: Access denied"

**Cause:** User trying to access data from different shop
**Solution:** Verify `shopId` in request matches user's `shopId`

### "Permission denied for default:resource"

**Cause:** Firestore security rules blocking operation
**Solution:** 
1. Check rules are properly deployed
2. Verify user is authenticated
3. Check user's shopId matches resource's shopId

### Sub user can't see their own data

**Cause:** Data missing `shopId` field
**Solution:** Add `shopId` to all documents in all collections

## Performance Optimization

### Indexes to Create

In Firebase Console → Firestore → Indexes:

```
Collection: users
Fields: (shopId: Ascending, isActive: Ascending)

Collection: users
Fields: (shopId: Ascending, userType: Ascending)

Collection: invoices
Fields: (shopId: Ascending, createdAt: Descending)

Collection: customers
Fields: (shopId: Ascending, name: Ascending)

Collection: roles
Fields: (shopId: Ascending, isActive: Ascending)
```

### Query Optimization

```dart
// ❌ Inefficient: Returns all users then filters
final allUsers = await db.collection('users').get();
final shopUsers = allUsers.docs
    .where((d) => d['shopId'] == shopId)
    .toList();

// ✅ Efficient: Filters at database level
final shopUsers = await db.collection('users')
    .where('shopId', '==', shopId)
    .get();
```

## Support & Reference

For more details:
- See `docs/FIRESTORE_SCHEMA.md` for database schema
- See `docs/FIRESTORE_SECURITY_RULES.md` for complete security rules
- See `lib/core/services/` for service implementations
- See `lib/features/shop/presentation/pages/shop_admin_panel.dart` for UI examples
