//
//  File+PreviewProvider.swift
//  Astro
//
//  Created by James Wilson on 2/7/2023.
//

import Foundation

import CoreData

extension File {
    
    static var example: File {
        // Get the first movie from the in-memory Core Data store
        let context = PersistenceController.preview.container.viewContext
        
        let fetchRequest: NSFetchRequest<File> = File.fetchRequest()
        fetchRequest.fetchLimit = 1
        
        let results = try? context.fetch(fetchRequest)
        
        return (results?.first!)!
    }
}
