// Firestore Security Rules for Multi-Tenant Shop System
// 
// Key Security Principles:
// 1. All data is scoped to shops via shopId field
// 2. Users can only access data from their own shop
// 3. Main Users have full shop access
// 4. Sub Users have limited access based on roles/permissions
// 5. No cross-shop data access is possible

rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // ==========================================
    // Helper Functions
    // ==========================================
    
    // Check if user is authenticated
    function isAuthenticated() {
      return request.auth != null;
    }
    
    // Get current user's shop ID
    function getUserShopId() {
      return get(/databases/$(database)/documents/users/$(request.auth.uid)).data.shopId;
    }
    
    // Check if user is Main User (owner/admin)
    function isMainUser(shopId) {
      let userData = get(/databases/$(database)/documents/users/$(request.auth.uid)).data;
      return userData.shopId == shopId && userData.userType == 'mainUser';
    }
    
    // Check if user is Sub User
    function isSubUser(shopId) {
      let userData = get(/databases/$(database)/documents/users/$(request.auth.uid)).data;
      return userData.shopId == shopId && userData.userType == 'subUser';
    }
    
    // Check if user belongs to shop
    function userBelongsToShop(shopId) {
      let userData = get(/databases/$(database)/documents/users/$(request.auth.uid)).data;
      return userData.shopId == shopId && userData.isActive == true;
    }
    
    // Check if user has a specific role in their shop
    function userHasRole(roleId) {
      let userData = get(/databases/$(database)/documents/users/$(request.auth.uid)).data;
      return roleId in userData.roleIds;
    }
    
    // Check if role belongs to user's shop
    function roleInUserShop(roleId) {
      let userShopId = getUserShopId();
      return get(/databases/$(database)/documents/roles/$(roleId)).data.shopId == userShopId;
    }
    
    // ==========================================
    // SHOPS Collection Rules
    // ==========================================
    match /shops/{shopId} {
      
      // User can read shop only if they belong to it
      allow read: if isAuthenticated() && 
                     userBelongsToShop(shopId);
      
      // Only Main User can update shop details
      allow update: if isAuthenticated() && 
                       isMainUser(shopId) &&
                       // Prevent changing mainUserId
                       (!request.resource.data.diff(resource.data).affectedKeys().hasAny(['mainUserId']));
      
      // Only admins can delete (for backend use only)
      allow delete: if false;
      
      // Only backend service can create new shops
      allow create: if false;
    }
    
    // ==========================================
    // USERS Collection Rules
    // ==========================================
    match /users/{userId} {
      
      // User can read their own profile
      allow read: if isAuthenticated() && 
                     (request.auth.uid == userId || 
                      // Main User can read other users in their shop
                      (isMainUser(resource.data.shopId) && 
                       userBelongsToShop(resource.data.shopId)));
      
      // User can update their own profile (limited fields)
      allow update: if isAuthenticated() && request.auth.uid == userId &&
                       // Prevent changing critical fields
                       !request.resource.data.diff(resource.data).affectedKeys()
                         .hasAny(['shopId', 'userType', 'isActive', 'roleIds', 'createdAt']);
      
      // Main User can update other users (sub users)
      allow update: if isAuthenticated() && 
                       isMainUser(resource.data.shopId) &&
                       resource.data.userType == 'subUser' &&
                       // Prevent changing shopId or userType
                       !request.resource.data.diff(resource.data).affectedKeys()
                         .hasAny(['shopId', 'userType', 'createdAt']);
      
      // Only backend can create users
      allow create: if false;
      
      // Only backend can delete users
      allow delete: if false;
      
      // List all users in current user's shop
      allow list: if isAuthenticated();
    }
    
    // ==========================================
    // ROLES Collection Rules
    // ==========================================
    match /roles/{roleId} {
      
      // User can read roles from their shop
      allow read: if isAuthenticated() && 
                     userBelongsToShop(resource.data.shopId);
      
      // Only Main User can create roles in their shop
      allow create: if isAuthenticated() && 
                       isMainUser(request.resource.data.shopId);
      
      // Only Main User can update roles in their shop
      allow update: if isAuthenticated() && 
                       isMainUser(resource.data.shopId) &&
                       // Prevent changing shopId
                       !request.resource.data.diff(resource.data).affectedKeys()
                         .hasAny(['shopId', 'createdAt']);
      
      // Only Main User can delete (soft delete) roles
      allow delete: if isAuthenticated() && 
                       isMainUser(resource.data.shopId);
      
      // List roles from current user's shop
      allow list: if isAuthenticated();
    }
    
    // ==========================================
    // PERMISSIONS Collection Rules
    // ==========================================
    match /permissions/{permissionId} {
      
      // User can read permissions from their shop
      allow read: if isAuthenticated() && 
                     userBelongsToShop(resource.data.shopId);
      
      // Only Main User can create permissions
      allow create: if isAuthenticated() && 
                       isMainUser(request.resource.data.shopId);
      
      // Only Main User can update permissions
      allow update: if isAuthenticated() && 
                       isMainUser(resource.data.shopId) &&
                       // Prevent changing shopId and code
                       !request.resource.data.diff(resource.data).affectedKeys()
                         .hasAny(['shopId', 'code', 'createdAt']);
      
      // Only Main User can delete permissions
      allow delete: if isAuthenticated() && 
                       isMainUser(resource.data.shopId);
      
      // List permissions from current user's shop
      allow list: if isAuthenticated();
    }
    
    // ==========================================
    // Additional Collections (Invoices, Reports, etc.)
    // ==========================================
    // Apply these rules to any shop-scoped data collections
    
    match /invoices/{invoiceId} {
      // Only allow access if invoice belongs to user's shop
      allow read: if isAuthenticated() && 
                     userBelongsToShop(resource.data.shopId);
      
      allow create: if isAuthenticated() && 
                       userBelongsToShop(request.resource.data.shopId);
      
      allow update: if isAuthenticated() && 
                       userBelongsToShop(resource.data.shopId);
      
      allow delete: if false; // Soft deletes only
    }
    
    match /customers/{customerId} {
      allow read: if isAuthenticated() && 
                     userBelongsToShop(resource.data.shopId);
      
      allow create: if isAuthenticated() && 
                       userBelongsToShop(request.resource.data.shopId);
      
      allow update: if isAuthenticated() && 
                       userBelongsToShop(resource.data.shopId);
      
      allow delete: if false;
    }
    
    match /suppliers/{supplierId} {
      allow read: if isAuthenticated() && 
                     userBelongsToShop(resource.data.shopId);
      
      allow create: if isAuthenticated() && 
                       userBelongsToShop(request.resource.data.shopId);
      
      allow update: if isAuthenticated() && 
                       userBelongsToShop(resource.data.shopId);
      
      allow delete: if false;
    }
    
    match /reports/{reportId} {
      allow read: if isAuthenticated() && 
                     userBelongsToShop(resource.data.shopId);
      
      allow create: if isAuthenticated() && 
                       userBelongsToShop(request.resource.data.shopId);
      
      allow delete: if false;
    }
    
    // ==========================================
    // Deny All Other Access
    // ==========================================
    match /{document=**} {
      allow read, write: if false;
    }
  }
}

// ==========================================
// Deployment Instructions
// ==========================================
// 
// 1. Go to Firebase Console
// 2. Navigate to Firestore Database
// 3. Go to Rules tab
// 4. Replace existing rules with the above content
// 5. Click "Publish"
//
// IMPORTANT: Before deploying to production:
// - Test rules thoroughly using Firestore Rules Simulator
// - Verify cross-shop access is denied
// - Test both Main User and Sub User access patterns
// - Monitor Firestore logs for denied requests
