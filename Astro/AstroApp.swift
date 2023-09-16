//
//  AstroApp.swift
//  Astro
//
//  Created by James Wilson on 2/7/2023.
//

import SwiftUI

@main
struct AstroApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
        WindowGroup(for: ImportRequest.ID.self) { $importRequestID in
            FileImportContentView(importRequestID: $importRequestID)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
        WindowGroup(for: URL.self) { $url in
            if let url,
               let objectID = persistenceController.container.persistentStoreCoordinator.managedObjectID(forURIRepresentation: url)
            {
                let object = persistenceController.container.viewContext.object(with: objectID)
                switch object {
                case let targetExportRequest as TargetExportRequest:
                    TargetExportContentView(exportRequest: targetExportRequest)
                        .environment(\.managedObjectContext, persistenceController.container.viewContext)
                default:
                    EmptyView()
                }
            } else {
                EmptyView()
            }
        }
    }
}
