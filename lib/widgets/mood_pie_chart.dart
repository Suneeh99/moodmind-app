import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class MoodPieChart extends StatefulWidget {
  final Map<String, double> data;

  const MoodPieChart({Key? key, required this.data}) : super(key: key);

  @override
  State<MoodPieChart> createState() => _MoodPieChartState();
}

class _MoodPieChartState extends State<MoodPieChart> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) {
      return const Center(
        child: Text(
          'No mood data available',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return PieChart(
      PieChartData(
        pieTouchData: PieTouchData(
          touchCallback: (FlTouchEvent event, pieTouchResponse) {
            setState(() {
              if (!event.isInterestedForInteractions ||
                  pieTouchResponse == null ||
                  pieTouchResponse.touchedSection == null) {
                touchedIndex = -1;
                return;
              }
              touchedIndex =
                  pieTouchResponse.touchedSection!.touchedSectionIndex;
            });
          },
        ),
        borderData: FlBorderData(show: false),
        sectionsSpace: 2,
        centerSpaceRadius: 60,
        sections: _buildPieChartSections(),
      ),
    );
  }

  List<PieChartSectionData> _buildPieChartSections() {
    final colors = {
      'Joy': const Color(0xFFFFD700), // Gold
      'Sadness': const Color(0xFF87CEEB), // Sky Blue
      'Anger': const Color(0xFFFF6B6B), // Red
      'Fear': const Color(0xFFFF8C42), // Orange
      'Neutral': const Color(0xFF98FB98), // Light Green
    };

    final List<PieChartSectionData> sections = [];
    int index = 0;

    // Sort by percentage for better visualization
    final sortedEntries = widget.data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    for (final entry in sortedEntries) {
      if (entry.value > 0) {
        // Only show emotions with actual percentages
        final isTouched = index == touchedIndex;
        final fontSize = isTouched ? 18.0 : 16.0;
        final radius = isTouched ? 80.0 : 70.0;
        final percentage = entry.value;

        sections.add(
          PieChartSectionData(
            color: colors[entry.key] ?? Colors.grey,
            value: percentage,
            title: '${percentage.toStringAsFixed(1)}%',
            radius: radius,
            titleStyle: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: const [
                Shadow(
                  color: Colors.black26,
                  offset: Offset(1, 1),
                  blurRadius: 2,
                ),
              ],
            ),
            badgeWidget: isTouched
                ? Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: colors[entry.key]?.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      entry.key,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : null,
            badgePositionPercentageOffset: 1.3,
          ),
        );
        index++;
      }
    }

    return sections;
  }
}
