//
//  ArrayExt.swift
//  CoreDataApp
//
//  Created by Dmitry on 12.03.22.
//

import Foundation

extension Array where Element == Task {
    subscript (priority: TaskPriority) -> [Task] {
        get {
            var tasks = [Task]()
            for element in self {
        
                if let elementPriority = element.priority {
                    
                    switch priority {
                    case .high:
                        if elementPriority.name == TaskPriority.high.rawValue {
                            tasks.append(element)
                        }
                    case .medium:
                        if elementPriority.name == TaskPriority.medium.rawValue {
                            tasks.append(element)
                        }
                    case .low:
                        if elementPriority.name == TaskPriority.low.rawValue {
                            tasks.append(element)
                        }
                    }
                }
            }
            
            return tasks
        }
         
        set {
            self = newValue
        }
    }
}
