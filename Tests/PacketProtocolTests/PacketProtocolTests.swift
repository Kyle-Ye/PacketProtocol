@testable import PacketProtocol
import XCTest

final class PacketProtocolTests: XCTestCase {

    func testData() {
        let path = Bundle.module.path(forResource: "reference_data_v1", ofType: "bin", inDirectory: "TestData") ?? ""
        let result = process(at: path)
        XCTAssertTrue(result)
    }
}
