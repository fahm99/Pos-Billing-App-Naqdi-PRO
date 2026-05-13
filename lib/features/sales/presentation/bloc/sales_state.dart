part of 'sales_bloc.dart';

enum SalesStatus { initial, loading, loaded, success, error }

class SalesState extends Equatable {
  final SalesStatus status;
  final List<Invoice> invoices;
  final String? message;

  const SalesState({
    this.status = SalesStatus.initial,
    this.invoices = const [],
    this.message,
  });

  // Summary getters
  double get totalRevenue =>
      invoices.fold(0.0, (sum, inv) => sum + inv.totalAmount);
  double get totalProfit =>
      invoices.fold(0.0, (sum, inv) => sum + inv.totalProfit);
  int get invoiceCount => invoices.length;

  SalesState copyWith({
    SalesStatus? status,
    List<Invoice>? invoices,
    String? message,
  }) {
    return SalesState(
      status: status ?? this.status,
      invoices: invoices ?? this.invoices,
      message: message,
    );
  }

  @override
  List<Object?> get props => [status, invoices, message];
}
