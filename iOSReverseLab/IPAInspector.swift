import Foundation

struct IPAReport {
    let fileName: String
    let fileSize: Int64
    let isZip: Bool
    let entryCount: Int
    let executableName: String?
    let bundleIdentifier: String?
    let version: String?
}

enum IPAInspectorError: LocalizedError {
    case unreadable
    case tooLarge
    case invalidArchive

    var errorDescription: String? {
        switch self {
        case .unreadable: return "Não foi possível ler o arquivo selecionado."
        case .tooLarge: return "Arquivo acima do limite de 2 GB."
        case .invalidArchive: return "O arquivo não possui assinatura ZIP reconhecível."
        }
    }
}

enum IPAInspector {
    static func inspect(url: URL) throws -> IPAReport {
        let values = try url.resourceValues(forKeys: [.fileSizeKey])
        let size = Int64(values.fileSize ?? 0)
        guard size > 0 else { throw IPAInspectorError.unreadable }
        guard size <= 2_000_000_000 else { throw IPAInspectorError.tooLarge }

        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }
        let header = try handle.read(upToCount: 4) ?? Data()
        let validZip = header.count == 4 &&
            header[0] == 0x50 && header[1] == 0x4B &&
            [0x03, 0x05, 0x07].contains(header[2])
        guard validZip else { throw IPAInspectorError.invalidArchive }

        // MVP: checks only the ZIP signature. Full central-directory and
        // Info.plist parsing is deliberately not claimed yet.
        return IPAReport(
            fileName: url.lastPathComponent,
            fileSize: size,
            isZip: true,
            entryCount: 0,
            executableName: nil,
            bundleIdentifier: nil,
            version: nil
        )
    }
}