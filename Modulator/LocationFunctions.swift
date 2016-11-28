//
//  LocationFunctions.swift
//  FreeAPRS
//
//  Created by James on 11/27/16.
//  Copyright © 2016 dimnsionofsound. All rights reserved.
//

import Foundation

import CoreLocation


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
    case Hundredths
    case Tenths
    case Ones
    case Tens
    case DegreeOnes
    case DegreeTens
}
/* Implemented as a lookup table in the interest of speed/efficiency. 
 CLLocationAccuracy is a Double*/
func metersError(forImpreciseDigit: PositionDigit) -> CLLocationAccuracy {
    switch forImpreciseDigit {
    case .Hundredths:
        return 1.0
    case .Tenths:
        return 1.0
    case .Ones:
        return 1.0
    case .Tens:
        return 1.0
    case .DegreeOnes:
        return 1.0
    case .DegreeTens:
        return 1.0
    }
}

func indexOfFirstSpace(in input: String) {
    
}

func location(fromStandard: String) -> CLLocation? {
    let length = fromStandard.utf8.count
    
    if (length < 19) { return nil }
    
    return nil
}

