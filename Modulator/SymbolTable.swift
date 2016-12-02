//
//  SymbolTable.swift
//  FreeAPRS
//
//  Created by James on 11/30/16.
//  Copyright © 2016 dimnsionofsound. All rights reserved.
//

import Foundation

//let SSIDSymbols : [Int : Symbols]

enum Symbols : String {
    case policeSheriff = "Police/Sheriff"
    case digiGreenStarWhiteCenter = "DIGI (Green Star, White Center)"
    case phone = "Phone"
    case dxCluser = "DX Cluster"
    case hfGateway = "HF Gateway"
    case smallAircraft = "Small Aircraft"
    case mobileSatelliteGroundStation = "Mobile Satellite Ground Station"
    case snowmobile = "Snowmobile"
    case redCross = "Red Cross"
    case boyScouts = "Boy Scouts"
    case house = "House"
    case x = "X"
    case dot = "Dot"
    case numeralCircle0 = "0"
    case numeralCircle1 = "1"
    case numeralCircle2 = "2"
    case numeralCircle3 = "3"
    case numeralCircle4 = "4"
    case numeralCircle5 = "5"
    case numeralCircle6 = "6"
    case numeralCircle7 = "7"
    case numeralCircle8 = "8"
    case numeralCircle9 = "9"
    case fire = "Fire"
    case campground = "Campground"
    case motorcycle = "Motorcyle"
    case railroadEngine = "RailroadEngine"
    case car = "Car"
    case fileServer = "File Server"
    case hurricaneFuturePrediction = "Hurricane Future Prediction"
    case aidStation = "Aid Station"
    case bbs = "BBS"
    case canoe = "Canoe"
    case eyeball = "Eyeball"
    case gridSquare = "Grid Square"
    case hotel = "Hotel"
    case tcpip = "TCP-IP"
    case school = "School"
    case macAPRS = "MacAPRS"
    case ntsStation = "NTS Station"
    case balloon = "Balloon"
    case police = "Police"
    case recreationalVehicle = "Recreational Vehicle"
    case spaceShuttle = "Space Shuttle"
    case sstv = "SSTV"
    case bus = "Bus"
    case atv = "ATV"
    case nationalWeatherServiceSite = "National Weather Service Site"
    case helicopter = "Helicopter"
    case yacht = "Yacht"
    case winAPRS = "WinAPRS"
    case jogger = "Jogger"
    case triangleDF = "Triangle (DF)"
    case pbbs = "PBBS"
    case largeAircraft = "Large Aircraft"
    case weatherStation = "Weather Station"
    case dishAntenna = "Dish Antenna"
    case ambulance = "Ambulance"
    case bicycle = "Bicycle"
    case dualGarageFireDepartment = "Dual Guarage Fire Department"
    case horse = "Horse"
    case fireTruck = "Fire Truck"
    case glider = "Glider"
    case hospital = "Hospital"
    case islandOnTheAir = "Island on the Air"
    case jeep = "Jeep"
    case truck = "Truck"
    case micRepeater = "Mic Repeater"
    case node = "Node"
    case emergencyOpertionsCenter = "Emergency Operations Center"
    case roverDog = "Rover Dog"
    case gridSquareAbove128Miles = "Grid Square Above 128 Miles"
    case antenna = "Antenna"
    case ship = "Ship"
    case truckStop = "Truck Stop"
    case semiTruck = "Semi Truck"
    case van = "Van"
    case waterStation = "Water Station"
    case xAPRS = "X-APRS"
    case yagiAtQTH = "Yagi at QTH"
    case emergency = "Emergency"
    case digiGreenStarWithOverlay = "Digi (Green Star) - "
    case bankATM = "Bank (ATM)"
    case hfGatewayDiamondWithOverlay = "HF Gateway (Diamond) - "
    case crashSite = "Crash Site"
    case cloudy = "Cloudy"
    case snow = "Snow"
    case church = "Church"
    case girlScouts = "Girl Scouts"
    case houseHF = "House (HF)"
    case unknownPosition = "UnknownPosition"
    case circleWithOverlay = "Circle - "
    case gasStation = "Gas Station"
    case hail = "Hail"
    case park = "Park"
    case nwsAdivsoryGail = "NWS Advisory - Gail"
    case carWithOverlay = "Car - "
    case informationKiosk = "Information Kiosk"
    case hurricane = "Hurricane"
    case boxWithOverlay = "Box - "
    case blowingSnow = "Blowing Snow"
    case coastGuard = "Coast Guard"
    case drizzle = "Drizzle"
    case smoke = "Smoke"
    case freezingRain = "Freezing Rain"
    case snowShower = "Snow Shower"
    case haze = "Haze"
    case rainShower = "Rain Shower"
    case lightning = "Lightning"
    case kenwood = "Kenwood"
    case lighthouse = "Lighthouse"
    case navigationBuoy = "Navigation Buoy"
    case parking = "Parking"
    case earthquake = "Earthquake"
    case restaurant = "Restaurant"
    case satellitePACSat = "Satellite/PACSat"
    case thunderstorm = "Thunderstorm"
    case sunny = "Sunny"
    case vortacNavAid = "VORTAC Nav Aid"
    case nwsSiteWithOverlay = "NWS Site - "
    case pharmacyRx = "Pharmacy RX"
    case wallCloud = "Wall Cloud"
    case aircraftWithOverlay = "Aircraft - "
    case weatherStationWithGreenDigiWithOverlay = "Weather Station with Green Digi - "
    case rain = "Rain"
    case letterOverlay = "- "
    case blowingDust = "Blowing Dust"
    case civilDefenseRACESWithOverlay = "Civil Defense (RACES) - "
    case dxSpot = "DX Spot"
    case sleet = "Sleet"
    case funnelCloud = "Funnel Cloud"
    case galeFlags = "Gale Flags"
    case hamStore = "Ham Store"
    case indoorShortRangeDigiWithOverlay = "Indoor Short Range Digi - "
    case workZoneSteamShovel = "Work Zone (Steam Shovel)"
    case areaSymbols = "Area Symbols"
    case valueSignpostWith3CharacterDisplay = "Value Signpost - "
    case triangleWithOverlay = "Triangle - "
    case smallCircle = "Small Circle"
    case partlyCloudy = "Partly Cloudy"
    case restrooms = "Restrooms"
    case shipTopViewWithOverlay = "Ship (Top View) - "
    case tornado = "Tornado"
    case truckWithOverlay = "Truck - "
    case vanWithOverlay = "Van - "
    case flooding = "Flooding"
    case fog = "Fog"
}

let overlaySymbols : [Symbols] = [
.digiGreenStarWithOverlay,
.hfGatewayDiamondWithOverlay,
.carWithOverlay,
.boxWithOverlay,
.nwsSiteWithOverlay,
.aircraftWithOverlay,
.weatherStationWithGreenDigiWithOverlay,
.civilDefenseRACESWithOverlay,
.indoorShortRangeDigiWithOverlay,
.triangleWithOverlay,
.shipTopViewWithOverlay,
.truckWithOverlay,
.vanWithOverlay
]

let primarySymbolTable : [String : Symbols] = [
    "!" : .policeSheriff,
    "#" : .digiGreenStarWhiteCenter,
    "$" : .phone,
    "%" : .dxCluser,
    "&" : .hfGateway,
    "'" : .smallAircraft,
    "(" : .mobileSatelliteGroundStation,
    "*" : .snowmobile,
    "+" : .redCross,
    "," : .boyScouts,
    "-" : .house,
    "." : .x,
    "/" : .dot,
    "0" : .numeralCircle0,
    "1" : .numeralCircle1,
    "2" : .numeralCircle2,
    "3" : .numeralCircle3,
    "4" : .numeralCircle4,
    "5" : .numeralCircle5,
    "6" : .numeralCircle6,
    "7" : .numeralCircle7,
    "8" : .numeralCircle8,
    "9" : .numeralCircle9,
    ":" : .fire,
    ";" : .campground,
    "<" : .motorcycle,
    "=" : .railroadEngine,
    ">" : .car,
    "?" : .fileServer,
    "@" : .hurricaneFuturePrediction,
    "A" : .aidStation,
    "B" : .bbs,
    "C" : .canoe,
    "E" : .eyeball,
    "G" : .gridSquare,
    "H" : .hotel,
    "I" : .tcpip,
    "K" : .school,
    "M" : .macAPRS,
    "N" : .ntsStation,
    "O" : .balloon,
    "P" : .police,
    "R" : .recreationalVehicle,
    "S" : .spaceShuttle,
    "T" : .sstv,
    "U" : .bus,
    "V" : .atv,
    "W" : .nationalWeatherServiceSite,
    "X" : .helicopter,
    "Y" : .yacht,
    "Z" : .winAPRS,
    "[" : .jogger,
    "\\" : .triangleDF,
    "]" : .pbbs,
    "^" : .largeAircraft,
    "_" : .weatherStation,
    "`" : .dishAntenna,
    "a" : .ambulance,
    "b" : .bicycle,
    "d" : .dualGarageFireDepartment,
    "e" : .horse,
    "f" : .fireTruck,
    "g" : .glider,
    "h" : .hospital,
    "i" : .islandOnTheAir,
    "j" : .jeep,
    "k" : .truck,
    "m" : .micRepeater,
    "n" : .node,
    "o" : .emergencyOpertionsCenter,
    "p" : .roverDog,
    "q" : .gridSquareAbove128Miles,
    "r" : .antenna,
    "s" : .ship,
    "t" : .truckStop,
    "u" : .semiTruck,
    "v" : .van,
    "w" : .waterStation,
    "x" : .xAPRS,
    "y" : .yagiAtQTH,
    ]

let secondarySymbolTable : [String : Symbols] = [
    "!" : .emergency,
    "#" : .digiGreenStarWithOverlay,
    "$" : .bankATM,
    "&" : .hfGatewayDiamondWithOverlay,
    "'" : .crashSite,
    "(" : .cloudy,
    "*" : .snow,
    "+" : .church,
    "," : .girlScouts,
    "-" : .houseHF,
    "." : .unknownPosition,
    "0" : .circleWithOverlay,
    "9" : .gasStation,
    ":" : .hail,
    ";" : .park,
    "<" : .nwsAdivsoryGail,
    ">" : .carWithOverlay,
    "?" : .informationKiosk,
    "@" : .hurricane,
    "A" : .boxWithOverlay,
    "B" : .blowingSnow,
    "C" : .coastGuard,
    "D" : .drizzle,
    "E" : .smoke,
    "F" : .freezingRain,
    "G" : .snowShower,
    "H" : .haze,
    "I" : .rainShower,
    "J" : .lightning,
    "K" : .kenwood,
    "L" : .lighthouse,
    "N" : .navigationBuoy,
    "P" : .parking,
    "Q" : .earthquake,
    "R" : .restaurant,
    "S" : .satellitePACSat,
    "T" : .thunderstorm,
    "U" : .sunny,
    "V" : .vortacNavAid,
    "W" : .nwsSiteWithOverlay,
    "X" : .pharmacyRx,
    "[" : .wallCloud,
    "^" : .aircraftWithOverlay,
    "_" : .weatherStationWithGreenDigiWithOverlay,
    "`" : .rain,
    "a" : .letterOverlay,
    "b" : .blowingDust,
    "c" : .civilDefenseRACESWithOverlay,
    "d" : .dxSpot,
    "e" : .sleet,
    "f" : .funnelCloud,
    "g" : .galeFlags,
    "h" : .hamStore,
    "i" : .indoorShortRangeDigiWithOverlay,
    "j" : .workZoneSteamShovel,
    "l" : .areaSymbols,
    "m" : .valueSignpostWith3CharacterDisplay,
    "n" : .triangleWithOverlay,
    "o" : .smallCircle,
    "p" : .partlyCloudy,
    "r" : .restrooms,
    "s" : .shipTopViewWithOverlay,
    "t" : .tornado,
    "u" : .truckWithOverlay,
    "v" : .vanWithOverlay,
    "w" : .flooding,
    "{" : .fog,
]

let symbolTableGPSxyz : [String : Symbols] = [
    "BB" : .policeSheriff,
    "BD" : .digiGreenStarWhiteCenter,
    "BE" : .phone,
    "BF" : .dxCluser,
    "BG" : .hfGateway,
    "BH" : .smallAircraft,
    "BI" : .mobileSatelliteGroundStation,
    "BK" : .snowmobile,
    "BL" : .redCross,
    "BM" : .boyScouts,
    "BN" : .house,
    "BO" : .x,
    "BP" : .dot,
    "P0" : .numeralCircle0,
    "P1" : .numeralCircle1,
    "P2" : .numeralCircle2,
    "P3" : .numeralCircle3,
    "P4" : .numeralCircle4,
    "P5" : .numeralCircle5,
    "P6" : .numeralCircle6,
    "P7" : .numeralCircle7,
    "P8" : .numeralCircle8,
    "P9" : .numeralCircle9,
    "MR" : .fire,
    "MS" : .campground,
    "MT" : .motorcycle,
    "MU" : .railroadEngine,
    "MV" : .car,
    "MW" : .fileServer,
    "MX" : .hurricaneFuturePrediction,
    "PA" : .aidStation,
    "PB" : .bbs,
    "PC" : .canoe,
    "PE" : .eyeball,
    "PG" : .gridSquare,
    "PH" : .hotel,
    "PI" : .tcpip,
    "PK" : .school,
    "PM" : .macAPRS,
    "PN" : .ntsStation,
    "PO" : .balloon,
    "PP" : .police,
    "PR" : .recreationalVehicle,
    "PS" : .spaceShuttle,
    "PT" : .sstv,
    "PU" : .bus,
    "PV" : .atv,
    "PS" : .nationalWeatherServiceSite,
    "PX" : .helicopter,
    "PY" : .yacht,
    "PZ" : .winAPRS,
    "HS" : .jogger,
    "HT" : .triangleDF,
    "HU" : .pbbs,
    "HV" : .largeAircraft,
    "HW" : .weatherStation,
    "HX" : .dishAntenna,
    "LA" : .ambulance,
    "LB" : .bicycle,
    "LD" : .dualGarageFireDepartment,
    "LE" : .horse,
    "LF" : .fireTruck,
    "LG" : .glider,
    "LH" : .hospital,
    "LI" : .islandOnTheAir,
    "LJ" : .jeep,
    "LK" : .truck,
    "LM" : .micRepeater,
    "LN" : .node,
    "LO" : .emergencyOpertionsCenter,
    "LP" : .roverDog,
    "LQ" : .gridSquareAbove128Miles,
    "LR" : .antenna,
    "LS" : .ship,
    "LT" : .truckStop,
    "LU" : .semiTruck,
    "LV" : .van,
    "LW" : .waterStation,
    "LX" : .xAPRS,
    "LY" : .yagiAtQTH,

    "OB" : .emergency,
    "OD" : .digiGreenStarWithOverlay,
    "OE" : .bankATM,
    "OG" : .hfGatewayDiamondWithOverlay,
    "OH" : .crashSite,
    "OI" : .cloudy,
    "OK" : .snow,
    "OL" : .church,
    "OM" : .girlScouts,
    "ON" : .houseHF,
    "OO" : .unknownPosition,
    "A0" : .circleWithOverlay,
    "A9" : .gasStation,
    "NR" : .hail,
    "NS" : .park,
    "NT" : .nwsAdivsoryGail,
    "NV" : .carWithOverlay,
    "NW" : .informationKiosk,
    "NX" : .hurricane,
    "AA" : .boxWithOverlay,
    "AB" : .blowingSnow,
    "AC" : .coastGuard,
    "AD" : .drizzle,
    "AE" : .smoke,
    "AF" : .freezingRain,
    "AG" : .snowShower,
    "AH" : .haze,
    "AI" : .rainShower,
    "AJ" : .lightning,
    "AK" : .kenwood,
    "AL" : .lighthouse,
    "AN" : .navigationBuoy,
    "AP" : .parking,
    "AQ" : .earthquake,
    "AR" : .restaurant,
    "AS" : .satellitePACSat,
    "AT" : .thunderstorm,
    "AU" : .sunny,
    "AV" : .vortacNavAid,
    "AW" : .nwsSiteWithOverlay,
    "AX" : .pharmacyRx,
    "DS" : .wallCloud,
    "DV" : .aircraftWithOverlay,
    "DW" : .weatherStationWithGreenDigiWithOverlay,
    "DX" : .rain,
    "SA" : .letterOverlay,
    "SB" : .blowingDust,
    "SC" : .civilDefenseRACESWithOverlay,
    "SD" : .dxSpot,
    "SE" : .sleet,
    "SF" : .funnelCloud,
    "SG" : .galeFlags,
    "SH" : .hamStore,
    "SI" : .indoorShortRangeDigiWithOverlay,
    "SJ" : .workZoneSteamShovel,
    "SL" : .areaSymbols,
    "SM" : .valueSignpostWith3CharacterDisplay,
    "SN" : .triangleWithOverlay,
    "SO" : .smallCircle,
    "SP" : .partlyCloudy,
    "SR" : .restrooms,
    "SS" : .shipTopViewWithOverlay,
    "ST" : .tornado,
    "SU" : .truckWithOverlay,
    "SV" : .vanWithOverlay,
    "SW" : .flooding,
    "Q1" : .fog,
    
]

let symbolTableGPSCnn : [String : Symbols] = [
    "01" : .policeSheriff,
    "03" : .digiGreenStarWhiteCenter,
    "04" : .phone,
    "05" : .dxCluser,
    "06" : .hfGateway,
    "07" : .smallAircraft,
    "08" : .mobileSatelliteGroundStation,
    "10" : .snowmobile,
    "11" : .redCross,
    "12" : .boyScouts,
    "13" : .house,
    "14" : .x,
    "15" : .dot,
    "16" : .numeralCircle0,
    "17" : .numeralCircle1,
    "18" : .numeralCircle2,
    "19" : .numeralCircle3,
    "20" : .numeralCircle4,
    "21" : .numeralCircle5,
    "22" : .numeralCircle6,
    "23" : .numeralCircle7,
    "24" : .numeralCircle8,
    "25" : .numeralCircle9,
    "26" : .fire,
    "27" : .campground,
    "28" : .motorcycle,
    "29" : .railroadEngine,
    "30" : .car,
    "31" : .fileServer,
    "32" : .hurricaneFuturePrediction,
    "33" : .aidStation,
    "34" : .bbs,
    "35" : .canoe,
    "37" : .eyeball,
    "39" : .gridSquare,
    "40" : .hotel,
    "41" : .tcpip,
    "43" : .school,
    "45" : .macAPRS,
    "46" : .ntsStation,
    "47" : .balloon,
    "48" : .police,
    "50" : .recreationalVehicle,
    "51" : .spaceShuttle,
    "52" : .sstv,
    "53" : .bus,
    "54" : .atv,
    "55" : .nationalWeatherServiceSite,
    "56" : .helicopter,
    "57" : .yacht,
    "58" : .winAPRS,
    "59" : .jogger,
    "60" : .triangleDF,
    "61" : .pbbs,
    "62" : .largeAircraft,
    "63" : .weatherStation,
    "64" : .dishAntenna,
    "65" : .ambulance,
    "66" : .bicycle,
    "68" : .dualGarageFireDepartment,
    "69" : .horse,
    "70" : .fireTruck,
    "71" : .glider,
    "72" : .hospital,
    "73" : .islandOnTheAir,
    "74" : .jeep,
    "75" : .truck,
    "77" : .micRepeater,
    "78" : .node,
    "79" : .emergencyOpertionsCenter,
    "80" : .roverDog,
    "81" : .gridSquareAbove128Miles,
    "82" : .antenna,
    "83" : .ship,
    "84" : .truckStop,
    "85" : .semiTruck,
    "86" : .van,
    "87" : .waterStation,
    "88" : .xAPRS,
    "89" : .yagiAtQTH,
]

let symbolTableGPSEnn : [String : Symbols] = [
    "01" : .emergency,
    "03" : .digiGreenStarWithOverlay,
    "04" : .bankATM,
    "06" : .hfGatewayDiamondWithOverlay,
    "07" : .crashSite,
    "08" : .cloudy,
    "10" : .snow,
    "11" : .church,
    "12" : .girlScouts,
    "13" : .houseHF,
    "14" : .unknownPosition,
    "16" : .circleWithOverlay,
    "25" : .gasStation,
    "26" : .hail,
    "27" : .park,
    "28" : .nwsAdivsoryGail,
    "30" : .carWithOverlay,
    "31" : .informationKiosk,
    "32" : .hurricane,
    "33" : .boxWithOverlay,
    "34" : .blowingSnow,
    "35" : .coastGuard,
    "36" : .drizzle,
    "37" : .smoke,
    "38" : .freezingRain,
    "39" : .snowShower,
    "40" : .haze,
    "41" : .rainShower,
    "42" : .lightning,
    "43" : .kenwood,
    "44" : .lighthouse,
    "46" : .navigationBuoy,
    "48" : .parking,
    "49" : .earthquake,
    "50" : .restaurant,
    "51" : .satellitePACSat,
    "52" : .thunderstorm,
    "53" : .sunny,
    "54" : .vortacNavAid,
    "55" : .nwsSiteWithOverlay,
    "56" : .pharmacyRx,
    "59" : .wallCloud,
    "62" : .aircraftWithOverlay,
    "63" : .weatherStationWithGreenDigiWithOverlay,
    "64" : .rain,
    "65" : .letterOverlay,
    "66" : .blowingDust,
    "67" : .civilDefenseRACESWithOverlay,
    "68" : .dxSpot,
    "69" : .sleet,
    "70" : .funnelCloud,
    "71" : .galeFlags,
    "72" : .hamStore,
    "73" : .indoorShortRangeDigiWithOverlay,
    "74" : .workZoneSteamShovel,
    "76" : .areaSymbols,
    "77" : .valueSignpostWith3CharacterDisplay,
    "78" : .triangleWithOverlay,
    "79" : .smallCircle,
    "80" : .partlyCloudy,
    "82" : .restrooms,
    "83" : .shipTopViewWithOverlay,
    "84" : .tornado,
    "85" : .truckWithOverlay,
    "86" : .vanWithOverlay,
    "87" : .flooding,
    "91" : .fog,
]
