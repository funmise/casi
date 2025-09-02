int daysUntilNextQuarter(DateTime now) {
  int nextStartMonth(int m) => [1, 4, 7, 10][((m - 1) ~/ 3 + 1) % 4];
  final m = nextStartMonth(now.month);
  final yearBump = (m <= now.month) ? 1 : 0;
  final nextStart = DateTime(now.year + yearBump, m, 1);
  return nextStart.difference(DateTime(now.year, now.month, now.day)).inDays;
}
