import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/invoice.dart';
import '../repositories/sales_repository.dart';

class GetInvoicesUseCase implements UseCase<List<Invoice>, NoParams> {
  final SalesRepository repository;
  GetInvoicesUseCase(this.repository);

  @override
  Future<Either<Failure, List<Invoice>>> call(NoParams params) =>
      repository.getInvoices();
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
