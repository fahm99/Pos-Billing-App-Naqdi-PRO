import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/stock_movement.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../../../product/domain/entities/product.dart';
import '../../../product/domain/repositories/product_repository.dart';

part 'inventory_event.dart';
part 'inventory_state.dart';

class InventoryBloc extends Bloc<InventoryEvent, InventoryState> {
  final InventoryRepository inventoryRepository;
  final ProductRepository productRepository;

  InventoryBloc({
    required this.inventoryRepository,
    required this.productRepository,
  }) : super(const InventoryState()) {
    on<LoadMovementsEvent>(_onLoad);
    on<AddStockEvent>(_onAddStock);
    on<AdjustStockEvent>(_onAdjust);
  }

  Future<void> _onLoad(
      LoadMovementsEvent event, Emitter<InventoryState> emit) async {
    emit(state.copyWith(status: InventoryStatus.loading));
    final result =
        await inventoryRepository.getMovements(productId: event.productId);
    result.fold(
      (f) => emit(
          state.copyWith(status: InventoryStatus.error, message: f.message)),
      (movements) => emit(
          state.copyWith(status: InventoryStatus.loaded, movements: movements)),
    );
  }

  Future<void> _onAddStock(
      AddStockEvent event, Emitter<InventoryState> emit) async {
    final product = event.product;
    final newStock = product.stock + event.quantity;

    // Update product stock
    final updateResult =
        await productRepository.adjustStock(product.id, newStock);
    if (updateResult.isLeft()) {
      emit(state.copyWith(
          status: InventoryStatus.error, message: 'فشل تحديث المخزون'));
      return;
    }

    // Record movement
    final movement = StockMovement(
      id: const Uuid().v4(),
      productId: product.id,
      productName: product.name,
      type: MovementType.stockIn,
      quantity: event.quantity,
      stockBefore: product.stock,
      stockAfter: newStock,
      note: event.note,
      date: DateTime.now(),
    );
    await inventoryRepository.addMovement(movement);

    emit(state.copyWith(
        status: InventoryStatus.success, message: 'تم إضافة المخزون'));
    add(const LoadMovementsEvent());
  }

  Future<void> _onAdjust(
      AdjustStockEvent event, Emitter<InventoryState> emit) async {
    final product = event.product;
    final diff = event.newStock - product.stock;

    final updateResult =
        await productRepository.adjustStock(product.id, event.newStock);
    if (updateResult.isLeft()) {
      emit(state.copyWith(
          status: InventoryStatus.error, message: 'فشل تحديث المخزون'));
      return;
    }

    final movement = StockMovement(
      id: const Uuid().v4(),
      productId: product.id,
      productName: product.name,
      type: MovementType.adjustment,
      quantity: diff.abs(),
      stockBefore: product.stock,
      stockAfter: event.newStock,
      note: event.note,
      date: DateTime.now(),
    );
    await inventoryRepository.addMovement(movement);

    emit(state.copyWith(
        status: InventoryStatus.success, message: 'تم تعديل المخزون'));
    add(const LoadMovementsEvent());
  }
}
