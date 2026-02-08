## Firestore Collection Structure for Multi-Tenant Shop System

### Collection Hierarchy

```
shops/
  {shopId}
    - id: string (document ID)
    - name: string
    - mainUserId: string (FK to users collection)
    - ownerName: string
    - email: string
    - phone: string
    - address: string
    - pincode: string
    - gstNumber: string
    - createdAt: timestamp
    - updatedAt: timestamp
    - isActive: boolean
    
  users/
    {userId}
      - id: string (Firebase Auth UID)
      - shopId: string (FK to shops collection) ⭐ KEY FOR SECURITY
      - firstName: string
      - middleName: string
      - lastName: string
      - email: string
      - phone: string
      - address: string
      - userType: string (MAIN_USER or SUB_USER)
      - roleIds: array<string>
      - createdAt: timestamp
      - updatedAt: timestamp
      - isActive: boolean
  
  roles/
    {roleId}
      - id: string (document ID)
      - shopId: string (FK to shops collection) ⭐ KEY FOR SECURITY
      - name: string
      - description: string
      - permissionIds: array<string>
      - createdAt: timestamp
      - updatedAt: timestamp
      - isActive: boolean
  
  permissions/
    {permissionId}
      - id: string (document ID)
      - shopId: string (FK to shops collection) ⭐ KEY FOR SECURITY
      - code: string (unique within shop)
      - name: string
      - description: string
      - createdAt: timestamp
```

### Data Flow and Relationships

1. **Shop → User Relationship (1:Many)**
   - Each shop has exactly one Main User
   - A shop can have many Sub Users
   - Query: Get all users for a shop: `users.where('shopId', '==', shopId)`

2. **User → Role Relationship (Many:Many)**
   - Users have array of roleIds
   - Roles are scoped to shops (shopId)
   - Query: Get roles for a user: `roles.where('id', 'in', user.roleIds)`

3. **Role → Permission Relationship (Many:Many)**
   - Roles have array of permissionIds
   - Permissions are scoped to shops (shopId)
   - Query: Get permissions for a role: `permissions.where('id', 'in', role.permissionIds)`

### Security Key Points

⭐ **shopId is the critical security field**
- Present in: users, roles, permissions collections
- Used to enforce multi-tenancy at database query level
- Every read/write operation MUST filter by shopId
- Prevents cross-shop data access

### Query Examples

```
// Get all users in a shop
db.collection('users')
  .where('shopId', '==', currentUserShopId)
  .get()

// Get all roles for a shop
db.collection('roles')
  .where('shopId', '==', currentUserShopId)
  .get()

// Get all permissions for a shop
db.collection('permissions')
  .where('shopId', '==', currentUserShopId)
  .get()

// Get specific user with shop validation
db.collection('users')
  .doc(userId)
  .get()
  // Then verify: user.shopId == currentUserShopId
```

### Indexing Requirements

For optimal performance, create composite indexes:

1. `users` collection:
   - Index on: (shopId, isActive)
   - Index on: (shopId, userType)

2. `roles` collection:
   - Index on: (shopId, isActive)

3. `permissions` collection:
   - Index on: (shopId, code)

### Design Decisions

1. **shopId in every document** - Enables fast filtering and security checks
2. **No nested subcollections** - Simplified querying and security rules
3. **Array fields for relations** - Denormalized for faster reads (roleIds, permissionIds)
4. **Timestamps on all documents** - Audit trail and sorting
5. **isActive flags** - Soft deletes instead of hard deletes
