import 'package:latlong2/latlong.dart';
import 'package:test/test.dart';
import 'package:vector_map_tiles/src/style/style.dart';

void main() {
  test('reads a Mapbox style', () async {
    const apiToken =
        'pk.eyJ1IjoibWFwYm94IiwiYSI6ImNpejY4M29iazA2Z2gycXA4N2pmbDZmangifQ.-g_vE53SD2WrJ6tFX7QHmA';
    final reader = StyleReader(
        uri: 'mapbox://styles/mapbox/streets-v12?access_token=$apiToken');
    final style = await reader.read();
    expect(style.name, 'Mapbox Streets');
    expect(style.zoom, 2);
    expect(style.center, LatLng(37.75, -92.25));
    expect(style.providers.tileProviderBySource.keys.toSet(),
        <String>{'composite'});
  });
  test('reads a Stadia Maps style', () async {
    const apiToken = 'an-api-key';
    final reader = StyleReader(
        uri:
            'https://tiles.stadiamaps.com/styles/outdoors.json?api_key=$apiToken');
    final style = await reader.read();
    expect(style.name, 'Outdoors');
    expect(style.zoom, 11.6);
    expect(style.center, LatLng(47.372, 8.542));
    expect(style.providers.tileProviderBySource.keys.toSet(),
        <String>{'openmaptiles'});
  });
}
