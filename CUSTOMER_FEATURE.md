# Customer Page Feature

## Overview
The Customer Page allows logged-in users to manage their customer information. Only authenticated users can access this page.

## Features

### 1. Add New Customer
- **First Name** (Required)
- **Middle Name** (Optional)
- **Last Name** (Required)
- **Contact Number** (Required - validates 10+ digits)
- **Address** (Optional)

### 2. View Customers
- Display list of all customers with key information
- Shows customer name, contact, and address (if available)
- Customers are sorted by creation date (newest first)

### 3. Edit Customer
- Click the edit icon on any customer card
- Form auto-fills with existing customer data
- Update any customer information
- Cancel button to abort editing

### 4. Delete Customer
- Click the delete icon on any customer card
- Confirmation dialog before deletion
- Once deleted, cannot be undone

## Security

### Authentication Protection
- Page checks for logged-in user on load
- Redirects to login page if not authenticated
- Uses Firebase Authentication

### Data Isolation
- Each user's customers are stored in their own Firestore collection
- Path: `users/{userId}/customers/{customerId}`
- Users can only access their own customers

## Database Structure

### Firestore Collection Path
```
users
  └── {userId}
      └── customers
          └── {customerId}
              ├── firstName: string
              ├── middleName: string
              ├── lastName: string
              ├── contact: string
              ├── address: string
              ├── createdAt: timestamp
              └── updatedAt: timestamp
```

## Form Validation

| Field | Rules |
|-------|-------|
| First Name | Required, text only |
| Middle Name | Optional |
| Last Name | Required, text only |
| Contact Number | Required, minimum 10 digits |
| Address | Optional, multi-line support |

## Navigation

### Access Customer Page
1. From Dashboard bottom navigation
2. Click on "Customers" tab (people icon)
3. Automatically checks authentication

### Back Navigation
- Use device back button
- Automatically returns to Dashboard

## Technical Details

### State Management
- Uses StatefulWidget with local state management
- Real-time customer list loading from Firestore
- Loading indicators during save/delete operations

### Error Handling
- Toast notifications for success/error messages
- User-friendly error messages
- Logs errors to console for debugging
- Graceful handling of network errors

### User Experience
- Empty state message when no customers exist
- Loading indicators on buttons during operations
- Automatic form scrolling when editing
- Auto-clear form after successful save

## Usage Example

```dart
// Access from Dashboard
Navigator.of(context).push(
  MaterialPageRoute(builder: (_) => const CustomerPage()),
);
```

## Future Enhancements

- [ ] Search and filter customers
- [ ] Bulk import customers (CSV)
- [ ] Export customer list
- [ ] Customer groups/categories
- [ ] Customer transaction history
- [ ] Integration with Bills module
- [ ] SMS/Email notifications

## Troubleshooting

### "User not authenticated" error
- User session expired
- Sign in again from login page
- Check Firebase Authentication setup

### Cannot save customer
- Verify all required fields are filled
- Check internet connection
- Check Firebase Firestore permissions

### Customers not loading
- Refresh the page
- Check internet connection
- Check Firebase rules allow reading user's collection

## Firestore Security Rules

Ensure your Firestore security rules allow users to read/write their own customer data:

```firestore
match /users/{userId}/customers/{document=**} {
  allow read, write: if request.auth.uid == userId;
}
```
