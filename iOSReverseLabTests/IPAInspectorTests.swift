import XCTest
@testable import iOSReverseLab

final class IPAInspectorTests: XCTestCase {
    func testRejectsNonZipInput() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try Data("not an ipa".utf8).write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }
        XCTAssertThrowsError(try IPAInspector.inspect(url: url))
    }

    func testRejectsZipWithoutAppBundle() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".ipa")
        let archive = Archive(url: url, accessMode: .create)!
        try archive.addEntry(with: "readme.txt", type: .file, uncompressedSize: 4,
                             provider: { position, size in
            let bytes = Data("test".utf8)
            return bytes.subdata(in: Int(position)..<min(Int(position + size), bytes.count))
        })
        defer { try? FileManager.default.removeItem(at: url) }
        XCTAssertThrowsError(try IPAInspector.inspect(url: url))
    }
}
