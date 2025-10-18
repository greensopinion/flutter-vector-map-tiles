import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:stash/stash_api.dart' as stash;
import 'package:vector_tile_renderer/vector_tile_renderer.dart';

import 'cache.dart';

typedef BinaryCache = stash.Cache<Uint8List>;
typedef CacheFactory = Future<BinaryCache> Function();

class AbstractStashCache extends Cache {
  final String name;
  final CacheFactory cacheFactory;
  Future<BinaryCache>? _delegateFuture;
  BinaryCache? _delegate;
  final _loading = <String, Future<Uint8List>>{};

  AbstractStashCache({required this.name, required this.cacheFactory});

  @override
  Future<Uint8List> get(String inputKey, {required LoadFunction load}) async {
    final lookupKey = inputKey.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final cache = await _cache();
    var entry = await cache.get(lookupKey);
    if (entry == null) {
      var completer = Completer<Uint8List>();
      var future = _loading[lookupKey];
      if (future == null) {
        future = completer.future;
        _loading[lookupKey] = future;
        try {
          entry = await load(lookupKey);
          try {
            await cache.put(lookupKey, entry);
          } on PathNotFoundException catch (_) {
            //ignore, expected (why?)
          } catch (e, stack) {
            const Logger.console().warn(() => '$e\n$stack');
          }
          completer.complete(entry);
        } catch (e) {
          completer.completeError(e);
        } finally {
          _loading.remove(lookupKey);
        }
      }
      return await future;
    }
    if (cache.statsEnabled) {
      emitStats(cache, lookupKey);
    }
    return entry;
  }

  Future<BinaryCache> _cache() async {
    var delegate = _delegate;
    if (delegate == null) {
      var future = _delegateFuture;
      if (future == null) {
        future = cacheFactory();
        _delegateFuture = future;
      }
      delegate = await future;
      _delegate = delegate;
      _delegateFuture = null;
    }
    return delegate;
  }

  void emitStats(BinaryCache cache, String key) {
    final stats = cache.stats;
    // ignore: avoid_print
    print(
      'Cache $name stats: requests=${stats.requests} gets=${stats.gets} (${stats.getPercentage.toStringAsFixed(2)}%) puts=${stats.puts} misses=${stats.misses} (${stats.missPercentage.toStringAsFixed(2)}%) misses=${stats.misses} expiries=${stats.expiries} evictions=${stats.evictions} key=$key',
    );
  }
}
