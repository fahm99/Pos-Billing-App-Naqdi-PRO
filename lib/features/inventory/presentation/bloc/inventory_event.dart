part of 'inventory_bloc.dart';

abstract class InventoryEvent extends Equatable {
  const InventoryEvent();
  @override
  List<Object?> get props => [];
}

class LoadMovementsEvent extends InventoryEvent {
  final String? productId;
  const LoadMovementsEvent({this.productId});
  @override
  List<Object?> get props => [productId];
}

class AddStockEvent extends InventoryEvent {
  final Product product;
  final int quantity;
  final String? note;
  const AddStockEvent(
      {required this.product, required this.quantity, this.note});
  @override
  List<Object?> get props => [product, quantity, note];
}

class AdjustStockEvent extends InventoryEvent {
  final Product product;
  final int newStock;
  final String? note;
  const AdjustStockEvent(
      {required this.product, required this.newStock, this.note});
  @override
  List<Object?> get props => [product, newStock, note];
}
