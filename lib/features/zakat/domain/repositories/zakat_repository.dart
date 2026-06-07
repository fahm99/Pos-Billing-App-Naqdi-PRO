import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import '../entities/zakat_payment.dart';

abstract class ZakatRepository {
  Future<Either<Failure, List<ZakatPayment>>> getPayments();
  Future<Either<Failure, void>> addPayment(ZakatPayment payment);
  Future<Either<Failure, void>> deletePayment(String id);
  Future<Either<Failure, double>> getTotalPaid();
}
