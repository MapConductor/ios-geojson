import CoreGraphics
import Foundation
import MapConductorCore
import UIKit

public final class GeoJSONTileRenderer: TileProvider {

    // MARK: - Public

    public let tileSize: Int

    // MARK: - Private types

    private struct WorldPoint {
        let wx: Double
        let wy: Double
    }

    private struct WorldBounds {
        let minX: Double
        let maxX: Double
        let minY: Double
        let maxY: Double

        func intersects(_ x1: Double, _ y1: Double, _ x2: Double, _ y2: Double) -> Bool {
            minX <= x2 && maxX >= x1 && minY <= y2 && maxY >= y1
        }
    }

    private indirect enum WorldGeometry {
        case point(wx: Double, wy: Double)
        case points([WorldPoint])
        case line([[WorldPoint]])
        case polygon([[WorldPoint]])
        case collection([WorldGeometry])
        case empty
    }

    public struct LayerStyle {
        public let strokeColor: UIColor
        public let fillColor: UIColor
        public let strokeWidth: CGFloat
        public let pointRadius: CGFloat

        public init(
            strokeColor: UIColor = GeoJSONDefaults.defaultStrokeColor,
            fillColor: UIColor = GeoJSONDefaults.defaultFillColor,
            strokeWidth: CGFloat = GeoJSONDefaults.defaultStrokeWidth,
            pointRadius: CGFloat = GeoJSONDefaults.defaultPointRadius
        ) {
            self.strokeColor = strokeColor
            self.fillColor = fillColor
            self.strokeWidth = strokeWidth
            self.pointRadius = pointRadius
        }
    }

    private struct RenderFeature {
        let source: GeoJSONFeature
        let worldGeometry: WorldGeometry
        let bounds: WorldBounds
        let fillColor: UIColor
        let strokeColor: UIColor
        let strokeWidth: CGFloat
        let pointRadius: CGFloat
    }

    private final class SpatialIndex {
        private let grid: [[Int]]
        private let gridSize: Int
        private let featureCount: Int

        init(grid: [[Int]], gridSize: Int, featureCount: Int) {
            self.grid = grid
            self.gridSize = gridSize
            self.featureCount = featureCount
        }

        func query(x1: Double, y1: Double, x2: Double, y2: Double) -> [Int] {
            let cx0 = max(0, min(gridSize - 1, Int(x1 * Double(gridSize))))
            let cx1 = max(0, min(gridSize - 1, Int(x2 * Double(gridSize))))
            let cy0 = max(0, min(gridSize - 1, Int(y1 * Double(gridSize))))
            let cy1 = max(0, min(gridSize - 1, Int(y2 * Double(gridSize))))
            // [Bool] uses 1 byte per feature vs Set<Int> which needs 8+ bytes per entry,
            // preventing OOM when many features fall into the same tile.
            var seen = [Bool](repeating: false, count: featureCount)
            var result: [Int] = []
            for cy in cy0...cy1 {
                for cx in cx0...cx1 {
                    for idx in grid[cy * gridSize + cx] {
                        if !seen[idx] { seen[idx] = true; result.append(idx) }
                    }
                }
            }
            return result
        }
    }

    private struct TileState {
        let features: [RenderFeature]
        let index: SpatialIndex?
    }

    // MARK: - State

    private let stateLock = NSLock()
    private var currentState = TileState(features: [], index: nil)

    private let cacheLock = NSLock()
    private let cache = NSCache<NSString, NSData>()
    private var cacheEpoch: Int64 = 0

    private static let indexThreshold = 256
    private static let indexGridSize = 64
    private static let maxCacheCostBytes = 8 * 1024 * 1024

    // MARK: - Init

    public init(tileSize: Int = GeoJSONDefaults.defaultTileSize) {
        self.tileSize = tileSize
        cache.totalCostLimit = Self.maxCacheCostBytes
    }

    // MARK: - Update

    public func update(features: [GeoJSONFeature], layerStyle: LayerStyle) {
        let rendered = features.filter { $0.visible }.map { buildRenderFeature($0, layerStyle: layerStyle) }
        let index = rendered.count >= Self.indexThreshold ? buildIndex(rendered) : nil
        stateLock.lock()
        currentState = TileState(features: rendered, index: index)
        stateLock.unlock()
        cacheLock.lock()
        cacheEpoch += 1
        cache.removeAllObjects()
        cacheLock.unlock()
    }

    // MARK: - TileProvider

    public func renderTile(request: TileRequest) -> Data? {
        let epoch: Int64
        cacheLock.lock()
        epoch = cacheEpoch
        cacheLock.unlock()

        let key = "\(epoch):\(request.z)/\(request.x)/\(request.y)" as NSString
        cacheLock.lock()
        let cached = cache.object(forKey: key)
        cacheLock.unlock()
        if let cached { return cached as Data }

        stateLock.lock()
        let state = currentState
        stateLock.unlock()

        let result = renderTileInternal(request: request, state: state)

        cacheLock.lock()
        if cacheEpoch == epoch {
            cache.setObject((result ?? Data()) as NSData, forKey: key, cost: result?.count ?? 1)
        }
        cacheLock.unlock()

        return result
    }

    // MARK: - Hit testing

    /// Returns the topmost feature at the given geographic coordinates, or nil.
    public func hitTest(longitude: Double, latitude: Double) -> GeoJSONFeature? {
        let wx = lonToWorld(longitude)
        let wy = latToWorld(latitude)

        stateLock.lock()
        let state = currentState
        stateLock.unlock()

        let tol = GeoJSONDefaults.hitLineTolerance
        let candidates = state.index?.query(x1: wx - tol, y1: wy - tol, x2: wx + tol, y2: wy + tol)
            ?? Array(state.features.indices)

        for idx in candidates {
            let feature = state.features[idx]
            guard feature.bounds.intersects(wx - tol, wy - tol, wx + tol, wy + tol) else { continue }
            if hitTestGeometry(wx: wx, wy: wy, geometry: feature.worldGeometry) {
                return feature.source
            }
        }
        return nil
    }

    // MARK: - Internal rendering

    private func renderTileInternal(request: TileRequest, state: TileState) -> Data? {
        guard !state.features.isEmpty else { return nil }

        let z = request.z
        let worldTileCount = 1 << z
        let x = ((request.x % worldTileCount) + worldTileCount) % worldTileCount
        let y = request.y
        guard y >= 0 && y < worldTileCount else { return nil }

        let tileMinX = Double(x) / Double(worldTileCount)
        let tileMaxX = Double(x + 1) / Double(worldTileCount)
        let tileMinY = Double(y) / Double(worldTileCount)
        let tileMaxY = Double(y + 1) / Double(worldTileCount)

        let candidates = state.index?.query(x1: tileMinX, y1: tileMinY, x2: tileMaxX, y2: tileMaxY)
            ?? Array(state.features.indices)

        let worldSize = Double(tileSize) * Double(worldTileCount)
        let originX = Double(x) * Double(tileSize)
        let originY = Double(y) * Double(tileSize)

        func toPixelX(_ wx: Double) -> CGFloat { CGFloat(wx * worldSize - originX) }
        func toPixelY(_ wy: Double) -> CGFloat { CGFloat(wy * worldSize - originY) }

        let renderer = UIGraphicsImageRenderer(size: CGSize(width: tileSize, height: tileSize))
        var hasContent = false

        let image = renderer.image { ctx in
            let cgCtx = ctx.cgContext
            cgCtx.clear(CGRect(x: 0, y: 0, width: tileSize, height: tileSize))

            for idx in candidates {
                let feature = state.features[idx]
                guard feature.bounds.intersects(tileMinX, tileMinY, tileMaxX, tileMaxY) else { continue }
                if drawFeature(cgCtx, feature: feature, toPixelX: toPixelX, toPixelY: toPixelY) {
                    hasContent = true
                }
            }
        }

        guard hasContent else { return nil }
        return image.pngData()
    }

    private func drawFeature(
        _ ctx: CGContext,
        feature: RenderFeature,
        toPixelX: (Double) -> CGFloat,
        toPixelY: (Double) -> CGFloat
    ) -> Bool {
        drawGeometry(ctx, geometry: feature.worldGeometry, feature: feature,
                     toPixelX: toPixelX, toPixelY: toPixelY)
    }

    private func drawGeometry(
        _ ctx: CGContext,
        geometry: WorldGeometry,
        feature: RenderFeature,
        toPixelX: (Double) -> CGFloat,
        toPixelY: (Double) -> CGFloat
    ) -> Bool {
        switch geometry {
        case .point(let wx, let wy):
            let px = toPixelX(wx)
            let py = toPixelY(wy)
            let r = feature.pointRadius
            let rect = CGRect(x: px - r, y: py - r, width: r * 2, height: r * 2)
            ctx.setFillColor(feature.fillColor.cgColor)
            ctx.fillEllipse(in: rect)
            ctx.setStrokeColor(feature.strokeColor.cgColor)
            ctx.setLineWidth(feature.strokeWidth)
            ctx.strokeEllipse(in: rect)
            return true

        case .points(let pts):
            guard !pts.isEmpty else { return false }
            let r = feature.pointRadius
            for pt in pts {
                let rect = CGRect(x: toPixelX(pt.wx) - r, y: toPixelY(pt.wy) - r,
                                  width: r * 2, height: r * 2)
                ctx.setFillColor(feature.fillColor.cgColor)
                ctx.fillEllipse(in: rect)
                ctx.setStrokeColor(feature.strokeColor.cgColor)
                ctx.setLineWidth(feature.strokeWidth)
                ctx.strokeEllipse(in: rect)
            }
            return true

        case .line(let rings):
            let path = CGMutablePath()
            for ring in rings {
                guard ring.count >= 2 else { continue }
                path.move(to: CGPoint(x: toPixelX(ring[0].wx), y: toPixelY(ring[0].wy)))
                for i in 1..<ring.count {
                    path.addLine(to: CGPoint(x: toPixelX(ring[i].wx), y: toPixelY(ring[i].wy)))
                }
            }
            guard !path.isEmpty else { return false }
            ctx.addPath(path)
            ctx.setStrokeColor(feature.strokeColor.cgColor)
            ctx.setLineWidth(feature.strokeWidth)
            ctx.setLineJoin(.round)
            ctx.setLineCap(.round)
            ctx.strokePath()
            return true

        case .polygon(let rings):
            let path = CGMutablePath()
            for ring in rings {
                guard ring.count >= 3 else { continue }
                path.move(to: CGPoint(x: toPixelX(ring[0].wx), y: toPixelY(ring[0].wy)))
                for i in 1..<ring.count {
                    path.addLine(to: CGPoint(x: toPixelX(ring[i].wx), y: toPixelY(ring[i].wy)))
                }
                path.closeSubpath()
            }
            guard !path.isEmpty else { return false }
            ctx.addPath(path)
            ctx.setFillColor(feature.fillColor.cgColor)
            ctx.fillPath(using: .evenOdd)
            ctx.addPath(path)
            ctx.setStrokeColor(feature.strokeColor.cgColor)
            ctx.setLineWidth(feature.strokeWidth)
            ctx.strokePath()
            return true

        case .collection(let parts):
            return parts.reduce(false) {
                drawGeometry(ctx, geometry: $1, feature: feature,
                             toPixelX: toPixelX, toPixelY: toPixelY) || $0
            }

        case .empty:
            return false
        }
    }

    // MARK: - Hit testing helpers

    private func hitTestGeometry(wx: Double, wy: Double, geometry: WorldGeometry) -> Bool {
        switch geometry {
        case .point(let gx, let gy):
            return distanceSq(wx, wy, gx, gy) <= GeoJSONDefaults.hitPointSq
        case .points(let pts):
            return pts.contains { distanceSq(wx, wy, $0.wx, $0.wy) <= GeoJSONDefaults.hitPointSq }
        case .line(let rings):
            return rings.contains { ring in
                zip(ring, ring.dropFirst()).contains { a, b in
                    segmentDistanceSq(px: wx, py: wy, ax: a.wx, ay: a.wy, bx: b.wx, by: b.wy) <= GeoJSONDefaults.hitLineSq
                }
            }
        case .polygon(let rings):
            guard let exterior = rings.first, pointInRing(wx: wx, wy: wy, ring: exterior) else { return false }
            return !rings.dropFirst().contains { pointInRing(wx: wx, wy: wy, ring: $0) }
        case .collection(let parts):
            return parts.contains { hitTestGeometry(wx: wx, wy: wy, geometry: $0) }
        case .empty:
            return false
        }
    }

    private func pointInRing(wx: Double, wy: Double, ring: [WorldPoint]) -> Bool {
        var inside = false
        var j = ring.count - 1
        for i in 0..<ring.count {
            let xi = ring[i].wx, yi = ring[i].wy
            let xj = ring[j].wx, yj = ring[j].wy
            if ((yi > wy) != (yj > wy)) && (wx < (xj - xi) * (wy - yi) / (yj - yi) + xi) {
                inside = !inside
            }
            j = i
        }
        return inside
    }

    private func segmentDistanceSq(px: Double, py: Double,
                                   ax: Double, ay: Double,
                                   bx: Double, by: Double) -> Double {
        let dx = bx - ax, dy = by - ay
        if dx == 0 && dy == 0 { return distanceSq(px, py, ax, ay) }
        let t = max(0, min(1, ((px - ax) * dx + (py - ay) * dy) / (dx * dx + dy * dy)))
        return distanceSq(px, py, ax + t * dx, ay + t * dy)
    }

    private func distanceSq(_ ax: Double, _ ay: Double, _ bx: Double, _ by: Double) -> Double {
        let dx = ax - bx, dy = ay - by
        return dx * dx + dy * dy
    }

    // MARK: - Build helpers

    private func buildRenderFeature(_ feature: GeoJSONFeature, layerStyle: LayerStyle) -> RenderFeature {
        let strokeColor = feature.strokeColor ?? layerStyle.strokeColor
        let fillColor = feature.fillColor ?? layerStyle.fillColor
        let strokeWidth = feature.strokeWidth ?? layerStyle.strokeWidth
        let pointRadius = feature.pointRadius ?? layerStyle.pointRadius
        let worldGeometry = toWorldGeometry(feature.geometry)
        // Strip geometry from source: worldGeometry already holds all coordinates in world
        // space for rendering and hit-testing. Keeping lat/lon coords here doubles memory
        // usage, which causes OOM on large datasets.
        let stripped = GeoJSONFeature(id: feature.id, geometry: .empty, properties: feature.properties)
        return RenderFeature(
            source: stripped,
            worldGeometry: worldGeometry,
            bounds: computeBounds(worldGeometry),
            fillColor: fillColor,
            strokeColor: strokeColor,
            strokeWidth: strokeWidth,
            pointRadius: pointRadius
        )
    }

    private func toWorldGeometry(_ geometry: GeoJSONGeometry) -> WorldGeometry {
        switch geometry {
        case .point(let lon, let lat):
            return .point(wx: lonToWorld(lon), wy: latToWorld(lat))
        case .multiPoint(let pts):
            return .points(pts.map { WorldPoint(wx: lonToWorld($0.longitude), wy: latToWorld($0.latitude)) })
        case .lineString(let coords):
            return .line([coords.map { WorldPoint(wx: lonToWorld($0.longitude), wy: latToWorld($0.latitude)) }])
        case .multiLineString(let lines):
            return .line(lines.map { line in line.map { WorldPoint(wx: lonToWorld($0.longitude), wy: latToWorld($0.latitude)) } })
        case .polygon(let rings):
            return .polygon(rings.map { ring in ring.map { WorldPoint(wx: lonToWorld($0.longitude), wy: latToWorld($0.latitude)) } })
        case .multiPolygon(let polygons):
            return .collection(polygons.map { poly in
                .polygon(poly.map { ring in ring.map { WorldPoint(wx: lonToWorld($0.longitude), wy: latToWorld($0.latitude)) } })
            })
        case .geometryCollection(let geometries):
            return .collection(geometries.map { toWorldGeometry($0) })
        case .empty:
            return .empty
        }
    }

    private func computeBounds(_ geometry: WorldGeometry) -> WorldBounds {
        switch geometry {
        case .point(let wx, let wy):
            return WorldBounds(minX: wx, maxX: wx, minY: wy, maxY: wy)
        case .points(let pts):
            return boundsOfPoints(pts)
        case .line(let rings):
            return boundsOfRings(rings)
        case .polygon(let rings):
            return boundsOfRings(rings)
        case .collection(let parts):
            let sub = parts.map { computeBounds($0) }
            return WorldBounds(
                minX: sub.map { $0.minX }.min() ?? 0,
                maxX: sub.map { $0.maxX }.max() ?? 1,
                minY: sub.map { $0.minY }.min() ?? 0,
                maxY: sub.map { $0.maxY }.max() ?? 1
            )
        case .empty:
            return WorldBounds(minX: 0, maxX: 1, minY: 0, maxY: 1)
        }
    }

    private func boundsOfPoints(_ pts: [WorldPoint]) -> WorldBounds {
        guard !pts.isEmpty else { return WorldBounds(minX: 0, maxX: 1, minY: 0, maxY: 1) }
        return WorldBounds(
            minX: pts.map { $0.wx }.min()!,
            maxX: pts.map { $0.wx }.max()!,
            minY: pts.map { $0.wy }.min()!,
            maxY: pts.map { $0.wy }.max()!
        )
    }

    private func boundsOfRings(_ rings: [[WorldPoint]]) -> WorldBounds {
        var minX = Double.infinity, maxX = -Double.infinity
        var minY = Double.infinity, maxY = -Double.infinity
        for ring in rings {
            for pt in ring {
                if pt.wx < minX { minX = pt.wx }; if pt.wx > maxX { maxX = pt.wx }
                if pt.wy < minY { minY = pt.wy }; if pt.wy > maxY { maxY = pt.wy }
            }
        }
        guard minX <= maxX else { return WorldBounds(minX: 0, maxX: 1, minY: 0, maxY: 1) }
        return WorldBounds(minX: minX, maxX: maxX, minY: minY, maxY: maxY)
    }

    private func buildIndex(_ features: [RenderFeature]) -> SpatialIndex {
        let gridSize = Self.indexGridSize
        var grid = Array(repeating: [Int](), count: gridSize * gridSize)
        for (i, feature) in features.enumerated() {
            let b = feature.bounds
            let x0 = max(0, min(gridSize - 1, Int(b.minX * Double(gridSize))))
            let x1 = max(0, min(gridSize - 1, Int(b.maxX * Double(gridSize))))
            let y0 = max(0, min(gridSize - 1, Int(b.minY * Double(gridSize))))
            let y1 = max(0, min(gridSize - 1, Int(b.maxY * Double(gridSize))))
            for cy in y0...y1 {
                for cx in x0...x1 {
                    grid[cy * gridSize + cx].append(i)
                }
            }
        }
        return SpatialIndex(grid: grid, gridSize: gridSize, featureCount: features.count)
    }

    // MARK: - Web Mercator

    private func lonToWorld(_ lon: Double) -> Double { lon / 360.0 + 0.5 }

    private func latToWorld(_ lat: Double) -> Double {
        let siny = sin(lat * .pi / 180.0)
        let clipped = max(-0.9999, min(0.9999, siny))
        return 0.5 - log((1.0 + clipped) / (1.0 - clipped)) / (4.0 * .pi)
    }
}
