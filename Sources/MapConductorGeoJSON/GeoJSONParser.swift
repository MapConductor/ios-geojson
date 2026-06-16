import Foundation

public enum GeoJSONParser {

    // MARK: - Public API

    /// Parses GeoJSON from raw Data. Handles FeatureCollection, Feature, or bare geometry.
    public static func parse(data: Data) -> [GeoJSONFeature] {
        guard let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return []
        }
        return parseTopLevel(root)
    }

    /// Parses GeoJSON from an InputStream without loading the full content into a String first.
    /// Suitable for files > 10 MB.
    public static func parse(stream: InputStream) -> [GeoJSONFeature] {
        stream.open()
        defer { stream.close() }
        guard let root = try? JSONSerialization.jsonObject(with: stream) as? [String: Any] else {
            return []
        }
        return parseTopLevel(root)
    }

    /// Parses GeoJSON from a file URL, streaming from disk without loading the full file.
    public static func parse(fileURL: URL) -> [GeoJSONFeature] {
        guard let stream = InputStream(url: fileURL) else { return [] }
        return parse(stream: stream)
    }

    // MARK: - Top-level dispatch

    private static func parseTopLevel(_ root: [String: Any]) -> [GeoJSONFeature] {
        switch root["type"] as? String {
        case "FeatureCollection":
            guard let features = root["features"] as? [[String: Any]] else { return [] }
            return features.compactMap { parseFeature($0) }
        case "Feature":
            return parseFeature(root).map { [$0] } ?? []
        default:
            if let geometry = parseGeometry(root) {
                return [GeoJSONFeature(geometry: geometry)]
            }
            return []
        }
    }

    // MARK: - Feature

    static func parseRecord(_ dict: [String: Any]) -> GeoJSONFeature? {
        switch dict["type"] as? String {
        case "Feature":
            return parseFeature(dict)
        default:
            guard let geometry = parseGeometry(dict) else { return nil }
            return GeoJSONFeature(geometry: geometry)
        }
    }

    private static func parseFeature(_ dict: [String: Any]) -> GeoJSONFeature? {
        guard let geometryDict = dict["geometry"] as? [String: Any],
              let geometry = parseGeometry(geometryDict) else { return nil }
        let id = dict["id"].map { "\($0)" }
        let properties = dict["properties"] as? [String: Any] ?? [:]
        return GeoJSONFeature(id: id, geometry: geometry, properties: properties)
    }

    // MARK: - Geometry

    static func parseGeometry(_ dict: [String: Any]) -> GeoJSONGeometry? {
        switch dict["type"] as? String {
        case "Point":
            guard let coords = dict["coordinates"] as? [Double], coords.count >= 2 else { return nil }
            return .point(longitude: coords[0], latitude: coords[1])

        case "MultiPoint":
            guard let coords = dict["coordinates"] as? [[Any]] else { return nil }
            return .multiPoint(points: coords.compactMap { parseLonLat($0) })

        case "LineString":
            guard let coords = dict["coordinates"] as? [[Any]] else { return nil }
            return .lineString(coordinates: coords.compactMap { parseLonLat($0) })

        case "MultiLineString":
            guard let coords = dict["coordinates"] as? [[[Any]]] else { return nil }
            return .multiLineString(lines: coords.map { ring in ring.compactMap { parseLonLat($0) } })

        case "Polygon":
            guard let coords = dict["coordinates"] as? [[[Any]]] else { return nil }
            return .polygon(rings: coords.map { ring in ring.compactMap { parseLonLat($0) } })

        case "MultiPolygon":
            guard let coords = dict["coordinates"] as? [[[[Any]]]] else { return nil }
            return .multiPolygon(polygons: coords.map { poly in
                poly.map { ring in ring.compactMap { parseLonLat($0) } }
            })

        case "GeometryCollection":
            guard let geometries = dict["geometries"] as? [[String: Any]] else { return nil }
            return .geometryCollection(geometries: geometries.compactMap { parseGeometry($0) })

        default:
            return nil
        }
    }

    private static func parseLonLat(_ arr: [Any]) -> LonLat? {
        guard arr.count >= 2,
              let lon = (arr[0] as? NSNumber).map({ Double(truncating: $0) }),
              let lat = (arr[1] as? NSNumber).map({ Double(truncating: $0) }) else { return nil }
        return LonLat(longitude: lon, latitude: lat)
    }
}
