import 'package:hive/hive.dart';
import '../../domain/entities/shop.dart';

part 'shop_model.g.dart';

@HiveType(typeId: 1)
class ShopModel extends Shop {
  @override
  @HiveField(0)
  final String name;
  @override
  @HiveField(1)
  final String addressLine1;
  @override
  @HiveField(2)
  final String addressLine2;
  @override
  @HiveField(3)
  final String phoneNumber;
  @override
  @HiveField(4)
  final String upiId;
  @override
  @HiveField(5)
  final String footerText;
  @override
  @HiveField(6)
  final String currencyName;
  @override
  @HiveField(7)
  final String currencySymbol;
  @override
  @HiveField(8)
  final String currencyLogo;
  @override
  @HiveField(9)
  final String shopLogo;
  @override
  @HiveField(10)
  final double defaultTaxPercent;

  const ShopModel({
    required this.name,
    required this.addressLine1,
    required this.addressLine2,
    required this.phoneNumber,
    required this.upiId,
    required this.footerText,
    this.currencyName = 'ريال',
    this.currencySymbol = 'ر.س',
    this.currencyLogo = '',
    this.shopLogo = '',
    this.defaultTaxPercent = 0,
  }) : super(
          name: name,
          addressLine1: addressLine1,
          addressLine2: addressLine2,
          phoneNumber: phoneNumber,
          upiId: upiId,
          footerText: footerText,
          currencyName: currencyName,
          currencySymbol: currencySymbol,
          currencyLogo: currencyLogo,
          shopLogo: shopLogo,
          defaultTaxPercent: defaultTaxPercent,
        );

  factory ShopModel.fromEntity(Shop shop) {
    return ShopModel(
      name: shop.name,
      addressLine1: shop.addressLine1,
      addressLine2: shop.addressLine2,
      phoneNumber: shop.phoneNumber,
      upiId: shop.upiId,
      footerText: shop.footerText,
      currencyName: shop.currencyName,
      currencySymbol: shop.currencySymbol,
      currencyLogo: shop.currencyLogo,
      shopLogo: shop.shopLogo,
      defaultTaxPercent: shop.defaultTaxPercent,
    );
  }

  Shop toEntity() => this;
}
