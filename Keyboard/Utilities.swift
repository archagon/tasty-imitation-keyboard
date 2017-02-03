//
//  Utilities.swift
//  TastyImitationKeyboard
//
//  Created by Alexei Baboulevitch on 10/22/14.
//  Copyright (c) 2014 Alexei Baboulevitch ("Archagon"). All rights reserved.
//

import Foundation
import UIKit

// from https://gist.github.com/berkus/8a9e104f8aac5d025eb5
//func memoize<T: Hashable, U>( body: ( (T)->U, T ) -> U ) -> (T) -> U {
//    var memo = Dictionary<T, U>()
//    var result: ((T)->U)!
//    
//    result = { x in
//        if let q = memo[x] { return q }
//        let r = body(result, x)
//        memo[x] = r
//        return r
//    }
//    
//    return result
//}

//func memoize<S:Hashable, T:Hashable, U>(fn : (S, T) -> U) -> (S, T) -> U {
//    var cache = Dictionary<FunctionParams<S,T>, U>()
//    func memoized(val1 : S, val2: T) -> U {
//        let key = FunctionParams(x: val1, y: val2)
//        if cache.indexForKey(key) == nil {
//            cache[key] = fn(val1, val2)
//        }
//        return cache[key]!
//    }
//    return memoized
//}

func memoize<T:Hashable, U>(_ fn : @escaping (T) -> U) -> (T) -> U {
    var cache = [T:U]()
    return {
        (val : T) -> U in
        let value = cache[val]
        if value != nil {
            return value!
        } else {
            let newValue = fn(val)
            cache[val] = newValue
            return newValue
        }
    }
}

//let fibonacci = memoize {
//    fibonacci, n in
//    n < 2 ? Double(n) : fibonacci(n-1) + fibonacci(n-2)
//}

//func memoize<T:Hashable, U>(fn : T -> U) -> (T -> U) {
//    var cache = Dictionary<T, U>()
//    func memoized(val : T) -> U {
//        if !cache.indexForKey(val) {
//            cache[val] = fn(val)
//        }
//        return cache[val]!
//    }
//    return memoized
//}

var profile: ((_ id: String) -> Double?) = {
    var counterForName = Dictionary<String, Double>()
    var isOpen = Dictionary<String, Double>()
    
    return { (id: String) -> Double? in
        if let startTime = isOpen[id] {
            let diff = CACurrentMediaTime() - startTime
            if let currentCount = counterForName[id] {
                counterForName[id] = (currentCount + diff)
            }
            else {
                counterForName[id] = diff
            }
            
            isOpen[id] = nil
        }
        else {
            isOpen[id] = CACurrentMediaTime()
        }
        
        return counterForName[id]
    }
}()
