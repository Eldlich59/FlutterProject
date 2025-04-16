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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Theo dõi sức khỏe'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Tất cả'),
            Tab(text: 'BMI'),
            Tab(text: 'Nhịp tim'),
            Tab(text: 'Huyết áp'),
            Tab(text: 'SpO2'),
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
                        : Column(
                          children: [
                            if (_selectedMetricType != 'all')
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: SizedBox(
                                  height: 200,
                                  child: _buildChart(),
                                ),
                              ),
                            Expanded(
                              child: ListView.builder(
                                padding: const EdgeInsets.all(16),
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
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddMetricDialog,
        tooltip: 'Thêm chỉ số mới',
        child: const Icon(Icons.add),
      ),
    );
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
                Text(
                  DateFormat('dd/MM/yyyy HH:mm').format(metric.timestamp),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _deleteMetric(metric),
                  iconSize: 20,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const Divider(),
            if (metric.bmi != null)
              _buildMetricItem(
                'BMI',
                metric.bmi!.toStringAsFixed(1),
                Icons.monitor_weight,
              ),
            if (metric.heartRate != null)
              _buildMetricItem(
                'Nhịp tim',
                '${metric.heartRate} bpm',
                Icons.favorite,
              ),
            if (metric.bloodPressure != null)
              _buildMetricItem(
                'Huyết áp',
                metric.bloodPressure.toString(),
                Icons.favorite_border,
              ),
            if (metric.spo2 != null)
              _buildMetricItem('SpO2', '${metric.spo2}%', Icons.air),
            if (metric.temperature != null)
              _buildMetricItem(
                'Nhiệt độ',
                '${metric.temperature}°C',
                Icons.thermostat,
              ),
            if (metric.respiratoryRate != null)
              _buildMetricItem(
                'Nhịp thở',
                '${metric.respiratoryRate} nhịp/phút',
                Icons.air,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: Theme.of(context).primaryColor),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(fontSize: 14)),
            ],
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ],
      ),
    );
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
              color: Colors.blue.withOpacity(0.2),
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
        minY: 90, // SpO2 típicamente no baja de 90%
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
        double? weight, height, temperature, bloodSugar;
        int? heartRate, spo2, respiratoryRate;
        int systolic = 120, diastolic = 80;

        return AlertDialog(
          title: const Text('Thêm chỉ số sức khỏe'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Cân nặng (kg)'),
                  onChanged: (value) => weight = double.tryParse(value),
                ),
                TextField(
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Chiều cao (cm)',
                  ),
                  onChanged: (value) => height = double.tryParse(value),
                ),
                TextField(
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Nhịp tim (bpm)',
                  ),
                  onChanged: (value) => heartRate = int.tryParse(value),
                ),
                TextField(
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'SpO2 (%)'),
                  onChanged: (value) => spo2 = int.tryParse(value),
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Huyết áp tâm thu',
                        ),
                        onChanged:
                            (value) => systolic = int.tryParse(value) ?? 120,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Huyết áp tâm trương',
                        ),
                        onChanged:
                            (value) => diastolic = int.tryParse(value) ?? 80,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                final userId = supabase.auth.currentUser?.id;
                if (userId != null) {
                  try {
                    final bmi =
                        (height != null && weight != null && height! > 0)
                            ? weight! / ((height! / 100) * (height! / 100))
                            : null;

                    final newMetric = {
                      'patient_id': userId,
                      'timestamp': DateTime.now().toIso8601String(),
                      'weight': weight,
                      'height': height,
                      'bmi': bmi,
                      'heart_rate': heartRate,
                      'blood_pressure':
                          heartRate != null
                              ? {'systolic': systolic, 'diastolic': diastolic}
                              : null,
                      'spo2': spo2,
                      'temperature': temperature,
                      'respiratory_rate': respiratoryRate,
                      'blood_sugar': bloodSugar,
                    };

                    final response =
                        await supabase
                            .from('health_metrics')
                            .insert(newMetric)
                            .select();

                    if (response.isNotEmpty) {
                      final newHealthMetric = HealthMetrics.fromJson(
                        response[0],
                      );
                      setState(() {
                        _metrics.insert(0, newHealthMetric);
                      });
                    }

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đã thêm chỉ số sức khỏe mới'),
                      ),
                    );
                  } catch (e) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Lỗi khi thêm chỉ số: $e')),
                    );
                  }
                }
              },
              child: const Text('Lưu'),
            ),
          ],
        );
      },
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

        setState(() {
          _metrics.removeWhere((m) => m.id == metric.id);
        });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đã xóa chỉ số sức khỏe')));
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi khi xóa: $e')));
      }
    }
  }
}
