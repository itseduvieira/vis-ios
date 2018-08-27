//
//  Queue.swift
//  VisualNoAr
//
//  Created by Eduardo Vieira on 25/08/18.
//  Copyright © 2018 Visual no Ar. All rights reserved.
//

struct Queue<T> {
    var list = [T]()
    
    mutating func enqueue(_ element: T) {
        list.append(element)
    }
    
    mutating func dequeue() -> T? {
        if !list.isEmpty {
            return list.removeFirst()
        } else {
            return nil
        }
    }
    
    func peek() -> T? {
        if !list.isEmpty {
            return list[0]
        } else {
            return nil
        }
    }
    
    var isEmpty: Bool {
        return list.isEmpty
    }
}
