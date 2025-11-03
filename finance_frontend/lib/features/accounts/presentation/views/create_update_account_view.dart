import 'package:finance_frontend/features/accounts/domain/entities/account.dart';
import 'package:finance_frontend/features/accounts/domain/entities/account_type_enum.dart';
import 'package:finance_frontend/features/accounts/domain/entities/dtos/account_create.dart';
import 'package:finance_frontend/features/accounts/domain/entities/dtos/account_patch.dart';
import 'package:finance_frontend/features/accounts/presentation/blocs/account_form/account_form_bloc.dart';
import 'package:finance_frontend/features/accounts/presentation/blocs/account_form/account_form_event.dart';
import 'package:finance_frontend/features/accounts/presentation/blocs/account_form/account_form_state.dart';
import 'package:finance_frontend/features/accounts/presentation/blocs/accounts/accounts_bloc.dart';
import 'package:finance_frontend/features/accounts/presentation/blocs/accounts/accounts_event.dart';
import 'package:finance_frontend/features/accounts/presentation/blocs/entities/operation_type_enum.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CreateUpdateAccountView extends StatefulWidget {
  final bool isUpdate;
  final Account? account;
  const CreateUpdateAccountView({
    required this.isUpdate,
    super.key,
    this.account,
  });

  @override
  State<CreateUpdateAccountView> createState() =>
      _CreateUpdateAccountViewState();
}

class _CreateUpdateAccountViewState extends State<CreateUpdateAccountView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late final TextEditingController _nameController;
  AccountType? type;
  TextEditingController? _currencyController;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);

    _nameController = TextEditingController();
    _nameController.text = widget.isUpdate ? widget.account!.name : "";

    type = widget.isUpdate ? widget.account!.type : AccountType.CASH;

    _currencyController = widget.isUpdate ? null : TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isUpdate = widget.isUpdate;
    final account = widget.account;

    return Scaffold(
        appBar: AppBar(
          title: Text(isUpdate ? "Update Account" : "Create Account"),
          actions: [
            isUpdate ? (IconButton(onPressed: () {
              context.read<AccountFormBloc>().add(account.active ? DeactivateAccount(account.id) : RestoreAccount(account.id));
            }, icon: Icon(account!.active ? Icons.delete : Icons.restore))) : Text("")
          ],
        ),
        body: BlocListener<AccountFormBloc, AccountFormState>(
          listener: (context, state) {
            if (state is AccountOperationSuccess) {
              if (state.operationType == AccountOperationType.create) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Account created successfully")),
                );
                context.read<AccountsBloc>().add(
                  AccountCreatedInForm(state.account),
                );
              }
              if (state.operationType == AccountOperationType.update) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Account updated successfully")),
                );
                context.read<AccountsBloc>().add(
                  AccountUpdatedInForm(state.account),
                );
              }
              if (state.operationType == AccountOperationType.deactivate) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Account deactivated successfully")),
                );
                context.read<AccountsBloc>().add(
                  AccountDeactivatedInForm(state.account),
                );
              }
              if (state.operationType == AccountOperationType.restore) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Account restored successfully")),
                );
                context.read<AccountsBloc>().add(
                  AccountRestoredInForm(state.account),
                );
              }
            } else if (state is AccountDeleteOperationSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Account deleted successfully")),
              );
              context.read<AccountsBloc>().add(
                AccountDeletedInForm(account!.id),
              );
            } else if (state is AccountOperationFailure) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.message)));
            } else {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: CircularProgressIndicator()));
            }
          },
          child: Column(
            children: [
              TextField(
                decoration: InputDecoration(label: Text("enter name")),
                controller: _nameController,
              ),
              DropdownButton(
                items:
                    AccountType.values
                        .map(
                          (accountType) => DropdownMenuItem(
                            value: accountType,
                            child: Text(accountType.name),
                          ),
                        )
                        .toList(),
                onChanged: (value) {
                  setState(() {
                    type = value;
                  });
                },
                value: type,
              ),
              isUpdate
                  ? Text("")
                  : TextField(
                    decoration: InputDecoration(label: Text("enter currency")),
                    controller: _currencyController,
                  ),
              TextButton.icon(
                onPressed: () {
                  context.read<AccountFormBloc>().add(
                    !isUpdate
                        ? CreateAccount(
                          AccountCreate(
                            name: _nameController.text,
                            type: type!,
                            currency: _currencyController!.text,
                          ),
                        )
                        : UpdateAccount(
                          account!.id,
                          AccountPatch(name: _nameController.text, type: type),
                        ),
                  );
                },
                label: Text(isUpdate ? "Update" : "Create"),
              ),
            ],
          ),
        ),
      );
  }
}
