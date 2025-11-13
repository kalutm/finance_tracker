import 'package:finance_frontend/features/accounts/domain/entities/account.dart';
import 'package:finance_frontend/features/accounts/presentation/blocs/accounts/accounts_bloc.dart';
import 'package:finance_frontend/features/accounts/presentation/blocs/accounts/accounts_state.dart';
import 'package:finance_frontend/features/categories/domain/entities/category.dart';
import 'package:finance_frontend/features/categories/presentation/blocs/categories/categories_bloc.dart';
import 'package:finance_frontend/features/transactions/data/model/dtos/transaction_create.dart';
import 'package:finance_frontend/features/transactions/data/model/dtos/transaction_update.dart';
import 'package:finance_frontend/features/transactions/data/model/dtos/transfer_transaction_create.dart';
import 'package:finance_frontend/features/transactions/domain/entities/transaction.dart';
import 'package:finance_frontend/features/transactions/domain/entities/transaction_operation_type.dart';
import 'package:finance_frontend/features/transactions/domain/entities/transaction_type.dart';
import 'package:finance_frontend/features/transactions/presentation/bloc/transaction_form/transaction_form_bloc.dart';
import 'package:finance_frontend/features/transactions/presentation/bloc/transaction_form/transaction_form_event.dart';
import 'package:finance_frontend/features/transactions/presentation/bloc/transaction_form/transaction_form_state.dart';
import 'package:finance_frontend/features/transactions/presentation/bloc/transactions/transactions_bloc.dart';
import 'package:finance_frontend/features/transactions/presentation/bloc/transactions/transactions_event.dart';
import 'package:finance_frontend/features/transactions/presentation/components/transaction_category_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class TransactionFormModal extends StatefulWidget {
  final Transaction? initialTransaction; // The transaction being edited

  const TransactionFormModal({this.initialTransaction, super.key});

  @override
  State<TransactionFormModal> createState() => _TransactionFormModalState();
}

class _TransactionFormModalState extends State<TransactionFormModal>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  Account? _selectedAccount;

  // Expense/Income Fields (TransactionCreate) 
  FinanceCategory? _selectedCategory;
  final TextEditingController _merchantController = TextEditingController();
  TransactionType _transactionType = TransactionType.EXPENSE; // 'Expense' or 'Income'

  // Transfer Fields (TransferTransactionCreate)
  Account? _selectedToAccount;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Check if we are editing an existing transaction
    if (widget.initialTransaction != null) {
      _loadInitialData(widget.initialTransaction!);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    _merchantController.dispose();
    super.dispose();
  }

  // New Method: Load Initial Data ---
  void _loadInitialData(Transaction txn) {
    final isTransfer = txn.type == TransactionType.TRANSFER;
    // If editing, we generally lock the type/tab
    _tabController.index = isTransfer ? 1 : 0;

    // Populate common fields
    _amountController.text = txn.amount;
    _selectedDate = txn.occuredAt;
    _descriptionController.text = txn.description ?? '';

    // Set Account (requires fetching from AccountsBloc or passing account entity)
    final accountsState = context.read<AccountsBloc>().state;
    if (accountsState is AccountsLoaded) {
      // Find the account by ID, checking the ID string matches
      _selectedAccount = accountsState.accounts.cast<Account?>().firstWhere(
        (acc) => acc?.id == txn.accountId,
        orElse: () => null,
      );
    }

    if (!isTransfer) {
      // Expense/Income specific fields
      _transactionType = txn.type; // 'Expense' or 'Income'
      _merchantController.text = txn.merchant ?? '';

      // Placeholder Category (since we don't have a lookup)
      // In a real app, you'd fetch the Category entity by ID here.
    } else {
      // Transfer specific fields
      // NOTE: For editing, the complexity of matching the TO account is high.
      // We only allow editing of amount/date/description for the group.
    }

    // Force a UI refresh to show loaded data
    WidgetsBinding.instance.addPostFrameCallback((_) => setState(() {}));
  }

  // --- Helpers ---
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // --- Submission Logic ---
  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final bloc = context.read<TransactionFormBloc>();
      final isEditing = widget.initialTransaction != null;

      if (_tabController.index == 0) {
        if (isEditing) {
          // --- UPDATE LOGIC ---
          final patchDto = TransactionPatch(
            amount: _amountController.text,
            occuredAt: _selectedDate,
            categoryId: _selectedCategory?.id,
            merchant:
                _merchantController.text.trim().isNotEmpty
                    ? _merchantController.text.trim()
                    : null,
            description:
                _descriptionController.text.trim().isNotEmpty
                    ? _descriptionController.text.trim()
                    : null,
          );
          if (!patchDto.isEmpty) {
            bloc.add(
              UpdateTransaction(widget.initialTransaction!.id, patchDto),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No changes to save.')),
            );
          }
        } else {
          // --- CREATE LOGIC ---
          final createDto = TransactionCreate(
            amount: _amountController.text,
            occuredAt: _selectedDate,
            accountId: _selectedAccount!.id,
            categoryId: _selectedCategory?.id,
            currency: _selectedAccount!.currency,
            merchant:
                _merchantController.text.trim().isNotEmpty
                    ? _merchantController.text.trim()
                    : null,
            type: _transactionType,
            description:
                _descriptionController.text.trim().isNotEmpty
                    ? _descriptionController.text.trim()
                    : null,
          );
          bloc.add(CreateTransaction(createDto));
        }
      } else {
        // TRANSFER
        if (isEditing) {
          // Transfers are generally not editable directly, only deletable.
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Transfers can only be deleted, not edited. Recreate it if needed.',
              ),
            ),
          );
        } else {
          // --- CREATE LOGIC ---
          final createTransferDto = TransferTransactionCreate(
            accountId: int.parse(_selectedAccount!.id),
            toAccountId: int.parse(_selectedToAccount!.id),
            amount: _amountController.text,
            currency: _selectedAccount!.currency,
            type: TransactionType.TRANSFER,
            description:
                _descriptionController.text.trim().isNotEmpty
                    ? _descriptionController.text.trim()
                    : null,
            occurredAt: _selectedDate,
          );
          bloc.add(CreateTransferTransaction(createTransferDto));
        }
      }
    }
  }

  // 8. New Method: Delete Confirmation Dialog
  void _confirmDelete(BuildContext context) {
    final theme = Theme.of(context);
    final txn = widget.initialTransaction!;

    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(
              'Confirm Deletion',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
            content: Text(
              txn.type == TransactionType.TRANSFER
                  ? 'Are you sure you want to delete this Transfer group? Both transactions will be permanently deleted.'
                  : 'Are you sure you want to delete this transaction?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.error,
                ),
                onPressed: () {
                  Navigator.of(ctx).pop(); // Close dialog
                  if (txn.type == TransactionType.TRANSFER) {
                    // Assuming txn.id is the transfer_group_id if it's a transfer entity
                    context.read<TransactionFormBloc>().add(
                      DeleteTransferTransaction(txn.id),
                    );
                  } else {
                    context.read<TransactionFormBloc>().add(
                      DeleteTransaction(txn.id),
                    );
                  }
                },
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accountsState = context.watch<AccountsBloc>().state;
    List<Account> accounts = [];
    if (accountsState is AccountsLoaded) {
      accounts = accountsState.accounts;
      if (_selectedAccount == null &&
          accounts.isNotEmpty &&
          widget.initialTransaction == null) {
        // Set a default account only for *new* transactions
        _selectedAccount = accounts.first;
      }
    }

    final isEditing = widget.initialTransaction != null;

    // --- BLoC Listener for Success/Failure ---
    return BlocListener<TransactionFormBloc, TransactionFormState>(
      listener: (context, state) {
        if (state is TransactionOperationSuccess) {
          final isUpdate =
              state.operationType == TransactionOperationType.update;
          // Notify TransactionsBloc and close
          context.read<TransactionsBloc>().add(
            isUpdate
                ? TransactionUpdatedInForm(state.transaction)
                : TransactionCreatedInForm(state.transaction),
          );
          Navigator.of(context).pop(); // Close form
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Transaction ${isUpdate ? 'updated' : 'created'} successfully!',
              ),
            ),
          );
        } else if (state is CreateTransferTransactionOperationSuccess) {
          // Notify TransactionsBloc and close
          context.read<TransactionsBloc>().add(
            TransferTransactionCreatedInForm(state.outgoing, state.incoming),
          );
          Navigator.of(context).pop(); // Close form
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Transfer created successfully!')),
          );
        } else if (state is TransactionDeleteOperationSuccess ||
            state is TransferTransactionDeleteOperationSuccess) {
          // Notify TransactionsBloc of the deletion
          final id =
              state is TransactionDeleteOperationSuccess
                  ? state.id
                  : (state as TransferTransactionDeleteOperationSuccess)
                      .transferGroupId;
          context.read<TransactionsBloc>().add(
            TransactionDeletedInForm(id),
          ); // Assuming single event covers both
          Navigator.of(context).pop(); // Close form
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Transaction deleted successfully!')),
          );
        } else if (state is TransactionOperationFailure) {
          showDialog(
            context: context,
            builder:
                (dialogContext) => AlertDialog(
                  title: const Text('Transaction Failed'),
                  content: Text(state.message),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: const Text('OK'),
                    ),
                  ],
                ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            isEditing ? 'Edit Transaction' : 'Record New Transaction',
          ),
          actions:
              isEditing
                  ? [
                    IconButton(
                      icon: const Icon(
                        Icons.delete_forever_rounded,
                        color: Colors.redAccent,
                      ),
                      tooltip: 'Delete Transaction',
                      onPressed: () => _confirmDelete(context),
                    ),
                  ]
                  : null,
          bottom: TabBar(
            controller: _tabController,
            // Disable swiping/tapping tabs if we are editing an existing item (to prevent accidental type change)
            physics: isEditing ? const NeverScrollableScrollPhysics() : null,
            onTap: isEditing ? (index) {} : null,
            labelStyle: theme.textTheme.labelLarge,
            indicatorColor: theme.colorScheme.onPrimary,
            tabs: const [Tab(text: 'Expense / Income'), Tab(text: 'Transfer')],
          ),
        ),

        // --- Form Body ---
        body: TabBarView(
          controller: _tabController,
          children: [
            // Tab 1: Expense / Income Form
            _buildExpenseIncomeForm(theme, accounts, isEditing),
            // Tab 2: Transfer Form
            _buildTransferForm(theme, accounts, isEditing),
          ],
        ),

        // --- Save Button ---
        floatingActionButton:
            BlocBuilder<TransactionFormBloc, TransactionFormState>(
              builder: (context, state) {
                final isLoading = state is TransactionOperationInProgress;
                return FloatingActionButton.extended(
                  onPressed: isLoading ? null : _submitForm,
                  label: Text(
                    isLoading
                        ? 'Processing...'
                        : isEditing && _tabController.index == 0
                        ? 'Save Changes'
                        : 'Save Transaction',
                  ),
                  icon:
                      isLoading
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Icon(Icons.check_circle_outline_rounded),
                );
              },
            ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }

  // --- Tab 1: Expense/Income Form Builder ---
  Widget _buildExpenseIncomeForm(
    ThemeData theme,
    List<Account> accounts,
    bool isEditing,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Type Toggle (Disabled if editing)
            Center(
              child: ToggleButtons(
                borderRadius: BorderRadius.circular(8),
                selectedColor: theme.colorScheme.onPrimary,
                fillColor: theme.colorScheme.primary,
                color: theme.colorScheme.onSurface,
                constraints: const BoxConstraints(minWidth: 120, minHeight: 40),
                isSelected: [
                  _transactionType == TransactionType.EXPENSE,
                  _transactionType == TransactionType.INCOME,
                ],
                onPressed:
                    isEditing
                        ? null
                        : (index) {
                          // Disable if editing
                          setState(() {
                            _transactionType =
                                index == 0 ? TransactionType.EXPENSE : TransactionType.INCOME;
                          });
                        },
                children: [
                  Text('Expense', style: theme.textTheme.labelLarge),
                  Text('Income', style: theme.textTheme.labelLarge),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Amount Field
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixIcon: Icon(Icons.attach_money),
              ),
              validator:
                  (value) =>
                      value == null ||
                              double.tryParse(value) == null ||
                              double.parse(value)! <= 0
                          ? 'Enter a valid amount'
                          : null,
            ),
            const SizedBox(height: 16),

            // Account Selector (Disabled if editing)
            AbsorbPointer(
              absorbing: isEditing,
              child: _buildAccountSelectorField(
                theme,
                accounts,
                (account) => setState(() => _selectedAccount = account),
                _selectedAccount,
              ),
            ),
            const SizedBox(height: 16),

            // Category Selector
            BlocProvider.value(
              value: context.read<CategoriesBloc>(),
              child: CategorySelector(
                selectedCategory: _selectedCategory,
                onCategorySelected: (category) {
                  setState(() {
                    _selectedCategory = category;
                  });
                },
              ),
            ),

            const SizedBox(height: 16),

            // Date Picker
            ListTile(
              title: Text('Date: ${DateFormat.yMd().format(_selectedDate)}'),
              leading: const Icon(Icons.calendar_today),
              trailing: const Icon(Icons.edit),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: theme.colorScheme.onSurface.withOpacity(0.2),
                ),
              ),
              onTap: () => _selectDate(context),
            ),
            const SizedBox(height: 16),

            // Merchant Field (Optional)
            TextFormField(
              controller: _merchantController,
              decoration: const InputDecoration(
                labelText: 'Merchant/Payee (Optional)',
                prefixIcon: Icon(Icons.store),
              ),
            ),
            const SizedBox(height: 16),

            // Description Field (Optional)
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notes/Description (Optional)',
                prefixIcon: Icon(Icons.description),
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Tab 2: Transfer Form Builder ---
  Widget _buildTransferForm(
    ThemeData theme,
    List<Account> accounts,
    bool isEditing,
  ) {
    if (isEditing) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text(
            'Edit details on the Expense/Income tab, or use the delete button to remove this transfer group.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // ... (Transfer form content - identical to previous, but using isEditing to control absorption)
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Form(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Amount Field
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Transfer Amount',
                prefixIcon: Icon(Icons.attach_money),
              ),
              validator:
                  (value) =>
                      value == null ||
                              double.tryParse(value) == null ||
                              double.parse(value)! <= 0
                          ? 'Enter a valid amount'
                          : null,
            ),
            const SizedBox(height: 16),

            // Account Selector (From)
            _buildAccountSelectorField(
              theme,
              accounts,
              (account) => setState(() => _selectedAccount = account),
              _selectedAccount,
              label: 'Transfer FROM Account',
            ),
            const SizedBox(height: 16),

            const Center(child: Icon(Icons.arrow_downward_rounded, size: 32)),
            const SizedBox(height: 16),

            // Account Selector (To)
            _buildAccountSelectorField(
              theme,
              accounts.where((acc) => acc != _selectedAccount).toList(),
              (account) => setState(() => _selectedToAccount = account),
              _selectedToAccount,
              label: 'Transfer TO Account',
            ),
            const SizedBox(height: 16),

            // Date Picker (Same as E/I)
            ListTile(
              title: Text('Date: ${DateFormat.yMd().format(_selectedDate)}'),
              leading: const Icon(Icons.calendar_today),
              trailing: const Icon(Icons.edit),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: theme.colorScheme.onSurface.withOpacity(0.2),
                ),
              ),
              onTap: () => _selectDate(context),
            ),
            const SizedBox(height: 16),

            // Description Field (Optional, Same as E/I)
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notes/Description (Optional)',
                prefixIcon: Icon(Icons.description),
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Reusable Account Selector Dropdown ---
  Widget _buildAccountSelectorField(
    ThemeData theme,
    List<Account> accounts,
    Function(Account?) onChanged,
    Account? selectedAccount, {
    String label = 'Select Account',
  }) {
    return DropdownButtonFormField<Account>(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.account_balance_wallet_rounded),
        border: const OutlineInputBorder(),
      ),
      value: selectedAccount,
      isExpanded: true,
      items:
          accounts.map((Account account) {
            return DropdownMenuItem<Account>(
              value: account,
              child: Text('${account.name} (${account.currency})'),
            );
          }).toList(),
      onChanged: onChanged,
      validator: (value) => value == null ? 'Please select an account' : null,
    );
  }
}
