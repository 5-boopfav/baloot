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
        colorSchemeSeed: const Color(0xFF0E5A36),
      ),
      home: const BalootHomeScreen(),
    );
  }
}

/// خدمة إدارة الغرف والدردشة عبر Firestore مع سقوط آمن عند عدم توفر إعداد Firebase بعد
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

  DocumentReference> roomDoc(String roomCode) {
    return FirebaseFirestore.instance
        .collection('baloot_rooms')
        .doc(roomCode.trim().toUpperCase());
  }

  Future<String> createOrJoinRoom(String roomCode, String playerName) async {
    final cleanCode = roomCode.trim().toUpperCase();
    if (cleanCode.isEmpty) {
      throw Exception('أدخل رمز غرفة صحيح');
    }
    if (!isFirebaseReady) {
      return 'غرفة [$cleanCode] نشطة محلياً — أضف إعدادات Firebase لتفعيل المزامنة السحابية';
    }

    final cleanName = playerName.trim().isEmpty ? 'أنت' : playerName.trim();
    final ref = roomDoc(cleanCode);
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
            'text': 'تم إنشاء غرفة $cleanCode في بلوت بحمد',
            'isQuickCall': false,
          }
        ],
      });
    } else {
      await ref.update({
        'players': FieldValue.arrayUnion([cleanName]),
      });
    }

    return 'متصل بغرفة الأونلاين [$cleanCode]';
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

    await roomDoc(cleanCode).update({
      'messages': FieldValue.arrayUnion([
        {
          'sender': sender,
          'text': text,
          'isQuickCall': isQuickCall,
        }
      ]),
    });
  }
}

class BalootHomeScreen extends StatefulWidget {
  const BalootHomeScreen({super.key});

  @override
  State<BalootHomeScreen> createState() => _BalootHomeScreenState();
}

class _BalootHomeScreenState extends State<BalootHomeScreen> {
  final TextEditingController _roomController =
      TextEditingController(text: 'BAH77');
  final TextEditingController _nameController =
      TextEditingController(text: 'بحمد');
  bool _isConnecting = false;

  @override
  void dispose() {
    _roomController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _openOnlineRoomSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0A3320),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'أونلاين — بلوت بحمد',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFFF7D774),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  OnlineRoomService.instance.isFirebaseReady
                      ? 'متصل بـ Firebase — شارك رمز الغرفة مع صديقك'
                      : 'جاهز للغرف — اربط ملف google-services.json لتفعيل المزامنة السحابية',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _fieldDecoration('اسمك على الطاولة'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _roomController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _fieldDecoration('رمز الغرفة (مثال: BAH77)'),
                ),
                const SizedBox(height: 18),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFE6B84C),
                    foregroundColor: const Color(0xFF072416),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _isConnecting
                      ? null
                      : () async {
                          setState(() => _isConnecting = true);
                          try {
                            final code = _roomController.text.trim().toUpperCase();
                            final name = _nameController.text.trim().isEmpty
                                ? 'أنت'
                                : _nameController.text.trim();
                            final msg = await OnlineRoomService.instance
                                .createOrJoinRoom(code, name);
                            if (!mounted || !ctx.mounted) return;
                            Navigator.of(ctx).pop();
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => BalootTableScreen(
                                  modeTitle: 'غرفة $code',
                                  roomCode: code,
                                  playerName: name,
                                  isOnlineMode: true,
                                  statusBannerNote: msg,
                                ),
                              ),
                            );
                          } catch (e) {
                            if (!ctx.mounted) return;
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(content: Text(e.toString())),
                            );
                          } finally {
                            if (mounted) setState(() => _isConnecting = false);
                          }
                        },
                  child: const Text(
                    'دخول الطاولة',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  InputDecoration _fieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      filled: true,
      fillColor: Colors.black26,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.white24),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE6B84C)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF041C10),
                Color(0xFF0D492D),
                Color(0xFF052113),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _topPill(Icons.style_rounded, 'صن • حكم • دبل'),
                      _topPill(
                        Icons.wifi_tethering,
                        OnlineRoomService.instance.isFirebaseReady
                            ? 'أونلاين متصل'
                            : 'وضع الطاولة جاهز',
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Container(
                        width: 108,
                        height: 108,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF1A6B44), Color(0xFF0B3722)],
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFE6B84C),
                            width: 2.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            '♠♥\n♣♦',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFFF7D774),
                              fontSize: 22,
                              height: 1.15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'بلوت بحمد',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'لعب سريع • دردشة فورية • غرف أصدقاء',
                        style: TextStyle(
                          color: Color(0xFFD7EFE2),
                          fontSize: 13.5,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFE6B84C),
                            foregroundColor: const Color(0xFF072416),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const BalootTableScreen(
                                  modeTitle: 'لعب سريع',
                                  playerName: 'أنت',
                                  isOnlineMode: false,
                                ),
                              ),
                            );
                          },
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.play_arrow_rounded, size: 26),
                              SizedBox(width: 8),
                              Text(
                                'ابدأ اللعب',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Color(0xFFE6B84C)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: _openOnlineRoomSheet,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.groups_rounded, size: 22),
                              SizedBox(width: 8),
                              Text(
                                'غرف الأونلاين',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _topPill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black38,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: const Color(0xFFE6B84C)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

enum Suit { spades, hearts, clubs, diamonds }

enum Rank { seven, eight, nine, ten, jack, queen, king, ace }

enum GameModeType { none, sun, hokm }

enum GamePhase { bidding, playing, roundEnd, matchEnd }

class PlayingCard {
  final Suit suit;
  final Rank rank;

  const PlayingCard({required this.suit, required this.rank});

  String get suitSymbol {
    switch (suit) {
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

  String get suitArabic {
    switch (suit) {
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

  bool get isRed => suit == Suit.hearts || suit == Suit.diamonds;

  bool get isCourtCard =>
      rank == Rank.jack || rank == Rank.queen || rank == Rank.king;

  String get rankLabel {
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

  int strength(GameModeType mode, Suit? hokmSuit) {
    if (mode == GameModeType.sun) {
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
    } else {
      final isTrump = suit == hokmSuit;
      if (isTrump) {
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
      } else {
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
    }
  }

  int abnatPoints(GameModeType mode, Suit? hokmSuit) {
    if (mode == GameModeType.sun) {
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
    } else {
      final isTrump = suit == hokmSuit;
      if (isTrump) {
        switch (rank) {
          case Rank.jack:
            return 20;
          case Rank.nine:
            return 14;
          case Rank.ace:
            return 11;
          case Rank.ten:
            return 10;
