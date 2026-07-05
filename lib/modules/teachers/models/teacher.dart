class DocumentRecord {
  final String id;
  final String name;
  final String type;
  final String status; // 'empty', 'uploaded', 'verified', 'rejected'
  final String url;
  final String rejectionReason;
  final String uploadedAt;
  final String verifiedAt;
  final List<String> ocrWarnings;

  DocumentRecord({
    required this.id,
    required this.name,
    required this.type,
    required this.status,
    required this.url,
    this.rejectionReason = '',
    this.uploadedAt = '',
    this.verifiedAt = '',
    this.ocrWarnings = const [],
  });

  factory DocumentRecord.fromMap(Map<String, dynamic> data) {
    return DocumentRecord(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      type: data['type'] ?? '',
      status: data['status'] ?? 'empty',
      url: data['url'] ?? '',
      rejectionReason: data['rejectionReason'] ?? '',
      uploadedAt: data['uploadedAt'] ?? '',
      verifiedAt: data['verifiedAt'] ?? '',
      ocrWarnings: List<String>.from(data['ocrWarnings'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'status': status,
      'url': url,
      'rejectionReason': rejectionReason,
      'uploadedAt': uploadedAt,
      'verifiedAt': verifiedAt,
      'ocrWarnings': ocrWarnings,
    };
  }

  DocumentRecord copyWith({
    String? status,
    String? url,
    String? rejectionReason,
    String? uploadedAt,
    String? verifiedAt,
    List<String>? ocrWarnings,
  }) {
    return DocumentRecord(
      id: id,
      name: name,
      type: type,
      status: status ?? this.status,
      url: url ?? this.url,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      ocrWarnings: ocrWarnings ?? this.ocrWarnings,
    );
  }
}

class TeacherRecord {
  final String id;
  final String username;
  final String email;
  final String password;
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
  final String status; // 'pending', 'active', 'inactive' — gates login
  final String registrationRejectionReason;
  final String verificationStatus; // 'pending', 'approved', 'rejected' — document/profile completeness
  final String verificationRejectionReason;
  final Map<String, DocumentRecord> documents;

  TeacherRecord({
    required this.id,
    required this.username,
    required this.email,
    this.password = '',
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
    this.registrationRejectionReason = '',
    this.verificationStatus = 'pending',
    this.verificationRejectionReason = '',
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

    bool docDone(String key) {
      final s = documents[key]?.status;
      return s == 'uploaded' || s == 'verified';
    }

    if (docDone('myKad')) score++;
    if (docDone('passportPhoto')) score++;
    if (docDone('resume')) score++;
    if (docDone('academicCertificates')) score++;
    if (docDone('medicalReport')) score++;
    if (docDone('bankStatement')) score++;

    return ((score / 16) * 100).round();
  }

  factory TeacherRecord.fromMap(String id, Map<String, dynamic> data) {
    Map<String, DocumentRecord> docs = {};
    if (data['documents'] != null && data['documents'] is Map) {
      final docMap = data['documents'] as Map<String, dynamic>;
      docMap.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          docs[key] = DocumentRecord.fromMap(value);
        }
      });
    }

    return TeacherRecord(
      id: id,
      username: data['username'] ?? '',
      email: data['email'] ?? '',
      password: data['password'] ?? '',
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
      currentScore: int.tryParse(data['currentScore']?.toString() ?? '') ?? 100,
      yearlyKpi: int.tryParse(data['yearlyKpi']?.toString() ?? '') ?? 0,
      status: data['status'] ?? 'active',
      registrationRejectionReason: data['registrationRejectionReason'] ?? '',
      verificationStatus: data['verificationStatus'] ?? 'pending',
      verificationRejectionReason: data['verificationRejectionReason'] ?? '',
      documents: docs,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'email': email,
      'password': password,
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
      'registrationRejectionReason': registrationRejectionReason,
      'verificationStatus': verificationStatus,
      'verificationRejectionReason': verificationRejectionReason,
      'documents': documents.map((key, value) => MapEntry(key, value.toMap())),
    };
  }

  TeacherRecord copyWith({
    String? email,
    String? address,
    String? phoneNumber,
    String? maritalStatus,
    String? emergencyContactName,
    String? emergencyContactNumber,
    String? verificationStatus,
    String? verificationRejectionReason,
    Map<String, DocumentRecord>? documents,
    int? currentScore,
    int? yearlyKpi,
    String? status,
    String? registrationRejectionReason,
    String? fullName,
    String? icNumber,
    String? gender,
    String? dob,
    String? role,
  }) {
    return TeacherRecord(
      id: id,
      username: username,
      email: email ?? this.email,
      password: password,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      icNumber: icNumber ?? this.icNumber,
      gender: gender ?? this.gender,
      dob: dob ?? this.dob,
      address: address ?? this.address,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      maritalStatus: maritalStatus ?? this.maritalStatus,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactNumber: emergencyContactNumber ?? this.emergencyContactNumber,
      currentScore: currentScore ?? this.currentScore,
      yearlyKpi: yearlyKpi ?? this.yearlyKpi,
      status: status ?? this.status,
      registrationRejectionReason: registrationRejectionReason ?? this.registrationRejectionReason,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      verificationRejectionReason: verificationRejectionReason ?? this.verificationRejectionReason,
      documents: documents ?? this.documents,
    );
  }
}
