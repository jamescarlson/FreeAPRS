//
//  CellViewModels.swift
//  FreeAPRS
//
//  Created by James on 1/8/17.
//  Copyright © 2017 dimnsionofsound. All rights reserved.
//

import Foundation
import CoreLocation

extension CLLocationCoordinate2D {
    func humanReadableString(withDigitsOfAccuracy digits: Int) -> String {
        let lat = String(format: "%.\(digits)f", self.latitude)
        let long = String(format: "%.\(digits)f", self.longitude)
        
        return lat + ", " + long
    }
}

let formatter : DateFormatter = {
    let formatter = DateFormatter()
    formatter.timeZone = TimeZone.autoupdatingCurrent
    formatter.dateFormat = "MM/dd HH:mm:ss"
    return formatter
}()

class PacketCellViewModel {
    let packet : APRSPacket
    init(packet: APRSPacket) {
        self.packet = packet
    }
    
    lazy var source: String = {
        return self.packet.source +
            ((self.packet.sourceSSID == 0) ?
                "" :
                "-" + String(describing: self.packet.sourceSSID))
    }()
    
    lazy var destination: String = {
        return self.packet.destination +
            ((self.packet.destinationSSID == 0) ?
                "" :
                "-" + String(describing: self.packet.destinationSSID))
    }()
    
    lazy var timestamp: String = {
        let timestamp = self.packet.data?.timestamp
        if timestamp != nil {
            return formatter.string(from: timestamp!)
        } else {
            return "Invalid"
        }
    }()
    
    lazy var type: String = {
        return self.packet.data?.type?.rawValue ?? "Unknown"
    }()
}

class LocationCellViewModel : PacketCellViewModel {
    
    lazy var symbol: String = {
        return self.packet.data?.symbol?.rawValue ?? "[No Symbol]"
    }()
    
    lazy var location: String = {
        let coordinate = self.packet.data?.location?.coordinate
        if coordinate != nil {
            return coordinate!.humanReadableString(withDigitsOfAccuracy: 4)
        } else {
            return "Invalid"
        }
    }()
    
    lazy var comment: String = {
        return self.packet.data?.comment ?? ""
    }()
}

class StatusCellViewModel : PacketCellViewModel {
    lazy var status: String = {
        return self.packet.data?.status ?? ""
    }()
}

class MessageCellViewModel : PacketCellViewModel {
    lazy var addressee: String = {
        return self.packet.data?.message?.destination ?? ""
    }()
    
    lazy var message: String = {
        return self.packet.data?.message?.message ?? ""
    }()
    
    lazy var idNumber: String = {
        guard let messageID = self.packet.data?.message?.messageID else {
            return ""
        }
        
        return "#" + String(describing: messageID)
    }()
}

class ObjectCellViewModel : PacketCellViewModel {
    lazy var location: String = {
        let coordinate = self.packet.data?.location?.coordinate
        if coordinate != nil {
            return coordinate!.humanReadableString(withDigitsOfAccuracy: 4)
        } else {
            return "Invalid"
        }
    }()
    
    lazy var alive: String = {
        guard let alive = self.packet.data?.object?.alive else {
            return ""
        }
        
        return alive ? "✅" : "❌"
    }()
    
    lazy var name: String = {
        return self.packet.data?.object?.name ?? ""
    }()
}

class ItemCellViewModel : ObjectCellViewModel {
    // Just an alias for ObjectCellViewModel
}

class OtherCellViewModel : PacketCellViewModel {
    lazy var information: String = {
        return self.packet.information
    }()
}

