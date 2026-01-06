import 'package:AZOyun/features/golf/golf_game_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:math';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/game_button.dart';

class GolfLobbyScreen extends StatefulWidget {
  const GolfLobbyScreen({super.key});

  @override
  State<GolfLobbyScreen> createState() => _GolfLobbyScreenState();
}

class _GolfLobbyScreenState extends State<GolfLobbyScreen> {
  final DatabaseReference _roomsRef = FirebaseDatabase.instance.ref(
    'golf_rooms',
  );
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _roomCodeController = TextEditingController();
  String? _playerName;
  List<Map<String, dynamic>> _availableRooms = [];

  @override
  void initState() {
    super.initState();
    _listenToRooms();
  }

  void _listenToRooms() {
    _roomsRef.onValue.listen((event) {
      if (event.snapshot.value != null) {
        final rooms = event.snapshot.value as Map<dynamic, dynamic>;
        final List<Map<String, dynamic>> roomList = [];

        rooms.forEach((key, value) {
          final room = Map<String, dynamic>.from(value as Map);
          room['id'] = key;
          if (room['status'] == 'waiting' && room['players'].length < 4) {
            roomList.add(room);
          }
        });

        if (mounted) {
          setState(() {
            _availableRooms = roomList;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _availableRooms = [];
          });
        }
      }
    });
  }

  String _generateRoomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(
        6,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
  }

  Future<void> _createRoom() async {
    if (_playerName == null || _playerName!.isEmpty) {
      _showNameDialog();
      return;
    }

    final roomCode = _generateRoomCode();
    final roomId = 'room_${DateTime.now().millisecondsSinceEpoch}';

    await _roomsRef.child(roomId).set({
      'status': 'waiting',
      'roomCode': roomCode,
      'players': {
        'player1': {'name': _playerName, 'score': 0, 'isReady': false},
      },
      'currentHole': 1,
      'totalHoles': 9,
      'createdAt': ServerValue.timestamp,
    });

    if (mounted) {
      _showRoomCodeDialog(roomCode, roomId);
    }
  }

  void _showRoomCodeDialog(String roomCode, String roomId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.share, color: AppColors.golfPrimary),
            const SizedBox(width: 10),
            const Text('Oda Oluşturuldu!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Arkadaşlarına bu kodu ver:', style: AppTextStyles.bodyLarge),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.golfPrimary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.golfPrimary, width: 2),
              ),
              child: Column(
                children: [
                  Text(
                    roomCode,
                    style: AppTextStyles.code.withColor(AppColors.golfPrimary),
                  ),
                  const SizedBox(height: 10),
                  GameButton(
                    text: 'KOPYALA',
                    icon: Icons.copy,
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: roomCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Oda kodu kopyalandı!')),
                      );
                    },
                    color: AppColors.golfPrimary,
                    height: 45,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'En fazla 4 oyuncu katılabilir',
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          GameButton(
            text: 'LOBİYE GİT',
            onPressed: () {
              Navigator.pop(context);
              _joinRoom(roomId, isCreator: true);
            },
            color: AppColors.golfPrimary,
            height: 48,
          ),
        ],
      ),
    );
  }

  Future<void> _joinRoomByCode() async {
    if (_playerName == null || _playerName!.isEmpty) {
      _showNameDialog();
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Oda Kodunu Gir'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _roomCodeController,
              decoration: const InputDecoration(
                hintText: 'Örn: ABC123',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.characters,
              maxLength: 6,
              style: AppTextStyles.code,
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İPTAL'),
          ),
          GameButton(
            text: 'KATIL',
            onPressed: () async {
              final code = _roomCodeController.text.toUpperCase().trim();
              if (code.length == 6) {
                Navigator.pop(context);
                await _findAndJoinRoom(code);
              }
            },
            color: AppColors.golfPrimary,
            width: 100,
            height: 40,
          ),
        ],
      ),
    );
  }

  Future<void> _findAndJoinRoom(String roomCode) async {
    final snapshot = await _roomsRef
        .orderByChild('roomCode')
        .equalTo(roomCode)
        .once();

    if (snapshot.snapshot.value != null) {
      final rooms = snapshot.snapshot.value as Map<dynamic, dynamic>;
      final roomId = rooms.keys.first;
      final room = Map<String, dynamic>.from(rooms[roomId] as Map);

      if (room['status'] == 'waiting') {
        final players = Map<String, dynamic>.from(room['players'] as Map);
        if (players.length < 4) {
          await _joinRoom(roomId, isCreator: false);
        } else {
          _showError('Oda dolu!');
        }
      } else {
        _showError('Oyun başlamış!');
      }
    } else {
      _showError('Oda bulunamadı!');
    }
  }

  Future<void> _joinRoom(String roomId, {bool isCreator = false}) async {
    if (!isCreator) {
      // Mevcut oyuncu sayısını al
      final snapshot = await _roomsRef.child(roomId).once();
      final room = Map<String, dynamic>.from(snapshot.snapshot.value as Map);
      final players = Map<String, dynamic>.from(room['players'] as Map);

      final playerKey = 'player${players.length + 1}';

      await _roomsRef.child('$roomId/players/$playerKey').set({
        'name': _playerName,
        'score': 0,
        'isReady': false,
      });
    }

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              GolfGameScreen(roomId: roomId, playerName: _playerName!),
        ),
      );
    }
  }

  void _showNameDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('İsim Girin'),
        content: TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            hintText: 'Adınızı girin',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          GameButton(
            text: 'TAMAM',
            onPressed: () {
              if (_nameController.text.isNotEmpty) {
                setState(() {
                  _playerName = _nameController.text;
                });
                Navigator.pop(context);
              }
            },
            color: AppColors.golfPrimary,
            width: double.infinity,
            height: 48,
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('⛳ Mini Golf'),
        backgroundColor: AppColors.golfPrimary,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.golfPrimary.withOpacity(0.1), Colors.white],
          ),
        ),
        child: Column(
          children: [
            if (_playerName != null)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.person,
                      color: AppColors.golfPrimary,
                      size: 30,
                    ),
                    const SizedBox(width: 12),
                    Text('Hoşgeldin, $_playerName!', style: AppTextStyles.h5),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        setState(() => _playerName = null);
                        _showNameDialog();
                      },
                      child: const Text('Değiştir'),
                    ),
                  ],
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  GameButton(
                    text: 'YENİ ODA OLUŞTUR',
                    icon: Icons.add_circle_outline,
                    onPressed: _createRoom,
                    color: AppColors.golfPrimary,
                  ),
                  const SizedBox(height: 12),
                  GameButton(
                    text: 'ODA KODUNA KATIL',
                    icon: Icons.vpn_key,
                    onPressed: _joinRoomByCode,
                    color: AppColors.golfPrimary,
                    isOutlined: true,
                  ),
                ],
              ),
            ),

            const Divider(thickness: 2),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.list, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text('Mevcut Odalar', style: AppTextStyles.h5),
                ],
              ),
            ),

            Expanded(
              child: _availableRooms.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.inbox, size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text(
                            'Henüz oda yok',
                            style: AppTextStyles.h5.withColor(Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _availableRooms.length,
                      itemBuilder: (context, index) {
                        final room = _availableRooms[index];
                        final players = Map<String, dynamic>.from(
                          room['players'] as Map,
                        );
                        final playerCount = players.length;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: AppColors.golfPrimary.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.golf_course,
                                color: AppColors.golfPrimary,
                                size: 30,
                              ),
                            ),
                            title: Text(
                              players['player1']['name'],
                              style: AppTextStyles.playerName,
                            ),
                            subtitle: Text(
                              '$playerCount/4 oyuncu • Kod: ${room['roomCode']}',
                            ),
                            trailing: GameButton(
                              text: 'KATIL',
                              onPressed: () => _joinRoom(room['id']),
                              color: AppColors.golfPrimary,
                              width: 80,
                              height: 36,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _roomCodeController.dispose();
    super.dispose();
  }
}
