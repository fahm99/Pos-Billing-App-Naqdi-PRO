part of 'sales_bloc.dart';

abstract class SalesEvent extends Equatable {
  const SalesEvent();
  @override
  List<Object?> get props => [];
}

class LoadInvoicesEvent extends SalesEvent {}

class SaveInvoiceEvent extends SalesEvent {
  final Invoice invoice;
  const SaveInvoiceEvent(this.invoice);
  @override
  List<Object?> get props => [invoice];
}

class DeleteInvoiceEvent extends SalesEvent {
  final String id;
  const DeleteInvoiceEvent(this.id);
  @override
  List<Object?> get props => [id];
}

class ReturnInvoiceEvent extends SalesEvent {
  final String id;
  const ReturnInvoiceEvent(this.id);
  @override
  List<Object?> get props => [id];
}
