import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/data/app_settings.dart';
import '../../../../core/widgets/input_label.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../shop/presentation/bloc/shop_bloc.dart';
import '../../../shop/domain/entities/shop.dart';

/// صفحة الإعداد الأولي للمتجر - First Time Setup Page
/// تظهر عند أول تشغيل للتطبيق
class SetupPage extends StatefulWidget {
  const SetupPage({super.key});

  @override
  State<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends State<SetupPage> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  // Controllers for shop data
  late TextEditingController _shopNameController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  late TextEditingController _taxNumberController;

  // Controllers for admin credentials
  late TextEditingController _adminUsernameController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;

  // Shop logo
  File? _shopLogoFile;

  bool _isSaving = false;
  int _currentStep = 0; // 0 = shop data, 1 = admin password

  @override
  void initState() {
    super.initState();
    _shopNameController = TextEditingController();
    _addressController = TextEditingController();
    _phoneController = TextEditingController();
    _taxNumberController = TextEditingController();
    _adminUsernameController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _shopNameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _taxNumberController.dispose();
    _adminUsernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
      });
    }
  }

  void _removeShopLogo() {
    setState(() {
      _shopLogoFile = null;
    });
  }

  /// حفظ صورة الشعار محلياً وإرجاع المسار
  Future<String?> _saveLogoLocally(File logoFile) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final logosDir = Directory('${directory.path}/shop_logos');

      if (!await logosDir.exists()) {
        await logosDir.create(recursive: true);
      }

      final fileName = 'shop_logo_${DateTime.now().millisecondsSinceEpoch}.png';
      final savedPath = '${logosDir.path}/$fileName';

      final savedFile = await logoFile.copy(savedPath);
      return savedFile.path;
    } catch (e) {
      debugPrint('Error saving logo: $e');
      return null;
    }
  }

  Future<void> _completeSetup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      // حفظ صورة الشعار إذا تم اختيارها
      String shopLogoPath = '';
      if (_shopLogoFile != null) {
        shopLogoPath = await _saveLogoLocally(_shopLogoFile!) ?? '';
      }

      // حفظ بيانات المتجر
      final shop = Shop(
        name: _shopNameController.text.trim(),
        addressLine1: _addressController.text.trim(),
        addressLine2: _taxNumberController.text
            .trim(), // الرقم الضريبي في addressLine2 مؤقتاً
        phoneNumber: _phoneController.text.trim(),
        shopLogo: shopLogoPath,
        taxNumber: _taxNumberController.text.trim(),
      );

      if (mounted) {
        context.read<ShopBloc>().add(UpdateShopEvent(shop));
      }

      // حفظ بيانات دخول الأدمن
      await AppSettings.setAdminUsername(_adminUsernameController.text.trim());
      await AppSettings.setAdminPassword(_passwordController.text);

      // تعيين الوضع الافتراضي - يبدأ في وضع الأدمن
      await AppSettings.setLastMode(true);
      await AppSettings.setDefaultOpenMode(true);

      // تعليم أن الإعداد الأولي تم
      await AppSettings.markSetupComplete();

      if (mounted) {
        // الانتقال للصفحة الرئيسية
        context.go('/scan');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        _buildHeader(),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(24),
                            child: _currentStep == 0
                                ? _buildShopDataStep()
                                : _buildAdminPasswordStep(),
                          ),
                        ),
                        _buildBottomButtons(),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          // Logo
          Image.asset(
            'assets/naqdilogo.jpg',
            width: 60,
            height: 60,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 12),
          Text(
            'مرحباً بك في نقدي',
            style: GoogleFonts.cairo(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF00A77E),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'لنبدأ بإعداد متجرك',
            style: GoogleFonts.cairo(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          // Progress indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStepIndicator(1, 'بيانات المتجر', _currentStep >= 0),
              _buildStepLine(_currentStep >= 1),
              _buildStepIndicator(2, 'كلمة السر', _currentStep >= 1),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int number, String label, bool isActive) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF00A77E) : Colors.grey[200],
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$number',
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey[500],
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: isActive ? const Color(0xFF00A77E) : Colors.grey[500],
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(bool isActive) {
    return Container(
      width: 50,
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      color: isActive ? const Color(0xFF00A77E) : Colors.grey[300],
    );
  }

  Widget _buildShopDataStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // شعار المتجر
        Center(
          child: GestureDetector(
            onTap: _pickShopLogo,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF00A77E).withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: _shopLogoFile != null
                  ? Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.file(
                            _shopLogoFile!,
                            width: 90,
                            height: 90,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: _removeShopLogo,
                            child: Container(
                              padding: const EdgeInsets.all(3),
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
                        const SizedBox(height: 6),
                        Text(
                          'إضافة شعار\n(اختياري)',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),

        const SizedBox(height: 24),

        // اسم المتجر
        const InputLabel(text: 'اسم المتجر'),
        TextFormField(
          controller: _shopNameController,
          decoration: InputDecoration(
            hintText: 'مثال: سوبرماركت الخير',
            prefixIcon: const Icon(Icons.storefront, size: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          textDirection: TextDirection.rtl,
          style: const TextStyle(fontSize: 14),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'اسم المتجر مطلوب';
            }
            return null;
          },
        ),

        const SizedBox(height: 16),

        // العنوان
        const InputLabel(text: 'العنوان'),
        TextFormField(
          controller: _addressController,
          decoration: InputDecoration(
            hintText: 'مثال: حي السلام، شارع الملك فهد',
            prefixIcon: const Icon(Icons.location_on_outlined, size: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          textDirection: TextDirection.rtl,
          style: const TextStyle(fontSize: 14),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'العنوان مطلوب';
            }
            return null;
          },
        ),

        const SizedBox(height: 16),

        // رقم الجوال
        const InputLabel(text: 'رقم الجوال'),
        TextFormField(
          controller: _phoneController,
          decoration: InputDecoration(
            hintText: 'مثال: 0501234567',
            prefixIcon: const Icon(Icons.phone_outlined, size: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          keyboardType: TextInputType.phone,
          textDirection: TextDirection.rtl,
          style: const TextStyle(fontSize: 14),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'رقم الجوال مطلوب';
            }
            return null;
          },
        ),

        const SizedBox(height: 16),

        // الرقم الضريبي (اختياري)
        Row(
          children: [
            const InputLabel(text: 'الرقم الضريبي'),
            const SizedBox(width: 6),
            Text(
              '(اختياري)',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
        TextFormField(
          controller: _taxNumberController,
          decoration: InputDecoration(
            hintText: 'مثال: 300123456789003',
            prefixIcon: const Icon(Icons.receipt_long_outlined, size: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          keyboardType: TextInputType.number,
          textDirection: TextDirection.rtl,
          style: const TextStyle(fontSize: 14),
        ),

        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildAdminPasswordStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // أيقونة
        Center(
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: const Color(0xFF00A77E).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.admin_panel_settings,
              size: 36,
              color: Color(0xFF00A77E),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // شرح
        Text(
          'كلمة سر وضع الأدمن',
          textAlign: TextAlign.center,
          style: GoogleFonts.cairo(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 8),

        Text(
          'استخدم اسم المستخدم وكلمة السر للوصول إلى وضع الأدمن وإدارة المنتجات والتقارير والإعدادات',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),

        const SizedBox(height: 24),

        // اسم المستخدم
        const InputLabel(text: 'اسم المستخدم'),
        TextFormField(
          controller: _adminUsernameController,
          decoration: InputDecoration(
            hintText: 'أدخل اسم المستخدم للأدمن',
            prefixIcon: const Icon(Icons.person_outline, size: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          textDirection: TextDirection.rtl,
          style: const TextStyle(fontSize: 14),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'اسم المستخدم مطلوب';
            }
            return null;
          },
        ),

        const SizedBox(height: 16),

        // كلمة السر
        const InputLabel(text: 'كلمة السر'),
        TextFormField(
          controller: _passwordController,
          decoration: InputDecoration(
            hintText: 'أدخل كلمة سر قوية',
            prefixIcon: const Icon(Icons.lock_outline, size: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          obscureText: true,
          textDirection: TextDirection.rtl,
          style: const TextStyle(fontSize: 14),
          validator: (value) {
            if (value == null || value.length < 4) {
              return 'كلمة السر يجب أن تكون 4 أحرف على الأقل';
            }
            return null;
          },
        ),

        const SizedBox(height: 16),

        // تأكيد كلمة السر
        const InputLabel(text: 'تأكيد كلمة السر'),
        TextFormField(
          controller: _confirmPasswordController,
          decoration: InputDecoration(
            hintText: 'أعد إدخال كلمة السر',
            prefixIcon: const Icon(Icons.lock_outline, size: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          obscureText: true,
          textDirection: TextDirection.rtl,
          style: const TextStyle(fontSize: 14),
          validator: (value) {
            if (value != _passwordController.text) {
              return 'كلمتا السر غير متطابقتين';
            }
            return null;
          },
        ),

        const SizedBox(height: 20),

        // تنبيه
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange[50],
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.orange[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.orange[700], size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'احتفظ بكلمة السر في مكان آمن. سيتم طلبها للوصول لوضع الأدمن.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange[700],
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: PrimaryButton(
        onPressed: _isSaving
            ? null
            : () {
                if (_currentStep == 0) {
                  // الانتقال للخطوة التالية
                  if (_formKey.currentState!.validate()) {
                    setState(() => _currentStep = 1);
                  }
                } else {
                  // إكمال الإعداد
                  _completeSetup();
                }
              },
        icon: _currentStep == 0 ? Icons.arrow_back : Icons.check,
        iconSize: 18,
        label: _isSaving
            ? 'جاري الحفظ...'
            : _currentStep == 0
                ? 'التالي'
                : 'إكمال الإعداد',
      ),
    );
  }
}
