class TestResultItem {
  final String name;
  final String value;
  final String referenceRange;
  final String status;

  TestResultItem({
    required this.name,
    required this.value,
    required this.referenceRange,
    required this.status,
  });

  factory TestResultItem.fromJson(Map<String, dynamic> json) {
    return TestResultItem(
      name: json['name'],
      value: json['value'],
      referenceRange: json['reference_range'],
      status: json['status'],
    );
  }
}

class TestResult {
  final String id;
  final String patientId;
  final String testName;
  final String laboratoryName;
  final DateTime testDate;
  final String doctorName;
  final String status;
  final List<TestResultItem> results;
  final String? notes;
  final List<String>? imageUrls;

  TestResult({
    required this.id,
    required this.patientId,
    required this.testName,
    required this.laboratoryName,
    required this.testDate,
    required this.doctorName,
    required this.status,
    required this.results,
    this.notes,
    this.imageUrls,
  });

  factory TestResult.fromJson(Map<String, dynamic> json) {
    return TestResult(
      id: json['id'],
      patientId: json['patient_id'],
      testName: json['test_name'],
      laboratoryName: json['laboratory_name'],
      testDate: DateTime.parse(json['test_date']),
      doctorName: json['doctor_name'],
      status: json['status'],
      results:
          (json['results'] as List)
              .map((item) => TestResultItem.fromJson(item))
              .toList(),
      notes: json['notes'],
      imageUrls:
          json['image_urls'] != null
              ? List<String>.from(json['image_urls'])
              : null,
    );
  }
}
