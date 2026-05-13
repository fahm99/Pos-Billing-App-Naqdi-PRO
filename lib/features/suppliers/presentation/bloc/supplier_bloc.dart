import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/supplier.dart';
import '../../domain/usecases/supplier_usecases.dart';
import '../../../../core/usecase/usecase.dart';

part 'supplier_event.dart';
part 'supplier_state.dart';

class SupplierBloc extends Bloc<SupplierEvent, SupplierState> {
  final GetSuppliersUseCase getSuppliersUseCase;
  final AddSupplierUseCase addSupplierUseCase;
  final UpdateSupplierUseCase updateSupplierUseCase;
  final DeleteSupplierUseCase deleteSupplierUseCase;

  SupplierBloc({
    required this.getSuppliersUseCase,
    required this.addSupplierUseCase,
    required this.updateSupplierUseCase,
    required this.deleteSupplierUseCase,
  }) : super(const SupplierState()) {
    on<LoadSuppliersEvent>(_onLoad);
    on<AddSupplierEvent>(_onAdd);
    on<UpdateSupplierEvent>(_onUpdate);
    on<DeleteSupplierEvent>(_onDelete);
  }

  Future<void> _onLoad(
      LoadSuppliersEvent event, Emitter<SupplierState> emit) async {
    emit(state.copyWith(status: SupplierStatus.loading));
    final result = await getSuppliersUseCase(NoParams());
    result.fold(
      (f) => emit(
          state.copyWith(status: SupplierStatus.error, message: f.message)),
      (suppliers) => emit(
          state.copyWith(status: SupplierStatus.loaded, suppliers: suppliers)),
    );
  }

  Future<void> _onAdd(
      AddSupplierEvent event, Emitter<SupplierState> emit) async {
    final result = await addSupplierUseCase(event.supplier);
    result.fold(
      (f) => emit(
          state.copyWith(status: SupplierStatus.error, message: f.message)),
      (_) {
        emit(state.copyWith(
            status: SupplierStatus.success, message: 'تمت إضافة المورد'));
        add(LoadSuppliersEvent());
      },
    );
  }

  Future<void> _onUpdate(
      UpdateSupplierEvent event, Emitter<SupplierState> emit) async {
    final result = await updateSupplierUseCase(event.supplier);
    result.fold(
      (f) => emit(
          state.copyWith(status: SupplierStatus.error, message: f.message)),
      (_) {
        emit(state.copyWith(
            status: SupplierStatus.success, message: 'تم تحديث المورد'));
        add(LoadSuppliersEvent());
      },
    );
  }

  Future<void> _onDelete(
      DeleteSupplierEvent event, Emitter<SupplierState> emit) async {
    final result = await deleteSupplierUseCase(event.id);
    result.fold(
      (f) => emit(
          state.copyWith(status: SupplierStatus.error, message: f.message)),
      (_) {
        emit(state.copyWith(
            status: SupplierStatus.success, message: 'تم حذف المورد'));
        add(LoadSuppliersEvent());
      },
    );
  }
}
