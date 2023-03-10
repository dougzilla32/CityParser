//
//  main.swift
//  CityParser
//
//  Created by Doug on 3/9/23.
//

import os

do {
    try await initialize(logger: Logger())
} catch {
    print(error)
}
