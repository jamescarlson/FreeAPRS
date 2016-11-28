//
//  DateFunctions.swift
//  FreeAPRS
//
//  Created by James on 11/27/16.
//  Copyright © 2016 dimnsionofsound. All rights reserved.
//

import Foundation

/* Parses an APRS timestamp in the form of ddHHmm\{z|/}, HHmmss\h or  MMHHmmss.
 Behavior undefined for date component values exceeding limits. */
func timestamp(from: String) -> Date? {
    let timestampLength = from.utf8.count
    
    guard let index = from.index(from.startIndex, offsetBy: 6, limitedBy: from.endIndex) else {
        return nil
    }
    
    let seventhChar = from[index]
    
    let now = Date(timeIntervalSinceNow: 0)
    
    /* Do validation after the ifs. */
    var outputCalendar : Calendar = Calendar.current
    let outputYear : Int = outputCalendar.component(.year, from: now)
    var outputMonth : Int = outputCalendar.component(.month, from: now)
    var outputDayOfMonth : Int = outputCalendar.component(.day, from: now)
    var outputHours : Int = outputCalendar.component(.hour, from: now)
    var outputMinutes : Int = outputCalendar.component(.minute, from: now)
    var outputSeconds : Int = outputCalendar.component(.second, from: now)
    var outputTimeZone : TimeZone = outputCalendar.timeZone
    
    guard let firstTwo = Int(from[from.startIndex..<from.index(from.startIndex, offsetBy: 2)]) else {
        return nil
    }
    
    guard let secondTwo = Int(from[from.index(from.startIndex, offsetBy: 2)..<from.index(from.startIndex, offsetBy: 4)]) else {
        return nil
    }
    
    guard let thirdTwo = Int(from[from.index(from.startIndex, offsetBy: 4)..<from.index(from.startIndex, offsetBy: 6)]) else {
        return nil
    }
    
    if (seventhChar == Character("z")) {
        // DDHHMM zulu
        outputDayOfMonth = firstTwo
        outputHours = secondTwo
        outputMinutes = thirdTwo
        outputTimeZone = TimeZone(secondsFromGMT: 0)!
        
    } else if (seventhChar == Character("/")) {
        // DDHHMM local time (deprecated - "[not] recommended"
        
        outputDayOfMonth = firstTwo
        outputHours = secondTwo
        outputMinutes = thirdTwo
        
    } else if (seventhChar == Character("h")) {
        // HHMMSS - local (not allowed in status reports)
        
        outputHours = firstTwo
        outputMinutes = secondTwo
        outputSeconds = thirdTwo
        
    } else if ("0"..."9" ~= seventhChar) {
        // If the 7th character is a number then this is MMDDHHMM. timestamp must be 8 characters long if so.
        if timestampLength < 8 { return nil }
        
        outputMonth = firstTwo
        outputDayOfMonth = secondTwo
        outputHours = thirdTwo
        guard let tempOoutputMinutes = Int(from[from.index(from.startIndex, offsetBy: 6)..<from.index(from.startIndex, offsetBy: 8)]) else {
            return nil
        }
        outputMinutes = tempOoutputMinutes
        outputTimeZone = TimeZone(secondsFromGMT: 0)!
        
    } else {
        //Unparseable timestamp
        return nil
    }
    
    let outputDateComponents = DateComponents(calendar: outputCalendar, timeZone: outputTimeZone, era: nil, year: outputYear, month: outputMonth, day: outputDayOfMonth, hour: outputHours, minute: outputMinutes, second: outputSeconds, nanosecond: nil, weekday: nil, weekdayOrdinal: nil, quarter: nil, weekOfMonth: nil, weekOfYear: nil, yearForWeekOfYear: nil)
    
    guard let outputDate = outputCalendar.date(from: outputDateComponents) else {
        return nil
    }
    
    return outputDate
}
