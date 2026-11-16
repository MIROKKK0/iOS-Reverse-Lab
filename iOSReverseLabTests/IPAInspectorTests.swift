import XCTest
@testable import iOSReverseLab

final class IPAInspectorTests: XCTestCase {
    func testRejectsNonZipInput() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try Data("not an ipa".utf8).write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }
        XCTAssertThrowsError(try IPAInspector.inspect(url: url))
    }
}