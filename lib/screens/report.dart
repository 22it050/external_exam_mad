import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:hive/hive.dart';
import '../models/trancs.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final transactionBox = Hive.box('transactions');
    final List<Transaction> transactions =
        transactionBox.values.toList().cast<Transaction>();

    // Group expenses by date
    Map<String, double> dailyExpenses = {};
    transactions.where((txn) => !txn.isIncome).forEach((txn) {
      String dateKey = DateFormat('yyyy-MM-dd').format(txn.date);
      dailyExpenses.update(dateKey, (value) => value + txn.amount,
          ifAbsent: () => txn.amount);
    });

    // Create spots for graph based on daily expenses
    List<FlSpot> expenseSpots = [];
    List<String> dateLabels = [];
    int index = 0;

    dailyExpenses.forEach((date, amount) {
      expenseSpots.add(FlSpot(index.toDouble(), amount));
      dateLabels.add(date);
      index++;
    });

    // Calculate max expense value for Y-axis limit
    double maxExpense = dailyExpenses.isNotEmpty
        ? dailyExpenses.values.reduce((a, b) => a > b ? a : b)
        : 100;
    double interval =
        (maxExpense / 5).ceilToDouble(); // Dynamic interval for better scaling

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: LineChart(
          LineChartData(
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) {
                    int index = value.toInt();
                    if (index >= 0 && index < dateLabels.length) {
                      return Text(
                        DateFormat('MM/dd').format(
                            DateFormat('yyyy-MM-dd').parse(dateLabels[index])),
                        style: const TextStyle(fontSize: 10),
                        textAlign: TextAlign.center,
                      );
                    }
                    return const Text('');
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: interval, // Set dynamic interval for Y-axis
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) {
                    return Text('\$${value.toInt()}',
                        style: const TextStyle(fontSize: 10));
                  },
                ),
              ),
              topTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: true,
              horizontalInterval: interval,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: Colors.grey.withOpacity(0.5),
                  strokeWidth: 1,
                  dashArray: [5, 5],
                );
              },
            ),
            lineBarsData: [
              LineChartBarData(
                spots: expenseSpots, // Set expense data points
                isCurved: true,
                color: Colors.redAccent,
                barWidth: 4,
                dotData:
                    const FlDotData(show: true), // Show dots on each data point
                belowBarData: BarAreaData(
                  show: true,
                  color: Colors.redAccent
                      .withOpacity(0.2), // Light red area under the curve
                ),
              ),
            ],
            borderData: FlBorderData(
              show: true,
              border: Border.all(color: Colors.black.withOpacity(0.3)),
            ),
            minY: 0,
            maxY: maxExpense +
                (interval * 2), // Add extra space above the highest expense
          ),
        ),
      ),
    );
  }
}