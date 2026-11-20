import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../navigation/join_router.dart';
import '../navigation/room_invite.dart';

class RoomQrButton extends StatelessWidget {
  const RoomQrButton({super.key});

  Future<void> _scan(BuildContext context) async {
    final invite = await Navigator.of(context).push<RoomInvite>(
      MaterialPageRoute(builder: (_) => const _RoomQrScanner()),
    );
    if (invite != null && context.mounted) {
      openGameInvite(context, invite.game, invite.code);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb &&
        defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS) {
      return const SizedBox.shrink();
    }
    return OutlinedButton.icon(
      onPressed: () => _scan(context),
      icon: const Icon(Icons.qr_code_scanner_rounded),
      label: const Text('QR ile odaya katıl'),
    );
  }
}

class _RoomQrScanner extends StatefulWidget {
  const _RoomQrScanner();

  @override
  State<_RoomQrScanner> createState() => _RoomQrScannerState();
}

class _RoomQrScannerState extends State<_RoomQrScanner> {
  bool _finished = false;
  bool _invalid = false;

  void _detect(BarcodeCapture capture) {
    if (_finished || ModalRoute.of(context)?.isCurrent != true) return;
    for (final barcode in capture.barcodes) {
      if (barcode.format != BarcodeFormat.qrCode) continue;
      final uri = Uri.tryParse(barcode.rawValue?.trim() ?? '');
      final invite = uri == null ? null : parseRoomInvite(uri);
      if (invite != null) {
        _finished = true;
        Navigator.of(context).pop(invite);
        return;
      }
      if (!_invalid) setState(() => _invalid = true);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('QR ile katıl')),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: MobileScanner(
                  onDetect: _detect,
                  errorBuilder: (context, error) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        error.errorCode ==
                                MobileScannerErrorCode.permissionDenied
                            ? 'Kamera izni kapalı. İzni cihaz ayarlarından aç veya oyun lobisinde oda kodunu gir.'
                            : 'Kamera açılamadı. Oyun lobisinde oda kodunu girebilirsin.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  _invalid
                      ? 'Bu QR kodu AZOyun odasına ait değil. Odanın davet kodunu okut.'
                      : 'Arkadaşının odasında görünen QR kodunu kameraya göster.',
                  textAlign: TextAlign.center,
                  semanticsLabel: _invalid ? 'Geçersiz oda daveti' : null,
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Oyun listesine dön'),
              ),
            ],
          ),
        ),
      );
}
