import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(const VaultBreakerApp());
}

class VaultBreakerApp extends StatelessWidget {
  const VaultBreakerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Взломщик сейфа',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F1218),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00E5FF),
          secondary: Color(0xFFFFD54F),
        ),
      ),
      home: const VaultScreen(),
    );
  }
}

class GuessAttempt {
  final String guess;
  final int exactMatches;
  final int misplacedMatches;

  const GuessAttempt({
    required this.guess,
    required this.exactMatches,
    required this.misplacedMatches,
  });
}

class VaultScreen extends StatefulWidget {
  const VaultScreen({super.key});

  @override
  State<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen> {
  final Random _random = Random();
  late String _secretCode;
  final List<int> _currentDigits = [];
  final List<GuessAttempt> _history = [];
  bool _isUnlocked = false;

  @override
  void initState() {
    super.initState();
    _resetVault();
  }

  void _resetVault() {
    final digits = List<int>.generate(10, (i) => i)..shuffle(_random);
    setState(() {
      _secretCode = digits.take(3).join();
      _currentDigits.clear();
      _history.clear();
      _isUnlocked = false;
    });
  }

  void _onDigitPress(int digit) {
    if (_isUnlocked || _currentDigits.length >= 3) return;
    if (_currentDigits.contains(digit)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Цифры в коде не повторяются'),
          duration: Duration(milliseconds: 900),
        ),
      );
      return;
    }
    setState(() => _currentDigits.add(digit));
  }

  void _onBackspace() {
    if (_isUnlocked || _currentDigits.isEmpty) return;
    setState(() => _currentDigits.removeLast());
  }

  void _submitGuess() {
    if (_isUnlocked || _currentDigits.length != 3) return;

    final guessStr = _currentDigits.join();
    int exact = 0;
    int misplaced = 0;

    for (int i = 0; i < 3; i++) {
      final ch = guessStr[i];
      if (_secretCode[i] == ch) {
        exact++;
      } else if (_secretCode.contains(ch)) {
        misplaced++;
      }
    }

    setState(() {
      _history.insert(
        0,
        GuessAttempt(
          guess: guessStr,
          exactMatches: exact,
          misplacedMatches: misplaced,
        ),
      );
      _currentDigits.clear();
      if (exact == 3) {
        _isUnlocked = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Взломщик сейфа'),
        actions: [
          IconButton(
            onPressed: _resetVault,
            icon: const Icon(Icons.refresh),
            tooltip: 'Новый код',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF171C26),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _isUnlocked ? const Color(0xFF00E676) : Colors.white12,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    _isUnlocked
                        ? 'СЕЙФ ВЗЛОМАН! КОД: $_secretCode'
                        : 'Введите 3 разные цифры',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: _isUnlocked
                          ? const Color(0xFF00E676)
                          : Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (index) {
                      final hasDigit = index < _currentDigits.length;
                      return Container(
                        width: 56,
                        height: 64,
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F1218),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: hasDigit
                                ? const Color(0xFF00E5FF)
                                : Colors.white24,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            hasDigit ? '${_currentDigits[index]}' : '•',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: hasDigit ? Colors.white : Colors.white24,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _history.isEmpty
                  ? const Center(
                      child: Text(
                        'Попыток пока нет. Подберите комбинацию по подсказкам.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white38),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _history.length,
                      itemBuilder: (context, index) {
                        final item = _history[index];
                        final misses =
                            3 - item.exactMatches - item.misplacedMatches;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF171C26),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                item.guess,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 4,
                                ),
                              ),
                              Row(
                                children: [
                                  _Badge(
                                    label: 'На месте: ${item.exactMatches}',
                                    color: const Color(0xFF00E676),
                                  ),
                                  const SizedBox(width: 6),
                                  _Badge(
                                    label: 'Не там: ${item.misplacedMatches}',
                                    color: const Color(0xFFFFD54F),
                                  ),
                                  const SizedBox(width: 6),
                                  _Badge(
                                    label: 'Мимо: $misses',
                                    color: Colors.white38,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 8),
            _NumberPad(
              onDigit: _onDigitPress,
              onBackspace: _onBackspace,
              onSubmit: _currentDigits.length == 3 && !_isUnlocked
                  ? _submitGuess
                  : null,
              isUnlocked: _isUnlocked,
              onNewGame: _resetVault,
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _NumberPad extends StatelessWidget {
  final ValueChanged<int> onDigit;
  final VoidCallback onBackspace;
  final VoidCallback? onSubmit;
  final bool isUnlocked;
  final VoidCallback onNewGame;

  const _NumberPad({
    required this.onDigit,
    required this.onBackspace,
    required this.onSubmit,
    required this.isUnlocked,
    required this.onNewGame,
  });

  Widget _buildKey(String text, {VoidCallback? onTap, Color? highlight}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: highlight ?? const Color(0xFF1D2330),
              foregroundColor: highlight != null ? Colors.black : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              text,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isUnlocked) {
      return SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton.icon(
          onPressed: onNewGame,
          icon: const Icon(Icons.lock_open),
          label: const Text('Взломать новый сейф'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00E676),
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        for (final row in [
          [1, 2, 3],
          [4, 5, 6],
          [7, 8, 9],
        ])
          Row(
            children: [
              for (final d in row) _buildKey('$d', onTap: () => onDigit(d)),
            ],
          ),
        Row(
          children: [
            _buildKey('⌫', onTap: onBackspace),
            _buildKey('0', onTap: () => onDigit(0)),
            _buildKey(
              'ОК',
              onTap: onSubmit,
              highlight: onSubmit != null ? const Color(0xFF00E5FF) : null,
            ),
          ],
        ),
      ],
    );
  }
}
