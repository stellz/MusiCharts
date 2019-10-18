//
//  Result.swift
//  MusiChart
//
//  Created by Stella on 6.02.19.
//  Copyright © 2019 Magpie Studio Ltd. All rights reserved.
//

import Foundation

enum Result {

    case result(Bool)
    case error(ResultError)

    var resultValue: Bool? {
        if case let .result(result) = self {
            return result
        }
        return nil
    }

}

enum ResultError: Error {
    
    case failed(String)
    case scrobbleFailure(Error)
    case loveFailure(Error)
}

extension Result: Equatable {

    static func == (lhs: Result, rhs: Result) -> Bool {
        switch (lhs, rhs) {
        case (.result, .result):
            return true
        case (.error, .error):
            return true
        default: return false
        }
    }

}
