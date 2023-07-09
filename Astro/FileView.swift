//
//  FileView.swift
//  Astro
//
//  Created by James Wilson on 2/7/2023.
//

import CoreData
import SwiftUI

struct FileView: View {
    @Environment(\.managedObjectContext) private var viewContext

    var file: File

    var body: some View {
        var stale = false
        let securityURL = try! URL(resolvingBookmarkData: file.bookmark!, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &stale)
        let fits = FITSFile(url: securityURL)!
        let nsImage = NSImage(cgImage: fits.image()!, size: NSSize.zero)
        Text(file.name ?? "unnamed")
            .padding(10.0)
        Image(nsImage: nsImage)
            .resizable()
            .aspectRatio(contentMode: .fit)
//            .frame(width: 250.0, height: 250.0, alignment: .center)

//            .clipShape(Circle())
//            .background(Circle().foregroundColor(.white))
    }
}

struct FileView_Previews: PreviewProvider {
    static var previews: some View {
        FileView(file: File.example).environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
