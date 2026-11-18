// ignore_for_file: unintended_html_in_doc_comment

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

/// Mofuchi Garden Shop — a self-contained screen.
///
/// Firestore: gamification_progress/{uid}
///   coinBalance: int (defaults to 0)
///   ownedGardenItems: List<String>
///   equippedGardenItems: Map<String,String>  // flowers/decorations/effects
///
/// IMPORTANT: This shop does not award coins. Connect coin earning separately to
/// the existing check-in/gamification service with idempotent daily rewards.
/// Product previews use locally rendered images from the user-provided GLBs;
/// tapping one opens its actual interactive GLB in a single ModelViewer.
class GardenShopScreen extends StatefulWidget {
  const GardenShopScreen({super.key});

  @override
  State<GardenShopScreen> createState() => _GardenShopScreenState();
}

class _GardenItem {
  final String id;
  final String title;
  final String category;
  final String description;
  final int price;
  final int minLevel;
  final String glb;
  final String preview;
  final IconData icon;
  final Color tint;

  const _GardenItem({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.price,
    required this.minLevel,
    required this.glb,
    required this.preview,
    required this.icon,
    required this.tint,
  });
}

const _items = <_GardenItem>[
  _GardenItem(id: 'tulips', title: 'Tulip Flowers', category: 'Flowers',
    description: 'Sweet tulips for your Sakura island.', price: 20, minLevel: 1,
    glb: 'assets/decorations/tulips.glb', preview: 'assets/images/shop/tulips.png',
    icon: Icons.local_florist_rounded, tint: Color(0xFFD99BAC)),
  _GardenItem(id: 'flower_bush', title: 'Flower Bush', category: 'Flowers',
    description: 'A blooming little bush for your island.', price: 30, minLevel: 1,
    glb: 'assets/decorations/flower_bush.glb', preview: 'assets/images/shop/flower_bush.png',
    icon: Icons.local_florist_rounded, tint: Color(0xFFA3C4A4)),
  _GardenItem(id: 'lantern', title: 'Candle Lantern', category: 'Decorations',
    description: 'A warm glow for your quiet corner.', price: 50, minLevel: 2,
    glb: 'assets/decorations/Candle_Lantern.glb', preview: 'assets/images/shop/lantern.png',
    icon: Icons.lightbulb_rounded, tint: Color(0xFFD6B47B)),
  _GardenItem(id: 'lily', title: 'Lily Flowers', category: 'Flowers',
    description: 'Delicate lilies for your garden.', price: 60, minLevel: 3,
    glb: 'assets/decorations/Lily.glb', preview: 'assets/images/shop/lily.png',
    icon: Icons.filter_vintage_rounded, tint: Color(0xFFE8C4CD)),
  _GardenItem(id: 'butterfly', title: 'Magical Butterfly', category: 'Effects',
    description: 'A gentle butterfly to decorate your garden.', price: 80, minLevel: 4,
    glb: 'assets/decorations/butterfly.glb', preview: 'assets/images/shop/butterfly.png',
    icon: Icons.auto_awesome_rounded, tint: Color(0xFFBFA6E7)),
  _GardenItem(id: 'cactus_flower', title: 'Cactus Flower', category: 'Decorations',
    description: 'A charming cactus companion.', price: 100, minLevel: 5,
    glb: 'assets/decorations/cactus_flower.glb', preview: 'assets/images/shop/cactus_flower.png',
    icon: Icons.spa_rounded, tint: Color(0xFF91B694)),
];

class _GardenShopScreenState extends State<GardenShopScreen> {
  static const _purple = Color(0xFF8460CB);
  static const _ink = Color(0xFF302938);
  static const _muted = Color(0xFF766B84);
  static const _gold = Color(0xFF98763B);

  int _levelFromXp(Map<String, dynamic>? data) {
    final xp = (data?['totalXp'] as num?)?.toInt() ?? 0;
    if (xp >= 350) return 5;
    if (xp >= 220) return 4;
    if (xp >= 120) return 3;
    if (xp >= 50) return 2;
    return 1;
  }

  void _show3D(_GardenItem item) {
    showModalBottomSheet<void>(
      context: context, isScrollControlled: true,
      backgroundColor: const Color(0xFFFAF8FC),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 22),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              Expanded(child: Text(item.title, style: const TextStyle(fontSize: 18,
                fontWeight: FontWeight.bold, color: _ink))),
              IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
            ]),
            SizedBox(height: MediaQuery.sizeOf(ctx).height * 0.47,
              child: ModelViewer(key: ValueKey(item.glb), src: item.glb,
                alt: item.title, backgroundColor: const Color(0xFFF4ECF6),
                cameraControls: true, disableZoom: false, autoRotate: false)),
            const SizedBox(height: 10),
            Text('3D preview only · Buy and equip to add to your collection',
              style: const TextStyle(fontSize: 11, color: _muted)),
          ]),
        ),
      ),
    );
  }

  String _filter = 'All';
  String? _busyItemId;

  DocumentReference<Map<String, dynamic>>? get _progressRef {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    return FirebaseFirestore.instance.collection('gamification_progress').doc(uid);
  }

  int _coinCount(Map<String, dynamic>? data) {
    final raw = data?['coinBalance'];
    return raw is num ? raw.toInt().clamp(0, 999999999).toInt() : 0;
  }

  List<String> _owned(Map<String, dynamic>? data) {
    final raw = data?['ownedGardenItems'];
    return raw is List ? raw.whereType<String>().toList() : <String>[];
  }

  Map<String, String> _equipped(Map<String, dynamic>? data) {
    final raw = data?['equippedGardenItems'];
    if (raw is! Map) return {};
    return raw.map((key, value) => MapEntry(key.toString(), value.toString()));
  }

  void _feedback(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  void _showInsufficientCoins(_GardenItem item, int coins) {
    final missing = item.price - coins;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(children: [
          Icon(Icons.monetization_on_outlined, color: _purple),
          SizedBox(width: 9),
          Expanded(child: Text('Not enough coins', style: TextStyle(fontSize: 18))),
        ]),
        content: Text(
          '${item.title} costs ${item.price} coins. You have $coins coins. '
          'Earn $missing more ${missing == 1 ? 'coin' : 'coins'} through check-ins to buy it.',
          style: const TextStyle(fontSize: 13, height: 1.5),
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _purple),
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Future<void> _buy(_GardenItem item) async {
    final ref = _progressRef;
    if (ref == null || _busyItemId != null) return;
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _PurchaseSheet(item: item),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busyItemId = item.id);
    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(ref);
        final data = snapshot.data();
        final balance = _coinCount(data);
        if (_levelFromXp(data) < item.minLevel) {
          throw _ShopIssue('Reach Level ${item.minLevel} to unlock this item.');
        }
        final owned = _owned(data);
        if (owned.contains(item.id)) throw const _ShopIssue('Already owned!');
        if (balance < item.price) {
          throw const _ShopIssue('Not enough coins for this treasure yet.');
        }
        transaction.set(ref, {
          'coinBalance': balance - item.price,
          'ownedGardenItems': FieldValue.arrayUnion([item.id]),
        }, SetOptions(merge: true));
      });
      if (mounted) {
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Text('A New Garden Treasure! 🌸'),
            content: Text('${item.title} is now in My Collection.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Lovely!')),
            ],
          ),
        );
      }
    } on _ShopIssue catch (e) {
      _feedback(e.message);
    } on FirebaseException catch (e) {
      _feedback('Purchase failed: ${e.message ?? e.code}');
    } catch (_) {
      _feedback('Could not complete the purchase. Please try again.');
    } finally {
      if (mounted) setState(() => _busyItemId = null);
    }
  }

  Future<void> _toggleEquip(_GardenItem item, bool isEquipped) async {
    final ref = _progressRef;
    if (ref == null || _busyItemId != null) return;
    setState(() => _busyItemId = item.id);
    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(ref);
        final data = snapshot.data();
        if (!_owned(data).contains(item.id)) {
          throw const _ShopIssue('Purchase this item before equipping it.');
        }
        final equipped = _equipped(data);
        if (isEquipped && equipped[item.category] == item.id) {
          equipped.remove(item.category);
        } else {
          equipped[item.category] = item.id;
        }
        transaction.set(ref, {'equippedGardenItems': equipped}, SetOptions(merge: true));
      });
    } on _ShopIssue catch (e) {
      _feedback(e.message);
    } on FirebaseException catch (e) {
      _feedback('Could not update item: ${e.message ?? e.code}');
    } catch (_) {
      _feedback('Could not update your garden item.');
    } finally {
      if (mounted) setState(() => _busyItemId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ref = _progressRef;
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8FC),
      body: SafeArea(
        child: ref == null
            ? const Center(child: Text('Please sign in to visit Garden Shop.'))
            : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: ref.snapshots(),
                builder: (context, snapshot) {
                  final data = snapshot.data?.data();
                  final coins = _coinCount(data);
                  final level = _levelFromXp(data);
                  final owned = _owned(data);
                  final equipped = _equipped(data);
                  final visible = _filter == 'All'
                      ? _items
                      : _items.where((item) => item.category == _filter).toList();

                  return Stack(
                    children: [
                      const Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFFF9F4FC), Color(0xFFF7FBF8), Color(0xFFFBF8FC)],
                            ),
                          ),
                        ),
                      ),
                      ListView(
                        padding: const EdgeInsets.fromLTRB(22, 12, 22, 40),
                        children: [
                          _header(coins),
                          if (snapshot.hasError)
                            const Padding(
                              padding: EdgeInsets.only(top: 12),
                              child: Text('Unable to load rewards. Check your connection or Firestore permissions.',
                                style: TextStyle(color: Colors.redAccent)),
                            ),
                          if (snapshot.connectionState == ConnectionState.waiting)
                            const Padding(
                              padding: EdgeInsets.only(top: 12),
                              child: LinearProgressIndicator(color: _purple),
                            ),
                          const SizedBox(height: 24),
                          _featured(_items[2], coins, level, owned, equipped),
                          const SizedBox(height: 26),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Flexible(child: Text('Find your little treasure',
                                style: TextStyle(color: _ink, fontSize: 17, fontWeight: FontWeight.w700))),
                              Text('${_items.length} treasures',
                                style: const TextStyle(color: _muted, fontSize: 11)),
                            ],
                          ),
                          const SizedBox(height: 14),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: ['All', 'Flowers', 'Decorations', 'Effects'].map((category) {
                                final selected = _filter == category;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 7),
                                  child: ChoiceChip(
                                    label: Text(category),
                                    selected: selected,
                                    showCheckmark: false,
                                    onSelected: (_) => setState(() => _filter = category),
                                    selectedColor: _purple,
                                    backgroundColor: Colors.white,
                                    labelStyle: TextStyle(color: selected ? Colors.white : _muted, fontSize: 11,
                                      fontWeight: FontWeight.w600),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13), side: BorderSide.none),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 14),
                          LayoutBuilder(builder: (context, constraints) {
                            final columns = constraints.maxWidth >= 550 ? 3 : 2;
                            return GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: visible.length,
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: columns,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 12,
                                mainAxisExtent: 250,
                              ),
                              itemBuilder: (context, index) {
                                final item = visible[index];
                                return _productCard(item, coins, level, owned, equipped);
                              },
                            );
                          }),
                          const SizedBox(height: 24),
                          _collection(owned, equipped),
                          const SizedBox(height: 24),
                          _earningGuide(),
                          const SizedBox(height: 18),
                          const Center(
                            child: Text('Grown through reflection. Spent on little joys.\nVirtual coins only · No real-money purchases',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Color(0xFF70816C), fontSize: 10, height: 1.8)),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }

  Widget _header(int coins) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () => Navigator.of(context).maybePop(),
            child: const CircleAvatar(backgroundColor: Colors.white,
              child: Icon(Icons.chevron_left_rounded, color: _muted)),
          ),
          const Expanded(child: Text('Mofuchi Garden', textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF6E7F68), fontSize: 11, fontWeight: FontWeight.w600))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(color: const Color(0xFFFFF4DD), borderRadius: BorderRadius.circular(30)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.monetization_on_rounded, color: _gold, size: 17),
              const SizedBox(width: 5),
              Text('$coins', style: const TextStyle(color: _gold, fontSize: 13, fontWeight: FontWeight.w700)),
            ]),
          ),
        ],
      ),
      const SizedBox(height: 18),
      const Text('Garden Shop', style: TextStyle(color: _ink, fontSize: 28, fontWeight: FontWeight.w700)),
      const SizedBox(height: 4),
      const Text('Little treasures for your garden', style: TextStyle(color: _muted, fontSize: 12)),
    ],
  );

  Widget _featured(_GardenItem item, int coins, int level, List<String> owned, Map<String, String> equipped) {
    final isOwned = owned.contains(item.id);
    return Container(
      height: 211,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFECE2FB), Color(0xFFF9EEF4)]),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: const [BoxShadow(color: Color(0x179A85B5), blurRadius: 19, offset: Offset(0, 5))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('A LITTLE GLOW', style: TextStyle(color: _purple, fontSize: 9, letterSpacing: 1.3,
                fontWeight: FontWeight.w700)),
              const SizedBox(height: 11),
              const Text('Candle\nLantern', style: TextStyle(color: _ink, fontSize: 21,
                fontWeight: FontWeight.w700, height: 1.15)),
              const SizedBox(height: 7),
              const Text('A warm light for\nyour quiet corner.', style: TextStyle(color: _muted, fontSize: 10.5)),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: _actionButton(item, coins, level, isOwned, equipped[item.category] == item.id, compact: true),
              ),
            ]),
          ),
          const SizedBox(width: 10),
          Expanded(child: _itemArt(item, featured: true, locked: !isOwned && level < item.minLevel)),
        ],
      ),
    );
  }

  Widget _itemArt(_GardenItem item, {bool featured = false, bool locked = false}) => InkWell(
    onTap: locked
        ? () => _feedback('Reach Level ${item.minLevel} to unlock ${item.title}.')
        : () => _show3D(item),
    borderRadius: BorderRadius.circular(featured ? 22 : 16),
    child: Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(featured ? 22 : 16),
        color: const Color(0xFFF0EAF4),
      ),
      child: Stack(fit: StackFit.expand, children: [
        ColorFiltered(
          colorFilter: locked
              ? const ColorFilter.matrix(<double>[
                  0.2126, 0.7152, 0.0722, 0, 0,
                  0.2126, 0.7152, 0.0722, 0, 0,
                  0.2126, 0.7152, 0.0722, 0, 0,
                  0, 0, 0, 1, 0,
                ])
              : const ColorFilter.mode(Colors.transparent, BlendMode.dst),
          child: Image.asset(item.preview, fit: BoxFit.cover,
            errorBuilder: (_, error, stack) => Center(child: Icon(item.icon,
              size: featured ? 80 : 58, color: item.tint))),
        ),
        if (locked) ...[
          Container(color: const Color(0x806B6570)),
          Center(child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: featured ? 14 : 11,
              vertical: featured ? 9 : 7,
            ),
            decoration: BoxDecoration(
              color: const Color(0xCC302938),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.lock_rounded, color: Colors.white,
                size: featured ? 27 : 23),
              const SizedBox(height: 4),
              Text('LEVEL ${item.minLevel}',
                style: const TextStyle(color: Colors.white, fontSize: 10,
                  fontWeight: FontWeight.w700)),
            ]),
          )),
        ] else
          const Positioned(right: 7, bottom: 7,
            child: Icon(Icons.threed_rotation_rounded,
              color: Color(0xFF7354AB), size: 23)),
      ]),
    ),
  );

  Widget _productCard(_GardenItem item, int coins, int level, List<String> owned, Map<String, String> equipped) {
    final isOwned = owned.contains(item.id);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white, width: 1),
        boxShadow: const [BoxShadow(color: Color(0x0F8B789F), blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: _itemArt(item, locked: !isOwned && level < item.minLevel)),
        const SizedBox(height: 8),
        Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: _ink, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 3),
        Row(children: [
          Expanded(child: Text('${item.price} coins', style: const TextStyle(color: _gold, fontSize: 11))),
          if (isOwned) const Text('Owned', style: TextStyle(color: Color(0xFF627B5D), fontSize: 9)),
        ]),
        const SizedBox(height: 9),
        SizedBox(width: double.infinity,
          child: _actionButton(item, coins, level, isOwned, equipped[item.category] == item.id)),
      ]),
    );
  }

  Widget _actionButton(_GardenItem item, int coins, int level, bool isOwned, bool isEquipped,
      {bool compact = false}) {
    final busy = _busyItemId != null;
    final canAfford = coins >= item.price;
    final isLocked = !isOwned && level < item.minLevel;
    final text = isLocked
        ? 'Unlock Lv ${item.minLevel}'
        : isOwned
            ? (isEquipped ? 'Unequip' : 'Equip')
            : 'Buy · ${item.price} coins';
    return SizedBox(
      height: compact ? 36 : 38,
      child: FilledButton(
        onPressed: busy || isLocked
            ? null
            : () {
                if (isOwned) {
                  _toggleEquip(item, isEquipped);
                } else if (!canAfford) {
                  _showInsufficientCoins(item, coins);
                } else {
                  _buy(item);
                }
              },
        style: FilledButton.styleFrom(
          backgroundColor: isOwned ? const Color(0xFFEEE8F6) : _purple,
          foregroundColor: isOwned ? const Color(0xFF7354AB) : Colors.white,
          disabledBackgroundColor: const Color(0xFFE8E2ED),
          disabledForegroundColor: _muted,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
        ),
        child: _busyItemId == item.id
            ? const SizedBox(width: 15, height: 15,
                child: CircularProgressIndicator(strokeWidth: 2, color: _purple))
            : Text(text, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: compact ? 10 : 11,
                  fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _collection(List<String> owned, Map<String, String> equipped) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('My Collection', style: TextStyle(color: _ink, fontSize: 18, fontWeight: FontWeight.w700)),
      const SizedBox(height: 3),
      const Text('A few lovely things to make it feel like you.',
        style: TextStyle(color: _muted, fontSize: 11)),
      const SizedBox(height: 12),
      if (owned.isEmpty)
        _softCard(const Padding(
          padding: EdgeInsets.all(8),
          child: Text('Your garden collection is empty for now. Your first treasure is waiting! 🌸',
            style: TextStyle(color: _muted, fontSize: 12)),
        ))
      else
        ..._items.where((item) => owned.contains(item.id)).map((item) {
          final active = equipped[item.category] == item.id;
          return Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: _softCard(Row(children: [
              Container(width: 50, height: 50, decoration: BoxDecoration(
                color: const Color(0xFFF0EAF5), borderRadius: BorderRadius.circular(15)),
                child: ClipRRect(borderRadius: BorderRadius.circular(15),
                  child: Image.asset(item.preview, fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Icon(item.icon, color: item.tint, size: 29)))),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(item.title, style: const TextStyle(color: _ink, fontSize: 12, fontWeight: FontWeight.w600)),
                Text(active ? 'Equipped in garden' : 'Garden ${item.category.toLowerCase()}',
                  style: const TextStyle(color: _muted, fontSize: 10)),
              ])),
              SizedBox(width: 85, child: _actionButton(item, 0, 5, true, active)),
            ])),
          );
        }),
    ],
  );

  Widget _softCard(Widget child) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.78),
      borderRadius: BorderRadius.circular(20)),
    child: child,
  );

  Widget _earningGuide() => _softCard(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text('Small moments, little rewards',
      style: TextStyle(color: _ink, fontSize: 15, fontWeight: FontWeight.w700)),
    const SizedBox(height: 4),
    const Text('Earn coins through caring reflection.', style: TextStyle(color: _muted, fontSize: 11)),
    const SizedBox(height: 14),
    _coinRule('First daily check-in', '+5 coins'),
    const SizedBox(height: 9),
    _coinRule('Optional written reflection', '+3 coins'),
    const SizedBox(height: 9),
    _coinRule('3-day weekly milestone', '+10 coins'),
    const SizedBox(height: 9),
    _coinRule('7-day weekly milestone', '+20 coins'),
    const SizedBox(height: 11),
    const Text('Proposed rewards: activate them in your check-in service before launch.',
      style: TextStyle(color: _muted, fontSize: 10, fontStyle: FontStyle.italic)),
  ]));

  Widget _coinRule(String label, String amount) => Row(children: [
    Expanded(child: Text(label, style: const TextStyle(color: Color(0xFF63596F), fontSize: 11))),
    Text(amount, style: const TextStyle(color: _gold, fontSize: 11, fontWeight: FontWeight.w600)),
  ]);
}

class _ShopIssue implements Exception {
  final String message;
  const _ShopIssue(this.message);
}

class _PurchaseSheet extends StatelessWidget {
  final _GardenItem item;
  const _PurchaseSheet({required this.item});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return Container(
      padding: EdgeInsets.fromLTRB(22, 22, 22, MediaQuery.paddingOf(context).bottom + 22),
      decoration: const BoxDecoration(color: Color(0xFFFBF8FD),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        SizedBox(width: 110, height: 100, child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Image.asset(item.preview, fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Icon(item.icon, size: 55, color: item.tint)))),
        const SizedBox(height: 9),
        Text(item.title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: Color(0xFF302938))),
        const SizedBox(height: 6),
        Text(item.description, textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFF766B84), fontSize: 12)),
        const SizedBox(height: 15),
        Text('Price: ${item.price} coins', style: const TextStyle(color: Color(0xFF98763B), fontWeight: FontWeight.w700)),
        const SizedBox(height: 20),
        if (uid != null)
          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance.collection('gamification_progress').doc(uid).snapshots(),
            builder: (context, snapshot) {
              final raw = snapshot.data?.data()?['coinBalance'];
              final current = raw is num ? raw.toInt() : 0;
              return Column(children: [
                Text('Balance: $current → ${current - item.price} coins',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF766B84))),
                const SizedBox(height: 12),
                SizedBox(width: double.infinity, child: FilledButton(
                  onPressed: current >= item.price ? () => Navigator.pop(context, true) : null,
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFF8460CB),
                    padding: const EdgeInsets.symmetric(vertical: 13)),
                  child: const Text('Confirm Purchase'),
                )),
              ]);
            },
          ),
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
      ]),
    );
  }
}
