import 'dart:io';

void main() {
  final lcovFile = File('coverage/lcov.info');
  if (!lcovFile.existsSync()) {
    print('coverage/lcov.info not found. Run flutter test --coverage first.');
    return;
  }

  final lines = lcovFile.readAsLinesSync();
  int totalFound = 0;
  int totalHit = 0;
  String? currentSF;

  final Map<String, Pair> fileStats = {};

  for (final line in lines) {
    if (line.startsWith('SF:')) {
      currentSF = line.substring(3);
    } else if (line.startsWith('LF:')) {
      final count = int.parse(line.substring(3));
      totalFound += count;
      if (currentSF != null) {
        fileStats.putIfAbsent(currentSF, () => Pair()).found = count;
      }
    } else if (line.startsWith('LH:')) {
      final count = int.parse(line.substring(3));
      totalHit += count;
      if (currentSF != null) {
        fileStats.putIfAbsent(currentSF, () => Pair()).hit = count;
      }
    }
  }

  final pct = totalFound == 0 ? 0.0 : (totalHit / totalFound) * 100;
  print('====================================================');
  print('          Coverage Analysis Summary                ');
  print('====================================================');
  print('Total Executable Lines: $totalFound');
  print('Lines Hit by Tests:     $totalHit');
  print('Line Coverage Rate:     ${pct.toStringAsFixed(2)}%\n');

  print('Per-File Coverage Breakdowns:');
  fileStats.forEach((file, stat) {
    final filePct = stat.found == 0 ? 0.0 : (stat.hit / stat.found) * 100;
    print('  - ${file.split('/lib/').last}: ${filePct.toStringAsFixed(1)}% (${stat.hit}/${stat.found} lines)');
  });
  print('====================================================');
}

class Pair {
  int found = 0;
  int hit = 0;
}
