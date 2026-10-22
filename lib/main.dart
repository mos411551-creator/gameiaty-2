import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'models/association.dart';
import 'widgets/app_icon.dart';

void main() {
  runApp(const GameiatyApp());
}

class GameiatyApp extends StatelessWidget {
  const GameiatyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'جمعيتي',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar', 'EG'),
      supportedLocales: const [Locale('ar', 'EG')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        fontFamily: 'Cairo',
        scaffoldBackgroundColor: const Color(0xFFFCFAF6),
        primaryColor: const Color(0xFF0F172A),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0D5D44),
          primary: const Color(0xFF0F172A),
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Association> associations = [];
  String selectedFilter = 'كلهم';
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('associations_data_v2');

    if (jsonStr != null && jsonStr.isNotEmpty) {
      final List decoded = jsonDecode(jsonStr);
      setState(() {
        associations = decoded.map((e) => Association.fromMap(e)).toList();
      });
    } else {
      // إدراج الجمعية الافتراضية (100 ج × 100 فرد = 10,000 ج)
      final now = DateTime.now();
      final end = now.add(const Duration(days: 100));

      final defaultMembers = List.generate(100, (i) {
        return Member(
          id: 'mem_${i + 1}',
          order: i + 1,
          name: i == 0 ? 'محمود رمضان (أنت)' : 'مشترك دور ${i + 1}',
          phone: '0100000000${i % 10}',
          dueDate: now.add(Duration(days: i)),
        );
      });

      final defaultAssoc = Association(
        id: 'assoc_1',
        name: 'جمعية الحبايب',
        type: 'يومية',
        shareAmount: 100.0,
        membersCount: 100,
        startDate: now,
        endDate: end,
        createdAt: now,
        members: defaultMembers,
      );

      setState(() {
        associations = [defaultAssoc];
      });
      _saveData();
    }
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(associations.map((a) => a.toMap()).toList());
    await prefs.setString('associations_data_v2', encoded);
  }

  void _sendWhatsAppReminder(String phone, String text) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final fullPhone = cleanPhone.startsWith('0') ? '2$cleanPhone' : cleanPhone;
    final uri = Uri.parse("https://wa.me/$fullPhone?text=${Uri.encodeComponent(text)}");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = associations.where((a) {
      final matchesFilter = selectedFilter == 'كلهم' || a.type == selectedFilter;
      final matchesSearch = a.name.contains(searchQuery);
      return matchesFilter && matchesSearch;
    }).toList();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              _buildStatsGrid(),
              const SizedBox(height: 16),
              _buildSearchAndFilters(),
              const SizedBox(height: 16),
              if (filtered.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(40),
                  child: Text('لا توجد جمعيات تطابق البحث', style: TextStyle(color: Colors.grey)),
                )
              else
                ...filtered.map((assoc) => _buildAssociationCard(assoc)).toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        ElevatedButton.icon(
          onPressed: () => _showAddAssociationDialog(),
          icon: const Icon(Icons.add, size: 18, color: Colors.white),
          label: const Text('جديدة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E1E1E),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          ),
        ),
        const Spacer(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: const [
            Text(
              'جمعيتي',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
            ),
            Text(
              'نظام الجمعية المصرية - أسهم مشتركة 50/30/20',
              style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(width: 10),
        const GameiatyLogo(size: 46),
      ],
    );
  }

  Widget _buildStatsGrid() {
    double totalPmt = associations.fold(0, (sum, a) => sum + a.shareAmount);
    int totalMembers = associations.fold(0, (sum, a) => sum + a.membersCount);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSmallStatCard(
                title: 'فلوس',
                icon: Icons.account_balance_wallet_outlined,
                mainValue: '${totalPmt.toInt()} ج',
                subValue: 'لكل دورة',
                bgColor: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSmallStatCard(
                title: 'الجمعيات',
                icon: Icons.layers_outlined,
                mainValue: '${associations.length}',
                subValue: '$totalMembers فرد',
                bgColor: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSmallStatCard(
                title: 'سهم مشترك',
                icon: Icons.call_split_rounded,
                mainValue: '100=50+30+20ج مثال',
                subValue: 'معاينة محلية',
                bgColor: const Color(0xFFE2F7F2),
                titleColor: const Color(0xFF0F766E),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSmallStatCard(
                title: 'نشطة',
                icon: Icons.emoji_events_outlined,
                mainValue: '${associations.length}',
                subValue: 'شغالة',
                bgColor: const Color(0xFFFFFBEB),
                titleColor: const Color(0xFFB45309),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSmallStatCard({
    required String title,
    required IconData icon,
    required String mainValue,
    required String subValue,
    required Color bgColor,
    Color titleColor = const Color(0xFF475569),
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: titleColor)),
              const SizedBox(width: 6),
              Icon(icon, size: 16, color: titleColor),
            ],
          ),
          const SizedBox(height: 6),
          Text(mainValue, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
          const SizedBox(height: 2),
          Text(subValue, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          TextField(
            textAlign: TextAlign.right,
            onChanged: (val) => setState(() => searchQuery = val),
            decoration: InputDecoration(
              hintText: 'دوّر باسم الجمعية...',
              hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
              prefixIcon: const Icon(Icons.search, color: Color(0xFF94A3B8)),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true,
            child: Row(
              children: [
                _buildFilterChip('كلهم'),
                _buildFilterChip('يومية'),
                _buildFilterChip('شهرية'),
                _buildFilterChip('سنوية'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    bool isSelected = selectedFilter == label;
    return GestureDetector(
      onTap: () => setState(() => selectedFilter = label),
      child: Container(
        margin: const EdgeInsets.only(left: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E1E1E) : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: isSelected ? Colors.transparent : const Color(0xFFE2E8F0)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildAssociationCard(Association assoc) {
    final nextMember = assoc.members.firstWhere((m) => !m.isReceived, orElse: () => assoc.members.last);
    final dateFormat = DateFormat('EEEE، d MMMM yyyy', 'ar');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            // شريط أزرق مطابق
            Container(height: 6, color: const Color(0xFF2563EB)),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        onPressed: () => _openAssociationDetails(assoc),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E1E1E),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
                        ),
                        child: const Text('دخول', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFBFDBFE)),
                            ),
                            child: Text(assoc.type, style: const TextStyle(fontSize: 11, color: Color(0xFF1D4ED8), fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${nextMember.order}/${assoc.membersCount} • ${assoc.type == 'يومية' ? 'يوم' : (assoc.type == 'شهرية' ? 'شهر' : 'سنة')}',
                              style: const TextStyle(fontSize: 11, color: Color(0xFFB45309), fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    assoc.name,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'أنشئت ${dateFormat.format(assoc.createdAt)} • ${assoc.membersCount} سهم / ${assoc.membersCount} فرد',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${assoc.progressPercentage.toInt()}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                      const Text('التقدم', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: assoc.progressPercentage / 100,
                      backgroundColor: const Color(0xFFE2E8F0),
                      color: const Color(0xFF2563EB),
                      minHeight: 7,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFDBEAFE)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Text('استحقاق الدور القادم', style: TextStyle(fontSize: 10, color: Color(0xFF1E40AF))),
                              const SizedBox(height: 2),
                              Text(
                                DateFormat('EEEE، d MMMM', 'ar').format(nextMember.dueDate),
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF1D4ED8)),
                              ),
                              const SizedBox(height: 2),
                              Text('${assoc.paidCount}/${assoc.membersCount} دفع (${assoc.membersCount} فرد)', style: const TextStyle(fontSize: 10, color: Color(0xFF60A5FA))),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Text('السهم', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                              const SizedBox(height: 2),
                              Text('${assoc.shareAmount.toInt()} ج', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                              const SizedBox(height: 2),
                              Text('كل ${assoc.type == 'يومية' ? 'يوم' : (assoc.type == 'شهرية' ? 'شهر' : 'سنة')}', style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Text('القبض', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                              const SizedBox(height: 2),
                              Text('${assoc.totalPayout.toInt()} ج', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                              const SizedBox(height: 2),
                              Text('${assoc.membersCount} فرد', style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => _deleteAssociation(assoc),
                        icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFFFEF2F2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _openAssociationDetails(assoc),
                          icon: const Icon(Icons.people_outline, size: 16, color: Color(0xFF475569)),
                          label: const Text('كشف الأعضاء', style: TextStyle(color: Color(0xFF475569))),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteAssociation(Association assoc) {
    setState(() => associations.removeWhere((a) => a.id == assoc.id));
    _saveData();
  }

  void _showAddAssociationDialog() {
    final nameCtrl = TextEditingController(text: 'جمعية جديدة');
    final amountCtrl = TextEditingController(text: '100');
    final membersCtrl = TextEditingController(text: '100');
    String type = 'يومية';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          double share = double.tryParse(amountCtrl.text) ?? 0;
          int membersCount = int.tryParse(membersCtrl.text) ?? 0;
          double totalPayout = share * membersCount;

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('إنشاء جمعية جديدة', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  TextField(controller: nameCtrl, textAlign: TextAlign.right, decoration: const InputDecoration(labelText: 'اسم الجمعية', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: type,
                          items: ['يومية', 'شهرية', 'سنوية'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                          onChanged: (v) => setModalState(() => type = v!),
                          decoration: const InputDecoration(labelText: 'الدورية', border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: amountCtrl,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          onChanged: (v) => setModalState(() {}),
                          decoration: const InputDecoration(labelText: 'قيمة السهم (ج)', border: OutlineInputBorder()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: membersCtrl,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    onChanged: (v) => setModalState(() {}),
                    decoration: const InputDecoration(labelText: 'عدد الأفراد / عدد الأسهم', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${totalPayout.toInt()} ج', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF065F46))),
                        Text('إجمالي القبض لكل مشترك ($membersCount فرد):', style: const TextStyle(fontSize: 12, color: Color(0xFF047857), fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      final now = DateTime.now();
                      DateTime end = type == 'يومية'
                          ? now.add(Duration(days: membersCount))
                          : (type == 'شهرية' ? DateTime(now.year, now.month + membersCount, now.day) : DateTime(now.year + membersCount, now.month, now.day));

                      final newMembers = List.generate(membersCount, (i) {
                        DateTime memberDue = type == 'يومية'
                            ? now.add(Duration(days: i))
                            : (type == 'شهرية' ? DateTime(now.year, now.month + i, now.day) : DateTime(now.year + i, now.month, now.day));

                        return Member(
                          id: 'mem_${DateTime.now().millisecondsSinceEpoch}_$i',
                          order: i + 1,
                          name: i == 0 ? 'محمود رمضان (أنت)' : 'مشترك فرد ${i + 1}',
                          phone: '01000000000',
                          dueDate: memberDue,
                        );
                      });

                      final newAssoc = Association(
                        id: 'assoc_${DateTime.now().millisecondsSinceEpoch}',
                        name: nameCtrl.text.trim().isEmpty ? 'جمعية' : nameCtrl.text.trim(),
                        type: type,
                        shareAmount: share,
                        membersCount: membersCount,
                        startDate: now,
                        endDate: end,
                        createdAt: now,
                        members: newMembers,
                      );

                      setState(() => associations.insert(0, newAssoc));
                      _saveData();
                      Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D5D44),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('حفظ وبدء الجمعية', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _openAssociationDetails(Association assoc) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AssociationDetailsScreen(
          association: assoc,
          onUpdate: () {
            setState(() {});
            _saveData();
          },
          onWhatsApp: _sendWhatsAppReminder,
        ),
      ),
    );
  }
}

class AssociationDetailsScreen extends StatefulWidget {
  final Association association;
  final VoidCallback onUpdate;
  final Function(String phone, String text) onWhatsApp;

  const AssociationDetailsScreen({
    super.key,
    required this.association,
    required this.onUpdate,
    required this.onWhatsApp,
  });

  @override
  State<AssociationDetailsScreen> createState() => _AssociationDetailsScreenState();
}

class _AssociationDetailsScreenState extends State<AssociationDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    final assoc = widget.association;
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: Text(assoc.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${assoc.totalPayout.toInt()} ج', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFF3C769))),
                      const Text('إجمالي مبلغ القبض', style: TextStyle(color: Colors.white70)),
                    ],
                  ),
                  const Divider(color: Colors.white24, height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${assoc.membersCount} فرد', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      const Text('عدد المشتركين والأسهم:', style: TextStyle(color: Colors.white70)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'كشف الأدوار والاستحقاقات (${assoc.members.length} فرد)',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: assoc.members.length,
              itemBuilder: (ctx, index) {
                final member = assoc.members[index];
                final isDueSoon = member.dueDate.difference(now).inDays <= 2 && member.dueDate.difference(now).inDays >= 0;

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDueSoon ? const Color(0xFFF59E0B) : Colors.grey.withOpacity(0.15),
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          final msg = 'مبروك يا ${member.name}! حان موعد استلام سهمك في ${assoc.name} بقيمة ${assoc.totalPayout.toInt()} ج.';
                          widget.onWhatsApp(member.phone, msg);
                        },
                        icon: const Icon(Icons.chat_bubble_outline, color: Color(0xFF25D366)),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() => member.isPaid = !member.isPaid);
                          widget.onUpdate();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: member.isPaid ? const Color(0xFFD1FAE5) : const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            member.isPaid ? '✓ دفع' : 'لم يدفع',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: member.isPaid ? const Color(0xFF065F46) : const Color(0xFFB91C1C),
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(member.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text(DateFormat('d MMMM yyyy', 'ar').format(member.dueDate), style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                        ],
                      ),
                      const SizedBox(width: 10),
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: const Color(0xFF0D5D44),
                        child: Text('${member.order}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
