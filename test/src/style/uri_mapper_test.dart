import 'package:test/test.dart';
import 'package:vector_map_tiles/src/style/uri_mapper.dart';

void main() {
  group('Style', () {
    test('maps a standard URI', () {
      const styleUri = 'https://tiles.stadiamaps.com/styles/outdoors.json';
      final mapped = StyleUriMapper().map(styleUri);
      expect(mapped, styleUri);
    });
    test('maps a mapbox URI with parameters', () {
      final mapped = StyleUriMapper()
          .map('mapbox://styles/mapbox/streets-v12?access_token=a-token-123');
      expect(mapped,
          'https://api.mapbox.com/styles/v1/mapbox/streets-v12?access_token=a-token-123');
    });
    test('maps a mapbox URI without parameters', () {
      final mapped = StyleUriMapper().map('mapbox://styles/mapbox/streets-v12');
      expect(mapped, 'https://api.mapbox.com/styles/v1/mapbox/streets-v12');
    });
  });
  group('Source', () {
    test('maps a URI source', () {
      const aKey = 'aKey123';
      const styleUri =
          'https://tiles.stadiamaps.com/styles/outdoors.json?api_key=$aKey';
      const sourceUri =
          'https://tiles.stadiamaps.com/data/openmaptiles.json?api_key=$aKey';
      final mapped = StyleUriMapper(key: aKey).mapSource(styleUri, sourceUri);
      expect(mapped,
          'https://tiles.stadiamaps.com/data/openmaptiles.json?api_key=$aKey');
    });
    test('maps a mapbox source', () {
      const aKey = 'aKey123';
      const styleUri =
          'https://api.mapbox.com/styles/v1/mapbox/streets-v12/?access_token=$aKey';
      const sourceUri =
          'mapbox://mapbox.mapbox-streets-v8,mapbox.mapbox-terrain-v2,mapbox.mapbox-bathymetry-v2';
      final mapped = StyleUriMapper(key: aKey).mapSource(styleUri, sourceUri);
      expect(mapped,
          'https://api.mapbox.com/v4/mapbox.mapbox-streets-v8,mapbox.mapbox-terrain-v2,mapbox.mapbox-bathymetry-v2.json?secure&access_token=aKey123');
    });
  });
}
