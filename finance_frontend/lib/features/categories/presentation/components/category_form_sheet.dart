import 'package:finance_frontend/features/categories/domain/entities/category_type_enum.dart';
import 'package:finance_frontend/features/categories/domain/entities/category.dart';
import 'package:finance_frontend/features/categories/domain/entities/dtos/category_create.dart';
import 'package:finance_frontend/features/categories/domain/entities/dtos/category_patch.dart';
import 'package:finance_frontend/features/categories/presentation/blocs/category_form/category_form_bloc.dart';
import 'package:finance_frontend/features/categories/presentation/blocs/category_form/category_form_event.dart';
import 'package:finance_frontend/features/categories/presentation/blocs/category_form/category_form_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CategoryFormSheet extends StatefulWidget {
  final FinanceCategory? initialCategory;

  const CategoryFormSheet({this.initialCategory, super.key});

  @override
  State<CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends State<CategoryFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  CategoryType? _type;

  @override
  void initState() {
    super.initState();
    if (widget.initialCategory != null) {
      final c = widget.initialCategory!;
      _nameCtrl.text = c.name;
      _descCtrl.text = c.description;
      _type = c.type;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialCategory != null;

    return BlocListener<CategoryFormBloc, CategoryFormState>(
      listener: (context, state) {
        if (state is CategoryOperationSuccess ||
            state is CategoryDeleteOperationSuccess) {
          Navigator.of(context).pop();
        } else if (state is CategoryOperationFailure) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      child: Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: FractionallySizedBox(
          heightFactor: 0.8,
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 48,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          isEditing ? 'Edit Category' : 'Create Category',
                          style: Theme.of(context).textTheme.headlineSmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _nameCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Name',
                            hintText: 'e.g., Groceries',
                          ),
                          validator: (v) =>
                              (v == null || v.trim().isEmpty)
                                  ? 'Name required'
                                  : null,
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<CategoryType>(
                          value: _type,
                          decoration:
                              const InputDecoration(labelText: 'Category Type'),
                          items: CategoryType.values
                              .map(
                                (type) => DropdownMenuItem(
                                  value: type,
                                  child: Text(type.name),
                                ),
                              )
                              .toList(),
                          onChanged: (val) => setState(() => _type = val),
                          validator: (val) =>
                              val == null ? 'Type required' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _descCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Description (optional)',
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 16),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => _submit(context, isEditing),
                          child: Text(
                            isEditing ? 'Save Changes' : 'Create Category',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submit(BuildContext context, bool isEditing) {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameCtrl.text.trim();
    final desc = _descCtrl.text.trim();
    final type = _type!;

    if (isEditing && widget.initialCategory != null) {
      final id = widget.initialCategory!.id;
      final patch = CategoryPatch(
        name: name != widget.initialCategory!.name ? name : null,
        type: type != widget.initialCategory!.type ? type : null,
        description: desc != widget.initialCategory!.description
            ? desc
            : null,
      );
      if (patch.isEmpty) {
        Navigator.of(context).pop();
        return;
      }
      context.read<CategoryFormBloc>().add(UpdateCategory(id, patch));
    } else {
      final createDto = CategoryCreate(
        name: name,
        type: type,
        description: desc,
      );
      context.read<CategoryFormBloc>().add(CreateCategory(createDto));
    }
  }
}
