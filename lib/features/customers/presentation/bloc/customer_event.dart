part of 'customer_bloc.dart';

abstract class CustomerEvent extends Equatable {
  const CustomerEvent();
  @override
  List<Object?> get props => [];
}

class LoadCustomersEvent extends CustomerEvent {}

class AddCustomerEvent extends CustomerEvent {
  final Customer customer;
  const AddCustomerEvent(this.customer);
  @override
  List<Object?> get props => [customer];
}

class UpdateCustomerEvent extends CustomerEvent {
  final Customer customer;
  const UpdateCustomerEvent(this.customer);
  @override
  List<Object?> get props => [customer];
}

class DeleteCustomerEvent extends CustomerEvent {
  final String id;
  const DeleteCustomerEvent(this.id);
  @override
  List<Object?> get props => [id];
}
