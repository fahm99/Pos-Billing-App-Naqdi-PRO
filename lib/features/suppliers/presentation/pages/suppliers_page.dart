import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/input_label.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/utils/app_validators.dart';
import '../../domain/entities/supplier.dart';
import '../bloc/supplier_bloc.dart';

class SuppliersPage extends StatefulWidget {
  const SuppliersPage({super.key});

  @override
  State<SuppliersPage> createState() => _SuppliersPageState();
}

class _SuppliersPageState extends State<SuppliersPage> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    context.read<SupplierBloc>().add(LoadSuppliersEvent());
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
        title: const Text('الموردون'),
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
                hintText: 'بحث باسم المورد أو الهاتف',
                prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
              ),
            ),
          ),
          Expanded(
            child: BlocConsumer<SupplierBloc, SupplierState>(
              listener: (context, state) {
                if (state.message != null) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(state.message!),
                    backgroundColor: state.status == SupplierStatus.error
                        ? Colors.red
                        : Colors.green,
                  ));
                }
              },
              builder: (context, state) {
                if (state.status == SupplierStatus.loading &&
                    state.suppliers.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                final filtered = state.suppliers
                    .where((s) =>
                        s.name.toLowerCase().contains(_query) ||
                        s.phone.contains(_query))
                    .toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.local_shipping_outlined,
                            size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        const Text('لا يوجد موردون',
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
                      _buildSupplierCard(context, filtered[index]),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showSupplierForm(context),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 32),
      ),
    );
  }

  Widget _buildSupplierCard(BuildContext context, Supplier supplier) {
    final hasBalance = supplier.balance != 0;
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
            backgroundColor: Colors.blue.withOpacity(0.1),
            child: Text(
              supplier.name.isNotEmpty ? supplier.name[0].toUpperCase() : '?',
              style: const TextStyle(
                  color: Colors.blue, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(supplier.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                if (supplier.phone.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(supplier.phone,
                      style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                ],
                if (supplier.address.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(supplier.address,
                      style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                ],
                if (hasBalance) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: supplier.balance > 0
                          ? Colors.orange.withOpacity(0.1)
                          : Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      supplier.balance > 0
                          ? 'مستحق للمورد: ₹${supplier.balance.toStringAsFixed(2)}'
                          : 'رصيد لصالحنا: ₹${supplier.balance.abs().toStringAsFixed(2)}',
                      style: TextStyle(
                          fontSize: 11,
                          color: supplier.balance > 0
                              ? Colors.orange[800]
                              : Colors.green[700],
                          fontWeight: FontWeight.bold),
                    ),
                  ),
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
                onTap: () => _showSupplierForm(context, supplier: supplier),
              ),
              const SizedBox(width: 8),
              _iconBtn(
                icon: Icons.delete_outline_rounded,
                color: Colors.red,
                onTap: () => _confirmDelete(context, supplier),
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

  void _showSupplierForm(BuildContext context, {Supplier? supplier}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => BlocProvider.value(
        value: context.read<SupplierBloc>(),
        child: _SupplierFormSheet(supplier: supplier),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Supplier supplier) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف المورد'),
        content: Text('هل تريد حذف ${supplier.name}؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          TextButton(
            onPressed: () {
              context
                  .read<SupplierBloc>()
                  .add(DeleteSupplierEvent(supplier.id));
              Navigator.pop(ctx);
            },
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _SupplierFormSheet extends StatefulWidget {
  final Supplier? supplier;
  const _SupplierFormSheet({this.supplier});

  @override
  State<_SupplierFormSheet> createState() => _SupplierFormSheetState();
}

class _SupplierFormSheetState extends State<_SupplierFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  late String _phone;
  late String _address;
  late double _balance;

  @override
  void initState() {
    super.initState();
    _name = widget.supplier?.name ?? '';
    _phone = widget.supplier?.phone ?? '';
    _address = widget.supplier?.address ?? '';
    _balance = widget.supplier?.balance ?? 0;
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final supplier = Supplier(
        id: widget.supplier?.id ?? const Uuid().v4(),
        name: _name,
        phone: _phone,
        address: _address,
        balance: _balance,
        createdAt: widget.supplier?.createdAt ?? DateTime.now(),
      );
      if (widget.supplier == null) {
        context.read<SupplierBloc>().add(AddSupplierEvent(supplier));
      } else {
        context.read<SupplierBloc>().add(UpdateSupplierEvent(supplier));
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
              widget.supplier == null ? 'إضافة مورد' : 'تعديل المورد',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const InputLabel(text: 'الاسم'),
            TextFormField(
              initialValue: _name,
              decoration: const InputDecoration(hintText: 'اسم المورد'),
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
            const InputLabel(text: 'الرصيد المستحق للمورد (₹)'),
            TextFormField(
              initialValue: _balance.toStringAsFixed(2),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(hintText: '0.00'),
              onSaved: (v) => _balance = double.tryParse(v ?? '0') ?? 0,
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              onPressed: _submit,
              label: widget.supplier == null ? 'إضافة' : 'حفظ',
              icon: widget.supplier == null ? Icons.add : Icons.save,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
