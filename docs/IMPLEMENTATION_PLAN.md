# خطة التنفيذ التفصيلية

## نظرة عامة

| المرحلة | المدة | الميزات |
|---------|-------|---------|
| **المرحلة 1** | 2-3 أسابيع | البنية التحتية للاشتراكات |
| **المرحلة 2** | 3-4 أسابيع | المحاسبة الأساسية والنسخ الاحتياطي |
| **المرحلة 3** | 3-4 أسابيع | الديون وأوامر الشراء |
| **المرحلة 4** | 2-3 أسابيع | التحليلات والتقارير |
| **المرحلة 5** | 3-4 أسابيع | المستخدمين والإشعارات |
| **الإجمالي** | **13-18 أسبوعاً** | **نظام محاسبي متكامل** |

---

## المرحلة 1: البنية التحتية للاشتراكات
**المدة: 2-3 أسابيع**

### 1.1 إنشاء نموذج الاشتراك

```
lib/features/subscription/domain/entities/subscription.dart
```

```dart
class Subscription extends Equatable {
  final String id;
  final String plan; // 'free', 'basic', 'standard', 'premium', 'ultimate'
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final String? paymentMethod;
  final String? transactionId;
  final DateTime? createdAt;

  const Subscription({
    required this.id,
    required this.plan,
    required this.startDate,
    required this.endDate,
    this.isActive = true,
    this.paymentMethod,
    this.transactionId,
    this.createdAt,
  });

  bool get isExpired => DateTime.now().isAfter(endDate);
  bool get isValid => isActive && !isExpired;

  Subscription copyWith({...});
}
```

### 1.2 إنشاء Hive Adapter للاشتراك

```
lib/features/subscription/data/models/subscription_model.dart
lib/features/subscription/data/models/subscription_model.g.dart
```

### 1.3 إنشاء SubscriptionBloc

```
lib/features/subscription/presentation/bloc/subscription_bloc.dart
lib/features/subscription/presentation/bloc/subscription_event.dart
lib/features/subscription/presentation/bloc/subscription_state.dart
```

**الأحداث:**
- `CheckSubscriptionEvent` - التحقق من حالة الاشتراك
- `PurchaseSubscriptionEvent` - شراء اشتراك جديد
- `CancelSubscriptionEvent` - إلغاء الاشتراك
- `RenewSubscriptionEvent` - تجديد الاشتراك

**الحالات:**
- `SubscriptionInitial` - الحالة الأولية
- `SubscriptionFree` - مستخدم مجاني
- `SubscriptionLoading` - جاري التحميل
- `SubscriptionActive` - اشتراك نشط
- `SubscriptionExpired` - اشتراك منتهي
- `SubscriptionError` - خطأ

### 1.4 إنشاء SubscriptionRepository

```
lib/features/subscription/domain/repositories/subscription_repository.dart
lib/features/subscription/data/repositories/subscription_repository_impl.dart
```

**الدوال:**
- `checkSubscription()` - التحقق من الاشتراك
- `purchaseSubscription(plan)` - شراء اشتراك
- `cancelSubscription()` - إلغاء الاشتراك
- `renewSubscription()` - تجديد الاشتراك
- `getSubscriptionStatus()` - الحصول على حالة الاشتراك

### 1.5 إنشاء Payment Service

```
lib/core/services/payment_service.dart
lib/core/services/fake_payment_service.dart
```

**الواجهة:**
```dart
abstract class PaymentService {
  Future<PaymentResult> processPayment({
    required String plan,
    required double amount,
    required String paymentMethod,
  });

  Future<bool> refundPayment(String transactionId);
  Future<PaymentStatus> checkPaymentStatus(String transactionId);
}
```

### 1.6 إنشاء شاشة إدارة الاشتراك

```
lib/features/subscription/presentation/pages/subscription_page.dart
```

**المكونات:**
- عرض حالة الاشتراك الحالي
- عرض الباقات المتاحة
- زر الاشتراك/التجديد
- عرض الميزات المقفلة
- عرض الوقت المتبقي

### 1.7 إنشاء شاشة الباقات

```
lib/features/subscription/presentation/pages/plans_page.dart
```

**المكونات:**
- بطاقات الباقات مع الأسعار
- قائمة الميزات لكل باقة
- زر اختيار الباقة
- خيار الشهري/السنوي

### 1.8 تحديث AppRouter

```
lib/config/routes/app_routes.dart
```

```dart
// إضافة مسارات جديدة
GoRoute(
  path: '/subscription',
  builder: (context) => const SubscriptionPage(),
),
GoRoute(
  path: '/plans',
  builder: (context) => const PlansPage(),
),
```

### 1.9 إنشاء Subscription Guard

```
lib/core/guards/subscription_guard.dart
```

```dart
class SubscriptionGuard extends StatelessWidget {
  final Widget child;
  final List<String> requiredPlans;

  const SubscriptionGuard({
    super.key,
    required this.child,
    required this.requiredPlans,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SubscriptionBloc, SubscriptionState>(
      builder: (context, state) {
        if (state is SubscriptionActive) {
          if (requiredPlans.contains(state.subscription.plan)) {
            return child;
          }
          return _showUpgradeDialog(context);
        }
        return _showUpgradeDialog(context);
      },
    );
  }
}
```

### 1.10 تحديث HiveDatabase

```
lib/core/data/hive_database.dart
```

```dart
// إضافة صندوق الاشتراكات
static const String subscriptionBoxName = 'subscription';

await Hive.openBox<SubscriptionModel>(subscriptionBoxName);
```

---

## المرحلة 2: المحاسبة الأساسية والنسخ الاحتياطي
**المدة: 3-4 أسابيع**

### 2.1 نظام تتبع المصروفات

#### 2.1.1 إنشاء ExpenseModel

```
lib/features/expenses/domain/entities/expense.dart
```

```dart
class Expense extends Equatable {
  final String id;
  final double amount;
  final String category; // 'rent', 'salary', 'utilities', 'supplies', 'other'
  final String description;
  final DateTime date;
  final String? receiptImage;
  final String? notes;

  const Expense({
    required this.id,
    required this.amount,
    required this.category,
    required this.description,
    required this.date,
    this.receiptImage,
    this.notes,
  });
}
```

#### 2.1.2 إنشاء ExpenseBloc

```
lib/features/expenses/presentation/bloc/expense_bloc.dart
lib/features/expenses/presentation/bloc/expense_event.dart
lib/features/expenses/presentation/bloc/expense_state.dart
```

**الأحداث:**
- `LoadExpensesEvent` - تحميل المصروفات
- `AddExpenseEvent` - إضافة مصروف
- `UpdateExpenseEvent` - تحديث مصروف
- `DeleteExpenseEvent` - حذف مصروف
- `FilterExpensesEvent` - تصفية المصروفات

#### 2.1.3 إنشاء ExpenseRepository

```
lib/features/expenses/domain/repositories/expense_repository.dart
lib/features/expenses/data/repositories/expense_repository_impl.dart
```

#### 2.1.4 إنشاء شاشة المصروفات

```
lib/features/expenses/presentation/pages/expenses_page.dart
lib/features/expenses/presentation/pages/add_expense_page.dart
```

**المكونات:**
- قائمة المصروفات
- إضافة/تعديل/حذف مصروف
- اختيار الفئة
- رفع صورة الإيصال
- تصفية بالتاريخ والفئة
- ملخص المصروفات

### 2.2 النسخ الاحتياطي السحابي

#### 2.2.1 إنشاء BackupService

```
lib/core/services/backup_service.dart
```

**الدوال:**
- `exportData()` - تصدير جميع البيانات كـ JSON
- `importData(JSON)` - استيراد البيانات
- `uploadToCloud()` - رفع للسحابة
- `downloadFromCloud()` - تحميل من السحابة
- `getBackupHistory()` - تاريخ النسخ الاحتياطية

#### 2.2.2 إنشاء BackupModel

```
lib/features/backup/domain/entities/backup.dart
```

```dart
class Backup extends Equatable {
  final String id;
  final DateTime createdAt;
  final int dataSize;
  final int itemCount;
  final String? cloudUrl;

  const Backup({
    required this.id,
    required this.createdAt,
    required this.dataSize,
    required this.itemCount,
    this.cloudUrl,
  });
}
```

#### 2.2.3 إنشاء شاشة النسخ الاحتياطي

```
lib/features/backup/presentation/pages/backup_page.dart
```

**المكونات:**
- زر الحفظ اليدوي
- جدولة تلقائية (يومي/أسبوعي/شهري)
- قائمة النسخ الاحتياطية
- استعادة من نسخة سابقة
- مشاركة النسخة

### 2.3 التقارير المالية

#### 2.3.1 إنشاء ReportModel

```
lib/features/reports/domain/entities/report.dart
```

```dart
class FinancialReport extends Equatable {
  final String id;
  final String type; // 'daily', 'weekly', 'monthly', 'custom'
  final DateTime startDate;
  final DateTime endDate;
  final double totalSales;
  final double totalExpenses;
  final double netProfit;
  final int invoiceCount;
  final int expenseCount;

  const FinancialReport({
    required this.id,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.totalSales,
    required this.totalExpenses,
    required this.netProfit,
    required this.invoiceCount,
    required this.expenseCount,
  });
}
```

#### 2.3.2 إنشاء ReportGenerator

```
lib/features/reports/domain/usecases/generate_report_usecase.dart
```

```dart
class GenerateReportUseCase {
  Future<FinancialReport> call({
    required String type,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    // جلب المبيعات
    final sales = await getSales(startDate, endDate);
    // جلب المصروفات
    final expenses = await getExpenses(startDate, endDate);
    // حساب الإجماليات
    final totalSales = sales.fold(0, (sum, s) => sum + s.totalAmount);
    final totalExpenses = expenses.fold(0, (sum, e) => sum + e.amount);
    // إنشاء التقرير
    return FinancialReport(...);
  }
}
```

#### 2.3.4 إنشاء شاشة التقارير

```
lib/features/reports/presentation/pages/reports_page.dart
```

**المكونات:**
- اختيار الفترة (يوم/أسبوع/شهر/مخصص)
- عرض الإجماليات (المبيعات، المصروفات، صافي الربح)
- عرض تفصيلي
- تصدير PDF/Excel
- مقارنة الفترات

---

## المرحلة 3: الديون وأوامر الشراء
**المدة: 3-4 أسابيع**

### 3.1 إدارة ديون العملاء

#### 3.1.1 إنشاء CustomerDebtModel

```
lib/features/debts/domain/entities/customer_debt.dart
```

```dart
class CustomerDebt extends Equatable {
  final String id;
  final String customerId;
  final String customerName;
  final String invoiceId;
  final double originalAmount;
  final double paidAmount;
  final double remainingAmount;
  final DateTime dueDate;
  final String status; // 'pending', 'partial', 'paid', 'overdue'
  final DateTime createdAt;

  const CustomerDebt({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.invoiceId,
    required this.originalAmount,
    required this.paidAmount,
    required this.remainingAmount,
    required this.dueDate,
    required this.status,
    required this.createdAt,
  });
}
```

#### 3.1.2 إنشاء CustomerDebtBloc

```
lib/features/debts/presentation/bloc/customer_debt_bloc.dart
```

#### 3.1.3 إنشاء شاشة إدارة ديون العملاء

```
lib/features/debts/presentation/pages/customer_debts_page.dart
lib/features/debts/presentation/pages/debt_payment_page.dart
```

**المكونات:**
- قائمة العملاء المدينين
- تفاصيل الدين
- تسجيل سداد (كلي/جزئي)
- تنبيهات الاستحقاق
- تقرير الديون

### 3.2 إدارة ديون الموردين

#### 3.2.1 إنشاء SupplierDebtModel

```
lib/features/debts/domain/entities/supplier_debt.dart
```

#### 3.2.2 إنشاء شاشة إدارة مستحقات الموردين

```
lib/features/debts/presentation/pages/supplier_debts_page.dart
```

**المكونات:**
- قائمة الموردين المستحقين
- تفاصيل المستحقات
- تسجيل الدفع للمورد
- تنبيهات السداد

### 3.3 أوامر الشراء

#### 3.3.1 إنشاء PurchaseOrderModel

```
lib/features/purchase_orders/domain/entities/purchase_order.dart
```

```dart
class PurchaseOrder extends Equatable {
  final String id;
  final String supplierId;
  final String supplierName;
  final List<PurchaseOrderItem> items;
  final double totalAmount;
  final String status; // 'draft', 'sent', 'confirmed', 'received', 'cancelled'
  final DateTime orderDate;
  final DateTime? expectedDate;
  final DateTime? receivedDate;
  final String? notes;

  const PurchaseOrder({
    required this.id,
    required this.supplierId,
    required this.supplierName,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.orderDate,
    this.expectedDate,
    this.receivedDate,
    this.notes,
  });
}
```

#### 3.3.2 إنشاء PurchaseOrderBloc

```
lib/features/purchase_orders/presentation/bloc/purchase_order_bloc.dart
```

#### 3.3.3 إنشاء شاشة أوامر الشراء

```
lib/features/purchase_orders/presentation/pages/purchase_orders_page.dart
lib/features/purchase_orders/presentation/pages/create_purchase_order_page.dart
```

**المكونات:**
- قائمة أوامر الشراء
- إنشاء أمر شراء جديد
- إرسال للمورد (بريد/واتساب)
- استلام وتحديث المخزون
- تتبع الحالة

### 3.4 إدارة المرتجعات

#### 3.4.1 إنشاء ReturnModel

```
lib/features/returns/domain/entities/return.dart
```

```dart
class Return extends Equatable {
  final String id;
  final String type; // 'sale', 'purchase'
  final String invoiceId;
  final String productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double totalAmount;
  final String reason;
  final String status; // 'pending', 'approved', 'rejected', 'completed'
  final DateTime date;
  final String? notes;

  const Return({
    required this.id,
    required this.type,
    required this.invoiceId,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.totalAmount,
    required this.reason,
    required this.status,
    required this.date,
    this.notes,
  });
}
```

#### 3.4.2 إنشاء شاشة المرتجعات

```
lib/features/returns/presentation/pages/returns_page.dart
```

**المكونات:**
- قائمة المرتجعات
- إنشاء مرتجع جديد
- الموافقة/الرفض
- تأثير المخزون
- تقرير المرتجعات

---

## المرحلة 4: التحليلات والتقارير المتقدمة
**المدة: 2-3 أسابيع**

### 4.1 لوحة التحكم التحليلية

#### 4.1.1 إنشاء AnalyticsModel

```
lib/features/analytics/domain/entities/analytics.dart
```

```dart
class Analytics extends Equatable {
  final double totalSales;
  final double totalExpenses;
  final double netProfit;
  final int invoiceCount;
  final int customerCount;
  final int productCount;
  final double salesGrowth;
  final double profitGrowth;
  final List<DailySales> dailySales;
  final List<TopProduct> topProducts;
  final List<TopCustomer> topCustomers;

  const Analytics({...});
}
```

#### 4.1.2 إنشاء AnalyticsBloc

```
lib/features/analytics/presentation/bloc/analytics_bloc.dart
```

#### 4.1.3 إنشاء شاشة AnalyticsDashboard

```
lib/features/analytics/presentation/pages/analytics_dashboard_page.dart
```

**المكونات:**
- مخطط المبيعات الشهري (Line Chart)
- مخطط الأرباح (Bar Chart)
- أفضل 5 منتجات (Pie Chart)
- أفضل 5 عملاء
- إحصائيات سريعة (KPIs)
- تحديث مباشر

### 4.2 التقارير المتقدمة

#### 4.2.1 إنشاء ReportGenerator

```
lib/features/reports/domain/usecases/report_generator.dart
```

**الدوال:**
- `generateSalesReport()` - تقرير المبيعات
- `generateProfitReport()` - تقرير الأرباح
- `generateInventoryReport()` - تقرير المخزون
- `generateCustomerReport()` - تقرير العملاء
- `generateSupplierReport()` - تقرير الموردين
- `generateComparisonReport()` - تقرير المقارنة

#### 4.2.2 إنشاء شاشة التقارير المتقدمة

```
lib/features/reports/presentation/pages/advanced_reports_page.dart
```

**المكونات:**
- فلاتر متقدمة (التاريخ، الفئة، العميل، المنتج)
- مقارنة الفترات
- تصدير متعدد الصيغ (PDF, Excel, CSV)
- حفظ التقارير المخصصة

### 4.3 تحليلات المنتجات

#### 4.3.1 إنشاء ProductAnalytics

```
lib/features/analytics/domain/entities/product_analytics.dart
```

```dart
class ProductAnalytics extends Equatable {
  final String productId;
  final String productName;
  final int totalSold;
  final double revenue;
  final double profit;
  final double profitMargin;
  final double trend; // -1 to 1
  final List<MonthlyData> monthlyData;

  const ProductAnalytics({...});
}
```

#### 4.3.2 إنشاء شاشة تحليلات المنتجات

```
lib/features/analytics/presentation/pages/product_analytics_page.dart
```

### 4.4 تحليلات العملاء

#### 4.4.1 إنشاء CustomerAnalytics

```
lib/features/analytics/domain/entities/customer_analytics.dart
```

```dart
class CustomerAnalytics extends Equatable {
  final String customerId;
  final String customerName;
  final int totalPurchases;
  final double totalSpent;
  final double averageOrder;
  final int orderCount;
  final double loyaltyScore;
  final DateTime lastPurchase;
  final List<MonthlyData> monthlyData;

  const CustomerAnalytics({...});
}
```

#### 4.4.2 إنشاء شاشة تحليلات العملاء

```
lib/features/analytics/presentation/pages/customer_analytics_page.dart
```

---

## المرحلة 5: المستخدمين والإشعارات
**المدة: 3-4 أسابيع**

### 5.1 نظام المستخدمين المتعددين

#### 5.1.1 إنشاء UserModel

```
lib/features/users/domain/entities/user.dart
```

```dart
class User extends Equatable {
  final String id;
  final String name;
  final String email;
  final String role; // 'admin', 'accountant', 'seller'
  final List<String> permissions;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastLogin;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.permissions,
    this.isActive = true,
    required this.createdAt,
    this.lastLogin,
  });
}
```

#### 5.1.2 إنشاء UserBloc

```
lib/features/users/presentation/bloc/user_bloc.dart
```

#### 5.1.3 إنشاء AuthBloc

```
lib/features/auth/presentation/bloc/auth_bloc.dart
```

**الأحداث:**
- `LoginEvent` - تسجيل الدخول
- `LogoutEvent` - تسجيل الخروج
- `CheckAuthEvent` - التحقق من الحالة

#### 5.1.4 إنشاء شاشة إدارة المستخدمين

```
lib/features/users/presentation/pages/users_page.dart
lib/features/users/presentation/pages/add_user_page.dart
lib/features/users/presentation/pages/edit_user_page.dart
```

**المكونات:**
- قائمة المستخدمين
- إضافة/تعديل/حذف مستخدم
- تعيين الأدوار
- إدارة الصلاحيات
- عرض المستخدمين المتصلين

### 5.2 سجل العمليات (Audit Log)

#### 5.2.1 إنشاء AuditLogModel

```
lib/features/audit_log/domain/entities/audit_log.dart
```

```dart
class AuditLog extends Equatable {
  final String id;
  final String userId;
  final String userName;
  final String action; // 'create', 'update', 'delete', 'login', 'logout'
  final String entity; // 'product', 'invoice', 'customer', etc.
  final String entityId;
  final Map<String, dynamic> oldValues;
  final Map<String, dynamic> newValues;
  final DateTime timestamp;
  final String ipAddress;

  const AuditLog({...});
}
```

#### 5.2.2 إنشاء شاشة سجل العمليات

```
lib/features/audit_log/presentation/pages/audit_log_page.dart
```

**المكونات:**
- قائمة العمليات
- تصفية حسب المستخدم
- تصفية حسب النوع
- تصفية بالتاريخ
- تصدير السجل

### 5.3 نظام الإشعارات

#### 5.3.1 إنشاء NotificationModel

```
lib/features/notifications/domain/entities/notification.dart
```

```dart
class Notification extends Equatable {
  final String id;
  final String type; // 'low_stock', 'debt_due', 'report_ready', etc.
  final String title;
  final String body;
  final bool isRead;
  final Map<String, dynamic> data;
  final DateTime createdAt;

  const Notification({...});
}
```

#### 5.3.2 إنشاء NotificationBloc

```
lib/features/notifications/presentation/bloc/notification_bloc.dart
```

#### 5.3.3 إنشاء شاشة الإشعارات

```
lib/features/notifications/presentation/pages/notifications_page.dart
```

**المكونات:**
- قائمة الإشعارات
- قراءة/غير مقروء
- حذف إشعار
- إعدادات الإشعارات
- أنواع الإشعارات:
  - المخزون المنخفض
  - الديون المستحقة
  - التقارير المجدولة
  - أوامر الشراء الجديدة

### 5.4 API للمطورين

#### 5.4.1 إنشاء ApiService

```
lib/core/services/api_service.dart
```

**المسارات:**
- `GET /api/products` - جلب المنتجات
- `POST /api/products` - إضافة منتج
- `PUT /api/products/:id` - تحديث منتج
- `DELETE /api/products/:id` - حذف منتج
- `GET /api/sales` - جلب المبيعات
- `POST /api/invoices` - إنشاء فاتورة
- `GET /api/reports` - جلب التقارير
- `GET /api/inventory` - جلب المخزون

#### 5.4.2 إنشاء ApiKeyManager

```
lib/core/services/api_key_manager.dart
```

**المكونات:**
- إنشاء مفاتيح API
- إدارة صلاحيات المفاتيح
- تتبع الاستخدام
- Rate limiting

---

## جدول المتطلبات التقنية

### قاعدة البيانات

```dart
// جداول جديدة لإضافتها لـ HiveDatabase
static const String subscriptionBoxName = 'subscription';
static const String expenseBoxName = 'expenses';
static const String backupBoxName = 'backups';
static const String customerDebtBoxName = 'customer_debts';
static const String supplierDebtBoxName = 'supplier_debts';
static const String purchaseOrderBoxName = 'purchase_orders';
static const String returnBoxName = 'returns';
static const String userBoxName = 'users';
static const String auditLogBoxName = 'audit_logs';
static const String notificationBoxName = 'notifications';
```

### إدارة الحالة

```dart
// Blocs جديدة لإضافتها
BlocProvider<SubscriptionBloc>(create: (context) => di.sl<SubscriptionBloc>()),
BlocProvider<ExpenseBloc>(create: (context) => di.sl<ExpenseBloc>()),
BlocProvider<ReportBloc>(create: (context) => di.sl<ReportBloc>()),
BlocProvider<DebtBloc>(create: (context) => di.sl<DebtBloc>()),
BlocProvider<PurchaseOrderBloc>(create: (context) => di.sl<PurchaseOrderBloc>()),
BlocProvider<ReturnBloc>(create: (context) => di.sl<ReturnBloc>()),
BlocProvider<AnalyticsBloc>(create: (context) => di.sl<AnalyticsBloc>()),
BlocProvider<UserBloc>(create: (context) => di.sl<UserBloc>()),
BlocProvider<AuthBloc>(create: (context) => di.sl<AuthBloc>()),
BlocProvider<NotificationBloc>(create: (context) => di.sl<NotificationBloc>()),
```

---

## ملاحظات هامة

1. **التجربة المجانية:** تقديم 7-14 يوم تجريبي مجاني للميزات المميزة
2. **الدفع:** يمكن البدء بـ Fake Payment للاختبار، ثم دمج Stripe/PayPal
3. **الترقية:** يجب تصميم واجهة الترقية لتكون واضحة وجذابة
4. **البيانات:** عند الترقية، يجب ترحيل البيانات القديمة للنظام الجديد

---

**تاريخ الإنشاء:** 12 مايو 2026
**الإصدار:** 1.0