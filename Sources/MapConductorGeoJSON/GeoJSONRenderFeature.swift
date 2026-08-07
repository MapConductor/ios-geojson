import CoreGraphics
import Foundation
import UIKit

/// 1 フィーチャーを描くのに必要な形に前処理したもの。
///
/// 元の緯度経度ジオメトリは**捨てる**（`source` の geometry を `.empty` にする）。
/// 座標は `worldGeometry` が世界座標で持っており、描画も当たり判定もそちらを使う。
/// 両方持つとメモリが倍になり、大きなデータで OOM になる。
struct RenderFeature {
    let source: GeoJSONFeature
    let worldGeometry: WorldGeometry
    let bounds: WorldBounds
    let fillColor: UIColor
    let strokeColor: UIColor
    let strokeWidth: CGFloat
    let pointRadius: CGFloat
}

/// スタイルを解決し、``RenderFeature`` を組み立てる部分。
///
/// android-sdk の `GeoJSONRenderFeature.kt` / react-sdk の同名ファイルと同じ。
enum GeoJSONRenderFeatureBuilder {
    static func build(
        _ feature: GeoJSONFeature,
        layerStyle: GeoJSONTileRenderer.LayerStyle,
        styleProvider: any GeoJSONStyleProvider
    ) -> RenderFeature {
        let style = styleProvider.style(for: feature, defaultStyle: layerStyle)
        let worldGeometry = GeoJSONWorld.toWorldGeometry(feature.geometry)
        let stripped = GeoJSONFeature(id: feature.id, geometry: .empty, properties: feature.properties)
        return RenderFeature(
            source: stripped,
            worldGeometry: worldGeometry,
            bounds: GeoJSONWorld.computeBounds(worldGeometry),
            fillColor: style.fillColor,
            strokeColor: style.strokeColor,
            strokeWidth: style.strokeWidth,
            pointRadius: style.pointRadius
        )
    }
}
