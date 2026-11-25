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

/// خدمة إدارة الغرف والدردشة والمزامنة عبر Firestore مع سقوط آمن عند عدم توفر إعداد Firebase
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
      return 'غرفة [$cleanCode] جاهزة محلياً — أضف FIREBASE_GOOGLE_SERVICES_JSON لتفعيل المزامنة السحابية';
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
            'text': 'تم فتح غرفة $cleanCode في بلوت بحمد',
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

  Future<void> syncRoomStatus({
    required String roomCode,
    required String statusText,
  }) async {
    if (!isFirebaseReady) return;
    final cleanCode = roomCode.trim().toUpperCase();
    if (cleanCode.isEmpty) return;
    await roomDoc(cleanCode).set({'lastStatus': statusText}, SetOptions(merge: true));
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
                      : 'جاهز للغرف — أضف إعدادات Firebase لتفعيل المزامنة السحابية',
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
                            final code =
                                _roomController.text.trim().toUpperCase();
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
                      _topPill(Icons.style_rounded, 'صن • حكم • مشاريع'),
                      _topPill(
                        Icons.wifi_tethering,
                        OnlineRoomService.instance.isFirebaseReady
                            ? 'أونلاين متصل'
                            : 'جاهز للعب',
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
                              color: Colors.black.withValues(alpha: 0.5),
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
                        'لعب سريع • مشاريع ومضاعفات • دردشة فورية',
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

enum ProjectKind { sera, khamseen, meah, arbaameah, baloot }

class ProjectDeclaration {
  final int seat;
  final ProjectKind kind;
  final Suit suit;
  final int topRankOrder;

  const ProjectDeclaration({
    required this.seat,
    required this.kind,
    required this.suit,
    required this.topRankOrder,
  });

  String get arabicName {
    switch (kind) {
      case ProjectKind.sera:
        return 'سرا';
      case ProjectKind.khamseen:
        return 'خمسين';
      case ProjectKind.meah:
        return 'مئة';
      case ProjectKind.arbaameah:
        return 'أربعمئة';
      case ProjectKind.baloot:
        return 'بلوت';
    }
  }

  int get priorityRank {
    switch (kind) {
      case ProjectKind.arbaameah:
        return 4;
      case ProjectKind.meah:
        return 3;
      case ProjectKind.khamseen:
        return 2;
      case ProjectKind.sera:
        return 1;
      case ProjectKind.baloot:
        return 0;
    }
  }

  int pointsForMode(GameModeType mode) {
    final isSun = mode == GameModeType.sun;
    switch (kind) {
      case ProjectKind.sera:
        return isSun ? 4 : 2;
      case ProjectKind.khamseen:
        return isSun ? 10 : 5;
      case ProjectKind.meah:
        return isSun ? 20 : 10;
      case ProjectKind.arbaameah:
        return isSun ? 40 : 0;
      case ProjectKind.baloot:
        return isSun ? 0 : 2;
    }
  }
}

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

  int get sequenceOrder {
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
          case Rank.king:
            return 4;
          case Rank.queen:
            return 3;
          default:
            return 0;
        }
      } else {
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
    }
  }

  @override
  bool operator ==(Object other) =>
      other is PlayingCard && other.suit == suit && other.rank == rank;

  @override
  int get hashCode => Object.hash(suit, rank);
}

class PlayedCard {
  final int seat;
  final PlayingCard card;

  const PlayedCard({required this.seat, required this.card});
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

class BalootTableScreen extends StatefulWidget {
  final String modeTitle;
  final String? roomCode;
  final String playerName;
  final bool isOnlineMode;
  final String? statusBannerNote;

  const BalootTableScreen({
    super.key,
    required this.modeTitle,
    this.roomCode,
    required this.playerName,
    required this.isOnlineMode,
    this.statusBannerNote,
  });

  @override
  State<BalootTableScreen> createState() => _BalootTableScreenState();
}

class _BalootTableScreenState extends State<BalootTableScreen> {
  final Random _rng = Random();
  final TextEditingController _chatController = TextEditingController();

  static const int targetScore = 152;
  static const List<String> quickPhrases = [
    'كفو يا ذيب',
    'العبها صح',
    'سرا / مشاريع',
    'دبل يا كفو',
    'مبروك البنت',
    'تم',
  ];

  late List<String> seatNames;
  List<String?> seatBubbles = [null, null, null, null];
  List<ChatMessageItem> chatLog = [];
  StreamSubscription<DocumentSnapshot>>? _roomSub;

  GamePhase phase = GamePhase.bidding;
  GameModeType mode = GameModeType.none;
  Suit? hokmSuit;
  int? buyerSeat;
  int doubleMultiplier = 1;

  int currentTurn = 0;
  int dealerSeat = 3;
  int bidRound = 1;
  int consecutivePasses = 0;

  List<List<PlayingCard>> hands = [[], [], [], []];
  PlayingCard? floorCard;
  List<PlayedCard> trick = [];
  List<ProjectDeclaration> declaredProjects = [];

  int usMatchScore = 0;
  int themMatchScore = 0;

  int usRoundAbnat = 0;
  int themRoundAbnat = 0;
  int lastTrickWinner = 0;

  String statusMessage = 'أهلاً بك في بلوت بحمد — اختر حكم أو صن أو بس';
  bool isBusy = false;

  @override
  void initState() {
    super.initState();
    seatNames = [
      widget.playerName,
      'اليمين',
      'الشريك',
      'اليسار',
    ];
    chatLog.add(
      ChatMessageItem(
        sender: 'النظام',
        text: widget.statusBannerNote ??
            'مرحباً بك في طاولة ${widget.modeTitle} داخل بلوت بحمد',
      ),
    );
    if (widget.isOnlineMode &&
        widget.roomCode != null &&
        OnlineRoomService.instance.isFirebaseReady) {
      _subscribeRoomStream(widget.roomCode!);
    }
    _startNewRound(resetMatch: true);
  }

  void _subscribeRoomStream(String code) {
    _roomSub = OnlineRoomService.instance.roomDoc(code).snapshots().listen((snap) {
      if (!mounted || !snap.exists) return;
      final data = snap.data();
      if (data == null) return;
      final rawMsgs = data['messages'];
      if (rawMsgs is List) {
        final parsed = <ChatMessageItem>[];
        for (final entry in rawMsgs) {
          if (entry is Map) {
            parsed.add(
              ChatMessageItem(
                sender: (entry['sender'] ?? 'لاعب').toString(),
                text: (entry['text'] ?? '').toString(),
                isQuickCall: entry['isQuickCall'] == true,
              ),
            );
          }
        }
        if (parsed.isNotEmpty) {
          final latest = parsed.last;
          if (latest.sender != seatNames[0]) {
            _setSeatBubble(2, latest.text);
          }
          setState(() {
            chatLog = parsed;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _roomSub?.cancel();
    _chatController.dispose();
    super.dispose();
  }

  void _setSeatBubble(int seat, String text) {
    seatBubbles[seat] = text;
    setState(() {});
    Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      if (seatBubbles[seat] == text) {
        seatBubbles[seat] = null;
        setState(() {});
      }
    });
  }

  Future<void> _sendChat(String text, {bool isQuickCall = false}) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    if (widget.isOnlineMode &&
        widget.roomCode != null &&
        OnlineRoomService.instance.isFirebaseReady) {
      await OnlineRoomService.instance.sendRoomMessage(
        roomCode: widget.roomCode!,
        sender: seatNames[0],
        text: trimmed,
        isQuickCall: isQuickCall,
      );
    } else {
      chatLog.add(
        ChatMessageItem(
          sender: seatNames[0],
          text: trimmed,
          isQuickCall: isQuickCall,
        ),
      );
    }

    _setSeatBubble(0, trimmed);
    _chatController.clear();
    setState(() {});
  }

  Future<void> _openChatSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0A3320),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  MediaQuery.of(ctx).viewInsets.bottom + 18,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'دردشة الطاولة والنداءات السريعة',
                      style: TextStyle(
                        color: Color(0xFFF7D774),
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: quickPhrases.map((phrase) {
                        return ActionChip(
                          backgroundColor: const Color(0xFF155C3A),
                          labelStyle: const TextStyle(color: Colors.white),
                          label: Text(phrase),
                          onPressed: () {
                            _sendChat(phrase, isQuickCall: true);
                            Navigator.of(ctx).pop();
                          },
                        );
                      }).toList(),
                    ),
                    const Divider(color: Colors.white24, height: 18),
                    SizedBox(
                      height: 170,
                      child: ListView.builder(
                        itemCount: chatLog.length,
                        itemBuilder: (_, i) {
                          final item = chatLog[i];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Text(
                              '${item.sender}: ${item.text}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _chatController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'اكتب رسالة للطاولة...',
                              hintStyle: const TextStyle(color: Colors.white54),
                              filled: true,
                              fillColor: Colors.black26,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0xFFE6B84C),
                            foregroundColor: const Color(0xFF072416),
                          ),
                          onPressed: () async {
                            await _sendChat(_chatController.text);
                            setSheetState(() {});
                          },
                          icon: const Icon(Icons.send_rounded),
                        ),
                      ],
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

  List<ProjectDeclaration> _detectProjectsForSeat(int seat) {
    final hand = hands[seat];
    final result = <ProjectDeclaration>[];

    if (mode == GameModeType.sun) {
      final kings = hand.where((c) => c.rank == Rank.king).toList();
      if (kings.length == 4) {
        result.add(
          ProjectDeclaration(
            seat: seat,
            kind: ProjectKind.arbaameah,
            suit: Suit.spades,
            topRankOrder: 7,
          ),
        );
      }
    }

    final byRank = <Rank, List<PlayingCard>>{};
    for (final c in hand) {
      byRank.putIfAbsent(c.rank, () => []).add(c);
    }
    byRank.forEach((rank, cards) {
      if (cards.length == 4 &&
          rank != Rank.seven &&
          rank != Rank.eight &&
          rank != Rank.nine) {
        result.add(
          ProjectDeclaration(
            seat: seat,
            kind: ProjectKind.meah,
            suit: cards.first.suit,
            topRankOrder: cards.first.sequenceOrder,
          ),
        );
      }
    });

    for (final suit in Suit.values) {
      final suitCards = hand.where((c) => c.suit == suit).toList()
        ..sort((a, b) => a.sequenceOrder.compareTo(b.sequenceOrder));

      if (suitCards.length >= 3) {
        var run = <PlayingCard>[suitCards.first];
        for (var i = 1; i < suitCards.length; i++) {
          if (suitCards[i].sequenceOrder == run.last.sequenceOrder + 1) {
            run.add(suitCards[i]);
          } else {
            _addSequenceProject(result, seat, suit, run);
            run = <PlayingCard>[suitCards[i]];
          }
        }
        _addSequenceProject(result, seat, suit, run);
      }
    }

    if (mode == GameModeType.hokm && hokmSuit != null) {
      final hasK = hand.any((c) => c.suit == hokmSuit && c.rank == Rank.king);
      final hasQ = hand.any((c) => c.suit == hokmSuit && c.rank == Rank.queen);
      if (hasK && hasQ) {
        result.add(
          ProjectDeclaration(
            seat: seat,
            kind: ProjectKind.baloot,
            suit: hokmSuit!,
            topRankOrder: 7,
          ),
        );
      }
    }

    return result;
  }

  void _addSequenceProject(
    List<ProjectDeclaration> out,
    int seat,
    Suit suit,
    List<PlayingCard> run,
  ) {
    if (run.length >= 5) {
      out.add(
        ProjectDeclaration(
          seat: seat,
          kind: ProjectKind.meah,
          suit: suit,
          topRankOrder: run.last.sequenceOrder,
        ),
      );
    } else if (run.length == 4) {
      out.add(
        ProjectDeclaration(
          seat: seat,
          kind: ProjectKind.khamseen,
          suit: suit,
          topRankOrder: run.last.sequenceOrder,
        ),
      );
    } else if (run.length == 3) {
      out.add(
        ProjectDeclaration(
          seat: seat,
          kind: ProjectKind.sera,
          suit: suit,
          topRankOrder: run.last.sequenceOrder,
        ),
      );
    }
  }

  void _declareProjectsForSeat(int seat) {
    final detected = _detectProjectsForSeat(seat);
    if (detected.isEmpty) return;

    for (final proj in detected) {
      final alreadyExists = declaredProjects.any(
        (p) =>
            p.seat == proj.seat &&
            p.kind == proj.kind &&
            p.suit == proj.suit,
      );
      if (!alreadyExists) {
        declaredProjects.add(proj);
      }
    }

    final names = detected.map((p) => p.arabicName).toSet().join(' • ');
    _setSeatBubble(seat, names);
    statusMessage = '${seatNames[seat]} أعلن مشروع: $names';
    setState(() {});
  }

  void _startNewRound({required bool resetMatch}) {
    if (resetMatch) {
      usMatchScore = 0;
      themMatchScore = 0;
    }

    dealerSeat = (dealerSeat + 1) % 4;
    currentTurn = (dealerSeat + 1) % 4;
    bidRound = 1;
    consecutivePasses = 0;
    mode = GameModeType.none;
    hokmSuit = null;
    buyerSeat = null;
    doubleMultiplier = 1;
    phase = GamePhase.bidding;
    trick = [];
    declaredProjects = [];
    usRoundAbnat = 0;
    themRoundAbnat = 0;
    seatBubbles = [null, null, null, null];
    isBusy = false;

    final deck = <PlayingCard>[];
    for (final s in Suit.values) {
      for (final r in Rank.values) {
        deck.add(PlayingCard(suit: s, rank: r));
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
      _sortHand(hands[i]);
    }

    statusMessage = 'دور الشراء (لفة $bidRound): ${seatNames[currentTurn]}';
    setState(() {});

    if (currentTurn != 0) {
      _scheduleBotTurn();
    }
  }

  void _sortHand(List<PlayingCard> hand) {
    hand.sort((a, b) {
      final suitCmp = a.suit.index.compareTo(b.suit.index);
      if (suitCmp != 0) return suitCmp;
      return a.rank.index.compareTo(b.rank.index);
    });
  }

  void _scheduleBotTurn() {
    if (phase == GamePhase.matchEnd || phase == GamePhase.roundEnd) return;
    isBusy = true;
    Timer(const Duration(milliseconds: 650), () {
      if (!mounted) return;
      isBusy = false;
      if (phase == GamePhase.bidding && currentTurn != 0) {
        _botBid();
      } else if (phase == GamePhase.playing && currentTurn != 0) {
        _botPlayCard();
      }
    });
  }

  void _botBid() {
    final hand = hands[currentTurn];
    final hokmCandidate = bidRound == 1
        ? (floorCard?.suit ?? Suit.spades)
        : Suit.values[currentTurn % Suit.values.length];

    final hokmPower = hand
        .where((c) => c.suit == hokmCandidate)
        .fold<int>(
          0,
          (sum, c) => sum + c.abnatPoints(GameModeType.hokm, hokmCandidate),
        );
    final sunPower = hand.fold<int>(
      0,
      (sum, c) => sum + c.abnatPoints(GameModeType.sun, null),
    );

    if (sunPower >= 24 && mode == GameModeType.none) {
      _acceptBid(currentTurn, GameModeType.sun, null);
      return;
    }

    if (hokmPower >= 22) {
      _acceptBid(currentTurn, GameModeType.hokm, hokmCandidate);
      return;
    }

    _passBid(currentTurn);
  }

  void _acceptBid(int seat, GameModeType selectedMode, Suit? selectedHokm) {
    mode = selectedMode;
    hokmSuit = selectedHokm;
    buyerSeat = seat;
    phase = GamePhase.playing;
    trick = [];
    currentTurn = (dealerSeat + 1) % 4;

    final modeLabel = mode == GameModeType.sun
        ? 'صن'
        : 'حكم (${hokmSuit!.suitArabic})';
    _setSeatBubble(seat, modeLabel);
    statusMessage = 'المشتري: ${seatNames[seat]} — النوع: $modeLabel';
    setState(() {});

    if (widget.isOnlineMode && widget.roomCode != null) {
      unawaited(
        OnlineRoomService.instance.syncRoomStatus(
          roomCode: widget.roomCode!,
          statusText: statusMessage,
        ),
      );
    }

    if (currentTurn != 0) {
      _scheduleBotTurn();
    }
  }

  void _applyDouble() {
    if (mode != GameModeType.hokm || phase != GamePhase.playing) return;
    doubleMultiplier = min(4, doubleMultiplier * 2);
    final label = doubleMultiplier == 2 ? 'دبل' : 'تربل / مضاعف';
    _setSeatBubble(0, label);
    statusMessage = 'تمت مضاعفة الحكم ($label)';
    setState(() {});
  }

  void _passBid(int seat) {
    consecutivePasses++;
    _setSeatBubble(seat, 'بس');
    statusMessage = '${seatNames[seat]} قال: بس';
    if (consecutivePasses >= 4) {
      if (bidRound == 1) {
        bidRound = 2;
        consecutivePasses = 0;
        currentTurn = (dealerSeat + 1) % 4;
        statusMessage = 'اللفة الثانية للشراء — اختر لون الحكم أو صن أو بس';
        setState(() {});
        if (currentTurn != 0) _scheduleBotTurn();
      } else {
        statusMessage = 'الكل بس! إعادة توزيع الصك';
        setState(() {});
        Timer(const Duration(milliseconds: 900), () {
          if (mounted) _startNewRound(resetMatch: false);
        });
      }
      return;
    }

    currentTurn = (currentTurn + 1) % 4;
    setState(() {});
    if (currentTurn != 0) {
      _scheduleBotTurn();
    }
  }

  List<PlayingCard> _legalCardsForSeat(int seat) {
    final hand = hands[seat];
    if (trick.isEmpty) return List<PlayingCard>.from(hand);

    final leadSuit = trick.first.card.suit;
    final matchingSuit = hand.where((c) => c.suit == leadSuit).toList();
    if (matchingSuit.isNotEmpty) {
      return matchingSuit;
    }

    if (mode == GameModeType.hokm && hokmSuit != null && leadSuit != hokmSuit) {
      final trumps = hand.where((c) => c.suit == hokmSuit).toList();
      if (trumps.isNotEmpty) {
        return trumps;
      }
    }

    return List<PlayingCard>.from(hand);
  }

  void _botPlayCard() {
    if (_detectProjectsForSeat(currentTurn).isNotEmpty && trick.isEmpty) {
      _declareProjectsForSeat(currentTurn);
    }
    final legal = _legalCardsForSeat(currentTurn);
    legal.sort(
      (a, b) => a.strength(mode, hokmSuit).compareTo(b.strength(mode, hokmSuit)),
    );
    _playCard(currentTurn, legal.first);
  }

  void _playCard(int seat, PlayingCard card) {
    if (phase != GamePhase.playing || seat != currentTurn) return;
    final legal = _legalCardsForSeat(seat);
    if (!legal.contains(card)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يجب الالتزام بقواعد اللعب (اللون أو الحكم)'),
        ),
      );
      return;
    }

    hands[seat].remove(card);
    trick.add(PlayedCard(seat: seat, card: card));

    if (trick.length < 4) {
      currentTurn = (currentTurn + 1) % 4;
      statusMessage = 'دور ${seatNames[currentTurn]}';
      setState(() {});
      if (currentTurn != 0) _scheduleBotTurn();
      return;
    }

    final leadSuit = trick.first.card.suit;
    PlayedCard winner = trick.first;

    for (final p in trick.skip(1)) {
      final winnerIsTrump = mode == GameModeType.hokm && p.card.suit == hokmSuit;
      final currentWinnerIsTrump =
          mode == GameModeType.hokm && winner.card.suit == hokmSuit;

      if (winnerIsTrump && !currentWinnerIsTrump) {
        winner = p;
      } else if (winnerIsTrump && currentWinnerIsTrump) {
        if (p.card.strength(mode, hokmSuit) >
            winner.card.strength(mode, hokmSuit)) {
          winner = p;
        }
      } else if (!currentWinnerIsTrump && p.card.suit == leadSuit) {
        if (p.card.strength(mode, hokmSuit) >
            winner.card.strength(mode, hokmSuit)) {
          winner = p;
        }
      }
    }

    lastTrickWinner = winner.seat;
    final trickPoints = trick.fold<int>(
      0,
      (sum, p) => sum + p.card.abnatPoints(mode, hokmSuit),
    );
    final isLastTrick = hands.every((h) => h.isEmpty);
    final totalTrickPoints = trickPoints + (isLastTrick ? 10 : 0);

    final winnerTeamIsUs = winner.seat == 0 || winner.seat == 2;
    if (winnerTeamIsUs) {
      usRoundAbnat += totalTrickPoints;
    } else {
      themRoundAbnat += totalTrickPoints;
    }

    _setSeatBubble(winner.seat, '+$totalTrickPoints');
    statusMessage =
        'أخذ البنت: ${seatNames[winner.seat]} (+$totalTrickPoints نقطة)';
    setState(() {});

    isBusy = true;
    Timer(const Duration(milliseconds: 950), () {
      if (!mounted) return;
      isBusy = false;
      trick = [];

      if (isLastTrick) {
        _finishRound();
      } else {
        currentTurn = lastTrickWinner;
        statusMessage = 'دور ${seatNames[currentTurn]}';
        setState(() {});
        if (currentTurn != 0) _scheduleBotTurn();
      }
    });
  }

  int _calculateProjectsBonus({required bool forUsTeam}) {
    if (declaredProjects.isEmpty) return 0;

    var directBonus = 0;
    final competitive = <ProjectDeclaration>[];

    for (final p in declaredProjects) {
      final isUs = p.seat == 0 || p.seat == 2;
      if (p.kind == ProjectKind.baloot) {
        if (isUs == forUsTeam) {
          directBonus += p.pointsForMode(mode);
        }
      } else {
        competitive.add(p);
      }
    }

    if (competitive.isNotEmpty) {
      competitive.sort((a, b) {
        final prio = b.priorityRank.compareTo(a.priorityRank);
        if (prio != 0) return prio;
        return b.topRankOrder.compareTo(a.topRankOrder);
      });
      final top = competitive.first;
      final topIsUs = top.seat == 0 || top.seat == 2;
      if (topIsUs == forUsTeam) {
        final sameTeamPoints = competitive
            .where((x) => (x.seat == 0 || x.seat == 2) == topIsUs)
            .fold<int>(0, (sum, x) => sum + x.pointsForMode(mode));
        directBonus += sameTeamPoints;
      }
    }

    return directBonus;
  }

  void _finishRound() {
    final scaleFactor = (mode == GameModeType.sun ? 2 : 1) * doubleMultiplier;
    final usProj = _calculateProjectsBonus(forUsTeam: true);
    final themProj = _calculateProjectsBonus(forUsTeam: false);

    final usAdded = (((usRoundAbnat + usProj) / 10).round()) * scaleFactor;
    final themAdded = (((themRoundAbnat + themProj) / 10).round()) * scaleFactor;

    usMatchScore += usAdded;
    themMatchScore += themAdded;

    if (usMatchScore >= targetScore || themMatchScore >= targetScore) {
      phase = GamePhase.matchEnd;
      statusMessage = usMatchScore >= targetScore
          ? 'مبروك! فريقكم كسب الصك في بلوت بحمد ($usMatchScore مقابل $themMatchScore)'
          : 'انتهى الصك بفوز الخصم ($themMatchScore مقابل $usMatchScore)';
    } else {
      phase = GamePhase.roundEnd;
      statusMessage =
          'نهاية الجولة: لكم +$usAdded (مشاريع $usProj) ولهم +$themAdded (مشاريع $themProj)';
    }
    setState(() {});
  }

  PlayedCard? _playedForSeat(int seat) {
    for (final p in trick) {
      if (p.seat == seat) return p;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final legalForUser = (phase == GamePhase.playing && currentTurn == 0)
        ? _legalCardsForSeat(0)
        : <PlayingCard>[];
    final myProjects =
        (phase == GamePhase.playing && currentTurn == 0 && !isBusy)
            ? _detectProjectsForSeat(0)
            : <ProjectDeclaration>[];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF093620),
        appBar: AppBar(
          backgroundColor: const Color(0xFF052013),
          foregroundColor: Colors.white,
          title: Row(
            children: [
              const Text(
                'بلوت بحمد',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  '• ${widget.modeTitle}',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFFE6B84C), fontSize: 12),
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'الدردشة',
              onPressed: _openChatSheet,
              icon: const Icon(Icons.chat_bubble_outline_rounded),
            ),
            IconButton(
              tooltip: 'صك جديد',
              onPressed: () => _startNewRound(resetMatch: true),
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: Column(
          children: [
            _buildScoreHeader(),
            _buildStatusBanner(),
            Expanded(child: _buildTableArena()),
            if (myProjects.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFE6B84C),
                    foregroundColor: const Color(0xFF072416),
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: () => _declareProjectsForSeat(0),
                  icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                  label: Text(
                    'إعلان مشروع (${myProjects.map((e) => e.arabicName).toSet().join(" • ")})',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            if (mode == GameModeType.hokm &&
                phase == GamePhase.playing &&
                doubleMultiplier < 4)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFF7D774),
                    side: const BorderSide(color: Color(0x88E6B84C)),
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: _applyDouble,
                  icon: const Icon(Icons.bolt_rounded, size: 16),
                  label: Text(
                    doubleMultiplier == 1
                        ? 'دبل'
                        : 'مضاعفة ×${doubleMultiplier * 2}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            if (phase == GamePhase.bidding && currentTurn == 0 && !isBusy)
              _buildBiddingBar(),
            if (phase == GamePhase.roundEnd)
              Padding(
                padding: const EdgeInsets.all(8),
                child: FilledButton(
                  onPressed: () => _startNewRound(resetMatch: false),
                  child: const Text('الجولة التالية'),
                ),
              ),
            if (phase == GamePhase.matchEnd)
              Padding(
                padding: const EdgeInsets.all(8),
                child: FilledButton(
                  onPressed: () => _startNewRound(resetMatch: true),
                  child: const Text('بدء صك جديد'),
                ),
              ),
            _buildPlayerHand(legalForUser),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreHeader() {
    final multSuffix = doubleMultiplier > 1 ? ' ×$doubleMultiplier' : '';
    final modeText = mode == GameModeType.none
        ? 'الشراء (لفة $bidRound)'
        : mode == GameModeType.sun
            ? 'صن$multSuffix'
            : 'حكم ${hokmSuit?.suitSymbol ?? ''} (${hokmSuit?.suitArabic ?? ''})$multSuffix';

    return Container(
      color: const Color(0xFF072A19),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'لنا: $usMatchScore',
            style: const TextStyle(
              color: Color(0xFFF7D774),
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF145A38),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0x88E6B84C)),
            ),
            child: Text(
              modeText,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12.5,
              ),
            ),
          ),
          Text(
            'لهم: $themMatchScore',
            style: const TextStyle(
              color: Colors.lightBlueAccent,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      color: Colors.black26,
      child: Text(
        statusMessage,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white, fontSize: 13.5),
      ),
    );
  }

  Widget _buildTableArena() {
    final topPlayed = _playedForSeat(2);
    final rightPlayed = _playedForSeat(1);
    final leftPlayed = _playedForSeat(3);
    final bottomPlayed = _playedForSeat(0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _seatWithBubble(2, hands[2].length),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _seatWithBubble(3, hands[3].length),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: const RadialGradient(
                        colors: [Color(0xFF1B7247), Color(0xFF0C4127)],
                      ),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: const Color(0xFFE6B84C),
                        width: 1.6,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.38),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: trick.isEmpty &&
                            phase == GamePhase.bidding &&
                            floorCard != null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'ورقة المشترى',
                                style: TextStyle(
                                  color: Color(0xFFF7D774),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              _cardWidget(floorCard!, enabled: true, compact: true),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              if (topPlayed != null)
                                _cardWidget(topPlayed.card, enabled: true, compact: true)
                              else
                                const SizedBox(height: 58),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  if (leftPlayed != null)
                                    _cardWidget(leftPlayed.card, enabled: true, compact: true)
                                  else
                                    const SizedBox(width: 44),
                                  if (rightPlayed != null)
                                    _cardWidget(rightPlayed.card, enabled: true, compact: true)
                                  else
                                    const SizedBox(width: 44),
                                ],
                              ),
                              if (bottomPlayed != null)
                                _cardWidget(bottomPlayed.card, enabled: true, compact: true)
                              else
                                const SizedBox(height: 58),
                            ],
                          ),
                  ),
                ),
                _seatWithBubble(1, hands[1].length),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'أبناط الجولة — لنا: $usRoundAbnat | لهم: $themRoundAbnat',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              InkWell(
                onTap: _openChatSheet,
                child: const Text(
                  'دردشة 💬',
                  style: TextStyle(
                    color: Color(0xFFF7D774),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _seatWithBubble(int seat, int cardCount) {
    final isTurn = currentTurn == seat;
    final bubbleText = seatBubbles[seat];
    final isBuyer = buyerSeat == seat;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (bubbleText != null)
          Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              bubbleText,
              style: const TextStyle(
                color: Color(0xFF072416),
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: isTurn ? const Color(0xFFE6B84C) : Colors.black45,
            borderRadius: BorderRadius.circular(12),
            border: isBuyer
                ? Border.all(color: Colors.amberAccent, width: 1.5)
                : null,
          ),
          child: Text(
            '${seatNames[seat]} ($cardCount)',
            style: TextStyle(
              color: isTurn ? const Color(0xFF072416) : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 11.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBiddingBar() {
    final defaultSuit = floorCard?.suit ?? Suit.spades;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      color: Colors.black45,
      child: bidRound == 1
          ? Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                FilledButton.tonal(
                  onPressed: () => _passBid(0),
                  child: const Text('بس'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF1A7348),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => _acceptBid(0, GameModeType.hokm, defaultSuit),
                  child: Text('حكم ${defaultSuit.suitArabic}'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFE6B84C),
                    foregroundColor: const Color(0xFF072416),
                  ),
                  onPressed: () => _acceptBid(0, GameModeType.sun, null),
                  child: const Text('صن'),
                ),
              ],
            )
          : Wrap(
              spacing: 6,
              runSpacing: 6,
              alignment: WrapAlignment.center,
              children: [
                FilledButton.tonal(
                  onPressed: () => _passBid(0),
                  child: const Text('بس'),
                ),
                ...Suit.values.map(
                  (s) => FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF1A7348),
                      foregroundColor: Colors.white,
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: () => _acceptBid(0, GameModeType.hokm, s),
                    child: Text('${s.suitSymbol} ${s.suitArabic}'),
                  ),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFE6B84C),
                    foregroundColor: const Color(0xFF072416),
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: () => _acceptBid(0, GameModeType.sun, null),
                  child: const Text('صن'),
                ),
              ],
            ),
    );
  }

  Widget _buildPlayerHand(List<PlayingCard> legalCards) {
    final myHand = hands[0];
    final isMyTurn = phase == GamePhase.playing && currentTurn == 0 && !isBusy;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
      color: const Color(0xFF052013),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${seatNames[0]}${isMyTurn ? " — دورك الآن" : ""}',
                style: TextStyle(
                  color: isMyTurn ? const Color(0xFFF7D774) : Colors.white70,
                  fontSize: 12,
                  fontWeight: isMyTurn ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              if (seatBubbles[0] != null)
                Text(
                  seatBubbles[0]!,
                  style: const TextStyle(color: Color(0xFFF7D774), fontSize: 12),
                ),
            ],
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: myHand.map((card) {
                final isLegal = !isMyTurn || legalCards.contains(card);
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: AnimatedSlide(
                    duration: const Duration(milliseconds: 180),
                    offset: isMyTurn && isLegal
                        ? const Offset(0, -0.08)
                        : Offset.zero,
                    child: _cardWidget(
                      card,
                      enabled: isLegal,
                      highlighted: isMyTurn && isLegal,
                      onTap: isMyTurn && isLegal ? () => _playCard(0, card) : null,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardWidget(
    PlayingCard card, {
    required bool enabled,
    bool compact = false,
    bool highlighted = false,
    VoidCallback? onTap,
  }) {
    final width = compact ? 46.0 : 62.0;
    final height = compact ? 66.0 : 90.0;
    final color =
        card.isRed ? const Color(0xFFC62828) : const Color(0xFF141916);

    return Opacity(
      opacity: enabled ? 1.0 : 0.38,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: const Color(0xFFFFFDF8),
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: highlighted
                  ? const Color(0xFFE6B84C)
                  : const Color(0x33000000),
              width: highlighted ? 2.0 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.30),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.all(4),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(7),
              border: Border.all(
                color: color.withValues(alpha: card.isCourtCard ? 0.35 : 0.12),
                width: 0.8,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      card.rankLabel,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w900,
                        fontSize: compact ? 11 : 14,
                        height: 1.0,
                      ),
                    ),
                    Text(
                      card.suitSymbol,
                      style: TextStyle(
                        color: color,
                        fontSize: compact ? 10 : 12,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
                Text(
                  card.suitSymbol,
                  style: TextStyle(
                    color: color,
                    fontSize: compact ? 19 : 26,
                    height: 1.0,
                  ),
                ),
                Align(
                  alignment: Alignment.bottomLeft,
                  child: Text(
                    card.rankLabel,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: compact ? 9 : 11,
                      height: 1.0,
                    ),
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
