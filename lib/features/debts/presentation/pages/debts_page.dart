import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/utils/currency_helper.dart';
import '../../domain/entities/debt.dart';
import '../bloc/debt_bloc.dart';

class DebtsPage extends StatefulWidget {
  const DebtsPage({super.key});

  @override
  State<DebtsPage> createState() => _DebtsPageState();
}

class _DebtsPageState extends State<DebtsPage> {
  String _filter = 'active';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<DebtBloc>().add(const LoadDebtsEvent());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الديون'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDebtDialog(context),
        child: const Icon(Icons.add),
      ),
      body: BlocBuilder<DebtBloc, DebtState>(
        builder: (context, state) {
          if (state.status == DebtStatusType.loading && state.debts.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          var filteredDebts = state.debts.where((d) {
            final matchesFilter = _filter == 'all' ||
                (_filter == 'active' && d.status == DebtStatus.active) ||
                (_filter == 'paid' && d.status == DebtStatus.paid) ||
                (_filter == 'overdue' && d.status == DebtStatus.overdue);
            final matchesSearch = _searchController.text.isEmpty ||
                d.customerName
                    .contains(_searchController.text);
            return matchesFilter && matchesSearch;
          }).toList();

          return Column(
            children: [
              _buildHeader(state),
              _buildFilterAndSearch(),
              Expanded(
                child: filteredDebts.isEmpty
                    ? const Center(child: Text('لا توجد ديون', style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        itemCount: filteredDebts.length,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemBuilder: (context, index) =>
                            _buildDebtCard(context, filteredDebts[index]),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(DebtState state) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('إجمالي الديون المستحقة',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Text(
            CurrencyHelper.formatPrice(context, state.totalOutstanding),
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 18, color: Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterAndSearch() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: 'بحث باسم العميل...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildFilterChip('الكل', 'all'),
              const SizedBox(width: 8),
              _buildFilterChip('نشط', 'active'),
              const SizedBox(width: 8),
              _buildFilterChip('مدفوع', 'paid'),
              const SizedBox(width: 8),
              _buildFilterChip('متأخر', 'overdue'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final selected = _filter == value;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _filter = value),
    );
  }

  Widget _buildDebtCard(BuildContext context, Debt debt) {
    final remainingStr = CurrencyHelper.formatPrice(context, debt.remainingAmount);
    final originalStr = CurrencyHelper.formatPrice(context, debt.originalAmount);
    final isOverdue = debt.isOverdue;
    final effectiveStatus = isOverdue ? DebtStatus.overdue : debt.status;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: () => context.push('/debt-detail', extra: debt),
        leading: CircleAvatar(
          backgroundColor: effectiveStatus == DebtStatus.paid
              ? Colors.green.shade100
              : isOverdue
                  ? Colors.red.shade100
                  : Colors.orange.shade100,
          child: Icon(
            effectiveStatus == DebtStatus.paid
                ? Icons.check_circle
                : isOverdue
                    ? Icons.warning
                    : Icons.pending,
            color: effectiveStatus == DebtStatus.paid
                ? Colors.green
                : isOverdue
                    ? Colors.red
                    : Colors.orange,
          ),
        ),
        title: Text(debt.customerName, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('$remainingStr / $originalStr - ${debt.description}'),
        trailing: Text(
          '${debt.date.day}/${debt.date.month}/${debt.date.year}',
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ),
    );
  }

  void _showAddDebtDialog(BuildContext context) {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    final descController = TextEditingController();
    final uuid = const Uuid();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 16, right: 16, top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('إضافة دين جديد',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                  labelText: 'اسم العميل', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'المبلغ', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                  labelText: 'الوصف', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                final amount = double.tryParse(amountController.text) ?? 0;
                if (nameController.text.isEmpty || amount <= 0) return;
                final debt = Debt(
                  id: uuid.v4(),
                  customerName: nameController.text,
                  originalAmount: amount,
                  remainingAmount: amount,
                  description: descController.text,
                  date: DateTime.now(),
                );
                context.read<DebtBloc>().add(AddDebtEvent(debt));
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('إضافة الدين'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
