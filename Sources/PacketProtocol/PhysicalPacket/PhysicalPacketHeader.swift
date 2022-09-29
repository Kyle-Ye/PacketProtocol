//
//  PhysicalPacketHeader.swift
//
//
//  Created by Kyle on 2021/5/30.
//

import Foundation

/**
 *  The Physical Packet Header
 *  10 bytes / 80 bits in total
 *  - blockType         1 byte
 *  - flagVersion       1 byte
 *      - flag          4 bit
 *      - reserved  2 bit
 *      - version 2 bit
 *  - timeStamp        4 byte
 *      - _1            16 bit
 *      - _2            16 bit
 *  - dataProperty     4 byte
 *      - dataType 10 bit
 *      - duration   12 bit
 *      - length       10 bit
 */
public struct PhysicalPacketHeader {
    public var blockType: BlockType // BLOCK_TYPE_PHYSICAL
    private var _flagVersion: UInt8 // bit 0~3 for flag, bit 4~5 reserved, bit 6~7 for version
    private var _timeStamp1: UInt16 // low 16 bit for timeStamp
    private var _timeStamp2: UInt16 // high 16 bit for timeStamp
    private var _dataProperty1: UInt16 // low 16 bit for dataProperty
    private var _dataProperty2: UInt16 // high 16 bit for dataProperty
}

// MARK: - Flag Version

extension PhysicalPacketHeader {
    public struct FlagOptions: OptionSet {
        public let rawValue: UInt8
        public init(rawValue: UInt8) {
            self.rawValue = rawValue
        }

        static let encrypted = FlagOptions(rawValue: 1 << 0) // 1 means the data is encrypted
        static let start = FlagOptions(rawValue: 1 << 1) // 1 means this block starts a data collection
        static let end = FlagOptions(rawValue: 1 << 2) // 1 means this block ends a data collection
        static let cached = FlagOptions(rawValue: 1 << 3) // 1 means cached data, 0 means real-time data
    }

    public var flag: FlagOptions {
        FlagOptions(rawValue: _flagVersion & 0x0F)
    }

    public var version: UInt {
        UInt(_flagVersion >> 6)
    }
}

// MARK: - Time Stamp

extension PhysicalPacketHeader {
    /// in seconds since 1970
    public var timeStamp: UInt32 {
        (UInt32(_timeStamp2) << 16) | UInt32(_timeStamp1)
    }

    public var sendDate: Date {
        Date(timeIntervalSince1970: TimeInterval(timeStamp))
    }
}

// MARK: - Data Property

extension PhysicalPacketHeader {
    /// bit 0~9 for data type, bit 10~21 for data duration in seconds, bit 22~31 for data length in bytes
    public var dataProperty: UInt32 {
        (UInt32(_dataProperty2) << 16) | UInt32(_dataProperty1)
    }

    public struct TypeOptions: OptionSet {
        public let rawValue: UInt8
        public init(rawValue: UInt8) {
            self.rawValue = rawValue
        }

        static let hr = TypeOptions(rawValue: 1 << 0) // 1 means the data contains HR info
        static let rr = TypeOptions(rawValue: 1 << 1) // 1 means the data contains RR info
        static let spO2 = TypeOptions(rawValue: 1 << 2) // 1 means the data contains SpO2 info
    }

    public var dataType: TypeOptions {
        TypeOptions(rawValue: UInt8(dataProperty & 0x000003FF))
    }

    public var duration: UInt {
        UInt((dataProperty >> 10) & 0x00000FFF)
    }

    public var dataLength: UInt {
        UInt(dataProperty >> 22)
    }
}

// CustomStringConvertible

extension PhysicalPacketHeader: CustomStringConvertible {
    public var description: String {
        """
        PhysicalPacketHeader:[
            blockType: \(blockType),
            flag: \(flag),
            version: \(version),
            sendDate: \(sendDate),
            dataType: \(dataType),
            duration: \(duration),
            dataLength: \(dataLength)
        ]
        """
    }
}

extension PhysicalPacketHeader.FlagOptions: CustomStringConvertible {
    public var description: String {
        switch self {
        case .encrypted:
            return "encrypted"
        case .start:
            return "start"
        case .end:
            return "end"
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

extension PhysicalPacketHeader.TypeOptions: CustomStringConvertible {
    public var description: String {
        switch self {
        case .hr:
            return "hr"
        case .rr:
            return "rr"
        case .spO2:
            return "spO2"
        default:
            return "\(rawValue) " +
                Array([.hr, .rr, .spO2])
                .filter { contains($0) }
                .description
        }
    }
}
