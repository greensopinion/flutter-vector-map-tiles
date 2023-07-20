import 'package:latlong2/latlong.dart';
import 'package:test/test.dart';
import 'package:vector_map_tiles/src/style/style.dart';

void main() {
  test('reads a Stadia Maps style', () async {
    const apiToken = 'an-api-key';
    final reader = StyleReader(
        uri:
            'https://tiles.stadiamaps.com/styles/outdoors.json?api_key=$apiToken');
    final style = await reader.read();
    expect(style.name, 'Outdoors');
    expect(style.zoom, 11.6);
    expect(style.center, const LatLng(47.372, 8.542));
    expect(style.providers.tileProviderBySource.keys.toSet(),
        <String>{'openmaptiles'});
  });
}
