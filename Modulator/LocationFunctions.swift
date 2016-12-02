//
//  LocationFunctions.swift
//  FreeAPRS
//
//  Created by James on 11/27/16.
//  Copyright © 2016 dimnsionofsound. All rights reserved.
//

import Foundation

import CoreLocation

extension String {
    subscript(i: Int) -> String {
        guard i >= 0 && i < characters.count else { return "" }
        return String(self[index(startIndex, offsetBy: i)])
    }
    subscript(range: Range<Int>) -> String {
        let lowerIndex = index(startIndex, offsetBy: max(0,range.lowerBound), limitedBy: endIndex) ?? endIndex
        return substring(with: lowerIndex..<(index(lowerIndex, offsetBy: range.upperBound - range.lowerBound, limitedBy: endIndex) ?? endIndex))
    }
    subscript(range: ClosedRange<Int>) -> String {
        let lowerIndex = index(startIndex, offsetBy: max(0,range.lowerBound), limitedBy: endIndex) ?? endIndex
        return substring(with: lowerIndex..<(index(lowerIndex, offsetBy: range.upperBound - range.lowerBound + 1, limitedBy: endIndex) ?? endIndex))
    }
}



/* Parses standard APRS positon strings.
 
 - Standard APRS position format, 19 characters long:
    Latitude    Longitude
    ddmm.hh{N|S}Idddmm.hh{E|W}C
 
    where d represents degrees, m minutes, and h as hundredths of a minute
    I is the symbol table identifier and C is the symbol code.
 
    Imprecision is conveyed by spaces in the latitude field representing
    indeterminate digits, with numerals being replaced by spaces starting
    from the right (hundredths) and successively moving left with increased
    imprecision.
 
*/
func numSpaces(in input: String) -> Int {
    var counter = 0
    let space = UTF8.CodeUnit(ascii: " ")
    
    for char in input.utf8 {
        if char == space {
            counter += 1
        }
    }
    
    return counter
}

enum PositionDigit {
    case thousandths
    case hundredths
    case tenths
    case ones
    case tens
    case degreeOnes
    case degreeTens
}

/* Implemented as a lookup table in the interest of speed/efficiency. Radius of the circle that is circumscribed
    by the bounding box caused by varying the imprecise digit(s)
    to their maximum and minimum values.
 CLLocationAccuracy is a Double, representing meters.*/
func metersError(forImpreciseDigit: PositionDigit) -> CLLocationAccuracy {
    switch forImpreciseDigit {
    case .thousandths:
        return 9.26
    case .hundredths:
        return 92.6
    case .tenths:
        return 926.0
    case .ones:
        return 9260.0
    case .tens:
        return 55600.0
    case .degreeOnes:
        return 556000.0
    case .degreeTens:
        return 5560000.0
    }
}


func location(fromStandard: String, atTime: Date? = nil)  -> CLLocation? {
    let length = fromStandard.utf8.count
    
    if (length < 19) { return nil }
    
    let latitude = fromStandard[Range<Int>(uncheckedBounds: (0, 8))]
    
    let longitude = fromStandard[Range<Int>(uncheckedBounds: (9, 18))]
    
    /* Create an int for each digit. Spaces should become either zeros or half their possible value. For example,
        30__.__ should become 3030.00
        3021.__ should become 3021.50
    */
    
    var lastReplaced : PositionDigit = .thousandths
    
    let latitudeNS = latitude[7]
    let longitudeEW = longitude[8]
    
    if (!(latitudeNS == "N" || latitudeNS == "S")) {
        return nil
    }
    
    if (!(longitudeEW == "E" || latitudeNS == "W")) {
        return nil
    }
    
    var latitudeHundredths = latitude[6]
    var longitudeHundredths = longitude[7]
    
    if (latitudeHundredths == " ") {
        latitudeHundredths = "0"
        longitudeHundredths = "0"
        lastReplaced = PositionDigit.hundredths
    }
    
    var latitudeTenths = latitude[5]
    var longitudeTenths = longitude[6]
    
    if (latitudeTenths == " ") {
        latitudeTenths = "0"
        longitudeTenths = "0"
        lastReplaced = PositionDigit.tenths
    }
    
    var latitudeOnes = latitude[3]
    var longitudeOnes = longitude[4]
    
    if (latitudeOnes == " ") {
        latitudeOnes = "0"
        longitudeOnes = "0"
        lastReplaced = PositionDigit.ones
    }
    
    var latitudeTens = latitude[2]
    var longitudeTens = longitude[3]
    
    if (latitudeTens == " ") {
        latitudeTens = "0"
        longitudeTens = "0"
        lastReplaced = PositionDigit.tens
    }
    
    var latitudeDegreeOnes = latitude[1]
    var longitudeDegreeOnes = longitude[2]
    
    if (latitudeDegreeOnes == " ") {
        latitudeDegreeOnes = "0"
        longitudeDegreeOnes = "0"
        lastReplaced = PositionDigit.degreeOnes
    }
    
    var latitudeDegreeTens = latitude[0]
    var longitudeDegreeTens = longitude[1]
    
    if (latitudeDegreeTens == " ") {
        latitudeDegreeTens = "0"
        longitudeDegreeTens = "0"
        lastReplaced = PositionDigit.degreeTens
    }
    
    let longitudeDegreeHundreds = longitude[0]
    
    let horizontalAccuracy = metersError(forImpreciseDigit: lastReplaced)
    
    switch lastReplaced {
    case .degreeTens:
        latitudeDegreeTens = "5"
        longitudeDegreeTens = "5"
        break
    case .degreeOnes:
        latitudeDegreeOnes = "5"
        longitudeDegreeOnes = "5"
        break
    case .tens:
        // Minutes only go up to 60
        latitudeTens = "3"
        longitudeTens = "3"
        break
    case .ones:
        latitudeOnes = "5"
        longitudeOnes = "5"
        break
    case .tenths:
        latitudeTenths = "5"
        longitudeTenths = "5"
        break
    case .hundredths:
        latitudeHundredths = "5"
        longitudeHundredths = "5"
        break
    case .thousandths:
        break
    }
    
    /* Now after dealing with all of that we can FINALLY put the strings back together and parse them. */
    
    let latitudeMinutesString = "0." + latitudeTens + latitudeOnes + latitudeTenths + latitudeHundredths
    
    let latitudeDegreesString = latitudeDegreeTens + latitudeDegreeOnes
    
    guard let latitudeDegrees = Double(latitudeDegreesString) else {
        return nil
    }
    
    guard var latitudeMinutes = Double(latitudeMinutesString) else {
        return nil
    }
    
    latitudeMinutes *= (10.0/6.0)
    
    let decimalLatitude = (latitudeDegrees + latitudeMinutes) *
        (latitudeNS == "N" ? 1 : -1)
    
    /* Longitude */
    
    let longitudeMinutesString = "0." + longitudeTens + longitudeOnes + longitudeTenths + longitudeHundredths
    
    let longitudeDegreesString = longitudeDegreeHundreds + longitudeDegreeTens + longitudeDegreeOnes
    
    guard let longitudeDegrees = Double(longitudeDegreesString) else {
        return nil
    }
    
    guard var longitudeMinutes = Double(longitudeMinutesString) else {
        return nil
    }
    
    longitudeMinutes *= (10.0/6.0)
    
    let decimalLongitude = (longitudeDegrees + longitudeMinutes) *
        (longitudeEW == "E" ? 1 : -1)
    
    /* Make Location */
    
    let locationCoordinate = CLLocationCoordinate2DMake(decimalLatitude, decimalLongitude)
    
    if (!CLLocationCoordinate2DIsValid(locationCoordinate)) {
        return nil
    }
    
    let timestamp = atTime ?? Date(timeIntervalSinceNow: 0.0)
    
    let location = CLLocation(coordinate: locationCoordinate, altitude: 0, horizontalAccuracy: horizontalAccuracy, verticalAccuracy: -1, timestamp: timestamp)
    
    return location
}

