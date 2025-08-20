import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../utils/app_theme.dart';

class CalendarWidget extends StatelessWidget {
  final DateTime selectedDate;
  final Map<DateTime, List<Task>> tasksMap;
  final Function(DateTime) onDateSelected;

  const CalendarWidget({
    Key? key,
    required this.selectedDate,
    required this.tasksMap,
    required this.onDateSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Month/Year header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => _changeMonth(-1),
                icon: const Icon(Icons.chevron_left),
              ),
              Text(
                _getMonthYearString(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () => _changeMonth(1),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Weekday headers
          Row(
            children: ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su']
                .map((day) => Expanded(
                      child: Center(
                        child: Text(
                          day,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          
          const SizedBox(height: 8),
          
          // Calendar grid
          _buildCalendarGrid(),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDayOfMonth = DateTime(selectedDate.year, selectedDate.month, 1);
    final lastDayOfMonth = DateTime(selectedDate.year, selectedDate.month + 1, 0);
    final firstWeekday = firstDayOfMonth.weekday;
    final daysInMonth = lastDayOfMonth.day;
    
    List<Widget> dayWidgets = [];
    
    // Empty cells for days before the first day of the month
    for (int i = 1; i < firstWeekday; i++) {
      dayWidgets.add(Container());
    }
    
    // Days of the month
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(selectedDate.year, selectedDate.month, day);
      final isSelected = date.day == selectedDate.day &&
          date.month == selectedDate.month &&
          date.year == selectedDate.year;
      final hasTasks = tasksMap[DateTime(date.year, date.month, date.day)]?.isNotEmpty ?? false;
      
      dayWidgets.add(
        GestureDetector(
          onTap: () => onDateSelected(date),
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: isSelected 
                  ? AppTheme.primaryBlue 
                  : hasTasks 
                      ? AppTheme.primaryBlue.withOpacity(0.1)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    day.toString(),
                    style: TextStyle(
                      color: isSelected 
                          ? Colors.white 
                          : Colors.black87,
                      fontWeight: isSelected || hasTasks 
                          ? FontWeight.bold 
                          : FontWeight.normal,
                    ),
                  ),
                  if (hasTasks && !isSelected)
                    Container(
                      width: 4,
                      height: 4,
                      margin: const EdgeInsets.only(top: 2),
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryBlue,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    
    // Create rows of 7 days each
    List<Widget> rows = [];
    for (int i = 0; i < dayWidgets.length; i += 7) {
      rows.add(
        SizedBox(
          height: 40,
          child: Row(
            children: dayWidgets
                .skip(i)
                .take(7)
                .map((widget) => Expanded(child: widget))
                .toList(),
          ),
        ),
      );
    }
    
    return Column(children: rows);
  }

  String _getMonthYearString() {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[selectedDate.month - 1]} ${selectedDate.year}';
  }

  void _changeMonth(int delta) {
    final newDate = DateTime(selectedDate.year, selectedDate.month + delta, 1);
    onDateSelected(newDate);
  }
}