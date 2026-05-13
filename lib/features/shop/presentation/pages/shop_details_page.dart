import 'dart:io';
import 'package:billing_app/core/widgets/input_label.dart';
import 'package:billing_app/core/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../domain/entities/shop.dart';
import '../bloc/shop_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_validators.dart';

class ShopDetailsPage extends StatefulWidget {
  const ShopDetailsPage({super.key});

  @override
  State<ShopDetailsPage> createState() => _ShopDetailsPageState();
}

class _ShopDetailsPageState extends State<ShopDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  late TextEditingController _nameController;
  late TextEditingController _address1Controller;
  late TextEditingController _address2Controller;
  late TextEditingController _phoneController;
  late TextEditingController _upiController;
  late TextEditingController _footerController;
  late TextEditingController _currencyNameController;
  late TextEditingController _currencySymbolController;
  late TextEditingController _currencyLogoController;
  late TextEditingController _shopLogoController;
  late TextEditingController _defaultTaxController;
  File? _shopLogoFile;
  String? _shopLogoUrl;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _address1Controller = TextEditingController();
    _address2Controller = TextEditingController();
    _phoneController = TextEditingController();
    _upiController = TextEditingController();
    _footerController = TextEditingController();
    _currencyNameController = TextEditingController();
    _currencySymbolController = TextEditingController();
    _currencyLogoController = TextEditingController();
    _shopLogoController = TextEditingController();
    _defaultTaxController = TextEditingController();

    context.read<ShopBloc>().add(LoadShopEvent());
  }

  void _updateControllers(Shop shop) {
    if (_nameController.text.isEmpty && shop.name.isNotEmpty) {
      _nameController.text = shop.name;
      _address1Controller.text = shop.addressLine1;
      _address2Controller.text = shop.addressLine2;
      _phoneController.text = shop.phoneNumber;
      _upiController.text = shop.upiId;
      _footerController.text = shop.footerText;
      _currencyNameController.text = shop.currencyName;
      _currencySymbolController.text = shop.currencySymbol;
      _currencyLogoController.text = shop.currencyLogo;
      _shopLogoController.text = shop.shopLogo;
      _shopLogoUrl = shop.shopLogo;
      _defaultTaxController.text = shop.defaultTaxPercent.toString();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _address1Controller.dispose();
    _address2Controller.dispose();
    _phoneController.dispose();
    _upiController.dispose();
    _footerController.dispose();
    _currencyNameController.dispose();
    _currencySymbolController.dispose();
    _currencyLogoController.dispose();
    _shopLogoController.dispose();
    _defaultTaxController.dispose();
    super.dispose();
  }

  Future<void> _pickShopLogo() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );
    if (image != null) {
      setState(() {
        _shopLogoFile = File(image.path);
        _shopLogoUrl = null;
      });
    }
  }

  void _removeShopLogo() {
    setState(() {
      _shopLogoFile = null;
      _shopLogoUrl = null;
      _shopLogoController.text = '';
    });
  }

  void _saveShop() {
    if (_formKey.currentState!.validate()) {
      final shop = Shop(
        name: _nameController.text,
        addressLine1: _address1Controller.text,
        addressLine2: _address2Controller.text,
        phoneNumber: _phoneController.text,
        upiId: _upiController.text,
        footerText: _footerController.text,
        currencyName: _currencyNameController.text.isNotEmpty
            ? _currencyNameController.text
            : 'ريال',
        currencySymbol: _currencySymbolController.text.isNotEmpty
            ? _currencySymbolController.text
            : 'ر.س',
        currencyLogo: _currencyLogoController.text,
        shopLogo: _shopLogoController.text,
        defaultTaxPercent: double.tryParse(_defaultTaxController.text) ?? 0,
      );

      context.read<ShopBloc>().add(UpdateShopEvent(shop));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('بيانات المتجر'),
        ),
        body: BlocConsumer<ShopBloc, ShopState>(
          listener: (context, state) {
            if (state is ShopLoaded) {
              _updateControllers(state.shop);
            } else if (state is ShopOperationSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('تم حفظ بيانات المتجر!'),
                  backgroundColor: Colors.green));
              context.pop();
            } else if (state is ShopError) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(state.message), backgroundColor: Colors.red));
            }
          },
          buildWhen: (previous, current) =>
              current is ShopLoading || current is ShopLoaded,
          builder: (context, state) {
            if (state is ShopLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildLogoSection(),
                    const SizedBox(height: 24),
                    Text('معلومات عامة',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          color: AppTheme.primaryColor.withOpacity(0.8),
                        )),
                    const SizedBox(height: 5),
                    Text(
                      'ستظهر هذه البيانات على الفواتير الرقمية والمطبوعة.',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                    const SizedBox(height: 16),
                    const InputLabel(text: 'اسم المتجر'),
                    _buildTextField(
                      controller: _nameController,
                      hint: 'مثال: سوبرماركت السريع',
                      validator: AppValidators.required('مطلوب'),
                    ),
                    const SizedBox(height: 15),
                    const InputLabel(text: 'العنوان - السطر الأول'),
                    _buildTextField(
                      controller: _address1Controller,
                      hint: 'الحي، المدينة',
                      validator: AppValidators.required('مطلوب'),
                    ),
                    const SizedBox(height: 15),
                    const InputLabel(text: 'العنوان - ا��سطر الثاني (اختياري)'),
                    _buildTextField(
                      controller: _address2Controller,
                      hint: 'الرمز البريدي',
                    ),
                    const SizedBox(height: 15),
                    const InputLabel(text: 'رقم الهاتف'),
                    _buildTextField(
                      controller: _phoneController,
                      hint: '+966 5xxxxxxxx',
                      keyboardType: TextInputType.phone,
                      validator: AppValidators.required('مطلوب'),
                    ),
                    const SizedBox(height: 15),
                    const InputLabel(text: 'معرف UPI'),
                    _buildTextField(
                      controller: _upiController,
                      hint: 'example@bank',
                    ),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const InputLabel(text: 'نص تذييل الفاتورة'),
                        Text('60 حرف كحد أقصى',
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey[400])),
                      ],
                    ),
                    _buildTextField(
                      controller: _footerController,
                      hint: 'شكراً لزيارتكم، نراكم قريباً!',
                      maxLines: 2,
                      maxLength: 60,
                    ),
                    const SizedBox(height: 32),
                    _buildCurrencySection(),
                    const SizedBox(height: 32),
                    _buildTaxSection(),
                  ],
                ),
              ),
            );
          },
        ),
        bottomNavigationBar: PrimaryButton(
          onPressed: _saveShop,
          icon: Icons.save,
          label: 'حفظ البيانات',
        ));
  }

  Widget _buildLogoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('شعار المتجر',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: AppTheme.primaryColor.withOpacity(0.8),
            )),
        const SizedBox(height: 5),
        Text(
          'سيظهر الشعار في رأس الفواتير والتطبيق',
          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _pickShopLogo,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.grey[300]!,
                style: BorderStyle.solid,
              ),
            ),
            child: _shopLogoFile != null
                ? Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(
                          _shopLogoFile!,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: _removeShopLogo,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close,
                                color: Colors.white, size: 12),
                          ),
                        ),
                      ),
                    ],
                  )
                : _shopLogoUrl != null && _shopLogoUrl!.isNotEmpty
                    ? Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(
                              _shopLogoUrl!,
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  _buildPlaceholderIcon(),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: _removeShopLogo,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close,
                                    color: Colors.white, size: 12),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate,
                              size: 32, color: Colors.grey[400]),
                          const SizedBox(height: 4),
                          Text(
                            'إضافة شعار',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholderIcon() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF00A77E).withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.storefront, color: Color(0xFF00A77E), size: 32),
    );
  }

  Widget _buildCurrencySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('إعدادات العملة',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: AppTheme.primaryColor.withOpacity(0.8),
            )),
        const SizedBox(height: 5),
        Text(
          'سيتم استخدام هذه الإعدادات في جميع الفواتير والأسعار.',
          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
        ),
        const SizedBox(height: 16),
        const InputLabel(text: 'اسم العملة'),
        _buildTextField(
          controller: _currencyNameController,
          hint: 'ريال (افتراضي)',
        ),
        const SizedBox(height: 15),
        const InputLabel(text: 'رمز العملة'),
        _buildTextField(
          controller: _currencySymbolController,
          hint: 'ر.س (افتراضي)',
        ),
        const SizedBox(height: 15),
        const InputLabel(text: 'رابط شعار العملة (اختياري)'),
        _buildTextField(
          controller: _currencyLogoController,
          hint: 'https://example.com/currency-logo.png',
        ),
      ],
    );
  }

  Widget _buildTaxSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('إعدادات الضريبة',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: AppTheme.primaryColor.withOpacity(0.8),
            )),
        const SizedBox(height: 5),
        Text(
          'ستكون هذه النسبة الافتراضية لكل منتج جديد',
          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
        ),
        const SizedBox(height: 16),
        const InputLabel(text: 'نسبة الضريبة الافتراضية (%)'),
        _buildTextField(
          controller: _defaultTaxController,
          hint: '0',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    int maxLines = 1,
    int? maxLength,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      maxLength: maxLength,
      textCapitalization: TextCapitalization.words,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
      ),
    );
  }
}
