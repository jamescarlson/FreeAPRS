//
//  APRSFilter.swift
//  FreeAPRS
//
//  Created by James on 1/7/17.
//  Copyright © 2017 dimnsionofsound. All rights reserved.
//

import Foundation
import CoreLocation

enum StringFilterCriteria {
    case contains
    case exactly
    case notContains
}

enum PacketFilterCriteria {
    case source
    case destination
    case information
    case dataType
    case dataTimestamp
    case dataLocation
}

func matches(_ first: String, _ second: String, criteria: StringFilterCriteria) -> Bool {
    if (criteria == .exactly) {
        return first == second
    } else if (criteria == .contains) {
        return first.range(of: second) != nil
    } else { //notContains
        return first.range(of: second) == nil
    }
}

extension Collection where Iterator.Element == APRSPacket {
    func matching(source: String, criteria: StringFilterCriteria) -> [APRSPacket] {
        var results = [APRSPacket]()
        for packet in self {
            if matches(packet.source, source, criteria: criteria) {
                results.append(packet)
            }
        }
        return results
    }
    
    func matching(destination: String, criteria: StringFilterCriteria) -> [APRSPacket] {
        var results = [APRSPacket]()
        for packet in self {
            if matches(packet.destination, destination, criteria: criteria) {
                results.append(packet)
            }
        }
        return results
    }
    
    func matching(information: String, criteria: StringFilterCriteria) -> [APRSPacket] {
        var results = [APRSPacket]()
        for packet in self {
            if matches(packet.information, information, criteria: criteria) {
                results.append(packet)
            }
        }
        return results
    }
    
    func matching(dataType: PacketType) -> [APRSPacket] {
        var results = [APRSPacket]()
        for packet in self {
            if packet.data?.type == dataType {
                results.append(packet)
            }
        }
        return results
    }
    
    func after(dataTimestamp: Date) -> [APRSPacket] {
        var results = [APRSPacket]()
        for packet in self {
            if packet.data?.timestamp != nil {
                if packet.data!.timestamp! >= dataTimestamp {
                    results.append(packet)
                }
            }
        }
        return results
    }
    
    func before(dataTimestamp: Date) -> [APRSPacket] {
        var results = [APRSPacket]()
        for packet in self {
            if packet.data?.timestamp != nil {
                if packet.data!.timestamp! < dataTimestamp {
                    results.append(packet)
                }
            }
        }
        return results
    }
    
    func near(location: CLLocation, withRadius: CLLocationAccuracy) -> [APRSPacket] {
        var results = [APRSPacket]()
        for packet in self {
            if packet.data?.location != nil {
                let packetLocation = packet.data!.location!
                let distance = packetLocation.distance(from: location)
                if (CLLocationAccuracy(distance) < withRadius) {
                    results.append(packet)
                }
            }
        }
        return results
    }
}
