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
    @State private var exposureValue: Double = 0

    var file: File

    init(file: File) {
        self.file = file
    }

    func willAppear() {
        print("willAppear")
    }

    var body: some View {
        var stale = false

        let securityURL = try! URL(resolvingBookmarkData: self.file.bookmark!, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &stale)
        let fits = FITSFile(url: securityURL)!
        let image = fits.image()!
        let exposedImage = fits.adjustExposure(inputImage: image, ev: Float(self.exposureValue))!
        Text(self.file.name ?? "unnamed")
            .padding(10.0)
        HStack {
            Image(nsImage: NSImage(cgImage: exposedImage, size: NSSize.zero))
                .resizable()
                .aspectRatio(contentMode: .fit)
            Image(nsImage: NSImage(cgImage: fits.createHistogram(inputImage: exposedImage)!, size: NSSize.zero))
                .aspectRatio(contentMode: .fit)
        }
        Slider(value: self.$exposureValue, in: -10 ... 10, step: 0.1) {
            Text("Exposure")
        }
        .padding()

        Text("Exposure Value: \(self.exposureValue)")
    }
}

struct FileView_Previews: PreviewProvider {
    static var previews: some View {
        FileView(file: File.example).environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
