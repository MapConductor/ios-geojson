# MapConductor GeoJSON Layer

`ios-geojson` adds a tile-rendered GeoJSON overlay to MapConductor map views.
It parses GeoJSON data into feature models, renders the features through MapConductor's
raster tile layer pipeline, and provides hit-testing for feature selection.

The layer is useful for large GeoJSON datasets because rendering is tile based and parsed
features can be supplied as lightweight data objects instead of one SwiftUI state object
per feature.

## Features

- Renders `Point`, `MultiPoint`, `LineString`, `MultiLineString`, `Polygon`,
  `MultiPolygon`, and `GeometryCollection`.
- Supports static bulk features with `GeoJSONFeature`.
- Supports reactive Combine features with `GeoJSONFeatureState`.
- Parses `FeatureCollection`, top-level `Feature`, and bare geometry input with
  `GeoJSONParser`.
- Streams GeoJSON Text Sequences with `GeoJSONSeqParser`.
- Supports layer-level and feature-level styling.
- Provides touch hit-testing through `GeoJSONLayerState.processClick(geoPoint:)`.

## Installation

When developing inside the MapConductor SDK repository, add the package as a local Swift
Package dependency:

```swift
.package(path: "./ios-geojson")
```

Then add the product to your app target:

```swift
.product(name: "MapConductorGeoJSON", package: "mapconductor-geojson")
```

For published artifacts, use the configured MapConductor package URL:

```swift
.package(url: "https://github.com/MapConductor/ios-geojson", from: "<version>")
```

The package depends on `MapConductorCore` and supports iOS 15 or later.

## Basic Usage

Load a GeoJSON `FeatureCollection` and render it inside any MapConductor map view content
scope:

```swift
import MapConductorCore
import MapConductorForMapKit
import MapConductorGeoJSON
import SwiftUI
import UIKit

struct BasicGeoJSONExample: View {
    @StateObject private var mapViewState = MapKitViewState(
        cameraPosition: MapCameraPosition(
            position: GeoPoint.fromLongLat(longitude: 55.3089185, latitude: 25.255377),
            zoom: 13.0
        )
    )

    @StateObject private var layerState = GeoJSONLayerState(
        layerStyle: GeoJSONTileRenderer.LayerStyle(
            strokeColor: UIColor(red: 29.0 / 255.0, green: 112.0 / 255.0, blue: 130.0 / 255.0, alpha: 1.0),
            fillColor: UIColor(red: 59.0 / 255.0, green: 178.0 / 255.0, blue: 208.0 / 255.0, alpha: 0.5),
            strokeWidth: 2.0
        )
    )

    @State private var features: [GeoJSONFeature] = []

    var body: some View {
        MapKitMapView(state: mapViewState) {
            GeoJSONLayer(state: layerState, features: features)
        }
        .task {
            let data = Data(basicGeoJSON.utf8)
            features = GeoJSONParser.parse(data: data)
        }
    }
}

private let basicGeoJSON = """
{
  "type": "FeatureCollection",
  "features": [
    {
      "type": "Feature",
      "geometry": {
        "type": "Polygon",
        "coordinates": [
          [
            [55.30122473231012, 25.26476622289597],
            [55.31622473231012, 25.26476622289597],
            [55.31622473231012, 25.25476622289597],
            [55.30122473231012, 25.25476622289597],
            [55.30122473231012, 25.26476622289597]
          ]
        ]
      },
      "properties": {}
    }
  ]
}
"""
```

## Styling

Set default layer style through `GeoJSONLayerState`:

```swift
let layerState = GeoJSONLayerState(
    opacity: 1.0,
    layerStyle: GeoJSONTileRenderer.LayerStyle(
        strokeColor: UIColor(red: 30.0 / 255.0, green: 136.0 / 255.0, blue: 229.0 / 255.0, alpha: 0.86),
        fillColor: UIColor(red: 30.0 / 255.0, green: 136.0 / 255.0, blue: 229.0 / 255.0, alpha: 0.24),
        strokeWidth: 1.5,
        pointRadius: 8.0
    )
)

GeoJSONLayer(
    state: layerState,
    features: features
)
```

Individual `GeoJSONFeature` and `GeoJSONFeatureState` objects can override
`strokeColor`, `fillColor`, `strokeWidth`, `pointRadius`, and `visible`.

## Touch Detection

The layer keeps hit-testing in `ios-geojson` and avoids changing MapConductor core.
Because MapConductor map views expose map click callbacks, apps should forward map clicks
to the `GeoJSONLayerState` manually.

```swift
@State private var selectedFeature: GeoJSONFeature?

let layerState = GeoJSONLayerState()
layerState.onClick = { feature, position in
    selectedFeature = feature
    // Use position for marker, info bubble, bottom sheet, etc.
}

MapKitMapView(
    state: mapViewState,
    onMapClick: { point in
        selectedFeature = nil
        layerState.processClick(geoPoint: point)
    }
) {
    GeoJSONLayer(
        state: layerState,
        features: features
    )
}
```

`processClick(geoPoint:)` invokes the layer `onClick` callback when a rendered feature is
found at that map position.

Hit-testing supports points, lines, polygons with holes, multiparts, and geometry
collections.

## Reactive Features

For small or frequently changing feature sets, keep stateful features and push them into
the layer state:

```swift
let pointState = GeoJSONFeatureState(
    featureId: "office",
    geometry: .point(
        longitude: 139.77,
        latitude: 35.68
    ),
    properties: ["name": "Office"]
)

layerState.setFeatures([pointState])
```

For many static features, prefer `GeoJSONFeature` plus the `features` parameter. That path
avoids creating SwiftUI or Combine state for every feature.

## GeoJSON Text Sequences

GeoJSON Text Sequences are supported for stream-friendly datasets where records are
separated by the RFC 8142 record separator character.

```swift
let features = GeoJSONSeqParser.parse(fileURL: fileURL)
```

Use `GeoJSONSeqParser.streamParse` to consume records one at a time.

```swift
GeoJSONSeqParser.streamParse(fileURL: fileURL) { feature in
    // Append, batch, or persist each feature as it is parsed.
}
```

## Performance Notes

- Prefer `GeoJSONParser.parse(stream:)` or `GeoJSONParser.parse(fileURL:)` for large
  `FeatureCollection` files.
- Load and parse data off the main actor when working with large files.
- Use static `GeoJSONFeature` lists for large datasets.
- Use `GeoJSONFeatureState` only when individual feature updates are needed.
- The layer internally invalidates its tile URL when feature data or style changes so map
  SDK raster caches request fresh rendered tiles.

## Current Limitations

- Automatic layer-level click listener registration is intentionally not implemented.
  Forward map clicks to `GeoJSONLayerState.processClick(geoPoint:)`.
- `GeoJSONParser` returns an empty feature list for malformed or unsupported input instead
  of throwing parse errors.
- Hit-test line and point tolerances are renderer constants in world coordinates, not
  configurable public API yet.
- The layer is rendered as raster tiles, so native SDK vector feature querying is not used.

## Development

Build the package with an iOS destination, either from Xcode or from the command line:

```sh
xcodebuild -scheme mapconductor-geojson -destination 'generic/platform=iOS Simulator' build
```

