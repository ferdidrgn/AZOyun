import 'package:AZOyun/core/theme/app_colors.dart';
import 'package:AZOyun/core/theme/app_text_styles.dart';
import 'package:AZOyun/core/widgets/banner_ad.dart';
import 'package:AZOyun/core/widgets/game_button.dart';
import 'package:AZOyun/features/golf/golf_lobby_screen.dart';
import 'package:AZOyun/features/hangman/hangman_lobby_screen.dart';
import 'package:AZOyun/features/math/math_lobby_screen.dart';
import 'package:flutter/material.dart';

class GameMenuScreen extends StatelessWidget {
  const GameMenuScreen({super.key});

  @override
  Widget build(final BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const SizedBox(height: 40),

              // Logo
              _buildHeader(),

              const SizedBox(height: 20),

              Text(
                'Arkadaşlarınla Gerçek Zamanlı Oyna',
                style: AppTextStyles.bodyLarge.white,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 30),

              // Oyunlar
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  children: [
                    // SPOR OYUNLARI
                    _buildSectionTitle('⚽ SPOR OYUNLARI'),

                    GameCardButton(
                      title: 'MİNİ GOLF',
                      subtitle: 'Top Vur, Deliğe Sok • 2-4 Oyuncu',
                      emoji: '⛳',
                      gradient: AppColors.golfGradient,
                      onTap: () => _navigate(context, const GolfLobbyScreen()),
                    ),
                    const SizedBox(height: 16),

                    GameCardButton(
                      title: 'SERBEST VURUŞ',
                      subtitle: 'Gol At, Kazan • 2 Oyuncu',
                      emoji: '⚽',
                      gradient: AppColors.freeKickGradient,
                      onTap: () =>
                          _navigate(context, const SoccerLobbyScreen()),
                    ),
                    const SizedBox(height: 30),

                    // ZİHİNSEL OYUNLAR
                    _buildSectionTitle('🧠 ZİHİNSEL OYUNLAR'),

                    GameCardButton(
                      title: 'ADAM ASMACA',
                      subtitle: 'Kelime Tahmin • 2 Oyuncu',
                      emoji: '🎯',
                      gradient: AppColors.hangmanGradient,
                      onTap: () =>
                          _navigate(context, const HangmanLobbyScreen()),
                    ),
                    const SizedBox(height: 16),

                    GameCardButton(
                      title: 'HIZLI MATEMATİK',
                      subtitle: 'Hızlı Hesapla • 2-4 Oyuncu',
                      emoji: '🧮',
                      gradient: const LinearGradient(
                        colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                      ),
                      onTap: () => _navigate(context, const MathLobbyScreen()),
                    ),
                    const SizedBox(height: 16),

                    GameCardButton(
                      title: 'ŞEHİR BULMACA',
                      subtitle: 'İpucu ile Şehir Bul • 2-4 Oyuncu',
                      emoji: '🏙️',
                      gradient: const LinearGradient(
                        colors: [Color(0xFFf093fb), Color(0xFFf5576c)],
                      ),
                      onTap: () => _navigate(context, const CityLobbyScreen()),
                    ),
                    const SizedBox(height: 16),

                    GameCardButton(
                      title: 'KELİME BULMACA',
                      subtitle: 'Kelime Oluştur • 2-4 Oyuncu',
                      emoji: '🔤',
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
                      ),
                      onTap: () => _navigate(context, const WordLobbyScreen()),
                    ),
                    const SizedBox(height: 30),

                    // SOSYAL OYUNLAR
                    _buildSectionTitle('🎭 SOSYAL OYUNLAR'),

                    GameCardButton(
                      title: 'VAMPİR KÖYLÜ',
                      subtitle: 'Mafia Tarzı Oyun • 4-8 Oyuncu',
                      emoji: '🧛',
                      gradient: const LinearGradient(
                        colors: [Color(0xFF434343), Color(0xFF000000)],
                      ),
                      onTap: () =>
                          _navigate(context, const VampireLobbyScreen()),
                    ),
                    const SizedBox(height: 16),

                    GameCardButton(
                      title: 'YALANCILAR KAHVESİ',
                      subtitle: 'Yalan Söyle, Yakala • 3-6 Oyuncu',
                      emoji: '☕',
                      gradient: const LinearGradient(
                        colors: [Color(0xFFd66d75), Color(0xFFe29587)],
                      ),
                      onTap: () => _navigate(context, const LiarLobbyScreen()),
                    ),

                    const SizedBox(height: 40),

                    // Bilgi
                    _buildInfoCard(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),

              // Banner Reklam
              const AdaptiveBannerAdWidget(padding: EdgeInsets.zero),
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
          'AZ OYUN',
          style: AppTextStyles.gameTitle,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text('MULTIPLAYER', style: AppTextStyles.bodySmall.white.bold),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(final String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 1.5,
        ),
      ),
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
            '3. Arkadaşın katılsın ve oyun başlasın!\n\n'
            '🎮 8 farklı oyun modu\n'
            '👥 2-8 oyuncu desteği\n'
            '⚡ Gerçek zamanlı oynanış',
            style: AppTextStyles.bodyMedium.white,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _navigate(final BuildContext context, final Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (final context) => screen),
    );
  }
}
