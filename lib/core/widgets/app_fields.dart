import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/formatters.dart';

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      );
}

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.validator,
    this.keyboardType,
    this.obscure = false,
    this.maxLines = 1,
    this.prefixIcon,
    this.suffix,
    this.onChanged,
    this.readOnly = false,
    this.onTap,
    this.textInputAction,
    this.onSubmitted,
    this.enabled = true,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool obscure;
  final int maxLines;
  final IconData? prefixIcon;
  final Widget? suffix;
  final ValueChanged<String>? onChanged;
  final bool readOnly;
  final VoidCallback? onTap;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          obscureText: obscure,
          maxLines: obscure ? 1 : maxLines,
          onChanged: onChanged,
          readOnly: readOnly,
          onTap: onTap,
          enabled: enabled,
          textInputAction: textInputAction,
          onFieldSubmitted: onSubmitted,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefixIcon == null ? null : Icon(prefixIcon, size: 20, color: AppColors.textSecondary),
            suffixIcon: suffix,
          ),
        ),
      ],
    );
  }
}

class AppDropdown<T> extends StatelessWidget {
  const AppDropdown({
    super.key,
    required this.label,
    required this.items,
    required this.value,
    required this.onChanged,
    this.itemLabel,
    this.validator,
    this.hint,
  });

  final String label;
  final List<T> items;
  final T? value;
  final ValueChanged<T?> onChanged;
  final String Function(T)? itemLabel;
  final String? Function(T?)? validator;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label),
        DropdownButtonFormField<T>(
          initialValue: value,
          isExpanded: true,
          validator: validator,
          hint: hint == null ? null : Text(hint!),
          decoration: const InputDecoration(),
          items: items
              .map((e) => DropdownMenuItem<T>(value: e, child: Text(itemLabel != null ? itemLabel!(e) : e.toString(), overflow: TextOverflow.ellipsis)))
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

/// Date picker field with validation support.
class DateSelector extends FormField<DateTime> {
  DateSelector({
    Key? key,
    required String label,
    DateTime? value,
    required ValueChanged<DateTime> onChanged,
    DateTime? firstDate,
    DateTime? lastDate,
    bool isRequired = true,
    String hint = 'Select date',
  }) : super(
          key: key ?? ValueKey('date-$label-${value?.millisecondsSinceEpoch}'),
          initialValue: value,
          validator: (v) => isRequired && v == null ? 'Please select $label' : null,
          builder: (state) {
            final context = state.context;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FieldLabel(label),
                InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () async {
                    final now = DateTime.now();
                    final first = firstDate ?? DateTime(now.year - 2);
                    final last = lastDate ?? DateTime(now.year + 2);
                    var initial = state.value ?? dateOnly(now);
                    if (initial.isBefore(first)) initial = first;
                    if (initial.isAfter(last)) initial = last;
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: initial,
                      firstDate: first,
                      lastDate: last,
                    );
                    if (picked != null) {
                      state.didChange(picked);
                      onChanged(picked);
                    }
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      errorText: state.errorText,
                      suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.textSecondary),
                    ),
                    child: Text(
                      state.value == null ? hint : Fmt.date(state.value!),
                      style: TextStyle(color: state.value == null ? AppColors.textSecondary : AppColors.textPrimary, fontSize: 14),
                    ),
                  ),
                ),
              ],
            );
          },
        );
}

/// Time picker field (returns a TimeOfDay).
class TimeSelector extends FormField<TimeOfDay> {
  TimeSelector({
    Key? key,
    required String label,
    TimeOfDay? value,
    required ValueChanged<TimeOfDay> onChanged,
    bool isRequired = true,
  }) : super(
          key: key ?? ValueKey('time-$label-${value?.hour}-${value?.minute}'),
          initialValue: value,
          validator: (v) => isRequired && v == null ? 'Select $label' : null,
          builder: (state) {
            final context = state.context;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FieldLabel(label),
                InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () async {
                    final picked = await showTimePicker(context: context, initialTime: state.value ?? const TimeOfDay(hour: 9, minute: 30));
                    if (picked != null) {
                      state.didChange(picked);
                      onChanged(picked);
                    }
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      errorText: state.errorText,
                      suffixIcon: const Icon(Icons.access_time, size: 18, color: AppColors.textSecondary),
                    ),
                    child: Text(
                      state.value == null ? 'Select time' : Fmt.hm(state.value!.hour, state.value!.minute),
                      style: TextStyle(color: state.value == null ? AppColors.textSecondary : AppColors.textPrimary, fontSize: 14),
                    ),
                  ),
                ),
              ],
            );
          },
        );
}

class SearchField extends StatefulWidget {
  const SearchField({super.key, required this.onChanged, this.hint = 'Search'});
  final ValueChanged<String> onChanged;
  final String hint;

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: (v) {
        setState(() {});
        widget.onChanged(v);
      },
      decoration: InputDecoration(
        hintText: widget.hint,
        prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textSecondary),
        suffixIcon: _controller.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () {
                  _controller.clear();
                  setState(() {});
                  widget.onChanged('');
                },
              ),
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      ),
    );
  }
}

/// Horizontal single-select chip filter row.
class AppFilterChips<T> extends StatelessWidget {
  const AppFilterChips({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
    this.labelOf,
  });

  final List<T> options;
  final T selected;
  final ValueChanged<T> onSelected;
  final String Function(T)? labelOf;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final o in options)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(labelOf != null ? labelOf!(o) : o.toString()),
                selected: o == selected,
                showCheckmark: false,
                selectedColor: AppColors.navy,
                backgroundColor: Colors.white,
                side: BorderSide(color: o == selected ? AppColors.navy : AppColors.border),
                labelStyle: TextStyle(
                  color: o == selected ? Colors.white : AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                onSelected: (_) => onSelected(o),
              ),
            ),
        ],
      ),
    );
  }
}
