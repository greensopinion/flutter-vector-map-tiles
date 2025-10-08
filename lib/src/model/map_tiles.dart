import 'package:executor_lib/executor_lib.dart';

import '../../vector_map_tiles.dart';
import '../layout/tile_position.dart';
import '../loader/tile_loader.dart';
import 'safe_change_notifier.dart';
import 'tile_data_model.dart';

class MapTiles extends SafeChangeNotifier {
  final _tiles = <TileIdentity, TileDataModel>{};
  final _jobs = <TileIdentity, _TileJob>{};
  List<TileIdentity> _latestTileIds = [];

  List<TileDataModel> get tileModels =>
      _tiles.values.toList()..sort(_zOrderSort);

  List<TileDataModel> get obsoleteModels => _latestTileIds.isEmpty
      ? []
      : _tiles.values
            .where((it) => _latestTileIds.first.z != it.tile.z)
            .toList();

  final TileLoader tileLoader;

  MapTiles({required this.tileLoader});

  void updateTiles(Iterable<TilePosition> neededTiles) {
    if (isDisposed) {
      return;
    }
    final originalTilePositions = _tiles.values
        .map((e) => e.tilePosition)
        .toSet();
    _latestTileIds = neededTiles.map((e) => e.tile).toList(growable: false);
    final idToTilePosition = Map.fromEntries(
      neededTiles.map((e) => MapEntry(e.tile, e)),
    );
    final newTiles = <TileDataModel>[];
    for (final tilePosition in idToTilePosition.values) {
      var model = _tiles[tilePosition.tile];
      if (model == null) {
        model = TileDataModel(tilePosition);
        _tiles[tilePosition.tile] = model;
        newTiles.add(model);
      } else {
        model.tilePosition = tilePosition;
      }
    }
    bool removedSome = _removeObsoleteTiles();
    for (var model in newTiles) {
      _startLoading(model);
    }
    final newTilePositions = _tiles.values.map((e) => e.tilePosition).toSet();
    if (removedSome || !_equals(newTilePositions, originalTilePositions)) {
      notifyListeners();
    }
  }

  List<TileDataModel> _computeTilesToRemove() {
    final neededTileIds = _latestTileIds.toSet();
    final loadingTileModels = _tiles.values
        .where((it) => !it.isDisplayReady)
        .toList();
    final obsoleteModels = _tiles.values
        .where((model) => !neededTileIds.contains(model.tile))
        .toList();
    if (loadingTileModels.isEmpty || neededTileIds.isEmpty) {
      return obsoleteModels;
    }
    final zoom = neededTileIds.first.z;
    const maxZoomDifference = 5;
    final toRetain = obsoleteModels
        .where(
          (it) =>
              it.isDisplayReady &&
              (it.tile.z - zoom).abs() <= maxZoomDifference &&
              it.tile.z != zoom &&
              loadingTileModels.any(
                (loadingTile) => loadingTile.tile.overlaps(it.tile),
              ),
        )
        .toList();
    final toRetainIds = toRetain.map((it) => it.tile).toSet();
    return obsoleteModels
        .where((it) => !toRetainIds.contains(it.tile))
        .toList();
  }

  void _startLoading(TileDataModel model) {
    final job = _TileJob(model);
    _jobs[model.tile] = job;
    _start(job);
  }

  @override
  void dispose() {
    if (!isDisposed) {
      super.dispose();
      _remove(_tiles.values.toList());
      _jobs.clear();
      _tiles.clear();
    }
  }

  bool _equals(Set<TilePosition> a, Set<TilePosition> b) =>
      a.containsAll(b) && b.containsAll(a);

  void _start(_TileJob job) async {
    try {
      await tileLoader.load(job.model, () => job.cancelled);
    } on CancellationException catch (_) {
      _tiles.remove(job.model.tile);
      job.model.dispose();
    } finally {
      _jobs.remove(job.model.tile);
      _removeObsoleteTiles();
      notifyListeners();
    }
  }

  bool _removeObsoleteTiles() {
    final toRemove = _computeTilesToRemove();
    _remove(toRemove);
    return toRemove.isNotEmpty;
  }

  void _remove(List<TileDataModel> toRemove) {
    for (var model in toRemove) {
      _jobs.remove(model.tile)?.cancel();
      _tiles.remove(model.tile);
      model.dispose();
    }
  }
}

class _TileJob {
  bool cancelled = false;
  final TileDataModel model;
  _TileJob(this.model);

  void cancel() {
    cancelled = true;
  }
}

int _zOrderSort(TileDataModel a, TileDataModel b) {
  var i = a.tile.z.compareTo(b.tile.z);
  if (i == 0) {
    i = a.tile.x.compareTo(b.tile.x);
    if (i == 0) {
      i = a.tile.y.compareTo(b.tile.y);
    }
  }
  return i;
}
