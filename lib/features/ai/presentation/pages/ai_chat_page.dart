import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:billing_app/features/ai/presentation/bloc/ai_bloc.dart';
import 'package:billing_app/features/ai/presentation/bloc/ai_event.dart';
import 'package:billing_app/features/ai/presentation/bloc/ai_state.dart';
import 'package:billing_app/features/ai/presentation/widgets/chat_widgets.dart';
import 'package:billing_app/features/ai/presentation/pages/ai_settings_page.dart';
import 'package:billing_app/features/ai/services/data_collector.dart';
import 'package:billing_app/features/ai/services/system_prompt_builder.dart';
import 'package:billing_app/features/sales/presentation/bloc/sales_bloc.dart';
import 'package:billing_app/features/expenses/presentation/bloc/expense_bloc.dart';
import 'package:billing_app/features/product/presentation/bloc/product_bloc.dart';
import 'package:billing_app/features/customers/presentation/bloc/customer_bloc.dart';
import 'package:billing_app/features/suppliers/presentation/bloc/supplier_bloc.dart';
import 'package:billing_app/features/debts/presentation/bloc/debt_bloc.dart';

class AiChatPage extends StatefulWidget {
  static const routeName = '/ai-chat';
  const AiChatPage({super.key});
  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage> {
  final _inputCtl = TextEditingController();
  final _scrollCtl = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<AiBloc>().add(LoadProviders());
    context.read<AiBloc>().add(LoadSessions());
    context.read<AiBloc>().add(NewSession());
  }

  @override
  void dispose() {
    _inputCtl.dispose();
    _scrollCtl.dispose();
    super.dispose();
  }

  String? _buildSystemPrompt() {
    try {
      final salesState = context.read<SalesBloc>().state;
      final expState = context.read<ExpenseBloc>().state;
      final prodState = context.read<ProductBloc>().state;
      final custState = context.read<CustomerBloc>().state;
      final suppState = context.read<SupplierBloc>().state;
      final debtState = context.read<DebtBloc>().state;
      final snapshot = DataCollector().collect(
        invoices: salesState.invoices,
        expenses: expState.expenses,
        products: prodState.products,
        customers: custState.customers,
        suppliers: suppState.suppliers,
        debts: debtState.debts,
      );
      return SystemPromptBuilder().build(snapshot);
    } catch (_) {
      return null;
    }
  }

  void _sendMessage([String? text]) {
    final msg = text ?? _inputCtl.text.trim();
    if (msg.isEmpty) return;
    final systemPrompt = _buildSystemPrompt();
    context.read<AiBloc>().add(SendMessage(msg, systemPrompt: systemPrompt));
    _inputCtl.clear();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtl.hasClients) {
        _scrollCtl.animateTo(
          _scrollCtl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('المساعد الذكي'),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () => Navigator.pushNamed(context, AiSettingsPage.routeName),
            ),
          ],
        ),
        drawer: BlocBuilder<AiBloc, AiState>(
          builder: (context, state) => SessionDrawer(
            sessions: state.sessions,
            currentId: state.currentSession?.id,
            onSelect: (id) {
              context.read<AiBloc>().add(SelectSession(id));
              Navigator.pop(context);
            },
            onNew: () {
              context.read<AiBloc>().add(NewSession());
              Navigator.pop(context);
            },
            onDelete: (id) {
              context.read<AiBloc>().add(DeleteSession(id));
            },
          ),
        ),
        body: BlocConsumer<AiBloc, AiState>(
          listener: (context, state) {
            if (state.status == AiStatus.ready) _scrollToBottom();
            if (state.error != null && state.status == AiStatus.error) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.error!)),
              );
            }
          },
          builder: (context, state) {
            if (state.selectedProvider == null && state.providers.isEmpty) {
              return _buildNoProvider();
            }
            return Column(
              children: [
                // Provider indicator
                if (state.selectedProvider != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    color: Colors.blue.shade50,
                    child: Row(
                      children: [
                        Icon(Icons.memory, size: 14, color: Colors.blue.shade700),
                        const SizedBox(width: 6),
                        Text(
                          'المزود: ${state.selectedProvider!.label}',
                          style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
                        ),
                      ],
                    ),
                  ),
                // Messages
                Expanded(
                  child: state.messages.isEmpty
                      ? EmptyChatWidget(
                          onSuggestion: (text) {
                            if (state.selectedProvider == null) return;
                            _sendMessage(text);
                          },
                        )
                      : ListView.builder(
                          controller: _scrollCtl,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: state.status == AiStatus.sending
                              ? state.messages.length + 1
                              : state.messages.length,
                          itemBuilder: (context, index) {
                            if (index == state.messages.length &&
                                state.status == AiStatus.sending) {
                              return _buildLoadingIndicator();
                            }
                            return ChatBubble(message: state.messages[index]);
                          },
                        ),
                ),
                // Input
                ChatInput(
                  controller: _inputCtl,
                  isSending: state.status == AiStatus.sending,
                  onSend: () => _sendMessage(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildNoProvider() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.orange),
            const SizedBox(height: 16),
            const Text(
              'لم يتم إضافة أي مزود ذكاء اصطناعي',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'الرجاء إضافة مزود من الإعدادات أولاً',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, AiSettingsPage.routeName),
              icon: const Icon(Icons.settings),
              label: const Text('فتح الإعدادات'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 8),
            Text('جارٍ التفكير...', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
