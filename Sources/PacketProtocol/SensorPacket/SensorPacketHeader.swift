//
//  SensorPacketHeader.swift
//
//
//  Created by Kyle on 2021/5/30.
//

import Foundation

/**
 *  The Sensor Packet Header
 *  20 bytes in total
 *  - blockType        1 byte
 *  - reserved          1 byte
 *  - sensorType      1 byte
 *  - dataSubtype    1 byte
 *  - version         1 byte
 *  - dataFormat      1 byte
 *  - flag                   1 byte
 *  - collenctionID    1 byte
 *  - sampleCount    2 byte
 *  - sampleRate      2 byte
 *  - timeStamp        6 byte
 *      - _1            32 bit
 *      - _2            16 bit
 *  - length               2 byte
 */
public struct SensorPacketHeader {
    public var blockType: BlockType // BLOCK_TYPE_SENSOR
    public var reserved: UInt8
    public var senesorType: SensorType // SENSOR_TYPE_ECG
    public var dataSubtype: UInt8 // ignored for ECG
    public var version: UInt8
    public var dataFormat: UInt8 // TODO:
    public var flag: FlagOptions // TODO:
    public var collectionID: UInt8
    public var sampleCount: UInt16
    public var sampleRate: UInt16
    private var _timeStamp1: UInt32 // low 32 bit for timeStamp
    private var _timeStamp2: UInt16 // high 16 bit for timeStamp
    public var dataLength: UInt16
}

// MARK: - Data Format

extension SensorPacketHeader {
    public enum DataUint: Int {
        case uint32 = 0
        case int32 = 1
        case uint16 = 2
        case int16 = 3

        var size: Int {
            switch self {
            case .uint32, .int32:
                return 4
            case .uint16, .int16:
                return 2
            }
        }
    }

    public var dataUnit: DataUint {
        DataUint(rawValue: Int(dataFormat & 0x0F))!
    }

    public var unitNumber: Int {
        Int(dataFormat >> 4)
    }
}

// MARK: - Flag

extension SensorPacketHeader {
    public struct FlagOptions: OptionSet {
        public let rawValue: UInt8
        public init(rawValue: UInt8) {
            self.rawValue = rawValue
        }

        static let compress = FlagOptions(rawValue: 1 << 0) // 1 means the data is compressed, 0 for raw data
        static let msb = FlagOptions(rawValue: 1 << 1) // 1 means MSB first
        static let start = FlagOptions(rawValue: 1 << 2) // 1 means this block starts a data collection
        static let end = FlagOptions(rawValue: 1 << 3) // 1 means this block ends a data collection
        static let encrypted = FlagOptions(rawValue: 1 << 4) // 1 means the data is encrypted
        static let cached = FlagOptions(rawValue: 1 << 5) // 1 means cached data, 0 means real-time data
    }
}

// MARK: - Time Stamp

extension SensorPacketHeader {
    /// in miliseconds since 1970
    public var timeStamp: UInt64 {
        (UInt64(_timeStamp2) << 32) | UInt64(_timeStamp1)
    }

    public var sendDate: Date {
        Date(timeIntervalSince1970: TimeInterval(Double(timeStamp) / 1000.0))
    }
}

// MARK: - CustomStringConvertible

extension SensorPacketHeader: CustomStringConvertible {
    public var description: String {
        """
        SensorPacketHeader:[
            blockType: \(blockType),
            sensorType: \(senesorType),
            dataSubType: \(dataSubtype),
            version: \(version),
            dataFormat: \(unitNumber) \(dataUnit),
            flag: \(flag),
            collectionID: \(collectionID),
            sampleCount: \(sampleCount),
            sampleRate: \(sampleRate),
            sendDate: \(sendDate),
            dataLength: \(dataLength)
        ]
        """
    }
}

extension SensorPacketHeader.DataUint: CustomStringConvertible {
    public var description: String {
        switch self {
        case .uint32:
            return "UInt32"
        case .int32:
            return "Int32"
        case .uint16:
            return "UInt16"
        case .int16:
            return "Int16"
        }
    }
}

extension SensorPacketHeader.FlagOptions: CustomStringConvertible {
    public var description: String {
        switch self {
        case .compress:
            return "compress"
        case .msb:
            return "msb"
        case .start:
            return "start"
        case .end:
            return "end"
        case .encrypted:
            return "encrypted"
        case .cached:
            return "cached"
        default:
            return "\(rawValue) " +
                Array([.encrypted, .start, .end, .cached])
                .filter { contains($0) }
                .description
        }
    }
}
