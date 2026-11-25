// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await OnlineRoomService.instance.tryInitialize();
  runApp(const BalootBahmadApp());
}

class BalootBahmadApp extends StatelessWidget {
  const BalootBahmadApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'بلوت بحمد',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF1D6B43),
      ),
      home: const LobbyMajlisScreen(),
    );
  }
}

class OnlineRoomService {
  OnlineRoomService._();
  static final OnlineRoomService instance = OnlineRoomService._();

  bool isFirebaseReady = false;

  Future<void> tryInitialize() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      isFirebaseReady = true;
    } catch (_) {
      isFirebaseReady = false;
    }
  }

  CollectionReference get _roomsCollection =>
      FirebaseFirestore.instance.collection('baloot_rooms');

  Future<String> createOrJoinRoom(String roomCode, String playerName) async {
    final cleanCode = roomCode.trim().toUpperCase();
    if (cleanCode.isEmpty) {
      throw Exception('أدخل رمز غرفة صحيح');
    }
    if (!isFirebaseReady) {
      return 'غرفة [$cleanCode] جاهزة';
    }
    final cleanName = playerName.trim().isEmpty ? 'محمد' : playerName.trim();
    final ref = _roomsCollection.doc(cleanCode);
    final snap = await ref.get();
    if (!snap.exists) {
      await ref.set({
        'code': cleanCode,
        'host': cleanName,
        'createdAt': FieldValue.serverTimestamp(),
        'players': [cleanName],
        'messages': [
          {
            'sender': 'النظام',
            'text': 'تم فتح غرفة $cleanCode',
            'isQuickCall': false,
          }
        ],
      });
    } else {
      await ref.update({
        'players': FieldValue.arrayUnion([cleanName]),
      });
    }
    return 'متصل بالغرفة [$cleanCode]';
  }

  Future<void> sendRoomMessage({
    required String roomCode,
    required String sender,
    required String text,
    required bool isQuickCall,
  }) async {
    if (!isFirebaseReady) return;
    final cleanCode = roomCode.trim().toUpperCase();
    if (cleanCode.isEmpty) return;
    await _roomsCollection.doc(cleanCode).update({
      'messages': FieldValue.arrayUnion([
        {
          'sender': sender,
          'text': text,
          'isQuickCall': isQuickCall,
        }
      ]),
    });
  }

  Future<List<ChatMessageItem>> fetchRoomMessages(String roomCode) async {
    if (!isFirebaseReady) return const [];
    final cleanCode = roomCode.trim().toUpperCase();
    if (cleanCode.isEmpty) return const [];
    final snap = await _roomsCollection.doc(cleanCode).get();
    final data = snap.data() as Map<String, dynamic>?;
    final rawMsgs = data?['messages'];
    if (rawMsgs is! List) return const [];
    return rawMsgs
        .whereType()
        .map(
          (entry) => ChatMessageItem(
            sender: (entry['sender'] ?? 'لاعب').toString(),
            text: (entry['text'] ?? '').toString(),
            isQuickCall: entry['isQuickCall'] == true,
          ),
        )
        .toList();
  }
}

class ChatMessageItem {
  final String sender;
  final String text;
  final bool isQuickCall;

  const ChatMessageItem({
    required this.sender,
    required this.text,
    this.isQuickCall = false,
  });
}

class LobbyMajlisScreen extends StatefulWidget {
  const LobbyMajlisScreen({super.key});

  @override
  State<LobbyMajlisScreen> createState() => _LobbyMajlisScreenState();
}

class _LobbyMajlisScreenState extends State<LobbyMajlisScreen> {
  String playerName = 'محمد';
  int playerLevel = 3;
  int goldBalance = 16514;
  int tickerIndex = 0;
  Timer? _tickerTimer;

  static const List<String> eventTickerItems = [
    '[عساك سالم]',
    '[زيرو_البساسين...: ...]',
    '[أحمد: [إيموجي]]',
    '[T-: [إيموجي]]',
    '[رياض: [إيموجي]]',
    '[أبو سعد:أبو ...]',
  ];

  @override
  void initState() {
    super.initState();
    _tickerTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      setState(() {
        tickerIndex = (tickerIndex + 1) % eventTickerItems.length;
      });
    });
  }

  @override
  void dispose() {
    _tickerTimer?.cancel();
    super.dispose();
  }

  void _openGoldSendDialog() {
    final friendCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Dialog(
            backgroundColor: const Color(0xFFF6EBD2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: const BorderSide(color: Color(0xFFC99B38), width: 2.5),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD8B774),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'سجل الإرسال',
                          style: TextStyle(
                            color: Color(0xFF4A2E08),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const Text(
                        'إرسال ذهب',
                        style: TextStyle(
                          color: Color(0xFF4A2E08),
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                      InkWell(
                        onTap: () => Navigator.of(ctx).pop(),
                        child: const Icon(
                          Icons.close_rounded,
                          color: Color(0xFF6A4918),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 18,
                        backgroundColor: Color(0xFF3F5E4D),
                        child: Icon(Icons.person, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$goldBalance',
                        style: const TextStyle(
                          color: Color(0xFF5A3B0C),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: friendCtrl,
                    decoration: InputDecoration(
                      hintText: 'أدخل حساب الصديق',
                      filled: true,
                      fillColor: const Color(0xFFE7D6B5),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'أدخل عدد الذهب المراد إرساله',
                      filled: true,
                      fillColor: const Color(0xFFE7D6B5),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'ميزة VIP لتقليل الرسوم: الخصم الإضافي للخصم عند الإهداء 15% : 0%',
                    style: TextStyle(color: Color(0xFF6E4C1B), fontSize: 11),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD5A949),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'الترقية إلى VIP',
                          style: TextStyle(
                            color: Color(0xFF3E2405),
                            fontWeight: FontWeight.bold,
                            fontSize: 11.5,
                          ),
                        ),
                      ),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF69B347),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          final val = int.tryParse(amountCtrl.text.trim()) ?? 0;
                          if (val > 0 && val <= goldBalance) {
                            setState(() => goldBalance -= val);
                          }
                          Navigator.of(ctx).pop();
                        },
                        child: const Text('تأكيد الإرسال'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _openTasksDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Dialog(
            backgroundColor: const Color(0xFFF6EBD2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: const BorderSide(color: Color(0xFFC99B38), width: 2.5),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'المهام',
                        style: TextStyle(
                          color: Color(0xFF4A2E08),
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                      InkWell(
                        onTap: () => Navigator.of(ctx).pop(),
                        child: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDE0C4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'تفاعل هذا الأسبوع: 0',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12.5,
                              ),
                            ),
                            Text(
                              'تفاعل اليوم: 0',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _taskRow(
                          title: 'تسجيل دخول تراكمي 1 يوم',
                          badge: 'التفاعل 20',
                          progress: '1/1',
                          done: true,
                        ),
                        _taskRow(
                          title: 'اختيار مشروع 100 لـ 3 مرة في جلسة',
                          badge: 'التفاعل 40',
                          progress: '1/1',
                          done: true,
                        ),
                        _taskRow(
                          title: 'تسجيل دخول تراكمي 5 يوم',
                          badge: 'التفاعل 50',
                          progress: '5/1',
                          done: false,
                        ),
                        _taskRow(
                          title: 'شحن 1 مرة',
                          badge: 'التفاعل 60',
                          progress: '1/0',
                          done: false,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _taskRow({
    required String title,
    required String badge,
    required String progress,
    required bool done,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F1E1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                Text(
                  badge,
                  style: const TextStyle(
                    color: Color(0xFFD96B27),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Text(
            progress,
            style: const TextStyle(fontSize: 11.5, color: Colors.black54),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: done ? const Color(0xFF69B347) : const Color(0xFF6AA6C8),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              done ? 'إستلام' : 'أكمل المهمة',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openFriendsDrawer() {
    const friends = [
      ('الزهراني', 'قبل 3 ساعة', 'متوسط'),
      ('2409BRN2CA', 'قبل 4 ساعة', 'متوسط'),
      ('h917', 'قبل 14 ساعة', 'متوسط'),
      ('iPhone13,2', 'قبل 14 ساعة', 'متوسط'),
    ];
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFFF6EBD2),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'قائمة الأصدقاء • 13/20',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF4A2E08),
                      ),
                    ),
                    Text(
                      'متابَعيني • متابِعيني • إضافة صديق',
                      style: TextStyle(fontSize: 11, color: Colors.black54),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ...friends.map(
                  (f) => ListTile(
                    dense: true,
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFF1D6B43),
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    title: Text(
                      f.$1,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('${f.$2} • ${f.$3}'),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF69B347),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'إذهب للدردشة',
                        style: TextStyle(color: Colors.white, fontSize: 11),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openMailDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Dialog(
            backgroundColor: const Color(0xFFF6EBD2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: const BorderSide(color: Color(0xFFC99B38), width: 2.5),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'البريد — رسائل النظام',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF4A2E08),
                        ),
                      ),
                      InkWell(
                        onTap: () => Navigator.of(ctx).pop(),
                        child: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'سيتم حفظ الرسالة لمدة 7 أيام',
                    style: TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF69B347),
                        ),
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('إستلام الكل'),
                      ),
                      const SizedBox(width: 10),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFD96B27),
                        ),
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('حذف الكل'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _openSettingsDialog() {
    var oldSound = true;
    var musicOn = false;
    var sOn = true;
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setD) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: Dialog(
                backgroundColor: const Color(0xFFF6EBD2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: const BorderSide(color: Color(0xFFC99B38), width: 2.5),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'الإعدادات',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                              color: Color(0xFF4A2E08),
                            ),
                          ),
                          InkWell(
                            onTap: () => Navigator.of(ctx).pop(),
                            child: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SwitchListTile(
                        title: const Text('الصوت القديم'),
                        value: oldSound,
                        onChanged: (v) => setD(() => oldSound = v),
                      ),
                      SwitchListTile(
                        title: const Text('موسيقى'),
                        value: musicOn,
                        onChanged: (v) => setD(() => musicOn = v),
                      ),
                      SwitchListTile(
                        title: const Text('ص'),
                        subtitle: const Text('يمكنك الحصول على جائزة ذهب'),
                        value: sOn,
                        onChanged: (v) => setD(() => sOn = v),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'تقديم • منع الحساب • تغييرات • معاينة الحساب • الكلام • الحساب رسمي',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 10.5, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openEventCenterDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Dialog(
            backgroundColor: const Color(0xFF283A4E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: const BorderSide(color: Color(0xFFD5A949), width: 2),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'مركز الأحداث — ليلة الكشتة',
                        style: TextStyle(
                          color: Color(0xFFF7D774),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      InkWell(
                        onTap: () => Navigator.of(ctx).pop(),
                        child: const Icon(
                          Icons.close_rounded,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'الشراء التراكمي اليوم 3 • صندوق ليلة الكشتة A / B',
                    style: TextStyle(color: Colors.white, fontSize: 12.5),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '3500 / 5000  •  30000 / 60000  •  250000 / 500000',
                    style: TextStyle(
                      color: Color(0xFFF7D774),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF8E6E46),
                Color(0xFF694D2C),
                Color(0xFF473119),
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildLeaderboardColumn(),
                        const SizedBox(width: 8),
                        Expanded(flex: 5, child: _buildMajlisCenter()),
                        const SizedBox(width: 8),
                        Expanded(flex: 6, child: _buildWatchPanel()),
                      ],
                    ),
                  ),
                ),
                _buildBottomBar(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black45,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFD5A949)),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.workspace_premium,
                  color: Color(0xFFF7D774),
                  size: 16,
                ),
                SizedBox(width: 4),
                Text(
                  'إشتراك VIP',
                  style: TextStyle(
                    color: Color(0xFFF7D774),
                    fontWeight: FontWeight.bold,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black45,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.monetization_on,
                  color: Color(0xFFF7D774),
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  '$goldBalance',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 6),
                InkWell(
                  onTap: _openGoldSendDialog,
                  child: const CircleAvatar(
                    radius: 9,
                    backgroundColor: Color(0xFF69B347),
                    child: Icon(Icons.add, size: 13, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4788C7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$playerLevel',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        playerName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const Text(
                    '16514',
                    style: TextStyle(color: Colors.white70, fontSize: 10.5),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF2D4739),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFD5A949), width: 1.5),
                ),
                child: const Icon(Icons.person, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardColumn() {
    return SizedBox(
      width: 78,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF6F4E29),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFD5A949)),
            ),
            child: const Text(
              'المتصدّرين',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFFF7D774),
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _LeaderBadge(rankText: '1', accent: Color(0xFFFFD54F)),
                  _LeaderBadge(rankText: '2', accent: Color(0xFFE0E0E0)),
                  _LeaderBadge(rankText: '3', accent: Color(0xFFBCAAA4)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMajlisCenter() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF9C7B53), Color(0xFF6B4F2F)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x88F7D774)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 116,
            height: 116,
            decoration: BoxDecoration(
              color: const Color(0xFF3E4E5E).withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFD5A949), width: 1.8),
            ),
            child: const Center(
              child: Icon(Icons.add, color: Colors.white, size: 38),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black38,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'لم تنضم لنادٍ بعد\nبعد الانضمام إلى النادي يمكنك الحصول على مزايا إضافية مثل فرص كنز الإخلاص',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 10.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWatchPanel() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF5D4224).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x88E6B84C)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'شاهد',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: _miniModeTile(
                          title: 'الدردشة الصوتية',
                          color: const Color(0xFFE69A28),
                          icon: Icons.mic,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => MoreGamesScreen(
                                  playerName: playerName,
                                  goldBalance: goldBalance,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 6),
                      Expanded(
                        child: _miniModeTile(
                          title: 'الساحة',
                          color: const Color(0xFF3E6F9E),
                          icon: Icons.stadium,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => MoreGamesScreen(
                                  playerName: playerName,
                                  goldBalance: goldBalance,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: _miniModeTile(
                          title: 'ألعاب الحظ',
                          color: const Color(0xFFD65A31),
                          icon: Icons.casino,
                          onTap: _openEventCenterDialog,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Expanded(
                        child: _miniModeTile(
                          title: 'تحدّي المصاقعة',
                          color: const Color(0xFFC98A28),
                          icon: Icons.sports_mma,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => MoreGamesScreen(
                                  playerName: playerName,
                                  goldBalance: goldBalance,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => MoreGamesScreen(
                    playerName: playerName,
                    goldBalance: goldBalance,
                  ),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF473119),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white12),
              ),
              child: const Text(
                'تحدّيات',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            flex: 3,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => SakkaRoomsScreen(
                      playerName: playerName,
                      goldBalance: goldBalance,
                    ),
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF28A76B), Color(0xFF136B42)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFF7D774),
                    width: 1.5,
                  ),
                ),
                padding: const EdgeInsets.all(10),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.style_rounded, color: Colors.white, size: 34),
                    SizedBox(height: 4),
                    Text(
                      'صكّة',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniModeTile({
    required String title,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(height: 3),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      color: const Color(0xFF392612),
      child: Row(
        children: [
          InkWell(
            onTap: _openEventCenterDialog,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF563A1C),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFD5A949)),
              ),
              child: Row(
                children: [
                  const Text(
                    'مركز الأحداث',
                    style: TextStyle(
                      color: Color(0xFFF7D774),
                      fontWeight: FontWeight.bold,
                      fontSize: 10.5,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    eventTickerItems[tickerIndex],
                    style: const TextStyle(color: Colors.white70, fontSize: 10),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          _bottomIconBtn(Icons.monetization_on, 'إرسال الذهب', _openGoldSendDialog),
          _bottomIconBtn(Icons.event_note, 'الأنشطة', _openEventCenterDialog),
          _bottomIconBtn(Icons.assignment, 'المهام', _openTasksDialog),
          _bottomIconBtn(Icons.people, 'الأصدقاء', _openFriendsDrawer),
          _bottomIconBtn(Icons.mail, 'الرسائل', _openMailDialog),
          _bottomIconBtn(Icons.settings, 'إعدادات', _openSettingsDialog),
        ],
      ),
    );
  }

  Widget _bottomIconBtn(IconData icon, String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: const Color(0xFFE6B84C), size: 18),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 9.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeaderBadge extends StatelessWidget {
  final String rankText;
  final Color accent;

  const _LeaderBadge({required this.rankText, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF4F371D),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent, width: 1.3),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 10,
            backgroundColor: accent,
            child: Text(
              rankText,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ),
          const SizedBox(width: 4),
          const Expanded(
            child: Icon(Icons.person, color: Colors.white70, size: 16),
          ),
        ],
      ),
    );
  }
}

class SakkaRoomsScreen extends StatelessWidget {
  final String playerName;
  final int goldBalance;

  const SakkaRoomsScreen({
    super.key,
    required this.playerName,
    required this.goldBalance,
  });

  @override
  Widget build(BuildContext context) {
    const rooms = [
      (
        'مبتدئ',
        '20:score',
        'فوز +3\nخسارة 0',
        'دخول\nأدنى دخول 1000~10000',
        Color(0xFF5D9E42),
        20,
      ),
      (
        'متوسط',
        '50:score',
        'فوز +4\nخسارة 0',
        'دخول\nأدنى دخول 5000~50000',
        Color(0xFF2D8F9E),
        50,
      ),
      (
        'متقدم',
        '150:score',
        'فوز +6\nخسارة 0',
        'دخول\nأدنى دخول 10000~100000',
        Color(0xFF3E68A8),
        150,
      ),
      (
        'محترف',
        '1000:score',
        'فوز +8\nخسارة 0',
        'دخول\nأدنى دخول 50000~800000',
        Color(0xFFB55A2A),
        152,
      ),
      (
        'نايفة',
        '3000:score',
        'فوز +10\nخسارة 0',
        'دخول\nأدنى دخول 300000~',
        Color(0xFF7D4399),
        152,
      ),
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF9C8464), Color(0xFF6B5338)],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        child: const CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.black38,
                          child: Icon(
                            Icons.arrow_forward,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'صكّة',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black38,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          '$goldBalance',
                          style: const TextStyle(
                            color: Color(0xFFF7D774),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: rooms.length,
                    itemBuilder: (_, idx) {
                      final r = rooms[idx];
                      return InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => BalootMatchScreen(
                                playerName: playerName,
                                partnerName: 'المحماد..',
                                rightOpponentName: 'عز',
                                leftOpponentName: 'iPhone1..',
                                targetScore: r.$6,
                                roomTitle: r.$1,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          width: 158,
                          margin: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: r.$5,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: const Color(0xFFF7D774),
                              width: 1.5,
                            ),
                          ),
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                r.$1,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 20,
                                ),
                              ),
                              Text(
                                r.$2,
                                style: const TextStyle(
                                  color: Color(0xFFF7D774),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                r.$3,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.black26,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  r.$4,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 10.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'رتبتي',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'جديد 3',
                        style: TextStyle(color: Color(0xFFF7D774)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MoreGamesScreen extends StatelessWidget {
  final String playerName;
  final int goldBalance;

  const MoreGamesScreen({
    super.key,
    required this.playerName,
    required this.goldBalance,
  });

  @override
  Widget build(BuildContext context) {
    const items = [
      ('الجلسات', Icons.chair_alt, Color(0xFFD99B38)),
      ('ربح مجاناً', Icons.emoji_events, Color(0xFFC75B2A)),
      ('سلم التحدّي', Icons.military_tech, Color(0xFFD49A2A)),
      ('دوري المحترفين', Icons.workspace_premium, Color(0xFF3E6F9E)),
      ('صكّة سريعة', Icons.style, Color(0xFF289A63)),
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFDFC89E), Color(0xFFC3A16B)],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.monetization_on,
                        color: Color(0xFF9C6B14),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$goldBalance',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4A2E08),
                        ),
                      ),
                      const Spacer(),
                      const Text(
                        'المزيد من الألعاب',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Color(0xFF4A2E08),
                        ),
                      ),
                      const Spacer(),
                      InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        child: const CircleAvatar(
                          radius: 16,
                          backgroundColor: Color(0xFF5A3B0C),
                          child: Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: items.map((it) {
                      return InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => LadderChallengeScreen(
                                playerName: playerName,
                                goldBalance: goldBalance,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          width: 112,
                          height: 158,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF6EBD2),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: const Color(0xFFC99B38),
                              width: 2,
                            ),
                          ),
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                radius: 28,
                                backgroundColor: it.$3,
                                child: Icon(
                                  it.$2,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                it.$1,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12.5,
                                  color: Color(0xFF4A2E08),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class LadderChallengeScreen extends StatefulWidget {
  final String playerName;
  final int goldBalance;

  const LadderChallengeScreen({
    super.key,
    required this.playerName,
    required this.goldBalance,
  });

  @override
  State<LadderChallengeScreen> createState() => _LadderChallengeScreenState();
}

class _LadderChallengeScreenState extends State<LadderChallengeScreen> {
  bool isSearching = false;
  int seconds = 0;
  Timer? _searchTimer;

  void _startSearch() {
    setState(() {
      isSearching = true;
      seconds = 0;
    });
    _searchTimer?.cancel();
    _searchTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => seconds++);
      if (seconds >= 3) {
        t.cancel();
        setState(() => isSearching = false);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => BalootMatchScreen(
              playerName: widget.playerName,
              partnerName: 'المحماد..',
              rightOpponentName: 'عز',
              leftOpponentName: 'iPhone1..',
              targetScore: 152,
              roomTitle: 'سلم التحدّي',
            ),
          ),
        );
      }
    });
  }

  void _cancelSearch() {
    _searchTimer?.cancel();
    setState(() {
      isSearching = false;
      seconds = 0;
    });
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final secStr = '00:0$seconds';
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF3E4B5B), Color(0xFF232C38)],
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        child: const CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.black38,
                          child: Icon(
                            Icons.arrow_forward,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'سلم التحدّي',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${widget.goldBalance}',
                        style: const TextStyle(
                          color: Color(0xFFF7D774),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black38,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'سلم التحدّي يستخدم طريقة اللعب الحر وخاصية قلبك ، يمكنك لعب أي ورقة',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF5D7694),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'متقدم',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: 132,
                      height: 152,
                      decoration: BoxDecoration(
                        color: const Color(0xFF6B8BAE),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: const Color(0xFFF7D774),
                          width: 2,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.shield_rounded,
                          color: Colors.white,
                          size: 68,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '4475/5200',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: Column(
                    children: [
                      const Text(
                        'فوز متتالي 1 جولة',
                        style: TextStyle(
                          color: Color(0xFFF7D774),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (!isSearching)
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF42A86B),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 34,
                              vertical: 12,
                            ),
                          ),
                          onPressed: _startSearch,
                          child: const Text(
                            'ابدأ البحث   500',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        )
                      else ...[
                        Text(
                          'جاري البحث $secStr',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFD45A38),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 34,
                              vertical: 10,
                            ),
                          ),
                          onPressed: _cancelSearch,
                          child: const Text(
                            'إلغاء البحث',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum Suit { spades, hearts, clubs, diamonds }

extension SuitExt on Suit {
  String get symbol {
    switch (this) {
      case Suit.spades:
        return '♠';
      case Suit.hearts:
        return '♥';
      case Suit.clubs:
        return '♣';
      case Suit.diamonds:
        return '♦';
    }
  }

  String get arabic {
    switch (this) {
      case Suit.spades:
        return 'سباتي';
      case Suit.hearts:
        return 'هاص';
      case Suit.clubs:
        return 'سبيت';
      case Suit.diamonds:
        return 'ديمن';
    }
  }
}

enum Rank { seven, eight, nine, ten, jack, queen, king, ace }

enum PlayMode { none, sun, hokm }

enum MatchPhase { bidding, playing, roundEnd, matchEnd }

class CardItem {
  final Suit suit;
  final Rank rank;

  const CardItem(this.suit, this.rank);

  bool get isRed => suit == Suit.hearts || suit == Suit.diamonds;

  String get rankText {
    switch (rank) {
      case Rank.seven:
        return '7';
      case Rank.eight:
        return '8';
      case Rank.nine:
        return '9';
      case Rank.ten:
        return '10';
      case Rank.jack:
        return 'J';
      case Rank.queen:
        return 'Q';
      case Rank.king:
        return 'K';
      case Rank.ace:
        return 'A';
    }
  }

  int get seq {
    switch (rank) {
      case Rank.seven:
        return 1;
      case Rank.eight:
        return 2;
      case Rank.nine:
        return 3;
      case Rank.ten:
        return 4;
      case Rank.jack:
        return 5;
      case Rank.queen:
        return 6;
      case Rank.king:
        return 7;
      case Rank.ace:
        return 8;
    }
  }

  int power(PlayMode mode, Suit? hokm) {
    if (mode == PlayMode.sun) {
      switch (rank) {
        case Rank.seven:
          return 1;
        case Rank.eight:
          return 2;
        case Rank.nine:
          return 3;
        case Rank.jack:
          return 4;
        case Rank.queen:
          return 5;
        case Rank.king:
          return 6;
        case Rank.ten:
          return 7;
        case Rank.ace:
          return 8;
      }
    }
    final trump = suit == hokm;
    if (trump) {
      switch (rank) {
        case Rank.seven:
          return 1;
        case Rank.eight:
          return 2;
        case Rank.queen:
          return 3;
        case Rank.king:
          return 4;
        case Rank.ten:
          return 5;
        case Rank.ace:
          return 6;
        case Rank.nine:
          return 7;
        case Rank.jack:
          return 8;
      }
    }
    switch (rank) {
      case Rank.seven:
        return 1;
      case Rank.eight:
        return 2;
      case Rank.nine:
        return 3;
      case Rank.jack:
        return 4;
      case Rank.queen:
        return 5;
      case Rank.king:
        return 6;
      case Rank.ten:
        return 7;
      case Rank.ace:
        return 8;
    }
  }

  int points(PlayMode mode, Suit? hokm) {
    if (mode == PlayMode.sun) {
      switch (rank) {
        case Rank.ace:
          return 11;
        case Rank.ten:
          return 10;
        case Rank.king:
          return 4;
        case Rank.queen:
          return 3;
        case Rank.jack:
          return 2;
        default:
          return 0;
      }
    }
    if (suit == hokm) {
      switch (rank) {
        case Rank.jack:
          return 20;
        case Rank.nine:
          return 14;
        case Rank.ace:
          return 11;
        case Rank.ten:
          return 10;
        case Rank.king:
          return 4;
        case Rank.queen:
          return 3;
        default:
          return 0;
      }
    }
    switch (rank) {
      case Rank.ace:
        return 11;
      case Rank.ten:
        return 10;
      case Rank.king:
        return 4;
      case Rank.queen:
        return 3;
      case Rank.jack:
        return 2;
      default:
        return 0;
    }
  }

  @override
  bool operator ==(Object other) =>
      other is CardItem && other.suit == suit && other.rank == rank;

  @override
  int get hashCode => Object.hash(suit, rank);
}

class BalootMatchScreen extends StatefulWidget {
  final String playerName;
  final String partnerName;
  final String rightOpponentName;
  final String leftOpponentName;
  final int targetScore;
  final String roomTitle;

  const BalootMatchScreen({
    super.key,
    required this.playerName,
    required this.partnerName,
    required this.rightOpponentName,
    required this.leftOpponentName,
    required this.targetScore,
    required this.roomTitle,
  });

  @override
  State<BalootMatchScreen> createState() => _BalootMatchScreenState();
}

class _BalootMatchScreenState extends State<BalootMatchScreen> {
  final Random _rng = Random();
  late List<String> names;
  List<String?> bubbles = [null, null, null, null];

  MatchPhase phase = MatchPhase.bidding;
  PlayMode playMode = PlayMode.none;
  Suit? hokmSuit;
  int dealerSeat = 0;
  int turn = 1;
  int passes = 0;
  int bidRound = 1;

  List<List<CardItem>> hands = [[], [], [], []];
  CardItem? floorCard;
  List<(int, CardItem)> trick = [];

  int usScore = 0;
  int themScore = 0;
  int usRoundPts = 0;
  int themRoundPts = 0;
  bool busy = false;

  int seraCount = 1;
  int fiftyCount = 1;
  int hundredCount = 1;
  int fourHundredCount = 1;

  @override
  void initState() {
    super.initState();
    names = [
      widget.playerName,
      widget.rightOpponentName,
      widget.partnerName,
      widget.leftOpponentName,
    ];
    _dealRound(resetMatch: true);
  }

  void _sayBubble(int seat, String text) {
    bubbles[seat] = text;
    setState(() {});
    Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      if (bubbles[seat] == text) {
        bubbles[seat] = null;
        setState(() {});
      }
    });
  }

  void _dealRound({required bool resetMatch}) {
    if (resetMatch) {
      usScore = 0;
      themScore = 0;
    }
    dealerSeat = (dealerSeat + 1) % 4;
    turn = (dealerSeat + 1) % 4;
    passes = 0;
    bidRound = 1;
    phase = MatchPhase.bidding;
    playMode = PlayMode.none;
    hokmSuit = null;
    trick = [];
    usRoundPts = 0;
    themRoundPts = 0;
    bubbles = [null, null, null, null];
    busy = false;

    final deck = <CardItem>[];
    for (final s in Suit.values) {
      for (final r in Rank.values) {
        deck.add(CardItem(s, r));
      }
    }
    deck.shuffle(_rng);

    hands = [
      deck.sublist(0, 8),
      deck.sublist(8, 16),
      deck.sublist(16, 24),
      deck.sublist(24, 32),
    ];
    floorCard = hands[(dealerSeat + 1) % 4].last;
    for (var i = 0; i < 4; i++) {
      hands[i].sort((a, b) {
        final sc = a.suit.index.compareTo(b.suit.index);
        return sc != 0 ? sc : a.rank.index.compareTo(b.rank.index);
      });
    }
    setState(() {});
    if (turn != 0) _scheduleBot();
  }

  void _scheduleBot() {
    if (phase == MatchPhase.matchEnd || phase == MatchPhase.roundEnd) return;
    busy = true;
    Timer(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      busy = false;
      if (phase == MatchPhase.bidding && turn != 0) {
        _botBid();
      } else if (phase == MatchPhase.playing && turn != 0) {
        _botPlay();
      }
    });
  }

  void _botBid() {
    final h = hands[turn];
    final candidate = floorCard?.suit ?? Suit.spades;
    final hokmPow = h
        .where((c) => c.suit == candidate)
        .fold<int>(0, (acc, c) => acc + c.points(PlayMode.hokm, candidate));
    final sunPow = h.fold<int>(
      0,
      (acc, c) => acc + c.points(PlayMode.sun, null),
    );

    if (sunPow >= 24) {
      _chooseBid(turn, PlayMode.sun, null, 'صن');
    } else if (hokmPow >= 20) {
      _chooseBid(turn, PlayMode.hokm, candidate, 'حكم');
    } else {
      _pass(turn);
    }
  }

  void _chooseBid(int seat, PlayMode m, Suit? hSuit, String label) {
    playMode = m;
    hokmSuit = hSuit;
    phase = MatchPhase.playing;
    trick = [];
    turn = (dealerSeat + 1) % 4;
    _sayBubble(seat, label);
    setState(() {});
    if (turn != 0) _scheduleBot();
  }

  void _pass(int seat) {
    passes++;
    _sayBubble(seat, 'بس');
    if (passes >= 4) {
      if (bidRound == 1) {
        bidRound = 2;
        passes = 0;
        turn = (dealerSeat + 1) % 4;
        setState(() {});
        if (turn != 0) _scheduleBot();
      } else {
        Timer(const Duration(milliseconds: 800), () {
          if (mounted) _dealRound(resetMatch: false);
        });
      }
      return;
    }
    turn = (turn + 1) % 4;
    setState(() {});
    if (turn != 0) _scheduleBot();
  }

  List<CardItem> _legalCards(int seat) {
    final h = hands[seat];
    if (trick.isEmpty) return List<CardItem>.from(h);
    final lead = trick.first.$2.suit;
    final sameSuit = h.where((c) => c.suit == lead).toList();
    if (sameSuit.isNotEmpty) return sameSuit;
    if (playMode == PlayMode.hokm && hokmSuit != null && lead != hokmSuit) {
      final trumps = h.where((c) => c.suit == hokmSuit).toList();
      if (trumps.isNotEmpty) return trumps;
    }
    return List<CardItem>.from(h);
  }

  void _botPlay() {
    final legal = _legalCards(turn);
    legal.sort(
      (a, b) => a.power(playMode, hokmSuit).compareTo(b.power(playMode, hokmSuit)),
    );
    _playCard(turn, legal.first);
  }

  void _playCard(int seat, CardItem card) {
    if (phase != MatchPhase.playing || seat != turn) return;
    final legal = _legalCards(seat);
    if (!legal.contains(card)) return;

    hands[seat].remove(card);
    trick.add((seat, card));

    if (trick.length < 4) {
      turn = (turn + 1) % 4;
      setState(() {});
      if (turn != 0) _scheduleBot();
      return;
    }

    final lead = trick.first.$2.suit;
    var win = trick.first;
    for (final item in trick.skip(1)) {
      final iTrump = playMode == PlayMode.hokm && item.$2.suit == hokmSuit;
      final wTrump = playMode == PlayMode.hokm && win.$2.suit == hokmSuit;
      if (iTrump && !wTrump) {
        win = item;
      } else if (iTrump && wTrump) {
        if (item.$2.power(playMode, hokmSuit) >
            win.$2.power(playMode, hokmSuit)) {
          win = item;
        }
      } else if (!wTrump && item.$2.suit == lead) {
        if (item.$2.power(playMode, hokmSuit) >
            win.$2.power(playMode, hokmSuit)) {
          win = item;
        }
      }
    }

    final isLast = hands.every((h) => h.isEmpty);
    final pts = trick.fold<int>(
          0,
          (acc, x) => acc + x.$2.points(playMode, hokmSuit),
        ) +
        (isLast ? 10 : 0);

    if (win.$1 == 0 || win.$1 == 2) {
      usRoundPts += pts;
    } else {
      themRoundPts += pts;
    }

    busy = true;
    setState(() {});
    Timer(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      busy = false;
      trick = [];
      if (isLast) {
        final mult = playMode == PlayMode.sun ? 2 : 1;
        usScore += (usRoundPts / 10).round() * mult;
        themScore += (themRoundPts / 10).round() * mult;
        phase = (usScore >= widget.targetScore || themScore >= widget.targetScore)
            ? MatchPhase.matchEnd
            : MatchPhase.roundEnd;
        setState(() {});
      } else {
        turn = win.$1;
        setState(() {});
        if (turn != 0) _scheduleBot();
      }
    });
  }

  (int, CardItem)? _forSeat(int seat) {
    for (final t in trick) {
      if (t.$1 == seat) return t;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final legal =
        (phase == MatchPhase.playing && turn == 0) ? _legalCards(0) : <CardItem>[];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF3E2A19),
        body: SafeArea(
          child: Column(
            children: [
              _buildMatchTopBar(),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Stack(
                    children: [
                      Column(
                        children: [
                          _buildTopPlayer(2),
                          Expanded(
                            child: Row(
                              children: [
                                _buildSidePlayer(3),
                                Expanded(child: _buildLeatherTable()),
                                _buildSidePlayer(1),
                              ],
                            ),
                          ),
                          if (phase == MatchPhase.bidding && turn == 0 && !busy)
                            _buildBidRow(),
                          if (phase == MatchPhase.roundEnd)
                            FilledButton(
                              onPressed: () => _dealRound(resetMatch: false),
                              child: const Text('الجولة التالية'),
                            ),
                          if (phase == MatchPhase.matchEnd)
                            FilledButton(
                              onPressed: () => _dealRound(resetMatch: true),
                              child: const Text('صك جديد'),
                            ),
                          if (phase == MatchPhase.playing) _buildProjectRow(),
                          _buildBottomHand(legal),
                        ],
                      ),
                      Positioned(
                        left: 6,
                        bottom: 128,
                        child: Column(
                          children: [
                            _callButton('سوا', () => _sayBubble(0, 'سوا')),
                            const SizedBox(height: 6),
                            _callButton('قدها', () => _sayBubble(0, 'قدها')),
                            const SizedBox(height: 6),
                            CircleAvatar(
                              radius: 17,
                              backgroundColor: const Color(0xFFD5A949),
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                icon: const Icon(
                                  Icons.chat_bubble,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                onPressed: () => _sayBubble(0, 'كفو'),
                              ),
                            ),
                          ],
                        ),
                      ),
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

  Widget _buildMatchTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.of(context).pop(),
            child: const CircleAvatar(
              radius: 15,
              backgroundColor: Colors.black38,
              child: Icon(
                Icons.arrow_forward,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            widget.roomTitle,
            style: const TextStyle(color: Colors.white70, fontSize: 11.5),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF4A311D),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFD5A949)),
            ),
            child: Row(
              children: [
                Text(
                  '$usScore',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    'لنا  :  لهم',
                    style: TextStyle(
                      color: Color(0xFFF7D774),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                Text(
                  '$themScore',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          const Text(
            '20:34',
            style: TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildTopPlayer(int seat) {
    return Column(
      children: [
        if (bubbles[seat] != null) _bubbleWidget(bubbles[seat]!),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _avatarCircle(seat),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  names[seat],
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11.5,
                  ),
                ),
                const Text(
                  'متوسط • ♠ ♥ ♣ ♦',
                  style: TextStyle(color: Colors.white70, fontSize: 9.5),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Text(
              '$usRoundPts',
              style: const TextStyle(
                color: Color(0xFFF7D774),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSidePlayer(int seat) {
    return SizedBox(
      width: 78,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (bubbles[seat] != null) _bubbleWidget(bubbles[seat]!),
          _avatarCircle(seat),
          const SizedBox(height: 3),
          Text(
            names[seat],
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 10.5,
            ),
          ),
          const Text(
            'متوسط',
            style: TextStyle(color: Colors.white60, fontSize: 9.5),
          ),
          if (seat == 1)
            Text(
              '$themRoundPts',
              style: const TextStyle(
                color: Color(0xFFF7D774),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
        ],
      ),
    );
  }

  Widget _avatarCircle(int seat) {
    final isDealer = dealerSeat == seat;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: turn == seat
              ? const Color(0xFFE6B84C)
              : const Color(0xFF2B4C3B),
          child: const Icon(Icons.person, color: Colors.white, size: 24),
        ),
        if (isDealer)
          Positioned(
            right: -6,
            bottom: -2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'الموزّع',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 8.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _bubbleWidget(String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 3),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF2D1D0E),
          fontWeight: FontWeight.bold,
          fontSize: 10.5,
        ),
      ),
    );
  }

  Widget _buildLeatherTable() {
    final topC = _forSeat(2);
    final rightC = _forSeat(1);
    final leftC = _forSeat(3);
    final botC = _forSeat(0);

    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF1D2024),
        borderRadius: BorderRadius.circular(56),
        border: Border.all(color: const Color(0xFF6B5338), width: 5),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Text(
            'بلوت',
            style: TextStyle(
              color: Colors.white12,
              fontSize: 34,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (trick.isEmpty && phase == MatchPhase.bidding && floorCard != null)
            _playingCardWidget(floorCard!, small: true, onTap: null),
          if (topC != null)
            Positioned(
              top: 12,
              child: _playingCardWidget(topC.$2, small: true, onTap: null),
            ),
          if (botC != null)
            Positioned(
              bottom: 12,
              child: _playingCardWidget(botC.$2, small: true, onTap: null),
            ),
          if (leftC != null)
            Positioned(
              left: 16,
              child: _playingCardWidget(leftC.$2, small: true, onTap: null),
            ),
          if (rightC != null)
            Positioned(
              right: 16,
              child: _playingCardWidget(rightC.$2, small: true, onTap: null),
            ),
        ],
      ),
    );
  }

  Widget _buildBidRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _bidBtn('بس', const Color(0xFFD99B26), () => _pass(0)),
          const SizedBox(width: 8),
          _bidBtn(
            'أشكل',
            const Color(0xFFE0A42E),
            () => _chooseBid(0, PlayMode.hokm, Suit.hearts, 'أشكل'),
          ),
          const SizedBox(width: 8),
          _bidBtn(
            'حكم',
            const Color(0xFFE5AC35),
            () => _chooseBid(
              0,
              PlayMode.hokm,
              floorCard?.suit ?? Suit.spades,
              'حكم',
            ),
          ),
          const SizedBox(width: 8),
          _bidBtn(
            'ص',
            const Color(0xFFEBB63E),
            () => _chooseBid(0, PlayMode.sun, null, 'صن'),
          ),
        ],
      ),
    );
  }

  Widget _bidBtn(String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFFFE599)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xFF3E2405),
            fontWeight: FontWeight.w900,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildProjectRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _projChip('سرا | $seraCount', () {
            setState(() => seraCount++);
            _sayBubble(0, 'سرا');
          }),
          const SizedBox(width: 6),
          _projChip('50 | $fiftyCount', () {
            setState(() => fiftyCount++);
            _sayBubble(0, 'خمسين');
          }),
          const SizedBox(width: 6),
          _projChip('100 | $hundredCount', () {
            setState(() => hundredCount++);
            _sayBubble(0, 'مئة');
          }),
          const SizedBox(width: 6),
          _projChip('400 | $fourHundredCount', () {
            setState(() => fourHundredCount++);
            _sayBubble(0, 'أربعمئة');
          }),
        ],
      ),
    );
  }

  Widget _projChip(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFF4B331D),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFD5A949)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xFFF7D774),
            fontSize: 10.5,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _callButton(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF4D341E),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFD5A949)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xFFF7D774),
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomHand(List<CardItem> legal) {
    final myHand = hands[0];
    final canPlay = phase == MatchPhase.playing && turn == 0 && !busy;

    return SizedBox(
      height: 82,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: myHand.map((c) {
            final ok = !canPlay || legal.contains(c);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: _playingCardWidget(
                c,
                small: false,
                dimmed: !ok,
                onTap: canPlay && ok ? () => _playCard(0, c) : null,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _playingCardWidget(
    CardItem card, {
    required bool small,
    bool dimmed = false,
    VoidCallback? onTap,
  }) {
    final w = small ? 42.0 : 54.0;
    final h = small ? 60.0 : 78.0;
    final col = card.isRed ? const Color(0xFFC62828) : const Color(0xFF1A1D20);

    return Opacity(
      opacity: dimmed ? 0.35 : 1.0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: const Color(0xFFFFFDF8),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFB89656), width: 1.2),
            boxShadow: const [
              BoxShadow(
                color: Colors.black45,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(3),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    card.rankText,
                    style: TextStyle(
                      color: col,
                      fontWeight: FontWeight.w900,
                      fontSize: small ? 10 : 12,
                      height: 1.0,
                    ),
                  ),
                  Text(
                    card.suit.symbol,
                    style: TextStyle(
                      color: col,
                      fontSize: small ? 9 : 11,
                      height: 1.0,
                    ),
                  ),
                ],
              ),
              Text(
                card.suit.symbol,
                style: TextStyle(
                  color: col,
                  fontSize: small ? 18 : 24,
                  height: 1.0,
                ),
              ),
              Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  card.rankText,
                  style: TextStyle(
                    color: col,
                    fontWeight: FontWeight.bold,
                    fontSize: small ? 8.5 : 10,
                    height: 1.0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
