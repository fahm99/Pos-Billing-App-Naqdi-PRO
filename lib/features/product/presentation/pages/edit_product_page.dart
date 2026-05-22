import 'dart:io';
import 'package:billing_app/core/widgets/input_label.dart';
import 'package:billing_app/core/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../bloc/product_bloc.dart';
import '../../domain/entities/product.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_validators.dart';
import '../../../shop/presentation/bloc/shop_bloc.dart';

class EditProductPage extends StatefulWidget {
  final Product product;
  const EditProductPage({super.key, required this.product});

  @override
  State<EditProductPage> createState() => _EditProductPageState();
}

class _EditProductPageState extends State<EditProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  late TextEditingController _nameCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _costPriceCtrl;
  late TextEditingController _stockCtrl;
  late TextEditingController _minStockCtrl;
  late TextEditingController _unitCtrl;
  late TextEditingController _categoryCtrl;
  DateTime? _expiryDate;
  String? _imageUrl;
  String _currencySymbol = 'ر.س';

  final List<String> _unitOptions = ['قطعة', 'كيلو', 'لتر', 'علبة', 'كرتون', 'زوج', 'متر'];
  final List<String> _categoryOptions = ['عام', 'مواد غذائية', 'مشروبات', 'منظفات', 'مستحضرات تجميل', 'ملابس', 'الكترونيات', 'قرطاسية'];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.product.name);
    _priceCtrl = TextEditingController(text: widget.product.price.toStringAsFixed(2));
    _costPriceCtrl = TextEditingController(text: widget.product.costPrice.toStringAsFixed(2));
    _stockCtrl = TextEditingController(text: '${widget.product.stock}');
    _minStockCtrl = TextEditingController(text: '${widget.product.minStock}');
    _unitCtrl = TextEditingController(text: widget.product.unit);
    _categoryCtrl = TextEditingController(text: widget.product.category);
    _expiryDate = widget.product.expiryDate;
    _imageUrl = widget.product.imageUrl;
    _loadCurrencySymbol();
  }

  void _loadCurrencySymbol() {
    final shopState = context.read<ShopBloc>().state;
    if (shopState is ShopLoaded && shopState.shop.currencySymbol.isNotEmpty) {
      setState(() => _currencySymbol = shopState.shop.currencySymbol);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _costPriceCtrl.dispose();
    _stockCtrl.dispose();
    _minStockCtrl.dispose();
    _unitCtrl.dispose();
    _categoryCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildImageSourceOption(
                icon: Icons.camera_alt,
                label: 'الكاميرا',
                source: ImageSource.camera,
              ),
              _buildImageSourceOption(
                icon: Icons.photo_library,
                label: 'المعرض',
                source: ImageSource.gallery,
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = 'product_${const Uuid().v4()}.jpg';
        final savedPath = '${appDir.path}/$fileName';
        await File(image.path).copy(savedPath);
        setState(() => _imageUrl = savedPath);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildImageSourceOption({
    required IconData icon,
    required String label,
    required ImageSource source,
  }) {
    return GestureDetector(
      onTap: () => Navigator.pop(context, source),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppTheme.primaryColor, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final updatedProduct = widget.product.copyWith(
        name: _nameCtrl.text.trim(),
        price: double.tryParse(_priceCtrl.text) ?? widget.product.price,
        costPrice: double.tryParse(_costPriceCtrl.text) ?? widget.product.costPrice,
        stock: int.tryParse(_stockCtrl.text) ?? widget.product.stock,
        minStock: int.tryParse(_minStockCtrl.text) ?? widget.product.minStock,
        unit: _unitCtrl.text.trim().isEmpty ? widget.product.unit : _unitCtrl.text.trim(),
        category: _categoryCtrl.text.trim().isEmpty ? widget.product.category : _categoryCtrl.text.trim(),
        expiryDate: _expiryDate,
        clearExpiryDate: _expiryDate == null && widget.product.expiryDate != null,
        imageUrl: _imageUrl,
        clearImageUrl: _imageUrl == null && widget.product.imageUrl != null,
      );

      context.read<ProductBloc>().add(UpdateProduct(updatedProduct));
      context.pop();
    }
  }

  Future<void> _pickExpiryDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      locale: const Locale('ar'),
    );
    if (date != null) {
      setState(() => _expiryDate = date);
    }
  }

  Widget _buildDefaultImage() {
    return Center(
      child: Image.asset(
        'assets/naqdilogo.jpg',
        width: 40,
        height: 40,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Icon(
          Icons.inventory_2_outlined,
          color: AppTheme.primaryColor,
          size: 28,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.chevron_left,
                size: 32, color: Theme.of(context).primaryColor),
            onPressed: () => context.pop(),
          ),
          title: const Text('تعديل المنتج',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          centerTitle: true,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // صورة المنتج
                  Center(
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Stack(
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey[300]!, width: 2),
                            ),
                            child: _imageUrl != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: Image.file(
                                      File(_imageUrl!),
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => _buildDefaultImage(),
                                    ),
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_photo_alternate_outlined,
                                          size: 40, color: Colors.grey[400]),
                                      const SizedBox(height: 8),
                                      Text('إضافة صورة',
                                          style: TextStyle(
                                              fontSize: 12, color: Colors.grey[500])),
                                    ],
                                  ),
                          ),
                          if (_imageUrl != null)
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () => setState(() => _imageUrl = null),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close, color: Colors.white, size: 14),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text('اضغط لتغيير صورة المنتج (اختياري)',
                        style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                  ),
                  const SizedBox(height: 24),
                  // عرض الباركود (للقراءة فقط)
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.primaryColor.withOpacity(0.1)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.qr_code_scanner,
                            color: AppTheme.primaryColor, size: 28),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('الباركود',
                                style: TextStyle(fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor.withOpacity(0.7))),
                            const SizedBox(height: 2),
                            Text(widget.product.barcode,
                                style: const TextStyle(fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'monospace')),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // اسم المنتج
                  const InputLabel(text: 'اسم المنتج'),
                  TextFormField(
                    controller: _nameCtrl,
                    textCapitalization: TextCapitalization.words,
                    validator: AppValidators.required('الرجاء إدخال الاسم'),
                  ),
                  const SizedBox(height: 24),

                  // سعر البيع والتكلفة
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const InputLabel(text: 'سعر البيع'),
                            TextFormField(
                              controller: _priceCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                prefixText: '$_currencySymbol ',
                                prefixStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                              ),
                              validator: AppValidators.price,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const InputLabel(text: 'تكلفة المنتج'),
                            TextFormField(
                              controller: _costPriceCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                prefixText: '$_currencySymbol ',
                                prefixStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // الكمية ونقطة الطلب
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const InputLabel(text: 'الكمية'),
                            TextFormField(
                              controller: _stockCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(hintText: '0'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const InputLabel(text: 'نقطة الطلب'),
                            TextFormField(
                              controller: _minStockCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(hintText: '5'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // الوحدة والتصنيف
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const InputLabel(text: 'الوحدة'),
                            Autocomplete<String>(
                              optionsBuilder: (textEditingValue) {
                                if (textEditingValue.text.isEmpty) return _unitOptions;
                                return _unitOptions.where((opt) =>
                                    opt.contains(textEditingValue.text));
                              },
                              initialValue: TextEditingValue(text: _unitCtrl.text),
                              onSelected: (value) => _unitCtrl.text = value,
                              fieldViewBuilder: (context, ctrl, focusNode, onSubmit) {
                                return TextFormField(
                                  controller: ctrl,
                                  focusNode: focusNode,
                                  decoration: const InputDecoration(hintText: 'قطعة'),
                                  onChanged: (v) => _unitCtrl.text = v,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const InputLabel(text: 'التصنيف'),
                            Autocomplete<String>(
                              optionsBuilder: (textEditingValue) {
                                if (textEditingValue.text.isEmpty) return _categoryOptions;
                                return _categoryOptions.where((opt) =>
                                    opt.contains(textEditingValue.text));
                              },
                              initialValue: TextEditingValue(text: _categoryCtrl.text),
                              onSelected: (value) => _categoryCtrl.text = value,
                              fieldViewBuilder: (context, ctrl, focusNode, onSubmit) {
                                return TextFormField(
                                  controller: ctrl,
                                  focusNode: focusNode,
                                  decoration: const InputDecoration(hintText: 'عام'),
                                  onChanged: (v) => _categoryCtrl.text = v,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // تاريخ الانتهاء
                  const InputLabel(text: 'تاريخ انتهاء الصلاحية (اختياري)'),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _pickExpiryDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, color: AppTheme.primaryColor, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _expiryDate != null
                                  ? DateFormat('yyyy/MM/dd', 'ar').format(_expiryDate!)
                                  : 'اختر تاريخ الانتهاء',
                              style: TextStyle(
                                color: _expiryDate != null ? Colors.black87 : Colors.grey[500],
                                fontSize: 14,
                              ),
                            ),
                          ),
                          if (_expiryDate != null)
                            GestureDetector(
                              onTap: () => setState(() => _expiryDate = null),
                              child: const Icon(Icons.close, color: Colors.red, size: 18),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: PrimaryButton(
          onPressed: _submit,
          icon: Icons.save,
          label: 'حفظ التغييرات',
        ));
  }
}