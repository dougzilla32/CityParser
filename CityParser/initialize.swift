//
//  intialize.swift
//  
//
//  Created by Doug on 2/3/22.
//

import Foundation
import System
import os
import SwiftCSV

var worldCities = [City]()

enum CityError: Error {
    case resourceNotFound(String)
    case invalidLatitude(String, [String], Int)
    case invalidLongitude(String, [String], Int)
    case invalidCapitol(String, [String], Int)
    case invalidPopulation(String, [String], Int)
}

private struct SearchIndex {
    let value: Substring
    let start: Int
}

public func initialize(logger: Logger) async throws {
    logger.info("Initializing...")
    
    try readWorldCities(logger)
    try readUSZipCodes(logger)
    
    worldCities.sort { (cityA: City, cityB: City) -> Bool in
        let valueA: String
        if cityA.zipCode != "" {
            valueA = cityA.zipCode
        } else {
            valueA = cityA.searchName
        }
        
        let valueB: String
        if cityB.zipCode != "" {
            valueB = cityB.zipCode
        } else {
            valueB = cityB.searchName
        }

        return valueA < valueB
    }
    
    logger.info("EXPORT Cities")

    let bytes = try BinaryEncoder.encode(
        WorldCitiesList(cities: worldCities)
    )
    let CityParserFolder = FilePath(#file).removingLastComponent().removingLastComponent()
    let CityDataFile = "\(CityParserFolder)/WorldCities.data"
    try Data(bytes).write(to: URL(fileURLWithPath: CityDataFile))

    logger.info("DONE Initializing")
}

private enum WorldCities: Int {
    case city = 0, city_ascii, lat, lng, country, iso2, iso3, admin_name, capitol, population, id
}

private let stateAbbreviationsList = [
    [ "Alabama",        "AL",    "Ala." ],
    [ "Alaska",         "AK",    "Alaska" ],
    [ "Arizona",        "AZ",    "Ariz." ],
    [ "Arkansas",       "AR",    "Ark." ],
    [ "California",     "CA",    "Calif." ],
    [ "Colorado",       "CO",    "Colo." ],
    [ "Connecticut",    "CT",    "Conn." ],
    [ "Delaware",       "DE",    "Del." ],
    [ "Florida",        "FL",    "Fla." ],
    [ "Georgia",        "GA",    "Ga." ],
    [ "Hawaii",         "HI",    "Hawaii" ],
    [ "Idaho",          "ID",    "Idaho" ],
    [ "Illinois",       "IL",    "Ill." ],
    [ "Indiana",        "IN",    "Ind." ],
    [ "Iowa",           "IA",    "Iowa" ],
    [ "Kansas",         "KS",    "Kans." ],
    [ "Kentucky",       "KY",    "Ky." ],
    [ "Louisiana",      "LA",    "La." ],
    [ "Maine",          "ME",    "Maine" ],
    [ "Maryland",       "MD",    "Md." ],
    [ "Massachusetts",  "MA",    "Mass." ],
    [ "Michigan",       "MI",    "Mich." ],
    [ "Minnesota",      "MN",    "Minn." ],
    [ "Mississippi",    "MS",    "Miss." ],
    [ "Missouri",       "MO",    "Mo." ],
    [ "Montana",        "MT",    "Mont." ],
    [ "Nebraska",       "NE",    "Nebr." ],
    [ "Nevada",         "NV",    "Nev." ],
    [ "New Hampshire",  "NH",    "N.H." ],
    [ "New Jersey",     "NJ",    "N.J." ],
    [ "New Mexico",     "NM",    "N.Mex." ],
    [ "New York",       "NY",    "N.Y." ],
    [ "North Carolina", "NC",    "N.C." ],
    [ "North Dakota",   "ND",    "N.Dak." ],
    [ "Ohio",           "OH",    "Ohio" ],
    [ "Oklahoma",       "OK",    "Okla." ],
    [ "Oregon",         "OR",    "Ore." ],
    [ "Pennsylvania",   "PA",    "Pa." ],
    [ "Rhode Island",   "RI",    "R.I." ],
    [ "South Carolina", "SC",    "S.C." ],
    [ "South Dakota",   "SD",    "S.Dak." ],
    [ "Tennessee",      "TN",    "Tenn." ],
    [ "Texas",          "TX",    "Tex." ],
    [ "Utah",           "UT",    "Utah" ],
    [ "Vermont",        "VT",    "Vt." ],
    [ "Virginia",       "VA",    "Va." ],
    [ "Washington",     "WA",    "Wash." ],
    [ "West Virginia",  "WV",    "W.Va." ],
    [ "Wisconsin",      "WI",    "Wisc."],
    [ "Wyoming",        "WY",    "Wyo." ],
    [ "District of Columbia", "DC", "D.C."]
]

private let stateIDs: [String: String] = {
    var d = [String: String]()
    for elem in stateAbbreviationsList {
        d[elem[0]] = elem[1]
    }
    return d
}()

private let stateAbbreviations: [String: String] = {
    var d = [String: String]()
    for elem in stateAbbreviationsList {
        d[elem[0]] = elem[2]
    }
    return d
}()

private func readWorldCities(_ logger: Logger) throws {
    let worldCitiesCSV = try CSV<Enumerated>(string: worldcitiesCSV, delimiter: .comma, loadColumns: false)
    
    logger.info("Reading World Cities...")
    
    var lineNumber = 1
    var errors = [CityError]()
    try worldCitiesCSV.enumerateAsArray(startAt: 1, rowLimit: nil) { line in
        let latitude = Double(line[WorldCities.lat.rawValue])
        let longitude = Double(line[WorldCities.lng.rawValue])
        let capitol = Capitol(rawValue: line[WorldCities.capitol.rawValue] == "" ? "none" : line[WorldCities.capitol.rawValue])
        
        let populationString = line[WorldCities.population.rawValue].components(separatedBy: ".")[0]
        let population = populationString == "" ? -1 : Int(populationString)
        
        if let latitude = latitude, let longitude = longitude, let capitol = capitol, let population = population {
            let appendCity = { searchName in
                worldCities.append(
                    City(
                        name: line[WorldCities.city.rawValue],
                        searchName: searchName,
                        zipCode: "",
                        latitude: latitude,
                        longitude: longitude,
                        country: line[WorldCities.country.rawValue],
                        iso2: line[WorldCities.iso2.rawValue],
                        iso3: line[WorldCities.iso3.rawValue],
                        adminName: line[WorldCities.admin_name.rawValue],
                        stateID: stateIDs[line[WorldCities.admin_name.rawValue]] ?? "",
                        stateAbbreviation: stateAbbreviations[line[WorldCities.admin_name.rawValue]] ?? "",
                        capitol: capitol,
                        population: population))
            }
            
            appendCity(line[WorldCities.city.rawValue].lowercased())
            
            if line[WorldCities.city.rawValue] != line[WorldCities.city_ascii.rawValue] {
                appendCity(line[WorldCities.city_ascii.rawValue].lowercased())
            }
        }
        else {
            if latitude == nil {
            errors.append(CityError.invalidLatitude(line[WorldCities.lat.rawValue], line, lineNumber))
            }
            if longitude == nil {
                errors.append(CityError.invalidLongitude(line[WorldCities.lng.rawValue], line, lineNumber))
            }
            if capitol == nil{
                errors.append(CityError.invalidLongitude(line[WorldCities.population.rawValue], line, lineNumber))
            }
            if population == nil {
                errors.append(CityError.invalidPopulation(line[WorldCities.population.rawValue], line, lineNumber))
            }
        }
        
        lineNumber += 1
        
        if lineNumber % 10000 == 0 {
            logger.info("\(lineNumber.withCommas) cities")
        }
    }
    
    if !errors.isEmpty {
        logger.error("World Cities PARSE ERROR(S):")
        for e in errors {
            logger.error("\(e)")
        }
        throw errors[0]
    }
    
    logger.info("DONE Reading \(lineNumber.withCommas) World Cities")
}

enum USZipCodes: Int {
    case zip = 0, lat, lng, city, state_id, state_name, zcta, parent_zcta, population, density, county_fips, county_name, county_weights, county_names_all, county_fips_all, imprecise, military, timezone
}
    
private func readUSZipCodes(_ logger: Logger) throws {
    let usZipsCSV = try CSV<Enumerated>(string: uszipsCSV, delimiter: .comma, loadColumns: false)
    
    logger.info("Reading US Zip Codes...")
    
    var lineNumber = 1
    var errors = [CityError]()
    try usZipsCSV.enumerateAsArray(startAt: 1, rowLimit: nil) { line in
        let latitude = Double(line[USZipCodes.lat.rawValue])
        let longitude = Double(line[USZipCodes.lng.rawValue])
        
        let populationString = line[USZipCodes.population.rawValue].components(separatedBy: ".")[0]
        let population = populationString == "" ? -1 : Int(populationString)
        
        if let latitude = latitude, let longitude = longitude, let population = population {
            worldCities.append(
                City(
                    name: line[USZipCodes.city.rawValue],
                    searchName: line[USZipCodes.city.rawValue].lowercased(),
                    zipCode: line[USZipCodes.zip.rawValue],
                    latitude: latitude,
                    longitude: longitude,
                    country: "United States",
                    iso2: "US",
                    iso3: "USA",
                    adminName: line[USZipCodes.state_name.rawValue],
                    stateID: line[USZipCodes.state_id.rawValue],
                    stateAbbreviation: stateAbbreviations[line[USZipCodes.state_name.rawValue]] ?? "",
                    capitol: .none,
                    population: population))
        }
        else {
            if latitude == nil {
                errors.append(CityError.invalidLatitude(line[USZipCodes.lat.rawValue], line, lineNumber))
            }
            if longitude == nil {
                errors.append(CityError.invalidLongitude(line[USZipCodes.lng.rawValue], line, lineNumber))
            }
            if population == nil {
                errors.append(CityError.invalidPopulation(line[USZipCodes.population.rawValue], line, lineNumber))
            }
        }
        
        lineNumber += 1
        
        if lineNumber % 10000 == 0 {
            logger.info("\(lineNumber.withCommas) zip codes")
        }
    }
    
    if !errors.isEmpty {
        logger.error("US Zip Codes PARSE ERROR(S):")
        for e in errors {
            logger.error("\(e)")
        }
        throw errors[0]
    }
    
    logger.info("DONE Reading \(lineNumber.withCommas) US Zip Codes")
}

//private func setupRedis(_ app: Application) async throws {
//    let initString = "**INITIALIZED V0**"
//    if let initialized = try await app.redis.get(RedisKey(initString), asJSON: String.self), initialized == initString {
//        return
//    }
//
//    try await createRedisAutocompleteTable(app.redis, logger: app.logger)
//    let saveTableResult = try await app.redis.send(command: "SAVE").get()
//    app.logger.info("Saved autocomplete table \(saveTableResult)")
//
//    try await app.redis.set(RedisKey(initString), toJSON: initString)
//    let saveInitKeyResult = try await app.redis.send(command: "SAVE").get()
//    app.logger.info("Saved initialization key \(saveInitKeyResult)")
//}
//
//private func createRedisAutocompleteTable(_ redis: Application.Redis, logger: Logger) async throws {
//    logger.info("Creating Autocomplete Table...")
//
//    var searchIndexArray = [SearchIndex]()
//
//    var cityIndex = 0
//    for city in worldCities {
//        let value: String
//        if let zipCode = city.zipCode {
//            value = zipCode
//            logger.debug("CITY \(zipCode) \(city.name)")
//        } else {
//            value = city.searchName
//            logger.debug("CITY \(city.searchName) \(city.name)")
//        }
//
//        var characterIndex = 1
//        for index in value.indices {
//            let sub = value[...index]
//
//            if searchIndexArray.count < characterIndex {
//                searchIndexArray.append(SearchIndex(value: sub, start: cityIndex))
//            }
//            else {
//                let searchIndex = searchIndexArray[characterIndex-1]
//                if searchIndex.value != sub {
//                    let range = searchIndex.start..<cityIndex
//                    try await redis.set(RedisKey(String(searchIndex.value)), toJSON: range)
//                    logger.debug("AAA redis.set \(searchIndex.value) \(range)")
//                    searchIndexArray[characterIndex-1] = SearchIndex(value: sub, start: cityIndex)
//                }
//            }
//
//            characterIndex += 1
//        }
//        for extraIndex in (characterIndex-1)..<searchIndexArray.count {
//            let searchIndex = searchIndexArray[extraIndex]
//            let range = searchIndex.start..<cityIndex
//            logger.debug("BBB redis.set \(searchIndex.value) \(range)")
//            try await redis.set(RedisKey(String(searchIndex.value)), toJSON: range)
//        }
//        searchIndexArray.removeLast(searchIndexArray.count - (characterIndex-1))
//
//        cityIndex += 1
//
//        if cityIndex % 5000 == 0 {
//            logger.info("\(cityIndex.withCommas) of \(worldCities.count.withCommas) cities indexed")
//        }
//    }
//
//    for searchIndex in searchIndexArray {
//        let range = searchIndex.start..<cityIndex
//        logger.debug("CCC redis.set \(searchIndex.value) \(range)")
//        try await redis.set(RedisKey(String(searchIndex.value)), toJSON: range)
//    }
//
//    logger.info("DONE Creating Autocomplete Table")
//}

extension Int {
    private static var commaFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()

    internal var withCommas: String {
        return Int.commaFormatter.string(from: NSNumber(value: self)) ?? ""
    }
}
