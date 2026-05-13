import 'package:fpdart/fpdart.dart';
import '../../../../core/data/hive_database.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/invoice.dart';
import '../../domain/repositories/sales_repository.dart';
import '../models/invoice_model.dart';

class SalesRepositoryImpl implements SalesRepository {
  @override
  Future<Either<Failure, List<Invoice>>> getInvoices() async {
    try {
      final invoices = HiveDatabase.invoiceBox.values
          .map((m) => m.toEntity())
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));
      return Right(invoices);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Invoice>> getInvoiceById(String id) async {
    try {
      final model = HiveDatabase.invoiceBox.get(id);
      if (model == null) return const Left(CacheFailure('الفاتورة غير موجودة'));
      return Right(model.toEntity());
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> saveInvoice(Invoice invoice) async {
    try {
      final model = InvoiceModel.fromEntity(invoice);
      await HiveDatabase.invoiceBox.put(model.id, model);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteInvoice(String id) async {
    try {
      await HiveDatabase.invoiceBox.delete(id);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
