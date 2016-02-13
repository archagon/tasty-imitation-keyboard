//
//  Direction.swift
//  TransliteratingKeyboard
//
//  Created by Alexei Baboulevitch on 7/19/14.
//  Copyright (c) 2014 Alexei Baboulevitch ("Archagon"). All rights reserved.
//

enum Direction: Int, CustomStringConvertible {
    case Left = 0
    case Down = 3
    case Right = 2
    case Up = 1
    
    var description: String {
    get {
        switch self {
        case Left:
            return "Left"
        case Right:
            return "Right"
        case Up:
            return "Up"
        case Down:
            return "Down"
        }
    }
    }
    
    func clockwise() -> Direction {
        switch self {
        case Left:
            return Up
        case Right:
            return Down
        case Up:
            return Right
        case Down:
            return Left
        }
    }
    
    func counterclockwise() -> Direction {
        switch self {
        case Left:
            return Down
        case Right:
            return Up
        case Up:
            return Left
        case Down:
            return Right
        }
    }
    
    func opposite() -> Direction {
        switch self {
        case Left:
            return Right
        case Right:
            return Left
        case Up:
            return Down
        case Down:
            return Up
        }
    }
    
    func horizontal() -> Bool {
        switch self {
        case
        Left,
        Right:
            return true
        default:
            return false
        }
    }
}
