import 'package:hive_flutter/hive_flutter.dart';
import '../../features/product/data/models/product_model.dart';
import '../../features/shop/data/models/shop_model.dart';
import '../../features/sales/data/models/invoice_model.dart';
import '../../features/customers/data/models/customer_model.dart';
import '../../features/suppliers/data/models/supplier_model.dart';
import '../../features/inventory/data/models/stock_movement_model.dart';
import '../../features/auth/data/models/user_model.dart';
import '../../features/expenses/data/models/expense_model.dart';
import '../../features/zakat/data/models/zakat_payment_model.dart';
import '../../features/debts/data/models/debt_model.dart';
import '../../features/debts/data/models/debt_payment_model.dart';
import '../../features/ai/data/models/ai_provider_model.dart';
import '../../features/ai/data/models/chat_message_model.dart';
import '../../features/ai/data/models/chat_session_model.dart';

class HiveDatabase {
  static const String productBoxName = 'products';
  static const String shopBoxName = 'shop';
  static const String settingsBoxName = 'settings';
  static const String invoiceBoxName = 'invoices';
  static const String customerBoxName = 'customers';
  static const String supplierBoxName = 'suppliers';
  static const String stockMovementBoxName = 'stock_movements';
  static const String userBoxName = 'users';
  static const String expenseBoxName = 'expenses';
  static const String debtBoxName = 'debts';
  static const String debtPaymentBoxName = 'debt_payments';
  static const String zakatPaymentBoxName = 'zakat_payments';

  static Future<void> init() async {
    await Hive.initFlutter();

    // Register Adapters (only if not already registered)
    // typeId: 0  = ProductModel
    // typeId: 1  = ShopModel
    // typeId: 2  = InvoiceModel
    // typeId: 3  = CustomerModel
    // typeId: 4  = SupplierModel
    // typeId: 6  = InvoiceItemModel
    // typeId: 7  = StockMovementModel
    // typeId: 8  = UserModel
    // typeId: 9  = ExpenseModel       (Phase 2)
    // typeId: 10 = DebtModel          (Phase 4)
    // typeId: 11 = DebtPaymentModel   (Phase 4)
    // typeId: 12 = ZakatPaymentModel  (Phase 3)
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(ProductModelAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(ShopModelAdapter());
    }
    if (!Hive.isAdapterRegistered(6)) {
      Hive.registerAdapter(InvoiceItemModelAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(InvoiceModelAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(CustomerModelAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(SupplierModelAdapter());
    }
    if (!Hive.isAdapterRegistered(7)) {
      Hive.registerAdapter(StockMovementModelAdapter());
    }
    if (!Hive.isAdapterRegistered(8)) {
      Hive.registerAdapter(UserModelAdapter());
    }
    if (!Hive.isAdapterRegistered(9)) {
      Hive.registerAdapter(ExpenseModelAdapter());
    }
    if (!Hive.isAdapterRegistered(12)) {
      Hive.registerAdapter(ZakatPaymentModelAdapter());
    }
    if (!Hive.isAdapterRegistered(10)) {
      Hive.registerAdapter(DebtModelAdapter());
    }
    if (!Hive.isAdapterRegistered(11)) {
      Hive.registerAdapter(DebtPaymentModelAdapter());
    }
    if (!Hive.isAdapterRegistered(13)) {
      Hive.registerAdapter(AiProviderModelAdapter());
    }
    if (!Hive.isAdapterRegistered(14)) {
      Hive.registerAdapter(ChatMessageModelAdapter());
    }
    if (!Hive.isAdapterRegistered(15)) {
      Hive.registerAdapter(ChatSessionModelAdapter());
    }

    // Open Boxes
    await Hive.openBox<ProductModel>(productBoxName);
    await Hive.openBox<ShopModel>(shopBoxName);
    await Hive.openBox<InvoiceModel>(invoiceBoxName);
    await Hive.openBox<CustomerModel>(customerBoxName);
    await Hive.openBox<SupplierModel>(supplierBoxName);
    await Hive.openBox<StockMovementModel>(stockMovementBoxName);
    await Hive.openBox<UserModel>(userBoxName);
    await Hive.openBox<ExpenseModel>(expenseBoxName);
    await Hive.openBox<ZakatPaymentModel>(zakatPaymentBoxName);
    await Hive.openBox<DebtModel>(debtBoxName);
    await Hive.openBox<DebtPaymentModel>(debtPaymentBoxName);
    await Hive.openBox(settingsBoxName);
  }

  static const String aiProviderBoxName = 'ai_providers';
  static const String aiSessionBoxName = 'ai_sessions';
  static const String aiMessageBoxName = 'ai_messages';

  static Box<ProductModel> get productBox =>
      Hive.box<ProductModel>(productBoxName);
  static Box<ShopModel> get shopBox => Hive.box<ShopModel>(shopBoxName);
  static Box<InvoiceModel> get invoiceBox =>
      Hive.box<InvoiceModel>(invoiceBoxName);
  static Box<CustomerModel> get customerBox =>
      Hive.box<CustomerModel>(customerBoxName);
  static Box<SupplierModel> get supplierBox =>
      Hive.box<SupplierModel>(supplierBoxName);
  static Box<StockMovementModel> get stockMovementBox =>
      Hive.box<StockMovementModel>(stockMovementBoxName);
  static Box<UserModel> get userBox => Hive.box<UserModel>(userBoxName);
  static Box<ExpenseModel> get expenseBox =>
      Hive.box<ExpenseModel>(expenseBoxName);
  static Box<ZakatPaymentModel> get zakatPaymentBox =>
      Hive.box<ZakatPaymentModel>(zakatPaymentBoxName);
  static Box<DebtModel> get debtBox =>
      Hive.box<DebtModel>(debtBoxName);
  static Box<DebtPaymentModel> get debtPaymentBox =>
      Hive.box<DebtPaymentModel>(debtPaymentBoxName);
  static Box get settingsBox => Hive.box(settingsBoxName);
}
