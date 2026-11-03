import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const Color _kBlue = Color(0xFF1A73E8);
const Color _kSlate = Color(0xFF64748B);
const Color _kBorder = Color(0xFFCBD5E1);

class DropdownItemOption<T> {
  final T? value;
  final String label;

  const DropdownItemOption({
    required this.value,
    required this.label,
  });
}

/// A premium, compact dropdown built with [DropdownButton2]
/// featuring a fixed menu height (maxHeight: 260), optional in-menu search,
/// and exact match to the PropCare design system.
class CustomDropdownButton2<T> extends StatefulWidget {
  final String? label;
  final T? selectedValue;
  final List<DropdownItemOption<T>> options;
  final ValueChanged<T?> onSelect;
  final bool enableSearch;
  final String searchHint;
  final double maxHeight;
  final double buttonHeight;
  final String? placeholder;

  const CustomDropdownButton2({
    super.key,
    this.label,
    required this.selectedValue,
    required this.options,
    required this.onSelect,
    this.enableSearch = false,
    this.searchHint = 'Search name or role...',
    this.maxHeight = 260.0,
    this.buttonHeight = 38.0,
    this.placeholder,
  });

  @override
  State<CustomDropdownButton2<T>> createState() => _CustomDropdownButton2State<T>();
}

class _CustomDropdownButton2State<T> extends State<CustomDropdownButton2<T>> {
  final TextEditingController _searchController = TextEditingController();
  bool _isOpen = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedIdx = widget.options.indexWhere(
      (opt) => opt.value == widget.selectedValue,
    );
    final activeIdx = selectedIdx >= 0 ? selectedIdx : 0;
    final isFiltered = widget.selectedValue != null;
    final currentLabel = selectedIdx >= 0
        ? widget.options[selectedIdx].label
        : (widget.placeholder ?? (widget.options.isNotEmpty ? widget.options[0].label : ''));

    Widget dropdownWidget = DropdownButtonHideUnderline(
      child: DropdownButton2<int>(
        isExpanded: true,
        value: widget.options.isNotEmpty ? activeIdx : null,
        onChanged: (int? newIndex) {
          if (newIndex != null && newIndex >= 0 && newIndex < widget.options.length) {
            widget.onSelect(widget.options[newIndex].value);
          }
        },
        onMenuStateChange: (isOpen) {
          setState(() {
            _isOpen = isOpen;
          });
          if (!isOpen) {
            _searchController.clear();
          }
        },
        items: widget.options.asMap().entries.map((entry) {
          final idx = entry.key;
          final option = entry.value;
          final isSelected = idx == selectedIdx;

          return DropdownMenuItem<int>(
            value: idx,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    option.label,
                    style: GoogleFonts.outfit(
                      fontSize: 12.5,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                      color: isSelected ? _kBlue : const Color(0xFF0F172A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isSelected)
                  const Icon(
                    Icons.check_rounded,
                    size: 16,
                    color: _kBlue,
                  ),
              ],
            ),
          );
        }).toList(),
        customButton: Container(
          height: widget.buttonHeight,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _isOpen
                  ? _kBlue
                  : (isFiltered ? _kBlue : _kBorder),
              width: (_isOpen || isFiltered) ? 1.3 : 1.0,
            ),
            color: isFiltered ? const Color(0xFFEFF6FF) : Colors.white,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  currentLabel,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: isFiltered ? FontWeight.w600 : FontWeight.w500,
                    color: isFiltered ? _kBlue : const Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                _isOpen
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: (_isOpen || isFiltered) ? _kBlue : _kSlate,
              ),
            ],
          ),
        ),
        dropdownStyleData: DropdownStyleData(
          maxHeight: widget.maxHeight,
          elevation: 6,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          offset: const Offset(0, -2),
          scrollbarTheme: ScrollbarThemeData(
            radius: const Radius.circular(4),
            thickness: WidgetStateProperty.all(4),
            thumbColor: WidgetStateProperty.all(const Color(0xFFCBD5E1)),
          ),
        ),
        menuItemStyleData: const MenuItemStyleData(
          height: 38,
          padding: EdgeInsets.symmetric(horizontal: 12),
        ),
        dropdownSearchData: widget.enableSearch
            ? DropdownSearchData(
                searchController: _searchController,
                searchInnerWidgetHeight: 46,
                searchInnerWidget: Container(
                  height: 46,
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                  child: TextFormField(
                    expands: true,
                    maxLines: null,
                    controller: _searchController,
                    style: GoogleFonts.outfit(fontSize: 12.5),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      hintText: widget.searchHint,
                      hintStyle: GoogleFonts.outfit(
                        fontSize: 12,
                        color: const Color(0xFF94A3B8),
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        size: 16,
                        color: Color(0xFF64748B),
                      ),
                      prefixIconConstraints: const BoxConstraints(
                        minWidth: 28,
                        minHeight: 28,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: _kBlue,
                          width: 1.2,
                        ),
                      ),
                    ),
                  ),
                ),
                searchMatchFn: (item, searchValue) {
                  final idx = item.value;
                  if (idx == null || idx < 0 || idx >= widget.options.length) {
                    return false;
                  }
                  final label = widget.options[idx].label;
                  return label.toLowerCase().contains(searchValue.toLowerCase());
                },
              )
            : null,
      ),
    );

    if (widget.label == null) {
      return dropdownWidget;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.label!,
          style: GoogleFonts.outfit(
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
            color: _kSlate,
          ),
        ),
        const SizedBox(height: 4),
        dropdownWidget,
      ],
    );
  }
}

