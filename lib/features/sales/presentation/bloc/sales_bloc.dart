import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/invoice.dart';
import '../../domain/usecases/sales_usecases.dart';
import '../../../../core/usecase/usecase.dart';

part 'sales_event.dart';
part 'sales_state.dart';

class SalesBloc extends Bloc<SalesEvent, SalesState> {
  final GetInvoicesUseCase getInvoicesUseCase;
  final SaveInvoiceUseCase saveInvoiceUseCase;
  final DeleteInvoiceUseCase deleteInvoiceUseCase;
  final CompleteSaleUseCase completeSaleUseCase;
  final ReturnInvoiceUseCase returnInvoiceUseCase;

  SalesBloc({
    required this.getInvoicesUseCase,
    required this.saveInvoiceUseCase,
    required this.deleteInvoiceUseCase,
    required this.completeSaleUseCase,
    required this.returnInvoiceUseCase,
  }) : super(const SalesState()) {
    on<LoadInvoicesEvent>(_onLoad);
    on<SaveInvoiceEvent>(_onSave);
    on<DeleteInvoiceEvent>(_onDelete);
    on<ReturnInvoiceEvent>(_onReturn);
    on<CompleteSaleEvent>(_onCompleteSale);
  }

  Future<void> _onLoad(
      LoadInvoicesEvent event, Emitter<SalesState> emit) async {
    emit(state.copyWith(status: SalesStatus.loading));
    final result = await getInvoicesUseCase(NoParams());
    result.fold(
      (f) =>
          emit(state.copyWith(status: SalesStatus.error, message: f.message)),
      (invoices) =>
          emit(state.copyWith(status: SalesStatus.loaded, invoices: invoices)),
    );
  }

  Future<void> _onSave(SaveInvoiceEvent event, Emitter<SalesState> emit) async {
    final result = await saveInvoiceUseCase(event.invoice);
    result.fold(
      (f) =>
          emit(state.copyWith(status: SalesStatus.error, message: f.message)),
      (_) {
        emit(state.copyWith(
            status: SalesStatus.success, message: 'تم حفظ الفاتورة'));
        add(LoadInvoicesEvent());
      },
    );
  }

  Future<void> _onDelete(
      DeleteInvoiceEvent event, Emitter<SalesState> emit) async {
    final result = await deleteInvoiceUseCase(event.id);
    result.fold(
      (f) =>
          emit(state.copyWith(status: SalesStatus.error, message: f.message)),
      (_) {
        emit(state.copyWith(
            status: SalesStatus.success, message: 'تم حذف الفاتورة'));
        add(LoadInvoicesEvent());
      },
    );
  }

  /// إتمام عملية البيع مع خصم المخزون
  Future<void> _onCompleteSale(
      CompleteSaleEvent event, Emitter<SalesState> emit) async {
    emit(state.copyWith(status: SalesStatus.loading));

    final result =
        await completeSaleUseCase(CompleteSaleParams(invoice: event.invoice));

    result.fold(
      (f) =>
          emit(state.copyWith(status: SalesStatus.error, message: f.message)),
      (invoice) {
        emit(state.copyWith(
            status: SalesStatus.success,
            message: 'تم إتمام البيع وخصم المخزون'));
        add(LoadInvoicesEvent());
      },
    );
  }

  /// استرجاع الفاتورة مع إعادة الكميات للمخزون
  Future<void> _onReturn(
      ReturnInvoiceEvent event, Emitter<SalesState> emit) async {
    emit(state.copyWith(status: SalesStatus.loading));

    final result =
        await returnInvoiceUseCase(ReturnInvoiceParams(invoiceId: event.id));

    result.fold(
      (f) =>
          emit(state.copyWith(status: SalesStatus.error, message: f.message)),
      (_) {
        emit(state.copyWith(
            status: SalesStatus.success,
            message: 'تم استرجاع الفاتورة وإعادة الكميات للمخزون'));
        add(LoadInvoicesEvent());
      },
    );
  }
}
