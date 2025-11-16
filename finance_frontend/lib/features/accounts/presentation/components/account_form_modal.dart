import 'package:finance_frontend/features/accounts/presentation/components/account_form_failure_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:finance_frontend/features/accounts/domain/entities/account.dart';
import 'package:finance_frontend/features/accounts/domain/entities/account_type_enum.dart';
import 'package:finance_frontend/features/accounts/domain/entities/dtos/account_create.dart';
import 'package:finance_frontend/features/accounts/domain/entities/dtos/account_patch.dart';
import 'package:finance_frontend/features/accounts/presentation/blocs/account_form/account_form_bloc.dart';
import 'package:finance_frontend/features/accounts/presentation/blocs/account_form/account_form_event.dart';
import 'package:finance_frontend/features/accounts/presentation/blocs/account_form/account_form_state.dart';
import 'package:finance_frontend/features/accounts/presentation/blocs/entities/operation_type_enum.dart';

class AccountFormModal extends StatefulWidget {
  final bool isUpdate;
  final Account? account;

  const AccountFormModal({required this.isUpdate, this.account, super.key});

  @override
  State<AccountFormModal> createState() => _AccountFormModalState();
}

class _AccountFormModalState extends State<AccountFormModal> {
  late final TextEditingController _nameController;
  late final TextEditingController _currencyController;
  AccountType? _selectedType;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.account?.name ?? '');
    _currencyController = TextEditingController();
    _selectedType = widget.account?.type ?? AccountType.CASH;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _currencyController.dispose();
    super.dispose();
  }

  // Handles the main form submission (Create/Update)
  void _submitForm() {
    if (!_formKey.currentState!.validate()) return;

    final formBloc = context.read<AccountFormBloc>();

    if (widget.isUpdate) {
      formBloc.add(
        UpdateAccount(
          widget.account!.id,
          AccountPatch(name: _nameController.text, type: _selectedType),
        ),
      );
    } else {
      formBloc.add(
        CreateAccount(
          AccountCreate(
            name: _nameController.text,
            type: _selectedType!,
            currency: _currencyController.text.toUpperCase(),
          ),
        ),
      );
    }
  }

  // Handles Deactivate/Restore/Delete actions
  void _handleAction(AccountOperationType actionType) {
    final formBloc = context.read<AccountFormBloc>();
    final accountId = widget.account!.id;

    if (actionType == AccountOperationType.deactivate) {
      formBloc.add(DeactivateAccount(accountId));
    } else if (actionType == AccountOperationType.restore) {
      formBloc.add(RestoreAccount(accountId));
    } else if (actionType == AccountOperationType.delete) {
      formBloc.add(DeleteAccount(accountId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final account = widget.account;
    final isUpdate = widget.isUpdate;
    final isInactive = isUpdate && !account!.active;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: BlocListener<AccountFormBloc, AccountFormState>(
        listener: (context, state) {
          if (state is AccountOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  "Account ${state.operationType.name}d successful.",
                ),
              ),
            );
            Navigator.of(context).pop();

          } else if (state is AccountDeleteOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Account deleted successfully.")),
            );
            Navigator.of(context).pop();
          } else if (state is AccountOperationFailure) {
            showDialog(
              context: context,
              builder: (dialogContext) => AccountFailureDialog(
                message: state.message,
              ),
            );
          }
        },
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isUpdate ? "Edit Account" : "New Account",
                  style: theme.textTheme.headlineMedium,
                ),
                const Divider(),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Account Name',
                    border: OutlineInputBorder(),
                  ),
                  validator:
                      (value) =>
                          value == null || value.isEmpty
                              ? 'Name is required'
                              : null,
                  enabled: !isInactive,
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<AccountType>(
                  value: _selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Account Type',
                    border: OutlineInputBorder(),
                  ),
                  items:
                      AccountType.values
                          .map(
                            (type) => DropdownMenuItem(
                              value: type,
                              child: Text(type.name.replaceAll('_', ' ')),
                            ),
                          )
                          .toList(),
                  onChanged:
                      isInactive
                          ? null
                          : (value) {
                            setState(() {
                              _selectedType = value;
                            });
                          },
                ),
                const SizedBox(height: 16),

                if (!isUpdate)
                  TextFormField(
                    controller: _currencyController,
                    decoration: const InputDecoration(
                      labelText: 'Currency (e.g., USD, EUR)',
                      border: OutlineInputBorder(),
                    ),
                    maxLength: 3,
                    textCapitalization: TextCapitalization.characters,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Currency is required';
                      }
                      if (value.length != 3) {
                        return 'Currency code must be exactly 3 characters (e.g., USD)';
                      }
                      return null;
                    },
                  ),
                if (!isUpdate) const SizedBox(height: 24),

                // --- Action Buttons ---
                BlocBuilder<AccountFormBloc, AccountFormState>(
                  builder: (context, state) {
                    final isSaving = state is AccountOperationInProgress;

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Deactivate/Restore/Delete Button
                        if (isUpdate)
                          _buildAccountActionButton(
                            context,
                            isInactive: isInactive,
                            isSaving: isSaving,
                          ),

                        const Spacer(),

                        // Cancel Button
                        TextButton(
                          onPressed:
                              isSaving
                                  ? null
                                  : () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),

                        // Create/Update Button
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed:
                              (isSaving || isInactive)
                                  ? null
                                  : _submitForm, // Cannot update inactive accounts
                          icon:
                              isSaving
                                  ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : Icon(
                                    isUpdate
                                        ? Icons.save_rounded
                                        : Icons.add_rounded,
                                  ),
                          label: Text(
                            isUpdate ? 'Save Changes' : 'Create Account',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAccountActionButton(
    BuildContext context, {
    required bool isInactive,
    required bool isSaving,
  }) {
    final theme = Theme.of(context);
    final account = widget.account!;

    return PopupMenuButton<AccountOperationType>(
      icon: Icon(
        Icons.more_vert_rounded,
        color: theme.colorScheme.onSurface.withAlpha(178),
      ),
      onSelected: _handleAction,
      itemBuilder:
          (context) => <PopupMenuEntry<AccountOperationType>>[
            if (account.active)
              PopupMenuItem<AccountOperationType>(
                value: AccountOperationType.deactivate,
                child: Row(
                  children: [
                    Icon(Icons.archive_rounded, color: theme.colorScheme.error),
                    const SizedBox(width: 8),
                    Text(
                      'Deactivate Account',
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ],
                ),
              ),
            if (!account.active) ...[
              PopupMenuItem<AccountOperationType>(
                value: AccountOperationType.restore,
                child: Row(
                  children: [
                    Icon(
                      Icons.restore_rounded,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    const Text('Restore Account'),
                  ],
                ),
              ),
              PopupMenuItem<AccountOperationType>(
                value: AccountOperationType.delete,
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_forever_rounded,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Permanently Delete',
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ],
                ),
              ),
            ],
          ],
      enabled: !isSaving,
    );
  }
}
