class DocumentRecord {
  final String id;
  final String name;
  final String type;
  final String status;
  final String url;

  DocumentRecord({
    required this.id,
    required this.name,
    required this.type,
    required this.status,
    required this.url,
  });

  factory DocumentRecord.fromMap(Map<String, dynamic> data) {
    return DocumentRecord(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      type: data['type'] ?? '',
      status: data['status'] ?? 'empty',
      url: data['url'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'status': status,
      'url': url,
    };
  }
}

class TeacherRecord {
  final String id;
  final String username;
  final String email;
  final String fullName;
  final String role;
  final String icNumber;
  final String gender;
  final String dob;
  final String address;
  final String phoneNumber;
  final String maritalStatus;
  final String emergencyContactName;
  final String emergencyContactNumber;
  final int currentScore;
  final int yearlyKpi;
  final String status;
  final Map<String, DocumentRecord> documents;

  TeacherRecord({
    required this.id,
    required this.username,
    required this.email,
    required this.fullName,
    required this.role,
    required this.icNumber,
    required this.gender,
    required this.dob,
    required this.address,
    required this.phoneNumber,
    required this.maritalStatus,
    required this.emergencyContactName,
    required this.emergencyContactNumber,
    required this.currentScore,
    required this.yearlyKpi,
    required this.status,
    required this.documents,
  });

  int get completionProgress {
    int score = 0;
    if (fullName.isNotEmpty) score++;
    if (icNumber.isNotEmpty) score++;
    if (gender.isNotEmpty) score++;
    if (dob.isNotEmpty) score++;
    if (address.isNotEmpty) score++;
    if (phoneNumber.isNotEmpty) score++;
    if (email.isNotEmpty) score++;
    if (maritalStatus.isNotEmpty) score++;
    if (emergencyContactName.isNotEmpty) score++;
    if (emergencyContactNumber.isNotEmpty) score++;
    
    if (documents['myKad']?.status != 'empty') score++;
    if (documents['passportPhoto']?.status != 'empty') score++;
    if (documents['resume']?.status != 'empty') score++;
    if (documents['academicCertificates']?.status != 'empty') score++;
    if (documents['medicalReport']?.status != 'empty') score++;
    if (documents['bankStatement']?.status != 'empty') score++;

    return ((score / 16) * 100).round();
  }

  factory TeacherRecord.fromMap(String id, Map<String, dynamic> data) {
    Map<String, DocumentRecord> docs = {};
    if (data['documents'] != null) {
      final docMap = data['documents'] as Map<String, dynamic>;
      docMap.forEach((key, value) {
        docs[key] = DocumentRecord.fromMap(value as Map<String, dynamic>);
      });
    }

    return TeacherRecord(
      id: id,
      username: data['username'] ?? '',
      email: data['email'] ?? '',
      fullName: data['fullName'] ?? '',
      role: data['role'] ?? 'teacher',
      icNumber: data['icNumber'] ?? '',
      gender: data['gender'] ?? '',
      dob: data['dob'] ?? '',
      address: data['address'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      maritalStatus: data['maritalStatus'] ?? '',
      emergencyContactName: data['emergencyContactName'] ?? '',
      emergencyContactNumber: data['emergencyContactNumber'] ?? '',
      currentScore: data['currentScore']?.toInt() ?? 0,
      yearlyKpi: data['yearlyKpi']?.toInt() ?? 0,
      status: data['status'] ?? 'active',
      documents: docs,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'email': email,
      'fullName': fullName,
      'role': role,
      'icNumber': icNumber,
      'gender': gender,
      'dob': dob,
      'address': address,
      'phoneNumber': phoneNumber,
      'maritalStatus': maritalStatus,
      'emergencyContactName': emergencyContactName,
      'emergencyContactNumber': emergencyContactNumber,
      'currentScore': currentScore,
      'yearlyKpi': yearlyKpi,
      'status': status,
      'documents': documents.map((key, value) => MapEntry(key, value.toMap())),
    };
  }
}
