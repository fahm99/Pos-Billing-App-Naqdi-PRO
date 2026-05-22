part of 'customer_bloc.dart';

enum CustomerStatus { initial, loading, loaded, success, error }

class CustomerState extends Equatable {
  final CustomerStatus status;
  final List<Customer> customers;
  final String? message;

  const CustomerState({
    this.status = CustomerStatus.initial,
    this.customers = const [],
    this.message,
  });

  CustomerState copyWith({
    CustomerStatus? status,
    List<Customer>? customers,
    String? message,
  }) {
    return CustomerState(
      status: status ?? this.status,
      customers: customers ?? this.customers,
      message: message,
    );
  }

  @override
  List<Object?> get props => [status, customers, message];
}
