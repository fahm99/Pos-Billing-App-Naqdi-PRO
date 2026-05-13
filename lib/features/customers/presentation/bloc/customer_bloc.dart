import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/customer.dart';
import '../../domain/usecases/customer_usecases.dart';
import '../../../../core/usecase/usecase.dart';

part 'customer_event.dart';
part 'customer_state.dart';

class CustomerBloc extends Bloc<CustomerEvent, CustomerState> {
  final GetCustomersUseCase getCustomersUseCase;
  final AddCustomerUseCase addCustomerUseCase;
  final UpdateCustomerUseCase updateCustomerUseCase;
  final DeleteCustomerUseCase deleteCustomerUseCase;

  CustomerBloc({
    required this.getCustomersUseCase,
    required this.addCustomerUseCase,
    required this.updateCustomerUseCase,
    required this.deleteCustomerUseCase,
  }) : super(const CustomerState()) {
    on<LoadCustomersEvent>(_onLoad);
    on<AddCustomerEvent>(_onAdd);
    on<UpdateCustomerEvent>(_onUpdate);
    on<DeleteCustomerEvent>(_onDelete);
  }

  Future<void> _onLoad(
      LoadCustomersEvent event, Emitter<CustomerState> emit) async {
    emit(state.copyWith(status: CustomerStatus.loading));
    final result = await getCustomersUseCase(NoParams());
    result.fold(
      (f) => emit(
          state.copyWith(status: CustomerStatus.error, message: f.message)),
      (customers) => emit(
          state.copyWith(status: CustomerStatus.loaded, customers: customers)),
    );
  }

  Future<void> _onAdd(
      AddCustomerEvent event, Emitter<CustomerState> emit) async {
    final result = await addCustomerUseCase(event.customer);
    result.fold(
      (f) => emit(
          state.copyWith(status: CustomerStatus.error, message: f.message)),
      (_) {
        emit(state.copyWith(
            status: CustomerStatus.success, message: 'تمت إضافة العميل'));
        add(LoadCustomersEvent());
      },
    );
  }

  Future<void> _onUpdate(
      UpdateCustomerEvent event, Emitter<CustomerState> emit) async {
    final result = await updateCustomerUseCase(event.customer);
    result.fold(
      (f) => emit(
          state.copyWith(status: CustomerStatus.error, message: f.message)),
      (_) {
        emit(state.copyWith(
            status: CustomerStatus.success, message: 'تم تحديث العميل'));
        add(LoadCustomersEvent());
      },
    );
  }

  Future<void> _onDelete(
      DeleteCustomerEvent event, Emitter<CustomerState> emit) async {
    final result = await deleteCustomerUseCase(event.id);
    result.fold(
      (f) => emit(
          state.copyWith(status: CustomerStatus.error, message: f.message)),
      (_) {
        emit(state.copyWith(
            status: CustomerStatus.success, message: 'تم حذف العميل'));
        add(LoadCustomersEvent());
      },
    );
  }
}
