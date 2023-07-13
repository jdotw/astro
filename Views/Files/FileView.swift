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
    @Binding var fileIDs: Set<File.ID>
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \File.timestamp, ascending: false)],
        animation: .default)
    private var files: FetchedResults<File>

    var fileID: File.ID? {
        return fileIDs.first
    }

    var file: File? {
        guard let fileID = fileID else {
            return nil
        }
        files.nsPredicate = NSPredicate(format: "id == %@", fileID)
        return files.first
    }

    var fits: FITSFile? {
        guard let file = file else {
            return nil
        }
        return FITSFile(file: file)
    }

    var image: CGImage? {
        return fits?.image()
    }

    var exposedImage: CGImage? {
        guard let fits = fits,
              let image = image
        else {
            return nil
        }
        return fits.adjustExposure(inputImage: image, ev: Float(exposureValue))
    }

    var nsImage: NSImage {
        guard let exposedImage = exposedImage else {
            return NSImage(size: NSSize(width: 10.0, height: 10.0))
        }
        return NSImage(cgImage: exposedImage, size: NSSize.zero)
    }

    var histogramImage: NSImage {
        guard let fits = fits,
              let exposedImage = exposedImage,
              let histogram = fits.createHistogram(inputImage: exposedImage)
        else {
            return NSImage(size: NSSize(width: 10.0, height: 10.0))
        }
        return NSImage(cgImage: histogram, size: NSSize.zero)
    }

    var body: some View {
        Text(self.file?.name ?? "unnamed")
        VStack {
            Image(nsImage: self.nsImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
            Image(nsImage: self.histogramImage)
                .aspectRatio(contentMode: .fit)
        }
        Slider(value: self.$exposureValue, in: -10 ... 10, step: 0.1) {
            Text("Exposure")
        }
        .padding()
//
//        Text("Exposure Value: \(self.exposureValue)")
//        Text("FileView: \(file.name ?? "none")")
    }
}

// struct FileView_Previews: PreviewProvider {
//    static var previews: some View {
//        FileView(file: File.example).environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
//    }
// }
