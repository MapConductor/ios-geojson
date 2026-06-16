import UIKit

/// Lightweight, non-reactive data model for static/bulk GeoJSON features.
/// Use this when loading large GeoJSON files that don't need per-feature reactive state.
public struct GeoJSONFeature: Identifiable {
    public let id: String?
    public let geometry: GeoJSONGeometry
    public let properties: [String: Any]
    public var strokeColor: UIColor?
    public var fillColor: UIColor?
    public var strokeWidth: CGFloat?
    public var pointRadius: CGFloat?
    public var visible: Bool

    public init(
        id: String? = nil,
        geometry: GeoJSONGeometry,
        properties: [String: Any] = [:],
        strokeColor: UIColor? = nil,
        fillColor: UIColor? = nil,
        strokeWidth: CGFloat? = nil,
        pointRadius: CGFloat? = nil,
        visible: Bool = true
    ) {
        self.id = id
        self.geometry = geometry
        self.properties = properties
        self.strokeColor = strokeColor
        self.fillColor = fillColor
        self.strokeWidth = strokeWidth
        self.pointRadius = pointRadius
        self.visible = visible
    }
}
