import 'dart:math';

class UsernameGenerator {
  static const List<String> _prefixes = [
    'Ghost',
    'Shadow',
    'Neon',
    'Phantom',
    'Void',
    'Whisper',
    'Vortex',
    'Spectre',
    'Cyber',
    'Cipher',
    'Astral',
    'Ember',
    'Eclipse',
    'Rogue',
    'Glitch',
    'Echo',
    'Drift',
    'Strobe',
    'Static',
    'Nova'
  ];

  static String generate() {
    final random = Random();
    final prefix = _prefixes[random.nextInt(_prefixes.length)];
    final suffixNumber = 1000 + random.nextInt(9000); // 1000 to 9999
    return '${prefix}_$suffixNumber';
  }
}
