import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_theme.dart';

class DonationPage extends StatelessWidget {
  const DonationPage({super.key});

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
                    AppTheme.primaryColor.withOpacity(0.1),
                    AppTheme.primaryColor.withOpacity(0.05),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.primaryColor.withOpacity(0.2),
                ),
              ),
              child: Column(
                children: [
                  const Icon(Icons.volunteer_activism,
                      size: 48, color: AppTheme.primaryColor),
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

            // Bank Accounts Section
            const Text(
              'الحسابات البنكية',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 16),

            // Bank: بنك الكريمي
            _buildBankCard(
              bankName: 'بنك الكريمي',
              bankLogo: '🏦',
              accounts: [
                {'type': 'ريال يمني', 'number': '3143593168'},
                {'type': 'ريال سعودي', 'number': '3143725412'},
              ],
            ),

            // Bank: بنك الراجحي
            _buildBankCard(
              bankName: 'بنك الراجحي',
              bankLogo: '🏦',
              accounts: [
                {'type': 'رقم الحساب', 'number': '141000010006086039638'},
                {'type': 'رقم الآيبان', 'number': 'SA30 8000 0141 6080 1603 9638'},
              ],
            ),

            const SizedBox(height: 32),

            // Contact Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.headset_mic, size: 20, color: Color(0xFF1A1A1A)),
                      SizedBox(width: 8),
                      Text(
                        'تواصل مع المطور',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildWhatsAppButton(
                    number: '+967738694238',
                    label: '+967 738 694 238',
                  ),
                  const SizedBox(height: 8),
                  _buildWhatsAppButton(
                    number: '+9660576701295',
                    label: '+966 057 670 1295',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildWhatsAppButton({required String number, required String label}) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          final url = 'https://wa.me/$number';
          launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        },
        icon: const Icon(
          Icons.chat,
          color: Color(0xFF25D366),
          size: 20,
        ),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF1A1A1A),
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          side: BorderSide(color: Colors.grey[300]!),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildBankCard({
    required String bankName,
    required String bankLogo,
    required List<Map<String, String>> accounts,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          // Bank Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.05),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Text(bankLogo, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Text(
                  bankName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
          ),

          // Account Numbers
          ...accounts.map((account) => Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.grey[100]!),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            account['type']!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                          const SizedBox(height: 4),
                          SelectableText(
                            account['number']!,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1A1A),
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, size: 20),
                      color: AppTheme.primaryColor,
                      onPressed: () {
                        Clipboard.setData(
                            ClipboardData(text: account['number']!));
                      },
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
