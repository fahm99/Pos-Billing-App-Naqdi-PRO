import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_validators.dart';
import '../../../../core/utils/currency_helper.dart';
import '../../../../core/widgets/input_label.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../domain/entities/expense.dart';
import '../bloc/expense_bloc.dart';

class ExpensesPage extends StatefulWidget {
  const ExpensesPage({super.key});

  @override
  State<ExpensesPage> createState() => _ExpensesPageState();
}

class _ExpensesPageState extends State<ExpensesPage> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    context.read<ExpenseBloc>().add(LoadExpensesEvent());
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
        title: const Text('إدارة المصروفات'),
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
                hintText: 'بحث في المصروفات',
                prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
              ),
            ),
          ),
          const _CategoryFilterChips(),
          _TotalSummaryBar(),
          Expanded(
            child: BlocConsumer<ExpenseBloc, ExpenseState>(
              listener: (context, state) {
                if (state.message != null) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(state.message!),
                    backgroundColor: state.status == ExpenseStatus.error
                        ? Colors.red
                        : Colors.green,
                  ));
                }
              },
              builder: (context, state) {
                if (state.status == ExpenseStatus.loading &&
                    state.expenses.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                final filtered = state.filteredExpenses
                    .where((e) =>
                        e.title.toLowerCase().contains(_query) ||
                        (e.description ?? '').toLowerCase().contains(_query))
                    .toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.receipt_long_outlined,
                            size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        const Text('لا توجد مصروفات',
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
                      _buildExpenseCard(context, filtered[index]),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showExpenseForm(context),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 32),
      ),
    );
  }

  Widget _buildExpenseCard(BuildContext context, Expense expense) {
    final currency = CurrencyHelper.getCurrencySymbol(context);
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
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _categoryColor(expense.category).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _categoryIcon(expense.category),
              color: _categoryColor(expense.category),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(expense.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _categoryColor(expense.category).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        expense.category.label,
                        style: TextStyle(
                          fontSize: 10,
                          color: _categoryColor(expense.category),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      DateFormat('yyyy/MM/dd').format(expense.date),
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                    if (expense.isRecurring) ...[
                      const SizedBox(width: 6),
                      Icon(Icons.repeat,
                          size: 12, color: Colors.purple[400]),
                    ],
                  ],
                ),
                if (expense.description != null &&
                    expense.description!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    expense.description!,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${expense.amount.toStringAsFixed(2)} $currency',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF1A1C1E)),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _iconBtn(
                    icon: Icons.edit_rounded,
                    color: AppTheme.primaryColor,
                    onTap: () => _showExpenseForm(context, expense: expense),
                  ),
                  const SizedBox(width: 4),
                  _iconBtn(
                    icon: Icons.delete_outline_rounded,
                    color: Colors.red,
                    onTap: () => _confirmDelete(context, expense),
                  ),
                ],
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
        icon: Icon(icon, color: color, size: 18),
        constraints: const BoxConstraints(),
        padding: const EdgeInsets.all(6),
        onPressed: onTap,
      ),
    );
  }

  IconData _categoryIcon(ExpenseCategory cat) {
    switch (cat) {
      case ExpenseCategory.rent:
        return Icons.home_outlined;
      case ExpenseCategory.utilities:
        return Icons.bolt_outlined;
      case ExpenseCategory.salary:
        return Icons.people_outline;
      case ExpenseCategory.supplies:
        return Icons.inventory_2_outlined;
      case ExpenseCategory.maintenance:
        return Icons.build_outlined;
      case ExpenseCategory.transportation:
        return Icons.directions_car_outlined;
      case ExpenseCategory.marketing:
        return Icons.campaign_outlined;
      case ExpenseCategory.other:
        return Icons.more_horiz;
    }
  }

  Color _categoryColor(ExpenseCategory cat) {
    switch (cat) {
      case ExpenseCategory.rent:
        return Colors.blue;
      case ExpenseCategory.utilities:
        return Colors.amber[700]!;
      case ExpenseCategory.salary:
        return Colors.green;
      case ExpenseCategory.supplies:
        return Colors.orange;
      case ExpenseCategory.maintenance:
        return Colors.purple;
      case ExpenseCategory.transportation:
        return Colors.teal;
      case ExpenseCategory.marketing:
        return Colors.pink;
      case ExpenseCategory.other:
        return Colors.grey;
    }
  }

  void _showExpenseForm(BuildContext context, {Expense? expense}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => BlocProvider.value(
        value: context.read<ExpenseBloc>(),
        child: ExpenseFormSheet(expense: expense),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Expense expense) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف المصروف'),
        content: Text('هل تريد حذف "${expense.title}"؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          TextButton(
            onPressed: () {
              context
                  .read<ExpenseBloc>()
                  .add(DeleteExpenseEvent(expense.id));
              Navigator.pop(ctx);
            },
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _CategoryFilterChips extends StatelessWidget {
  const _CategoryFilterChips();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ExpenseBloc, ExpenseState>(
      buildWhen: (p, c) => p.selectedCategory != c.selectedCategory,
      builder: (context, state) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              _chip(
                context,
                label: 'الكل',
                selected: state.selectedCategory == null,
                onTap: () => context
                    .read<ExpenseBloc>()
                    .add(const FilterExpensesByCategoryEvent(null)),
              ),
              ...ExpenseCategory.values.map((cat) => _chip(
                    context,
                    label: cat.label,
                    selected: state.selectedCategory == cat,
                    onTap: () => context
                        .read<ExpenseBloc>()
                        .add(FilterExpensesByCategoryEvent(cat)),
                  )),
            ],
          ),
        );
      },
    );
  }

  Widget _chip(BuildContext context,
      {required String label,
      required bool selected,
      required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: selected
                ? AppTheme.primaryColor
                : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? AppTheme.primaryColor
                  : Colors.grey[300]!,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : Colors.black87,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

class _TotalSummaryBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ExpenseBloc, ExpenseState>(
      buildWhen: (p, c) => p.expenses != c.expenses,
      builder: (context, state) {
        final currency = CurrencyHelper.getCurrencySymbol(context);
        final total = state.filteredExpenses.fold<double>(
            0, (sum, e) => sum + e.amount);
        final count = state.filteredExpenses.length;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.account_balance_wallet_outlined,
                      color: AppTheme.primaryColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'الإجمالي ($count مصروف)',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ],
              ),
              Text(
                '${total.toStringAsFixed(2)} $currency',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppTheme.primaryColor),
              ),
            ],
          ),
        );
      },
    );
  }
}

class ExpenseFormSheet extends StatefulWidget {
  final Expense? expense;
  const ExpenseFormSheet({super.key, this.expense});

  @override
  State<ExpenseFormSheet> createState() => _ExpenseFormSheetState();
}

class _ExpenseFormSheetState extends State<ExpenseFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late String _title;
  late String _description;
  late double _amount;
  late DateTime _date;
  late ExpenseCategory _category;
  late String _paymentMethod;
  late bool _isRecurring;
  RecurringPeriod? _recurringPeriod;
  late String _notes;

  @override
  void initState() {
    super.initState();
    _title = widget.expense?.title ?? '';
    _description = widget.expense?.description ?? '';
    _amount = widget.expense?.amount ?? 0;
    _date = widget.expense?.date ?? DateTime.now();
    _category = widget.expense?.category ?? ExpenseCategory.other;
    _paymentMethod = widget.expense?.paymentMethod ?? 'cash';
    _isRecurring = widget.expense?.isRecurring ?? false;
    _recurringPeriod = widget.expense?.recurringPeriod;
    _notes = widget.expense?.notes ?? '';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final expense = Expense(
        id: widget.expense?.id ?? const Uuid().v4(),
        title: _title,
        description: _description.isEmpty ? null : _description,
        amount: _amount,
        date: _date,
        category: _category,
        paymentMethod: _paymentMethod,
        isRecurring: _isRecurring,
        recurringPeriod: _isRecurring ? _recurringPeriod : null,
        notes: _notes.isEmpty ? null : _notes,
      );
      if (widget.expense == null) {
        context.read<ExpenseBloc>().add(AddExpenseEvent(expense));
      } else {
        context.read<ExpenseBloc>().add(UpdateExpenseEvent(expense));
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
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.expense == null ? 'إضافة مصروف' : 'تعديل المصروف',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const InputLabel(text: 'العنوان'),
              TextFormField(
                initialValue: _title,
                decoration: const InputDecoration(hintText: 'مثال: إيجار الشهر'),
                validator: AppValidators.required('مطلوب'),
                onSaved: (v) => _title = v!,
              ),
              const SizedBox(height: 12),
              const InputLabel(text: 'الوصف'),
              TextFormField(
                initialValue: _description,
                maxLines: 2,
                decoration: const InputDecoration(hintText: 'وصف اختياري'),
                onSaved: (v) => _description = v ?? '',
              ),
              const SizedBox(height: 12),
              const InputLabel(text: 'المبلغ'),
              TextFormField(
                initialValue: _amount == 0 ? '' : _amount.toStringAsFixed(2),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(hintText: '0.00'),
                validator: AppValidators.price,
                onSaved: (v) => _amount = double.tryParse(v ?? '0') ?? 0,
              ),
              const SizedBox(height: 12),
              const InputLabel(text: 'الفئة'),
              DropdownButtonFormField<ExpenseCategory>(
                value: _category,
                items: ExpenseCategory.values
                    .map((cat) => DropdownMenuItem(
                          value: cat,
                          child: Text(cat.label),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _category = v!),
                decoration: const InputDecoration(),
              ),
              const SizedBox(height: 12),
              const InputLabel(text: 'التاريخ'),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 18),
                      const SizedBox(width: 8),
                      Text(DateFormat('yyyy/MM/dd').format(_date)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const InputLabel(text: 'طريقة الدفع'),
              DropdownButtonFormField<String>(
                value: _paymentMethod,
                items: const [
                  DropdownMenuItem(value: 'cash', child: Text('نقدي')),
                  DropdownMenuItem(value: 'card', child: Text('بطاقة')),
                  DropdownMenuItem(value: 'credit', child: Text('آجل')),
                  DropdownMenuItem(value: 'transfer', child: Text('تحويل بنكي')),
                ],
                onChanged: (v) => setState(() => _paymentMethod = v!),
                decoration: const InputDecoration(),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('مصروف متكرر'),
                value: _isRecurring,
                onChanged: (v) => setState(() => _isRecurring = v),
              ),
              if (_isRecurring) ...[
                const InputLabel(text: 'فترة التكرار'),
                DropdownButtonFormField<RecurringPeriod>(
                  value: _recurringPeriod ?? RecurringPeriod.monthly,
                  items: RecurringPeriod.values
                      .map((p) => DropdownMenuItem(
                            value: p,
                            child: Text(p.label),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _recurringPeriod = v!),
                  decoration: const InputDecoration(),
                ),
                const SizedBox(height: 12),
              ],
              const InputLabel(text: 'ملاحظات'),
              TextFormField(
                initialValue: _notes,
                maxLines: 2,
                decoration: const InputDecoration(hintText: 'ملاحظات اختيارية'),
                onSaved: (v) => _notes = v ?? '',
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                onPressed: _submit,
                label: widget.expense == null ? 'إضافة' : 'حفظ',
                icon: widget.expense == null ? Icons.add : Icons.save,
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
