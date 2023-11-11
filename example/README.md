# vector_map_tiles_example

An example of `flutter_map` using vector tiles provided by the `vector_map_tiles` package.

## To Use

1. Get an API key from [Stadia Maps](https://stadiamaps.com), [MapTiler](https://www.maptiler.com/) or [Mapbox](https://www.mapbox.com/)
2. Create a file `lib/api_key.dart` as follows:
    ```dart
    const stadiaMapsApiKey = '<your_stadiamaps_api_key>';
    const maptilerApiKey = '<your_maptiler_api_key>';
    const mapboxApiKey = '<your_mapbox_api_key>';
    ```
3. Update `example/main.dart` to use the URL of the map provider that you selected and corresponding API key
4. Run the example app