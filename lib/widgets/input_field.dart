import 'package:flutter/material.dart';

const kRed = Color(0xFFE53935);

class InputField extends StatefulWidget {
  final TextEditingController controller;
  final TextInputType keyboardType;
  final String label;
  final String? hint;
  final IconData icon;
  final String? Function(String?)? validator;
  final bool obscureText;

  const InputField({
    super.key,
    required this.controller,
    required this.icon,
    required this.label,
    this.hint,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.obscureText = false,
  });

  @override
  State<InputField> createState() => _InputFieldState();
}

class _InputFieldState extends State<InputField> {
  late bool _isObscure;

  @override
  void initState() {
    super.initState();
    _isObscure = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      keyboardType: widget.keyboardType,
      obscureText: _isObscure,
      validator: widget.validator,
      cursorColor: kRed,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        prefixIcon: Icon(widget.icon, color: kRed),
        suffixIcon: widget.obscureText
            ? IconButton(
                icon: Icon(
                  _isObscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: Colors.grey,
                  size: 20,
                ),
                onPressed: () => setState(() => _isObscure = !_isObscure),
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50),
          borderSide: const BorderSide(color: kRed, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50),
          borderSide: const BorderSide(color: kRed),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50),
          borderSide: const BorderSide(color: kRed, width: 1.5),
        ),

        errorStyle: const TextStyle(color: kRed, fontSize: 11),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}
