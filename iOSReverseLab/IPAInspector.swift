import Foundation
import ZIPFoundation

struct IPAReport {
    let fileName: String
    let fileSize: Int64
    let isZip: Bool
    let entryCount: Int
    let executableName: String?
    let bundleIdentifier: String?
    let version: String?
    let buildNumber: String?
    let architectures: [String]
    let minimumOSVersion: String?
}

enum IPAInspectorError: LocalizedError {
    case unreadable, tooLarge, invalidArchive, missingAppBundle, invalidInfoPlist

    var errorDescription: String? {
        switch self {
        case .unreadable: return "Não foi possível ler o arquivo selecionado."
        case .tooLarge: return "Arquivo acima do limite de 2 GB."
        case .invalidArchive: return "O arquivo ZIP/IPA está inválido ou não é compatível."
        case .missingAppBundle: return "O IPA não contém Payload/*.app/Info.plist."
        case .invalidInfoPlist: return "O Info.plist está ausente, inválido ou excede 4 MB."
        }
    }
}

enum IPAInspector {
    private static let maximumArchiveSize: Int64 = 2_000_000_000
    private static let maximumInfoPlistSize = 4 * 1024 * 1024

    static func inspect(url: URL) throws -> IPAReport {
        let values = try url.resourceValues(forKeys: [.fileSizeKey])
        let size = Int64(values.fileSize ?? 0)
        guard size > 0 else { throw IPAInspectorError.unreadable }
        guard size <= maximumArchiveSize else { throw IPAInspectorError.tooLarge }

        guard let archive = Archive(url: url, accessMode: .read) else {
            throw IPAInspectorError.invalidArchive
        }

        let entries = Array(archive)
        guard let infoEntry = entries.first(where: {
            let parts = $0.path.split(separator: "/")
            return parts.count == 3 &&
                parts[0] == "Payload" &&
                parts[1].hasSuffix(".app") &&
                parts[2] == "Info.plist"
        }) else {
            throw IPAInspectorError.missingAppBundle
        }

        var plistData = Data()
        do {
            _ = try archive.extract(infoEntry) { chunk in
                if plistData.count + chunk.count <= maximumInfoPlistSize {
                    plistData.append(chunk)
                } else {
                    plistData.removeAll(keepingCapacity: false)
                }
            }
        } catch {
            throw IPAInspectorError.invalidInfoPlist
        }
        guard !plistData.isEmpty,
              let plist = try? PropertyListSerialization.propertyList(from: plistData, options: [], format: nil) as? [String: Any]
        else { throw IPAInspectorError.invalidInfoPlist }

        let executable = plist["CFBundleExecutable"] as? String
        let appPath = String(infoEntry.path.dropLast("Info.plist".count))
        var architectures: [String] = []
        if let executable,
           let binary = entries.first(where: { $0.path == appPath + executable }) {
            var header = Data()
            _ = try? archive.extract(binary) { chunk in
                if header.count < 64 {
                    header.append(chunk.prefix(64 - header.count))
                }
            }
            architectures = machOArchitectures(from: header)
        }

        return IPAReport(
            fileName: url.lastPathComponent,
            fileSize: size,
            isZip: true,
            entryCount: entries.count,
            executableName: executable,
            bundleIdentifier: plist["CFBundleIdentifier"] as? String,
            version: plist["CFBundleShortVersionString"] as? String,
            buildNumber: plist["CFBundleVersion"] as? String,
            architectures: architectures,
            minimumOSVersion: plist["MinimumOSVersion"] as? String
        )
    }

    private static func machOArchitectures(from data: Data) -> [String] {
        guard data.count >= 8 else { return [] }
        let bytes = [UInt8](data)
        let magic = Array(bytes.prefix(4))
        let littleEndian = magic == [0xCE, 0xFA, 0xED, 0xFE] ||
            magic == [0xCF, 0xFA, 0xED, 0xFE]
        let bigEndianFat = magic == [0xCA, 0xFE, 0xBA, 0xBE] ||
            magic == [0xCA, 0xFE, 0xBA, 0xBF]
        let isMachO = littleEndian || magic == [0xFE, 0xED, 0xFA, 0xCE] ||
            magic == [0xFE, 0xED, 0xFA, 0xCF]
        if isMachO {
            let cpu = readUInt32(bytes, at: 4, littleEndian: littleEndian)
            return [architectureName(cpu)]
        }
        guard bigEndianFat, data.count >= 8 else { return [] }
        let count = Int(readUInt32(bytes, at: 4, littleEndian: false))
        guard count > 0, count <= 32, data.count >= 8 + count * 20 else { return [] }
        return (0..<count).map { index in
            architectureName(readUInt32(bytes, at: 8 + index * 20, littleEndian: false))
        }
    }

    private static func readUInt32(_ bytes: [UInt8], at offset: Int, littleEndian: Bool) -> UInt32 {
        guard offset + 4 <= bytes.count else { return 0 }
        let b = bytes[offset..<(offset + 4)]
        if littleEndian {
            return UInt32(b[b.startIndex]) |
                UInt32(b[b.startIndex + 1]) << 8 |
                UInt32(b[b.startIndex + 2]) << 16 |
                UInt32(b[b.startIndex + 3]) << 24
        }
        return UInt32(b[b.startIndex]) << 24 |
            UInt32(b[b.startIndex + 1]) << 16 |
            UInt32(b[b.startIndex + 2]) << 8 |
            UInt32(b[b.startIndex + 3])
    }

    private static func architectureName(_ cpu: UInt32) -> String {
        switch cpu {
        case 12: return "arm"
        case 0x0100000C: return "arm64"
        case 7: return "x86"
        case 0x01000007: return "x86_64"
        default: return String(format: "CPU 0x%08X", cpu)
        }
    }
}
