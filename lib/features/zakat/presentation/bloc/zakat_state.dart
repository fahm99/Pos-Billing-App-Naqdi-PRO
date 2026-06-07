part of 'zakat_bloc.dart';

enum ZakatStatus { initial, loading, loaded, error, paymentSuccess }

class ZakatState extends Equatable {
  final ZakatStatus status;
  final ZakatCalculation? calculation;
  final List<ZakatPayment> payments;
  final double totalPaid;
  final String? errorMessage;

  const ZakatState({
    this.status = ZakatStatus.initial,
    this.calculation,
    this.payments = const [],
    this.totalPaid = 0,
    this.errorMessage,
  });

  ZakatState copyWith({
    ZakatStatus? status,
    ZakatCalculation? calculation,
    List<ZakatPayment>? payments,
    double? totalPaid,
    String? errorMessage,
  }) {
    return ZakatState(
      status: status ?? this.status,
      calculation: calculation ?? this.calculation,
      payments: payments ?? this.payments,
      totalPaid: totalPaid ?? this.totalPaid,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props =>
      [status, calculation, payments, totalPaid, errorMessage];
}
