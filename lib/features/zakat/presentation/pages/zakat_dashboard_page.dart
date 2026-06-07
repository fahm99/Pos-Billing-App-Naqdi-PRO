import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/currency_helper.dart';
import '../../domain/entities/zakat_payment.dart';
import '../bloc/zakat_bloc.dart';

class ZakatDashboardPage extends StatefulWidget {
  const ZakatDashboardPage({super.key});

  @override
  State<ZakatDashboardPage> createState() => _ZakatDashboardPageState();
}

class _ZakatDashboardPageState extends State<ZakatDashboardPage> {
  String _selectedPeriod = 'year';

  DateTime _getFromDate() {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case '3months':
        return DateTime(now.year, now.month - 3, now.day);
      case '6months':
        return DateTime(now.year, now.month - 6, now.day);
      case 'year':
      default:
        return DateTime(now.year - 1, now.month, now.day);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadZakat();
  }

  void _loadZakat() {
    final to = DateTime.now();
    final from = _getFromDate();
    context.read<ZakatBloc>().add(LoadZakatEvent(from: from, to: to));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('حساب الزكاة'),
      ),
      body: BlocConsumer<ZakatBloc, ZakatState>(
        listener: (context, state) {
          if (state.status == ZakatStatus.paymentSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('تم تسجيل دفع الزكاة بنجاح')),
            );
          } else if (state.status == ZakatStatus.error && state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage!)),
            );
          }
        },
        builder: (context, state) {
          if (state.status == ZakatStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          final calc = state.calculation;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPeriodSelector(),
                const SizedBox(height: 16),
                if (calc != null) ...[
                  _buildSummarySection(context, calc),
                  const SizedBox(height: 16),
                  _buildPayButton(context, state, calc),
                ],
                const SizedBox(height: 24),
                _buildTotalPaidSection(context, state),
                const SizedBox(height: 16),
                _buildPaymentHistorySection(context, state),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Row(
      children: [
        const Text('الفترة: ', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(width: 8),
        Expanded(
          child: SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: '3months', label: Text('3 شهور')),
              ButtonSegment(value: '6months', label: Text('6 شهور')),
              ButtonSegment(value: 'year', label: Text('سنة')),
            ],
            selected: {_selectedPeriod},
            onSelectionChanged: (value) {
              setState(() => _selectedPeriod = value.first);
              _loadZakat();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSummarySection(BuildContext context, dynamic calc) {
    final profitStr = CurrencyHelper.formatPrice(context, calc.totalSalesProfit);
    final expensesStr = CurrencyHelper.formatPrice(context, calc.totalExpenses);
    final netStr = CurrencyHelper.formatPrice(context, calc.netZakatableAmount);
    final zakatStr = CurrencyHelper.formatPrice(context, calc.zakatDue);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ملخص حساب الزكاة',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            _buildSummaryRow('إجمالي أرباح المبيعات', profitStr, Colors.green),
            _buildSummaryRow('إجمالي المصروفات', expensesStr, Colors.red),
            _buildSummaryRow(
              'صافي المبلغ الخاضع للزكاة',
              netStr,
              calc.netZakatableAmount >= 0 ? Colors.blue : Colors.red,
            ),
            const Divider(),
            _buildSummaryRow(
              'الزكاة المستحقة (2.5%)',
              zakatStr,
              calc.isZakatDue ? Colors.orange : Colors.grey,
              isBold: true,
              fontSize: 18,
            ),
            if (!calc.isZakatDue)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'المبلغ لا يصل إلى نصاب الزكاة',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, Color valueColor,
      {bool isBold = false, double fontSize = 14}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: fontSize, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(value,
              style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                  color: valueColor)),
        ],
      ),
    );
  }

  Widget _buildPayButton(BuildContext context, ZakatState state, dynamic calc) {
    if (!calc.isZakatDue) return const SizedBox.shrink();

    final alreadyPaid = state.payments.any((p) =>
        p.calculationFrom == calc.fromDate &&
        p.calculationTo == calc.toDate &&
        p.status == ZakatPaymentStatus.paid);

    if (alreadyPaid) {
      return Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('تم دفع الزكاة لهذه الفترة',
                  style: TextStyle(color: Colors.green)),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _confirmPayment(calc),
        icon: const Icon(Icons.payments),
        label: Text('تسجيل دفع الزكاة (${CurrencyHelper.formatPrice(context, calc.zakatDue)})'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  void _confirmPayment(dynamic calc) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد دفع الزكاة'),
        content: Text(
            'هل أنت متأكد من تسجيل دفع الزكاة بقيمة ${CurrencyHelper.formatPrice(context, calc.zakatDue)}؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<ZakatBloc>().add(PayZakatEvent(
                    amount: calc.zakatDue,
                    from: calc.fromDate,
                    to: calc.toDate,
                    totalSalesProfit: calc.totalSalesProfit,
                    totalExpenses: calc.totalExpenses,
                  ));
            },
            child: const Text('تأكيد الدفع'),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalPaidSection(BuildContext context, ZakatState state) {
    final totalPaidStr =
        CurrencyHelper.formatPrice(context, state.totalPaid);

    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('إجمالي الزكاة المدفوعة',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(totalPaidStr,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.blue)),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentHistorySection(BuildContext context, ZakatState state) {
    if (state.payments.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: Text('لا توجد مدفوعات زكاة مسجلة',
                style: TextStyle(color: Colors.grey)),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('سجل المدفوعات',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...state.payments.map((payment) => Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.green.shade100,
                  child: const Icon(Icons.check, color: Colors.green),
                ),
                title: Text(
                    CurrencyHelper.formatPrice(context, payment.amount)),
                subtitle: Text(
                    '${payment.date.year}/${payment.date.month}/${payment.date.day}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () {
                    context
                        .read<ZakatBloc>()
                        .add(DeleteZakatPaymentEvent(payment.id));
                  },
                ),
              ),
            )),
      ],
    );
  }
}
