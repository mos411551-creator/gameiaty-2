class Member {
  String id;
  int order;
  String name;
  String phone;
  DateTime dueDate;
  bool isPaid;
  bool isReceived;
  String paymentMethod;

  Member({
    required this.id,
    required this.order,
    required this.name,
    required this.phone,
    required this.dueDate,
    this.isPaid = false,
    this.isReceived = false,
    this.paymentMethod = 'كاش',
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'order': order,
    'name': name,
    'phone': phone,
    'dueDate': dueDate.toIso8601String(),
    'isPaid': isPaid,
    'isReceived': isReceived,
    'paymentMethod': paymentMethod,
  };

  factory Member.fromMap(Map<String, dynamic> map) => Member(
    id: map['id'],
    order: map['order'],
    name: map['name'],
    phone: map['phone'],
    dueDate: DateTime.parse(map['dueDate']),
    isPaid: map['isPaid'] ?? false,
    isReceived: map['isReceived'] ?? false,
    paymentMethod: map['paymentMethod'] ?? 'كاش',
  );
}

class Association {
  String id;
  String name;
  String type;
  double shareAmount;
  int membersCount;
  DateTime startDate;
  DateTime endDate;
  DateTime createdAt;
  List<Member> members;

  Association({
    required this.id,
    required this.name,
    required this.type,
    required this.shareAmount,
    required this.membersCount,
    required this.startDate,
    required this.endDate,
    required this.createdAt,
    required this.members,
  });

  // الحسبة الدقيقة: السهم × عدد الأفراد = إجمالي القبض
  double get totalPayout => shareAmount * membersCount;
  int get paidCount => members.where((m) => m.isPaid).length;
  double get progressPercentage => members.isEmpty ? 0 : (paidCount / membersCount) * 100;

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'type': type,
    'shareAmount': shareAmount,
    'membersCount': membersCount,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    'members': members.map((m) => m.toMap()).toList(),
  };

  factory Association.fromMap(Map<String, dynamic> map) => Association(
    id: map['id'],
    name: map['name'],
    type: map['type'],
    shareAmount: (map['shareAmount'] as num).toDouble(),
    membersCount: map['membersCount'],
    startDate: DateTime.parse(map['startDate']),
    endDate: DateTime.parse(map['endDate']),
    createdAt: DateTime.parse(map['createdAt']),
    members: (map['members'] as List).map((m) => Member.fromMap(m)).toList(),
  );
}
