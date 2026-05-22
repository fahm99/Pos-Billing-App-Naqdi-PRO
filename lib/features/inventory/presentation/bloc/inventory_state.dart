part of 'inventory_bloc.dart';

enum InventoryStatus { initial, loading, loaded, success, error }

class InventoryState extends Equatable {
  final InventoryStatus status;
  final List<StockMovement> movements;
  final String? message;

  const InventoryState({
    this.status = InventoryStatus.initial,
    this.movements = const [],
    this.message,
  });

  InventoryState copyWith({
    InventoryStatus? status,
    List<StockMovement>? movements,
    String? message,
  }) {
    return InventoryState(
      status: status ?? this.status,
      movements: movements ?? this.movements,
      message: message,
    );
  }

  @override
  List<Object?> get props => [status, movements, message];
}
