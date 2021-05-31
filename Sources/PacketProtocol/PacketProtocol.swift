import Foundation

public class PacketProtocol {
    public static func process(at path: String,
                               sensorCompletion: @escaping (SensorPacketHeader, [Data]) -> Void = { _,_  in },
                               physicalCompletion: @escaping (PhysicalPacketHeader, [Data]) -> Void = { _,_  in }) -> Bool {
        guard let handle = FileHandle(forReadingAtPath: path) else {
            fatalError()
        }

        let total = handle.availableData.count
        try! handle.seek(toOffset: 0)
        while try! handle.offset() != total {
            guard let blockTypeData = try? handle.peek(upToCount: MemoryLayout<BlockType>.stride) else {
                print("DATA READ ERROR")
                return false
            }
            let blockType: BlockType = blockTypeData.asStruct()
            switch blockType {
            case BLOCK_TYPE_SENSOR:
                parseSensorPacket(handle, completion: sensorCompletion)
            case BLOCK_TYPE_PHYSICAL:
                parsePhysicalPacket(handle, completion: physicalCompletion)
            default:
                print("UNKNOWN BLOCK TYPE")
                return false
            }
        }
        return true
    }

    private static func parseSensorPacket(_ handle: FileHandle, completion: @escaping (SensorPacketHeader, [Data]) -> Void) {
        guard let headerData = try? handle.read(upToCount: MemoryLayout<SensorPacketHeader>.stride) else {
            print("DATA READ ERROR")
            return
        }
        let header: SensorPacketHeader = headerData.asStruct()
        let sampleData = parseData(handle, header: header)
        completion(header, sampleData)
    }

    private static func parsePhysicalPacket(_ handle: FileHandle, completion: @escaping (PhysicalPacketHeader, [Data]) -> Void) {
        guard let headerData = try! handle.read(upToCount: MemoryLayout<PhysicalPacketHeader>.stride) else {
            print("DATA READ ERROR")
            return
        }
        let header: PhysicalPacketHeader = headerData.asStruct()
        let sampleData = parseData(handle, header: header)
        completion(header, sampleData)
    }

    private static func parseData(_ handle: FileHandle, header: SensorPacketHeader) -> [Data] {
        let dataSize: Int = header.unitNumber * header.dataUnit.size
        let number = Int(header.dataLength) / dataSize
        return (0 ..< number).compactMap { _ in try? handle.read(upToCount: dataSize) }
    }

    private static func parseData(_ handle: FileHandle, header: PhysicalPacketHeader) -> [Data] {
        let dataSize: Int = 1
        let number = Int(header.dataLength) / dataSize
        return (0 ..< number).compactMap { _ in try? handle.read(upToCount: dataSize) }
    }
}

extension Data {
    func asStruct<T>(fromByteOffset offset: Int = 0) -> T {
        return withUnsafeBytes { $0.load(fromByteOffset: offset, as: T.self) }
    }
}

extension FileHandle {
    func peek(upToCount count: Int) throws -> Data? {
        // persist the current offset, since `upToCount` doesn't guarantee all bytes will be read
        let originalOffset = offsetInFile
        let data = try read(upToCount: count)
        try seek(toOffset: originalOffset)
        return data
    }
}
