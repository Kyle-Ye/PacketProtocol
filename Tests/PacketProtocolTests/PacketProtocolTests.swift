@testable import PacketProtocol
import XCTest

final class PacketProtocolTests: XCTestCase {
    func testData() {
        let path = Bundle.module.path(forResource: "reference_data_v1", ofType: "bin", inDirectory: "TestData") ?? ""
        let result = PacketProtocol.process(at: path) { header, samplesData in
            print(header)
            print(samplesData.map { data -> (UInt16, UInt16) in
                (data.asStruct(),data.asStruct(fromByteOffset: 2))
            })
        } physicalCompletion: { header, samplesData in
            print(header)
            print(samplesData.map { data -> UInt8 in
                data.asStruct()
            })
        }
        XCTAssertTrue(result)
    }
}
