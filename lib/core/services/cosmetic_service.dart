import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/felt.dart';
import 'profile_service.dart';

class TableCloth {
  const TableCloth({
    required this.id,
    required this.title,
    required this.cost,
    required this.top,
    required this.bottom,
  });

  final String id;
  final String title;
  final int cost;
  final Color top;
  final Color bottom;
}

const kTableCloths = [
  TableCloth(
    id: 'classic',
    title: 'Klasik keçe',
    cost: 0,
    top: FeltColors.ivory,
    bottom: FeltColors.feltDeep,
  ),
  TableCloth(
    id: 'clay',
    title: 'Kil masa',
    cost: 120,
    top: FeltColors.clayPage,
    bottom: FeltColors.clayPageDeep,
  ),
  TableCloth(
    id: 'night',
    title: 'Gece keçesi',
    cost: 180,
    top: FeltColors.felt,
    bottom: FeltColors.feltDeep,
  ),
  TableCloth(
    id: 'brass',
    title: 'Pirinç salon',
    cost: 240,
    top: FeltColors.brassPage,
    bottom: FeltColors.brassPageDeep,
  ),
];

bool canAffordCloth({required int coins, required int cost, required bool owned}) =>
    owned || coins >= cost;

class CosmeticService extends ChangeNotifier {
  CosmeticService._();
  static final CosmeticService instance = CosmeticService._();

  static const _ownedKey = 'table_cloths_owned';
  static const _equippedKey = 'table_cloth_equipped';

  Set<String> owned = {'classic'};
  String equippedId = 'classic';

  TableCloth get equipped =>
      kTableCloths.firstWhere((cloth) => cloth.id == equippedId, orElse: () => kTableCloths.first);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    owned = {...?prefs.getStringList(_ownedKey), 'classic'};
    equippedId = prefs.getString(_equippedKey) ?? 'classic';
    if (!owned.contains(equippedId)) {
      equippedId = 'classic';
    }
  }

  Future<bool> choose(String id) async {
    final cloth = kTableCloths.firstWhere((item) => item.id == id);
    await ProfileService.instance.load();
    final coins = ProfileService.instance.profile.coins;
    final already = owned.contains(id);
    if (!canAffordCloth(coins: coins, cost: cloth.cost, owned: already)) {
      return false;
    }
    if (!already && cloth.cost > 0) {
      await ProfileService.instance.addCoins(-cloth.cost);
      owned.add(id);
    }
    equippedId = id;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_ownedKey, owned.toList());
    await prefs.setString(_equippedKey, equippedId);
    notifyListeners();
    return true;
  }
}
