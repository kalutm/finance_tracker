import 'package:flutter/material.dart';

class AuthField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData prefixIcon;
  final bool isPassword;
  final TextInputType keyboardType;

  const AuthField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.prefixIcon,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
  });

  @override
  State<AuthField> createState() => _AuthFieldState();
}

class _AuthFieldState extends State<AuthField> {
  bool _isObscured = true;

  @override
  Widget build(BuildContext context) {
    // Getting theme data to style our field consistently
    final theme = Theme.of(context);

    return TextFormField(
      controller: widget.controller,
      keyboardType: widget.keyboardType,
      obscureText: widget.isPassword ? _isObscured : false,
      decoration: InputDecoration(
        hintText: widget.hintText,
        prefixIcon: Icon(widget.prefixIcon, color: theme.colorScheme.onSurface.withAlpha(153)),
        // Suffix icon for password visibility toggle
        suffixIcon: widget.isPassword
            ? IconButton(
                icon: Icon(
                  _isObscured ? Icons.visibility_off : Icons.visibility,
                  color: theme.colorScheme.onSurface.withAlpha(153),
                ),
                onPressed: () {
                  setState(() {
                    _isObscured = !_isObscured;
                  });
                },
              )
            : null,
      ),
      // Basic validator, can be expanded
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '${widget.hintText} cannot be empty';
        }
        if (widget.hintText.toLowerCase().contains('email') && !value.contains('@')) {
          return 'Please enter a valid email';
        }
        return null;
      },
    );
  }
}