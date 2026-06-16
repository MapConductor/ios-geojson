import Foundation

public struct LonLat: Equatable, Hashable {
    public let longitude: Double
    public let latitude: Double

    public init(longitude: Double, latitude: Double) {
        self.longitude = longitude
        self.latitude = latitude
    }
}

public indirect enum GeoJSONGeometry: Equatable, Hashable {
    case point(longitude: Double, latitude: Double)
    case multiPoint(points: [LonLat])
    case lineString(coordinates: [LonLat])
    case multiLineString(lines: [[LonLat]])
    case polygon(rings: [[LonLat]])
    case multiPolygon(polygons: [[[LonLat]]])
    case geometryCollection(geometries: [GeoJSONGeometry])
    case empty
}
