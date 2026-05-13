import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import '../entities/invoice.dart';

abstract class SalesRepository {
  Future<Either<Failure, List<Invoice>>> getInvoices();
  Future<Either<Failure, Invoice>> getInvoiceById(String id);
  Future<Either<Failure, void>> saveInvoice(Invoice invoice);
  Future<Either<Failure, void>> deleteInvoice(String id);
}
