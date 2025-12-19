import 'package:flutter/material.dart';

class EventsFilterBar extends StatelessWidget {
  final String selectedType;
  final Function(String) onTypeChange;

  const EventsFilterBar({
    super.key,
    required this.selectedType,
    required this.onTypeChange,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          _buildFilterChip('Все', 'all'),
          const SizedBox(width: 8),
          _buildFilterChip('Мои', 'created'),
          const SizedBox(width: 8),
          _buildFilterChip('Я иду', 'attending'),
          const SizedBox(width: 8),
          _buildFilterChip('Прошедшие', 'past'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isActive = selectedType == value;
    return ChoiceChip(
      label: Text(label),
      selected: isActive,
      onSelected: (_) => onTypeChange(value),
      selectedColor: const Color(0xFF007AFF),
      labelStyle: TextStyle(
        color: isActive ? Colors.white : Colors.black,
        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
      ),
      backgroundColor: const Color(0xFFF2F2F2),
    );
  }
}
