import 'package:equatable/equatable.dart';

class Shop extends Equatable {
  final String name;
  final String addressLine1;
  final String addressLine2;
  final String phoneNumber;
  final String upiId;
  final String footerText;
  final String currencyName;
  final String currencySymbol;
  final String currencyLogo;
  final String shopLogo;
  final double defaultTaxPercent;

  const Shop({
    this.name = '',
    this.addressLine1 = '',
    this.addressLine2 = '',
    this.phoneNumber = '',
    this.upiId = '',
    this.footerText = '',
    this.currencyName = 'ريال',
    this.currencySymbol = 'ر.س',
    this.currencyLogo = '',
    this.shopLogo = '',
    this.defaultTaxPercent = 0,
  });

  Shop copyWith({
    String? name,
    String? addressLine1,
    String? addressLine2,
    String? phoneNumber,
    String? upiId,
    String? footerText,
    String? currencyName,
    String? currencySymbol,
    String? currencyLogo,
    String? shopLogo,
    double? defaultTaxPercent,
  }) {
    return Shop(
      name: name ?? this.name,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      upiId: upiId ?? this.upiId,
      footerText: footerText ?? this.footerText,
      currencyName: currencyName ?? this.currencyName,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      currencyLogo: currencyLogo ?? this.currencyLogo,
      shopLogo: shopLogo ?? this.shopLogo,
      defaultTaxPercent: defaultTaxPercent ?? this.defaultTaxPercent,
    );
  }

  @override
  List<Object?> get props => [
        name,
        addressLine1,
        addressLine2,
        phoneNumber,
        upiId,
        footerText,
        currencyName,
        currencySymbol,
        currencyLogo,
        shopLogo,
        defaultTaxPercent,
      ];
}
