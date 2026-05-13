import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/widgets/input_label.dart';

class DonationPage extends StatefulWidget {
  const DonationPage({super.key});

  @override
  State<DonationPage> createState() => _DonationPageState();
}

class _DonationPageState extends State<DonationPage> {
  String? _selectedBank;
  String? _selectedAccountType;
  File? _receiptImage;
  final ImagePicker _picker = ImagePicker();

  final List<Map<String, dynamic>> _banks = [
    {
      'name': 'بنك الكريمي',
      'logo': '🏦',
      'accounts': [
        {'type': 'YER', 'number': '3143593168', 'label': 'ريال يمني'},
        {'type': 'SAR', 'number': '3143725412', 'label': 'ريال سعودي'},
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تبرع لتطوير التطبيق'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.chevron_left,
              size: 28, color: Theme.of(context).primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Motivational Text
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF00A77E).withOpacity(0.1),
                    const Color(0xFF00A77E).withOpacity(0.05),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF00A77E).withOpacity(0.2),
                ),
              ),
              child: Column(
                children: [
                  const Icon(Icons.volunteer_activism,
                      size: 48, color: Color(0xFF00A77E)),
                  const SizedBox(height: 12),
                  const Text(
                    'ساهم في تطوير التطبيق',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'تبرعك يساعدنا على الاستمرار في تطوير التطبيق وإضافة ميزات جديدة لخدمتك بشكل أفضل. كل مساهمة قيمة وتُقدر.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Donation Method Selection
            const Text(
              'اختر طريقة التبرع',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 16),

            // Bank Donation Option
            _buildDonationMethodCard(
              icon: Icons.account_balance,
              title: 'التبرع البنكي',
              subtitle: 'تحويل بنكي مباشر',
              isSelected: _selectedBank == null,
              onTap: () {
                setState(() {
                  _selectedBank = '';
                  _selectedAccountType = null;
                });
              },
            ),

            const SizedBox(height: 16),

            // Bank Selection
            if (_selectedBank == '') _buildBankSelection(),

            const SizedBox(height: 32),

            // Receipt Upload Section
            if (_receiptImage != null || _selectedAccountType != null)
              _buildReceiptUploadSection(),

            const SizedBox(height: 32),

            // Submit Button
            if (_receiptImage != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitDonation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00A77E),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'إرسال التبرع',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDonationMethodCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF00A77E) : Colors.grey[200]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF00A77E).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: const Color(0xFF00A77E), size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: isSelected ? const Color(0xFF00A77E) : Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBankSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const InputLabel(text: 'اختر البنك'),
        const SizedBox(height: 8),
        ..._banks.map((bank) => GestureDetector(
              onTap: () {
                setState(() {
                  _selectedBank = bank['name'];
                  _selectedAccountType = null;
                });
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _selectedBank == bank['name']
                        ? const Color(0xFF00A77E)
                        : Colors.grey[200]!,
                    width: _selectedBank == bank['name'] ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Text(bank['logo'], style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        bank['name'],
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: _selectedBank == bank['name']
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: _selectedBank == bank['name']
                              ? const Color(0xFF00A77E)
                              : Colors.black87,
                        ),
                      ),
                    ),
                    if (_selectedBank == bank['name'])
                      const Icon(Icons.check_circle,
                          color: Color(0xFF00A77E), size: 20),
                  ],
                ),
              ),
            )),
        const SizedBox(height: 16),

        // Account Type Selection
        if (_selectedBank != null && _selectedBank!.isNotEmpty)
          _buildAccountTypeSelection(),
      ],
    );
  }

  Widget _buildAccountTypeSelection() {
    final bank = _banks.firstWhere((b) => b['name'] == _selectedBank);
    final accounts = bank['accounts'] as List;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const InputLabel(text: 'اختر نوع الحساب'),
        const SizedBox(height: 8),
        ...accounts.map((account) => GestureDetector(
              onTap: () {
                setState(() {
                  _selectedAccountType = account['type'];
                });
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _selectedAccountType == account['type']
                        ? const Color(0xFF00A77E)
                        : Colors.grey[200]!,
                    width: _selectedAccountType == account['type'] ? 2 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            account['label'],
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight:
                                  _selectedAccountType == account['type']
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                              color: _selectedAccountType == account['type']
                                  ? const Color(0xFF00A77E)
                                  : Colors.black87,
                            ),
                          ),
                        ),
                        if (_selectedAccountType == account['type'])
                          const Icon(Icons.check_circle,
                              color: Color(0xFF00A77E), size: 20),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SelectableText(
                            account['number'],
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                              color: Colors.black87,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy, size: 18),
                            onPressed: () {
                              // Copy to clipboard
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )),
      ],
    );
  }

  Widget _buildReceiptUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const InputLabel(text: 'إيصال التحويل'),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickReceiptImage,
          child: Container(
            width: double.infinity,
            height: 150,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey[300]!,
                style: BorderStyle.solid,
              ),
            ),
            child: _receiptImage != null
                ? Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          _receiptImage!,
                          width: double.infinity,
                          height: 150,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _receiptImage = null;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close,
                                color: Colors.white, size: 16),
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cloud_upload,
                          size: 40, color: Colors.grey[400]),
                      const SizedBox(height: 8),
                      Text(
                        'اضغط لرفع صورة إيصال التحويل',
                        style: TextStyle(
                          fontSize: 13,
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

  Future<void> _pickReceiptImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );
    if (image != null) {
      setState(() {
        _receiptImage = File(image.path);
      });
    }
  }

  void _submitDonation() {
    // TODO: Save donation to database
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('شكراً لتبرعك! سنقوم بمراجعة إيصال التحويل قريباً.'),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.pop(context);
  }
}
