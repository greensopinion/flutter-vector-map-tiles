mixin CacheStats {
  int _miss = 0;
  int _hit = 0;

  double get hitRatio {
    final total = _hit + _miss;
    return total > 0 ? _hit.toDouble() / (total).toDouble() : 0.0;
  }

  void cacheHit() {
    ++_hit;
  }

  void cacheMiss() {
    ++_miss;
  }
}
