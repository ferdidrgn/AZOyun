import 'package:a_z_oyun/features/hangman/hangman_game_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:math';

class HangmanLobbyScreen extends StatefulWidget {
  const HangmanLobbyScreen({super.key});

  @override
  State<HangmanLobbyScreen> createState() => _HangmanLobbyScreenState();
}

class _HangmanLobbyScreenState extends State<HangmanLobbyScreen> {
  final DatabaseReference _roomsRef = FirebaseDatabase.instance.ref(
    'hangman_rooms',
  );
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _roomCodeController = TextEditingController();
  String? _playerName;
  List<Map<String, dynamic>> _availableRooms = [];
  String? _myRoomCode;

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
          // Sadece bekleyen odaları göster
          if (room['status'] == 'waiting') {
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
      'player1': {'name': _playerName, 'score': 0},
      'player2': null,
      'currentRound': 1,
      'totalRounds': 3,
      'createdAt': ServerValue.timestamp,
    });

    setState(() {
      _myRoomCode = roomCode;
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
        title: const Row(
          children: [
            Icon(Icons.share, color: Colors.blue),
            SizedBox(width: 10),
            Text('Oda Oluşturuldu!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Arkadaşına bu kodu ver:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue, width: 2),
              ),
              child: Column(
                children: [
                  Text(
                    roomCode,
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 8,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: roomCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Oda kodu kopyalandı!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy),
                    label: const Text('KOPYALA'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Arkadaşın "ODA KODUNA KATIL" butonuna tıklayıp bu kodu girecek',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _waitInRoom(roomId);
            },
            child: const Text('TAMAM, BEKLİYORUM'),
          ),
        ],
      ),
    );
  }

  Future<void> _waitInRoom(String roomId) async {
    // Oda ekranına git ve bekle
    _joinRoom(roomId, isCreator: true);
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
                counterText: '',
              ),
              textCapitalization: TextCapitalization.characters,
              maxLength: 6,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              'Arkadaşından aldığın 6 haneli kodu gir',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İPTAL'),
          ),
          ElevatedButton(
            onPressed: () async {
              final code = _roomCodeController.text.toUpperCase().trim();
              if (code.length == 6) {
                Navigator.pop(context);
                await _findAndJoinRoom(code);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('KATIL'),
          ),
        ],
      ),
    );
  }

  Future<void> _findAndJoinRoom(String roomCode) async {
    // Tüm odaları tara ve room code'u eşleşeni bul
    final snapshot = await _roomsRef
        .orderByChild('roomCode')
        .equalTo(roomCode)
        .once();

    if (snapshot.snapshot.value != null) {
      final rooms = snapshot.snapshot.value as Map<dynamic, dynamic>;
      final roomId = rooms.keys.first;
      final room = Map<String, dynamic>.from(rooms[roomId] as Map);

      if (room['status'] == 'waiting') {
        await _joinRoom(roomId, isCreator: false);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Bu oda dolu veya oyun başlamış!'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Oda bulunamadı! Kodu kontrol et.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _joinRoom(String roomId, {bool isCreator = false}) async {
    if (!isCreator) {
      if (_playerName == null || _playerName!.isEmpty) {
        _showNameDialog();
        return;
      }

      // Player 2 olarak katıl
      await _roomsRef.child(roomId).update({
        'player2': {'name': _playerName, 'score': 0},
        'status': 'playing',
      });
    }

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HangmanGameScreen(
            roomId: roomId,
            playerName: _playerName!,
            isPlayer1: isCreator,
          ),
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
          onSubmitted: (value) {
            if (value.isNotEmpty) {
              setState(() {
                _playerName = value;
              });
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (_nameController.text.isNotEmpty) {
                setState(() {
                  _playerName = _nameController.text;
                });
                Navigator.pop(context);
              }
            },
            child: const Text('TAMAM'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adam Asmaca - Lobi'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.red.shade100, Colors.red.shade50],
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
                    const Icon(Icons.person, color: Colors.red, size: 30),
                    const SizedBox(width: 12),
                    Text(
                      'Hoşgeldin, $_playerName!',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _playerName = null;
                        });
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
                  // Oda Oluştur Butonu
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _createRoom,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_circle_outline, size: 24),
                          SizedBox(width: 8),
                          Text(
                            'YENİ ODA OLUŞTUR',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Oda Koduna Katıl Butonu
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _joinRoomByCode,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.green,
                        side: const BorderSide(color: Colors.green, width: 2),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.vpn_key, size: 24),
                          SizedBox(width: 8),
                          Text(
                            'ODA KODUNA KATIL',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(thickness: 2),

            const Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.list, color: Colors.grey),
                  SizedBox(width: 8),
                  Text(
                    'Yakındaki Odalar',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  Spacer(),
                  Icon(Icons.info_outline, color: Colors.grey, size: 20),
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
                          const Text(
                            'Yakında oda yok',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 40),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              '💡 İpucu: Arkadaşınla oynamak için "Oda Oluştur" ile oda aç ve kodu paylaş!',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.blue),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _availableRooms.length,
                      itemBuilder: (context, index) {
                        final room = _availableRooms[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.red.shade100,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.gamepad,
                                color: Colors.red,
                                size: 30,
                              ),
                            ),
                            title: Text(
                              room['player1']['name'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Rakip bekliyor...'),
                                const SizedBox(height: 4),
                                Text(
                                  'Kod: ${room['roomCode']}',
                                  style: TextStyle(
                                    color: Colors.blue.shade700,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            trailing: ElevatedButton(
                              onPressed: () => _joinRoom(room['id']),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('KATIL'),
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
