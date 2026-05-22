part of 'supplier_bloc.dart';

enum SupplierStatus { initial, loading, loaded, success, error }

class SupplierState extends Equatable {
  final SupplierStatus status;
  final List<Supplier> suppliers;
  final String? message;

  const SupplierState({
    this.status = SupplierStatus.initial,
    this.suppliers = const [],
    this.message,
  });

  SupplierState copyWith({
    SupplierStatus? status,
    List<Supplier>? suppliers,
    String? message,
  }) {
    return SupplierState(
      status: status ?? this.status,
      suppliers: suppliers ?? this.suppliers,
      message: message,
    );
  }

  @override
  List<Object?> get props => [status, suppliers, message];
}
