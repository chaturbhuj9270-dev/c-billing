# Purchase & Inventory Management Module

A comprehensive inventory management system for the C-Billing application with product management, purchase tracking, stock history, and dashboard metrics.

## Architecture Overview

```
lib/features/inventory_management/
├── domain/
│   ├── entities/
│   │   ├── product.dart          # Product entity with validation
│   │   ├── stock.dart            # Stock history/ledger entity
│   │   └── purchase.dart         # Purchase records entity
│   └── repositories/
│       ├── product_repository.dart       # Product repo interface
│       ├── stock_repository.dart         # Stock repo interface
│       └── purchase_repository.dart      # Purchase repo interface
├── data/
│   └── repositories/
│       ├── firebase_product_repository.dart       # Firebase Product impl
│       ├── firebase_stock_repository.dart         # Firebase Stock impl
│       └── firebase_purchase_repository.dart      # Firebase Purchase impl
└── presentation/
    └── pages/
        ├── purchase_page.dart            # Purchase management UI
        └── product_management_page.dart  # Product management UI

lib/core/services/
├── inventory_service.dart           # Main business logic service
└── dashboard_inventory_service.dart  # Dashboard metrics service
```

## Entities

### Product Entity
```dart
Product {
  String id;
  String name;
  String category;
  double purchasePrice;
  double salesPrice;
  int currentStock;
  DateTime createdAt;
  DateTime updatedAt;
}
```

**Methods:**
- `getStockValue()` - Calculate total stock value based on purchase price
- `isLowStock(threshold)` - Check if stock is below threshold
- `copyWith()` - Create modified copy
- `toJson() / fromJson()` - Serialization

### Stock Entity
```dart
Stock {
  String id;
  String productId;
  int quantityIn;        // Inbound quantity
  int quantityOut;       // Outbound quantity
  int balanceQuantity;   // Current balance
  ReferenceType type;    // PURCHASE | SALE | ADJUSTMENT
  String referenceId;    // Reference to purchase/sale record
  DateTime createdAt;
}
```

**Methods:**
- `getNetChange()` - Get net quantity change (in - out)
- `isInbound()` - Check if inbound transaction

### Purchase Entity
```dart
Purchase {
  String id;
  String productId;
  int quantity;
  double purchasePrice;
  double totalAmount;
  String notes;
  DateTime createdAt;
  DateTime updatedAt;
}
```

## Services

### InventoryService
Main service with all business logic operations:

#### Purchase Operations
```dart
Future<String> processPurchase({
  required String productId,
  required int quantity,
  required double purchasePrice,
  String? notes,
})
```
- Validates inputs
- Creates purchase record
- Updates product stock
- Creates stock history entry

#### Sales Operations
```dart
Future<String> processSale({
  required String productId,
  required int quantity,
  String? referenceId,
})
```
- Validates stock availability
- Decreases product stock
- Creates outbound stock entry

#### Dashboard Metrics
```dart
Future<double> getTotalPurchasesAmount(...)
Future<int> getTotalPurchasesQuantity(...)
Future<double> getTotalSalesAmount(...)
Future<int> getTotalSalesQuantity(...)
Future<double> getProfit(...)
Future<double> getCurrentStockValue()
Future<List<Product>> getLowStockProducts(threshold)
```

#### Product Management
```dart
Future<String> createProduct(...)
Future<List<Product>> getAllProducts()
Future<Product?> getProductById(String id)
Future<void> updateProduct(Product product)
Future<List<Stock>> getProductStockHistory(String productId)
```

### DashboardInventoryService
Singleton service for dashboard integration:

```dart
Future<Map<String, dynamic>> getDashboardSummary(...)
Future<Map<String, dynamic>> getTotalPurchases(...)
Future<Map<String, dynamic>> getTotalSales(...)
Future<double> getProfit(...)
Future<double> getCurrentStockValue()
Future<List<Product>> getLowStockProducts(...)
```

## Usage Examples

### Using InventoryService

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:c_billing/core/services/inventory_service.dart';
import 'package:c_billing/features/inventory_management/data/repositories/firebase_*.dart';

// Initialize
final firestore = FirebaseFirestore.instance;
final inventoryService = InventoryService(
  productRepository: FirebaseProductRepository(firestore: firestore),
  stockRepository: FirebaseStockRepository(firestore: firestore),
  purchaseRepository: FirebasePurchaseRepository(firestore: firestore),
);

// Create product
final productId = await inventoryService.createProduct(
  name: 'Laptop',
  category: 'Electronics',
  purchasePrice: 50000,
  salesPrice: 65000,
  initialStock: 5,
);

// Record a purchase
final purchaseId = await inventoryService.processPurchase(
  productId: 'product-123',
  quantity: 10,
  purchasePrice: 5000,
  notes: 'Bulk purchase from supplier X',
);

// Record a sale
final stockEntryId = await inventoryService.processSale(
  productId: 'product-123',
  quantity: 2,
  referenceId: 'invoice-456',
);

// Get metrics
final profit = await inventoryService.getProfit();
final stockValue = await inventoryService.getCurrentStockValue();
final lowStockItems = await inventoryService.getLowStockProducts(threshold: 10);
```

### Using Dashboard Service

```dart
import 'package:c_billing/core/services/dashboard_inventory_service.dart';

final dashboardService = DashboardInventoryService();

// Get complete dashboard summary
final summary = await dashboardService.getDashboardSummary();
print('Total Purchases: ₹${summary['totalPurchases']['amount']}');
print('Total Sales: ₹${summary['totalSales']['amount']}');
print('Profit: ₹${summary['profit']}');
print('Stock Value: ₹${summary['currentStockValue']}');
print('Low Stock Items: ${summary['lowStockProductsCount']}');

// Get individual metrics
final purchases = await dashboardService.getTotalPurchases();
final sales = await dashboardService.getTotalSales();
final profit = await dashboardService.getProfit();
```

## UI Components

### PurchasePage
Full-featured purchase management page with:
- Product selection dropdown
- Current stock display
- Quantity input
- Price input with auto-calculation
- Total amount calculation
- Optional notes field
- Real-time form validation

### ProductManagementPage
Product catalog management with:
- Product list view
- Stock status indicator
- Price display (purchase & sales)
- Stock value calculation
- Low stock highlighting
- Add new product dialog

## Data Flow

### Purchase Flow
```
User inputs → Validation → Create Purchase record
    ↓
Create Stock entry (quantityIn)
    ↓
Update Product.currentStock
    ↓
Display confirmation
```

### Sale Flow
```
Validate stock availability
    ↓
Update Product.currentStock
    ↓
Create Stock entry (quantityOut)
    ↓
Return stock entry ID
```

## Firebase Collections

### `products` collection
```json
{
  "id": "auto-generated",
  "name": "Product Name",
  "category": "Category",
  "purchasePrice": 1000.50,
  "salesPrice": 1500.00,
  "currentStock": 50,
  "createdAt": "2026-02-02T10:00:00Z",
  "updatedAt": "2026-02-02T10:00:00Z"
}
```

### `stock` collection (Stock Ledger)
```json
{
  "id": "auto-generated",
  "productId": "product-id",
  "quantityIn": 10,
  "quantityOut": 0,
  "balanceQuantity": 50,
  "referenceType": "PURCHASE",
  "referenceId": "purchase-id",
  "createdAt": "2026-02-02T10:00:00Z"
}
```

### `purchases` collection
```json
{
  "id": "auto-generated",
  "productId": "product-id",
  "quantity": 10,
  "purchasePrice": 1000.50,
  "totalAmount": 10005.00,
  "notes": "Optional notes",
  "createdAt": "2026-02-02T10:00:00Z",
  "updatedAt": "2026-02-02T10:00:00Z"
}
```

## Key Features

✅ **Product Management**
- Create and manage products
- Categorization
- Dual pricing (purchase & sales)
- Stock auto-update

✅ **Purchase Tracking**
- Record purchases with quantity and price
- Override purchase prices
- Track purchase history
- Stock ledger entries

✅ **Sales Management**
- Stock availability validation
- Auto-decrease inventory on sale
- Sale history with stock entries
- Prevent overselling

✅ **Stock Management**
- Complete stock ledger
- History tracking (PURCHASE, SALE, ADJUSTMENT)
- Balance calculation
- Current stock tracking

✅ **Dashboard Integration**
- Total purchases (amount & quantity)
- Total sales (amount & quantity)
- Profit calculation
- Current stock value
- Low stock alerts
- Date range filtering

✅ **Business Logic**
- Input validation
- Error handling
- Atomic transactions (purchase = record + stock + update)
- Audit trail via stock ledger

## Future Enhancements

- [ ] Stock adjustments (damage, theft, recount)
- [ ] Supplier management
- [ ] Purchase order workflows
- [ ] Invoice generation
- [ ] Stock reports
- [ ] Barcode scanning
- [ ] Batch operations
- [ ] Stock forecasting
- [ ] Price history tracking
- [ ] Multi-location inventory

## Error Handling

All services throw descriptive exceptions:
- Product not found
- Insufficient stock
- Invalid quantity/price
- Validation errors
- Database operation failures

