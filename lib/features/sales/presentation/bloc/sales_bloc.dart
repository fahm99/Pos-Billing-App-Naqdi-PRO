import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/invoice.dart';
import '../../domain/usecases/sales_usecases.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../product/domain/usecases/product_usecases.dart';
part 'sales_event.dart';
part 'sales_state.dart';

/// SalesBloc - كتلة إدارة المبيعات
class SalesBloc extends Bloc<SalesEvent, SalesState> {
  final GetInvoicesUseCase getInvoicesUseCase;
  final SaveInvoiceUseCase saveInvoiceUseCase;
  final DeleteInvoiceUseCase deleteInvoiceUseCase;
  final CompleteSaleUseCase completeSaleUseCase;
  final ReturnInvoiceUseCase returnInvoiceUseCase;
  final GetProductsUseCase getProductsUseCase;

  SalesBloc({
    required this.getInvoicesUseCase,
    required this.saveInvoiceUseCase,
    required this.deleteInvoiceUseCase,
    required this.completeSaleUseCase,
    required this.returnInvoiceUseCase,
    required this.getProductsUseCase,
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

  /// إتمام عملية البيع مع خصم المخزون وتحديث لحظي
  Future<void> _onCompleteSale(
      CompleteSaleEvent event, Emitter<SalesState> emit) async {
    emit(state.copyWith(status: SalesStatus.loading));

    final result =
        await completeSaleUseCase(CompleteSaleParams(invoice: event.invoice));

    result.fold(
      (f) =>
          emit(state.copyWith(status: SalesStatus.error, message: f.message)),
      (invoice) async {
        String message = 'تم إتمام البيع وخصم المخزون';

        // التحقق من المنتجات التي وصلت أو انخفضت عن حد إعادة الطلب
        final productsResult = await getProductsUseCase(NoParams());
        productsResult.fold(
          (_) {},
          (products) {
            final reorderProducts = <String>[];
            for (final item in invoice.items) {
              final product = products.where((p) => p.id == item.productId).firstOrNull;
              if (product != null &&
                  product.stock <= product.minStock) {
                reorderProducts.add(product.name);
              }
            }
            if (reorderProducts.isNotEmpty) {
              message += '\n\n⚠️ تنبيه إعادة الطلب:\n';
              message +=
                  'المنتجات التالية وصلت لحد الطلب: ${reorderProducts.join('، ')}';
              message += '\nيجب عليك طلبها وتوفيرها في المخزون';
            }
          },
        );

        emit(state.copyWith(
            status: SalesStatus.success,
            message: message));
        add(LoadInvoicesEvent());
      },
    );
  }

  /// استرجاع الفاتورة مع إعادة الكميات للمخزون وتحديث لحظي
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
        // تحديث لحظي للمخزون بعد الإرجاع
      },
    );
  }
}
