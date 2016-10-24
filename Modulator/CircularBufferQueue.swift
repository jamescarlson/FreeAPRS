//
//  CircularBufferQueue.swift
//  Modulator
//
//  Created by James on 10/17/16.
//  Copyright © 2016 dimnsionofsound. All rights reserved.
//

import Foundation

/* A circular buffer queue is designed to minimze the asymptotic complexity
 of queueing and dequeueing elemetnts. 
 
 An Array stores the elements in the queue and when enqueueing, an element is
 written at the "write" index, which is then advanced, wrapping around if
 needed. When dequeueing, an element is read from the "read" index, which is
 then advanced, wrapping around if needed.
 
 The queue is initialized with a certain capacity, and if the user attempts to
 enqueue more elements than the capacity, the array is resized to support it.
 */

class CirclarBufferQueue <T> {
    private var elements : [T?]
    private var writeIndex = 0
    private var readIndex = 0
    
    init (withCapacity: Int) {
        elements = [T?](repeating: nil, count: withCapacity)
    }
    
    public func push(e: T) {
        if (size() >= elements.count) {
            
            /*Double the array size to get more space
            Modulus indexing will still work: if the read index was about to
            wrap around, those elements are now in the second half. */
            
            elements.append(contentsOf: elements)
        }
        
        elements[writeIndex % elements.count] = e
    }
    
    public func pop(e: T) -> T? {
        if (isEmpty()) {
            return nil;
        }
        
        return elements[readIndex % elements.count]
    }
    
    public func isEmpty() -> Bool {
        return readIndex >= writeIndex
    }
    
    public func size() -> Int {
        return writeIndex - readIndex
    }
    
}
