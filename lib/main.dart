import 'dart:math';

import 'package:flutter/material.dart';

void main() => runApp(const NeonStrikeApp());

class NeonStrikeApp extends StatelessWidget {
  const NeonStrikeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Neon Strike',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF100D1D),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF5B52),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const CombatScreen(),
    );
  }
}

class Combatant {
  Combatant({required this.name, required this.maxHp, required this.power})
      : hp = maxHp;

  final String name;
  final int maxHp;
  final int power;
  int hp;
}

class CombatScreen extends StatefulWidget {
  const CombatScreen({super.key});

  @override
  State<CombatScreen> createState() => _CombatScreenState();
}

class _CombatScreenState extends State<CombatScreen>
    with SingleTickerProviderStateMixin {
  final _random = Random();
  late Combatant _player;
  late Combatant _opponent;
  late AnimationController _idleAnimation;

  String _message = 'Choose your move';
  int _combo = 0;
  bool _busy = false;
  bool _gameOver = false;
  bool _playerStriking = false;
  bool _opponentStriking = false;

  @override
  void initState() {
    super.initState();
    _resetFighters();
    _idleAnimation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
      lowerBound: 0.97,
      upperBound: 1.03,
    )..repeat(reverse: true);
  }

  void _resetFighters() {
    _player = Combatant(name: 'Viper', maxHp: 100, power: 18);
    _opponent = Combatant(name: 'Kane', maxHp: 100, power: 16);
  }

  @override
  void dispose() {
    _idleAnimation.dispose();
    super.dispose();
  }

  Future<void> _attack({required bool heavy}) async {
    if (_busy || _gameOver) return;
    setState(() {
      _busy = true;
      _playerStriking = true;
      _message = heavy ? 'VIPER • HEAVY STRIKE' : 'VIPER • QUICK RUSH';
    });

    await Future<void>.delayed(const Duration(milliseconds: 220));
    if (!mounted) return;

    final critical = _random.nextDouble() < 0.18;
    final baseDamage = heavy ? _player.power + 9 : _player.power - 2;
    final damage = baseDamage + (critical ? 10 : 0);
    setState(() {
      _opponent.hp = max(0, _opponent.hp - damage);
      _playerStriking = false;
      _combo++;
      _message = critical
          ? 'CRITICAL HIT!  −$damage HP'
          : '${heavy ? 'Heavy strike' : 'Quick rush'}!  −$damage HP';
    });

    if (_opponent.hp == 0) {
      _finish(true);
      return;
    }
    await _opponentTurn();
  }

  Future<void> _repairArmor() async {
    if (_busy || _gameOver || _player.hp == _player.maxHp) return;
    setState(() {
      _busy = true;
      _combo = 0;
      final healed = min(20, _player.maxHp - _player.hp);
      _player.hp += healed;
      _message = 'ARMOR REPAIRED  +$healed HP';
    });
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    await _opponentTurn();
  }

  Future<void> _opponentTurn() async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;
    setState(() {
      _opponentStriking = true;
      _message = 'KANE IS COUNTERING…';
    });
    await Future<void>.delayed(const Duration(milliseconds: 240));
    if (!mounted) return;

    final damage = _opponent.power + _random.nextInt(7);
    setState(() {
      _player.hp = max(0, _player.hp - damage);
      _opponentStriking = false;
      _combo = 0;
      _message = 'COUNTER HIT!  −$damage HP';
      _busy = false;
    });
    if (_player.hp == 0) _finish(false);
  }

  void _finish(bool won) {
    setState(() {
      _gameOver = true;
      _busy = false;
      _playerStriking = false;
      _opponentStriking = false;
      _message = won ? 'VICTORY • KANE DEFEATED' : 'DEFEAT • VIPER HAS FALLEN';
    });
  }

  void _rematch() {
    setState(() {
      _resetFighters();
      _message = 'Choose your move';
      _combo = 0;
      _busy = false;
      _gameOver = false;
      _playerStriking = false;
      _opponentStriking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF21183C), Color(0xFF100D1D)],
            ),
          ),
          child: Column(
            children: [
              _buildTopBar(),
              _buildFighterHud(),
              Expanded(child: _buildArena()),
              _buildBattleMessage(),
              _buildActions(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        children: [
          const Icon(Icons.bolt, color: Color(0xFFFFC857), size: 23),
          const SizedBox(width: 7),
          const Text(
            'NEON STRIKE',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 2),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white12),
            ),
            child: const Row(
              children: [
                Icon(Icons.circle, size: 7, color: Color(0xFF70E1A1)),
                SizedBox(width: 6),
                Text('ARENA 01', style: TextStyle(fontSize: 10, letterSpacing: 1)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFighterHud() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 4),
      child: Row(
        children: [
          Expanded(child: _healthPanel(_player, const Color(0xFF3BD8FF))),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFF5B52).withOpacity(0.13),
              border: Border.all(color: const Color(0xFFFF5B52).withOpacity(0.5)),
            ),
            child: const Text('VS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
          ),
          Expanded(child: _healthPanel(_opponent, const Color(0xFFFF586B), alignRight: true)),
        ],
      ),
    );
  }

  Widget _healthPanel(Combatant fighter, Color color, {bool alignRight = false}) {
    return Column(
      crossAxisAlignment: alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(fighter.name.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.6)),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: fighter.hp / fighter.maxHp,
            minHeight: 9,
            backgroundColor: Colors.white10,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        const SizedBox(height: 4),
        Text('${fighter.hp} / ${fighter.maxHp} HP', style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.58))),
      ],
    );
  }

  Widget _buildArena() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final fighterWidth = min(138.0, constraints.maxWidth * 0.36);
        return Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            const Positioned.fill(child: CustomPaint(painter: ArenaPainter())),
            Positioned(
              left: 0,
              right: 0,
              bottom: 20,
              child: Center(
                child: Container(
                  width: constraints.maxWidth * 0.72,
                  height: 22,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(100),
                    boxShadow: [BoxShadow(color: const Color(0xFF8A61FF).withOpacity(0.28), blurRadius: 35, spreadRadius: 7)],
                  ),
                ),
              ),
            ),
            Positioned(
              left: constraints.maxWidth * 0.07,
              bottom: 34,
              child: _animatedFighter(width: fighterWidth, color: const Color(0xFF3BD8FF), enemy: false),
            ),
            Positioned(
              right: constraints.maxWidth * 0.07,
              bottom: 34,
              child: _animatedFighter(width: fighterWidth, color: const Color(0xFFFF586B), enemy: true),
            ),
            Positioned(
              top: 20,
              left: 0,
              right: 0,
              child: Center(
                child: Text('THE UNDERCITY', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 10, letterSpacing: 4, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _animatedFighter({required double width, required Color color, required bool enemy}) {
    return AnimatedBuilder(
      animation: _idleAnimation,
      builder: (context, child) {
        final attacking = enemy ? _opponentStriking : _playerStriking;
        return Transform.translate(
          offset: Offset(attacking ? (enemy ? -22 : 22) : 0, (1 - _idleAnimation.value) * 55),
          child: Transform.scale(
            scaleX: enemy ? -1 : 1,
            child: SizedBox(
              width: width,
              height: width * 1.48,
              child: CustomPaint(painter: FighterPainter(color: color)),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBattleMessage() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      child: Container(
        key: ValueKey(_message),
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(18, 4, 18, 14),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.055),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.09)),
        ),
        child: Column(
          children: [
            Text(_message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1.1)),
            if (_combo > 1 && !_gameOver) ...[
              const SizedBox(height: 4),
              Text('COMBO  ×$_combo', style: const TextStyle(color: Color(0xFFFFC857), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.8)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActions() {
    if (_gameOver) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: SizedBox(
          width: double.infinity,
          height: 58,
          child: FilledButton.icon(
            onPressed: _rematch,
            icon: const Icon(Icons.refresh),
            label: const Text('FIGHT AGAIN', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5)),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFFF5B52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          Expanded(child: _actionButton('RUSH', 'FAST • 16 DMG', Icons.flash_on, const Color(0xFF3BD8FF), () => _attack(heavy: false))),
          const SizedBox(width: 8),
          Expanded(child: _actionButton('HEAVY', 'SLOW • 27 DMG', Icons.sports_mma, const Color(0xFFFFC857), () => _attack(heavy: true))),
          const SizedBox(width: 8),
          Expanded(child: _actionButton('REPAIR', '+20 HP', Icons.shield_outlined, const Color(0xFF70E1A1), _repairArmor, disabled: _player.hp == _player.maxHp)),
        ],
      ),
    );
  }

  Widget _actionButton(String title, String subtitle, IconData icon, Color color, VoidCallback onPressed, {bool disabled = false}) {
    final active = !_busy && !disabled;
    return Opacity(
      opacity: active ? 1 : 0.45,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: active ? onPressed : null,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            height: 82,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [color.withOpacity(0.2), color.withOpacity(0.055)]),
              border: Border.all(color: color.withOpacity(0.48)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 21, color: color),
                const SizedBox(height: 3),
                Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.8)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(fontSize: 8, color: Colors.white.withOpacity(0.55))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ArenaPainter extends CustomPainter {
  const ArenaPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final haze = Paint()
      ..shader = RadialGradient(colors: [const Color(0xFF7455E8).withOpacity(0.24), Colors.transparent]).createShader(
        Rect.fromCircle(center: Offset(size.width / 2, size.height * 0.72), radius: size.width * 0.72),
      );
    canvas.drawRect(Offset.zero & size, haze);

    final floorTop = size.height * 0.69;
    final floor = Paint()
      ..shader = const LinearGradient(colors: [Color(0xFF352653), Color(0xFF171224)], begin: Alignment.topCenter, end: Alignment.bottomCenter)
          .createShader(Rect.fromLTWH(0, floorTop, size.width, size.height - floorTop));
    canvas.drawRect(Rect.fromLTWH(0, floorTop, size.width, size.height - floorTop), floor);

    final grid = Paint()..color = Colors.white.withOpacity(0.075)..strokeWidth = 1;
    for (var i = 0; i < 6; i++) {
      final y = floorTop + i * (size.height - floorTop) / 5;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    for (var i = -3; i <= 3; i++) {
      canvas.drawLine(Offset(size.width / 2, floorTop), Offset(size.width / 2 + i * size.width / 2, size.height), grid);
    }

    final speck = Paint()..color = const Color(0xFFB8A7FF).withOpacity(0.28);
    for (var i = 0; i < 18; i++) {
      final x = (i * 73.0) % size.width;
      final y = (i * 47.0) % (floorTop * 0.85);
      canvas.drawCircle(Offset(x, y), i % 4 == 0 ? 1.7 : 1, speck);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class FighterPainter extends CustomPainter {
  const FighterPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 138;
    final sy = size.height / 204;
    canvas.save();
    canvas.scale(sx, sy);

    final shadow = Paint()..color = Colors.black.withOpacity(0.42);
    final armor = Paint()..color = color;
    final armorDark = Paint()..color = Color.lerp(color, const Color(0xFF10101D), 0.48)!;
    final skin = Paint()..color = const Color(0xFFE9AC8D);
    final ink = Paint()..color = const Color(0xFF12101B);
    final shine = Paint()..color = Colors.white.withOpacity(0.82);

    canvas.drawOval(Rect.fromCenter(center: const Offset(70, 193), width: 112, height: 19), shadow);

    // Boots and armored legs
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(38, 139, 25, 48), const Radius.circular(8)), armorDark);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(76, 139, 25, 48), const Radius.circular(8)), armorDark);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(31, 177, 36, 15), const Radius.circular(6)), ink);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(72, 177, 36, 15), const Radius.circular(6)), ink);

    // Torso silhouette
    final torso = Path()
      ..moveTo(41, 69)..lineTo(92, 69)..lineTo(111, 143)..lineTo(27, 143)..close();
    canvas.drawPath(torso, armor);
    final chest = Path()
      ..moveTo(48, 77)..lineTo(85, 77)..lineTo(94, 116)..lineTo(39, 116)..close();
    canvas.drawPath(chest, armorDark);

    // Head, hair and glowing visor
    canvas.drawCircle(const Offset(67, 45), 27, skin);
    canvas.drawArc(const Rect.fromLTWH(39, 17, 56, 38), pi, pi, true, ink);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(43, 42, 48, 10), const Radius.circular(5)), shine);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(49, 44, 35, 4), const Radius.circular(2)), Paint()..color = color);

    // Guarding arm and fist
    canvas.save();
    canvas.rotate(-0.2);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(94, 75, 20, 59), const Radius.circular(10)), armorDark);
    canvas.drawCircle(const Offset(104, 137), 13, skin);
    canvas.restore();
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(24, 80, 18, 46), const Radius.circular(9)), armor);

    // Chest insignia
    final emblem = Paint()..color = color.withOpacity(0.9);
    canvas.drawCircle(const Offset(67, 96), 8, emblem);
    canvas.drawCircle(const Offset(67, 96), 3, shine);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant FighterPainter oldDelegate) => oldDelegate.color != color;
}
