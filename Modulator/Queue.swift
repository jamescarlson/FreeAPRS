//
//  Queue.swift
//  FreeAPRS
//
//  Created by James on 11/22/16.
//  Copyright © 2016 dimnsionofsound. All rights reserved.
//

import Foundation

protocol Queue {
    associatedtype ElementType
    
    func push(_ e: ElementType)
    
    func pushMultiple(_ e: [ElementType])
    
    func pop() -> ElementType?
    
    func isEmpty() -> Bool
    
    var count : Int { get }
}

extension Queue {
    func isEmpty() -> Bool {
        return self.count == 0
    }
}
