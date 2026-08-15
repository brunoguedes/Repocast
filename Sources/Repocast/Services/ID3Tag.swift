import Foundation

/// A minimal ID3v2.3/v2.4 tag reader for the frames a narration package
/// carries: `TIT2` (title), `TALB` (album / package name), `TPE1` (artist —
/// the TTS voice), `TRCK` (track N/M) and `USLT` (unsynchronised lyrics — the
/// file's full transcript). Hand-rolled because `AVAsset` metadata loading is
/// async and doesn't surface `USLT` reliably, while the format itself is a few
/// dozen lines; anything unrecognised is skipped, and a malformed or missing
/// tag yields `nil` rather than an error.
struct ID3Tag: Sendable, Equatable {
    var title: String?
    var album: String?
    var artist: String?
    var lyrics: String?
    var trackNumber: Int?
    var trackTotal: Int?

    /// Read the leading ID3v2 tag of the file at `url`, or `nil` if there
    /// isn't a parseable one. Uses a mapped read so large audio files aren't
    /// pulled into memory.
    static func read(from url: URL) -> ID3Tag? {
        guard let data = try? Data(contentsOf: url, options: .mappedIfSafe) else { return nil }
        return parse(data)
    }

    static func parse(_ data: Data) -> ID3Tag? {
        // 10-byte header: "ID3", version (major, revision), flags, syncsafe size.
        guard data.count >= 10, data[0] == 0x49, data[1] == 0x44, data[2] == 0x33 else { return nil }
        let version = data[3]
        guard version == 3 || version == 4 else { return nil }
        let flags = data[5]
        guard flags & 0x80 == 0 else { return nil }  // unsynchronisation scheme unsupported
        let tagSize = syncsafe(data, at: 6)
        let end = min(10 + tagSize, data.count)

        var offset = 10
        if flags & 0x40 != 0 {  // extended header
            guard offset + 4 <= end else { return nil }
            let extSize = version == 4 ? syncsafe(data, at: offset) : Int(uint32(data, at: offset)) + 4
            offset += extSize
        }

        var tag = ID3Tag()
        while offset + 10 <= end {
            guard data[offset] != 0 else { break }  // hit the padding
            let idData = data.subdata(in: offset..<offset + 4)
            guard let frameID = String(data: idData, encoding: .isoLatin1) else { break }
            let frameSize = version == 4 ? syncsafe(data, at: offset + 4) : Int(uint32(data, at: offset + 4))
            guard frameSize > 0, offset + 10 + frameSize <= end else { break }
            let payload = data.subdata(in: offset + 10..<offset + 10 + frameSize)

            switch frameID {
            case "TIT2": tag.title = decodeText(payload)
            case "TALB": tag.album = decodeText(payload)
            case "TPE1": tag.artist = decodeText(payload)
            case "TRCK":
                let parts = (decodeText(payload) ?? "").split(separator: "/")
                tag.trackNumber = parts.first.flatMap { Int($0.trimmingCharacters(in: .whitespaces)) }
                tag.trackTotal = parts.count > 1 ? Int(parts[1].trimmingCharacters(in: .whitespaces)) : nil
            case "USLT": tag.lyrics = decodeLyrics(payload)
            default: break
            }
            offset += 10 + frameSize
        }
        return tag
    }

    // MARK: Frame payload decoding

    /// Text frame: one encoding byte, then the string.
    private static func decodeText(_ payload: Data) -> String? {
        guard payload.count > 1 else { return nil }
        return decode(payload.dropFirst(), encodingByte: payload[payload.startIndex])
    }

    /// USLT frame: encoding byte, 3-byte language, null-terminated content
    /// descriptor, then the lyrics text (all in the declared encoding).
    private static func decodeLyrics(_ payload: Data) -> String? {
        guard payload.count > 4 else { return nil }
        let encoding = payload[payload.startIndex]
        let body = payload.dropFirst(4)  // skip encoding + language
        let wide = encoding == 1 || encoding == 2
        guard let textStart = indexAfterTerminator(in: body, wide: wide) else { return nil }
        return decode(body[textStart...], encodingByte: encoding)
    }

    /// Index just past the first (1- or 2-byte) null terminator in `data`.
    private static func indexAfterTerminator(in data: Data, wide: Bool) -> Data.Index? {
        if wide {
            var index = data.startIndex
            while index + 1 < data.endIndex {
                if data[index] == 0 && data[index + 1] == 0 { return index + 2 }
                index += 2
            }
        } else if let zero = data.firstIndex(of: 0) {
            return zero + 1
        }
        return nil
    }

    private static func decode(_ data: Data, encodingByte: UInt8) -> String? {
        let encoding: String.Encoding = switch encodingByte {
        case 0: .isoLatin1
        case 1: .utf16       // BOM-prefixed
        case 2: .utf16BigEndian
        default: .utf8
        }
        guard let text = String(data: Data(data), encoding: encoding) else { return nil }
        let cleaned = text.trimmingCharacters(in: CharacterSet(charactersIn: "\0"))
        return cleaned.isEmpty ? nil : cleaned
    }

    // MARK: Integer helpers

    /// 4-byte syncsafe integer (7 bits per byte) at `index`.
    private static func syncsafe(_ data: Data, at index: Int) -> Int {
        let i = data.startIndex + index
        return Int(data[i] & 0x7F) << 21 | Int(data[i + 1] & 0x7F) << 14
            | Int(data[i + 2] & 0x7F) << 7 | Int(data[i + 3] & 0x7F)
    }

    private static func uint32(_ data: Data, at index: Int) -> UInt32 {
        let i = data.startIndex + index
        return UInt32(data[i]) << 24 | UInt32(data[i + 1]) << 16 | UInt32(data[i + 2]) << 8 | UInt32(data[i + 3])
    }
}
