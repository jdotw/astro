//
//  Session+PreviewProvider.swift
//  Astro
//
//  Created by James Wilson on 12/7/2023.
//

import CoreData
import Foundation

extension Session {
    static var example: Session {
        let context = PersistenceController.preview.container.viewContext
        let fetchRequest: NSFetchRequest<Session> = Session.fetchRequest()
        fetchRequest.fetchLimit = 1
        let results = try? context.fetch(fetchRequest)
        return (results?.first!)!
    }
}
