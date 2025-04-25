import 'package:flutter/material.dart';
import 'package:patient_application/models/health_metrics.dart';
import 'package:patient_application/main.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class HealthMetricsScreen extends StatefulWidget {
  const HealthMetricsScreen({super.key});

  @override
  State<HealthMetricsScreen> createState() => _HealthMetricsScreenState();
}

class _HealthMetricsScreenState extends State<HealthMetricsScreen>
    with SingleTickerProviderStateMixin {
  List<HealthMetrics> _metrics = [];
  bool _isLoading = true;
  late TabController _tabController;
  String _selectedMetricType =
      'all'; // 'all', 'bmi', 'heart', 'blood_pressure', 'spo2'

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(_handleTabChange);
    _fetchHealthMetrics();
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      setState(() {
        switch (_tabController.index) {
          case 0:
            _selectedMetricType = 'all';
            break;
          case 1:
            _selectedMetricType = 'bmi';
            break;
          case 2:
            _selectedMetricType = 'heart';
            break;
          case 3:
            _selectedMetricType = 'blood_pressure';
            break;
          case 4:
            _selectedMetricType = 'spo2';
            break;
        }
      });
    }
  }

  Future<void> _fetchHealthMetrics() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final userId = supabase.auth.currentUser?.id;
      if (userId != null) {
        final data = await supabase
            .from('health_metrics')
            .select()
            .eq('patient_id', userId)
            .order('timestamp', ascending: false);

        setState(() {
          _metrics =
              data
                  .map<HealthMetrics>((json) => HealthMetrics.fromJson(json))
                  .toList();
        });
      }
    } catch (e) {
      debugPrint('Lỗi khi tải dữ liệu sức khỏe: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Không thể tải dữ liệu: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<HealthMetrics> get _filteredMetrics {
    if (_selectedMetricType == 'all') return _metrics;

    return _metrics.where((metric) {
      switch (_selectedMetricType) {
        case 'bmi':
          return metric.bmi != null;
        case 'heart':
          return metric.heartRate != null;
        case 'blood_pressure':
          return metric.bloodPressure != null;
        case 'spo2':
          return metric.spo2 != null;
        default:
          return true;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Theo dõi sức khỏe',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 2,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: false, // Changed from true to false to center tabs
          indicatorWeight: 3,
          indicatorSize: TabBarIndicatorSize.tab,
          labelColor: theme.primaryColor,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(
              text: 'Tất cả',
              icon: Icon(Icons.dashboard_rounded),
              iconMargin: EdgeInsets.only(bottom: 4),
            ),
            Tab(
              text: 'BMI',
              icon: Icon(Icons.monitor_weight_outlined),
              iconMargin: EdgeInsets.only(bottom: 4),
            ),
            Tab(
              text: 'Nhịp tim',
              icon: Icon(Icons.favorite_outline),
              iconMargin: EdgeInsets.only(bottom: 4),
            ),
            Tab(
              text: 'Huyết áp',
              icon: Icon(Icons.monitor_heart_outlined),
              iconMargin: EdgeInsets.only(bottom: 4),
            ),
            Tab(
              text: 'SpO2',
              icon: Icon(Icons.air_outlined),
              iconMargin: EdgeInsets.only(bottom: 4),
            ),
          ],
        ),
      ),

      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _fetchHealthMetrics,
                child:
                    _metrics.isEmpty
                        ? _buildEmptyState()
                        : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (_selectedMetricType != 'all')
                                Card(
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 16.0,
                                  ),
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Text(
                                          _getChartTitle(),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 8),
                                        SizedBox(
                                          height: 220,
                                          child: _buildChart(),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              Expanded(
                                child: ListView.builder(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8.0,
                                  ),
                                  itemCount: _filteredMetrics.length,
                                  itemBuilder: (context, index) {
                                    final metric = _filteredMetrics[index];
                                    return _buildMetricCard(metric);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
              ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddMetricDialog,
        icon: const Icon(Icons.add),
        label: const Text('Thêm chỉ số'),
        heroTag: 'healthMetricsButton',
        tooltip: 'Thêm chỉ số mới',
      ),
    );
  }

  String _getChartTitle() {
    switch (_selectedMetricType) {
      case 'bmi':
        return 'Chỉ số khối cơ thể (BMI) theo thời gian';
      case 'heart':
        return 'Nhịp tim (bpm) theo thời gian';
      case 'blood_pressure':
        return 'Huyết áp (mmHg) theo thời gian';
      case 'spo2':
        return 'Nồng độ oxy trong máu (SpO2) theo thời gian';
      default:
        return '';
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'Chưa có dữ liệu sức khỏe',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Thêm chỉ số mới để theo dõi sức khỏe của bạn',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showAddMetricDialog,
              icon: const Icon(Icons.add),
              label: const Text('Thêm chỉ số mới'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(HealthMetrics metric) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('dd/MM/yyyy').format(metric.timestamp),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('HH:mm').format(metric.timestamp),
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _deleteMetric(metric),
                      iconSize: 20,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 24),
            Wrap(
              spacing: 16,
              runSpacing: 12,
              children: [
                if (metric.bmi != null)
                  _buildMetricItemChip(
                    'BMI',
                    metric.bmi!.toStringAsFixed(1),
                    Icons.monitor_weight,
                    _getBMIColor(metric.bmi!),
                  ),
                if (metric.heartRate != null)
                  _buildMetricItemChip(
                    'Nhịp tim',
                    '${metric.heartRate} bpm',
                    Icons.favorite,
                    _getHeartRateColor(metric.heartRate!),
                  ),
                if (metric.bloodPressure != null)
                  _buildMetricItemChip(
                    'Huyết áp',
                    '${metric.bloodPressure!.systolic}/${metric.bloodPressure!.diastolic}',
                    Icons.favorite_border,
                    _getBloodPressureColor(
                      metric.bloodPressure!.systolic,
                      metric.bloodPressure!.diastolic,
                    ),
                  ),
                if (metric.spo2 != null)
                  _buildMetricItemChip(
                    'SpO2',
                    '${metric.spo2}%',
                    Icons.air,
                    _getSpO2Color(metric.spo2!),
                  ),
                if (metric.temperature != null)
                  _buildMetricItemChip(
                    'Nhiệt độ',
                    '${metric.temperature}°C',
                    Icons.thermostat,
                    _getTemperatureColor(metric.temperature!),
                  ),
                if (metric.respiratoryRate != null)
                  _buildMetricItemChip(
                    'Nhịp thở',
                    '${metric.respiratoryRate} lần/phút',
                    Icons.air,
                    Theme.of(context).primaryColor,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItemChip(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withAlpha(25), // Thay thế withOpacity(0.1)
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withAlpha(76),
        ), // Thay thế withOpacity(0.3)
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[800]),
              ),
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper functions to determine colors based on health values
  Color _getBMIColor(double bmi) {
    if (bmi < 18.5) return Colors.blue;
    if (bmi < 25) return Colors.green;
    if (bmi < 30) return Colors.orange;
    return Colors.red;
  }

  Color _getHeartRateColor(int heartRate) {
    if (heartRate < 60) return Colors.blue;
    if (heartRate <= 100) return Colors.green;
    return Colors.red;
  }

  Color _getBloodPressureColor(int systolic, int diastolic) {
    if (systolic < 120 && diastolic < 80) return Colors.green;
    if (systolic < 130 && diastolic < 80) return Colors.lightGreen;
    if (systolic < 140 && diastolic < 90) return Colors.orange;
    return Colors.red;
  }

  Color _getSpO2Color(int spo2) {
    if (spo2 >= 95) return Colors.green;
    if (spo2 >= 90) return Colors.orange;
    return Colors.red;
  }

  Color _getTemperatureColor(double temp) {
    if (temp < 36.1) return Colors.blue;
    if (temp <= 37.2) return Colors.green;
    if (temp <= 38) return Colors.orange;
    return Colors.red;
  }

  Widget _buildChart() {
    // Tùy theo loại metric được chọn, hiển thị biểu đồ tương ứng
    switch (_selectedMetricType) {
      case 'bmi':
        return _buildBMIChart();
      case 'heart':
        return _buildHeartRateChart();
      case 'blood_pressure':
        return _buildBloodPressureChart();
      case 'spo2':
        return _buildSpO2Chart();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildBMIChart() {
    // Lọc các metrics có BMI, giới hạn 10 kết quả, và đảo ngược để hiển thị theo thời gian
    final bmiData =
        _metrics
            .where((m) => m.bmi != null)
            .take(10)
            .toList()
            .reversed
            .toList();

    if (bmiData.isEmpty) return const SizedBox.shrink();

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 40),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < bmiData.length) {
                  final date = bmiData[value.toInt()].timestamp;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      '${date.day}/${date.month}',
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(bmiData.length, (index) {
              return FlSpot(index.toDouble(), bmiData[index].bmi!);
            }),
            isCurved: true,
            color: Colors.blue,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.blue.withAlpha(50), // Thay thế withOpacity(0.2)
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeartRateChart() {
    final heartData =
        _metrics
            .where((m) => m.heartRate != null)
            .take(10)
            .toList()
            .reversed
            .toList();

    if (heartData.isEmpty) return const SizedBox.shrink();

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 40),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < heartData.length) {
                  final date = heartData[value.toInt()].timestamp;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      '${date.day}/${date.month}',
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(heartData.length, (index) {
              return FlSpot(
                index.toDouble(),
                heartData[index].heartRate!.toDouble(),
              );
            }),
            isCurved: true,
            color: Colors.red,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.red.withOpacity(0.2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBloodPressureChart() {
    final bpData =
        _metrics
            .where((m) => m.bloodPressure != null)
            .take(10)
            .toList()
            .reversed
            .toList();

    if (bpData.isEmpty) return const SizedBox.shrink();

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 40),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < bpData.length) {
                  final date = bpData[value.toInt()].timestamp;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      '${date.day}/${date.month}',
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          // Systolic (tâm thu)
          LineChartBarData(
            spots: List.generate(bpData.length, (index) {
              return FlSpot(
                index.toDouble(),
                bpData[index].bloodPressure!.systolic.toDouble(),
              );
            }),
            isCurved: true,
            color: Colors.red,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: true),
          ),
          // Diastolic (tâm trương)
          LineChartBarData(
            spots: List.generate(bpData.length, (index) {
              return FlSpot(
                index.toDouble(),
                bpData[index].bloodPressure!.diastolic.toDouble(),
              );
            }),
            isCurved: true,
            color: Colors.blue,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: true),
          ),
        ],
      ),
    );
  }

  Widget _buildSpO2Chart() {
    final spo2Data =
        _metrics
            .where((m) => m.spo2 != null)
            .take(10)
            .toList()
            .reversed
            .toList();

    if (spo2Data.isEmpty) return const SizedBox.shrink();

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < spo2Data.length) {
                  final date = spo2Data[value.toInt()].timestamp;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      '${date.day}/${date.month}',
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        minY: 85, // SpO2 típicamente no baja de 90%
        maxY: 100,
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(spo2Data.length, (index) {
              return FlSpot(index.toDouble(), spo2Data[index].spo2!.toDouble());
            }),
            isCurved: true,
            color: Colors.purple,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.purple.withOpacity(0.2),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddMetricDialog() {
    showDialog(
      context: context,
      builder: (context) {
        double? weight, height, temperature;
        int? heartRate, spo2, respiratoryRate;
        int systolic = 120, diastolic = 80;
        final formKey = GlobalKey<FormState>();

        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.add_circle, color: Theme.of(context).primaryColor),
              const SizedBox(width: 8),
              const Text('Thêm chỉ số sức khỏe mới'),
            ],
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Nhập các chỉ số sức khỏe mà bạn muốn ghi lại:',
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 16),

                  // BMI Section
                  _buildSectionHeader('Cân nặng và chiều cao'),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Cân nặng (kg)',
                            prefixIcon: Icon(Icons.line_weight),
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) => weight = double.tryParse(value),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Chiều cao (cm)',
                            prefixIcon: Icon(Icons.height),
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) => height = double.tryParse(value),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Heart rate and SpO2
                  _buildSectionHeader('Nhịp tim và SpO2'),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Nhịp tim (bpm)',
                            prefixIcon: Icon(Icons.favorite),
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) => heartRate = int.tryParse(value),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'SpO2 (%)',
                            prefixIcon: Icon(Icons.air),
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) => spo2 = int.tryParse(value),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Blood pressure
                  _buildSectionHeader('Huyết áp'),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Tâm thu (mmHg)',
                            prefixIcon: Icon(Icons.arrow_upward),
                            border: OutlineInputBorder(),
                          ),
                          onChanged:
                              (value) => systolic = int.tryParse(value) ?? 120,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Tâm trương (mmHg)',
                            prefixIcon: Icon(Icons.arrow_downward),
                            border: OutlineInputBorder(),
                          ),
                          onChanged:
                              (value) => diastolic = int.tryParse(value) ?? 80,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Temperature and respiratory rate
                  _buildSectionHeader('Nhiệt độ và nhịp thở'),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Nhiệt độ (°C)',
                            prefixIcon: Icon(Icons.thermostat),
                            border: OutlineInputBorder(),
                          ),
                          onChanged:
                              (value) => temperature = double.tryParse(value),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Nhịp thở (lần/phút)',
                            prefixIcon: Icon(Icons.air_outlined),
                            border: OutlineInputBorder(),
                          ),
                          onChanged:
                              (value) => respiratoryRate = int.tryParse(value),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.cancel, color: Colors.grey),
              label: const Text('Hủy'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                final userId = supabase.auth.currentUser?.id;
                if (userId != null) {
                  try {
                    final bmi =
                        (height != null && weight != null && height! > 0)
                            ? weight! / ((height! / 100) * (height! / 100))
                            : null;

                    final bloodPressure =
                        (systolic != 0 && diastolic != 0)
                            ? {'systolic': systolic, 'diastolic': diastolic}
                            : null;

                    final newMetric = {
                      'patient_id': userId,
                      'timestamp': DateTime.now().toIso8601String(),
                      'weight': weight,
                      'height': height,
                      'bmi': bmi,
                      'heart_rate': heartRate,
                      'blood_pressure': bloodPressure,
                      'spo2': spo2,
                      'temperature': temperature,
                      'respiratory_rate': respiratoryRate,
                    };

                    final response =
                        await supabase
                            .from('health_metrics')
                            .insert(newMetric)
                            .select();

                    Navigator.pop(context);

                    if (!mounted) return;

                    if (response.isNotEmpty) {
                      final newHealthMetric = HealthMetrics.fromJson(
                        response[0],
                      );
                      setState(() {
                        _metrics.insert(0, newHealthMetric);
                      });
                    }

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đã thêm chỉ số sức khỏe mới thành công'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    Navigator.pop(context);

                    if (!mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Lỗi khi thêm chỉ số: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.save),
              label: const Text('Lưu'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  Future<void> _deleteMetric(HealthMetrics metric) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Xác nhận xóa'),
            content: const Text('Bạn có chắc chắn muốn xóa chỉ số này không?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Hủy'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Xóa'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        await supabase.from('health_metrics').delete().eq('id', metric.id);

        if (!mounted) return;

        setState(() {
          _metrics.removeWhere((m) => m.id == metric.id);
        });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đã xóa chỉ số sức khỏe')));
      } catch (e) {
        if (!mounted) return;

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi khi xóa: $e')));
      }
    }
  }
}
