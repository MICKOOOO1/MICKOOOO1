import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'scan_history.dart';
import 'package:intl/intl.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  static const Color _purple = Color(0xFF9B5CFF);

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  List<ScanResult> _history = [];
  Map<String, int> _beanTypeCounts = {};
  double _averageConfidence = 0.0;
  int _totalScans = 0;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    final history = await ScanHistory.getHistory();
    final beanTypeCounts = <String, int>{};
    double totalConfidence = 0.0;

    for (final scan in history) {
      beanTypeCounts[scan.beanType] = (beanTypeCounts[scan.beanType] ?? 0) + 1;
      totalConfidence += scan.confidence;
    }

    setState(() {
      _history = history;
      _beanTypeCounts = beanTypeCounts;
      _averageConfidence = history.isNotEmpty ? totalConfidence / history.length : 0.0;
      _totalScans = history.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final purple = AnalyticsPage._purple;
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    final overlay = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    );
    SystemChrome.setSystemUIOverlayStyle(overlay);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: overlay,
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              // Purple header
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(
                  18,
                  MediaQuery.of(context).padding.top + 20,
                  18,
                  20,
                ),
                decoration: BoxDecoration(
                  color: purple.withOpacity(0.95),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(28),
                    bottomRight: Radius.circular(28),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Analytics',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'View your scanning statistics',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 20,
                  ),
                  child: Column(
                    children: [
                      // Summary Cards
                      Row(
                        children: [
                          Expanded(
                            child: _buildSummaryCard(
                              'Total Scans',
                              _totalScans.toString(),
                              Icons.scanner,
                              purple,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildSummaryCard(
                              'Avg Confidence',
                              '${(_averageConfidence * 100).toStringAsFixed(1)}%',
                              Icons.trending_up,
                              purple,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Bean Type Distribution
                      _buildBeanTypeChart(purple),
                      const SizedBox(height: 20),

                      // Confidence Distribution
                      _buildConfidenceDistribution(purple),
                      const SizedBox(height: 20),

                      // Recent Activity
                      _buildRecentActivity(purple),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBeanTypeChart(Color purple) {
    if (_beanTypeCounts.isEmpty) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Bean Type Distribution',
              style: TextStyle(
                color: purple,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No data available',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    final sortedEntries = _beanTypeCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxCount = sortedEntries.first.value;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bean Type Distribution',
            style: TextStyle(
              color: purple,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...sortedEntries.map((entry) {
            final percentage = (entry.value / _totalScans * 100).toStringAsFixed(1);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entry.key,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${entry.value} ($percentage%)',
                        style: TextStyle(
                          color: purple,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: entry.value / maxCount,
                      child: Container(
                        decoration: BoxDecoration(
                          color: purple,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildConfidenceDistribution(Color purple) {
    final ranges = [
      {'range': '90-100%', 'count': 0, 'color': Colors.green},
      {'range': '80-89%', 'count': 0, 'color': Colors.blue},
      {'range': '70-79%', 'count': 0, 'color': Colors.orange},
      {'range': '60-69%', 'count': 0, 'color': Colors.red},
      {'range': '<60%', 'count': 0, 'color': Colors.grey},
    ];

    for (final scan in _history) {
      final confidencePercent = scan.confidence * 100;
      if (confidencePercent >= 90) ranges[0]['count'] = (ranges[0]['count'] as int) + 1;
      else if (confidencePercent >= 80) ranges[1]['count'] = (ranges[1]['count'] as int) + 1;
      else if (confidencePercent >= 70) ranges[2]['count'] = (ranges[2]['count'] as int) + 1;
      else if (confidencePercent >= 60) ranges[3]['count'] = (ranges[3]['count'] as int) + 1;
      else ranges[4]['count'] = (ranges[4]['count'] as int) + 1;
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Confidence Distribution',
            style: TextStyle(
              color: purple,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...ranges.map((range) {
            final count = range['count'] as int;
            if (count == 0) return const SizedBox.shrink();
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: range['color'] as Color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    range['range'] as String,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    count.toString(),
                    style: TextStyle(
                      color: purple,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRecentActivity(Color purple) {
    final recentScans = _history.take(5).toList();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Activity',
            style: TextStyle(
              color: purple,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (recentScans.isEmpty)
            Text(
              'No recent activity',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 14,
              ),
            )
          else
            ...recentScans.map((scan) {
              final formattedTime = DateFormat('MMM dd, HH:mm').format(scan.timestamp);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.history,
                      color: Colors.grey.shade400,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${scan.beanType} - ${formattedTime}',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Text(
                      '${(scan.confidence * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: purple,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
