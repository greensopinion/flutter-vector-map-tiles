import 'dart:developer';

import '../vector_map_tiles.dart';

/// Filter key for [TimelineTask]s that this library records.
///
/// Asynchronous tasks that are recorded by this library will be displayed in
/// their own lane, with this value as its name.
const _timelineTaskFilterKey = 'VectorMapTiles';

/// Prefix for [Timeline] events that this library records.
///
/// By searching for this value in the DevTools Performance page, you can find
/// all the [Timeline] events recorded by this library.
const _timelinePrefix = 'VMT';

TimelineTask tileRenderingTask(TileIdentity tile) =>
    TimelineTask(filterKey: _timelineTaskFilterKey)..start(_name('TileDelay'));

String _name(String name) {
  return '$_timelinePrefix::$name';
}
