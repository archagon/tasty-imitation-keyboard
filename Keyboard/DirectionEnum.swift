//
//  Direction.swift
//  TransliteratingKeyboard
//
//  Created by Alexei Baboulevitch on 7/19/14.
//  Copyright (c) 2014 Apple. All rights reserved.
//

enum Direction: Int {
    case Left = 0
    case Down = 3
    case Right = 2
    case Up = 1
    
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
}
