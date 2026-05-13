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

  SalesBloc({
    required this.getInvoicesUseCase,
    required this.saveInvoiceUseCase,
    required this.deleteInvoiceUseCase,
  }) : super(const SalesState()) {
    on<LoadInvoicesEvent>(_onLoad);
    on<SaveInvoiceEvent>(_onSave);
    on<DeleteInvoiceEvent>(_onDelete);
    on<ReturnInvoiceEvent>(_onReturn);
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

  Future<void> _onReturn(
      ReturnInvoiceEvent event, Emitter<SalesState> emit) async {
    try {
      final invoice = state.invoices.firstWhere((i) => i.id == event.id);
      final returned = Invoice(
        id: invoice.id,
        invoiceNumber: invoice.invoiceNumber,
        date: invoice.date,
        items: invoice.items,
        subtotal: invoice.subtotal,
        discountAmount: invoice.discountAmount,
        taxAmount: invoice.taxAmount,
        totalAmount: invoice.totalAmount,
        paymentMethod: invoice.paymentMethod,
        cashPaid: invoice.cashPaid,
        upiPaid: invoice.upiPaid,
        cardPaid: invoice.cardPaid,
        changeAmount: invoice.changeAmount,
        customerId: invoice.customerId,
        customerName: invoice.customerName,
        status: InvoiceStatus.returned,
        notes: invoice.notes,
      );
      final result = await saveInvoiceUseCase(returned);
      result.fold(
        (f) =>
            emit(state.copyWith(status: SalesStatus.error, message: f.message)),
        (_) {
          emit(state.copyWith(
              status: SalesStatus.success, message: 'تم تسجيل الاسترجاع'));
          add(LoadInvoicesEvent());
        },
      );
    } catch (_) {
      emit(state.copyWith(
          status: SalesStatus.error, message: 'الفاتورة غير موجودة'));
    }
  }
}
