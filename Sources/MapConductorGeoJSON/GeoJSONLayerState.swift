import Combine
import Foundation
import MapConductorCore

public final class GeoJSONLayerState: ObservableObject {
    let rasterLayerState: RasterLayerState
    let renderer: GeoJSONTileRenderer

    public var onClick: ((GeoJSONFeature, GeoPoint) -> Void)?

    public var opacity: Double {
        didSet { rasterLayerState.opacity = min(1.0, max(0.0, opacity)) }
    }

    public var minZoom: Int {
        didSet { scheduleUpdate() }
    }

    public var maxZoom: Int {
        didSet { scheduleUpdate() }
    }

    public var layerStyle: GeoJSONTileRenderer.LayerStyle {
        didSet { scheduleUpdate() }
    }

    private let groupId: String
    private let tileServer: LocalTileServer
    private var version: Int64 = 0
    private var lastFeatures: [GeoJSONFeature] = []
    private let updateQueue = DispatchQueue(label: "MapConductorGeoJSONLayer")
    private var featureStateCancellables: [AnyCancellable] = []

    public init(
        tileSize: Int = GeoJSONDefaults.defaultTileSize,
        opacity: Double = GeoJSONDefaults.defaultOpacity,
        minZoom: Int = 0,
        maxZoom: Int = GeoJSONDefaults.defaultMaxZoom,
        layerStyle: GeoJSONTileRenderer.LayerStyle = GeoJSONTileRenderer.LayerStyle()
    ) {
        let initialOpacity = min(1.0, max(0.0, opacity))
        self.opacity = opacity
        self.minZoom = minZoom
        self.maxZoom = maxZoom
        self.layerStyle = layerStyle
        self.groupId = UUID().uuidString
        self.tileServer = TileServerRegistry.get(forceNoStoreCache: false)
        self.renderer = GeoJSONTileRenderer(tileSize: tileSize)

        self.rasterLayerState = RasterLayerState(
            source: RasterSource.urlTemplate(
                template: tileServer.urlTemplate(routeId: groupId, tileSize: tileSize, cacheKey: "0"),
                tileSize: tileSize,
                minZoom: minZoom,
                maxZoom: maxZoom,
                scheme: .XYZ
            ),
            opacity: initialOpacity,
            visible: false,
            id: "geojson-\(groupId)",
            extra: Int64(0)
        )

        tileServer.register(routeId: groupId, provider: renderer)
    }

    deinit {
        tileServer.unregister(routeId: groupId)
    }

    public func setFeatures(_ features: [GeoJSONFeature]) {
        updateQueue.async { [weak self] in
            guard let self else { return }
            self.lastFeatures = features
            self.applyUpdate(features: features)
        }
    }

    public func setFeatures(_ states: [GeoJSONFeatureState]) {
        featureStateCancellables.removeAll()
        let features = states.map { $0.toFeature() }
        setFeatures(features)
        let publisher = Publishers.MergeMany(states.map { $0.asPublisher() })
            .debounce(for: .milliseconds(50), scheduler: updateQueue)
            .sink { [weak self] _ in
                guard let self else { return }
                let updated = states.map { $0.toFeature() }
                self.lastFeatures = updated
                self.applyUpdate(features: updated)
            }
        featureStateCancellables.append(publisher)
    }

    public func processClick(geoPoint: GeoPoint) {
        let feature = renderer.hitTest(longitude: geoPoint.longitude, latitude: geoPoint.latitude)
        guard let feature else { return }
        onClick?(feature, geoPoint)
    }

    private func scheduleUpdate() {
        updateQueue.async { [weak self] in
            guard let self else { return }
            self.applyUpdate(features: self.lastFeatures)
        }
    }

    private func applyUpdate(features: [GeoJSONFeature]) {
        renderer.update(features: features, layerStyle: layerStyle)
        version += 1
        let nextVersion = version
        let tileSize = renderer.tileSize
        let nextSource = RasterSource.urlTemplate(
            template: tileServer.urlTemplate(routeId: groupId, tileSize: tileSize, cacheKey: String(nextVersion)),
            tileSize: tileSize,
            minZoom: minZoom,
            maxZoom: maxZoom,
            scheme: .XYZ
        )
        let shouldShowLayer = !features.isEmpty
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.rasterLayerState.source = nextSource
            self.rasterLayerState.extra = nextVersion
            self.rasterLayerState.visible = shouldShowLayer
        }
    }
}
