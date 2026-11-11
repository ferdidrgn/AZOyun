import 'dart:convert';

import 'package:AZOyun/features/family/family_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('TV invite opens a phone lobby with the room code',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'az_family_server': 'https://masa.example.test',
    });
    final client = MockClient((request) async {
      final data = switch ((request.method, request.url.path)) {
        ('POST', '/api/family/rooms') => {'code': 'ABC234', 'token': 'host'},
        ('POST', '/api/family/rooms/ABC234/join') => {
            'code': 'ABC234',
            'token': 'guest',
          },
        ('GET', '/api/family/rooms/ABC234') => {
            'code': 'ABC234',
            'revision': 1,
            'game': 'okey',
            'status': 'lobby',
            'players': [
              if (request.headers['Authorization'] == 'Bearer guest')
                {'name': 'Ada'},
            ],
          },
        _ => throw StateError('Unexpected request ${request.url}'),
      };
      return http.Response(jsonEncode(data), 200,
          headers: {'content-type': 'application/json'});
    });

    await http.runWithClient(() async {
      await tester.pumpWidget(const FamilyApp(host: true));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Klasik Okey'));
      await tester.pumpAndSettle();
      expect(find.byType(QrImageView), findsOneWidget);
      String? invite;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            invite = (call.arguments as Map)['text'] as String;
          }
          return null;
        },
      );
      await tester.ensureVisible(find.text('Katılım bağlantısını kopyala'));
      await tester.tap(find.text('Katılım bağlantısını kopyala'));
      await tester.pumpAndSettle();
      final url = Uri.parse(invite!);
      expect(url.origin, 'https://masa.example.test');
      expect(url.queryParameters, {'family': 'ABC234'});

      await tester.pumpWidget(FamilyApp(
        key: const ValueKey('phone'),
        host: false,
        code: url.queryParameters['family'],
      ));
      await tester.pumpAndSettle();
      expect(find.text('ABC234'), findsOneWidget);
      await tester.enterText(find.byType(TextField).at(1), 'Ada');
      await tester.tap(find.text('Katıl'));
      await tester.pumpAndSettle();
      expect(find.text('TV’de masanın başlatılmasını bekle.'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    }, () => client);
  });
}
