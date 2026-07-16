import Foundation

/// Resolves the render style for a GeoJSON feature.
public protocol GeoJSONStyleProvider: AnyObject {
    func style(
        for feature: GeoJSONFeature,
        defaultStyle: GeoJSONTileRenderer.LayerStyle
    ) -> GeoJSONTileRenderer.LayerStyle
}

/// Preserves the existing feature-style-over-layer-style behavior.
public final class DefaultGeoJSONStyleProvider: GeoJSONStyleProvider {
    public static let shared = DefaultGeoJSONStyleProvider()

    private init() {}

    public func style(
        for feature: GeoJSONFeature,
        defaultStyle: GeoJSONTileRenderer.LayerStyle
    ) -> GeoJSONTileRenderer.LayerStyle {
        GeoJSONTileRenderer.LayerStyle(
            strokeColor: feature.strokeColor ?? defaultStyle.strokeColor,
            fillColor: feature.fillColor ?? defaultStyle.fillColor,
            strokeWidth: feature.strokeWidth ?? defaultStyle.strokeWidth,
            pointRadius: feature.pointRadius ?? defaultStyle.pointRadius
        )
    }
}
