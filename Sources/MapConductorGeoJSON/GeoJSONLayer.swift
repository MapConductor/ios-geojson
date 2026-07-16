import MapConductorCore
import SwiftUI

public struct GeoJSONLayer: ViewBasedMapOverlay, Identifiable {
    public let id: String
    private let overlayState: GeoJSONLayerState
    private let features: [GeoJSONFeature]

    public init(
        _ state: GeoJSONLayerState,
        features: [GeoJSONFeature] = []
    ) {
        self.overlayState = state
        self.features = features
        self.id = state.rasterLayerState.id
    }

    public init(
        state: GeoJSONLayerState,
        features: [GeoJSONFeature] = []
    ) {
        self.init(state, features: features)
    }

    public init(
        features: [GeoJSONFeature] = [],
        tileSize: Int = GeoJSONDefaults.defaultTileSize,
        opacity: Double = GeoJSONDefaults.defaultOpacity,
        layerStyle: GeoJSONTileRenderer.LayerStyle = GeoJSONTileRenderer.LayerStyle(),
        styleProvider: any GeoJSONStyleProvider = DefaultGeoJSONStyleProvider.shared
    ) {
        let state = GeoJSONLayerState(
            tileSize: tileSize,
            opacity: opacity,
            layerStyle: layerStyle,
            styleProvider: styleProvider
        )
        self.init(state, features: features)
    }

    public var body: some View {
        GeoJSONStateUpdater(overlayState: overlayState, features: features)
    }

    public func append(to content: inout MapViewContent) {
        content.rasterLayers.append(RasterLayer(state: overlayState.rasterLayerState))
    }
}

private struct GeoJSONStateUpdater: View {
    let overlayState: GeoJSONLayerState
    let features: [GeoJSONFeature]

    private var updateToken: Int {
        var result: Int32 = 1
        for feature in features {
            var hasher = Hasher()
            hasher.combine(feature.id)
            hasher.combine(feature.geometry)
            hasher.combine(feature.visible)
            result = result &* 31 &+ Int32(truncatingIfNeeded: hasher.finalize())
        }
        return Int(result)
    }

    var body: some View {
        Color.clear
            .frame(width: 0, height: 0)
            .task(id: updateToken) {
                overlayState.setFeatures(features)
            }
    }
}
