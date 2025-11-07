import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../config/app_colors.dart';
import '../../utils/animations.dart';

/// Enhanced Earnings Chart Widget for Drivers
/// Shows beautiful visualizations of earnings data
class EarningsChartWidget extends StatefulWidget {
  final List<EarningsData> data;
  final String period; // 'day', 'week', 'month'
  final double totalEarnings;

  const EarningsChartWidget({
    super.key,
    required this.data,
    required this.period,
    required this.totalEarnings,
  });

  @override
  State<EarningsChartWidget> createState() => _EarningsChartWidgetState();
}

class _EarningsChartWidgetState extends State<EarningsChartWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int touchedIndex = -1;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Stats Cards Row
        _buildStatsCards(),
        const SizedBox(height: 24),

        // Chart
        _buildChart(),
        const SizedBox(height: 20),

        // Legend
        _buildLegend(),
      ],
    );
  }

  Widget _buildStatsCards() {
    final avgEarnings = widget.data.isEmpty
        ? 0.0
        : widget.totalEarnings / widget.data.length;
    final maxEarning = widget.data.isEmpty
        ? 0.0
        : widget.data.map((e) => e.amount).reduce((a, b) => a > b ? a : b);
    final deliveryCount = widget.data.fold<int>(
      0,
      (sum, item) => sum + item.deliveryCount,
    );

    return Row(
      children: [
        Expanded(
          child: AnimatedListItem(
            index: 0,
            child: _buildStatCard(
              'Average',
              '\$${avgEarnings.toStringAsFixed(2)}',
              Icons.trending_up,
              AppColors.success,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AnimatedListItem(
            index: 1,
            child: _buildStatCard(
              'Highest',
              '\$${maxEarning.toStringAsFixed(2)}',
              Icons.star,
              AppColors.warning,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AnimatedListItem(
            index: 2,
            child: _buildStatCard(
              'Deliveries',
              deliveryCount.toString(),
              Icons.local_shipping,
              AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 18,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart() {
    if (widget.data.isEmpty) {
      return _buildEmptyState();
    }

    return Container(
      height: 250,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: _getMaxY() * 1.2,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (group) => AppColors.primary,
                  tooltipRoundedRadius: 8,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final data = widget.data[groupIndex];
                    return BarTooltipItem(
                      '${_formatDate(data.date)}\n',
                      const TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      children: [
                        TextSpan(
                          text: '\$${data.amount.toStringAsFixed(2)}\n',
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(
                          text: '${data.deliveryCount} deliveries',
                          style: TextStyle(
                            color: AppColors.white.withOpacity(0.8),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                touchCallback: (FlTouchEvent event, barTouchResponse) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        barTouchResponse == null ||
                        barTouchResponse.spot == null) {
                      touchedIndex = -1;
                      return;
                    }
                    touchedIndex = barTouchResponse.spot!.touchedBarGroupIndex;
                  });
                },
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() >= widget.data.length) {
                        return const SizedBox();
                      }
                      final data = widget.data[value.toInt()];
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          _formatDateShort(data.date),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    },
                    reservedSize: 30,
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        '\$${value.toInt()}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: _getMaxY() / 4,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: AppColors.grey200,
                    strokeWidth: 1,
                  );
                },
              ),
              borderData: FlBorderData(show: false),
              barGroups: _buildBarGroups(),
            ),
          );
        },
      ),
    );
  }

  List<BarChartGroupData> _buildBarGroups() {
    return widget.data.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      final isTouched = index == touchedIndex;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: data.amount * _animation.value,
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: isTouched
                  ? [AppColors.secondary, AppColors.secondaryDark]
                  : [AppColors.primary, AppColors.primaryDark],
            ),
            width: isTouched ? 20 : 16,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(8),
            ),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: _getMaxY() * 1.2,
              color: AppColors.grey100,
            ),
          ),
        ],
      );
    }).toList();
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildLegendItem('This Period', AppColors.primary),
          const SizedBox(width: 24),
          _buildLegendItem('Selected', AppColors.secondary),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 250,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bar_chart_rounded,
            size: 64,
            color: AppColors.grey300,
          ),
          const SizedBox(height: 16),
          Text(
            'No earnings data yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Complete deliveries to see your earnings',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  double _getMaxY() {
    if (widget.data.isEmpty) return 100;
    return widget.data
        .map((e) => e.amount)
        .reduce((a, b) => a > b ? a : b);
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  String _formatDateShort(DateTime date) {
    switch (widget.period) {
      case 'day':
        return DateFormat('ha').format(date); // 2PM, 3PM
      case 'week':
        return DateFormat('E').format(date); // Mon, Tue
      case 'month':
        return DateFormat('d').format(date); // 1, 2, 3
      default:
        return DateFormat('MMM d').format(date);
    }
  }
}

/// Data model for earnings chart
class EarningsData {
  final DateTime date;
  final double amount;
  final int deliveryCount;

  EarningsData({
    required this.date,
    required this.amount,
    required this.deliveryCount,
  });
}
