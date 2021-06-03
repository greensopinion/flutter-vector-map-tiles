Map<String, dynamic> testStyle() => {
      "version": 8,
      "name": "Empty Style",
      "metadata": {"maputnik:renderer": "mbgljs"},
      "sources": {
        "openmaptiles": {
          "type": "vector",
          "url": "https://api.maptiler.com/tiles/v3/tiles.json?key={key}"
        }
      },
      "sprite": "",
      "glyphs":
          "https://orangemug.github.io/font-glyphs/glyphs/{fontstack}/{range}.pbf",
      "layers": [
        {
          "id": "background",
          "type": "background",
          "paint": {"background-color": "#f1f3f4"}
        },
        {
          "id": "landcover_grass",
          "type": "fill",
          "source": "openmaptiles",
          "source-layer": "landcover",
          "filter": [
            "all",
            ["==", "class", "grass"]
          ],
          "paint": {"fill-color": "#81c784", "fill-opacity": 0.2}
        },
        {
          "id": "landcover_wood",
          "type": "fill",
          "source": "openmaptiles",
          "source-layer": "landcover",
          "filter": [
            "all",
            ["==", "class", "wood"]
          ],
          "paint": {"fill-color": "#81c784", "fill-opacity": 0.5}
        },
        {
          "id": "park",
          "type": "fill",
          "source": "openmaptiles",
          "source-layer": "park",
          "paint": {
            "fill-color": "#81c784",
            "fill-outline-color": "#66bb6a",
            "fill-opacity": 0.5
          }
        },
        {
          "id": "landcover_sand",
          "type": "fill",
          "source": "openmaptiles",
          "source-layer": "landcover",
          "filter": [
            "all",
            ["==", "class", "sand"]
          ],
          "paint": {"fill-color": "#fffde7"}
        },
        {
          "id": "landcover_ice",
          "type": "fill",
          "source": "openmaptiles",
          "source-layer": "landcover",
          "filter": [
            "all",
            ["==", "class", "ice"]
          ],
          "paint": {"fill-color": "rgba(206, 240, 253, 1)", "fill-opacity": 0.8}
        },
        {
          "id": "water",
          "type": "fill",
          "source": "openmaptiles",
          "source-layer": "water",
          "filter": [
            "all",
            ["!=", "brunnel", "tunnel"]
          ],
          "paint": {"fill-color": "#bbdefb"}
        },
        {
          "id": "aeroway",
          "type": "fill",
          "source": "openmaptiles",
          "source-layer": "aeroway",
          "minzoom": 10,
          "paint": {"fill-color": "#0e0e0e", "fill-opacity": 0.05}
        },
        {
          "id": "aeroway_taxiway",
          "type": "line",
          "source": "openmaptiles",
          "source-layer": "aeroway",
          "minzoom": 12,
          "filter": [
            "all",
            ["==", "\$type", "LineString"],
            ["!=", "class", "runway"]
          ],
          "layout": {"line-cap": "round", "line-join": "miter"},
          "paint": {
            "line-color": "#fafafa",
            "line-width": {
              "base": 1.2,
              "stops": [
                [11, 1.2],
                [20, 14]
              ]
            }
          }
        },
        {
          "id": "aeroway_runway",
          "type": "line",
          "source": "openmaptiles",
          "source-layer": "aeroway",
          "minzoom": 9,
          "filter": [
            "all",
            ["==", "\$type", "LineString"],
            ["==", "class", "runway"]
          ],
          "layout": {"line-cap": "butt", "line-join": "round"},
          "paint": {
            "line-color": "#fafafa",
            "line-width": {
              "base": 1.2,
              "stops": [
                [11, 2],
                [16, 20]
              ]
            }
          }
        },
        {
          "id": "transportation_pattern",
          "type": "fill",
          "source": "openmaptiles",
          "source-layer": "transportation",
          "filter": [
            "all",
            ["==", "\$type", "Polygon"]
          ],
          "paint": {"fill-color": "rgba(245, 245, 245, 0.2)"}
        },
        {
          "id": "waterway_tunnel",
          "type": "line",
          "source": "openmaptiles",
          "source-layer": "waterway",
          "filter": [
            "all",
            ["==", "brunnel", "tunnel"]
          ],
          "layout": {"line-cap": "round", "line-join": "round"},
          "paint": {
            "line-color": "#b0bec5",
            "line-width": {
              "base": 1.4,
              "stops": [
                [8, 1],
                [20, 2]
              ]
            }
          }
        },
        {
          "id": "waterway_other",
          "type": "line",
          "source": "openmaptiles",
          "source-layer": "waterway",
          "filter": [
            "all",
            ["!=", "class", "river"],
            ["!=", "brunnel", "tunnel"]
          ],
          "layout": {"line-cap": "round", "line-join": "round"},
          "paint": {
            "line-width": {
              "base": 1.3,
              "stops": [
                [13, 0.5],
                [20, 6]
              ]
            },
            "line-color": "#bbdefb"
          }
        },
        {
          "id": "waterway_river",
          "type": "line",
          "source": "openmaptiles",
          "source-layer": "waterway",
          "filter": [
            "all",
            ["==", "class", "river"],
            ["!=", "brunnel", "tunnel"]
          ],
          "layout": {"line-cap": "round", "line-join": "round"},
          "paint": {
            "line-width": {
              "base": 1.2,
              "stops": [
                [11, 0.5],
                [20, 6]
              ]
            },
            "line-color": "#bbdefb"
          }
        },
        {
          "id": "bridge_path_pedestrian_casing",
          "type": "line",
          "source": "openmaptiles",
          "source-layer": "transportation",
          "filter": [
            "all",
            ["==", "\$type", "LineString"],
            ["==", "brunnel", "bridge"],
            ["in", "class", "pedestrian", "path"]
          ],
          "paint": {
            "line-color": "#e0e0e0",
            "line-width": {
              "base": 1.2,
              "stops": [
                [14, 1.5],
                [20, 18]
              ]
            }
          }
        },
        {
          "id": "bridge_path_pedestrian-copy",
          "type": "line",
          "source": "openmaptiles",
          "source-layer": "transportation",
          "filter": [
            "all",
            ["==", "\$type", "LineString"],
            ["==", "brunnel", "bridge"],
            ["in", "class", "pedestrian", "path"]
          ],
          "paint": {
            "line-color": "#ffffff",
            "line-width": {
              "base": 1.2,
              "stops": [
                [14, 0.5],
                [20, 10]
              ]
            }
          }
        },
        {
          "id": "path_pedestrian",
          "type": "line",
          "source": "openmaptiles",
          "source-layer": "transportation",
          "filter": [
            "all",
            ["==", "\$type", "LineString"],
            ["!in", "brunnel", "bridge"],
            ["in", "class", "pedestrian", "path"]
          ],
          "paint": {
            "line-color": "#ffffff",
            "line-width": {
              "base": 1.2,
              "stops": [
                [14, 0.5],
                [20, 10]
              ]
            }
          }
        },
        {
          "id": "rail",
          "type": "line",
          "source": "openmaptiles",
          "source-layer": "transportation",
          "minzoom": 11,
          "filter": [
            "all",
            ["in", "class", "rail"]
          ],
          "paint": {"line-color": "#ccc", "line-width": 2}
        },
        {
          "id": "road_service_track_casing",
          "type": "line",
          "source": "openmaptiles",
          "source-layer": "transportation",
          "minzoom": 14,
          "filter": [
            "all",
            ["==", "\$type", "LineString"],
            ["in", "class", "service", "track"]
          ],
          "layout": {"line-cap": "butt", "line-join": "round"},
          "paint": {
            "line-color": "#dadcdf",
            "line-width": {
              "base": 1.2,
              "stops": [
                [15, 1],
                [16, 4],
                [20, 11]
              ]
            }
          }
        },
        {
          "id": "road_minor_casing",
          "type": "line",
          "source": "openmaptiles",
          "source-layer": "transportation",
          "minzoom": 12.5,
          "filter": [
            "all",
            ["==", "\$type", "LineString"],
            ["==", "class", "minor"]
          ],
          "layout": {"line-cap": "butt", "line-join": "round"},
          "paint": {
            "line-color": "#dadcdf",
            "line-width": {
              "base": 1.2,
              "stops": [
                [12, 0.5],
                [13, 1],
                [14, 4],
                [20, 20]
              ]
            }
          }
        },
        {
          "id": "road_motorway_ramp_casing",
          "type": "line",
          "source": "openmaptiles",
          "source-layer": "transportation",
          "filter": [
            "all",
            ["in", "class", "motorway"],
            ["==", "ramp", 1]
          ],
          "layout": {
            "line-join": "round",
            "line-cap": "butt",
            "visibility": "visible"
          },
          "paint": {
            "line-color": "#ffca28",
            "line-width": {
              "base": 1.2,
              "stops": [
                [12, 1],
                [13, 3],
                [14, 4],
                [20, 15]
              ]
            }
          }
        },
        {
          "id": "road_secondary_tertiary_casing",
          "type": "line",
          "source": "openmaptiles",
          "source-layer": "transportation",
          "minzoom": 11,
          "filter": [
            "all",
            ["in", "class", "secondary", "tertiary"]
          ],
          "layout": {"line-join": "round", "line-cap": "butt"},
          "paint": {
            "line-color": "#dadcdf",
            "line-width": {
              "base": 1.2,
              "stops": [
                [8, 3.5],
                [20, 17]
              ]
            }
          }
        },
        {
          "id": "road_motorway_casing",
          "type": "line",
          "source": "openmaptiles",
          "source-layer": "transportation",
          "filter": [
            "all",
            ["in", "class", "motorway"],
            ["!=", "ramp", 1]
          ],
          "layout": {"line-cap": "butt", "line-join": "round"},
          "paint": {
            "line-color": "#ffca28",
            "line-width": {
              "base": 1.2,
              "stops": [
                [5, 0.4],
                [6, 0.7],
                [7, 1.75],
                [20, 22]
              ]
            }
          }
        },
        {
          "id": "road_primary_casing",
          "type": "line",
          "source": "openmaptiles",
          "source-layer": "transportation",
          "filter": [
            "all",
            ["in", "class", "primary", "trunk"]
          ],
          "layout": {"line-cap": "butt", "line-join": "round"},
          "paint": {
            "line-color": "#ffd54f",
            "line-width": {
              "base": 1.2,
              "stops": [
                [5, 0.4],
                [6, 0.7],
                [7, 1.75],
                [20, 22]
              ]
            }
          }
        },
        {
          "id": "road_service_track",
          "type": "line",
          "source": "openmaptiles",
          "source-layer": "transportation",
          "minzoom": 13,
          "filter": [
            "all",
            ["==", "\$type", "LineString"],
            ["in", "class", "service", "track"]
          ],
          "layout": {
            "line-cap": "butt",
            "line-join": "round",
            "visibility": "visible"
          },
          "paint": {
            "line-color": "#ffffff",
            "line-width": {
              "base": 1.2,
              "stops": [
                [15.5, 0],
                [16, 2],
                [20, 7.5]
              ]
            }
          }
        },
        {
          "id": "road_minor",
          "type": "line",
          "source": "openmaptiles",
          "source-layer": "transportation",
          "minzoom": 12.5,
          "filter": [
            "all",
            ["==", "\$type", "LineString"],
            ["==", "class", "minor"]
          ],
          "layout": {"line-cap": "butt", "line-join": "round"},
          "paint": {
            "line-color": "#ffffff",
            "line-width": {
              "base": 1.2,
              "stops": [
                [13.5, 0],
                [14, 2.5],
                [20, 18]
              ]
            }
          }
        },
        {
          "id": "road_secondary_tertiary",
          "type": "line",
          "source": "openmaptiles",
          "source-layer": "transportation",
          "minzoom": 11,
          "filter": [
            "all",
            ["in", "class", "secondary", "tertiary"]
          ],
          "layout": {"line-join": "round", "line-cap": "butt"},
          "paint": {
            "line-color": "#ffffff",
            "line-width": {
              "base": 1.2,
              "stops": [
                [6.5, 0],
                [8, 2.5],
                [20, 13]
              ]
            }
          }
        },
        {
          "id": "road_motorway_ramp",
          "type": "line",
          "source": "openmaptiles",
          "source-layer": "transportation",
          "filter": [
            "all",
            ["in", "class", "motorway"],
            ["==", "ramp", 1]
          ],
          "layout": {
            "line-join": "round",
            "line-cap": "butt",
            "visibility": "visible"
          },
          "paint": {
            "line-color": "#ffe082",
            "line-width": {
              "base": 1.2,
              "stops": [
                [12.5, 0],
                [13, 1.5],
                [14, 2.5],
                [20, 11.5]
              ]
            }
          }
        },
        {
          "id": "road_motorway",
          "type": "line",
          "source": "openmaptiles",
          "source-layer": "transportation",
          "filter": [
            "all",
            ["in", "class", "motorway"],
            ["!=", "ramp", 1]
          ],
          "layout": {
            "line-join": "round",
            "line-cap": "butt",
            "visibility": "visible"
          },
          "paint": {
            "line-color": "#ffe082",
            "line-width": {
              "base": 1.2,
              "stops": [
                [5, 0],
                [7, 1],
                [20, 18]
              ]
            }
          }
        },
        {
          "id": "road_primary",
          "type": "line",
          "source": "openmaptiles",
          "source-layer": "transportation",
          "filter": [
            "all",
            ["in", "class", "primary", "trunk"]
          ],
          "layout": {"line-join": "round", "line-cap": "butt"},
          "paint": {
            "line-color": "#ffecb3",
            "line-width": {
              "base": 1.2,
              "stops": [
                [5, 0],
                [7, 1],
                [20, 18]
              ]
            }
          }
        },
        {
          "id": "building",
          "type": "fill",
          "source": "openmaptiles",
          "source-layer": "building",
          "minzoom": 16,
          "paint": {"fill-color": "#e0e0e0"}
        },
        {
          "id": "boundary_2",
          "type": "line",
          "source": "openmaptiles",
          "source-layer": "boundary",
          "minzoom": 3,
          "filter": [
            "all",
            ["==", "admin_level", 2]
          ],
          "paint": {"line-color": "#aaa", "line-width": 2}
        }
      ],
      "id": "awzvtprqd"
    };
