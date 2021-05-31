import Foundation

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

func parseSensorPacket(_ handle: FileHandle) {
    guard let headerData = try? handle.read(upToCount: MemoryLayout<SensorPacketHeader>.stride) else {
        print("DATA READ ERROR")
        return
    }
    let header: SensorPacketHeader = headerData.asStruct()
    let sampleData = parseData(handle, header: header)
    print(header)
    print(sampleData)
}

func parsePhysicalPacket(_ handle: FileHandle) {
    guard let headerData = try! handle.read(upToCount: MemoryLayout<PhysicalPacketHeader>.stride) else {
        print("DATA READ ERROR")
        return
    }
    let header: PhysicalPacketHeader = headerData.asStruct()
    let sampleData = parseData(handle, header: header)
    print(header)
    print(sampleData)
}

func parseData(_ handle: FileHandle, header: SensorPacketHeader) -> [Data] {
    let dataSize: Int = header.unitNumber * header.dataUnit.size
    let number = Int(header.dataLength) / dataSize
    return (0 ..< number).compactMap{ _ in try? handle.read(upToCount: dataSize)}}

func parseData(_ handle: FileHandle, header: PhysicalPacketHeader) -> [Data] {
    let dataSize: Int = 1
    let number = Int(header.dataLength) / dataSize
    return (0 ..< number).compactMap{ _ in try? handle.read(upToCount: dataSize)}
}

func process(at path: String) -> Bool{
    guard let handle = FileHandle(forReadingAtPath: path) else {
        fatalError()
    }

    let total = handle.availableData.count
    try! handle.seek(toOffset: 0)
    while try!handle.offset() != total {
        guard let blockTypeData = try? handle.peek(upToCount: MemoryLayout<BlockType>.stride) else {
            print("DATA READ ERROR")
            return false
        }
        let blockType: BlockType = blockTypeData.asStruct()
        switch blockType {
        case BLOCK_TYPE_SENSOR:
            parseSensorPacket(handle)
        case BLOCK_TYPE_PHYSICAL:
            parsePhysicalPacket(handle)
        default:
            print("UNKNOWN BLOCK TYPE")
            return false
        }
    }
    return true
}
