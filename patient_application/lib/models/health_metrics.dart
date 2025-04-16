import 'package:intl/intl.dart';

class HealthMetrics {
  final String id;
  final String patientId;
  final DateTime timestamp;
  final double? height; // cm
  final double? weight; // kg
  final double? bmi;
  final int? heartRate; // nhịp/phút
  final BloodPressure? bloodPressure;
  final double? bloodSugar; // mmol/L
  final int? spo2; // %
  final SleepData? sleepData;
  final double? temperature; // °C
  final int? respiratoryRate; // nhịp/phút

  HealthMetrics({
    required this.id,
    required this.patientId,
    required this.timestamp,
    this.height,
    this.weight,
    this.bmi,
    this.heartRate,
    this.bloodPressure,
    this.bloodSugar,
    this.spo2,
    this.sleepData,
    this.temperature,
    this.respiratoryRate,
  });

  // Tính BMI nếu có chiều cao và cân nặng
  double? calculateBMI() {
    if (height != null && weight != null && height! > 0) {
      return weight! / ((height! / 100) * (height! / 100));
    }
    return null;
  }

  // Định dạng thời gian đo
  String get formattedTimestamp {
    return DateFormat('dd/MM/yyyy HH:mm').format(timestamp);
  }

  // Định dạng ngày đo
  String get formattedDate {
    return DateFormat('dd/MM/yyyy').format(timestamp);
  }

  // Factory constructor từ JSON
  factory HealthMetrics.fromJson(Map<String, dynamic> json) {
    return HealthMetrics(
      id: json['id'],
      patientId: json['patient_id'],
      timestamp: DateTime.parse(json['timestamp']),
      height: json['height']?.toDouble(),
      weight: json['weight']?.toDouble(),
      bmi: json['bmi']?.toDouble(),
      heartRate: json['heart_rate'],
      bloodPressure:
          json['blood_pressure'] != null
              ? BloodPressure.fromJson(json['blood_pressure'])
              : null,
      bloodSugar: json['blood_sugar']?.toDouble(),
      spo2: json['spo2'],
      sleepData:
          json['sleep_data'] != null
              ? SleepData.fromJson(json['sleep_data'])
              : null,
      temperature: json['temperature']?.toDouble(),
      respiratoryRate: json['respiratory_rate'],
    );
  }

  // Chuyển đổi thành JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patient_id': patientId,
      'timestamp': timestamp.toIso8601String(),
      'height': height,
      'weight': weight,
      'bmi': bmi,
      'heart_rate': heartRate,
      'blood_pressure': bloodPressure?.toJson(),
      'blood_sugar': bloodSugar,
      'spo2': spo2,
      'sleep_data': sleepData?.toJson(),
      'temperature': temperature,
      'respiratory_rate': respiratoryRate,
    };
  }
}

class BloodPressure {
  final int systolic; // mmHg
  final int diastolic; // mmHg

  BloodPressure({required this.systolic, required this.diastolic});

  // Phân loại huyết áp
  String get classification {
    if (systolic < 120 && diastolic < 80) {
      return 'Bình thường';
    } else if ((systolic >= 120 && systolic <= 129) && diastolic < 80) {
      return 'Huyết áp tăng';
    } else if ((systolic >= 130 && systolic <= 139) ||
        (diastolic >= 80 && diastolic <= 89)) {
      return 'Tăng huyết áp cấp 1';
    } else if (systolic >= 140 || diastolic >= 90) {
      return 'Tăng huyết áp cấp 2';
    } else if (systolic > 180 || diastolic > 120) {
      return 'Khủng hoảng tăng huyết áp';
    }
    return 'Không xác định';
  }

  // Màu sắc tương ứng với phân loại
  int get colorCode {
    if (systolic < 120 && diastolic < 80) {
      return 0xFF4CAF50; // Xanh lá - bình thường
    } else if ((systolic >= 120 && systolic <= 129) && diastolic < 80) {
      return 0xFFFFC107; // Vàng - huyết áp tăng
    } else if ((systolic >= 130 && systolic <= 139) ||
        (diastolic >= 80 && diastolic <= 89)) {
      return 0xFFFF9800; // Cam - tăng huyết áp cấp 1
    } else if (systolic >= 140 || diastolic >= 90) {
      return 0xFFF44336; // Đỏ - tăng huyết áp cấp 2
    } else if (systolic > 180 || diastolic > 120) {
      return 0xFF9C27B0; // Tím - khủng hoảng tăng huyết áp
    }
    return 0xFF9E9E9E; // Xám - không xác định
  }

  // Factory constructor từ JSON
  factory BloodPressure.fromJson(Map<String, dynamic> json) {
    return BloodPressure(
      systolic: json['systolic'],
      diastolic: json['diastolic'],
    );
  }

  // Chuyển đổi thành JSON
  Map<String, dynamic> toJson() {
    return {'systolic': systolic, 'diastolic': diastolic};
  }

  @override
  String toString() {
    return '$systolic/$diastolic mmHg';
  }
}

class SleepData {
  final DateTime startTime;
  final DateTime endTime;
  final int deepSleepMinutes;
  final int lightSleepMinutes;
  final int remSleepMinutes;
  final int awakeSleepMinutes;

  SleepData({
    required this.startTime,
    required this.endTime,
    required this.deepSleepMinutes,
    required this.lightSleepMinutes,
    required this.remSleepMinutes,
    required this.awakeSleepMinutes,
  });

  // Tổng thời gian ngủ (phút)
  int get totalSleepMinutes {
    return deepSleepMinutes + lightSleepMinutes + remSleepMinutes;
  }

  // Tổng thời gian ngủ (giờ)
  double get totalSleepHours {
    return totalSleepMinutes / 60;
  }

  // Hiệu quả ngủ (%)
  double get sleepEfficiency {
    final totalMinutes = endTime.difference(startTime).inMinutes;
    if (totalMinutes == 0) return 0;
    return (totalSleepMinutes / totalMinutes) * 100;
  }

  // Factory constructor từ JSON
  factory SleepData.fromJson(Map<String, dynamic> json) {
    return SleepData(
      startTime: DateTime.parse(json['start_time']),
      endTime: DateTime.parse(json['end_time']),
      deepSleepMinutes: json['deep_sleep_minutes'],
      lightSleepMinutes: json['light_sleep_minutes'],
      remSleepMinutes: json['rem_sleep_minutes'],
      awakeSleepMinutes: json['awake_sleep_minutes'],
    );
  }

  // Chuy���n đổi thành JSON
  Map<String, dynamic> toJson() {
    return {
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'deep_sleep_minutes': deepSleepMinutes,
      'light_sleep_minutes': lightSleepMinutes,
      'rem_sleep_minutes': remSleepMinutes,
      'awake_sleep_minutes': awakeSleepMinutes,
    };
  }

  // Định dạng thời gian ngủ
  String get formattedSleepDuration {
    final hours = (totalSleepMinutes / 60).floor();
    final minutes = totalSleepMinutes % 60;
    return '$hours giờ $minutes phút';
  }

  // Định dạng thời gian bắt đầu và kết thúc
  String get formattedTimeRange {
    final startFormat = DateFormat('HH:mm');
    final endFormat = DateFormat('HH:mm');
    return '${startFormat.format(startTime)} - ${endFormat.format(endTime)}';
  }
}
