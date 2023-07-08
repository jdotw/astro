//
//  FileView.swift
//  Astro
//
//  Created by James Wilson on 2/7/2023.
//

import SwiftUI
import CoreData

struct FileView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    var file: File
    
    var body: some View {
        Text(file.name ?? "unnamed")
    }
}

struct FileView_Previews: PreviewProvider {
    static var previews: some View {
        FileView(file: File.example).environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
