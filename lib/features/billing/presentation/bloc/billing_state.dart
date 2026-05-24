part of 'billing_bloc.dart';

class BillingState extends Equatable {
  final List<CartItem> cartItems;
  final String? error;
  final String? warning;
  final bool isPrinting;
  final bool printSuccess;

  const BillingState({
    this.cartItems = const [],
    this.error,
    this.warning,
    this.isPrinting = false,
    this.printSuccess = false,
  });

  double get totalAmount => cartItems.fold(0, (sum, item) => sum + item.total);

  BillingState copyWith({
    List<CartItem>? cartItems,
    String? error,
    bool clearError = false,
    String? warning,
    bool clearWarning = false,
    bool? isPrinting,
    bool? printSuccess,
  }) {
    return BillingState(
      cartItems: cartItems ?? this.cartItems,
      error: clearError ? null : (error ?? this.error),
      warning: clearWarning ? null : (warning ?? this.warning),
      isPrinting: isPrinting ?? this.isPrinting,
      printSuccess: printSuccess ?? this.printSuccess,
    );
  }

  @override
  List<Object?> get props => [cartItems, error, warning, isPrinting, printSuccess];
}
