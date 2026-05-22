import 'package:fpdart/fpdart.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/invoice.dart';
import '../repositories/sales_repository.dart';
import '../../../product/domain/repositories/product_repository.dart';
import '../../../inventory/domain/repositories/inventory_repository.dart';
import '../../../inventory/domain/entities/stock_movement.dart';
import '../../../product/domain/entities/product.dart';

class GetInvoicesUseCase implements UseCase<List<Invoice>, NoParams> {
  final SalesRepository repository;
  GetInvoicesUseCase(this.repository);

  @override
  Future<Either<Failure, List<Invoice>>> call(NoParams params) =>
      repository.getInvoices();
}

class GetInvoiceByIdUseCase implements UseCase<Invoice, String> {
  final SalesRepository repository;
  GetInvoiceByIdUseCase(this.repository);

  @override
  Future<Either<Failure, Invoice>> call(String params) =>
      repository.getInvoiceById(params);
}

class SaveInvoiceUseCase implements UseCase<void, Invoice> {
  final SalesRepository repository;
  SaveInvoiceUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(Invoice params) =>
      repository.saveInvoice(params);
}

class DeleteInvoiceUseCase implements UseCase<void, String> {
  final SalesRepository repository;
  DeleteInvoiceUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(String params) =>
      repository.deleteInvoice(params);
}

/// Use case لإتمام عملية البيع بشكل متكامل
/// يتكفل بـ:
/// 1. التحقق من توفر المخزون
/// 2. خصم الكميات من المخزون
/// 3. تسجيل حركات المخزون (صادر)
/// 4. حفظ الفاتورة
class CompleteSaleUseCase implements UseCase<Invoice, CompleteSaleParams> {
  final SalesRepository salesRepository;
  final ProductRepository productRepository;
  final InventoryRepository inventoryRepository;

  CompleteSaleUseCase({
    required this.salesRepository,
    required this.productRepository,
    required this.inventoryRepository,
  });

  @override
  Future<Either<Failure, Invoice>> call(CompleteSaleParams params) async {
    final invoice = params.invoice;

    // 1. التحقق من توفر المخزون لكل منتج
    final stockCheckResult = await _checkStockAvailability(invoice.items);
    if (stockCheckResult != null) {
      return Left(stockCheckResult);
    }

    // 2. خصم الكميات من المخزون وتسجيل الحركات
    for (final item in invoice.items) {
      final adjustResult = await _adjustStockForItem(item);
      if (adjustResult != null) {
        return Left(adjustResult);
      }
    }

    // 3. حفظ الفاتورة
    final saveResult = await salesRepository.saveInvoice(invoice);
    if (saveResult.isLeft()) {
      // في حالة فشل الحفظ، نحاول إعادة الكميات (rollback)
      await _rollbackStockChanges(invoice.items);
      return const Left(CacheFailure('فشل حفظ الفاتورة'));
    }

    return Right(invoice);
  }

  /// التحقق من توفر المخزون - يعيد null إذا كل شيء صحيح
  Future<Failure?> _checkStockAvailability(List<InvoiceItem> items) async {
    for (final item in items) {
      final productsResult = await productRepository.getProducts();
      if (productsResult.isLeft()) {
        return const CacheFailure('فشل في جلب المنتجات');
      }

      List<Product> products = [];
      productsResult.fold(
        (_) => products = [],
        (list) => products = list,
      );

      // البحث عن المنتج
      final productIndex = products.indexWhere((p) => p.id == item.productId);
      if (productIndex == -1) {
        return CacheFailure('المنتج غير موجود: ${item.productName}');
      }

      final product = products[productIndex];

      if (product.stock < item.quantity) {
        return CacheFailure(
            'الكمية غير متوفرة: ${item.productName} (متوفر: ${product.stock}, مطلوب: ${item.quantity})');
      }
    }
    return null;
  }

  /// خصم الكمية من المخزون وتسجيل الحركة - يعيد null إذا نجح
  Future<Failure?> _adjustStockForItem(InvoiceItem item) async {
    // جلب المنتج الحالي
    final productsResult = await productRepository.getProducts();
    if (productsResult.isLeft()) {
      return const CacheFailure('فشل في جلب المنتج');
    }

    List<Product> products = [];
    productsResult.fold(
      (_) => products = [],
      (list) => products = list,
    );

    final productIndex = products.indexWhere((p) => p.id == item.productId);
    if (productIndex == -1) {
      return const CacheFailure('المنتج غير موجود');
    }

    final product = products[productIndex];

    final stockBefore = product.stock;
    final stockAfter = stockBefore - item.quantity;

    // تحديث المخزون
    final adjustResult =
        await productRepository.adjustStock(item.productId, stockAfter);
    if (adjustResult.isLeft()) {
      return const CacheFailure('فشل تحديث المخزون');
    }

    // تسجيل حركة المخزون
    final movement = StockMovement(
      id: const Uuid().v4(),
      productId: item.productId,
      productName: item.productName,
      type: MovementType.stockOut,
      quantity: item.quantity,
      stockBefore: stockBefore,
      stockAfter: stockAfter,
      note: 'بيع - فاتورة',
      date: DateTime.now(),
    );

    final movementResult = await inventoryRepository.addMovement(movement);
    if (movementResult.isLeft()) {
      // إعادة المخزون في حالة فشل تسجيل الحركة
      await productRepository.adjustStock(item.productId, stockBefore);
      return const CacheFailure('فشل تسجيل حركة المخزون');
    }

    return null;
  }

  /// إعادة الكميات في حالة الفشل (rollback)
  Future<void> _rollbackStockChanges(List<InvoiceItem> items) async {
    for (final item in items) {
      final productsResult = await productRepository.getProducts();
      if (productsResult.isRight()) {
        List<Product> products = [];
        productsResult.fold(
          (_) => products = [],
          (list) => products = list,
        );
        final productIndex = products.indexWhere((p) => p.id == item.productId);
        if (productIndex != -1) {
          final product = products[productIndex];
          // إعادة الكمية
          await productRepository.adjustStock(
              item.productId, product.stock + item.quantity);
        }
      }
    }
  }
}

/// معاملات Use Case إتمام البيع
class CompleteSaleParams {
  final Invoice invoice;

  const CompleteSaleParams({required this.invoice});
}

/// Use case لاسترجاع الفاتورة وإعادة الكميات للمخزون
class ReturnInvoiceUseCase implements UseCase<Invoice, ReturnInvoiceParams> {
  final SalesRepository salesRepository;
  final ProductRepository productRepository;
  final InventoryRepository inventoryRepository;

  ReturnInvoiceUseCase({
    required this.salesRepository,
    required this.productRepository,
    required this.inventoryRepository,
  });

  @override
  Future<Either<Failure, Invoice>> call(ReturnInvoiceParams params) async {
    final invoiceId = params.invoiceId;

    // جلب الفاتورة
    final invoiceResult = await salesRepository.getInvoiceById(invoiceId);

    if (invoiceResult.isLeft()) {
      return const Left(CacheFailure('الفاتورة غير موجودة'));
    }

    Invoice? invoice;
    invoiceResult.fold(
      (_) => invoice = null,
      (inv) => invoice = inv,
    );

    if (invoice == null) {
      return const Left(CacheFailure('الفاتورة غير موجودة'));
    }

    if (invoice!.status == InvoiceStatus.returned) {
      return const Left(CacheFailure('الفاتورة مسترجعة بالفعل'));
    }

    // إعادة الكميات للمخزون
    for (final item in invoice!.items) {
      final restoreResult = await _restoreStockForItem(item);
      if (restoreResult != null) {
        return Left(restoreResult);
      }
    }

    // تحديث حالة الفاتورة
    final returnedInvoice = Invoice(
      id: invoice!.id,
      invoiceNumber: invoice!.invoiceNumber,
      date: invoice!.date,
      items: invoice!.items,
      subtotal: invoice!.subtotal,
      discountAmount: invoice!.discountAmount,
      taxAmount: invoice!.taxAmount,
      totalAmount: invoice!.totalAmount,
      paymentMethod: invoice!.paymentMethod,
      cashPaid: invoice!.cashPaid,
      upiPaid: invoice!.upiPaid,
      cardPaid: invoice!.cardPaid,
      changeAmount: invoice!.changeAmount,
      customerId: invoice!.customerId,
      customerName: invoice!.customerName,
      status: InvoiceStatus.returned,
      notes: invoice!.notes,
    );

    final saveResult = await salesRepository.saveInvoice(returnedInvoice);
    if (saveResult.isLeft()) {
      return const Left(CacheFailure('فشل تحديث الفاتورة'));
    }

    return Right(returnedInvoice);
  }

  /// إعادة الكمية للمخزون وتسجيل الحركة - يعيد null إذا نجح
  Future<Failure?> _restoreStockForItem(InvoiceItem item) async {
    final productsResult = await productRepository.getProducts();
    if (productsResult.isLeft()) {
      return const CacheFailure('فشل في جلب المنتج');
    }

    List<Product> products = [];
    productsResult.fold(
      (_) => products = [],
      (list) => products = list,
    );

    final productIndex = products.indexWhere((p) => p.id == item.productId);
    if (productIndex == -1) {
      return const CacheFailure('المنتج غير موجود');
    }

    final product = products[productIndex];

    final stockBefore = product.stock;
    final stockAfter = stockBefore + item.quantity;

    // تحديث المخزون
    final adjustResult =
        await productRepository.adjustStock(item.productId, stockAfter);
    if (adjustResult.isLeft()) {
      return const CacheFailure('فشل تحديث المخزون');
    }

    // تسجيل حركة الإرجاع
    final movement = StockMovement(
      id: const Uuid().v4(),
      productId: item.productId,
      productName: item.productName,
      type: MovementType.returned,
      quantity: item.quantity,
      stockBefore: stockBefore,
      stockAfter: stockAfter,
      note: 'استرجاع - فاتورة',
      date: DateTime.now(),
    );

    await inventoryRepository.addMovement(movement);

    return null;
  }
}

class ReturnInvoiceParams {
  final String invoiceId;

  const ReturnInvoiceParams({required this.invoiceId});
}
