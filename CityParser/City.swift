//
//  City.swift
//  
//
//  Created by Doug on 2/3/22.
//

public final class WorldCitiesList: BinaryCodable {
    public let cities: [City]
    
    public init(cities: [City]) {
        self.cities = cities
    }
}

public enum Capitol: String, BinaryCodable {
    case primary, admin, minor, none
}

public final class City: BinaryCodable {
    public let name: String
    public let searchName: String
    public let zipCode: String
    public let latitude: Double
    public let longitude: Double
    public let country: String
    public let iso2: String
    public let iso3: String
    public let adminName: String
    public let stateID: String
    public let stateAbbreviation: String
    public let capitol: Capitol
    public let population: Int
    
    public init(name: String,
                searchName: String,
                zipCode: String,
                latitude: Double,
                longitude: Double,
                country: String,
                iso2: String,
                iso3: String,
                adminName: String,
                stateID: String,
                stateAbbreviation: String,
                capitol: Capitol,
                population: Int
    ) {
        self.name = name
        self.searchName = searchName
        self.zipCode = zipCode
        self.latitude = latitude
        self.longitude = longitude
        self.country = country
        self.iso2 = iso2
        self.iso3 = iso3
        self.adminName = adminName
        self.stateID = stateID
        self.stateAbbreviation = stateAbbreviation
        self.capitol = capitol
        self.population = population
    }
}
