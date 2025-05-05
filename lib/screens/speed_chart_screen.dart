// speed_chart_screen.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class SpeedChartScreen extends StatelessWidget {
  final List<Map<String, dynamic>> speedData;

  const SpeedChartScreen({super.key, required this.speedData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Historique des vitesses')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: LineChart(
          LineChartData(
            gridData: FlGridData(show: true),
            titlesData: FlTitlesData(show: true),
            borderData: FlBorderData(show: true),
            lineBarsData: [
              LineChartBarData(
                spots: speedData.asMap().entries.map((entry) {
                  final index = entry.key.toDouble();
                  final speed = (entry.value['speed'] as double);
                  return FlSpot(index, speed);
                }).toList(),
                isCurved: true,
                color: Colors.blue,
                dotData: FlDotData(show: false),
                belowBarData: BarAreaData(show: false),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
