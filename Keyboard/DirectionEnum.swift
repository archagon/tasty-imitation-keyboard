//
//  Direction.swift
//  TransliteratingKeyboard
//
//  Created by Alexei Baboulevitch on 7/19/14.
//  Copyright (c) 2014 Alexei Baboulevitch ("Archagon"). All rights reserved.
//

enum Direction: Int, CustomStringConvertible {
    case left = 0
    case down = 3
    case right = 2
    case up = 1
    
    var description: String {
        get {
            switch self {
            case .left:
                return "Left"
            case .right:
                return "Right"
            case .up:
                return "Up"
            case .down:
                return "Down"
            }
        }
    }
    
    func clockwise() -> Direction {
        switch self {
        case .left:
            return .up
        case .right:
            return .down
        case .up:
            return .right
        case .down:
            return .left
        }
    }
    
    func counterclockwise() -> Direction {
        switch self {
        case .left:
            return .down
        case .right:
            return .up
        case .up:
            return .left
        case .down:
            return .right
        }
    }
    
    func opposite() -> Direction {
        switch self {
        case .left:
            return .right
        case .right:
            return .left
        case .up:
            return .down
        case .down:
            return .up
        }
    }
    
    func horizontal() -> Bool {
        switch self {
        case
        .left,
        .right:
            return true
        default:
            return false
        }
    }
}
