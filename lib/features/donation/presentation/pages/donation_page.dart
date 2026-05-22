import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
          ],
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Bank Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF00A77E).withOpacity(0.05),
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
                      color: const Color(0xFF00A77E),
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
