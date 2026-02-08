# Multi-Tenant Shop System - Quick Reference & Checklist

## What Was Implemented

### ✅ Core Features

1. **Multi-Tenancy Enforcement**
   - Each user belongs to exactly one shop
   - Shop ID is the security boundary
   - Cross-shop data access is prevented at database and application level

2. **User Type System**
   - **Main User (Owner/Admin)**
     - Full access to shop data
     - Can create, update, delete sub users
     - Can assign roles and permissions
     - Cannot be deleted
   
   - **Sub User**
     - Limited access based on assigned roles/permissions
     - Can only access their shop's data
     - Cannot manage other users

3. **Role-Based Access Control (RBAC)**
   - Hierarchical: Roles contain Permissions
   - Users assigned multiple Roles
   - Each Role has multiple Permissions
   - Permissions scoped to shop

4. **Database Security**
   - Firestore security rules enforce multi-tenancy
   - shopId field is present on all shop-related documents
   - All queries filtered by shopId
   - Prevent hard deletes (soft delete with isActive flag)

### 📁 File Structure Created

```
lib/
  core/
    models/
      ✅ shop.dart              (Shop entity)
      ✅ shop_user.dart         (ShopUser: Main/Sub user)
      ✅ role.dart              (Role + Permission entities)
    services/
      ✅ shop_access_service.dart           (Multi-tenancy enforcement)
      ✅ user_management_service.dart       (Sub user CRUD)
      ✅ role_permission_service.dart       (Role/permission management)
      ✅ multi_tenant_api_service.dart      (Example API endpoints)
  features/
    shop/
      presentation/
        pages/
          ✅ shop_admin_panel.dart          (Admin UI for user/role management)
            ├─ ShopManagementBloc           (Business logic)
            ├─ ShopAdminPanelPage           (Main admin screen)
            └─ Dialog widgets               (CRUD operation dialogs)

docs/
  ✅ FIRESTORE_SCHEMA.md                    (Database design)
  ✅ FIRESTORE_SECURITY_RULES.md            (Security rules)
  ✅ MULTI_TENANT_IMPLEMENTATION_GUIDE.md   (Integration guide)
  ✅ MULTI_TENANT_QUICK_REFERENCE.md        (This file)
```

## Service APIs Quick Reference

### ShopAccessService

**Multi-tenancy enforcement & validation**

```dart
// Validate user has access to shop
await shopAccessService.validateUserShopAccess(
  userId: 'user_123',
  shopId: 'shop_456',
);

// Check if user is main user
bool isMain = await shopAccessService.isMainUser(
  userId: 'user_123',
  shopId: 'shop_456',
);

// Get user's shop ID
String? shopId = await shopAccessService.getUserShopId('user_123');
```

### UserManagementService

**Create & manage sub users**

```dart
// Create sub user (only main users can do this)
ShopUser newUser = await userManagementService.createSubUser(
  mainUserId: 'current_user_uid',
  shopId: 'shop_123',
  firstName: 'John',
  middleName: 'M',
  lastName: 'Doe',
  email: 'john@example.com',
  phone: '9876543210',
  address: '123 Main St',
  roleIds: ['role_1', 'role_2'],
  subUserId: 'new_user_uid',
);

// Get all users in shop
List<ShopUser> users = await userManagementService.getShopUsers('shop_123');

// Get only sub users
List<ShopUser> subUsers = await userManagementService.getShopSubUsers('shop_123');

// Update sub user
ShopUser updated = await userManagementService.updateSubUser(
  mainUserId: 'current_user_uid',
  subUserId: 'user_456',
  shopId: 'shop_123',
  firstName: 'Jane', // optional updates
);

// Deactivate user (soft delete)
await userManagementService.deactivateUser(
  mainUserId: 'current_user_uid',
  userId: 'user_456',
  shopId: 'shop_123',
);
```

### RolePermissionService

**Manage roles & permissions**

```dart
// Create role
Role role = await rolePermissionService.createRole(
  shopId: 'shop_123',
  name: 'Sales Manager',
  description: 'Can manage sales',
  permissionIds: ['perm_1', 'perm_2'],
);

// Get all roles in shop
List<Role> roles = await rolePermissionService.getShopRoles('shop_123');

// Get user's roles
List<Role> userRoles = await rolePermissionService.getUserRoles(
  userId: 'user_456',
  shopId: 'shop_123',
);

// Assign role to user
await rolePermissionService.assignRoleToUser(
  userId: 'user_456',
  roleId: 'role_1',
  shopId: 'shop_123',
);

// Remove role from user
await rolePermissionService.removeRoleFromUser(
  userId: 'user_456',
  roleId: 'role_1',
  shopId: 'shop_123',
);

// Check if user has permission
bool hasPermission = await rolePermissionService.userHasPermission(
  userId: 'user_456',
  permissionCode: 'create_invoice',
  shopId: 'shop_123',
);

// Get all permissions for user
List<String> permissions = await rolePermissionService.getUserPermissions(
  userId: 'user_456',
  shopId: 'shop_123',
);
```

### MultiTenantApiService

**Example REST-like API endpoints**

```dart
// Create sub user
Map<String, dynamic> result = await apiService.createSubUser(
  mainUserId: 'user_1',
  shopId: 'shop_123',
  subUserId: 'user_2',
  firstName: 'Jane',
  middleName: 'M',
  lastName: 'Smith',
  email: 'jane@example.com',
  phone: '9876543210',
  address: '456 Oak St',
  roleIds: ['role_1'],
);

// Get shop users
Map<String, dynamic> result = await apiService.getShopUsers(
  currentUserId: 'user_1',
  shopId: 'shop_123',
);

// Assign role
Map<String, dynamic> result = await apiService.assignRoleToUser(
  mainUserId: 'user_1',
  userId: 'user_2',
  roleId: 'role_1',
  shopId: 'shop_123',
);

// Check permission
Map<String, dynamic> result = await apiService.checkUserPermission(
  userId: 'user_2',
  shopId: 'shop_123',
  permissionCode: 'create_invoice',
);
```

## Database Operations Checklist

### When Creating Any Document:

- [ ] Add `shopId` field matching user's shop
- [ ] Add `createdAt` timestamp
- [ ] Add `isActive: true` flag
- [ ] Validate user has access to shop before create

```dart
// ✅ CORRECT
await FirebaseFirestore.instance.collection('invoices').add({
  'shopId': currentShopId,         // ⭐ Required
  'amount': 1000,
  'createdAt': DateTime.now(),     // ⭐ Required
  'isActive': true,                // ⭐ Required
  'customerName': 'John',
});

// ❌ WRONG
await FirebaseFirestore.instance.collection('invoices').add({
  'amount': 1000,                  // Missing shopId!
  'customerName': 'John',
});
```

### When Reading/Querying:

- [ ] Always filter by `shopId`
- [ ] Check user has access to shop
- [ ] Only filter by `isActive: true` when needed

```dart
// ✅ CORRECT
final invoices = await FirebaseFirestore.instance
    .collection('invoices')
    .where('shopId', '==', currentShopId)    // ⭐ Required filter
    .where('isActive', '==', true)
    .get();

// ❌ WRONG - Violates multi-tenancy
final invoices = await FirebaseFirestore.instance
    .collection('invoices')
    .get();  // No shop filter!
```

### When Updating:

- [ ] Validate user is main user or owner of document
- [ ] Update `updatedAt` timestamp
- [ ] Never change `shopId` or `createdAt`

```dart
// ✅ CORRECT
await FirebaseFirestore.instance.collection('invoices').doc(id).update({
  'amount': 1500,
  'updatedAt': DateTime.now(),  // ⭐ Update timestamp
});

// ❌ WRONG - Changing shop affiliation
await FirebaseFirestore.instance.collection('invoices').doc(id).update({
  'shopId': 'different_shop',   // ❌ Never change!
});
```

### When Deleting:

- [ ] Use soft delete (set `isActive: false`)
- [ ] Only hard delete for cleanup operations

```dart
// ✅ CORRECT - Soft delete
await FirebaseFirestore.instance.collection('invoices').doc(id).update({
  'isActive': false,
  'deletedAt': DateTime.now(),
});

// ❌ WRONG - Hard delete
await FirebaseFirestore.instance.collection('invoices').doc(id).delete();
```

## Integration Checklist

### Before Deploying:

- [ ] Update all existing collections to include `shopId` field
- [ ] Create Firestore indexes for common queries
- [ ] Deploy Firestore security rules from `FIRESTORE_SECURITY_RULES.md`
- [ ] Test security rules using Rules Simulator
- [ ] Update all data queries to filter by `shopId`
- [ ] Add ShopId to SessionManager/AuthService
- [ ] Create DI setup for all services
- [ ] Add ShopAdminPanelPage to navigation (for main users)
- [ ] Test cross-shop access prevention
- [ ] Test main user vs sub user permissions
- [ ] Configure Firestore indexes for performance

### Adding New Collections:

When adding a new collection (e.g., `expenses`, `inventory`):

1. **Add shopId field** to every document
   ```dart
   {
     'shopId': 'shop_123',
     'itemName': 'Widget',
     'quantity': 50,
   }
   ```

2. **Update Firestore security rules** (add new match block):
   ```firestore
   match /expenses/{expenseId} {
     allow read: if isAuthenticated() && 
                    userBelongsToShop(resource.data.shopId);
     
     allow create: if isAuthenticated() && 
                      userBelongsToShop(request.resource.data.shopId);
     
     allow update: if isAuthenticated() && 
                      userBelongsToShop(resource.data.shopId);
     
     allow delete: if false;
   }
   ```

3. **Update all queries** in code:
   ```dart
   final expenses = await FirebaseFirestore.instance
       .collection('expenses')
       .where('shopId', '==', currentShopId)
       .get();
   ```

4. **Create appropriate indexes** for performance

## Common Patterns

### Get Current User's Shop Context

```dart
// Method 1: From SessionManager
final shopId = sessionManager.currentShopId;

// Method 2: From Service
final shopId = await shopAccessService.getUserShopId(userId);
```

### Fetch Shop-Scoped Data

```dart
// Generic pattern for any collection
final data = await FirebaseFirestore.instance
    .collection('invoices')
    .where('shopId', '==', currentShopId)
    .get();
```

### Check User Permission Before Action

```dart
final canCreate = await rolePermissionService.userHasPermission(
  userId: currentUserId,
  permissionCode: 'create_invoice',
  shopId: currentShopId,
);

if (canCreate) {
  // Show button/perform action
} else {
  // Show permission denied message
}
```

### Create Sub User with Role

```dart
// 1. Create user
final newUser = await userManagementService.createSubUser(
  mainUserId: currentUserId,
  shopId: currentShopId,
  firstName: 'John',
  middleName: 'M',
  lastName: 'Doe',
  email: 'john@example.com',
  phone: '9876543210',
  address: '123 Main St',
  roleIds: [], // Start with no roles
  subUserId: newUserId,
);

// 2. Assign role
await rolePermissionService.assignRoleToUser(
  userId: newUserId,
  roleId: roleId,
  shopId: currentShopId,
);
```

## Error Handling

### ShopAccessDeniedException

Thrown when user violates shop boundaries

```dart
try {
  await shopAccessService.validateUserShopAccess(
    userId: userId,
    shopId: shopId,
  );
} on ShopAccessDeniedException catch (e) {
  print('Access denied: ${e.message}');
  // Show error dialog to user
}
```

### MissingShopContextException

Thrown when shopId or userId is missing

```dart
try {
  await shopAccessService.validateShopExists(shopId);
} on MissingShopContextException catch (e) {
  print('Missing context: ${e.message}');
  // Redirect to login or home
}
```

## Performance Tips

1. **Use pagination** for large user lists:
   ```dart
   .limit(20)
   .startAfter([lastDocSnapshot])
   ```

2. **Index common queries** in Firestore Console

3. **Cache shop data** (shop ID, user type, main user status)

4. **Batch operations** for bulk role assignments:
   ```dart
   final batch = FirebaseFirestore.instance.batch();
   // Add multiple operations
   await batch.commit();
   ```

5. **Monitor Firestore reads** using Analytics

## Security Reminders

⚠️ **Critical Points:**

1. **NEVER trust client-side role checks alone**
   - Always validate on Firestore rules

2. **ALWAYS filter by shopId**
   - Every query must include shop context

3. **NEVER hardcode shopIds**
   - Get from authenticated user's session

4. **NEVER allow changing shopId**
   - Security rule prevents this

5. **ALWAYS validate main user status**
   - Before user management operations

## Support Resources

📚 **Documentation:**
- `FIRESTORE_SCHEMA.md` - Database design details
- `FIRESTORE_SECURITY_RULES.md` - Complete security rules
- `MULTI_TENANT_IMPLEMENTATION_GUIDE.md` - Detailed integration guide

💻 **Code Examples:**
- `multi_tenant_api_service.dart` - REST-like API examples
- `shop_admin_panel.dart` - Complete UI implementation
- Service files - Detailed comments and examples

🔍 **Testing:**
- Use Firestore Rules Simulator to test security
- Test cross-shop access denial
- Verify main vs sub user permissions

---

**Version:** 1.0  
**Last Updated:** January 2026  
**Status:** Production Ready
