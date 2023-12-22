import 'dart:typed_data';

enum TileProtoRequestType { loadStyleFromUri, loadTheme, tile }

var _requestId = 0;
String newTileProtoRequestId() => '${++_requestId}';

abstract class TileProtoRequest {
  final String requestId;
  final TileProtoRequestType requestType;
  final int timestamp = DateTime.now().millisecondsSinceEpoch;

  TileProtoRequest({required this.requestId, required this.requestType});

  String debugId() => '$runtimeType:${identityHashCode(this)}';

  Map toPayload();

  Map _payload() =>
      {_Fields.requestId: requestId, _Fields.requestType: requestType.index};

  static TileProtoRequest fromPayload(dynamic payload) {
    if (payload is Map) {
      final requestType = payload[_Fields.requestType];
      final requestId = payload[_Fields.requestId];
      if (requestType == TileProtoRequestType.loadStyleFromUri.index) {
        return LoadStyleFromUriRequest(
            requestId: requestId,
            uri: payload[_Fields.uri],
            apiKey: payload[_Fields.apiKey],
            tileOffset: payload[_Fields.tileOffset]);
      } else if (requestType == TileProtoRequestType.loadTheme.index) {
        return LoadThemeRequest(
            requestId: requestId,
            theme: payload[_Fields.theme],
            tileOffset: payload[_Fields.tileOffset],
            tileProviders: Map.fromEntries((payload[_Fields.tileProviders]
                    as Map<String, dynamic>)
                .entries
                .map((e) => MapEntry(e.key,
                    NetworkVectorTileProviderConfig.fromPayload(e.value)))));
      } else if (requestType == TileProtoRequestType.tile.index) {
        return TileRequest(
          requestId: requestId,
          z: payload[_Fields.z],
          x: payload[_Fields.x],
          y: payload[_Fields.y],
        );
      }
    }
    throw Exception('Unexpected payload: $payload');
  }
}

abstract class TileProtoResponse {
  final String requestId;
  final TileProtoRequestType requestType;
  final bool success;
  final String? errorMessage;
  final String? stack;

  TileProtoResponse(
      {required this.requestId,
      required this.requestType,
      required this.success,
      required this.errorMessage,
      required this.stack});

  Map toPayload();

  Map _payload() => {
        _Fields.requestId: requestId,
        _Fields.requestType: requestType.index,
        _Fields.success: success,
        _Fields.errorMessage: errorMessage,
        _Fields.stack: stack
      };

  static TileProtoResponse fromPayload(dynamic payload) {
    if (payload is Map) {
      final requestType = payload[_Fields.requestType];
      final requestId = payload[_Fields.requestId];
      final success = payload[_Fields.success];
      final errorMessage = payload[_Fields.errorMessage];
      final stack = payload[_Fields.stack];
      if (requestType == TileProtoRequestType.loadStyleFromUri.index) {
        return LoadStyleFromUriResponse(
            requestId: requestId,
            success: success,
            errorMessage: errorMessage,
            stack: stack);
      } else if (requestType == TileProtoRequestType.loadTheme.index) {
        return LoadThemeResponse(
            requestId: requestId,
            success: success,
            errorMessage: errorMessage,
            stack: stack);
      } else if (requestType == TileProtoRequestType.tile.index) {
        return TileResponse(
            requestId: requestId,
            success: success,
            errorMessage: errorMessage,
            stack: stack,
            tileData: payload[_Fields.tileData]);
      }
    }
    throw Exception('Unexpected payload: $payload');
  }
}

class LoadStyleFromUriRequest extends TileProtoRequest {
  final String uri;
  final String? apiKey;
  final int tileOffset;

  LoadStyleFromUriRequest(
      {required super.requestId,
      required this.uri,
      required this.apiKey,
      required this.tileOffset})
      : super(requestType: TileProtoRequestType.loadStyleFromUri);

  @override
  Map toPayload() {
    final payload = _payload();
    payload[_Fields.uri] = uri;
    payload[_Fields.apiKey] = apiKey;
    payload[_Fields.tileOffset] = tileOffset;
    return payload;
  }
}

class LoadStyleFromUriResponse extends TileProtoResponse {
  LoadStyleFromUriResponse(
      {required super.requestId,
      required super.success,
      required super.errorMessage,
      required super.stack})
      : super(requestType: TileProtoRequestType.loadStyleFromUri);

  @override
  Map toPayload() => _payload();
}

class LoadThemeRequest extends TileProtoRequest {
  final dynamic theme;
  final Map<String, NetworkVectorTileProviderConfig> tileProviders;
  final int tileOffset;

  LoadThemeRequest(
      {required super.requestId,
      required this.theme,
      required this.tileProviders,
      required this.tileOffset})
      : super(requestType: TileProtoRequestType.loadTheme);

  @override
  Map toPayload() {
    final payload = _payload();
    payload[_Fields.theme] = theme;
    payload[_Fields.tileOffset] = tileOffset;
    payload[_Fields.tileProviders] = Map.fromEntries(
        tileProviders.entries.map((e) => MapEntry(e.key, e.value.toPayload())));
    return payload;
  }
}

class NetworkVectorTileProviderConfig {
  final String urlTemplate;
  final Map<String, String> httpHeaders;
  final int? maximumZoom;
  final int? minimumZoom;

  NetworkVectorTileProviderConfig(
      {required this.urlTemplate,
      required this.httpHeaders,
      required this.maximumZoom,
      required this.minimumZoom});

  Map toPayload() {
    final payload = <String, dynamic>{};
    payload[_Fields.urlTemplate] = urlTemplate;
    payload[_Fields.httpHeaders] = httpHeaders;
    payload[_Fields.maximumZoom] = maximumZoom;
    payload[_Fields.minimumZoom] = minimumZoom;
    return payload;
  }

  static NetworkVectorTileProviderConfig fromPayload(payload) {
    return NetworkVectorTileProviderConfig(
        urlTemplate: payload[_Fields.urlTemplate],
        httpHeaders: payload[_Fields.httpHeaders],
        maximumZoom: payload[_Fields.maximumZoom],
        minimumZoom: payload[_Fields.minimumZoom]);
  }
}

class LoadThemeResponse extends TileProtoResponse {
  LoadThemeResponse(
      {required super.requestId,
      required super.success,
      required super.errorMessage,
      required super.stack})
      : super(requestType: TileProtoRequestType.loadTheme);

  @override
  Map toPayload() => _payload();
}

class TileRequest extends TileProtoRequest {
  final int z;
  final int x;
  final int y;

  TileRequest(
      {required super.requestId,
      required this.z,
      required this.x,
      required this.y})
      : super(requestType: TileProtoRequestType.tile);

  @override
  String debugId() => '${super.debugId()}:$z,$x,$y';

  @override
  Map toPayload() {
    final payload = _payload();
    payload[_Fields.z] = z;
    payload[_Fields.x] = x;
    payload[_Fields.y] = y;
    return payload;
  }
}

class TileResponse extends TileProtoResponse {
  final Uint8List? tileData;

  TileResponse(
      {required super.requestId,
      required super.success,
      required super.errorMessage,
      required super.stack,
      required this.tileData})
      : super(requestType: TileProtoRequestType.tile);

  @override
  Map toPayload() {
    final payload = _payload();
    payload[_Fields.tileData] = tileData;
    return payload;
  }
}

class _Fields {
  static const requestId = 'requestId';
  static const requestType = 'requestType';
  static const success = 'success';
  static const errorMessage = 'errorMessage';
  static const stack = 'stack';
  static const uri = 'uri';
  static const apiKey = 'apiKey';
  static const theme = 'theme';
  static const tileData = 'tileData';
  static const z = 'z';
  static const x = 'x';
  static const y = 'y';
  static const urlTemplate = 'urlTemplate';
  static const httpHeaders = 'httpHeaders';
  static const maximumZoom = 'maximumZoom';
  static const minimumZoom = 'minimumZoom';
  static const tileProviders = 'tileProviders';
  static const tileOffset = 'tileOffset';
}
