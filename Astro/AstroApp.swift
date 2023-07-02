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
    }
}
