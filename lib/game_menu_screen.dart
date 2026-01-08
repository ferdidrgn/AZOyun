import 'package:AZOyun/core/theme/app_colors.dart';
import 'package:AZOyun/core/theme/app_text_styles.dart';
import 'package:AZOyun/core/widgets/game_button.dart';

// Banner widget importu (Dosya yolunu projene göre kontrol et)
import 'package:AZOyun/core/widgets/banner_ad.dart';
import 'package:AZOyun/features/golf/golf_lobby_screen.dart';
import 'package:AZOyun/features/hangman/hangman_lobby_screen.dart';
import 'package:flutter/material.dart';

class GameMenuScreen extends StatelessWidget {
  const GameMenuScreen({super.key});

  @override
  Widget build(final BuildContext context) {
    return Scaffold(
      // Scaffold background color ayarlanırsa banner arkası sırıtmamış olur
      backgroundColor: AppColors.primary,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: SafeArea(
          // 'bottom: false' yaparak banner'ın safe area'nın en altına yapışmasını sağladık
          bottom: false,
          child: Column(
            children: [
              const SizedBox(height: 40),

              // Başlık ve logo
              _buildHeader(),

              const SizedBox(height: 20),

              // Alt başlık
              Text(
                'Arkadaşlarınla Gerçek Zamanlı Oyna',
                style: AppTextStyles.bodyLarge.white,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              // Oyun kartları (Expanded ile alanı kaplar)
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  children: [
                    GameCardButton(
                      title: 'ADAM ASMACA',
                      subtitle: 'Kelime Tahmin Oyunu • 2 Oyuncu',
                      emoji: '🎯',
                      gradient: AppColors.hangmanGradient,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (final context) => const HangmanLobbyScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),

                    GameCardButton(
                      title: 'MİNİ GOLF',
                      subtitle: 'Top Vur, Deliğe Sok • 4 Oyuncu',
                      emoji: '⛳',
                      gradient: AppColors.golfGradient,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (final context) => const GolfLobbyScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),

                    GameCardButton(
                      title: 'SERBEST VURUŞ',
                      subtitle: 'Gol At, Kazan • 2 Oyuncu',
                      emoji: '⚽',
                      gradient: AppColors.freeKickGradient,
                      isComingSoon: true,
                      onTap: () => _showComingSoon(context, 'Serbest Vuruş'),
                    ),
                    const SizedBox(height: 20),

                    GameCardButton(
                      title: 'YARIŞ',
                      subtitle: 'Birinci Ol • 4 Oyuncu',
                      emoji: '🏎️',
                      gradient: AppColors.racingGradient,
                      isComingSoon: true,
                      onTap: () => _showComingSoon(context, 'Yarış'),
                    ),

                    const SizedBox(height: 40),

                    // Bilgi kartı
                    _buildInfoCard(),

                    // Listenin en altında biraz boşluk bırakalım ki banner üstüne binmesin
                    const SizedBox(height: 20),
                  ],
                ),
              ),

              // 📢 REKLAM ALANI
              // Adaptive Banner kullanarak ekran genişliğine tam oturmasını sağlıyoruz
              const AdaptiveBannerAdWidget(
                padding: EdgeInsets.zero, // Alt kısımdaki boşlukları sıfırladık
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.sports_esports,
            size: 60,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'MULTIPLAYER GAMES',
          style: AppTextStyles.gameTitle,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
      ),
      child: Column(
        children: [
          const Icon(Icons.info_outline, color: Colors.white, size: 40),
          const SizedBox(height: 12),
          Text('Nasıl Oynanır?', style: AppTextStyles.h5.white.bold),
          const SizedBox(height: 8),
          Text(
            '1. Oyun seç ve oda oluştur\n'
            '2. Oda kodunu arkadaşına gönder\n'
            '3. Arkadaşın katılsın ve oyun başlasın!',
            style: AppTextStyles.bodyMedium.white,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showComingSoon(final BuildContext context, final String gameName) {
    showDialog(
      context: context,
      builder: (final context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.rocket_launch, color: AppColors.primary),
            const SizedBox(width: 10),
            Expanded(child: Text(gameName)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.construction, size: 64, color: AppColors.warning),
            const SizedBox(height: 16),
            Text(
              'Bu oyun yakında eklenecek!',
              style: AppTextStyles.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Şu an Adam Asmaca ve Mini Golf oynanabilir.',
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          GameButton(
            text: 'TAMAM',
            onPressed: () => Navigator.pop(context),
            color: AppColors.primary,
            width: double.infinity,
            height: 48,
          ),
        ],
      ),
    );
  }
}
