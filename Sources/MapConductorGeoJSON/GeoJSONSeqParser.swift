import Foundation

/// Parser for GeoJSON Text Sequences (RFC 8142).
///
/// Records are separated by RS (0x1E). Each record is a GeoJSON Feature or bare geometry.
/// Unlike FeatureCollection, there is no wrapping object, making this format
/// suitable for streaming very large datasets.
public enum GeoJSONSeqParser {

    private static let rs: UInt8 = 0x1E
    private static let chunkSize = 8192

    public static func parse(data: Data) -> [GeoJSONFeature] {
        var result: [GeoJSONFeature] = []
        streamParse(data: data) { result.append($0) }
        return result
    }

    public static func parse(stream: InputStream) -> [GeoJSONFeature] {
        var result: [GeoJSONFeature] = []
        streamParse(stream: stream) { result.append($0) }
        return result
    }

    public static func parse(fileURL: URL) -> [GeoJSONFeature] {
        guard let stream = InputStream(url: fileURL) else { return [] }
        return parse(stream: stream)
    }

    public static func streamParse(data: Data, onFeature: (GeoJSONFeature) -> Void) {
        let stream = InputStream(data: data)
        streamParse(stream: stream, onFeature: onFeature)
    }

    public static func streamParse(stream: InputStream, onFeature: (GeoJSONFeature) -> Void) {
        stream.open()
        defer { stream.close() }

        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: chunkSize)
        defer { buffer.deallocate() }

        var record = Data()
        record.reserveCapacity(4096)

        while stream.hasBytesAvailable {
            let bytesRead = stream.read(buffer, maxLength: chunkSize)
            guard bytesRead > 0 else { break }
            for i in 0..<bytesRead {
                if buffer[i] == rs {
                    flushRecord(&record, onFeature: onFeature)
                } else {
                    record.append(buffer[i])
                }
            }
        }
        flushRecord(&record, onFeature: onFeature)
    }

    public static func streamParse(fileURL: URL, onFeature: (GeoJSONFeature) -> Void) {
        guard let stream = InputStream(url: fileURL) else { return }
        streamParse(stream: stream, onFeature: onFeature)
    }

    private static func flushRecord(_ record: inout Data, onFeature: (GeoJSONFeature) -> Void) {
        defer { record.removeAll(keepingCapacity: true) }
        guard !record.isEmpty else { return }
        guard let dict = try? JSONSerialization.jsonObject(with: record) as? [String: Any] else { return }
        if let feature = GeoJSONParser.parseRecord(dict) {
            onFeature(feature)
        }
    }
}
