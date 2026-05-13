import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/input_label.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/utils/app_validators.dart';
import '../../domain/entities/customer.dart';
import '../bloc/customer_bloc.dart';

class CustomersPage extends StatefulWidget {
  const CustomersPage({super.key});

  @override
  State<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends State<CustomersPage> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    context.read<CustomerBloc>().add(LoadCustomersEvent());
    _searchController.addListener(
        () => setState(() => _query = _searchController.text.toLowerCase()));
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
        title: const Text('العملاء'),
        leading: IconButton(
          icon: Icon(Icons.chevron_left,
              size: 28, color: Theme.of(context).primaryColor),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextFormField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'بحث باسم العميل أو الهاتف',
                prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
              ),
            ),
          ),
          Expanded(
            child: BlocConsumer<CustomerBloc, CustomerState>(
              listener: (context, state) {
                if (state.message != null) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(state.message!),
                    backgroundColor: state.status == CustomerStatus.error
                        ? Colors.red
                        : Colors.green,
                  ));
                }
              },
              builder: (context, state) {
                if (state.status == CustomerStatus.loading &&
                    state.customers.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                final filtered = state.customers
                    .where((c) =>
                        c.name.toLowerCase().contains(_query) ||
                        c.phone.contains(_query))
                    .toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.people_outline,
                            size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        const Text('لا يوجد عملاء',
                            style: TextStyle(color: Colors.grey, fontSize: 16)),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) =>
                      _buildCustomerCard(context, filtered[index]),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCustomerForm(context),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 32),
      ),
    );
  }

  Widget _buildCustomerCard(BuildContext context, Customer customer) {
    final hasDebt = customer.creditBalance > 0;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
            child: Text(
              customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?',
              style: const TextStyle(
                  color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(customer.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                if (customer.phone.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(customer.phone,
                      style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                ],
                if (hasDebt) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'دين: ₹${customer.creditBalance.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontSize: 11,
                          color: Colors.red,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
                if (customer.loyaltyPoints > 0) ...[
                  const SizedBox(height: 4),
                  Text('نقاط: ${customer.loyaltyPoints.toStringAsFixed(0)}',
                      style: TextStyle(fontSize: 11, color: Colors.amber[700])),
                ],
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _iconBtn(
                icon: Icons.edit_rounded,
                color: AppTheme.primaryColor,
                onTap: () => _showCustomerForm(context, customer: customer),
              ),
              const SizedBox(width: 8),
              _iconBtn(
                icon: Icons.delete_outline_rounded,
                color: Colors.red,
                onTap: () => _confirmDelete(context, customer),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _iconBtn(
      {required IconData icon,
      required Color color,
      required VoidCallback onTap}) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: 20),
        constraints: const BoxConstraints(),
        padding: const EdgeInsets.all(8),
        onPressed: onTap,
      ),
    );
  }

  void _showCustomerForm(BuildContext context, {Customer? customer}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => BlocProvider.value(
        value: context.read<CustomerBloc>(),
        child: _CustomerFormSheet(customer: customer),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Customer customer) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف العميل'),
        content: Text('هل تريد حذف ${customer.name}؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          TextButton(
            onPressed: () {
              context
                  .read<CustomerBloc>()
                  .add(DeleteCustomerEvent(customer.id));
              Navigator.pop(ctx);
            },
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _CustomerFormSheet extends StatefulWidget {
  final Customer? customer;
  const _CustomerFormSheet({this.customer});

  @override
  State<_CustomerFormSheet> createState() => _CustomerFormSheetState();
}

class _CustomerFormSheetState extends State<_CustomerFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  late String _phone;
  late String _address;
  late double _creditBalance;

  @override
  void initState() {
    super.initState();
    _name = widget.customer?.name ?? '';
    _phone = widget.customer?.phone ?? '';
    _address = widget.customer?.address ?? '';
    _creditBalance = widget.customer?.creditBalance ?? 0;
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final customer = Customer(
        id: widget.customer?.id ?? const Uuid().v4(),
        name: _name,
        phone: _phone,
        address: _address,
        creditBalance: _creditBalance,
        loyaltyPoints: widget.customer?.loyaltyPoints ?? 0,
        createdAt: widget.customer?.createdAt ?? DateTime.now(),
      );
      if (widget.customer == null) {
        context.read<CustomerBloc>().add(AddCustomerEvent(customer));
      } else {
        context.read<CustomerBloc>().add(UpdateCustomerEvent(customer));
      }
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.customer == null ? 'إضافة عميل' : 'تعديل العميل',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const InputLabel(text: 'الاسم'),
            TextFormField(
              initialValue: _name,
              decoration: const InputDecoration(hintText: 'اسم العميل'),
              validator: AppValidators.required('مطلوب'),
              onSaved: (v) => _name = v!,
            ),
            const SizedBox(height: 12),
            const InputLabel(text: 'الهاتف'),
            TextFormField(
              initialValue: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(hintText: 'رقم الهاتف'),
              onSaved: (v) => _phone = v ?? '',
            ),
            const SizedBox(height: 12),
            const InputLabel(text: 'العنوان'),
            TextFormField(
              initialValue: _address,
              decoration: const InputDecoration(hintText: 'العنوان'),
              onSaved: (v) => _address = v ?? '',
            ),
            const SizedBox(height: 12),
            const InputLabel(text: 'الدين المستحق (₹)'),
            TextFormField(
              initialValue: _creditBalance.toStringAsFixed(2),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(hintText: '0.00'),
              onSaved: (v) => _creditBalance = double.tryParse(v ?? '0') ?? 0,
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              onPressed: _submit,
              label: widget.customer == null ? 'إضافة' : 'حفظ',
              icon: widget.customer == null ? Icons.add : Icons.save,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
