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

class MajlisScenePainter extends CustomPainter {
  const MajlisScenePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final wallPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFB59A76),
          Color(0xFF947753),
          Color(0xFF6B5032),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), wallPaint);

    final lampGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFE6A3).withValues(alpha: 0.34),
          const Color(0xFFFFE6A3).withValues(alpha: 0.0),
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.5, size.height * 0.14),
          radius: size.width * 0.36,
        ),
      );
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.14),
      size.width * 0.36,
      lampGlow,
    );

    final floorPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF8C6B46), Color(0xFF5A3F23)],
      ).createShader(
        Rect.fromLTWH(0, size.height * 0.62, size.width, size.height * 0.38),
      );
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.62, size.width, size.height * 0.38),
      floorPaint,
    );

    final rugPaint = Paint()..color = const Color(0xFFC7A87C);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.24,
          size.height * 0.65,
          size.width * 0.52,
          size.height * 0.27,
        ),
        const Radius.circular(14),
      ),
      rugPaint,
    );

    final sofaPaint = Paint()..color = const Color(0xFF7B5A38);
    final cushionPaint = Paint()..color = const Color(0xFF9A7750);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.16,
          size.height * 0.44,
          size.width * 0.11,
          size.height * 0.24,
        ),
        const Radius.circular(10),
      ),
      sofaPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.18,
          size.height * 0.47,
          size.width * 0.07,
          size.height * 0.17,
        ),
        const Radius.circular(8),
      ),
      cushionPaint,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.73,
          size.height * 0.44,
          size.width * 0.11,
          size.height * 0.24,
        ),
        const Radius.circular(10),
      ),
      sofaPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.75,
          size.height * 0.47,
          size.width * 0.07,
          size.height * 0.17,
        ),
        const Radius.circular(8),
      ),
      cushionPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class TimerRingPainter extends CustomPainter {
  final double progress;
  final Color color;

  const TimerRingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (min(size.width, size.height) / 2) - 2.2;

    final bgPaint = Paint()
      ..color = Colors.black38
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2;
    canvas.drawCircle(center, radius, bgPaint);

    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.4
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress.clamp(0.0, 1.0),
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant TimerRingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
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
  bool isVip = false;
  String? clubName;
  int ammoCount = 23;
  int weeklyInteraction = 0;
  int dailyInteraction = 0;
  int tickerIndex = 0;
  Timer? _tickerTimer;

  bool oldSound = true;
  bool musicOn = false;
  bool sRewardOn = true;

  final List<String> friendsList = [
    'الزهراني',
    '2409BRN2CA',
    'h917',
    'iPhone13,2',
  ];
  final List<String> followingList = ['المحماد..', 'عز'];
  final List<String> followersList = ['أبو سعد', 'رياض'];
  final List<String> mailItems = [
    'هدية تسجيل الدخول اليومي: 500 ذهب',
    'مكافأة فعالية ليلة الكشتة: 1200 ذهب',
  ];
  final List<String> transferHistory = [];

  final List<bool> taskDone = [true, true, false, false];
  final List<bool> taskClaimed = [false, false, false, false];
  final List<bool> kashtaClaimed = [false, false, false];

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

  void _showNotice(String msg) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, textDirection: TextDirection.rtl),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _openProfileEditDialog() {
    final ctrl = TextEditingController(text: playerName);
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: const Color(0xFFF6EBD2),
            title: const Text('ملف اللاعب'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('المستوى: $playerLevel • الذهب: $goldBalance'),
                const SizedBox(height: 10),
                TextField(
                  controller: ctrl,
                  decoration: const InputDecoration(
                    labelText: 'تغيير الاسم',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('إلغاء'),
              ),
              FilledButton(
                onPressed: () {
                  final n = ctrl.text.trim();
                  if (n.isNotEmpty) {
                    setState(() => playerName = n);
                    _showNotice('تم تحديث الاسم إلى $n');
                  }
                  Navigator.of(ctx).pop();
                },
                child: const Text('حفظ'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openVipDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: const Color(0xFFF6EBD2),
            title: const Text('إشتراك VIP'),
            content: Text(
              isVip
                  ? 'اشتراك VIP مفعّل حالياً على حسابك ($playerName).'
                  : 'تفعيل اشتراك VIP يمنحك خصم 15% على الإهداء وشارة مميزة مقابل 1000 ذهب.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('إغلاق'),
              ),
              if (!isVip)
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFD5A949),
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () {
                    if (goldBalance >= 1000) {
                      setState(() {
                        goldBalance -= 1000;
                        isVip = true;
                        playerLevel++;
                      });
                      _showNotice('تم تفعيل VIP بنجاح');
                    } else {
                      _showNotice('رصيد الذهب غير كافٍ');
                    }
                    Navigator.of(ctx).pop();
                  },
                  child: const Text('تفعيل (1000)'),
                ),
            ],
          ),
        );
      },
    );
  }

  void _openClubDialog() {
    final ctrl = TextEditingController(text: clubName ?? '');
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: const Color(0xFFF6EBD2),
            title: Text(clubName == null ? 'الانضمام لنادٍ' : 'نادي: $clubName'),
            content: TextField(
              controller: ctrl,
              decoration: const InputDecoration(
                hintText: 'اكتب اسم النادي للانضمام أو الإنشاء',
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              if (clubName != null)
                TextButton(
                  onPressed: () {
                    setState(() => clubName = null);
                    _showNotice('تمت مغادرة النادي');
                    Navigator.of(ctx).pop();
                  },
                  child: const Text('مغادرة'),
                ),
              FilledButton(
                onPressed: () {
                  final c = ctrl.text.trim();
                  if (c.isNotEmpty) {
                    setState(() => clubName = c);
                    _showNotice('أصبحت عضواً في نادي $c');
                  }
                  Navigator.of(ctx).pop();
                },
                child: const Text('تأكيد'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openLeaderboardDialog(int highlightedRank) {
    const leaders = [
      (1, 'سلطان نجد', '18,420'),
      (2, 'أبو فهد', '15,910'),
      (3, 'صقر الشمال', '14,250'),
    ];
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: const Color(0xFFF6EBD2),
            title: const Text('المتصدّرين'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: leaders.map((l) {
                final active = l.$1 == highlightedRank;
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 3),
                  decoration: BoxDecoration(
                    color: active ? const Color(0xFFE6CF9A) : Colors.white60,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      radius: 13,
                      child: Text('${l.$1}'),
                    ),
                    title: Text(l.$2),
                    trailing: Text(l.$3),
                  ),
                );
              }).toList(),
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('حسناً'),
              ),
            ],
          ),
        );
      },
    );
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
                      InkWell(
                        onTap: () {
                          final hist = transferHistory.isEmpty
                              ? 'لا توجد عمليات إرسال بعد'
                              : transferHistory.join('\n');
                          _showNotice(hist);
                        },
                        child: Container(
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
                  Text(
                    isVip
                        ? 'ميزة VIP لتقليل الرسوم: الخصم الإضافي للخصم عند الإهداء 15% : 15%'
                        : 'ميزة VIP لتقليل الرسوم: الخصم الإضافي للخصم عند الإهداء 15% : 0%',
                    style: const TextStyle(color: Color(0xFF6E4C1B), fontSize: 11),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      InkWell(
                        onTap: () {
                          Navigator.of(ctx).pop();
                          _openVipDialog();
                        },
                        child: Container(
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
                      ),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF69B347),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          final target = friendCtrl.text.trim().isEmpty
                              ? 'صديق'
                              : friendCtrl.text.trim();
                          final val = int.tryParse(amountCtrl.text.trim()) ?? 0;
                          if (val <= 0) {
                            _showNotice('أدخل عدداً صحيحاً للذهب');
                            return;
                          }
                          if (val > goldBalance) {
                            _showNotice('الرصيد غير كافٍ');
                            return;
                          }
                          setState(() {
                            goldBalance -= val;
                            transferHistory.add('أرسلت $val إلى $target');
                          });
                          _showNotice('تم إرسال $val ذهب إلى $target');
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

  void _openBagDialog() {
    var selectedTab = 0;
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
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'الشنطة',
                            style: TextStyle(
                              color: Color(0xFF4A2E08),
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Row(
                            children: [
                              ChoiceChip(
                                label: const Text('الكل'),
                                selected: selectedTab == 0,
                                onSelected: (_) => setD(() => selectedTab = 0),
                              ),
                              const SizedBox(width: 4),
                              ChoiceChip(
                                label: const Text('ذخيرة'),
                                selected: selectedTab == 1,
                                onSelected: (_) => setD(() => selectedTab = 1),
                              ),
                            ],
                          ),
                          InkWell(
                            onTap: () => Navigator.of(ctx).pop(),
                            child: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Container(
                            width: 96,
                            height: 112,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEDE0C4),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFD5A949),
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.inventory_2,
                                  color: Color(0xFF4E8D47),
                                  size: 40,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '$ammoCount',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'ذخيرة مجانية لحصر الصيد',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Color(0xFF4A2E08),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'يمكن استخدامها في صيد مستوى مبتدئ والحصول على مكافأة ذهب فورية.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                FilledButton(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFF69B347),
                                  ),
                                  onPressed: () {
                                    if (ammoCount > 0) {
                                      setState(() {
                                        ammoCount--;
                                        goldBalance += 150;
                                      });
                                      setD(() {});
                                      _showNotice(
                                        'تم استخدام ذخيرة وحصلت على +150 ذهب',
                                      );
                                    } else {
                                      _showNotice('لا توجد ذخيرة متبقية');
                                    }
                                  },
                                  child: const Text('إستخدام'),
                                ),
                              ],
                            ),
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
      },
    );
  }

  void _openTasksDialog() {
    var tabIndex = 0;
    const titles = [
      'تسجيل دخول تراكمي 1 يوم',
      'اختيار مشروع 100 لـ 3 مرة في جلسة',
      'تسجيل دخول تراكمي 5 يوم',
      'شحن 1 مرة',
    ];
    const badges = [
      'التفاعل 20',
      'التفاعل 40',
      'التفاعل 50',
      'التفاعل 60',
    ];
    const rewards = [200, 300, 400, 500];

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
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              ChoiceChip(
                                label: const Text('مهام التفاعل'),
                                selected: tabIndex == 0,
                                onSelected: (_) => setD(() => tabIndex = 0),
                              ),
                              const SizedBox(width: 6),
                              ChoiceChip(
                                label: const Text('مهام النادي'),
                                selected: tabIndex == 1,
                                onSelected: (_) => setD(() => tabIndex = 1),
                              ),
                            ],
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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'تفاعل هذا الأسبوع: $weeklyInteraction',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12.5,
                                  ),
                                ),
                                Text(
                                  'تفاعل اليوم: $dailyInteraction',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ...List.generate(titles.length, (i) {
                              final canClaim = taskDone[i] && !taskClaimed[i];
                              final label = taskClaimed[i]
                                  ? 'تم الاستلام'
                                  : (taskDone[i] ? 'إستلام' : 'أكمل المهمة');
                              return InkWell(
                                onTap: () {
                                  if (canClaim) {
                                    setState(() {
                                      taskClaimed[i] = true;
                                      goldBalance += rewards[i];
                                      dailyInteraction += 20;
                                      weeklyInteraction += 20;
                                    });
                                    setD(() {});
                                    _showNotice(
                                      'تم استلام +${rewards[i]} ذهب',
                                    );
                                  } else if (!taskDone[i]) {
                                    setState(() {
                                      taskDone[i] = true;
                                    });
                                    setD(() {});
                                    _showNotice('تم إكمال المهمة، اضغط إستلام');
                                  }
                                },
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF9F1E1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              tabIndex == 1
                                                  ? '${titles[i]} (النادي)'
                                                  : titles[i],
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                            Text(
                                              badges[i],
                                              style: const TextStyle(
                                                color: Color(0xFFD96B27),
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: taskClaimed[i]
                                              ? Colors.grey
                                              : (taskDone[i]
                                                  ? const Color(0xFF69B347)
                                                  : const Color(0xFF6AA6C8)),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          label,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
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
      },
    );
  }

  void _openFriendsDrawer() {
    var tab = 0;
    final addCtrl = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFF6EBD2),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setM) {
            final currentList = tab == 0
                ? friendsList
                : (tab == 1 ? followingList : followersList);
            return Directionality(
              textDirection: TextDirection.rtl,
              child: Padding(
                padding: EdgeInsets.only(
                  left: 14,
                  right: 14,
                  top: 14,
                  bottom: MediaQuery.of(ctx).viewInsets.bottom + 14,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        ChoiceChip(
                          label: Text('الأصدقاء (${friendsList.length})'),
                          selected: tab == 0,
                          onSelected: (_) => setM(() => tab = 0),
                        ),
                        const SizedBox(width: 6),
                        ChoiceChip(
                          label: Text('متابَعيني (${followingList.length})'),
                          selected: tab == 1,
                          onSelected: (_) => setM(() => tab = 1),
                        ),
                        const SizedBox(width: 6),
                        ChoiceChip(
                          label: Text('متابِعيني (${followersList.length})'),
                          selected: tab == 2,
                          onSelected: (_) => setM(() => tab = 2),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: addCtrl,
                            decoration: const InputDecoration(
                              hintText: 'إضافة صديق بالاسم',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: () {
                            final name = addCtrl.text.trim();
                            if (name.isNotEmpty) {
                              setState(() {
                                friendsList.insert(0, name);
                              });
                              setM(() {});
                              addCtrl.clear();
                              _showNotice('تمت إضافة $name إلى الأصدقاء');
                            }
                          },
                          child: const Text('إضافة صديق'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...currentList.map(
                      (person) => ListTile(
                        dense: true,
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFF1D6B43),
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                        title: Text(
                          person,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: const Text('متوسط • متصل'),
                        trailing: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF69B347),
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                          ),
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => BalootMatchScreen(
                                  playerName: playerName,
                                  partnerName: person,
                                  rightOpponentName: 'عز',
                                  leftOpponentName: 'iPhone1..',
                                  targetScore: 152,
                                  roomTitle: 'جلسة مع $person',
                                ),
                              ),
                            );
                          },
                          child: const Text(
                            'إذهب للدردشة',
                            style: TextStyle(fontSize: 11),
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
      },
    );
  }

  void _openMailDialog() {
    var mailTab = 0;
    const mailTabs = ['رسائل النظام', 'رسائل اللاعب', 'بريد الهدايا', 'الألبوم'];
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
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'البريد — ${mailTabs[mailTab]}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Color(0xFF4A2E08),
                            ),
                          ),
                          InkWell(
                            onTap: () => Navigator.of(ctx).pop(),
                            child: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 4,
                        children: List.generate(
                          mailTabs.length,
                          (i) => ChoiceChip(
                            label: Text(
                              mailTabs[i],
                              style: const TextStyle(fontSize: 10.5),
                            ),
                            selected: mailTab == i,
                            onSelected: (_) => setD(() => mailTab = i),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (mailItems.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          child: Text(
                            'لا توجد رسائل حالياً • يتم حفظ الرسالة لمدة 7 أيام',
                            style: TextStyle(color: Colors.black54, fontSize: 12),
                          ),
                        )
                      else
                        ...mailItems.map(
                          (m) => ListTile(
                            dense: true,
                            leading: const Icon(
                              Icons.mail_outline,
                              color: Color(0xFF4A2E08),
                            ),
                            title: Text(
                              m,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF69B347),
                            ),
                            onPressed: () {
                              if (mailItems.isNotEmpty) {
                                final bonus = mailItems.length * 500;
                                setState(() {
                                  goldBalance += bonus;
                                  mailItems.clear();
                                });
                                setD(() {});
                                _showNotice('تم استلام +$bonus ذهب');
                              } else {
                                _showNotice('لا توجد جوائز للاستلام');
                              }
                            },
                            child: const Text('إستلام الكل'),
                          ),
                          const SizedBox(width: 10),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFD96B27),
                            ),
                            onPressed: () {
                              setState(() => mailItems.clear());
                              setD(() {});
                              _showNotice('تم حذف جميع الرسائل');
                            },
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
      },
    );
  }

  void _openSettingsDialog() {
    var bottomTab = 0;
    const bottomLabels = [
      'تقديم',
      'منع الحساب',
      'تغييرات',
      'معاينة الحساب',
      'الكلام',
      'الحساب رسمي',
    ];
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
                  padding: const EdgeInsets.all(14),
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
                      const SizedBox(height: 8),
                      SwitchListTile(
                        dense: true,
                        title: const Text('الصوت القديم'),
                        value: oldSound,
                        onChanged: (v) {
                          setState(() => oldSound = v);
                          setD(() {});
                        },
                      ),
                      SwitchListTile(
                        dense: true,
                        title: const Text('موسيقى'),
                        value: musicOn,
                        onChanged: (v) {
                          setState(() => musicOn = v);
                          setD(() {});
                        },
                      ),
                      SwitchListTile(
                        dense: true,
                        title: const Text('ص'),
                        subtitle: const Text('يمكنك الحصول على جائزة ذهب'),
                        value: sRewardOn,
                        onChanged: (v) {
                          setState(() => sRewardOn = v);
                          setD(() {});
                        },
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        alignment: WrapAlignment.center,
                        children: List.generate(
                          bottomLabels.length,
                          (i) => ChoiceChip(
                            label: Text(
                              bottomLabels[i],
                              style: const TextStyle(fontSize: 10),
                            ),
                            selected: bottomTab == i,
                            onSelected: (_) => setD(() => bottomTab = i),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${bottomLabels[bottomTab]}: الحالة نشطة وجاهزة على حساب $playerName',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF5A3B0C),
                        ),
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
    const boxLabels = [
      'صندوق الكشتة A (3500/5000)',
      'صندوق الكشتة B (30000/60000)',
      'صندوق الكبار (250000/500000)',
    ];
    const boxRewards = [250, 600, 1500];

    showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setD) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: Dialog(
                backgroundColor: const Color(0xFF283A4E),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: const BorderSide(color: Color(0xFFD5A949), width: 2),
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
                      ...List.generate(boxLabels.length, (i) {
                        final claimed = kashtaClaimed[i];
                        return ListTile(
                          dense: true,
                          title: Text(
                            boxLabels[i],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                          trailing: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: claimed
                                  ? Colors.grey
                                  : const Color(0xFF69B347),
                            ),
                            onPressed: claimed
                                ? null
                                : () {
                                    setState(() {
                                      kashtaClaimed[i] = true;
                                      goldBalance += boxRewards[i];
                                    });
                                    setD(() {});
                                    _showNotice(
                                      'تم استلام +${boxRewards[i]} ذهب من ليلة الكشتة',
                                    );
                                  },
                            child: Text(
                              claimed ? 'تم' : 'استلام +${boxRewards[i]}',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                        );
                      }),
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

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: CustomPaint(
          painter: const MajlisScenePainter(),
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
          InkWell(
            onTap: _openVipDialog,
            borderRadius: BorderRadius.circular(18),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isVip ? const Color(0xFF5A3E0A) : Colors.black45,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFD5A949)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.workspace_premium,
                    color: Color(0xFFF7D774),
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isVip ? 'VIP نشط' : 'إشتراك VIP',
                    style: const TextStyle(
                      color: Color(0xFFF7D774),
                      fontWeight: FontWeight.bold,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
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
                InkWell(
                  onTap: _openGoldSendDialog,
                  child: Text(
                    '$goldBalance',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
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
          const SizedBox(width: 8),
          InkWell(
            onTap: _openBagDialog,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white24),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.backpack,
                    color: Color(0xFFE6B84C),
                    size: 15,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    'الشنطة ($ammoCount)',
                    style: const TextStyle(color: Colors.white, fontSize: 10.5),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          InkWell(
            onTap: _openProfileEditDialog,
            child: Row(
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
                    Text(
                      '$goldBalance',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10.5,
                      ),
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
                    border: Border.all(
                      color: const Color(0xFFD5A949),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(Icons.person, color: Colors.white),
                ),
              ],
            ),
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
          InkWell(
            onTap: () => _openLeaderboardDialog(1),
            child: Container(
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _LeaderBadge(
                    rankText: '1',
                    accent: const Color(0xFFFFD54F),
                    onTap: () => _openLeaderboardDialog(1),
                  ),
                  _LeaderBadge(
                    rankText: '2',
                    accent: const Color(0xFFE0E0E0),
                    onTap: () => _openLeaderboardDialog(2),
                  ),
                  _LeaderBadge(
                    rankText: '3',
                    accent: const Color(0xFFBCAAA4),
                    onTap: () => _openLeaderboardDialog(3),
                  ),
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
        color: Colors.black26,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x88F7D774)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          InkWell(
            onTap: _openClubDialog,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 112,
              height: 112,
              decoration: BoxDecoration(
                color: const Color(0xFF3E4E5E).withValues(alpha: 0.78),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFD5A949), width: 1.8),
              ),
              child: Center(
                child: clubName == null
                    ? const Icon(Icons.add, color: Colors.white, size: 38)
                    : Text(
                        clubName!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black45,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              clubName == null
                  ? 'لم تنضم لنادٍ بعد\nبعد الانضمام إلى النادي يمكنك الحصول على مزايا إضافية مثل فرص كنز الإخلاص'
                  : 'عضو في نادي: $clubName • مزايا النادي مفعّلة',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 10.5),
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
                                  initialTabIndex: 0,
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
                                  initialTabIndex: 3,
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
                                  initialTabIndex: 2,
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
                    initialTabIndex: 2,
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
  final VoidCallback onTap;

  const _LeaderBadge({
    required this.rankText,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
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
                              builder: (_) => VsSplashScreen(
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
  final int initialTabIndex;

  const MoreGamesScreen({
    super.key,
    required this.playerName,
    required this.goldBalance,
    this.initialTabIndex = 2,
  });

  @override
  Widget build(BuildContext context) {
    const items = [
      ('الجلسات', Icons.chair_alt, Color(0xFFD99B38), 'جلسة خاصة'),
      ('ربح مجاناً', Icons.emoji_events, Color(0xFFC75B2A), 'ربح مجاناً'),
      ('سلم التحدّي', Icons.military_tech, Color(0xFFD49A2A), 'سلم التحدّي'),
      ('دوري المحترفين', Icons.workspace_premium, Color(0xFF3E6F9E), 'دوري المحترفين'),
      ('صكّة سريعة', Icons.style, Color(0xFF289A63), 'صكّة سريعة'),
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
                      Text(
                        items[initialTabIndex].$1,
                        style: const TextStyle(
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
                          if (it.$1 == 'صكّة سريعة') {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (_) => VsSplashScreen(
                                  playerName: playerName,
                                  partnerName: 'المحماد..',
                                  rightOpponentName: 'عز',
                                  leftOpponentName: 'iPhone1..',
                                  targetScore: 152,
                                  roomTitle: 'صكّة سريعة',
                                ),
                              ),
                            );
                          } else {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (_) => LadderChallengeScreen(
                                  playerName: playerName,
                                  goldBalance: goldBalance,
                                  modeTitle: it.$4,
                                ),
                              ),
                            );
                          }
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
  final String modeTitle;

  const LadderChallengeScreen({
    super.key,
    required this.playerName,
    required this.goldBalance,
    this.modeTitle = 'سلم التحدّي',
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
            builder: (_) => VsSplashScreen(
              playerName: widget.playerName,
              partnerName: 'المحماد..',
              rightOpponentName: 'عز',
              leftOpponentName: 'iPhone1..',
              targetScore: 152,
              roomTitle: widget.modeTitle,
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
                      Text(
                        widget.modeTitle,
                        style: const TextStyle(
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
                    SizedBox(
                      width: 142,
                      height: 158,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (isSearching)
                            SizedBox(
                              width: 138,
                              height: 138,
                              child: CustomPaint(
                                painter: TimerRingPainter(
                                  progress: (seconds % 10) / 10.0,
                                  color: const Color(0xFFF7D774),
                                ),
                              ),
                            ),
                          Container(
                            width: 116,
                            height: 132,
                            decoration: BoxDecoration(
                              color: const Color(0xFF6B8BAE),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: const Color(0xFFF7D774),
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                isSearching
                                    ? Icons.emoji_events_rounded
                                    : Icons.shield_rounded,
                                color: Colors.white,
                                size: 62,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
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

class VsSplashScreen extends StatefulWidget {
  final String playerName;
  final String partnerName;
  final String rightOpponentName;
  final String leftOpponentName;
  final int targetScore;
  final String roomTitle;

  const VsSplashScreen({
    super.key,
    required this.playerName,
    required this.partnerName,
    required this.rightOpponentName,
    required this.leftOpponentName,
    required this.targetScore,
    required this.roomTitle,
  });

  @override
  State<VsSplashScreen> createState() => _VsSplashScreenState();
}

class _VsSplashScreenState extends State<VsSplashScreen> {
  Timer? _navTimer;

  @override
  void initState() {
    super.initState();
    _navTimer = Timer(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => BalootMatchScreen(
            playerName: widget.playerName,
            partnerName: widget.partnerName,
            rightOpponentName: widget.rightOpponentName,
            leftOpponentName: widget.leftOpponentName,
            targetScore: widget.targetScore,
            roomTitle: widget.roomTitle,
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    _navTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF1F1711),
        body: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFD5A949), width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _vsPlayerCard(widget.rightOpponentName, 'متقدم', true),
                _vsPlayerCard(widget.leftOpponentName, 'متقدم', true),
                const Text(
                  'VS',
                  style: TextStyle(
                    color: Color(0xFFF7D774),
                    fontWeight: FontWeight.w900,
                    fontSize: 30,
                  ),
                ),
                _vsPlayerCard(widget.partnerName, 'متوسط', false),
                _vsPlayerCard(widget.playerName, 'متقدم', false),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _vsPlayerCard(String name, String rankLabel, bool isOpponent) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 26,
          backgroundColor:
              isOpponent ? const Color(0xFF8D3B2B) : const Color(0xFF2B6E4C),
          child: const Icon(Icons.person, color: Colors.white, size: 28),
        ),
        const SizedBox(height: 6),
        Text(
          name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white12,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            rankLabel,
            style: const TextStyle(color: Color(0xFFF7D774), fontSize: 10),
          ),
        ),
      ],
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
  int turnSeconds = 10;
  Timer? _turnTimer;

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

  String onlineRoomCode = 'BAH77';
  String onlineStatus = 'جاهز للربط';
  final List<ChatMessageItem> tableMessages = [];

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

  @override
  void dispose() {
    _turnTimer?.cancel();
    super.dispose();
  }

  void _openTableChatDialog() {
    final msgCtrl = TextEditingController();
    final roomCtrl = TextEditingController(text: onlineRoomCode);
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setD) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                backgroundColor: const Color(0xFFF6EBD2),
                title: const Text('دردشة الطاولة والغرفة'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: roomCtrl,
                              decoration: const InputDecoration(
                                labelText: 'رمز الغرفة',
                                isDense: true,
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          FilledButton(
                            onPressed: () async {
                              try {
                                final st = await OnlineRoomService.instance
                                    .createOrJoinRoom(
                                  roomCtrl.text,
                                  widget.playerName,
                                );
                                final fetched = await OnlineRoomService.instance
                                    .fetchRoomMessages(roomCtrl.text);
                                setState(() {
                                  onlineRoomCode =
                                      roomCtrl.text.trim().toUpperCase();
                                  onlineStatus = st;
                                  if (fetched.isNotEmpty) {
                                    tableMessages
                                      ..clear()
                                      ..addAll(fetched);
                                  }
                                });
                                setD(() {});
                              } catch (e) {
                                setState(() => onlineStatus = '$e');
                                setD(() {});
                              }
                            },
                            child: const Text('ربط'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        onlineStatus,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF4A2E08),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...tableMessages.map(
                        (m) => Align(
                          alignment: Alignment.centerRight,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 2),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white70,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${m.sender}: ${m.text}',
                              style: const TextStyle(fontSize: 11.5),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: msgCtrl,
                              decoration: const InputDecoration(
                                hintText: 'اكتب رسالة للطاولة',
                                isDense: true,
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          FilledButton(
                            onPressed: () async {
                              final txt = msgCtrl.text.trim();
                              if (txt.isEmpty) return;
                              final item = ChatMessageItem(
                                sender: widget.playerName,
                                text: txt,
                              );
                              setState(() {
                                tableMessages.add(item);
                              });
                              _sayBubble(0, txt);
                              msgCtrl.clear();
                              setD(() {});
                              await OnlineRoomService.instance.sendRoomMessage(
                                roomCode: onlineRoomCode,
                                sender: widget.playerName,
                                text: txt,
                                isQuickCall: false,
                              );
                            },
                            child: const Text('إرسال'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('إغلاق'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _startTurnClock() {
    _turnTimer?.cancel();
    turnSeconds = 10;
    _turnTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (turnSeconds > 1) {
        setState(() => turnSeconds--);
      } else {
        setState(() => turnSeconds = 10);
      }
    });
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
    _startTurnClock();
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
    _startTurnClock();
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
        _startTurnClock();
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
    _startTurnClock();
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
      _startTurnClock();
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
        _startTurnClock();
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
                                onPressed: _openTableChatDialog,
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
    final isTurn = turn == seat;
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 52,
          height: 52,
          child: isTurn
              ? CustomPaint(
                  painter: TimerRingPainter(
                    progress: turnSeconds / 10.0,
                    color: const Color(0xFF4CAF50),
                  ),
                )
              : const SizedBox.shrink(),
        ),
        CircleAvatar(
          radius: 21,
          backgroundColor:
              isTurn ? const Color(0xFFE6B84C) : const Color(0xFF2B4C3B),
          child: const Icon(Icons.person, color: Colors.white, size: 23),
        ),
        if (isTurn)
          Positioned(
            top: -4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: const Color(0xFF388E3C),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${turnSeconds}s',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
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
            setState(() {
              seraCount++;
              usRoundPts += 2;
            });
            _sayBubble(0, 'سرا');
          }),
          const SizedBox(width: 6),
          _projChip('50 | $fiftyCount', () {
            setState(() {
              fiftyCount++;
              usRoundPts += 5;
            });
            _sayBubble(0, 'خمسين');
          }),
          const SizedBox(width: 6),
          _projChip('100 | $hundredCount', () {
            setState(() {
              hundredCount++;
              usRoundPts += 10;
            });
            _sayBubble(0, 'مئة');
          }),
          const SizedBox(width: 6),
          _projChip('400 | $fourHundredCount', () {
            setState(() {
              fourHundredCount++;
              usRoundPts += 40;
            });
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
    final count = myHand.length;
    final mid = (count - 1) / 2.0;
    final totalW = max(180.0, (count * 34.0) + 28.0);

    return SizedBox(
      height: 86,
      child: Center(
        child: SizedBox(
          width: totalW,
          height: 84,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: List.generate(count, (i) {
              final c = myHand[i];
              final ok = !canPlay || legal.contains(c);
              final offsetIdx = i - mid;
              final angle = offsetIdx * 0.045;
              final dy = offsetIdx.abs() * 2.2;
              final dx = offsetIdx * 31.0;

              return Transform.translate(
                offset: Offset(dx, dy),
                child: Transform.rotate(
                  angle: angle,
                  child: _playingCardWidget(
                    c,
                    small: false,
                    dimmed: !ok,
                    onTap: canPlay && ok ? () => _playCard(0, c) : null,
                  ),
                ),
              );
            }),
          ),
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
