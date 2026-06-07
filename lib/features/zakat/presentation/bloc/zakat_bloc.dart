import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/zakat_calculation.dart';
import '../../domain/entities/zakat_payment.dart';
import '../../domain/usecases/zakat_usecases.dart';

part 'zakat_event.dart';
part 'zakat_state.dart';

class ZakatBloc extends Bloc<ZakatEvent, ZakatState> {
  final CalculateZakatUseCase calculateZakatUseCase;
  final GetZakatPaymentsUseCase getPaymentsUseCase;
  final AddZakatPaymentUseCase addPaymentUseCase;
  final DeleteZakatPaymentUseCase deletePaymentUseCase;
  final GetZakatTotalPaidUseCase getTotalPaidUseCase;
  final Uuid _uuid = const Uuid();

  ZakatBloc({
    required this.calculateZakatUseCase,
    required this.getPaymentsUseCase,
    required this.addPaymentUseCase,
    required this.deletePaymentUseCase,
    required this.getTotalPaidUseCase,
  }) : super(const ZakatState()) {
    on<LoadZakatEvent>(_onLoad);
    on<PayZakatEvent>(_onPay);
    on<DeleteZakatPaymentEvent>(_onDelete);
  }

  Future<void> _onLoad(LoadZakatEvent event, Emitter<ZakatState> emit) async {
    emit(state.copyWith(status: ZakatStatus.loading));

    final calcResult = await calculateZakatUseCase(event.from, event.to);
    final paymentsResult = await getPaymentsUseCase(NoParams());
    final totalPaidResult = await getTotalPaidUseCase(NoParams());

    ZakatCalculation? calculation;
    if (calcResult.isRight()) {
      calculation = calcResult.getRight().toNullable();
    }

    List<ZakatPayment> payments = [];
    if (paymentsResult.isRight()) {
      payments = paymentsResult.getRight().toNullable() ?? [];
    }

    double totalPaid = 0;
    if (totalPaidResult.isRight()) {
      totalPaid = totalPaidResult.getRight().toNullable() ?? 0;
    }

    emit(state.copyWith(
      status: ZakatStatus.loaded,
      calculation: calculation,
      payments: payments,
      totalPaid: totalPaid,
    ));
  }

  Future<void> _onPay(PayZakatEvent event, Emitter<ZakatState> emit) async {
    final payment = ZakatPayment(
      id: _uuid.v4(),
      amount: event.amount,
      date: DateTime.now(),
      calculationFrom: event.from,
      calculationTo: event.to,
      totalSalesProfit: event.totalSalesProfit,
      totalExpenses: event.totalExpenses,
      status: ZakatPaymentStatus.paid,
    );

    final result = await addPaymentUseCase(payment);
    if (result.isRight()) {
      emit(state.copyWith(status: ZakatStatus.paymentSuccess));
      add(LoadZakatEvent(from: event.from, to: event.to));
    }
  }

  Future<void> _onDelete(
      DeleteZakatPaymentEvent event, Emitter<ZakatState> emit) async {
    final result = await deletePaymentUseCase(event.paymentId);
    if (result.isRight()) {
      final payments = List<ZakatPayment>.from(state.payments)
        ..removeWhere((p) => p.id == event.paymentId);
      emit(state.copyWith(payments: payments));
    }
  }
}
