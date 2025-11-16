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
import 'package:finance_frontend/features/transactions/presentation/components/transaction_category_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class TransactionFormModal extends StatefulWidget {
  final Transaction? initialTransaction;

  const TransactionFormModal({this.initialTransaction, super.key});

  @override
  State<TransactionFormModal> createState() => _TransactionFormModalState();
}

class _TransactionFormModalState extends State<TransactionFormModal>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _transferFormKey = GlobalKey<FormState>();

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  Account? _selectedAccount;

  // Expense/Income Fields for (TransactionCreate)
  FinanceCategory? _selectedCategory;
  final TextEditingController _merchantController = TextEditingController();
  TransactionType _transactionType =
      TransactionType.EXPENSE; // 'Expense' or 'Income'

  // Transfer Fields for (TransferTransactionCreate)
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

  void _loadInitialData(Transaction txn) {
    final isTransfer = txn.type == TransactionType.TRANSFER;
    _tabController.index = isTransfer ? 1 : 0;

    _amountController.text = txn.amount;
    _selectedDate = txn.occuredAt;
    _descriptionController.text = txn.description ?? '';

    // Set Account
    final accountsState = context.read<AccountsBloc>().state;
    if (accountsState is AccountsLoaded) {
      // Find the account by ID, checking the ID string matches
      _selectedAccount = accountsState.accounts.cast<Account?>().firstWhere(
        (acc) => acc?.id == txn.accountId,
        orElse: () => null,
      );
    }

    if (!isTransfer) {
      // set Expense/Income specific fields
      _transactionType = txn.type; 
      _merchantController.text = txn.merchant ?? '';

    } 
    // Force a UI refresh to show loaded data
    WidgetsBinding.instance.addPostFrameCallback((_) => setState(() {}));
  }

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

  void _submitForm() {
  final isEditing = widget.initialTransaction != null;
  final bloc = context.read<TransactionFormBloc>();

  if (_tabController.index == 0) {
    // Income / Expense Form
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      if (isEditing) {
        final patchDto = TransactionPatch(
          amount: _amountController.text,
          occuredAt: _selectedDate,
          categoryId: _selectedCategory?.id,
          merchant: _merchantController.text.trim().isNotEmpty
              ? _merchantController.text.trim()
              : null,
          description: _descriptionController.text.trim().isNotEmpty
              ? _descriptionController.text.trim()
              : null,
        );
        if (!patchDto.isEmpty) {
          bloc.add(UpdateTransaction(widget.initialTransaction!.id, patchDto));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No changes to save.')),
          );
        }
      } else {
        final createDto = TransactionCreate(
          amount: _amountController.text,
          occuredAt: _selectedDate,
          accountId: _selectedAccount!.id,
          categoryId: _selectedCategory?.id,
          currency: _selectedAccount!.currency,
          merchant: _merchantController.text.trim().isNotEmpty
              ? _merchantController.text.trim()
              : null,
          type: _transactionType,
          description: _descriptionController.text.trim().isNotEmpty
              ? _descriptionController.text.trim()
              : null,
        );
        bloc.add(CreateTransaction(createDto));
      }
    }
  } else {
    // Transfer Form
    if (_transferFormKey.currentState!.validate()) {
      _transferFormKey.currentState!.save();

      if (isEditing) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Transfers can only be deleted, not edited. Recreate it if needed.',
            ),
          ),
        );
      } else {
        if (_selectedAccount == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select the FROM Account.')),
          );
          return;
        }
        if (_selectedToAccount == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select the TO Account.')),
          );
          return;
        }
        if (_selectedAccount!.id == _selectedToAccount!.id) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content:
                    Text('Source and Destination accounts cannot be the same.')),
          );
          return;
        }

        final createTransferDto = TransferTransactionCreate(
          accountId: _selectedAccount!.id,
          toAccountId: _selectedToAccount!.id,
          amount: _amountController.text,
          currency: _selectedAccount!.currency,
          type: TransactionType.TRANSFER,
          description: _descriptionController.text.trim().isNotEmpty
              ? _descriptionController.text.trim()
              : null,
          occurredAt: _selectedDate,
        );
        bloc.add(CreateTransferTransaction(createTransferDto));
      }
    }
  }
}


  void _confirmDelete(BuildContext context) {
    final theme = Theme.of(context);
    final txn = widget.initialTransaction!;
    final isTransfer = txn.type == TransactionType.TRANSFER;

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
              isTransfer
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
                  Navigator.of(ctx).pop(); 

                  if (isTransfer) {
                    if (txn.transferGroupId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Transfer group ID missing!'),
                        ),
                      );
                      return;
                    }
                    context.read<TransactionFormBloc>().add(
                      DeleteTransferTransaction(txn.transferGroupId!),
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
      final activeAccounts = accountsState.accounts.where((acc) => acc.active).toList();
      accounts = activeAccounts;
      if (_selectedAccount == null &&
          accounts.isNotEmpty &&
          widget.initialTransaction == null) {
        // Set a default account only for a new transaction
        _selectedAccount = accounts.first;
      }
    }

    final isEditing = widget.initialTransaction != null;

    return BlocListener<TransactionFormBloc, TransactionFormState>(
      listener: (context, state) {
        if (state is TransactionOperationSuccess) {
          final isUpdate =
              state.operationType == TransactionOperationType.update;
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Transaction ${isUpdate ? 'updated' : 'created'} successfully!',
              ),
            ),
          );
        } else if (state is CreateTransferTransactionOperationSuccess) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Transfer created successfully!')),
          );
        } else if (state is TransactionDeleteOperationSuccess ||
            state is TransferTransactionDeleteOperationSuccess) {
          Navigator.of(context).pop();
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

        body: TabBarView(
          controller: _tabController,
          children: [
            _buildExpenseIncomeForm(theme, accounts, isEditing),
            _buildTransferForm(theme, accounts, isEditing),
          ],
        ),

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
                                index == 0
                                    ? TransactionType.EXPENSE
                                    : TransactionType.INCOME;
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
                              double.parse(value) <= 0
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
                  color: theme.colorScheme.onSurface.withAlpha(51),
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

  final fromAccounts = accounts;

  // To list excludes the currently selected FROM account
  final toAccounts = accounts.where((acc) => acc.id != _selectedAccount?.id).toList();

  // Defensive: if previously selected TO account is now invalid (equal to FROM), clear it 
  if (_selectedToAccount != null &&
      toAccounts.indexWhere((a) => a.id == _selectedToAccount!.id) == -1) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _selectedToAccount = null;
        });
      }
    });
  }

  return SingleChildScrollView(
    padding: const EdgeInsets.all(20.0),
    child: Form(
      key: _transferFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Transfer Amount',
              prefixIcon: Icon(Icons.attach_money),
            ),
            validator: (value) =>
                value == null || double.tryParse(value) == null || double.parse(value) <= 0
                    ? 'Enter a valid amount'
                    : null,
          ),
          const SizedBox(height: 16),

          // Account Selector (From)
          // When user selects FROM account, ensure TO selection is not the same
          _buildAccountSelectorField(
            theme,
            fromAccounts,
            (account) {
              setState(() {
                _selectedAccount = account;
                // If the TO account equals newly selected FROM, clear it.
                if (_selectedToAccount != null && _selectedToAccount!.id == account?.id) {
                  _selectedToAccount = null;
                }
              });
            },
            _selectedAccount,
            label: 'Transfer FROM Account',
          ),
          const SizedBox(height: 16),

          const Center(child: Icon(Icons.arrow_downward_rounded, size: 32)),
          const SizedBox(height: 16),

          // Account Selector (To)
          // Guard the value so it's null if it isn't present in the `toAccounts` list
          _buildAccountSelectorField(
            theme,
            toAccounts,
            (account) => setState(() => _selectedToAccount = account),
            // If current selectedToAccount is not in toAccounts, pass null
            toAccounts.any((a) => a.id == _selectedToAccount?.id) ? _selectedToAccount : null,
            label: 'Transfer TO Account',
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
                color: theme.colorScheme.onSurface.withAlpha(51),
              ),
            ),
            onTap: () => _selectDate(context),
          ),
          const SizedBox(height: 16),

          // Description Field
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

Widget _buildAccountSelectorField(
  ThemeData theme,
  List<Account> accounts,
  void Function(Account?) onChanged,
  Account? selectedAccount, {
  String label = 'Select Account',
}) {
  final valueToUse = selectedAccount != null && accounts.any((a) => a.id == selectedAccount.id)
      ? selectedAccount
      : null;

  return DropdownButtonFormField<Account>(
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: const Icon(Icons.account_balance_wallet_rounded),
      border: const OutlineInputBorder(),
    ),
    value: valueToUse,
    isExpanded: true,
    items: accounts.map((Account account) {
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
