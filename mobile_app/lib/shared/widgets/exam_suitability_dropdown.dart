import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Dropdown widget for filtering exams by suitability
class ExamSuitabilityDropdown extends StatefulWidget {
  final String selectedValue;
  final ValueChanged<String> onChanged;
  final bool isAppBarStyle;
  final List<String> options;

  const ExamSuitabilityDropdown({
    super.key,
    required this.selectedValue,
    required this.onChanged,
    this.isAppBarStyle = false,
    this.options = const [
      'All',
      'MTS',
      'Postman',
      'Postal Assistant',
      'Inspector',
      'Group B',
      'Others',
    ],
  });

  @override
  State<ExamSuitabilityDropdown> createState() =>
      _ExamSuitabilityDropdownState();
}

class _ExamSuitabilityDropdownState extends State<ExamSuitabilityDropdown> {
  @override
  Widget build(BuildContext context) {
    if (widget.isAppBarStyle) {
      return _buildAppBarDropdown();
    } else {
      return _buildRegularDropdown();
    }
  }

  Widget _buildAppBarDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: widget.selectedValue,
          onChanged: (String? newValue) {
            if (newValue != null) {
              widget.onChanged(newValue);
            }
          },
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: Colors.white.withOpacity(0.8),
            size: 18,
          ),
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
          dropdownColor: const Color(0xFF4F46E5),
          borderRadius: BorderRadius.circular(12),
          items: widget.options.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 120),
                child: Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildRegularDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: widget.selectedValue,
          onChanged: (String? newValue) {
            if (newValue != null) {
              widget.onChanged(newValue);
            }
          },
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: Colors.grey.shade600,
            size: 20,
          ),
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade800,
          ),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(12),
          isExpanded: true,
          items: widget.options.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade800,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

/// Compact dropdown for use in filters
class CompactSuitabilityDropdown extends StatelessWidget {
  final String selectedValue;
  final ValueChanged<String> onChanged;
  final List<String> options;

  const CompactSuitabilityDropdown({
    super.key,
    required this.selectedValue,
    required this.onChanged,
    this.options = const [
      'All',
      'MTS',
      'Postman',
      'PA',
      'Inspector',
      'ASP',
      'SP',
      'Group B',
    ],
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: selectedValue == 'All'
            ? Colors.grey.shade100
            : const Color(0xFF4F46E5).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selectedValue == 'All'
              ? Colors.grey.shade300
              : const Color(0xFF4F46E5).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedValue,
          onChanged: (String? newValue) {
            if (newValue != null) {
              onChanged(newValue);
            }
          },
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: selectedValue == 'All'
                ? Colors.grey.shade600
                : const Color(0xFF4F46E5),
            size: 16,
          ),
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: selectedValue == 'All'
                ? Colors.grey.shade700
                : const Color(0xFF4F46E5),
          ),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(12),
          items: options.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade800,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

/// Chip-style dropdown for horizontal scrolling
class ChipSuitabilityFilter extends StatelessWidget {
  final String selectedValue;
  final ValueChanged<String> onChanged;
  final List<String> options;

  const ChipSuitabilityFilter({
    super.key,
    required this.selectedValue,
    required this.onChanged,
    this.options = const [
      'All',
      'MTS',
      'Postman',
      'PA',
      'Inspector',
      'ASP',
      'SP',
      'Group B',
    ],
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        itemBuilder: (context, index) {
          final option = options[index];
          final isSelected = option == selectedValue;

          return Padding(
            padding: EdgeInsets.only(
              left: index == 0 ? 16 : 8,
              right: index == options.length - 1 ? 16 : 0,
            ),
            child: FilterChip(
              label: Text(
                option,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                ),
              ),
              selected: isSelected,
              onSelected: (bool selected) {
                if (selected) {
                  onChanged(option);
                }
              },
              backgroundColor: Colors.grey.shade100,
              selectedColor: const Color(0xFF4F46E5),
              checkmarkColor: Colors.white,
              side: BorderSide(
                color:
                    isSelected ? const Color(0xFF4F46E5) : Colors.grey.shade300,
                width: 1,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          );
        },
      ),
    );
  }
}
