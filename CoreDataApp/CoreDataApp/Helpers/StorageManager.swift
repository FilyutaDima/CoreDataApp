//
//  StorageManager.swift
//  CoreDataApp
//
//  Created by Dmitry on 12.03.22.
//

import UIKit

enum TaskPriority: String, CaseIterable {
    case high = "High"
    case medium = "Medium"
    case low = "Low"
}

class Storage {
    private init() {}
    
    static let shared = Storage()
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    func saveContext() {
        do {
            try context.save()
        } catch{
            print(#line, error.localizedDescription)
        }
    }
}
