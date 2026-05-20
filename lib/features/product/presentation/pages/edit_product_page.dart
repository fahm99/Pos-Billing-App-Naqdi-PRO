import 'package:billing_app/core/widgets/input_label.dart';
import 'package:billing_app/core/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../bloc/product_bloc.dart';
import '../../domain/entities/product.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_validators.dart';

/// EditProductPage - شاشة تعديل المنتج محسّنة
/// التعديل: إصلاح BUG فقدان البيانات باستخدام copyWith()
/// + إضافة جميع الحقول (costPrice, stock, minStock, unit, category, expiryDate)
class EditProductPage extends StatefulWidget {
  final Product product;
  const EditProductPage({super.key, required this.product});

  @override
  State<EditProductPage> createState() => _EditProductPageState();
}

class _EditProductPageState extends State<EditProductPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _costPriceCtrl;
  late TextEditingController _stockCtrl;
  late TextEditingController _minStockCtrl;
  late TextEditingController _unitCtrl;
  late TextEditingController _categoryCtrl;
  DateTime? _expiryDate;

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

  void _submit() {
    if (_formKey.currentState!.validate()) {
      // استخدام copyWith() للحفاظ على جميع البيانات الموجودة
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
                              decoration: const InputDecoration(
                                prefixText: 'ر.س ',
                                prefixStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
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
                              decoration: const InputDecoration(
                                prefixText: 'ر.س ',
                                prefixStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
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