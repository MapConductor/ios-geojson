import Combine
import CoreGraphics
import Foundation
import MapConductorCore
import Swift
import SwiftUI
import UIKit
import _Concurrency
import _StringProcessing
import _SwiftConcurrencyShims
public enum GeoJSONDefaults {
  public static let defaultTileSize: Swift.Int
  public static let defaultMaxZoom: Swift.Int
  public static let defaultOpacity: Swift.Double
  public static let defaultStrokeColor: UIKit.UIColor
  public static let defaultFillColor: UIKit.UIColor
  public static let defaultStrokeWidth: CoreFoundation.CGFloat
  public static let defaultPointRadius: CoreFoundation.CGFloat
}
public struct GeoJSONFeature : Swift.Identifiable {
  public let id: Swift.String?
  public let geometry: MapConductorGeoJSON.GeoJSONGeometry
  public let properties: [Swift.String : Any]
  public var strokeColor: UIKit.UIColor?
  public var fillColor: UIKit.UIColor?
  public var strokeWidth: CoreFoundation.CGFloat?
  public var pointRadius: CoreFoundation.CGFloat?
  public var visible: Swift.Bool
  public init(id: Swift.String? = nil, geometry: MapConductorGeoJSON.GeoJSONGeometry, properties: [Swift.String : Any] = [:], strokeColor: UIKit.UIColor? = nil, fillColor: UIKit.UIColor? = nil, strokeWidth: CoreFoundation.CGFloat? = nil, pointRadius: CoreFoundation.CGFloat? = nil, visible: Swift.Bool = true)
  public typealias ID = Swift.String?
}
final public class GeoJSONFeatureState : Combine.ObservableObject {
  final public let id: Swift.String
  @Combine.Published<MapConductorGeoJSON.GeoJSONGeometry> @_projectedValueProperty($geometry) final public var geometry: MapConductorGeoJSON.GeoJSONGeometry {
    get
    @available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
    set
    @available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
    _modify
  }
  final public var $geometry: Combine.Published<MapConductorGeoJSON.GeoJSONGeometry>.Publisher {
    get
    @available(iOS 14.0, tvOS 14.0, watchOS 7.0, macOS 11.0, *)
    set
  }
  @Combine.Published<[Swift.String : Any]> @_projectedValueProperty($properties) final public var properties: [Swift.String : Any] {
    get
    @available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
    set
    @available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
    _modify
  }
  final public var $properties: Combine.Published<[Swift.String : Any]>.Publisher {
    get
    @available(iOS 14.0, tvOS 14.0, watchOS 7.0, macOS 11.0, *)
    set
  }
  @Combine.Published<UIKit.UIColor?> @_projectedValueProperty($strokeColor) final public var strokeColor: UIKit.UIColor? {
    get
    @available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
    set
    @available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
    _modify
  }
  final public var $strokeColor: Combine.Published<UIKit.UIColor?>.Publisher {
    get
    @available(iOS 14.0, tvOS 14.0, watchOS 7.0, macOS 11.0, *)
    set
  }
  @Combine.Published<UIKit.UIColor?> @_projectedValueProperty($fillColor) final public var fillColor: UIKit.UIColor? {
    get
    @available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
    set
    @available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
    _modify
  }
  final public var $fillColor: Combine.Published<UIKit.UIColor?>.Publisher {
    get
    @available(iOS 14.0, tvOS 14.0, watchOS 7.0, macOS 11.0, *)
    set
  }
  @Combine.Published<CoreFoundation.CGFloat?> @_projectedValueProperty($strokeWidth) final public var strokeWidth: CoreFoundation.CGFloat? {
    get
    @available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
    set
    @available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
    _modify
  }
  final public var $strokeWidth: Combine.Published<CoreFoundation.CGFloat?>.Publisher {
    get
    @available(iOS 14.0, tvOS 14.0, watchOS 7.0, macOS 11.0, *)
    set
  }
  @Combine.Published<CoreFoundation.CGFloat?> @_projectedValueProperty($pointRadius) final public var pointRadius: CoreFoundation.CGFloat? {
    get
    @available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
    set
    @available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
    _modify
  }
  final public var $pointRadius: Combine.Published<CoreFoundation.CGFloat?>.Publisher {
    get
    @available(iOS 14.0, tvOS 14.0, watchOS 7.0, macOS 11.0, *)
    set
  }
  @Combine.Published<Swift.Bool> @_projectedValueProperty($visible) final public var visible: Swift.Bool {
    get
    @available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
    set
    @available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
    _modify
  }
  final public var $visible: Combine.Published<Swift.Bool>.Publisher {
    get
    @available(iOS 14.0, tvOS 14.0, watchOS 7.0, macOS 11.0, *)
    set
  }
  public init(featureId: Swift.String? = nil, geometry: MapConductorGeoJSON.GeoJSONGeometry, properties: [Swift.String : Any] = [:], strokeColor: UIKit.UIColor? = nil, fillColor: UIKit.UIColor? = nil, strokeWidth: CoreFoundation.CGFloat? = nil, pointRadius: CoreFoundation.CGFloat? = nil, visible: Swift.Bool = true)
  final public func fingerPrint() -> MapConductorGeoJSON.GeoJSONFeatureFingerPrint
  final public func asPublisher() -> Combine.AnyPublisher<MapConductorGeoJSON.GeoJSONFeatureFingerPrint, Swift.Never>
  final public func toFeature() -> MapConductorGeoJSON.GeoJSONFeature
  public typealias ObjectWillChangePublisher = Combine.ObservableObjectPublisher
  @objc deinit
}
public struct GeoJSONFeatureFingerPrint : Swift.Equatable {
  public let id: Swift.Int
  public let geometry: Swift.Int
  public let properties: Swift.Int
  public let style: Swift.Int
  public let visible: Swift.Int
  public static func == (a: MapConductorGeoJSON.GeoJSONFeatureFingerPrint, b: MapConductorGeoJSON.GeoJSONFeatureFingerPrint) -> Swift.Bool
}
public struct LonLat : Swift.Equatable, Swift.Hashable {
  public let longitude: Swift.Double
  public let latitude: Swift.Double
  public init(longitude: Swift.Double, latitude: Swift.Double)
  public static func == (a: MapConductorGeoJSON.LonLat, b: MapConductorGeoJSON.LonLat) -> Swift.Bool
  public func hash(into hasher: inout Swift.Hasher)
  public var hashValue: Swift.Int {
    get
  }
}
indirect public enum GeoJSONGeometry : Swift.Equatable, Swift.Hashable {
  case point(longitude: Swift.Double, latitude: Swift.Double)
  case multiPoint(points: [MapConductorGeoJSON.LonLat])
  case lineString(coordinates: [MapConductorGeoJSON.LonLat])
  case multiLineString(lines: [[MapConductorGeoJSON.LonLat]])
  case polygon(rings: [[MapConductorGeoJSON.LonLat]])
  case multiPolygon(polygons: [[[MapConductorGeoJSON.LonLat]]])
  case geometryCollection(geometries: [MapConductorGeoJSON.GeoJSONGeometry])
  case empty
  public static func == (a: MapConductorGeoJSON.GeoJSONGeometry, b: MapConductorGeoJSON.GeoJSONGeometry) -> Swift.Bool
  public func hash(into hasher: inout Swift.Hasher)
  public var hashValue: Swift.Int {
    get
  }
}
@_Concurrency.MainActor @preconcurrency public struct GeoJSONLayer : MapConductorCore.ViewBasedMapOverlay, Swift.Identifiable {
  @_Concurrency.MainActor @preconcurrency public let id: Swift.String
  @_Concurrency.MainActor @preconcurrency public init(_ state: MapConductorGeoJSON.GeoJSONLayerState, features: [MapConductorGeoJSON.GeoJSONFeature] = [])
  @_Concurrency.MainActor @preconcurrency public init(state: MapConductorGeoJSON.GeoJSONLayerState, features: [MapConductorGeoJSON.GeoJSONFeature] = [])
  @_Concurrency.MainActor @preconcurrency public init(features: [MapConductorGeoJSON.GeoJSONFeature] = [], tileSize: Swift.Int = GeoJSONDefaults.defaultTileSize, opacity: Swift.Double = GeoJSONDefaults.defaultOpacity, layerStyle: MapConductorGeoJSON.GeoJSONTileRenderer.LayerStyle = GeoJSONTileRenderer.LayerStyle(), styleProvider: any MapConductorGeoJSON.GeoJSONStyleProvider = DefaultGeoJSONStyleProvider.shared)
  @_Concurrency.MainActor @preconcurrency public var body: some SwiftUICore.View {
    get
  }
  @_Concurrency.MainActor @preconcurrency public func append(to content: inout MapConductorCore.MapViewContent)
  public typealias Body = @_opaqueReturnTypeOf("$s19MapConductorGeoJSON0C9JSONLayerV4bodyQrvp", 0) __
  public typealias ID = Swift.String
}
final public class GeoJSONLayerState : Combine.ObservableObject {
  final public var onClick: ((MapConductorGeoJSON.GeoJSONFeature, MapConductorCore.GeoPoint) -> Swift.Void)?
  final public var onLoadStart: (() -> Swift.Void)?
  final public var onLoadComplete: (((any Swift.Error)?) -> Swift.Void)?
  final public var opacity: Swift.Double {
    get
    set
  }
  final public var minZoom: Swift.Int {
    get
    set
  }
  final public var maxZoom: Swift.Int {
    get
    set
  }
  final public var layerStyle: MapConductorGeoJSON.GeoJSONTileRenderer.LayerStyle {
    get
    set
  }
  final public var styleProvider: any MapConductorGeoJSON.GeoJSONStyleProvider {
    get
    set
  }
  public init(tileSize: Swift.Int = GeoJSONDefaults.defaultTileSize, opacity: Swift.Double = GeoJSONDefaults.defaultOpacity, minZoom: Swift.Int = 0, maxZoom: Swift.Int = GeoJSONDefaults.defaultMaxZoom, layerStyle: MapConductorGeoJSON.GeoJSONTileRenderer.LayerStyle = GeoJSONTileRenderer.LayerStyle(), styleProvider: any MapConductorGeoJSON.GeoJSONStyleProvider = DefaultGeoJSONStyleProvider.shared, onLoadStart: (() -> Swift.Void)? = nil, onLoadComplete: (((any Swift.Error)?) -> Swift.Void)? = nil, onClick: ((MapConductorGeoJSON.GeoJSONFeature, MapConductorCore.GeoPoint) -> Swift.Void)? = nil)
  @objc deinit
  final public func setFeatures(_ features: [MapConductorGeoJSON.GeoJSONFeature])
  final public func beginLoading()
  final public func completeLoading(error: (any Swift.Error)? = nil)
  final public func setFeatures(_ states: [MapConductorGeoJSON.GeoJSONFeatureState])
  final public func processClick(geoPoint: MapConductorCore.GeoPoint, pixelTolerance: Swift.Double? = nil, zoom: Swift.Double? = nil)
  public typealias ObjectWillChangePublisher = Combine.ObservableObjectPublisher
}
public enum GeoJSONParser {
  public static func parse(data: Foundation.Data) -> [MapConductorGeoJSON.GeoJSONFeature]
  public static func parse(stream: Foundation.InputStream) -> [MapConductorGeoJSON.GeoJSONFeature]
  public static func parse(fileURL: Foundation.URL) -> [MapConductorGeoJSON.GeoJSONFeature]
}
public enum GeoJSONSeqParser {
  public static func parse(data: Foundation.Data) -> [MapConductorGeoJSON.GeoJSONFeature]
  public static func parse(stream: Foundation.InputStream) -> [MapConductorGeoJSON.GeoJSONFeature]
  public static func parse(fileURL: Foundation.URL) -> [MapConductorGeoJSON.GeoJSONFeature]
  public static func streamParse(data: Foundation.Data, onFeature: (MapConductorGeoJSON.GeoJSONFeature) -> Swift.Void)
  public static func streamParse(stream: Foundation.InputStream, onFeature: (MapConductorGeoJSON.GeoJSONFeature) -> Swift.Void)
  public static func streamParse(fileURL: Foundation.URL, onFeature: (MapConductorGeoJSON.GeoJSONFeature) -> Swift.Void)
}
public protocol GeoJSONStyleProvider : AnyObject {
  func style(for feature: MapConductorGeoJSON.GeoJSONFeature, defaultStyle: MapConductorGeoJSON.GeoJSONTileRenderer.LayerStyle) -> MapConductorGeoJSON.GeoJSONTileRenderer.LayerStyle
}
@_hasMissingDesignatedInitializers final public class DefaultGeoJSONStyleProvider : MapConductorGeoJSON.GeoJSONStyleProvider {
  public static let shared: MapConductorGeoJSON.DefaultGeoJSONStyleProvider
  final public func style(for feature: MapConductorGeoJSON.GeoJSONFeature, defaultStyle: MapConductorGeoJSON.GeoJSONTileRenderer.LayerStyle) -> MapConductorGeoJSON.GeoJSONTileRenderer.LayerStyle
  @objc deinit
}
final public class GeoJSONTileRenderer : MapConductorCore.TileProvider {
  final public let tileSize: Swift.Int
  public struct LayerStyle {
    public let strokeColor: UIKit.UIColor
    public let fillColor: UIKit.UIColor
    public let strokeWidth: CoreFoundation.CGFloat
    public let pointRadius: CoreFoundation.CGFloat
    public init(strokeColor: UIKit.UIColor = GeoJSONDefaults.defaultStrokeColor, fillColor: UIKit.UIColor = GeoJSONDefaults.defaultFillColor, strokeWidth: CoreFoundation.CGFloat = GeoJSONDefaults.defaultStrokeWidth, pointRadius: CoreFoundation.CGFloat = GeoJSONDefaults.defaultPointRadius)
  }
  public struct GeoJSONHitTestResult {
    public let feature: MapConductorGeoJSON.GeoJSONFeature
    public let position: MapConductorCore.GeoPoint
  }
  public init(tileSize: Swift.Int = GeoJSONDefaults.defaultTileSize)
  final public func update(features: [MapConductorGeoJSON.GeoJSONFeature], layerStyle: MapConductorGeoJSON.GeoJSONTileRenderer.LayerStyle, styleProvider: any MapConductorGeoJSON.GeoJSONStyleProvider = DefaultGeoJSONStyleProvider.shared)
  final public func renderTile(request: MapConductorCore.TileRequest) -> Foundation.Data?
  final public func hitTest(longitude: Swift.Double, latitude: Swift.Double, lineTolSq: Swift.Double? = nil, pointTolSq: Swift.Double? = nil) -> MapConductorGeoJSON.GeoJSONTileRenderer.GeoJSONHitTestResult?
  final public func hitTestFeature(longitude: Swift.Double, latitude: Swift.Double, lineTolSq: Swift.Double? = nil, pointTolSq: Swift.Double? = nil) -> MapConductorGeoJSON.GeoJSONFeature?
  @objc deinit
}
extension MapConductorGeoJSON.GeoJSONLayer : Swift.Sendable {}
